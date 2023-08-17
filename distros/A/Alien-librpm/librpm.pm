package Alien::librpm;

use parent qw(Alien::Base);
use strict;
use warnings;

our $VERSION = 0.01;

1;

__END__

=encoding UTF-8

=head1 NAME

Alien::librpm - Find or download and install rpm library.

=head1 SYNOPSIS

 use Alien::librpm;

 my $atleast_version = Alien::librpm->atleast_version($wanted_version);
 my $bin_dir = Alien::librpm->bin_dir;
 my $cflags = Alien::librpm->cflags;
 my $cflags_static = Alien::librpm->cflags_static;
 my $dist_dir = Alien::librpm->dist_dir;
 my $exact_version = Alien::librpm->exact_version($wanted_version);
 my $install_type = Alien::librpm->install_type;
 my $libs = Alien::librpm->libs;
 my $libs_static = Alien::librpm->libs_static;
 my $max_version = Alien::librpm->max_version($wanted_version);
 my $version = Alien::librpm->version;

=head1 DESCRIPTION

Some packages insist on using rpm library.

This package detect system rpm library or install own.

=head1 SUBROUTINES/METHODS

All methods are inherited from L<Alien::Base>.

=head1 CONFIGURATION AND ENVIRONMENT

Not yet.

=head1 EXAMPLE

=for comment filename=alien_librpm_variables.pl

 use strict;
 use warnings;

 use Alien::librpm;

 print 'cflags: '.Alien::librpm->cflags."\n";
 print 'cflags_static: '.Alien::librpm->cflags_static."\n";
 print 'dist_dir: '.Alien::librpm->dist_dir."\n";
 print 'libs: '.Alien::librpm->libs."\n";
 print 'libs_static: '.Alien::librpm->libs_static."\n";
 print 'version: '.Alien::librpm->version."\n";

 # Output like (Debian 11.7 system rpm library):
 # cflags:  
 # cflags_static:  
 # dist_dir: ../perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-librpm
 # libs: -lrpm -lrpmio 
 # libs_static: -lrpm -lrpmio -lpopt -lrt -lpthread -llzma -ldb -lbz2 -lz -llua5.2 -lzstd 
 # version: 4.16.1.2

=head1 DEPENDENCIES

L<Alien::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Alien-librpm>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
