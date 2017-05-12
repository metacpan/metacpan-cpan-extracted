#!/usr/bin/perl

use strict;
use warnings;

use Activator::Registry;
use Activator::Config;
use Activator::Log qw( :levels );
use Exception::Class::TryCatch;
use Data::Dumper;
use Template;
use File::Find;

=head1 NAME

activator.pl - setup and manage services with an Activator project.

=head1 SYNOPSIS

activator.pl [OPTIONS] ACTION project-name

 Actions
  sync : sync user codebase to target install base

 Options:
  --restart : (re)start the webserver after performing <ACTION>
  --log_level : One of TRACE, DEBUG, INFO, WARN, ERROR, FATAL (see L<Activator::Log>)
  --sync_dir : ignore sync_dir setting from configuration, use this.

 Todo:
  --activator_codebase=<path> : use alternate Activator codebase (for Activator development)

See L<Activator::Tutorial> for a description of how to configure an Activator project.

=cut

# $config, $args, $project, $action and the current apache pid are globally interesting
my ( $config, $args, $project, $action, $httpd_pid );

try eval {
    # Act::Config requires that project be set via an option or be the
    # last arg, hence the flag after undef below
    $config = Activator::Config->get_config( \@ARGV, undef, 1 );
};

if ( catch my $e ) {
    die( "Error while processing command line options: $e" );
}

my $log_level = $config->{log_level} || 'WARN';
if ( $config->{v} || $config->{verbose} ) {
    Activator::Log->level( 'INFO' );
}

$action  = $ARGV[-2];
$project = $ARGV[-1];

if ( $action eq 'sync' ) {
    &sync( $project );
}
else {
    ERROR("'$action' action not supported");
    exit(1);
}

if ( $config->{restart} ) {
    &restart( $project );
}

sub sync {
    my $project = shift;

    if ( $config->{sync_target} eq '/' ) {
	ERROR( "target sync_dir is root dir! Refusing to continue this DANGEROUS operation");
	exit(1);
    }


    my $cmd;

    # before blowing away the run dir, grab the httpd pid and store it globally
    if ( -f $config->{apache2}->{PidFile}) {
	INFO("Looking for pid file...");
	$cmd = 'cat '. $config->{apache2}->{PidFile};
	INFO( $cmd );
	$httpd_pid = `$cmd`;
	chomp $httpd_pid;
    }

    # convenience vars
    my $project_codebase = $config->{project_codebase};
    my $perl5lib      = $config->{apache2}->{PERL5LIB};
    my $document_root = $config->{apache2}->{DocumentRoot};
    my $server_root   = $config->{apache2}->{ServerRoot};

    my $rsync_flags = ( $config->{debug} ? '-v' : '' );
    $rsync_flags   .= ' --cvs-exclude';

    # these commands need to run to create the target installation
    my @cmds = (
		# blow away the target dir
		"rm -rf $config->{sync_target}",

		"mkdir -p $config->{sync_target}",
		"mkdir -p $config->{sync_run_dir}",
		"mkdir -p $config->{sync_lock_dir}",
		"mkdir -p $config->{sync_conf_dir}",
		"mkdir -p $config->{sync_log_dir}",

		"mkdir -p $perl5lib",
		"mkdir -p $document_root",
		"mkdir -p $server_root/logs",

		# all your perl lib are belong to PERL5LIB
		"rsync -a $rsync_flags $project_codebase/lib/* $perl5lib",

		# symlink template files so we don't have to restart server
		# not that this symlinks INTO document root
		"ln -sf $project_codebase/root $document_root",

		# symlink apache modules
		"ln -sf /usr/lib/httpd/modules $server_root",

		# symlink apache log files
		"ln -sf $server_root/logs $config->{sync_log_dir}/httpd",

	       );


    if ( $config->{activator_codebase} ) {
	push @cmds,
	  "rsync -a $rsync_flags ".$config->{activator_codebase}."/lib/* $perl5lib";
    }

    if ( $config->{sync_data_dirs} ) {
	foreach my $dir ( @{ $config->{sync_data_dirs} } ) {
	    push @cmds, "mkdir -p $dir";
	}
    }

    if ( my $dict_targ = $config->{Activator}->{Dictionary}->{dict_files} ) {
	push @cmds, "ln -sf $config->{conf_path}/dict $dict_targ";
    }
    
    foreach $cmd ( @cmds ) {
	DEBUG( $cmd );
	die "$cmd failed" unless !system( $cmd );
    }

    # TODO: abstract this out such that we can process any number of
    # configured directories. Since this is running under the apache
    # engine, we know to process the share/apache/ config.
    #
    # TODO: make activator_codebase NOT be required: When activator
    # installs, it should look for the share directory.
    #
    find( \&process, "$config->{activator_codebase}/share/apache2" );


    # process configuration files

    my $config_files = $config->{sync_config_files};

    my $reg = Activator::Registry->new();
    foreach my $config_file ( @$config_files ) {
	DEBUG( "processing config file: $config_file");
	my $fq_source_file = "$config->{conf_path}/$config_file";
	my $fq_dest_file   ="$config->{sync_conf_dir}/$config_file";

	if ( $config_file =~ /\.ya?ml$/i ) {

	    # Read the project registry and catalyst configuration files and
	    # do variable replacements. We do this by kinda cheating: load the
	    # yml into a special registry realm (named after the file), and
	    # since it is a hash, do a YAML dump of that hash.
	
	    try eval {
		# load the yml into a realm named after the file
		$reg->register_file( $fq_source_file, $config_file );

		# do replacments
		$reg->replace_in_realm( $config_file, $config );

		$YAML::Syck::SingleQuote = 1;
		DEBUG( qq(dumping config: $fq_dest_file, ). $reg->get_realm( $config_file ) );
		YAML::Syck::DumpFile( $fq_dest_file,
				      # get realm returns a hashref
				      $reg->get_realm( $config_file ) );
	    };
	    if ( catch my $e ) {
		WARN( "Couldn't process YAML file '$config_file': $e");
	    }
	}

	# if it's a template process it based on the current config.
	elsif ($config_file =~ /\.tt$/i ) {
	    $config_file =~ /(.+)\.tt$/;
	    my $out = $1;
	    if ( !$out ) {
		WARN( "Couldn't process Template file '$config_file'");
		next;
	    }
#	    $fq_dest_file = "$config->{sync_conf_dir}/$out";
	    my $tt = Template->new( { DEBUG => 1,
				      ABSOLUTE => 1,
				      OUTPUT_PATH  => $config->{sync_conf_dir},
				    }
				  );
	    DEBUG( qq(tt processing: $fq_source_file, $config, $out ));
	    $tt->process( $fq_source_file, $config, $out ) || Activator::Log->logdie( $tt->error()."\n");
	}

	# just copy the file
	else {
	    my $rsync_flags = ( $config->{debug} ? '-v' : '' );
	    $rsync_flags   .= ' --cvs-exclude';
	    my $cmd = "rsync -a $rsync_flags $fq_source_file $fq_dest_file";
	    die "$cmd failed" unless !system( $cmd );
	}
    }
    &restart();
}

sub restart {

    my $httpd_conf = $config->{apache2}->{ServerRoot} . '/conf/httpd.conf';
    if ( !-f $httpd_conf ) {
	Activator::Log->logdie( "apache config not found: '$httpd_conf'");
    }

    my $httpd_pid = $config->{apache2}->{PidFile};

    my $cmd;

    if ( $httpd_pid && $httpd_pid =~ /^\d+$/ ) {
	INFO("killing pid '$httpd_pid' from pid file");
	system( "kill $httpd_pid");
    } else {
	INFO("Looking for pid from ps");
	$cmd = qq(ps -C httpd -opid,user,command | grep '$ENV{USER}' | grep '$project');
	INFO( $cmd );

	my @outp = split /\n/, `$cmd`;
	my @pids;
	foreach my $line ( @outp ) {
	    $line =~ /^\s*(\d+)\s/;
	    push @pids, $1 if $1;
	}
	if ( @pids ) {
	    INFO("Killing from ps");
	    $cmd = 'kill ' . join ' ', @pids;
	    DEBUG( $cmd );
	    system( $cmd );
	} else {
	    INFO("Nothing to kill: can't find any 'httpd's running");
	}
    }

    INFO("Sleeping to allow children to exit");
    $| = 1;
    foreach ( 1..3 ) {
	print ".";
	sleep(1);
    }
    print "\n";
    $cmd = "/usr/sbin/httpd -f $httpd_conf";
    INFO("Starting apache");
    DEBUG("...with command: $cmd");
    system( $cmd );

}

# TODO: this should process anything, not just apache2 files
sub process {
    my $dir  = $File::Find::dir; # is the current directory name,
    my $file = $_;               # is the current filename within that directory
    my $fq   = $File::Find::name; # is the complete pathname to the file.

    # capture the intervening path
    $fq =~ m|share/apache2/(.+)\.tt$|;
    my $out = $1;
    return unless $out;

    DEBUG( qq( processing $file into ).$config->{apache2}->{ServerRoot}.'/'.$out );
    my $tt = Template->new( { DEBUG => 1,
			      ABSOLUTE => 1,
			      OUTPUT_PATH  => $config->{apache2}->{ServerRoot},
			    }
			  );
    $tt->process( $fq, $config, $out ) || Activator::Log->logdie( $tt->error()."\n");

    # TODO: use some smart hueristics to properly chmod that which
    # should be executable
    #
    #if( $out =~ m@/s?bin/|/init.d/@ ) {
    #	chmod 0755, $config->{apache2}->{ServerRoot}.'/'.$out
    #}
}

# copy the default project config for a catalyst app to the correct
# place, setting project_name, project_alias, domain_name.
sub init {

    use Cwd;
    DEBUG( getcwd );


}
