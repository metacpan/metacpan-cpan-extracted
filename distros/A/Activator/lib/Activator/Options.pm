package Activator::Options;

use Data::Dumper;
use Activator::Registry;
use Activator::Log qw( :levels );
use Scalar::Util qw( reftype );
use Exception::Class::TryCatch;
use base 'Class::StrongSingleton';

=head1 NAME

THIS MODULE DEPRECATED. USE L<Activator::Config> instead.


C<Activator::Options> - process options for a script combining command
line, environment variables, and configuration files.

=head1 SYNOPSIS

  use Activator::Options;

  my $opts = Activator::Options->get_opts( \@ARGV);  # default realm
  my $opts = Activator::Options->get_opts( \@ARGV, $otherrealm);

  #### Get a hashref of command line arguments, and an arrayref of barewords
  my ( $argv, $barewords ) = Activator::Options->get_args( \@ARGV );

=head1 DESCRIPTION

This module allows a script to obtain options from command line,
envirnoment variables, and YAML configuration files.

=head2 Prcedence Heirarchy

The precedence heirarchy from highest to lowest is:

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

=head2 Configuration File Heirarchy

In order to facilite the varied ways in which software is developed,
deployed, and used, the following heirarchy lists the configuration
file heirarchy suported from highest to lowest:

  $ENV{USER}.yml - user specific settings
  <realm>.yml    - realm specific settings and defaults
  <project>.yml  - project specific settings and defaults
  org.yml        - top level organization settings and defaults

It is up to the script using this module to define what C<project> is,
and up to the project to define what realms exist, which all could
come from any of the command line options, environment variables or
configuration files. All of the above files are optional and will be
ignored if they don't exist, however at least one configuration file
must exist for the C<get_opts()> function.

=head2 Configuration File Search Path

TODO: This functionality is not implemented yet. Currently, only
      ~/.activator.d/<project> is supported

The search path for configuration YAML files is listed below. The
first conf file for each level appearing in the following directories
will be utilized:

  --conf_path=<paths_to_conf_dir>        # colon separated list
  --conf_files=<conf_files>              # comma separated list
  $ENV{ACT_OPT_conf_path}
  $ENV{ACT_OPT_project_home}/.<$ENV{ACT_OPT_project}>.d/
  $ENV{HOME}/.<$ENV{ACT_OPT_project}>.d/
  /etc/<$ENV{ACT_OPT_project}>.d/
  /etc/activator.d/                      # useful for org.yml

It is up to the script to define what C<project> is by insuring that
C<$ENV{ACT_OPT_project}> is set. This module will throw
C<Activator::Exception::Option> it is not set by you or passed in as a
command line argument, so you could force the user to use the
C<--project> option if you like.

=head2 Realms

This module supports the concept of realms to allow multiple similar
configurations to override only the esential keys to "git 'er done".

=head2 Configuration Logic Summary

=over

=item *

All configuration files are read and merged together on a realm by
realm basis with higher precedence configuration files overriding
lower precedence. If duplicate level files exist in the Configuration
File Search Path, only the first discovered file is used.

=item *

All realms are then merged with the C<default> realm, I<realm> config
taking precedence.

=item *

All C<default> realm environment variables override all values for
each realm (excepting C<overrides> realm).

=item *

All specific realm environment variables override that realm's values
for the key.

=item *

The C<default> realm overrides section is used to override matching
keys in all realms.

=item *

The specific realm overrides section is used to override matching keys
in the requested realm.

=item *

Any command line options given override ALL matching keys for all
realms.

=item *

# TODO: NOT YET IMPLEMENTED

Perform variable substitution

=back

=head1 COMMAND LINE ARGUMENTS

This module allows long or short options using C<'-'> or C<'--'>
notation, allows barewords in any order, and recognizes the arguments
terminator C<'--'>. Also supported are multiple flag arguments:

  #### turn on super verbosity. sets $opts->{v} = 2
  myscript.pl -v -v

You can specify configured options at the command line for
override:

  #### override the configuration file setting for 'foo'
  myscript.pl --foo=bar

Command line overrides only apply to keys that exist in a
configuration file and any unrecognized options are ignored. C<@ARGV>
is modified to remove recognized options, leaving barewords and
unrecognized options in the order they were specified. This module has
no support for argument validation, and your script must handle
unrecognizd options and behave appropriately. There are numerous
modules on CPAN that can help you do that (L<Getopt::Long> for
example). If you do use another options module, make sure you call
C<get_opts()> BEFORE you call their processor, so that @ARGV will be
in an appropriate state.

Also, while YAML configuration (and this module) support deep
structures for options, you can only override top level keys that are
scalars using command line arguments and/or environment variables.

=head2 Special Arguments

There are a few special command line arguments that do not require
YAML existence:

 --skip_env        : ignore environment variables
 --project=<>      : use this value for <project> in config file search path.
 --project_home=<> : useful for when utilizing <project_home>/.<project> config dir
 --realm=<>        : use <realm>.yml in config file processing and consider all
                     command line arguments to be in this realm

TODO: these are not implemented yet

Also supported are these variables which can be listed as many times
as necessary:

 --conf_file=<> : include <> file for inclusion
 --conf_path=<> : include <> path when looking for config files


=head1 ENVIRONMENT VARIABLES

Environment variables can be used to override any top level YAML
configuration key which is a scalar. The expected format is
C<ACT_OPT_[key]>. Note that YAML is case sensitive, so the environment
variables must match. Be especially wary of command shell senstive
characters in your YAML keys.

If you wish to override a key for only a particular realm, you
can insert the realm into the env variable wrapped by double
underscores:

 ACT_OPT_foo       - set 'foo' for default realm
 ACT_OPT__bar__foo - set 'foo' only for 'bar' realm

The special command line arguments listed in the COMMAND LINE
ARGUMENTS section also have corresponding environment variables with
minor differences in use:

 ACT_OPT_skip_env     : set to 1 to skip, or 0 (or don't set it at all) to
                        not skip
 ACT_OPT_project      : same as command line argument
 ACT_OPT_project_home : same as command line argument
 ACT_OPT_realm        : same as command line argument
 ACT_OPT_conf_file    : comma separated list of files
 ACT_OPT_conf_path    : colon separated list of directories

=head1 CONFIGURATION FILES

=head2 Realms

This module suports realms such that when passing a realm to
L<get_opts()> (or via the C<--realm> command line argument), values
for the realm take precedence over the default realm's values. For
example, given YAML:

  default:
    key1: value1
  realm:
    key1: value2

C<Activator::Options-E<gt>get_opts( \@ARGV )> would return:

$opts = { key1 => value1 }

and C<Activator::Options-E<gt>get_opts( \@ARGV, 'realm' )> would return:

$opts = { key1 => value2 }

=head2 Overrides

Sometimes it is desireable to force a value to override the
organiztaion/project/realm value when many config files are merged to
create the C<$opts> hash. The special realm C<overrides> can be utilzed in
these cases, and will stomp any values that come from YAML
configurations. E.g.:

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

Would produce the following C<$opts>:

 $opts = {
    default => {
       name => 'Ron Johnson from Ronson, Wisconson',
    },
    some_realm => {
       name => 'Johnny Jammer, the Rhode Island Hammer',
    },
    other_realm => {
      name => 'Ron Johnson from Ronson, Wisconson',
    },
 }

=head2 Variable Substitution

#### TODO: NOT YET IMPLEMENTED

Substitution occurs as the last step of processing. Every value for
every key (including values within lists ) are visited. Values for any
key can optionally contain a reference to another key by using C<${}>
notation. Use the indirect operator C<'-E<gt>'> to reference deeply nested
values. For example:

  default:
    key1: value1
    key2: value2
  realm1:
    foo: bar
  realm2:
    key2: ${key1}
  realm3:
    key3: ${realm1->foo}/${key2}         # value == 'bar/value2'
    key4: ${realm1->foo}/${realm2->key2} # value == 'bar/value1'

Note that you must fully qualify any deeply nested references.

=head1 METHODS

=head2 new()

Constructor: implements singleton. Not very useful. Use L<get_opts()>.

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

=head2 get_opts()

Usage:

  Activator::Options->get_opts( \@ARGV );         # default realm
  Activator::Options->get_opts( \@ARGV, $realm );

Strip recognized options from C<@ARGV> and return the configuration
hash C<$opts> for C<$realm> based on C<@ARGV>. C<$realm> is optional
(default is 'default'), and if not specified either the command line
argument (C<--realm>) or environment variable
(C<ACT_OPT_E<lt>realmE<gt>> unless C<ACT_OPT_skip_env> is set) will be
used. Not specifying a realm via one of these mechanisms is a fatal
error.

Examples:

  #### get options for default realm
  my $opts = Activator::Options->get_opts( \@ARGV );

  #### get options for 'some' realm
  my $opts = Activator::Options->get_opts( \@ARGV, 'some' );

See L<get_args()> for a description of the way command line arguments
are processed.

=cut

sub get_opts {
    my ( $pkg, $argv, $realm ) = @_;
    my $self = &new( @_ );
    my $argx = {};

    # get_args sets $self->{ARGV}
    $self->get_args( $argv );
    DEBUG( Data::Dumper->Dump( [ $self->{ARGV} ], [ qw/ ARGV / ] ) );
    DEBUG( Data::Dumper->Dump( [ $self->{BAREWORDS} ], [ qw /BAREWORDS/ ] ) );

    # make sure we can use ENV vars
    my $skip_env =  $ENV{ACT_OPT_skip_env};

    $realm ||=
      $self->{ARGV}->{realm} ||
	( $skip_env ? undef : $ENV{ACT_OPT_realm} ) ||
	  'default';

    # setup or get the merged YAML configuration settings from files
    # into the registry
    my $opts = $self->{REGISTRY}->get_realm( $realm );

    # first call
    if ( !keys %$opts ) {
	# define valid opts from config files
	try eval {
	    $self->_process_config_for( $realm );
	};

	# _set_reg throws err if $realm is invalid
	if ( catch my $e ) {
	    $e->rethrow;
	}

	# read environment variables, set any keys found
	if ( !$skip_env ) {
	    my ( $env_key, $env_realm );
	    foreach my $env_key ( keys %ENV ) {
		next unless $env_key =~ /^ACT_OPT_(.+)/;
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
		      !grep( /$opt_key/, qw( skip_env project project_home
					     realm conf_file conf_path ) ) ) {
		    WARN( "Skipped invalid environment variable $env_key.  Key '$opt_key' for realm '$opt_realm' unchanged");
		}
	    }
	}

	# forced overrides from config files
	my $overrides = $self->{REGISTRY}->get_realm( 'overrides' );
	DEBUG( 'processing overrides: '.Dumper( $overrides ));

	# NOTE: bad (typo) keys could be in overrides. Someday,
	# Activator::Registry will allow debug mode so we can state
	# show this.
	if ( exists( $overrides->{ $realm } ) ) {
	    $self->{REGISTRY}->register_hash( 'right', $overrides->{ $realm }, $realm );
	}

	# now that realm is set, make sure our $opts points to it
	$opts = $self->{REGISTRY}->get_realm( $realm );

	# Override any provided command line options into this realm.
	# Strips known options out of \@ARGV
	$self->_argv_override( $opts, $argv );

	DEBUG( 'created opts: '.Dumper( $opts ));
    }
    else {
	DEBUG( 'found opts: '.Dumper( $opts ));
    }

    return $opts;
}

=head2 get_args()

Usage: Activator::Options->get_args( $argv_raw )

Takes a reference to a list of command line arguments (usually \@ARGV)
and returns a hash. C<$argv_raw> is not changed.

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

Flag arguments are counted. That is C<-v -v> would set C<$opts-E<gt>{v} = 2>

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

Throws C<Activator::Exception::Option> when arg is invalid (which at this
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
	Activator::Exception::Options->throw( 'argument',
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
sub _process_config_for {
    my ( $pkg, $realm ) = @_;
    my $self = &new( @_ );

    # figure out what project we are working on
    my $project =
      $self->{ARGV}->{project} ||
	$ENV{ACT_OPT_project} ||
	  Activator::Exception::Options->throw( 'project', 'missing' );

    # assemble a list of paths to look for config files
    # TODO: look in all these places:
    #   --conf_path
    #   ACT_OPT_conf_path
    #   $ENV{ACT_OPT_project_home}/.<$ENV{ACT_OPT_project}>.d/
    #   $ENV{HOME}/.<$ENV{ACT_OPT_project}>.d/
    #   $ENV{HOME}/.activator.d/
    #   /etc/<$ENV{ACT_OPT_project}>.d/
    #   /etc/activator.d/
    #

    # assemble a list of files to process into the keys of $seach_paths
    # TODO: assemble list of files for each of the above dirs
    #   --conf_file=       : use $self->{ARGV}->{conf_file} (which could be an arrayref )
    #   ACT_OPT_conf_file= : comma separated list of files
    #   $ENV{USER}.yml
    #   <realm>.yml    - realm specific settings and defaults
    #   <project>.yml  - project specific settings and defaults
    #   org.yml        - top level organization settings and defaults

    # For now, just use ~/.activator.d/$project : key/value is path/'where
    # found', 'where found' being one of: hardcoded, env, or arg
    my $dir = $self->{ARGV}->{conf_path} ||
	$ENV{ACT_OPT_conf_path} ||
	  Activator::Exception::Options->throw( 'conf_path', 'missing');
    my $search_paths = { $dir => 'arg' };

    my $files = { user    => { target => "$ENV{USER}.yml" },
		  realm   => { target => "${realm}.yml"   },
		  project => { target => "${project}.yml" },
		  org     => { target => 'org.yml' } };
    foreach my $path ( keys %$search_paths ) {
	$path =~ s|/$||;
	foreach my $which ( keys %$files ) {
	    my $target = $files->{ $which }->{target};
	    if ( !opendir DIR, $path ) {
		# TODO: enhance this note to say where this path was detected
		WARN( "Ignoring invalid path '$path'" );
	    }
	    else {
		my @found = grep { /^$target$/ && -f "$path/$_" } readdir(DIR);
		if ( @found  ) {
		    my $file = "$path/$found[0]";
		    if ( !exists( $files->{ $which }->{ file } ) ) {
			$files->{ $which }->{file} = $file;
		    }
		    else {
			# TODO: enhance this note to say where this path was detected
			INFO( "Ignoring lower priority config file '$file'" );
		    }
		}
	    }
	}
    }

    # now that we have all the files, import 'em! This is a super long
    # winded but safe "left precedence" merge of all files
    my ( $user_config, $realm_config, $project_config, $org_config );

    try eval {
	if( exists( $files->{user}->{file} ) ) {
	    $user_yml = YAML::Syck::LoadFile( $files->{user}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Options->throw( 'user_config', 'invalid', $e );
    }

    try eval {
	if( exists( $files->{realm}->{file} ) ) {
	    $realm_yml = YAML::Syck::LoadFile( $files->{realm}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Options->throw( 'realm_config', 'invalid', $e );
    }

    try eval {
	if( exists( $files->{project}->{file} ) ) {
	    $project_yml = YAML::Syck::LoadFile( $files->{project}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Options->throw( 'project_config', 'invalid', $e );
    }

    try eval {
	if( exists( $files->{org}->{file} ) ) {
	    $org_yml = YAML::Syck::LoadFile( $files->{org}->{file} );
	}
    };
    if ( catch my $e ) {
	Activator::Exception::Options->throw( 'org_config', 'invalid', $e );
    }

    if ( defined( $user_yml ) && exists( $user_yml->{ $realm } ) ) {
	$self->{REGISTRY}->register_hash( 'left', $user_yml->{ $realm }, $realm );
    }

    if ( defined( $realm_yml ) && exists( $realm_yml->{ $realm } ) ) {
	$self->{REGISTRY}->register_hash( 'left', $realm_yml->{ $realm }, $realm );
    }

    if ( defined( $project_yml ) && exists( $project_yml->{ $realm } ) ) {
	$self->{REGISTRY}->register_hash( 'left', $project_yml->{ $realm }, $realm );
    }

    if ( defined( $org_yml ) && exists( $org_yml->{ $realm } ) ) {
	$self->{REGISTRY}->register_hash( 'left', $org_yml->{ $realm }, $realm );
    }

    if ( defined( $user_yml ) && exists( $user_yml->{default} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $user_yml->{default}, $realm );
    }

    if ( defined( $realm_yml ) && exists( $realm_yml->{default} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $realm_yml->{default}, $realm );
    }

    if ( defined( $project_yml ) && exists( $project_yml->{default} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $project_yml->{default}, $realm );
    }

    if ( defined( $org_yml ) && exists( $org_yml->{default} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $org_yml->{default}, $realm );
    }

    if ( defined( $user_yml ) && exists( $user_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $user_yml->{overrides}, 'overrides' );
    }

    if ( defined( $realm_yml ) && exists( $realm_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $realm_yml->{overrides}, 'overrides' );
    }

    if ( defined( $project_yml ) && exists( $project_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $project_yml->{overrides}, 'overrides' );
    }

    if ( defined( $org_yml ) && exists( $org_yml->{overrides} ) ) {
	$self->{REGISTRY}->register_hash( 'left', $org_yml->{overrides}, 'overrides' );
    }

    # make sure all is kosher
    my $test = $self->{REGISTRY}->get_realm( $realm );
    if ( !keys %$test ) {
	Activator::Exception::Options->throw('realm', 'invalid', $realm);
    }

}

# Override any options in $opts with the values in $argv. Sets non-existent keys.
#
# Arguments:
#   $opts  : hashref to the options for $realm
#   $argv  : arrayref to command line arguments. All recognized options are removed.
#
sub _argv_override {
    my ( $self, $opts, $argv ) = @_;

    my @barewords;
    my @unrec;

    # loop through $argv (which we assume to be a ref to @ARGV) and
    # set any opts if they exist.
    while ( my $arg = shift @$argv  ) {
	my ( $key, $value ) = $self->_get_arg( $arg );

	# ignore barewords
	if ( ! defined( $key ) ) {
	    DEBUG("Ignoring bareword '$arg'");
	    push @barewords, $arg;
	    next;
	}

	# finish up if we find terminator
	if ( $key eq '--' ) {
	    DEBUG("Found arguments terminator --");
	    unshift @$argv, '--';
	    unshift @$argv, @barewords;
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

	$opts->{ $key } = $value;
    }
    unshift @$argv, @unrec;

}

# do variable replacements throughout
sub _var_replace {
    my ( $self, $opts, $replacements ) = @_;
#    Activator::Registry->replace_in_hashref( $opts, 
}

=head1 DEBUG MODE

Since this module is part of L<Activator>, you can set your
L<Activator::Log> level to DEBUG to see how your C<$opts> are
generated.

 #### TODO: in the future, there needs to be a 'lint' hash within the
 #### realm that says where every variable came from.

=head1 COOKBOOK

This section gives some examples of how to utilze this module. Each
section below (cleverly) assumes we are writing a Cookbook application
that can fetch recipies from a database.

 #### TODO: these examples use currently unimplemented features. FIX IT!

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
  #### account, which has the environment variable ACT_OPT_realm set
  #### to 'staging'. demo user then uses the script as if it were
  #### installed, but connects to the staging database:
  cookbook.pl lookup beans

  #### if the developer wants to see what the demo user sees:
  cd $HOME/src/Cookbook
  bin/cookbook.pl --realm=staging lookup beans

=head1 TODO: complex development

Someday, we'll have a really neat example of all the goodness this
module is capable of.


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
