package Alien::fpm;

use strict;
use warnings;
use base qw( Alien::Base );

use Alien::Ruby;

our $VERSION = '0.04';

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

On a share install, by default, fpm is installed from RubyGems.org. Set
C<ALIEN_FPM_GIT_URL> to install from a git repository instead.

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<ALIEN_FPM_VERSION>

When set, requires the specified version of fpm. On the gem path, this passes
C<-v VERSION> to C<gem fetch>. On the git path, this derives the git tag
C<vVERSION> as the branch unless C<ALIEN_FPM_GIT_BRANCH> is explicitly set.

=item C<ALIEN_FPM_GIT_URL>

When set, fpm will be installed from a git repository instead of from
RubyGems.org. The value should be a URL that C<git clone> accepts.

=item C<ALIEN_FPM_GIT_BRANCH>

When set alongside C<ALIEN_FPM_GIT_URL>, the specified branch or tag will be
checked out. If not set, the repository's default branch is used.

=back

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
