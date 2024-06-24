package App::Oozie::Run;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    DEFAULT_END_DATE_DAYS
    DEFAULT_START_DATE_DAY_FRAME
    EMPTY_STRING
    FORMAT_ZULU_TIME
    INDEX_NOT_FOUND
    MAX_RETRY
    OOZIE_STATES_RUNNING
    SHORTCUT_METHODS
    SPACE_CHAR
    TERMINAL_LINE_LEN
);
use App::Oozie::Date;
use App::Oozie::Types::DateTime qw( IsDate IsHour IsMinute );
use App::Oozie::Types::Common qw( IsJobType );
use App::Oozie::Util::Misc qw(
    remove_newline
    resolve_tmp_dir
    trim_slashes
);

use Config::Properties;
use Cwd;
use File::Basename;
use File::Spec;
use File::Temp ();
use IO::Interactive qw( is_interactive );
use IPC::Cmd        ();
use Ref::Util       qw( is_ref is_hashref is_arrayref );
use Template;
use Time::Duration  qw( duration_exact );
use Types::Standard qw( Int );
use XML::LibXML::Simple;

use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o [options] workflow-name
USAGE
;

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Common
    App::Oozie::Role::Fields::Path
    App::Oozie::Role::Meta
    App::Oozie::Role::Info
);

#------------------------------------------------------------------------------#

option appname => (
    is     => 'rw',
    format => 's',
    doc    => remove_newline( <<'DOC' ),
Workflow name, useful if you want to run different instances of the same
workflow with different parameters. If not set, then this will default to
the workflow basename.
DOC
);

my $__JOB_TYPES = eval {
    sprintf ' Valid values are %s',
            join q{, },
            @{ IsJobType->parent->values },
    ;
} || EMPTY_STRING;

option type => (
    default => sub { 'coord' },
    is      => 'rw',
    isa     => IsJobType,
    format  => 's',
    doc     => remove_newline( sprintf <<'DOC', $__JOB_TYPES ),
Defines the type of job the user needs to launch. If nothing is specified,
the script will check the existence of a coordinator.xml file, to determine
whether this should be launched as a coordinator or a single workflow.%s
DOC
);

option notify => (
    is      => 'rw',
    default => sub { 1 },
);

option define => (
    is      => 'rw',
    format  => 's@',
    default => sub { [] },
    doc     => q{Define extra parameters for oozie, like "--define 'foo=bar'"},
);

option path => (
    is      => 'rw',
    format  => 's',
    default => \&_option_build_guess_wf_path,
    lazy    => 1,
    doc     => 'HDFS location for the workflow. Defaults to <default_hdfs_destination>/<workflow-basename>',
);

option sla_duration => (
    is      => 'rw',
    isa     => Int,
    format  => 'i',
    doc     => remove_newline( <<'DOC' ),
the runtime, in minutes, after which a workflow deployed using the --sla
switch should send an sla-duration-miss email to the errorEmailTo
recipient(s). This may be adjusted dynamically and automatically after
several runs have happened to provide enough statistics, but is for now
required to deploy a new workflow needing SLA events
DOC
);

option starthour => (
    is      => 'rw',
    format  => 's',
    default => sub { 0 },
    isa     => IsHour,
    doc     => remove_newline( <<'DOC' ),
hour of day (0 to 23) for the 1st coordinator run. Applies to all
coordinators, even hourly ones. Defaults to midnight (in UTC)
DOC
);

option startmin => (
    is      => 'rw',
    format  => 's',
    default => sub { 0 },
    isa     => IsMinute,
    doc     => remove_newline( <<'DOC' ),
minute within starthour 00 to 59 for the coordinator run. Applies to all
coordinators. Defaults to 00
DOC
);

option endhour => (
    is      => 'rw',
    format  => 's',
    default => sub { 0 },
    isa     => IsHour,
    doc     => remove_newline( <<'DOC' ),
hour of day (0 to 23) for the last coordinator run. Applies to all
coordinators, even hourly ones. Defaults to midnight (in UTC)
DOC
);

option endmin => (
    is      => 'rw',
    format  => 's',
    default => sub { 0 },
    isa     => IsMinute,
    doc     => remove_newline( <<'DOC' ),
minute within endhour 00 to 59 for the coordinator run. Applies to all
coordinators. Defaults to 00
DOC
);

option dates_from_properties => (
    is => 'rw',
);

option startdate => (
    is     => 'rw',
    isa    => IsDate,
    format => 's',
    doc    => remove_newline( sprintf <<'DOC', DEFAULT_START_DATE_DAY_FRAME, join( q{, }, SHORTCUT_METHODS ) ),
date at which the first instance of the coordinator should be run. Maximum
%s days in the past or future, can be overriden with --force, defaults to
tomorrow. Option can also be: %s
DOC
);

option enddate => (
    is     => 'rw',
    isa    => IsDate,
    format => 's',
    doc    => remove_newline( sprintf <<'DOC', ( DEFAULT_END_DATE_DAYS ) x 2 ),
The last date the workflow should run. Maximum %s days from today. Defaults
to %s days from today.
DOC
);

option doas => (
    is     => 'rw',
    format => 's',
    lazy   => 1,
    doc    => 'User to impersonate as',
);

sub setup_dates {
    my $self = shift;

    state $is_shortcut_date = {
        map { $_ => 1 } SHORTCUT_METHODS
    };

    return if $self->dates_from_properties;

    my $date = $self->date;

    # process the date, within reasonable bounds. the default date is today, which
    # generally means the workflow will run at least once as soon as it is
    # deployed, provided the time of day at which it is scheduled is earlier than
    # the time it is submitted
    my $startdate = $self->startdate;
    if ( $startdate ) {
        my %is_shortcut = map { $_ => 1 } SHORTCUT_METHODS;
        if ( $is_shortcut{ $startdate } ) {
            $startdate = $date->$startdate();
        }
        else {
            my $intersects = $date->intersection(
                $startdate,
                $startdate,
                $date->move( $date->today, -DEFAULT_START_DATE_DAY_FRAME ),
                $date->move( $date->today,  DEFAULT_START_DATE_DAY_FRAME ),
            );

            if ( ! $intersects ) {
                push @{ $self->errors },
                    sprintf 'Start date is out of normal bounds (%s days in the past or in the future)',
                                DEFAULT_START_DATE_DAY_FRAME,
                    ;
            }
        }
    }
    else {
        $startdate = $date->tomorrow;
    }

    $self->startdate( $startdate );
    my $enddate = $self->enddate;

    $enddate //= $date->move( $date->today, DEFAULT_END_DATE_DAYS );

    if ( $is_shortcut_date->{ $enddate } ) {
        $enddate = $date->$enddate();
    }

    if ( $enddate lt $startdate ) {
        die 'End date should be later than start date';
    }

    if ( ! $self->force
        && abs $date->diff($enddate, $date->today) > DEFAULT_END_DATE_DAYS
    ) {
        die sprintf 'End date should not be later than %s days from today',
                        DEFAULT_END_DATE_DAYS,
        ;
    }

    $self->enddate( $enddate );

    return;
}

#------------------------------------------------------------------------------#

has basedir => (
    is => 'rw',
);

has errors => (
    is      => 'rw',
    default => sub { [] },
);

sub _option_build_guess_wf_path {
    my $self    = shift;
    my $wf_dir = $self->basedir;

    my $rv;
    # Should be the same on local file system and HDFS
    my $relativePath;
    my $local_wf_basedir = '/workflows/';

    if (File::Spec->file_name_is_absolute($wf_dir)) {
        my $workflowsPartIndex = rindex($wf_dir, $local_wf_basedir);
        if ( $workflowsPartIndex != INDEX_NOT_FOUND ) {
            $relativePath = substr $wf_dir, $workflowsPartIndex + length($local_wf_basedir);
        }
    }
    else {
        $relativePath = $wf_dir;
    }

    if ( $relativePath ) {
        $rv = File::Spec->catfile(
                    $self->oozie_basepath,
                    trim_slashes( $relativePath ),
                );
    }
    else {
        die 'Failed to guess the workflow path!';
    }

    return $rv;
}

sub run {
    my $self   = shift;
    my $wf_dir = shift || $self->logger->logdie( 'Please specify a workflow/coordinator/bundle to run' );

    my $logger  = $self->logger;

    my $run_start_epoch = time;

    for my $huh ( @_ ) {
        $logger->warn( sprintf 'Unknown parameter: %s', $huh // '[undefined]');
    }

    my $verbose = $self->verbose;

    $logger->info( 'Starting' . ( $verbose ? EMPTY_STRING : '. Enable --verbose to see the underlying commands' ) );

    $self->log_versions if $self->verbose;

    $self->basedir( $wf_dir );

    my $CWD = getcwd() || die "Can't happen: unable to get cwd: $!";
    if ( ! chdir $wf_dir ) {
        die sprintf 'Cannot chdir to %s: %s -- Current dir: %s', $wf_dir, $!, $CWD;
    }

    if ( ! $self->appname ) {
        my $guess = basename getcwd;
        $logger->info( 'appname is not set, using the basedir=' . $guess );
        $self->appname( $guess );
    }

    # move to constructor?
    (my $appname = $self->appname) =~ s{ [/]+ \z }{}xms;
    $self->appname( $appname );

    $self->logger->info( sprintf 'Job name: %s',            $self->appname );
    $self->logger->info( sprintf 'Job path (HDFS dir): %s', $self->path    );

    $self->setup_dates;

    my($cmd_tmpl, $cmd_param) = $self->collect_oozie_cmd_args;

    # Are we alone or do we need to kill our brothers and sisters?
    $self->check_current_instances;

    Template->new
            ->process(
                \join( SPACE_CHAR, @{ $cmd_tmpl } ),
                $cmd_param,
                \my $command,
            );
    my $success = $self->execute( $command );
    if(!$success){
        return $success;
    }
    # go back where we started!
    chdir $CWD if $CWD;


    $logger->info(
        sprintf 'Completed successfully in %s (took %s)',
                    sprintf( '%s%s', $self->cluster_name, ( $self->dryrun ? ' (dryrun is set)' : EMPTY_STRING ) ),
                    duration_exact( time - $run_start_epoch ),
    );

    return $success;
}

sub collect_oozie_cmd_args {
    my $self   = shift;
    my $logger = $self->logger;

    my @extra_oozie_args;

    my @define = @{ $self->define };

    my %extra_def = ();
    # We are not supporting sla for bundles (yet)
    if ( !($self->type eq 'bundle') ) {
      %extra_def = (
          $self->verify_sla,
      );
    }

    if ( $self->type eq 'wf' ) {
        %extra_def = (
            %extra_def,
            $self->check_coordinator_function_calls({
                map { (split m{ [=] }xms, $_)[0] => 1 } @define
            }),
        );
    }

    if (@{ $self->errors } ) {
        $logger->error(
            'Overridable errors encountered',
            ( $self->force ? EMPTY_STRING : ' (relaunch using --force to proceed)' )
        );
        $logger->error( '- ' . $_ ) for @{ $self->errors };
        die if !$self->force && !$self->dryrun;
    }

    my $hash_to_def = sub {
        my($h, $no_quote) = @_;
        my $tmpl = $no_quote ? q{-D%s=%s} : q{-D'%s=%s'};
        map { sprintf $tmpl, $_, $h->{$_} } keys %{ $h }
    };

    # IMPORTANT ! keep this in sync with the sudoers file,
    # if you have a corresponding setting in such a place

    my %def = (
        appName                             => '[% app_name      %]',
        startTime                           => '[% start_time    %]',
        endTime                             => '[% end_time      %]',
        workflowPath                        => '[% workflow_path %]',
        'oozie.[% type %].application.path' => '[% workflow_path %]',
        path                                => '[% path %]',
        nameNode                            => '[% name_node     %]',
        'oozie.use.system.libpath'          => 'true',
        ( @define ? ( map { split m{ [=] }xms, $_, 2 } @define ) : () ),
    );

    my %prop  = $self->probe_settings;
    my %owner = $self->probe_meta;

    $self->logger->info( 'Combining owner info into job.properties' );

    my $override_file = File::Temp->new(
                            SUFFIX => '.properties',
                            DIR    => resolve_tmp_dir(),
                        );
    my $original = EMPTY_STRING;
    my $orig_filename = 'job.properties';

    if ( open my $ORIG_FH, '<', $orig_filename ) {
        local $/;
        $original = <$ORIG_FH>;
        if ( ! close $ORIG_FH ) {
            $logger->warn(
                sprintf 'Failed to close %s: %s',
                            $orig_filename,
                            $!,
            );
        }
    }

    $override_file->print( $original, "\n\n" );

    my $c = Config::Properties->new( be_like_java => 1 );
    for my $var ( keys %owner ) {
        $c->setProperty( $var => $owner{ $var } );
    }

    $override_file->print( $c->saveToString );

    my @args = (
        $hash_to_def->( \%def ),
        $hash_to_def->( \%extra_def ),
        @extra_oozie_args,
        '-config' => $override_file,
        ($self->doas ? (-doas => $self->doas) : ()), #impersonation
    );

    # These can't be set in the list above, because of Oozie requiring them
    # to be set before the sub-command as otherwise they become no-op.
    # You gotta love the Hadoop stack.
    #
    # This in turn also requires yet another sudoers template, so be careful
    # with this and contact the BigData Team if you need something to be
    # changed in this section.
    #

    # IMPORTANT! the order matters for this section for sudoers if you have a corresponding setting.
    my @username_override = $prop{username_override}
        ? (
            $hash_to_def->({ 'oozie.auth.token.cache' => 'false'                  }, 1),
            $hash_to_def->({ 'user.name'              => $prop{username_override} }, 1),
            )
        : ();

    if ( $self->type eq 'bundle' && $self->dryrun ) {
        die 'Oozie does not support dryrun for bundles. We will stop now!';
    }

    my @cmd_tmpl = (
        ( $self->secure_cluster
            ? ()
            : ( $self->execute_as_someone_else
                    ? ( qw[ sudo -u ], $self->username )
                    : ()
                )
        ),
        $self->oozie_cli,
        ($self->secure_cluster ? ($hash_to_def->({ 'oozie.auth.token.cache' => 'false'}, 1)) : ()),
        @username_override,
        job => ( $self->dryrun ? '-dryrun' : '-run' ),
        @args,
    );

    if ( $self->notify ) {
        # TODO: check if this whole section can be removed
        my %ndef =  map {
                        $_ => $prop{ $_ }
                    }
                    grep {
                        m{ notification[.]url }xms
                    }
                    keys %prop
                    ;

        #if ( ! %ndef ) {
        #    die "--notify is set but the required settings are not in your configuration";
        #}

        push @cmd_tmpl, $hash_to_def->( \%ndef );
    }

    push @cmd_tmpl,'-oozie=[% oozie_uri %]';

    my $end_time   = $prop{endTime}
                        || sprintf FORMAT_ZULU_TIME,
                                    map { $self->$_ }
                                    qw(
                                        enddate
                                        endhour
                                        endmin
                                    );

    my $start_time = $prop{startTime}
                        || sprintf FORMAT_ZULU_TIME,
                                    map { $self->$_ }
                                    qw(
                                        startdate
                                        starthour
                                        startmin
                                    );

    my $nameNode = $prop{nameNode} || $self->template_namenode;

    my %cmd_param = (
        app_name      => $self->appname,
        end_time      => $end_time,
        name_node     => $nameNode,
        oozie_uri     => $self->oozie_uri,
        start_time    => $start_time,
        type          => $self->type,
        workflow_path => $self->path . ($self->type eq 'bundle'? '/bundle.xml' : EMPTY_STRING) ,
        path          => $nameNode . $self->path,
    );

    return \@cmd_tmpl, \%cmd_param;
}

sub verify_sla {
    my $self = shift;
    my %rv;

    # check the SLA parameter is provided if the workflow has an SLA block
    eval {
        my $raw  = $self->hdfs->read(
                        File::Spec->catfile( $self->path, 'workflow.xml' )
                    );
        if ( $raw =~ m{ sla[:]info }xms ) {
            if ( ! $self->sla_duration ) {
                die 'The workflow contains an SLA block, please provide an --sla-duration parameter in minutes';
            }
            %rv = (
                slaDuration    => $self->sla_duration,
                slaEmailErrors => 'duration_miss',
            );
        }
        elsif ( $self->sla_duration ) {
            die q{You've specified an SLA duration, but the workflow does not contain the sla:info block! There will be no SLA events};
        }
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        die sprintf 'Cannot retrieve the workflow.xml off HDFS; did you deploy the workflow? %s', $eval_error;
    };

    return %rv;
}

sub check_current_instances {
    my $self = shift;
    my $logger = $self->logger;
    $logger->info( 'Duplicates check' );

    if ( $self->type eq 'wf' ) {
        $logger->warn( q{Please note that this program doesn't check the existence of duplicate workflows yet, only coordinators} );
        return;
    }

    my @running = @{
        $self->oozie->coordinators(
            filter => {
                name   => $self->appname,
                status => [ OOZIE_STATES_RUNNING ],
            }
        )->{coordinatorjobs} || []
    };

    return if !@running;

    $logger->warn( 'There are coordinator(s) already running under the same name on the server.' );

    my $meta_tmpl = <<'META';

* coordinator: %s
  start date : %s
  frequency  : %s %s
  console URL: %s

META

    my @other_instances;
    for my $job (@running) {
        my $meta = sprintf $meta_tmpl,
                        @{ $job }{qw/
                                toString
                                startTime
                                frequency
                                timeUnit
                                consoleUrl
                        /};


        $logger->warn( $meta );
        push @other_instances, $job->{coordJobId};
    }

    $logger->warn(
        sprintf 'Detected %s active coordinator(s) with the name `%s`',
                    scalar @other_instances,
                    $self->appname,
    );

    my $is_killed;
    if (!$self->dryrun && @other_instances) {
        my $yesno = 'N';
        if ( is_interactive() ) {
            printf "Do you want to kill the duplicate coordinator(s)? Ids: '%s' [yN]: \n",
                        join( q{', '}, @other_instances ),
            ;
            $yesno = <STDIN>;
            chomp $yesno;
        }
        else {
            $logger->warn( 'Not running interactively and there are other instances. The next calls will fail.' );
        }

        my $outbuffer;
        if ( lc $yesno eq 'y' ) {
            for (@other_instances) {
                $logger->info( "Killing oozie coordinator $_" );

                my $command = [
                    ( $self->secure_cluster
                        ? ()
                        : ( $self->execute_as_someone_else
                                            ? ( qw[ sudo -u ], $self->username )
                                            : ()
                            )
                    ),
                    $self->oozie_cli,
                    ($self->secure_cluster ? ('-Doozie.auth.token.cache=false') : ()),
                    job => -kill => $_,
                    (-oozie => $self->oozie_uri),
                    ($self->doas ? (-doas => $self->doas) : ()), #impersonation
                ];

                IPC::Cmd::run(
                    command => $command,
                    verbose => $self->verbose,
                    buffer  => \$outbuffer,
                    timeout => $self->timeout,
                ) or do {
                    $logger->error( "Error encountered when trying to kill old instance $_" );
                    die sprintf 'Error: %s', $outbuffer // '[unknown]';
                };
                $is_killed++;
            }
            $logger->info( 'Coordinator(s) are now killed' );
        }
    }

    push @{ $self->errors }, 'At least one coordinator running under the same name' if ! $is_killed;

    return;
}

sub check_coordinator_function_calls {
    my $self = shift;
    my $skip = shift;
    my $logger = $self->logger;
    # try to predict the value of such things?
    # examples:
    #    ${coord:formatTime(coord:nominalTime(), 'yyyy-MM-dd')}
    #    ${coord:formatTime(coord:nominalTime(), 'HH')}
    #
    my $looks_like_coord_conf = qr< [$][{]coord[:] >xms;
    my %missing;
    my $collector = sub {
        my($h, $key) = @_;
        return if $key ne 'property';
        my $slot = $h->{ $key };
        #
        # this is possibly broken for some cases
        # as it tries to locate stuff in the hairy xml
        # which can be defined in different ways.
        # need to be fixed / extended per wf
        #
        foreach my $name ( keys %{ $slot } ) {
            if ( ! is_hashref $slot->{ $name } ) {
                if (   exists $slot->{name}
                    && exists $slot->{value}
                    && $slot->{value} =~ $looks_like_coord_conf
                ) {
                    $missing{ $slot->{name} } = $slot->{value};
                }
                next;
            }

            next if exists $slot->{ $name }{ action };

            if ( my $val = $slot->{ $name }{ value } ) {
                next if $val !~ $looks_like_coord_conf;
                $missing{ $name } = $val;
                next;
            }
        }
    };

    my $loop_xml_conf_hash;
    $loop_xml_conf_hash = sub {
        my $hash = shift;
        my $cb   = shift;
        foreach my $key ( keys %{ $hash } ) {
            $cb->( $hash, $key );
            my $value = $hash->{ $key };
            $loop_xml_conf_hash->( $value, $cb ) if is_hashref $value;
        }
        return;
    };

    foreach my $conf ( qw(
        workflow.xml
        coordinator.xml
    )) {
        my $abs_path = File::Spec->catfile($self->path, $conf );
        my $raw;
        eval {
            $raw = $self->hdfs->read( $abs_path );
            if ( ! $raw ) {
                my $msg = 'Could not read the workflow file in HDFS: '
                        . 'did you do the deploy first? No data for: %s'
                        ;
                $logger->logdie( sprintf $msg, $abs_path );
            }
            my $xs = XML::LibXML::Simple->new;
            my $oozie_conf = $xs->XMLin( \$raw );
            $loop_xml_conf_hash->( $oozie_conf, $collector );
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';
            my $log_level = $conf =~ m{ workflow }xms ? 'logdie' : 'warn';
            $logger->$log_level( $eval_error );
            1;
        };
    }

    return if ! %missing;

    my @vars = sort {  lc $a cmp lc $b } grep { ! $skip->{ $_ } } keys %missing;

    if ( ! @vars ) {
        my $what = join ', ', sort keys %missing;
        $self->logger->info( sprintf 'The missing coordinator variables (%s) were manually defined. Skipping ...', $what );
        return;
    }

    my $fyi = join SPACE_CHAR, map { "--define '$_=value'" } @vars;

    print <<"DEFINE";
The oozie workflow you are trying to run has several coordinator function
dependencies in it's configuration, but since you've wanted to execute it as
as type=workflow, they won't be defined and the oozie job will either fail
or won't be launched at all. I will now ask you to enter the values for these
variables manually. Alternatively, you can exit this program now and execute
again with defining the parameters with the `--define` parameter. For example:

    $0 $fyi

You can [ctrl]+c to kill this program at this point to exit without doing anything.

DEFINE

    my %rv;
    foreach my $name ( @vars ) {
        print q{-} x TERMINAL_LINE_LEN, "\n";
        print "\t$name:\t$missing{$name}\n\n";
        my $value = $self->ask( $name );
        next if ! defined $value;
        $rv{ $name } = $value;
    }

    return %rv;
}

sub collect_properties {
    my $self = shift;
    my %rv;

    my $orig_filename = 'job.properties';

    my $properties = Config::Properties->new;
    open my $FH, '<', 'job.properties' or die 'Cannot open job.properties';
    $properties->load($FH);
    if ( ! close $FH ) {
        $self->logger->warn(
            sprintf 'Failed to close %s: %s',
                        $orig_filename,
                        $!,
        );
    }

    if ( my $uname = $properties->getProperty('user.name') ) {
        $self->logger->info( "Collected user.name override = $uname" );
        $rv{username_override} = $uname;
    }

    foreach my $name ( qw(
        oozie.coord.application.path
        oozie.wf.application.path

        oozie.wf.action.notification.url
        oozie.wf.workflow.notification.url
        oozie.coord.action.notification.url

        startTime
        endTime
    ) ) {
        my $val = $properties->getProperty( $name ) || next;
        if ( is_ref $val ) {
            require Data::Dumper;
            my $d = Data::Dumper->new([ $val ], [ $name ]);
            $self->logger->logdie(
                sprintf 'You seem to have a double definition in %s for %s as %s',
                            'job.properties',
                            $name,
                            $d->Dump,
            );
        }
        $rv{ $name } = $val;
    }

    return %rv;
}

sub probe_settings {
    my $self = shift;

    # Check we don't have a coordinator/application path already.
    my %prop = $self->collect_properties;

    if (   $prop{'oozie.coord.application.path'}
        || $prop{'oozie.wf.application.path'}
    ) {
        die join "\n",
                EMPTY_STRING,
                '==> ERROR! the file job.properties specifies an oozie.(coord|wf).application.path!',
                'Please remove or comment it, and check the --path option if needed',
                EMPTY_STRING,
    }

    if ( $self->dates_from_properties ) {
        foreach my $tp ( qw( startTime endTime ) ) {
            next if $prop{ $tp };
            die "--dates-from-properties is set but there is no $tp in job.properties";
        }
    }

    return %prop;
}

sub ask {
    my $self = shift;
    my $var = shift;
    my $msg = "Please enter the new value for `$var` based on the definition above";
    my($input, $count);
    while ( 1 ) {
        if ( ++$count > MAX_RETRY ) {
            print "\tYou didn't specify anything 3 times, so I give up! ($var=undef)\n";
            last;
        }
        print "$msg: ";
        chomp($input = <STDIN>);
        if ( $input eq EMPTY_STRING ) {
            print "Nothing specified!\n";
            next;
        }
        last;
    }

    if ( $input ne EMPTY_STRING ) {
        print "\t$var will be set to '$input'\n";
    }

    return $input;
}

sub execute {
    my $self    = shift;
    my $command = shift;
    my $logger  = $self->logger;
    my $verbose = $self->verbose;
    my $outbuffer;

    if ( ! $self->dryrun ) {
        $logger->info( 'Executing the command to schedule' );

        my ($ok, $err, $full_buf, $stdout_buff, $stderr_buff);
        ($ok, $err, $full_buf, $stdout_buff, $stderr_buff)  = IPC::Cmd::run(
            command => $command,
            verbose => 1,
            buffer  => \$outbuffer,
            timeout => $self->timeout,
        );

        if ( ! $ok ) {
            $logger->fatal( $err );
            return 0;
        }

        if ( is_arrayref $stderr_buff && @{ $stderr_buff } ) {
            $logger->warn( join "\n", @{ $stderr_buff } );
        }

        ($outbuffer) = reverse
                        map {
                            split m{ \n }xms, $_
                        }
                        @{ $stdout_buff }
                        ;

        if (
            # TODO: move to constant
            $outbuffer =~ m{
                ([0-9-]+ oozie-oozi- [CWB])
            }xms
        ) {
            my $job_id =  $1;
            $self->log_console_url( $job_id );
        }
        else {
            $logger->warn( 'Failed to locate the Oozie job id from the system call' );
        }

        return 1;
    }

    my $type = $self->type;
    my @info = (
        'Running oozie --dryrun for your command',
        sprintf( 'This will dryrun or test run a %s job, no job will be queued or scheduled ', $type ),
    );
    push @info, 'In case of --type=wf you will only get an OK in case of success' if $type eq 'wf';
    push @info, 'oozie --dryrun Output START';

    $logger->info( $_ ) for @info;

    IPC::Cmd::run(
        command => $command,
        verbose => 1,
        buffer  => \$outbuffer,
        timeout => $self->timeout,
    ) or do {
        $logger->fatal( sprintf 'Error encountered when trying to dryrun the new %s!!!', $type );
        $logger->fatal( 'oozie response: ' . $outbuffer );
        $logger->info( 'oozie --dryrun Output END' );
        return 0;
    };

    $logger->info( 'oozie response: ' . $outbuffer );
    $logger->info( 'oozie --dryrun Output END' );

    return 1;
}

sub log_console_url {
    my $self   = shift;
    my $job_id = shift;
    $self->logger->info( sprintf 'Console URL: %s?job=%s', $self->oozie_uri, $job_id );
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Run

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use App::Oozie::Run;
    App::Oozie::Run->new_with_options->run;

=head1 DESCRIPTION

For this to work, the coordinator.xml and workflow.xml must make

    <coordinator-app timezone="UTC" xmlns="uri:oozie:coordinator:0.1"
        name      = "${appName}"
        frequency = "${if frequency}"
        start     = "${startTime}"
        end=      = "${endTime}"
        >
        <action>
            <workflow>
                <!-- HDFS base dir -->
                <app-path>${workflowsBase}/${appName}</app-path>
            </workflow>
        </action>
    </coordinator-app>

=head1 NAME

App::Oozie::Run - Schedule Oozie Coordinators and Workflows.

=head1 Methods

=head3 ask

=head3 check_coordinator_function_calls

=head3 check_current_instances

=head3 collect_oozie_cmd_args

=head3 collect_properties

=head3 execute

=head3 log_console_url

=head3 probe_settings

=head3 run

=head3 setup_dates

=head3 verify_sla

=head1 Accessors

=head2 Overridable from cli

=head3 appname

=head3 dates_from_properties

=head3 define

=head3 doas

=head3 enddate

=head3 endhour

=head3 endmin

=head3 notify

=head3 path

=head3 sla_duration

=head3 startdate

=head3 starthour

=head3 startmin

=head3 type

=head2 Overridable from sub-classes

=head3 basedir

=head3 errors

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
