package Alien::fpm;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '0.02';

sub fpm_gem_home {
    my ($class) = @_;
    return $class->runtime_prop->{prefix};
}

1;

__END__

=head1 NAME

Alien::fpm - Find or install fpm

=head1 SYNOPSIS

 use Alien::fpm;

 use Env qw( @PATH @GEM_PATH );

 unshift @PATH, Alien::fpm->bin_dir;
 unshift @GEM_PATH, Alien::fpm->fpm_gem_home;

 system('fpm --verbose -s cpan -t rpm Fennec');

=head1 DESCRIPTION

This package can be used by other Perl modules that require fpm.

=head1 SEE ALSO

=over 4

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=head1 AUTHOR

Nicholas Hubbard <nicholashubbard@posteo.net>

=head1 CONTRIBUTORS

=over 4

=item * Zakariyya Mughal

=back

=cut
