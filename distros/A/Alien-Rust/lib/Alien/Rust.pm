package Alien::Rust;
$Alien::Rust::VERSION = '0.03';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

sub needs_rustup_home {
  my ($class) = @_;
  exists $class->runtime_prop->{'_using_rustup'}
    ?    $class->runtime_prop->{'_using_rustup'}
    :    0;
}

sub rustup_home {
  my ($class) = @_;
  $class->runtime_prop->{'rustup_home'} || '';
}

1;

=head1 NAME

Alien::Rust - Find or build Rust

=head1 SYNOPSIS

Command line tool:

 use Alien::Rust;
 use Env qw( @PATH $RUSTUP_HOME );

 unshift @PATH, Alien::Rust->bin_dir;
 $RUSTUP_HOME = Alien::Rust->rustup_home if Alien::Rust->needs_rustup_home;

=head1 DESCRIPTION

This distribution provides Rust so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of Rust on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 METHODS

=head2 rustup_home

Returns the value for the environment variable C<RUSTUP_HOME>. This is valid only
if L</needs_rustup_home> returns true.

Without this value, certain Rust configurations that use
L<C<rustup>|https://rust-lang.github.io/rustup/> will not work as their
binaries (e.g., C<rustc>, C<cargo>, etc.) are shims that point to the toolchain
managed by C<rustup>.

=head2 needs_rustup_home

Returns true if the value returned by L</rustup_home> must be set. See
L</rustup_home> for more information.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut
