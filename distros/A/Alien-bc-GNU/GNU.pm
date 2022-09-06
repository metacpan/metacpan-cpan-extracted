package Alien::bc::GNU;

use parent qw(Alien::Base);
use strict;
use warnings;

use Path::Tiny qw(path);

our $VERSION = 0.03;

sub exe {
	my $self = shift;

	return path($self->bin_dir, $self->runtime_prop->{'command'});
}

1;

__END__

=encoding UTF-8

=head1 NAME

Alien::bc::GNU - Find or download and install GNU bc.

=head1 SYNOPSIS

 use Alien::bc::GNU;

 my $atleast_version = Alien::bc::GNU->atleast_version($wanted_version);
 my $bin_dir = Alien::bc::GNU->bin_dir;
 my $dist_dir = Alien::bc::GNU->dist_dir;
 my $exact_version = Alien::bc::GNU->exact_version($wanted_version);
 my $install_type = Alien::bc::GNU->install_type;
 my $max_version = Alien::bc::GNU->max_version($wanted_version);
 my $version = Alien::bc::GNU->version;

=head1 DESCRIPTION

Some packages insist on using GNU bc tool.

This package detect system GNU bc tool or install own.

=head1 SUBROUTINES/METHODS

All methods are inherited from L<Alien::Base>.

=head1 CONFIGURATION AND ENVIRONMENT

Not yet.

=head1 EXAMPLE

=for comment filename=print_variables.pl

 use strict;
 use warnings;

 use Alien::bc::GNU;

 print 'bin_dir: '.Alien::bc::GNU->bin_dir."\n"
	if defined Alien::bc::GNU->bin_dir;
 print 'dist_dir: '.Alien::bc::GNU->dist_dir."\n";
 print 'install_type: '.Alien::bc::GNU->install_type."\n";
 print 'version: '.Alien::bc::GNU->version."\n";

 # Output like (share):
 # bin_dir: ~home/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-bc-GNU/bin
 # dist_dir: ~home/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-bc-GNU
 # install_type: share
 # version: 1.07.1

 # Output like (system):
 # dist_dir: ~home/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/auto/share/dist/Alien-bc-GNU
 # install_type: system
 # version: 1.07.1

=head1 DEPENDENCIES

L<Alien::Base>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Alien-bc-GNU>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
