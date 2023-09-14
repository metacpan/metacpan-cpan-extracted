package App::Oozie::Deploy;
$App::Oozie::Deploy::VERSION = '0.006';
use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES
    WEBHDFS_CREATE_CHUNK_SIZE
);
use Cwd 'abs_path';
use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o

Deploys workflows to HDFS. Specifying names as final arguments will upload only those
USAGE
;

use App::Oozie::Deploy::Template;
use App::Oozie::Deploy::Validate::Spec;
use App::Oozie::Types::Common qw( IsDir IsFile );
use App::Oozie::Constants qw( OOZIE_STATES_RUNNING );

use Carp ();
use Config::Properties;
use DateTime::Format::Strptime;
use DateTime;
use Email::Valid;
use Fcntl           qw( :mode );
use File::Basename  qw( basename dirname );
use File::Find ();
use File::Find::Rule;
use File::Spec;
use File::Temp      qw( tempdir );
use List::MoreUtils qw( uniq );
use List::Util      qw( max  );
use Path::Tiny      qw( path );
use Ref::Util       qw( is_arrayref is_hashref );
use Sys::Hostname ();
use Template;
use Text::Glob qw(
    match_glob
    glob_to_regex
);
use Time::Duration qw( duration_exact );
use Time::HiRes qw( time );
use Types::Standard qw(
    ArrayRef
    CodeRef
    StrictNum
    Str
);

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Common
    App::Oozie::Role::NameNode
    App::Oozie::Role::Git
    App::Oozie::Role::Meta
);

option write_ownership_to_workflow_xml => (
    is      => 'rw',
    default => sub { 1 },
    doc     => 'Populate the meta file into workflow.xml? This option is temporary while testing',
);

option hdfs_dest => (
    is       => 'rw',
    format   => 's',
    doc      => 'HDFS destination (default is <default_hdfs_destination>/<name>)',
);

option keep_deploy_path => (
    is       => 'rw',
    short    => 'keep',
    doc      => 'Keep the temp files at the end of deployment',
);

option prune => (
    is      => 'rw',
    short   => 'p',
    doc     => 'Prune obsolete files on HDFS',
);

option sla => (
    is      => 'rw',
    doc     => 'Enable SLA under Oozie?',
);

option oozie_workflows_base => (
    is      => 'rw',
    format  => 's',
    default => sub {
        my $self = shift;
        File::Spec->catdir( $self->local_oozie_code_path, 'workflows' ),
    },
    lazy   => 1,
);

option dump_xml_to_json => (
    is      => 'rw',
    isa     => IsDir,
    format  => 's',
    doc     => 'Specify a directory to convert and dump XML files in the workflow as JSON. This implies a dryrun.',
);

#------------------------------------------------------------------------------#

has required_tt_files => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [qw(
            coordinator_config_xml
            ttree.cfg
            workflow_global_xml_end
            workflow_global_xml_start
            workflow_parameters_xml_end
            workflow_parameters_xml_start
            workflow_sla_xml
            workflow_xmlns
        )],
    },
);

has ttlib_base_dir => (
    is       => 'rw',
    isa      => IsDir,
    lazy     => 1,
    default  => sub {
        my $self        = shift;
        my $first_guess = File::Spec->catdir( $self->local_oozie_code_path, 'lib' );
        return $first_guess if App::Oozie::Types::Common->get_type(IsDir)->check( $first_guess );
        (my $whereami = __FILE__) =~ s{ [.]pm \z }{}xms;
        my $base = File::Spec->catdir( $whereami, 'ttlib' );
        return $base if App::Oozie::Types::Common->get_type(IsDir)->check( $base );
        die "Failed to locate the ttlib path!";
    },
);

# this will be used for dynamic includes/directives etc. It will be inside
# ttlib_base_dir
has ttlib_dynamic_base_dir_name => (
    is      => 'ro',
    isa     => Str,
    default => sub { '.oozie-deploy-lib' },
);

has deploy_start => (
    is      => 'ro',
    default => sub { time },
);

has max_node_name_len => (
    is      => 'ro',
    isa     => StrictNum, # range check?
    lazy    => 1,
    default => sub {
        shift->oozie->max_node_name_len;
    },
);

has spec_queue_is_missing_message => (
    is  => 'rw',
    isa => Str,
    default => sub {
        <<'NO_QUEUE_MSG';
The action configuration property "%s" is not
defined for these action(s):

%s
NO_QUEUE_MSG
    },
);

has deployment_meta_file_name => (
    is      => 'rw',
    default => sub { '.deployment' },
);

has configuration_files => (
    is      => 'rw',
    # TODO: type needs fixing for coercion
    # isa     => ArrayRef[IsFile],
);

has email_validator => (
    is       => 'rw',
    default  => sub {
        my $self = shift;
        sub {
            my $self   = shift;
            my $emails = shift || do {
                $self->logger->warn( "No email was set!" );
                return;
            };
            my @splits = map s/\+.+?@/@/r, map s/^\s+|\s+$//gr, split q{,}, $emails; ## no critic (ProhibitStringySplit)
            my @invalids = grep { ! Email::Valid->address( $_ ) } @splits;
            return 1 if ! @invalids;
            for my $bogus ( @invalids ) {
                $self->logger->warn(
                    sprintf 'FIXME !!! errorEmailTo parameter in workflow.xml is not set to a proper address: %s',
                            $bogus,
                );
            }
            return;
        },
    },
    isa => CodeRef,
    lazy => 1,
);

has internal_conf => (
    is      => 'ro',
    builder => '__collect_internal_conf',
    lazy    => 1,
);

has process_coord_directive_varname => (
    is      => 'rw',
    isa     => CodeRef,
    default => sub {
        sub {
            my $name = shift;
            return $name;
        },
    }
);

sub BUILD {
    my ($self, $args)  = @_;

    my $logger         = $self->logger;
    my $oozie_base_dir = $self->local_oozie_code_path;
    my $ttlib_base_dir = $self->ttlib_base_dir;
    my $verbose        = $self->verbose;
    my $is_file        = IsFile->library->get_type( IsFile );

    foreach my $file ( @{ $self->required_tt_files } ) {
        my $absolute_path = File::Spec->catfile( $ttlib_base_dir, $file );
        if ( $verbose ) {
            $logger->debug("Assert file: $absolute_path");
        }
        # assert_valid() does not display the error message, hence the manual check

        my $error = $is_file->validate( $absolute_path ) || next;
        $logger->logdie( sprintf "required_tt_files(): %s", $error );
    }

    if ( $verbose ) {
        $logger->debug( join '=', $_, $self->$_ ) for qw(
            local_oozie_code_path
            ttlib_base_dir
        );
    }

    if ( $self->dump_xml_to_json && ! $self->dryrun ) {
        $self->logger->info( 'dump_xml_to_json is enabled without a dryrun. Enabling dryrun as well.' );
        $self->dryrun( 1 );
    }

    return;
}

sub run {
    my $self      = shift;
    my $workflows = shift;
    my $logger    = $self->logger;
    my $config    = $self->internal_conf;
    my $dryrun    = $self->dryrun;

    my $run_start_epoch = time;
    my $log_marker = '#' x 10;

    $logger->info(
        sprintf '%s Starting deployment in %s%s %s',
                    $log_marker,
                    $self->cluster_name,
                    $self->verbose ? '' : '. Enable --verbose to see the underlying commands',
                    $log_marker,
    );

    my($update_coord) = $self->_verify_and_compile_all_workflows( $workflows );

    if (!$self->secure_cluster) {
        # Left in place for historial reasons.
        # All clusters should be under Kerberos.
        # Possible removal in a future version.
        #
        # unsafe, but needed when uploading with mapred's uid or hdfs dfs cannot see the files
        chmod 0755, $config->{base_dest};
    }

    my $success = $self->upload_to_hdfs;

    $self->maybe_update_coordinators( $update_coord ) if @{ $update_coord };

    if ($self->prune) {
        $logger->info( "--prune is set, checking workflow directories for old files" );
        for my $workflow ( @{ $workflows } ) {
            $self->prune_path(
                File::Spec->catdir(
                    $config->{hdfs_dest},
                    basename $workflow
                )
            );
        }
    }

    $logger->info(
        sprintf '%s Completed successfully in %s (took %s) %s',
                    $log_marker,
                    sprintf( '%s%s', $self->cluster_name, ( $dryrun ? ' (dryrun is set)' : '' ) ),
                    duration_exact( time - $run_start_epoch ),
                    $log_marker,
    );

    return $success;
}

sub _verify_and_compile_all_workflows {
    my $self = shift;
    my $workflows = shift;

    my $logger    = $self->logger;

    if ( ! is_arrayref $workflows || ! @{ $workflows } ) {
        $logger->logdie( "Please give one or several workflow name(s) on the command line (glob pattern accepted). Also see --help" );
    }

    $self->pre_verification( $workflows );
    $self->verify_temp_dir;

    if (   $self->gitfeatures
        && ! $self->gitforce
    ) {
        $self->verify_git_tag;
    }

    my $wfs = $self->collect_names_to_deploy( $workflows );
    my($total_errors, $validation_errors);

    my @update_coord;
    for my $workflow ( @{ $wfs } ) {
        my($t_validation_errors, $t_total_errors, $dest, $cvc) =  $self->process_workflow( $workflow );
        push @update_coord, $self->guess_running_coordinator( $workflow, $cvc, $dest );
        $total_errors      += $t_validation_errors;
        $validation_errors += $t_total_errors;
    }

    if ($total_errors) {
        $logger->fatal( "ERROR: $total_errors errors were encountered during this run. Please fix it!" );
        $logger->fatal( "The --force option has been disabled, as not enough really paid attention." );
        $logger->fatal( "Fixing the errors is really your best and easiest option." );
        $logger->logdie( 'Failed.' );
    }

    return \@update_coord;
}

sub process_workflow {
    my $self = shift;
    my $workflow = shift;
    my($t_validation_errors, $t_total_errors, $dest, $cvc) = $self->process_templates( $workflow );
    return $t_validation_errors, $t_total_errors, $dest, $cvc;
}

sub pre_verification {
    # stub
}

sub destination_path {
    my $self    = shift;
    my $default = shift || $self->default_hdfs_destination;
    return $default =~ m{ \A hdfs:// }xms
            ? $default
            : File::Spec->canonpath( File::Spec->catdir( '/', $default ) )
            ;
}

sub __collect_internal_conf {
    my $self  = shift;
    my $keep  = $self->keep_deploy_path;
    my $logger = $self->logger;

    # This will load static properties that we will reuse as variables in the
    # template and merge it with the common.properties file
    my $properties = Config::Properties->new;

    my $config = {};

    if ( my $files = $self->configuration_files ) {
        my $verbose = $self->verbose;
        foreach my $file ( @{ $files } ) {
            if ( $verbose ) {
                $logger->debug( sprintf 'Processing conf file %s ...', $file );
            }
            open my $FH, '<', $file or $logger->logdie( sprintf "Failed to read %s: %s", $file, $! );
            $properties->load( $FH );
            close $FH;
            $config = {
                %{ $config },
                $properties->properties,
            };
        }
    }

    my $base_dest = tempdir( CLEANUP => ! $keep );

    $config->{base_dest} = $base_dest;

    $self->logger->info(
        "Output directory: `$base_dest`.",
        ( $keep ? ' You have decided to keep it after completion' : '' )
    );

    $config->{hdfs_dest} = $self->destination_path( $config->{workflowsBaseDir} );

    # if YARN, use a different property. the oozie syntax doesn't change (still
    # uses the jobtracker property)
    $config->{jobTracker}     = $config->{resourceManager};
    $config->{nameNode}     //= $self->template_namenode;

    $config->{has_sla}        = $self->sla;

    $self->logger->info( "Upload directory: ".$self->destination_path );

    return $config;
}

sub max_wf_xml_length {
    my $self      = shift;
    my $ooz_admin = $self->oozie->admin('configuration');
    my $conf_val  = $ooz_admin->{'oozie.service.WorkflowAppService.WorkflowDefinitionMaxLength'};

    return $conf_val if $conf_val;

    $self->logger->logdie( "Unable to fetch the ooozie configuration WorkflowDefinitionMaxLength!" );
}

sub guess_running_coordinator {
    state $is_running = { map { $_ => 1 } OOZIE_STATES_RUNNING };

    my $self     = shift;
    my $workflow = shift;
    my $cvc      = shift;
    my $dest     = shift;

    my $logger = $self->logger;
    $logger->info( 'Probing for existing coordinators ...' );

    my $local_base  = $self->oozie_workflows_base;
    (my $rel_path   = $workflow) =~ s{ \A \Q$local_base\E [/]? }{}xms;
    my $remote_path = File::Spec->catfile( $self->destination_path, $rel_path );
    my $paths       = $self->oozie
                          ->active_job_paths(
                               coordinator => $self->destination_path
                           );

    my @rv;
    foreach my $path ( grep { $_ =~ m{ \Q$remote_path\E \b \z }xms } keys %{ $paths } ) {
        my $e = $paths->{ $path };
        if ( @{ $e } > 1 ) {
            # TODO: multi path
        }
        foreach my $jobs ( @{ $e } ) {
            foreach my $cid ( keys %{ $jobs } ) {
                # multiple coordinators
                my $job = $jobs->{ $cid };
                next if ! $is_running->{ $job->{status} };
                push @rv,
                     {
                        path     => $path,
                        coord_id => $cid,
                        job      => $job,
                        cvc      => $cvc,
                        workflow => $workflow,
                        dest     => $dest,
                    };
            }
        }
    }

    return @rv;
}

sub maybe_update_coordinators {
    my $self   = shift;
    my $coords = shift;
    for my $e ( @{ $coords } ) {
        # stub: better override in a subclass
    }
    return;
}

sub _get_spec_validator {
    my($self, $dest) = @_;

    my @pass_through = qw(
        email_validator
        max_node_name_len
        max_wf_xml_length
        oozie_cli
        oozie_client_jar
        oozie_uri
        spec_queue_is_missing_message
        timeout
        verbose
    );

    return App::Oozie::Deploy::Validate::Spec->new(
                ( map { $_ => $self->$_ } @pass_through ),
                local_path => $dest,
            );
}

sub __maybe_dump_xml_to_json {
    my $self      = shift;
    my $dump_path = $self->dump_xml_to_json || return;
    my $logger    = $self->logger;

    require JSON;

    my $sv                    = shift || $logger->logdie( "Spec validator not specified!" );
    my $validation_errors_ref = shift;
    my $total_errors_ref      = shift;

    for my $xml_file ( $sv->local_xml_files ) {
        my $parsed = $sv->maybe_parse_xml( $xml_file );

        if ( my $error = $parsed->{error} ) {
            $logger->fatal(
                sprintf "We can't validate %s since parsing failed: %s",
                            $parsed->{relative_file_name},
                            $error,
            );
            ${ $validation_errors_ref }++;
            ${ $total_errors_ref }++;
            next; #we don't even have valid XML file at this point, so just skip it
        };

        $logger->info('Dumping xml to json within ', $dump_path );
        my $json_filename = File::Spec->catfile(
            $dump_path,
            File::Basename::basename($xml_file, '.xml') . '.json'
        );
        File::Path::make_path( $dump_path );
        open my $JSON_FH, '>', $json_filename or $logger->logdie( sprintf "Failed to create %s: %s", $json_filename, $! );
        print $JSON_FH JSON->new->pretty->encode( $parsed->{xml_in} );
        close $JSON_FH;
    }
}

sub compile_templates {
    my $self                  = shift;
    my $workflow              = shift;
    my $validation_errors_ref = shift;
    my $total_errors_ref      = shift;

    if ( ! -d $workflow ) {
        die "The workflow path $workflow either does not exist or not a directory";
    }

    state $pass_through = [
        qw(
            dryrun
            effective_username
            internal_conf
            oozie_workflows_base
            process_coord_directive_varname
            timeout
            ttlib_base_dir
            ttlib_dynamic_base_dir_name
            verbose
            write_ownership_to_workflow_xml
        )
    ];

    my $t = App::Oozie::Deploy::Template->new(
                map { $_ => $self->$_ }
                    @{ $pass_through }
            );

    my($template_validation_errors,
       $template_total_errors,
       $dest,
    ) = $t->compile( $workflow );

    my $cvc = $t->coordinator_directive_var_cache;

    ${ $validation_errors_ref } += $template_validation_errors;
    ${ $total_errors_ref }      += $template_total_errors;

    return $dest, $cvc;
}

sub process_templates {
    my $self = shift;
    my $workflow = shift || die "No workflow path specified!";

    if ( ! -d $workflow ) {
        die "The workflow path $workflow either does not exist or not a directory";
    }

    my($validation_errors, $total_errors);

    my($dest, $cvc) = $self->compile_templates(
                            $workflow,
                            \$validation_errors,
                            \$total_errors,
                        );

    if ( $self->write_ownership_to_workflow_xml ) {
        $self->validate_meta_file(
            File::Spec->catfile( $workflow, $self->meta->file ),
            \$validation_errors,
            \$total_errors,
            {},
        );
    }

    my $sv = $self->_get_spec_validator( $dest );

    $self->__maybe_dump_xml_to_json(
        $sv,
        \$validation_errors,
        \$total_errors,
    ) if $self->dump_xml_to_json;

    my($spec_validation_errors, $spec_total_errors) = $sv->verify( $workflow );
    $validation_errors += $spec_validation_errors;
    $total_errors      += $spec_total_errors;

    $self->create_deployment_meta_file( $dest, $workflow, $total_errors );

    if ( $validation_errors ) {
        $self->logger->error( "Oozie deployment validation status: !!!!! FAILED !!!!!" );
    }
    else {
        $self->logger->info( "Oozie deployment validation status: OK" );
    }

    return $validation_errors, $total_errors, $dest, $cvc;
}

sub validate_meta_file {
    my $self = shift;
    my $file = shift;

    $self->logger->info( sprintf 'Extra validation for %s', $file );

    return;
}

sub verify_temp_dir {
    my $self         = shift;
    my $user_setting = $ENV{TMPDIR} || return;
    my $logger       = $self->logger;

    # The path needs to be readable by mapred in order the deploy to be successful
    # Some users have this set in their environment to paths lacking relevant
    # permissions leading to failures.
    #
    # If the path is bogus, then by removing the setting locally in here
    # will lead the temporary directory to be created inside "/tmp" by default.
    #
    # Otherwise it can still be altered to elsewhere by changing the
    # environment by the users.
    #

    my $remove;

    if ( ! -d $user_setting ) {
        $logger->warn( sprintf "You have TMPDIR=%s but it doesn't exist! I will ignore/remove that setting!", $user_setting );
        $remove = 1;
    }
    else {
        my $mode       = (stat $user_setting)[2];
        my $group_read = ( $mode & S_IRGRP ) >> 3;
        my $other_read =   $mode & S_IROTH;

        if ( ! $group_read || ! $other_read ) {
            $logger->warn(
                sprintf "You have TMPDIR=%s and it is not group/other readable (mode=%04o)! I will ignore/remove that setting!",
                             $user_setting,
                             S_IMODE( $mode ),
            );
            $remove = 1;
        }
    }

    delete $ENV{TMPDIR} if $remove;

}

sub collect_names_to_deploy {
    my $self  = shift;
    my $names = shift || die "No workflow names were specified!";

    my $owf_base = $self->oozie_workflows_base;
    my $logger   = $self->logger;
    my $verbose  = $self->verbose;

    if ( ! is_arrayref $names ) {
        die "Workflow names need to be specified as an arrayref";
    }

    my(@firstLevelMatchingPatterns, @secondLevelMatchingPatterns);

    # removing path separator from string's start and end
    my @workflow = map {s{^/}{};s{/$}{}; $_} @{ $names };
    my $workflowPatternCount = @workflow;

    for my $w (@workflow) {
        my $separators = () = $w =~ /\//g;

        # disallow the case with going up the tree ".." ?
        if ( $separators == 0 ) {
            push @firstLevelMatchingPatterns, $w;
        }
        elsif ($separators == 1 ) {
            push @secondLevelMatchingPatterns, $w;
        }
        else {
            my $msg = <<"MSG";
=> Only first or second-level folders inside the workflow folder can be used to
    store workflows which are eligible for deployment.
    The following path or pattern will, therefore, be ignored: $w\n",
MSG
            $logger->info( $msg );
        }
    }

    @firstLevelMatchingPatterns = map {qr/^$_$/} @firstLevelMatchingPatterns;

    # Transform the patterns in actual, existing directories
    my @firstLevelWorkflows =
        File::Find::Rule->directory
            ->maxdepth( 1 )
            ->mindepth( 1 )
            ->extras({
                follow      => 1,
                follow_skip => FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES,
            })
            ->name(@firstLevelMatchingPatterns)
            ->in( $owf_base );

    #Don't want to be matching the 'workflows' part in workflows/stuff/workflow
    my $workflowFolderPrefixLength = length( $owf_base ) + 1;

    my @secondLevelWorkflows =
        File::Find::Rule
            ->directory
            ->maxdepth( 2 )
            ->mindepth( 2 )
            ->extras({
                follow      => 1,
                follow_skip => FILE_FIND_FOLLOW_SKIP_IGNORE_DUPLICATES,
            })
            ->exec(
                sub{
                    my $str = substr $_[2], $workflowFolderPrefixLength;
                    # might be a good idea to limit matching
                    # globs to the last level of folder structure
                    # only (e.g. no "f*g/k*s")
                    return grep { match_glob($_, $str) }
                                @secondLevelMatchingPatterns
                }
            )
            ->in( $owf_base );

    for my $i ( 0..$#firstLevelWorkflows ) {
        my $workflowFileLocationGuess = File::Spec->rel2abs(
                                            $firstLevelWorkflows[$i]."/workflow.xml"
                                        );
        my $bundleFileLocationGuess = File::Spec->rel2abs($firstLevelWorkflows[$i]."/bundle.xml");

        if (! -f $workflowFileLocationGuess) {
            $logger->info(
                "Doesn't look like there's a workflow at $firstLevelWorkflows[$i]. ",
                "I will process its subfolders, if any, instead."
            );
            my @subs = File::Find::Rule->directory
                                 ->maxdepth(1)
                                 ->mindepth(1)
                                 ->in( $firstLevelWorkflows[$i] )
                             ;
            if (@subs) {
                for my $subx ( @subs ) {
                    $logger->debug( "Will additionally look for workflows in the following sub folder: $subx" );
                }
            }

            push @secondLevelWorkflows, @subs;
            # When deploying a wf/coord, it makes no sense to upload what we have in parent,
            # otherwise, yes, we'll need to update bundle.xml along with any other file on it
            if (! -f $bundleFileLocationGuess) {
              splice @firstLevelWorkflows, $i, 1;
              $i--;
            }
            else
            {
                $self->logger->debug("We have identified this a a bundle.");
            }
        }
    }

    @firstLevelWorkflows  = uniq @firstLevelWorkflows;
    @secondLevelWorkflows = uniq @secondLevelWorkflows;
    my $num_workflows     = @secondLevelWorkflows + @firstLevelWorkflows;

    if ( ! $num_workflows ) {
        die "Exiting: found no workflows to deploy under `$owf_base`.";
    }

    if ($workflowPatternCount > $num_workflows) {
        my @uniq_wfs = (@secondLevelWorkflows, @firstLevelWorkflows);
        my @params = (
            $num_workflows,
            $workflowPatternCount,
            join(qq{\n\t}, @{ $names } ),
            join(qq{\n\t}, @uniq_wfs),
        );
        my $msg = sprintf <<"ERROR", @params;

Exiting: only %s workflow folders found when we expected at least %s (from the number of command-line arguments).

Expected workflows:
\t%s

Computed:
\t%s

Hint: you might have a character which could look like a dash but it is not in your arguments.
If this is the case, such an argument will be treated as a workflow name.

ERROR
        ;
        $logger->logdie( $msg );
    }

    @workflow = ( @firstLevelWorkflows, @secondLevelWorkflows );

    for my $wf ( @workflow ) {
        $logger->info( "Workflow to be deployed: $wf" );
    }

    return \@workflow;
}

sub collect_data_for_deployment_meta_file {
    my $self         = shift;
    my $workflow     = shift;
    my $total_errors = shift;
    my $use_git      = $self->gitfeatures;

    my $obase      = $self->oozie_workflows_base;

    # returns values for "workflow" might be overridden to be absolute from
    # the subclasses
    my $source_dir = File::Spec->file_name_is_absolute( $workflow )
                    ? $workflow
                    : File::Spec->catfile( $obase, $workflow )
                    ;

    my @meta = (
        {
            display => 'User',
            name    => 'user',
            value   => $self->effective_username,
        },
        {
            display => 'Deployment date',
            name    => 'date',
            value   => $self->date->epoch_yyyy_mm_dd_hh_mm_ss( time ),
        },
        {
            display => 'Deployment host',
            name    => 'host',
            value   => Sys::Hostname::hostname(),
        },
        {
            display => 'Deployed directory',
            name    => 'source_dir',
            value   => $source_dir,
        },
        {
            display => 'Validation errors',
            name    => 'total_errors',
            value   => $total_errors,
        },
    );

    if ( $use_git ) {

        my $repo_dir = $self->git_repo_path;
        my $git_log = join "\n", $self->get_git_info_on_all_files_in( $workflow );
        $git_log ||= 'N/A. The files were not committed';

        push @meta,
            {
                display => 'Latest local SHA1',
                name    => 'git_hash',
                value   => scalar $self->get_latest_git_commit,
            },
            {
                display => 'Latest workflow SHA1',
                name    => 'git_folder_hash',
                value   => scalar $self->get_git_sha1_of_folder( abs_path $workflow ) },
            {
                display => 'Latest git-deploy tag',
                name    => 'git_tag',
                value   => $self->get_latest_git_tag,
            },
            {
                display => 'Git status from deployment location',
                name    => 'git_status',
                value   => scalar $self->get_git_status,
            },
            {
                display => "Git data on files (assuming git repo to be in $repo_dir)",
                name    => 'git_log',
                value   => $git_log,
            },
        ;
    }

    # We also want to have this convertible/accessible as a hash
    my %seen;
    for my $e ( @meta ) {
        if ( ++$seen{ $e->{name} } > 1 ) {
            die "$e->{name} is used more than once in the deployment meta spec!";
        }
    }

    return \@meta;
}

sub create_deployment_meta_file {
    my $self         = shift;
    my $path         = shift || die "No path was specified!";
    my $workflow     = shift || die "No workflow was specified!";
    my $total_errors = shift;

    my $meta = $self->collect_data_for_deployment_meta_file( $workflow, $total_errors  );
    $self->write_deployment_meta_file( $path, $meta );

    return;
}

sub write_deployment_meta_file {
    my $self = shift;
    my $path = shift;
    my $meta = shift;

    # only probe the single line meta data
    my $max_len = max   map  { length $_->{display} }
                        grep { $_->{value} !~ m{\n}xms }
                        @{ $meta }
                    ;

    my $file = File::Spec->catfile( $path, $self->deployment_meta_file_name );

    open my $FH, '>', $file or die "Could not create $file: $!";

    for my $row ( @{ $meta } ) {
        my($display, $value) = @{ $row }{qw/ display value /};
        my $multi_line = $value =~ m{\n}xms;
        printf $FH "%s% -${max_len}s:%s%s%s",
                    ( $multi_line ? "\n" : ''     ),
                    $display,
                    ( $multi_line ? "\n\n" : ' '  ),
                    $value,
                    ( $multi_line ? "\n\n" : "\n" ),
        ;
    }

    close $FH;

    return;
}

sub prune_path {
    my $self          = shift;
    my $path          = shift || die "No path was specified";
    my $files         = $self->hdfs->list($path);
    my $total_files   = scalar @$files;
    my $deleted_files = 0;
    my $deploy_start  = $self->deploy_start;
    my $dryrun        = $self->dryrun;

    for my $file (@$files) {

        #next if $file->{pathSuffix} =~ /^(\.deployment|coordinator\.xml)$/;
        if (   $file->{type} eq 'FILE'
            && $file->{modificationTime} / 1000 < $deploy_start
        ) {
            my $msg = sprintf "old file found in destination: %s (mtime %s) -> %s",
                                $file->{pathSuffix},
                                $self->date->epoch_yyyy_mm_dd_hh_mm_ss(
                                    int( $file->{modificationTime} / 1000 )
                                ),
                                $dryrun ? 'would have deleted if dryrun was not specified' : 'is now deleted',
                        ;
            $self->logger->info( $msg );
            $self->hdfs->delete("$path/$file->{pathSuffix}") if ! $dryrun;
            $deleted_files++;
        }

        # check directories regardless of age
        if( $file->{type} eq 'DIRECTORY' ) {
            my $msg = sprintf "Directory found in destination: %s (mtime %s) -> checking contents",
                            $file->{pathSuffix},
                            $self->date->epoch_yyyy_mm_dd_hh_mm_ss(
                                int( $file->{modificationTime} / 1000 )
                            ),
                        ;
            $self->logger->info( $msg );

            #recurse down to check lower directories
            my $empty = $self->prune_path("$path/$file->{pathSuffix}");

            if( $empty ) {
                $self->logger->info( "$file->{pathSuffix} is empty, " . ( $dryrun ? 'would have deleted if dryrun was not specified' : 'deleting' ) );
                $self->hdfs->delete("$path/$file->{pathSuffix}") if ! $dryrun;
                $deleted_files++;
            } else {
                $self->logger->info( "$file->{pathSuffix} has current files, keeping it" );
            }
        }
    }

    return ($total_files == $deleted_files);
}

sub upload_to_hdfs {
    my $self    = shift;
    my $config  = $self->internal_conf;

    if ( $self->dryrun ) {
        $self->logger->warn(
            sprintf "Skipping upload to HDFS as dryrun was set. Would have uploaded from %s to %s",
                                $config->{base_dest},
                                $config->{hdfs_dest},
        );
        return 1;
    }

    my $success = $self->_copy_to_hdfs_with_webhdfs($config->{base_dest}, $config->{hdfs_dest});
    return $success;
}


sub _hdfs_exists_no_exception {
    my $self = shift;
    my $path = shift;
    my $hdfs = $self->hdfs;
    my $rv;

    eval {
        $rv = $hdfs->exists( $path );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        if ( $self->verbose ) {
            $self->logger->debug(
                sprintf "WebHDFS exists() failed with exception, however since this is a silent call, it is ignored: %s",
                            $eval_error,
            )
        }
    };

    return $rv;
}

sub _copy_to_hdfs_with_webhdfs {
    my $self         = shift;
    my $sourceFolder = shift;
    my $destFolder   = shift;

    my $hdfs         = $self->hdfs;
    my $logger       = $self->logger;
    my $verbose      = $self->verbose;

    $logger->info(
        sprintf "copying from `%s` to `%s`",
                    $sourceFolder,
                    $destFolder,
    );

    if ( ! $self->_hdfs_exists_no_exception( $destFolder ) ) {
        if ( $verbose ) {
            $logger->debug(
                sprintf 'HDFS destination %s does not exist',
                            $destFolder,
            );
        }
        my(undef, @paths) = File::Spec->splitpath( $destFolder );
        my $remote_base;
        for my $chunk ( @paths ) {
            if ( $remote_base ) {
                $remote_base = File::Spec->catdir( $remote_base, $chunk);
            }
            else {
                $remote_base = $chunk;
            }
            if ( $self->_hdfs_exists_no_exception( $remote_base ) ) {
                next;
            }
            if ( $verbose ) {
                $logger->debug(
                    sprintf 'Attempting to mkdir HDFS destination %s',
                                $remote_base,
                );
            }
            $hdfs->mkdir( $remote_base );
            $hdfs->chmod( $remote_base, 775 );
        }
        # since the above calls were silent, see if this throws anything
        if ( $hdfs->exists($destFolder) ) {
            if ( $verbose ) {
                $logger->debug(
                    sprintf "HDFS destination %s exists",
                                $destFolder,
                );
            }
        }
    }
    else {
        if ( $verbose ) {
            $logger->debug(
                sprintf 'HDFS destination %s exists',
                            $destFolder,
            );
        }
    }
    my $f_rule = File::Find::Rule->new->file->maxdepth(1)->mindepth(1);

    my @files = $f_rule->in($sourceFolder);

    foreach my $file (@files)
    {
        my $filename = basename($file);
        my $dest = File::Spec->catfile($destFolder, $filename);
        my $filehandle = path( $file );
        my $data = $filehandle->slurp_raw;
        if($verbose){
            $logger->debug("Creating $dest");
        }
        $hdfs->touchz( $dest );
        if ( ! $hdfs->create($dest, $data, overwrite => "true") ) {
            $logger->logdie(
                sprintf 'Failed to create %s through WebHDFS',
                        $dest
            );
        }
        $hdfs->chmod($dest, 775);
    }

    my $d_rule = File::Find::Rule->new->directory->maxdepth(1)->mindepth(1);
    my @folders = $d_rule->in($sourceFolder);

    foreach my $folder (@folders)
    {
        my $foldername = basename($folder);
        my $dest = File::Spec->catfile($destFolder, $foldername);
        $self->_copy_to_hdfs_with_webhdfs($folder, $dest)
    }
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Deploy

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use App::Oozie::Deploy;
    App::Oozie::Deploy->new_with_options->run;

=head1 DESCRIPTION

This is an action/program in the Oozie Tooling.

=for Pod::Coverage BUILD

=head1 NAME

App::Oozie::Deploy - The program to deploy Oozie workflows.

=head1 Methods

=head2 collect_data_for_deployment_meta_file

=head2 collect_names_to_deploy

=head2 compile_templates

=head2 create_deployment_meta_file

=head2 destination_path

=head2 guess_running_coordinator

=head2 max_wf_xml_length

=head2 maybe_update_coordinators

=head2 pre_verification

=head2 process_templates

=head2 process_workflow

=head2 prune_path

=head2 run

=head2 upload_to_hdfs

=head2 validate_meta_file

=head2 verify_temp_dir

=head2 write_deployment_meta_file

=head1 Accessors

=head2 Overridable from cli

=head3 dump_xml_to_json

=head3 hdfs_dest

=head3 keep_deploy_path

=head3 oozie_workflows_base

=head3 prune

=head3 sla

=head3 write_ownership_to_workflow_xml

=head2 Overridable from sub-classes

=head3 configuration_files

=head3 deploy_start

=head3 deployment_meta_file_name

=head3 email_validator

=head3 internal_conf

=head3 max_node_name_len

=head3 process_coord_directive_varname

=head3 required_tt_files

=head3 spec_queue_is_missing_message

=head3 ttlib_base_dir

=head3 ttlib_dynamic_base_dir_name

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# oozie_base/lib
# oozie_base/workflows
# ?


