package Acme::CPANAuthors::AnyEvent;

use 5.005;
use utf8;
use strict;
use warnings;

=encoding utf-8

=head1 NAME

Acme::CPANAuthors::AnyEvent - We are CPAN Authors of AnyEvent!

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

use Acme::CPANAuthors::Register(
	MLEHMANN   => 'Marc Lehmann', # Main AnyEvent author ;)
	AGRUNDMA   => 'Andy Grundman',
	BEPPU      => 'John Beppu',
	BLUET      => 'BlueT - Matthew Lien - Che-Ming Lien',
	CLKAO      => 'Chia-liang Kao',
	CORNELIUS  => 'Lin You An',
	DMAKI      => 'Daisuke Maki',
	DMITRYNOD  => 'Dmitrii Konstantinov',
	ELMEX      => 'Robin Redeker',
	FRANCKC    => 'Franck Cuny',
	GBARR      => 'Graham Barr',
	GUGOD      => 'Liu Kang Min',
	IKUTA      => 'Masahito Ikuta',
	JHTHORSEN  => 'Jan Henning Thorsen',
	JROCKWAY   => 'Jonathan Rockway',
	KARASIK    => 'Dmitry Karasik',
	KEROYON    => 'keroyonn',
	KEVINJ     => 'Kevin Jones',
	MART       => 'Martin Atkins',
	MELO       => 'Pedro Melo',
	MGRIMES    => 'Mark Grimes',
	MIKI       => 'Takeshi Miki',
	MIYAGAWA   => 'Tatsuhiko Miyagawa',
	MONS       => 'Mons Anderson',
	MSTPLBG    => 'Michael Stapelberg',
	NAIM       => 'Naim Shafiev',
	NUFFIN     => 'Yuval Kogman',
	PMAKHOLM   => 'Peter Makholm',
	PUNYTAN    => 'punipuni',
	SANKO      => 'Sanko Robinson',
	SEKIMURA   => 'Masayoshi Sekimura',
	TOKUHIROM  => 'Tokuhiro Matsuno',
	TYPESTER   => 'Daisuke Murase',
	VKRAMSKIH  => 'Vitaly Kramskikh',
	YANNK      => 'Yann Kerherve',
);

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new('AnyEvent');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("MLEHMANN");
    my $url      = $authors->avatar_url("ELMEX");
    my $kwalitee = $authors->kwalitee("MONS");
    my $name     = $authors->name("MIYAGAWA");

=head1 DESCRIPTION

This class provides a hash of L<AnyEvent> namespace CPAN Authors' PAUSE ID and name to the L<Acme::CPANAuthors> module.

It is currently statically generated information, I hope to make it dynamic in the future.

=head1 MAINTENANCE

If you are a AnyEvent CPAN author not listed here, please send us your ID/name via email or RT so we can always keep this module up to date.

And if you aren't a AnyEvent CPAN author listed here, please send us your ID/name via email or RT and we will remove your name.

=head1 CONTAINED AUTHORS

Now B<35> AnyEvent CPAN authors:

    MLEHMANN   => 'Marc Lehmann', # Main AnyEvent author ;) 

    AGRUNDMA   => 'Andy Grundman',
    BEPPU      => 'John Beppu',
    BLUET      => 'BlueT - Matthew Lien - Che-Ming Lien',
    CLKAO      => 'Chia-liang Kao',
    CORNELIUS  => 'Lin You An',
    DMAKI      => 'Daisuke Maki',
    DMITRYNOD  => 'Dmitrii Konstantinov',
    ELMEX      => 'Robin Redeker',
    FRANCKC    => 'Franck Cuny',
    GBARR      => 'Graham Barr',
    GUGOD      => 'Liu Kang Min',
    IKUTA      => 'Masahito Ikuta',
    JHTHORSEN  => 'Jan Henning Thorsen',
    JROCKWAY   => 'Jonathan Rockway',
    KARASIK    => 'Dmitry Karasik',
    KEROYON    => 'keroyonn',
    KEVINJ     => 'Kevin Jones',
    MART       => 'Martin Atkins',
    MELO       => 'Pedro Melo',
    MGRIMES    => 'Mark Grimes',
    MIKI       => 'Takeshi Miki',
    MIYAGAWA   => 'Tatsuhiko Miyagawa',
    MONS       => 'Mons Anderson',
    MSTPLBG    => 'Michael Stapelberg',
    NAIM       => 'Naim Shafiev',
    NUFFIN     => 'Yuval Kogman',
    PMAKHOLM   => 'Peter Makholm',
    PUNYTAN    => 'punipuni',
    SANKO      => 'Sanko Robinson',
    SEKIMURA   => 'Masayoshi Sekimura',
    TOKUHIROM  => 'Tokuhiro Matsuno',
    TYPESTER   => 'Daisuke Murase',
    VKRAMSKIH  => 'Vitaly Kramskikh',
    YANNK      => 'Yann Kerherve',

And we've written B<83> distros

=head1 SEE ALSO

=head2 The base

=over 4

=item * L<Acme::CPANAuthors>

=item * L<Acme::CPANAuthors::Register>

=back

=head2 The subject

=over 4

=item * L<AnyEvent>

=back

=head2 Fun and etc

=over 4

=item * L<Acme::CPANAuthors::Not>

We are not CPAN authors

=item * L<Acme::CPANAuthors::Acme::CPANAuthors::Authors>

We are CPAN authors who have authored Acme::CPANAuthors modules

=item * L<Acme::CPANAuthors::You::re_using>

We are the CPAN authors that have written the modules installed on your perl!

=item * L<Acme::CPANAuthors::POE>

We are CPAN Authors of POE

=back

=head2 Search

L<http://search.cpan.org/search?query=Acme%3A%3ACPANAuthors&mode=all>

L<http://search.cpan.org/search?query=AnyEvent&mode=all>

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::CPANAuthors::AnyEvent
