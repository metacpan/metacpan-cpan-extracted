package Alien::libpopt;

use parent qw(Alien::Base);
use strict;
use warnings;

our $VERSION = 0.01;

1;

__END__

=encoding UTF-8

=head1 NAME

Alien::libpopt - Find or download and install popt library.

=head1 SYNOPSIS

 use Alien::libpopt;

 my $atleast_version = Alien::libpopt->atleast_version($wanted_version);
 my $bin_dir = Alien::libpopt->bin_dir;
 my $cflags = Alien::libpopt->cflags;
 my $cflags_static = Alien::libpopt->cflags_static;
 my $dist_dir = Alien::libpopt->dist_dir;
 my $exact_version = Alien::libpopt->exact_version($wanted_version);
 my $install_type = Alien::libpopt->install_type;
 my $libs = Alien::libpopt->libs;
 my $libs_static = Alien::libpopt->libs_static;
 my $max_version = Alien::libpopt->max_version($wanted_version);
 my $version = Alien::libpopt->version;

=head1 DESCRIPTION

Some packages insist on using popt library.

This package detect system popt library or install own.

=head1 SUBROUTINES/METHODS

All methods are inherited from L<Alien::Base>.

=head1 CONFIGURATION AND ENVIRONMENT

Not yet.

=head1 EXAMPLE

=for comment filename=alien_libpopt_variables.pl

 use strict;
 use warnings;

 use Alien::libpopt;

 print 'cflags: '.Alien::libpopt->cflags."\n";
 print 'cflags_static: '.Alien::libpopt->cflags_static."\n";
 print 'dist_dir: '.Alien::libpopt->dist_dir."\n";
 print 'libs: '.Alien::libpopt->libs."\n";
 print 'libs_static: '.Alien::libpopt->libs_static."\n";
 print 'version: '.Alien::libpopt->version."\n";

 # Output like (Debian 11.7 system popt library):
 # cflags:  
 # cflags_static:  
 # dist_dir: /home/skim/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-libpopt
 # libs: -L/usr/lib/x86_64-linux-gnu -lpopt 
 # libs_static: -L/usr/lib/x86_64-linux-gnu -lpopt 
 # version: 1.18

=head1 DEPENDENCIES

L<Alien::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Alien-libpopt>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
