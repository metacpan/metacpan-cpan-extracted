package App::PerlShell::Config;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Carp;

use Exporter;

our %EXPORT_TAGS = ( 'config_where' => [qw( config_where )], );
our @EXPORT_OK = ( @{$EXPORT_TAGS{'config_where'}} );

our @ISA = qw( Exporter );

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    if ( ( @_ % 2 ) == 1 ) {
        croak("Insufficient number of args - @_");
    } else {
        my %cfg = @_;
        return bless \%cfg, $class;
    }
}

sub config {
    my $self = shift;
    my ( $key, $value ) = @_;

    my $retType = wantarray;
    if ( defined $key ) {
        if ( exists $self->{$key} ) {

            # Set
            if ( defined $value ) {
                my $prev = $self->{$key};
                if ( $value eq '' ) {
                    undef $self->{$key};
                } else {
                    $self->{$key} = $value;
                }
                return ( defined $prev ) ? $prev : undef;

                # Get
            } else {
                if ( !defined $retType ) {
                    printf "%-15s => %s\n", $key,
                      defined( $self->{$key} ) ? $self->{$key} : 'undef';
                }
                return $self->{$key};
            }
        } else {
            if ( !defined $retType ) {
                carp("Key not valid - `$key'");
            }
            return undef;
        }

        # Get all
    } else {
        if ( !defined($retType) ) {
            for ( sort( keys( %{$self} ) ) ) {
                printf "%-15s => %s\n", $_,
                  defined( $self->{$_} ) ? $self->{$_} : 'undef';
            }
        } elsif ($retType) {
            return %{$self};
        } else {
            my %ret = %{$self};
            return \%ret;
        }
    }
}

sub add {
    my $self = shift;
    my ( $key, $value ) = @_;

    my $retType = wantarray;
    if ( defined $key ) {
        if ( !exists $self->{$key} ) {
            if ( defined $value ) {
                $self->{$key} = $value;
            } else {
                $self->{$key} = undef;
            }
            return 1;
        } else {
            if ( !defined $retType ) {
                carp("Key exists");
            }
        }
    } else {
        carp("Key required");
    }
    return 0;
}

sub delete {
    my $self = shift;
    my ($key) = @_;

    my $retType = wantarray;
    if ( defined $key ) {
        if ( exists $self->{$key} ) {
            delete $self->{$key};
            return 1;
        } else {
            if ( !defined $retType ) {
                carp("Key doesn't exist");
            }
        }
    } else {
        carp("Key required");
    }
    return 0;
}

sub exists {
    my $self = shift;
    my ($key) = @_;

    if ( defined $key ) {
        if ( exists $self->{$key} ) {
            return 1;
        }
    } else {
        carp("Key required");
    }
    return 0;
}

sub config_where {
    my ( $config_file, $dir ) = @_;

    my $home_dir = $ENV{HOME};
    if ( ( $^O eq 'MSWin32' ) and !( defined $home_dir ) ) {
        $home_dir = $ENV{USERPROFILE};
    }

    # 1 current working directory
    if ( -e $config_file ) {
        return $config_file

          # 2 user home directory
    } elsif ( -e $home_dir . "/" . $config_file ) {
        return $home_dir . "/" . $config_file;

        # 3 provided directory
    } elsif ( ( defined $dir ) and ( -e $dir . "/" . $config_file ) ) {
        return $dir . "/" . $config_file;

        # not found - indicate so in config
    } else {
        return;
    }
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

App::PerlShell::Config - Perl Shell Config

=head1 SYNOPSIS

 use App::PerlShell::Config;
 my $config = App::PerlShell::Config->new(
     key => 'value'
 );
 print $config->config;
 print $config->config('key');
 $config->config('key', 'new_value');
 print $config->config('key');

=head1 DESCRIPTION

B<App::PerlShell::Config> creates a global configuration structure for 
B<App::PerlShell> applications.

=head1 METHODS

=head2 new() - create a new Config object

  my $config = App::PerlShell::Config->new(
      key1 => 'value1',
      key2 => 'value2',
      ...
  );

Create a new B<App::PerlShell::Config> object with provided key / value 
pairs as configuration options.

=head2 config() - get / set configuration parameters

  [$c =] $config->config([OPTIONS]);

Get or set configuration parameters configured with C<new>.  This allows a 
user of B<App::PerlShell> to manipulate configuration parameters but 
not add new ones with this method interface.

In a B<App::PerlShell> program / module, one may choose to subclass 
this method with:

  sub config {
      $config->config(@_)
  }

This allows for manipulation of the configuration parameters without knowing 
the object variable (B<$config> in the above example).

Get all:

  [$i =] $config->config();
  [%i =] $config->config();

Called with no options, returns all configuration parameters as reference 
or hash, depending on how it's called.  In B<App::PerlShell>, 
called with no return value simply prints all configuration parameters.

Get one:

  [$i =] $config->config('key');

Returns the value of C<key>.

Set:

  [$i =] $config->config('key','new_value');
  [$i =] $config->config(key => 'new_value');

Sets the value of C<key> to 'new_value' and returns the previous value.

=head2 add() - add configuration parameters

  $config->add(key [,value]);

Add 'key' with optional 'value' to the B<App::PerlShell::Config> object.  If 
'value' not provided, 'key' is added with value undef.  Returns 1 on success, 
0 on failure.

=head2 delete() - delete configuration parameters

  [$c =] $config->delete(key);

Delete 'key' from the B<App::PerlShell::Config> object.  Returns 1 on success, 
0 on failure.

=head2 exists() - check for existence of configuration parameters

  [$c =] $config->exists(key);

Check if 'key' exists in the B<App::PerlShell::Config> object.  Returns 1 
if yes, 0 if not.

=head1 SUBROUTINES

=head2 config_where - find config file provided

  $conf_file = config_where($conf [,$dir]);

Given a config file name (C<$conf>) and an optional directory (C<$dir>), find 
the config file and return the full path or undefined if not found.

Search order is:

=over 4

=item 1

'$conf' in the current working directory where the script is invoked.  If 
found, return value is simply the file name in '$conf', no path.

=item 2

'$conf' in user's home directory (e.g., $HOME, %USERPROFILE%).

=item 3

'$conf' in the provided directory '$dir'.  This can be any directory, but 
usually would be the installation directory of the script as such:

  use FindBin qw($Bin);
  ...
  $conf_file = config_where($conf, $Bin);

=back

If no configuration file is found, returns undefined.

=head1 EXPORTS

Subroutine C<config_where> can be exported by calling use with:

  use App::PerlShell::Config qw(config_where);

=head1 SEE ALSO

B<App::PerlShell>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2015 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
