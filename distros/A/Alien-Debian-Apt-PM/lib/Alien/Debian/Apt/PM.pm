package Alien::Debian::Apt::PM;

use warnings;
use strict;

our $VERSION = '0.03';

1;


__END__

=head1 NAME

Alien::Debian::Apt::PM - install bundled apt-pm apt-cpan apt-pm-web dh-make-pm cpan-patches dpkg-scanpmpackages

=head1 SYNOPSIS

	apt-pm update
	apt-pm find Moose::Meta::Method
	apt-cpan install Pod::POM::Web

See:

=over 4

=item apt-cpan

L<http://search.cpan.org/perldoc?apt-cpan>

=item apt-pm

L<http://search.cpan.org/perldoc?apt-pm>

=item apt-pm-web

L<http://search.cpan.org/perldoc?apt-pm-web>

=item dh-make-pm

L<http://search.cpan.org/perldoc?dh-make-pm>

=item cpan-patches

L<http://search.cpan.org/perldoc?cpan-patches>

=item dpkg-scanpmpackages

L<http://search.cpan.org/perldoc?dpkg-scanpmpackages>

=back

=head1 DESCRIPTION

This alien was made to install L<PAR::Packer> created versions of scripts
provided or needed by L<Debian::Apt::PM>.

L<Alien::Debian::Apt::PM> has no dependencies besides L<Module::Build>, will
install one binary C<alien-debian-apt-pm> and create symlinks to it.

The result is having full functional and system Perl independent
C<apt-pm>, C<apt-cpan>, C<apt-pm-web>, C<dh-make-pm>, C<cpan-patches>,
C<dpkg-scanpmpackages> scripts.

=head1 INSTALL

=head2 get alien-debian-apt-pm

=head3 form CPAN

	cpan Alien::Debian::Apt::PM

=head3 manual set-up

	cd /usr/local/bin/
	wget https://github.com/jozef/Alien-Debian-Apt-PM/raw/master/script/alien-debian-apt-pm
	ln -s alien-debian-apt-pm apt-cpan
	ln -s alien-debian-apt-pm apt-pm
	ln -s alien-debian-apt-pm apt-pm-web
	ln -s alien-debian-apt-pm dh-make-pm
	ln -s alien-debian-apt-pm cpan-patches
	ln -s alien-debian-apt-pm dpkg-scanpmpackages

=head2 add pmindex repository

	echo "deb     http://alioth.debian.org/~jozef-guest/pmindex/     squeeze main contrib non-free" >> /etc/apt/sources.list

=head2 create apt-pm folders

	mkdir -p /var/cache/apt/apt-pm/deb
	mkdir -p /var/cache/apt/apt-pm/deb-src

=head1 USAGE

	apt-pm update
	apt-pm find Moose::Meta::Method
	apt-cpan -n install Pod::POM::Web

=head1 pp used

	pp 	-M Moose::Meta::Object::Trait -M Package::Stash::XS -M MetaCPAN::API \
		-M MetaCPAN::API::Author -M MetaCPAN::API::Module -M MetaCPAN::API::POD \
		-M MetaCPAN::API::Release -M Class::Load::PP -M CPAN::PackageDetails::Entries \
		-M CPAN::PackageDetails::Header -M CPAN::PackageDetails::Entry
		-o alien-debian-apt-pm \
		apt-pm apt-cpan apt-pm-web dh-make-pm cpan-patches dpkg-scanpmpackages

=head1 AUTHOR

Jozef Kutej

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
