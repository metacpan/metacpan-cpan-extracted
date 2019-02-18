#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2019 -- leonerd@leonerd.org.uk

package Alien::unibilium;

our $VERSION = '0.14';

use POSIX qw( WEXITSTATUS );

my $module = '@PKGCONFIG_MODULE@';
my $use_bundled = '@USE_BUNDLED@';

# libdir is the first @INC path that contains a pkgconfig/ dir
my $libdir;
if( $use_bundled ) {
   foreach my $inc ( @INC ) {
      $libdir = $inc and last if -d "$inc/pkgconfig";
   }
   defined $libdir or die "Cannot find my libdir containing pkgconfig";
}

=head1 NAME

C<Alien::unibilium> - L<Alien> wrapping for F<unibilium>

=head1 DESCRIPTION

This CPAN distribution wraps the C library F<unibilium> in a wrapper suitable
to drive CPAN and other Perl-related build infrastructure.

If the C library is already installed and known by F<pkg-config>, this module
provides a simple access to its configuration. If not, the process of
installing it will install a locally-bundled copy of the library into perl's
arch-specific library directory.

This module bundles a patched version of F<unibilium> version v2.0.0,
containing the pending upstream pull-request #39.

=head1 METHODS

This module behaves like L<ExtUtils::PkgConfig>, responding to the same
methods, except that the module name is implied. Thus, the configuration can
be obtained by calling

 $cflags = Alien::unibilium->cflags
 $libs = Alien::unibilium->libs

 $ok = Alien::unibilium->atleast_version( $version )

 etc...

=cut

my %check_methods = map { $_ => 1 } qw(
   atleast_version
   exact_version
   max_version
);

# I AM EVIL
sub AUTOLOAD
{
   our $AUTOLOAD =~ s/^.*:://;
   return defined _get_pkgconfig( $AUTOLOAD, @_ ) if $check_methods{$AUTOLOAD};
   return _get_pkgconfig( $AUTOLOAD, @_ );
}

sub _get_pkgconfig
{
   my ( $method, $self, @args ) = @_;

   $method =~ s/_/-/g;

   unshift @args, "--$method";

   local $ENV{PKG_CONFIG_PATH} = "$libdir/pkgconfig/" if $use_bundled;

   open my $eupc, "-|", "pkg-config", @args, $module or
      die "Cannot popen pkg-config - $!";

   my $ret = do { local $/; <$eupc> }; chomp $ret;
   close $eupc;

   return undef if WEXITSTATUS($?);
   return $ret;
}

sub libs
{
   # Append RPATH so that runtime linking actually works
   return _get_pkgconfig( libs => @_ ) . ( $use_bundled ? " -Wl,-R$libdir" : "" );
}

=head1 SEE ALSO

=over 4

=item *

L<https://github.com/mauke/unibilium> - mauke/unibilium on github

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
