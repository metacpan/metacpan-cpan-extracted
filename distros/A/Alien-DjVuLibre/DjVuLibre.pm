package Alien::DjVuLibre;

use parent qw(Alien::Base);
use strict;
use warnings;

our $VERSION = 0.07;

1;

__END__

=encoding UTF-8

=head1 NAME

Alien::DjVuLibre - Find or download and install DjVuLibre.

=head1 SYNOPSIS

 use Alien::DjVuLibre;

 my $atleast_version = Alien::DjVulibre->atleast_version($wanted_version);
 my $bin_dir = Alien::DjVuLibre->bin_dir;
 my $cflags = Alien::DjVuLibre->cflags;
 my $cflags_static = Alien::DjVuLibre->cflags_static;
 my $dist_dir = Alien::DjVuLibre->dist_dir;
 my $exact_version = Alien::DjVuLibre->exact_version($wanted_version);
 my $install_type = Alien::DjVuLibre->install_type;
 my $libs = Alien::DjVuLibre->libs;
 my $libs_static = Alien::DjVuLibre->libs_static;
 my $max_version = Alien::DjVuLibre->max_version($wanted_version);
 my $version = Alien::DjVuLibre->version;

=head1 DESCRIPTION

Some packages insist on using DjVuLibre library.

This package detect system DjVuLibre library or install own.

=head1 SUBROUTINES/METHODS

All methods are inherited from L<Alien::Base>.

=head1 CONFIGURATION AND ENVIRONMENT

Not yet.

=head1 EXAMPLE

=for comment filename=alien_djvulibre_variables.pl

 use strict;
 use warnings;

 use Alien::DjVuLibre;

 print 'cflags: '.Alien::DjVuLibre->cflags."\n";
 print 'cflags_static: '.Alien::DjVuLibre->cflags_static."\n";
 print 'dist_dir: '.Alien::DjVuLibre->dist_dir."\n";
 print 'libs: '.Alien::DjVuLibre->libs."\n";
 print 'libs_static: '.Alien::DjVuLibre->libs_static."\n";
 print 'version: '.Alien::DjVuLibre->version."\n";

 # Output like:
 # cflags: -pthread
 # cflags_static: -pthread
 # dist_dir: ~/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-DjVuLibre
 # libs: -ldjvulibre
 # libs_static: -ldjvulibre -ljpeg -lpthread -lm
 # version: 3.5.28

=head1 DEPENDENCIES

L<Alien::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Alien-DjVuLibre>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 CONTRIBUTORS

Zakariyya Mughal L<mailto:zaki.mughal@gmail.com>

=head1 LICENSE AND COPYRIGHT

© 2022-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
