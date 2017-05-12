package Activator::Config;

use Data::Dumper;
use Activator::Registry;
use Activator::Log qw( :levels );
use Scalar::Util qw( reftype );
use Exception::Class::TryCatch;
use base 'Class::StrongSingleton';

=head1 NAME

C<Activator::Config> - provides a merged configuration to a script
combining command line options, environment variables, and
configuration files.

=head1 SYNOPSIS

  use Activator::Config;

  my $config = Activator::Config->get_config( \@ARGV);  # default realm
  my $config = Activator::Config->get_config( \@ARGV, $otherrealm);

  #### Get a hashref of command line arguments, and an arrayref of bareword arguments
  my ( $config, $args ) = Activator::Config->get_args( \@ARGV );

=head1 DESCRIPTION

This module allows a script or application to have a complex
configuration combining options from command line, environment
variables, and YAML configuration files.

For a script or application, one creates any number of YAML
configuration files. These files will be deterministically merged into
one hash. You can then pass this to an application or write it to file.

This module is not an options validator. It uses command line options
as overrides to existing keys in configuration files and DOES NOT
validate them. Unrecognized command line options are ignored and
C<@ARGV> is modified to remove recognized options, leaving barewords
and unrecognized options in place and the same order for a real
options validator (like L<Getopt::Long>). If you do use another
options module, make sure you call C<get_config()> BEFORE you call
their processor, so that C<@ARGV> will be in an appropriate state.

Environment variables can be used to act as a default to command line
options, and/or override any top level configuration file key which is
a scalar.

This module is cool because:

=over

=item *

You can generate merged, complex configuration heirarchies that are
context sensitive very easily.

=item *

You can pass as complex a config as you like to any script or
application, and override any scalar configuration option with your
environment variables or from the command line.

=item *

It supports realms, allowing you to have default configurations for
development, QA, production, or any number of arbitrary realms you
desire. That is, with a simple command line flag, you can switch
your configuration context.

=back

=head2 Configuration Source Precedence

The precedence heirarchy for configuration from highest to lowest is:

=over

=item *

command line options

=item *

environment variables

=item *

forced overrides from config files

=item *

merged settings from YAML configuration files

=back

=head1 COMMAND LINE ARGUMENTS

This module allows you to override configuration file settings from
the command line. You can use long or short options using C<'-'> or
C<'--'> notation, allows barewords in any order, and recognizes the
arguments terminator C<'--'>. Also supported are multiple flag
arguments:

  #### turn on super verbosity. sets $config->{v} = 2
  myscript.pl -v -v

You can specify configured options at the command line for
override:

  #### override the configuration file setting for 'foo'
  myscript.pl --foo=bar

Note that while YAML configuration (and this module) support deep
structures for configuration, you can only override top level keys
that are scalars using command line arguments and/or environment
variables.

=head2 Reserved Arguments

There are a few reserved command line arguments:

 --skip_env        : ignore environment variables (EXCEPT $USER)
 --project=<>      : used to search for the C<E<lt>projectE<gt>.yml> file
 --realm=<>        : use C<E<lt>realmE<gt>.yml> in config file processing and
                     consider all command line arguments to be in this realm
 --conf_path       : colon separated list of directories to search for config files

=head2 Project as a Bareword Argument

There are times where a script takes the project name as a required
bareword argument. For these cases, require that project be the last
argument, and pass a flag to L</get_config()>. 

That is, when your script is called like this:

  myscript.pl --options <project>

get the config like this:

  Activator::Config->get_config( \@ARGV, undef, 1 );

The second argument to L</get_config()> is the realm, so you pass
C<undef> (unless you know the realm you are looking for) to allow the
command line options and environment variables to take affect.

=head1 ENVIRONMENT VARIABLES

Environment variables can be used to act as a default to command line
options, and/or override any top level configuration file key which is
a scalar. The expected format is C<ACT_CONFIG_[key]>. Note that YAML is
case sensitive, so the environment variables must match. Be especially
wary of command shell senstive characters in your YAML keys (like
C<:~E<gt>E<lt>|>).

If you wish to override a key for only a particular realm, you
can insert the realm into the env variable wrapped by double
underscores:

 ACT_CONFIG_foo       - set 'foo' for default realm
 ACT_CONFIG__bar__foo - set 'foo' only for 'bar' realm

The L</Reserved Arguments> listed in the L</COMMAND LINE ARGUMENTS>
section also have corresponding environment variables with only
C<skip_env> being slightly different:

 ACT_CONFIG_skip_env     : set to 1 to skip, or 0 (or don't set it at all) to
                        not skip
 ACT_CONFIG_project      : same as command line argument
 ACT_CONFIG_realm        : same as command line argument
 ACT_CONFIG_conf_path    : same as command line argument

=head2 Automatically Imported Environment Variables

Since they tend to be generally useful, the following environment
variables are automatically imported into your configuration:

=over

=item *

HOME

=item *

USER

=back

it is L</FUTURE WORK> to make these cross-platform compatible.

=head1 CONFIGURATION FILES

Currently, you can put your YAML configuration file wherever you like,
but you must set a key inside your configuration files C<conf_path>,
then set the environment variable C<ACT_CONFIG_conf_path> or use the
C<--conf_path> option. It is somewhat wonky the way this currently
works, and it'll get fixed Real Soon Now.

This path behaves the same as a bash shell C<$PATH>, in that you can
set this to one or more colon separated fully qualified path values.
Note that the leftmost path takes precedence when processing config
files.

=head2 Configuration File Heirarchy

In order to facilite the varied ways in which software is developed,
deployed, and used, the following heirarchy lists the configuration
file heirarchy suported from highest precedence to lowest:

  $ENV{USER}.yml - user specific settings
  <realm>.yml    - realm specific settings and defaults
  <project>.yml  - project specific settings and defaults
  org.yml        - top level organization settings and defaults

It is up to the script using this module to define what C<project> is,
and up to the project to define what realms exist, which all could
come from any of the command line options, environment variables or
configuration files. All of the above files are optional and will be
ignored if they don't exist.

=head2 Realm Configuration Files

This module supports the concept of realms to allow multiple similar
configurations to override only the esential keys. This allows you to
have a very large default project configuration file, and for each
realm a very small configuration file overriding only the few keys
that vary between realms (db connection, email defaults, apache
settings, cookie domain for example).

A common configuration directory will have the following files:

  <user>.yml files
  qa.yml
  dev.yml
  prod.yml

Using the C<--realm> option or C<ACT_CONFIG_realm> environment variable
set to qa, dev or prod will cause I<realm>.yml to be used during
configuration file processing in addition to any I<realm> specific
keys in any other config files being utilized.

=head1 CONFIGURATION FILE FORMAT

The format for configuration files is YAML. In addition to YAML's
requirements, you must define top level relams within your YAML files.

When passing a realm to L</get_config()> (or via the C<--realm>
command line argument), values for the realm take precedence over the
default realm's values. For example, given YAML:

  default:
    key1: value1
  realm:
    key1: value2

C<Activator::Config-E<gt>get_config( \@ARGV )> would return:

$config = { key1 => value1 }

and C<Activator::Config-E<gt>get_config( \@ARGV, 'realm' )> would return:

$config = { key1 => value2 }

=head2 Overrides Format

Sometimes it is desireable to override the generated value after
merging several configuration files. There is support for the special
realm C<overrides> can be utilzed in these cases, and will stomp any
values that come from YAML configurations. For example, given YAML:

  default:
    name: David Davidson from Deluth, Delaware
  some_realm:
    name: Sally Samuelson from Showls, South Carolina
  other_realm:
    name: Ollie Oliver from Olive Branch, Oklahoma
  overrides:
    default:
      name: Ron Johnson from Ronson, Wisconson
    some_realm:
      name: Johnny Jammer, the Rhode Island Hammer

C<Activator::Config-E<gt>get_config( \@ARGV )> would return:

  $config = { name => 'Ron Johnson from Ronson, Wisconson', }

C<Activator::Config-E<gt>get_config( \@ARGV, 'some_realm' )> would return:

  $config = { name => 'Johnny Jammer, the Rhode Island Hammer' }

C<Activator::Config-E<gt>get_config( \@ARGV, 'other_realm' )> would return:

  $config = { name => 'Ollie Oliver from Olive Branch, Oklahoma' }

=head2 How to NOT use realms

If you don't need realms for a particular config file (as is often the
case with the C<E<lt>projectE<gt>.yml> file), use the special key
C<act_config_no_realms>. Example:

  act_config_no_realms:
  this_key: is in the default realm
  this_one: too

=head1 CONFIGURATION LOGIC SUMMARY

=over

=item *

All configuration files are read and merged together with higher
precedence configuration files overriding lower precedence on a realm
by realm basis.

If identically named files exist in the C<conf_path> for any level
(user, realm, project, organization), only the first discovered file
is used. Put another way, the leftmost path in the C<conf_path> takes
precedence for any file name conflict.

=item *

The C<default> realm is merged into each realm (I<realm>'s values
taking precedence).

=item *

All C<default> realm environment variables override all values for
each I<realm> (excepting the C<overrides> realm).

=item *

All specific I<realm> environment variables override that realm's values.

=item *

The C<default> realm overrides section is used to override matching
keys in each I<realm>.

=item *

The specific I<realm> overrides section is used to override matching keys
in I<realm>.

=item *

Any command line options given override ALL matching keys for ALL realms.

=item *

# TODO: NOT YET IMPLEMENTED

Perform variable substitution

=back

=head1 METHODS

=cut

sub new {
    my ( $pkg ) = @_;

    my $self = bless( {
		       REGISTRY   => Activator::Registry->new(),
		       ARGV_EXTRA => {},
		       ARGV       => undef,
		       BAREWORDS  => undef,
		      }, $pkg);

    $self->_init_StrongSingleton();

    return $self;
}

=head2 get_config()

Process command line arguments, environment variables and
configuration files then return a hashref representing the merged
configuration. Recognized configuration items are removed from C<@ARGV>.

Usage:
  Activator::Config->get_config( \@ARGV, $realm, $project_is_arg );


C<$realm> is optional (default is 'default'). If undefined, it will be
determined from a command line option or environment variable.

C<$project_is_arg> is optional. Use any true value for this argument
if your script requries the project name as the last bareword
argument.

Examples:

  #
  # get options for default realm
  #
  my $config = Activator::Config->get_config( \@ARGV );

  #
  # get options for 'some' realm, ignoring --realm and ACT_CONFIG_realm
  #
  my $config = Activator::Config->get_config( \@ARGV, 'some' );

  #
  # don't ignore --realm and ACT_CONFIG_realm, use $barewords[-1] (the
  # last bareword argument) as the project
  #
  Activator::Config->get_config( \@ARGV, undef, 1 );

See L</get_args()> for a description of the way command line arguments
are processed.

If called repeatedly, this sub does NOT reprocess C<\@ARGV>. This
allows you to make multiple calls to get a reference to the config for
multiple realms if desired.

=cut

sub get_config {
    my ( $pkg, $argv, $realm, $project_is_arg ) = @_;
    my $self = &new( @_ );

    # get_args sets $self->{ARGV}
    $self->get_args( $argv );
    DEBUG( Data::Dumper->Dump( [ $self->{ARGV} ], [ qw/ ARGV / ] ) );
    DEBUG( Data::Dumper->Dump( [ $self->{BAREWORDS} ], [ qw /BAREWORDS/ ] ) );

    # make sure we can use ENV vars
    my $skip_env =  $ENV{ACT_CONFIG_skip_env};

    $realm ||=
      $self->{ARGV}->{realm} ||
	( $skip_env ? undef : $ENV{ACT_CONFIG_realm} ) ||
	  'default';

    if ( ref( $realm ) ) {
	Activator::Exception::Config->throw( 'realm_specified_more_than_once', Dumper( $realm ) );
    }

    if ( $realm ne 'default' ) {
	Activator::Registry->set_default_realm( $realm );
    }

    # setup or get the merged YAML configuration settings from files
    # into the registry
    my $config = $self->{REGISTRY}->get_realm( $realm );

    # first call
    if ( !keys %$config ) {
	# define valid config from config files
	try eval {
	    $self->_process_config_files( $realm, $skip_env, $project_is_arg );
	};
	if ( catch my $e ) {
	    $e->rethrow;
	}

	# read environment variables, set any keys found
	if ( !$skip_env ) {
	    my ( $env_key, $env_realm );
	    foreach my $env_key ( keys %ENV ) {
		next unless $env_key =~ /^ACT_CONFIG_(.+)/;
		$opt_key = $1;
		$opt_realm = $realm;

		my $env_opt_realm = $opt_realm;
		my $env_opt_key = $opt_key;
		if ( $opt_key =~ /^_(\w+)__(\w+)$/ ) {
		    $env_opt_realm = $1;
		    $env_opt_key = $2;
		    if ( $env_opt_realm eq $realm ) {
			$opt_key = $env_opt_key;
			$opt_realm = $env_opt_realm;
		    }
		}

		if ( $self->{REGISTRY}->get( $opt_key, $opt_realm ) ) {
		    $self->{REGISTRY}->register( $opt_key, $ENV{ $env_key }, $opt_realm );
		}
		elsif( $env_opt_realm ne $opt_realm &&
		      !grep( /$opt_key/, qw( skip_env project
					     realm conf_path ) ) ) {
		    WARN( "Skipped invalid environment variable $env_key.  Key '$opt_key' for realm '$opt_realm' unchanged");
		}
	    }
	}

	# forced overrides from config files
	my $overrides = $self->{REGISTRY}->get_realm( 'overrides' );
	DEBUG( Data::Dumper->Dump( [ $overrides ], [ 'processing overrides' ] ) );

	# NOTE: bad (typo) keys could be in overrides. Someday,
	# Activator::Registry will allow debug mode so we can
	# show this.
	if ( exists( $overrides->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'right', $overrides->{ $realm }, $realm );
	}

	# now that realm is set, make sure our $config points to it
	$config = $self->{REGISTRY}->get_realm( $realm );

	# Override any provided command line options into this realm.
	# Strips known options out of \@ARGV
	$self->_argv_override( $config, $argv );

	# inject some env variables that we support
	# TODO: make this cross-platform
	$config->{HOME} = $ENV{HOME};
	$config->{USER} = $ENV{USER};

	# feed the realm to itself for any self-defined variables
	$self->{REGISTRY}->replace_in_realm( $realm, $config );

	DEBUG( 'generated  ' . Data::Dumper->Dump( [ $config ], [ qw/ config / ] ) );
    }
    else {
	DEBUG( 'found ' . Data::Dumper->Dump( [ $config ], [ qw/ config / ] ) );
    }

    return $config;
}

=head2 get_args()

Takes a reference to a list of command line arguments (usually
C<\@ARGV>) and returns an arrayref consisting of an options hash, and
a barewords arrayref. C<$argv_raw> is not changed.

Usage: Activator::Config->get_args( $argv_raw )

=over

=item *

Arguments can be barewords, '-' notation or '--' notation.

=item *

Any arguments after the arguments terminator symbol (a plain '--'
argument) are returned as barewords. Bareword order of specification
is maintained.

=item *

Values with spaces must be double-quoted, and can themselves contain quotes

  --mode="sliding out of control"
  --plan="pump the "brakes" vigorously"

=item *

Flag arguments are counted. That is C<-v -v> would set C<$config-E<gt>{v} = 2>

=item *

Argument bundling is not supported.

=back

Examples:

  @ARGV                | Value returned
 ----------------------+-----------------------------------------
  --arg                | $argv = { arg => 1 }
  --arg --arg          | $argv = { arg => 2 }
  --arg=val            | $argv = { arg => 'val' }
  --arg=val --arg=val2 | $argv = { arg => [ 'val', 'val2' ] }
  --arg="val val"      | $argv = { arg => 'val val' }

Returns array: C<( $args_hashref, $barewords_arrayref )>

Throws C<Activator::Exception::Config> when arg is invalid (which at this
time is only when a barewod arg of '=' is detected).

=cut

sub get_args {
    my ( $pkg, $argv_raw ) = @_;
    my $self = &new( @_ );

    # quick and dirty check for debug mode
    if( grep /^--?debug$/, @$argv_raw ) {
	Activator::Log->level('DEBUG');
	DEBUG('Entering debug mode');
    }

    if ( defined( $self->{ARGV} ) || defined( $self->{BAREWORDS} ) ) {
	DEBUG("skipping ARGV reprocessing");
	return ( $self->{ARGV}, $self->{BAREWORDS} );
    }

    DEBUG("got ARGV: ". join(' ', @$argv_raw ));

    # use refs to insure that that $self->{ARGV} and
    # $self->{BAREWORDS} are defined, so we don't return undef.
    my $argv = {};
    my $barewords = [];
    my $found_terminator = 0;

    foreach my $arg ( @$argv_raw ) {
	my ( $key, $value ) = $self->_get_arg( $arg );

	if ( $found_terminator || !defined( $key ) ) {
	    DEBUG("'$arg' is a bareword or after the args terminator '--'");
	    push @$barewords, $arg;
            next;
	}

	if( $key eq '--' ) {
	    DEBUG("'$arg' is the terminator");
	    $found_terminator = 1;
	    next;
	}

        if ( defined $value ) {
	    DEBUG("got key '$key' = '$value'");

	    # if we see an argument again, coerce this value into an
	    # array
            if ( exists $argv->{ $key } ) {
		if ( reftype ( $argv->{ $key } ) eq 'ARRAY' ) {
		    DEBUG("added '$value' to key list '$key'" );
		    push @{ $argv->{ $key } }, $value;
		}
		else {
		    DEBUG("created key list '$key' and added '$value'" );
		  $argv->{ $key } = [ $argv->{ $key }, $value ];
	      }
	    }
	    # just set it
	    else {
		$argv->{ $key } = $value;
	    }
	}
        else {

	    # if we see a value again, increment the occurence count
	    if ( exists $argv->{ $key } ) {
		DEBUG("incremented key '$key'" );
		$argv->{ $key }++;
	    }
	    else {
		DEBUG("set $key" );
		$argv->{ $key } = 1;
	    }
        }
    }

    # save these so we don't have to do it again
    $self->{ARGV}      = $argv;
    $self->{BAREWORDS} = $barewords;

    return ( $argv, $barewords );
}

# Helper to split an arg into key/value. Returns ($key, $value), where
# $value is undef if the argument is flag format (--debug), undef if
# it is a bareword ( foo ) and '--' if it is the arguments terminator
# symbol.
#
sub _get_arg {
    my ( $self, $arg ) = @_;

    if ( $arg !~ /^-(-)?/ ) {
	return;
    }

    if ( $arg eq '--' ) {
	return $arg;
    }

    my ( $key, $value ) = split /=/xms, $arg, 2;

    if ( !defined $key ) {
	Activator::Exception::Config->throw( 'argument',
					      'invalid',
					      $arg );
    }

    # clean up key
    $key =~ s/^--?//;

    # clean up value, if quoted
    if ( defined $value ) {
	$value =~ s/^"//;
	$value =~ s/"$//;
    }

    return ( $key, $value );
}

# Merge config files into this objects Activator::Registry object
sub _process_config_files {
    my ( $pkg, $realm, $skip_env, $project_is_arg ) = @_;
    my $self = &new( @_ );

    # figure out what project we are working on
    my $project =
      $self->{ARGV}->{project} ||
	( $project_is_arg ? $self->{BAREWORDS}->[-1] : undef ) ||
	  ( $skip_env ? undef : $ENV{ACT_CONFIG_project} ) ||
	    Activator::Exception::Config->throw( 'project', 'missing' );

    # process these files:
    #     $ENV{USER}.yml
    #     <realm>.yml    - realm specific settings and defaults
    #     <project>.yml  - project specific settings and defaults
    #     org.yml        - top level organization settings and defaults
    # in one of these paths, if set
    #   --conf_file=       : use $self->{ARGV}->{conf_file} (which could be an arrayref )
    #   ACT_CONFIG_conf_file= : comma separated list of files

    my $conf_path = $self->{ARGV}->{conf_path};
    if ( ! $conf_path ) {
	$conf_path = ( $skip_env ? undef : $ENV{ACT_CONFIG_conf_path} );
	if ( !$conf_path ) {
	    ERROR( "Neither ACT_CONFIG conf_path env var nor --conf_path set");
	    Activator::Exception::Config->throw( 'conf_path', 'missing' );
	}
	else {
	    INFO( "Using ACT_CONFIG_conf_path env var: $conf_path");
	}
    }
    else {
	INFO( "Using conf_path argument: $conf_path");
    }

    my @search_paths = split ':', $conf_path;
    DEBUG( 'Searching for conf files in: ' . Data::Dumper->Dump( [ \@search_paths ], [ qw/ search_paths / ] ) );

    # Search for these files, create a files lookup.
    my $files = { user    => { target => "$ENV{USER}.yml" },
		  realm   => { target => "${realm}.yml"   },
		  project => { target => "${project}.yml" },
		  org     => { target => 'org.yml' } };

    foreach my $path ( @search_paths ) {
	$path =~ s|/$||;
	foreach my $which ( keys %$files ) {
	    my $target = $files->{ $which }->{target};

	    if ( !opendir DIR, $path ) {
		WARN( "Ignoring invalid path '$path'" );
	    } else {
		my @found = grep { /^$target$/ && -f "$path/$_" } readdir(DIR);
		if ( @found  ) {
		    my $file = "$path/$found[0]";
		    if ( !exists( $files->{ $which }->{ file } ) ) {
			$files->{ $which }->{file} = $file;
		    } else {
			INFO( "Ignoring lower priority config file '$file'" );
		    }
		}
	    }
	}
    }

    DEBUG ( 'Processing config files: ' . Data::Dumper->Dump( [ $files ], [ qw/ files / ] ) );

    # now that we have all the files, import 'em! This is a super long
    # winded but safe "left precedence" merge of all files
    my ( $user_config, $realm_config, $project_config, $org_config );

    try eval {
	if ( exists( $files->{user}->{file} ) ) {
	    $user_yml = YAML::Syck::LoadFile( $files->{user}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Config->throw( 'user_config', 'invalid', $e );
    }

    try eval {
	if ( exists( $files->{realm}->{file} ) ) {
	    $realm_yml = YAML::Syck::LoadFile( $files->{realm}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Config->throw( 'realm_config', 'invalid', $e );
    }

    try eval {
	if ( exists( $files->{project}->{file} ) ) {
	    $project_yml = YAML::Syck::LoadFile( $files->{project}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Config->throw( 'project_config', 'invalid', $e );
    }

    try eval {
	if ( exists( $files->{org}->{file} ) ) {
	    $org_yml = YAML::Syck::LoadFile( $files->{org}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Config->throw( 'org_config', 'invalid', $e );
    }

    if ( $realm ne 'default' ) {
	if ( defined( $user_yml ) && exists( $user_yml->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $user_yml->{ $realm }, $realm );
	    DEBUG('Registered: ' . $files->{user}->{file} . " for realm $realm" );
	}

	if ( defined( $realm_yml ) && exists( $realm_yml->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $realm_yml->{ $realm }, $realm );
	    DEBUG('Registered: ' . $files->{realm}->{file} . " for realm $realm" );
	}

	if ( defined( $project_yml ) && exists( $project_yml->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $project_yml->{ $realm }, $realm );
	    DEBUG('Registered: ' . $files->{project}->{file} . " for realm $realm" );
	}

	if ( defined( $org_yml ) && exists( $org_yml->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $org_yml->{ $realm }, $realm );
	    DEBUG('Registered: ' . $files->{org}->{file} . " for realm $realm" );
	}
    }

    if ( defined( $user_yml ) ) {
	if ( exists( $user_yml->{default} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $user_yml->{default}, $realm );
	}
	elsif ( exists( $user_yml->{act_config_no_realms} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $user_yml, $realm );
	}
	DEBUG('Registered: ' . $files->{user}->{file} . " for default realm" );
    }

    if ( defined( $realm_yml ) ) {
	if ( exists( $realm_yml->{default} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $realm_yml->{default}, $realm );
	}
	elsif ( exists( $realm_yml->{act_config_no_realms} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $realm_yml, $realm );
	}
	DEBUG('Registered: ' . $files->{realm}->{file} . " for default realm" );
    }

    if ( defined( $project_yml ) ) {
	if ( exists( $project_yml->{default} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $project_yml->{default}, $realm );
	}
	elsif ( exists( $project_yml->{act_config_no_realms} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $project_yml, $realm );
	}
	DEBUG('Registered: ' . $files->{project}->{file} . " for default realm" );
    }

    if ( defined( $org_yml ) ) {
	if ( exists( $org_yml->{default} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $org_yml->{default}, $realm );
	}
	elsif ( exists( $org_yml->{act_config_no_realms} ) ) {
	    $self->{REGISTRY}->register_hash( 'left', $org_yml, $realm );
	}
	DEBUG('Registered: ' . $files->{org}->{file} . " for default realm" );
    }

    if ( defined( $user_yml ) && exists( $user_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $user_yml->{overrides}, 'overrides' );
	DEBUG('Registered: ' . $files->{user}->{file} . " overrides" );
    }

    if ( defined( $realm_yml ) && exists( $realm_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $realm_yml->{overrides}, 'overrides' );
	DEBUG('Registered: ' . $files->{realm}->{file} . " overrides" );
    }

    if ( defined( $project_yml ) && exists( $project_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $project_yml->{overrides}, 'overrides' );
	DEBUG('Registered: ' . $files->{project}->{file} . " overrides" );
    }

    if ( defined( $org_yml ) && exists( $org_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $org_yml->{overrides}, 'overrides' );
	DEBUG('Registered: ' . $files->{org}->{file} . " overrides" );
    }

    # make sure all is kosher
    my $test = $self->{REGISTRY}->get_realm( $realm );
    if ( !keys %$test ) {
	DEBUG( Data::Dumper->Dump( [ $self->{REGISTRY} ], [ qw/ registry / ] ) );
	ERROR( "After processing, '$realm' realm should not be empty, but it is!");
	Activator::Exception::Config->throw('realm', 'empty', $realm);
    }
}

# Override any options in $config with the values in $argv. Sets non-existent keys.
#
# Arguments:
#   $config  : hashref to the options for $realm
#   $argv  : arrayref to command line arguments. All recognized options are removed.
#
sub _argv_override {
    my ( $self, $config, $argv ) = @_;

    my @barewords;
    my @unrec;

    # loop through $argv (which we assume to be a ref to @ARGV) and
    # set any config keys if they exist.
    while ( my $arg = shift @$argv  ) {
	my ( $key, $value ) = $self->_get_arg( $arg );

	# ignore barewords
	if ( ! defined( $key ) ) {
	    DEBUG("Ignoring bareword '$arg'");
	    push @unrec, $arg;
	    next;
	}

	# finish up if we find terminator
	if ( $key eq '--' ) {
	    DEBUG("Found arguments terminator --");
	    unshift @$argv, '--';
	    last;
	}

# TODO: consider supporting realm specific command line arguments
#
#	# skip this key if it is for a different realm
#	if ( $key =~ /^__(\w+)__(\w+)$/ ) {
#	    $key_realm = $1;
#	    $key = $2;
#	    if( $realm ne $key_realm ) {
#		push @unrec, $arg;
#		next;
#	    }
#	}

	# leave this key in @ARGV if we don't recognize it
	if( !exists( $config->{ $key } ) ) {
	    push @unrec, $arg;
	}

	# set the value no matter what
	$config->{ $key } = $value;
    }
    unshift @$argv, @unrec;

}

# do variable replacements throughout
sub _var_replace {
    my ( $self, $config, $replacements ) = @_;
#    Activator::Registry->replace_in_hashref( $config,
}

=head1 DEBUG MODE

Since this module is part of L<Activator>, you can set your
L<Activator::Log> level to DEBUG to see how your C<$config> are
generated.

 #### TODO: in the future, there needs to be a 'lint' hash within the
 #### realm that says where every variable came from.

=head1 COOKBOOK


 #### TODO: these examples are probably complete baloney at this point.



This section gives some examples of how to utilze this module. Each
section below (cleverly) assumes we are writing a Cookbook application
that can fetch recipies from a database.


=head2 End User

Use Case: A user has a CPAN module that provides C<cookbook.pl> to
lookup recipies from a database. The project installs these files:

  /etc/cookbook.d/org.yml
  /usr/lib/perl5/site-perl/Cookbook.pm
  /usr/bin/cookbook.pl

C<org.yml> has the following data:

  ---
  default:
    db_name:   cookbook
    db_user:   chef
    db_passwd: southpark

The user can run the script as such:

  #### list recipes matching beans in the organization's public db
  #### using the public account
  cookbook.pl lookup beans

  #### lookup beans in user's db
  cookbook.pl --db_name=my_db  \
              --db_user=cookie \
              --db_passwd=cheflater  lookup beans

  #### user creates $HOME/$USER.yml
  cookbook.pl --conf_file=$HOME/$USER.yaml lookup beans

  #### user creates $HOME/.cookbook.d
  cookbook.pl lookup beans

=head2 Simple Development

Use Case: developer is working on C<cookbook.pl>. Project directory
looks like:

  $HOME/src/Cookbook/lib/Cookbook.pm
  $HOME/src/Cookbook/bin/cookbook.pl
  $HOME/src/Cookbook/etc/cookbook.d/org.yml
  $HOME/src/Cookbook/.cookbook.d/$USER.yml

With these configurations:

  org.yml:
  ---
  default:
    db_name:   cookbook
    db_user:   chef
    db_passwd: southpark

  $USER.yml
  ---
  default:
    db_name:   $USER
    db_user:   $USER
    db_passwd: passwd
  staging:
    db_name:   staging
    db_user:   test
    db_passwd: test

  #### when developing, call the script like this to lookup bean
  #### recipies from developers personal db
  cd $HOME/src/Cookbook
  bin/cookbook.pl lookup beans

  #### To demo the project to someone else, developer creates a demo
  #### account, which has the environment variable ACT_CONFIG_realm set
  #### to 'staging'. demo user then uses the script as if it were
  #### installed, but connects to the staging database:
  cookbook.pl lookup beans

  #### if the developer wants to see what the demo user sees:
  cd $HOME/src/Cookbook
  bin/cookbook.pl --realm=staging lookup beans

=head1 TODO: complex development

Someday, we'll have a really neat example of all the goodness this
module is capable of.

=head1 FUTURE WORK

=over

=item *

Make sure that L</Automatically Imported Environment Variables> are
cross platform compatible.

=item *

Don't force the conf_path arg: default to something like
C<~/.activator> so a user can have default settings. Further,
activator.pl should support a configuration wizard for this file.

=item *

Clean up cookbook

=back

=head1 SEE ALSO

 L<Activator::Exception>
 L<Activator::Log>

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

1;
