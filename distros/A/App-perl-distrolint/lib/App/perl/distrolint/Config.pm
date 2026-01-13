#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.36;

package App::perl::distrolint::Config 0.09;

=head1 NAME

C<App::perl::distrolint::Config> - configuration management for C<App::perl::distrolint>

=head1 SYNOPSIS

=for highlighter

   $ cat distrolint.ini
   [check Pod]
   enabled = false

=for highlighter language=perl

   use App::perl::distrolint::Check;

   if( App::perl::distrolint::Config->is_check_enabled( "Foo", 1 ) ) {
      say "The 'Foo' check is enabled";
   }

=head1 DESCRIPTION

This module manages reading of config files that configure how the
C<App::perl::distrolint> checks behave. On first use, it reads
F<distrolint.ini> files found in various places and stores the configuration
found there. Package methods allow modules to query that stored configuration.

There are two locations that files may be found. First is a F<distrolint.ini>
file in the current working directory; presumed to be the root directory of a
distribution source code. The second is F<$HOME/.config/distrolint.ini> in the
user's home directory, for storing user-wide configuration.

Each file should be in F<ini> format, with sections named for each check type,
using a section marker like C<[check Name]>. Values that are literal C<true>
or C<false> strings are converted into suitable boolean values; everything
else is taken literally.

Certain configuration keys are pre-defined as standard; individual check
modules may document other keys that are specific to that check.

=head2 Standard Configuration

=over 4

=item C<enabled>

A boolean that enables or disables that check module entirely.

=item C<skip>

A space-separated list of glob patterns. Files which match any of these
patterns will be skipped by checks that would otherwise iterate over all
source files of a certain type.

A glob metacharacter of C<*> will only match parts of a path within a
directory; use C<**> to match subdirectories also.

=back

=cut

use Config::Tiny;

my $config;

my sub _read_config ()
{
   return if $config;

   $config //= {};

   foreach my $path ( "distrolint.ini", "$ENV{HOME}/.config/distrolint.ini" ) {
      -r $path or next;

      my $thisconfig = Config::Tiny->read( $path );
      foreach my $section ( sort keys $thisconfig->%* ) {
         foreach my $key ( sort keys $thisconfig->{$section}->%* ) {
            my $value = $thisconfig->{$section}{$key};

            # convert boolean literals
            $value = ( $value eq "true" ) if $value =~ m/^(?:true|false)$/;

            $config->{$section}{$key} //= $value;
         }
      }
   }
}

=head1 METHODS

=cut

=head2 check_config

   $value = App::perl::distrolint::Config->check_config( $name, $key, $default );

Returns the value of a configuration key from the C<[check $name]> section of
the configuration file. If no entry exists, the value of C<$default> is
returned instead.

C<$name> may be given as a literal string, or as an object reference to the
check object itself (often C<$self> will suffice).

=cut

sub check_config ( $, $name, $key, $default )
{
   ref $name and
      $name = ( ref $name ) =~ s/^App::perl::distrolint::Check:://r;

   $config or _read_config();

   exists $config->{"check $name"} or return $default;
   return $config->{"check $name"}{$key} // $default;
}

=head2 is_check_enabled

   $enabled = App::perl::distrolint::Config->is_check_enabled( $name, $default = true );

Returns true if the check is enabled (or at least, has not been specifically
disabled), or false if a configuration file has specifically disabled this
check.

By default, all checks are enabled.

=cut

sub is_check_enabled ( $, $name, $default = 1 )
{
   return App::perl::distrolint::Config->check_config( $name, "enabled", $default );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
