use strict;
use warnings;
package Acme::CPANAuthors::Nonhuman; # git description: v0.024-4-gb0c43eb
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: We are non-human CPAN authors
# KEYWORDS: acmeism cpan authors animals fun

our $VERSION = '0.025';

use utf8;

# this data was generated at build time via __DATA__ section
# and Dist::Zilla::Plugin::MungeFile::WithDataSection 0.009
my %authors = (
    ETHER => 'Karen Etheridge',
    VOJ => 'Jakob Voß',
    IVANWILLS => 'Ivan Wills',
    MITHALDU => 'Christian Walde',
    DOLMEN => 'Olivier Mengué',
    ZDM => 'Dmytro Zagashev',
    ALTREUS => 'Alastair McGowan-Douglas',
    HIROSE => 'HIROSE Masaaki',
    KAARE => 'Kaare Rasmussen',
    AKXLIX => 'azuma, kuniyuki',
    BBAXTER => 'Brad Baxter',
    ABERNDT => 'Alan Berndt',
    ARUNBEAR => 'Arun Prasaad',
    IANKENT => 'Ian Kent',
    JTRAMMELL => 'John J. Trammell',
    SIMCOP => 'Ryan Voots',
    CARLOS => 'Carlos Lima',
    FGA => 'Fabrice Gabolde',
    SKINGTON => 'Sam Kington',
    AKIHITO => 'Akihito Takeda',
    GLEACH => 'Geoffrey Leach',
    MAXS => 'Maxime Soulé',
    ARUN => 'Arun Venkataraman',
    CKRAS => 'Christiaan Kras',
    EAST => 'Robert Ginko',
    INFRARED => 'Michael Kroher',
    NMELNICK => 'Nicholas Melnick',
    BAHOOTYPR => 'Bahootyper',
    BENW => 'Ben Wilber',
    BIGREDS => 'Avi Greenbury',
    DAIBA => '台場 圭一',
    EUGENEK => 'Eugene Kuzin',
    ROBMAN => 'Rob Manson',
    GAURAV => 'Gaurav Vaidya',
    ORCHEW => 'Cooper Vertz',
    PERLPIE => 'perlpie',
    SZARATE => 'Santiago Zarate',
    ZHDA => 'Denis Zhdanov',
);

my %avatar_urls = (
    ETHER => 'https://secure.gravatar.com/avatar/bdc5cd06679e732e262f6c1b450a0237?s=80&d=identicon',
    VOJ => 'http://www.gravatar.com/avatar/9827ddb7c8cb132375cf55bf7e624250?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fdcad11c6680a6c59cc31d2bf1b3975e5%3Fs%3D130%26d%3Didenticon',
    IVANWILLS => 'https://secure.gravatar.com/avatar/c668586858d59a94f3eb761903175f27?s=80&d=identicon',
    MITHALDU => 'https://secure.gravatar.com/avatar/d9c28af939032ab0c30fd7be8fdc1040?s=80&d=identicon',
    DOLMEN => 'https://secure.gravatar.com/avatar/70d9b050bfe39350c234d710fadfcd39?s=80',
    ZDM => 'https://secure.gravatar.com/avatar/f99956427457624457d0b626f492747d.png',
    ALTREUS => 'https://s.gravatar.com/avatar/f6ff3f40f3b6fdf036bff73832357634?s=80',
    HIROSE => 'https://secure.gravatar.com/avatar/9fdc92e131d7950e81895ca892b7a384?s=80&d=identicon',
    KAARE => 'https://secure.gravatar.com/avatar/4981bb322567b621afe038246f4dce1a?s=80&d=identicon',
    AKXLIX => 'https://secure.gravatar.com/avatar/22376afdd53ef1adc944c7168349cd8d?s=80&d=identicon',
    BBAXTER => 'https://secure.gravatar.com/avatar/af7986efb2374332f4babfaaef3b55d4?s=80&d=identicon',
    ABERNDT => 'https://secure.gravatar.com/avatar/888b4060c4844235ed6897de4946f9dd?s=80&d=identicon',
    ARUNBEAR => 'https://secure.gravatar.com/avatar/dc46344b5cdbf99fb62291b4eb9c4aef?s=80&d=identicon',
    IANKENT => 'https://secure.gravatar.com/avatar/7d3b3b7b9d22aadba754cade8781518c?s=80&d=identicon',
    JTRAMMELL => 'http://www.gravatar.com/avatar/6e8ddfd51613a0bb512abb09b64dafef?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F7fe2f580391d8c9089747010fada9d22%3Fs%3D130%26d%3Didenticon',
    SIMCOP => 'https://secure.gravatar.com/avatar/064ea1cf6dd27118fdbbc2b23d12266f?s=80&d=identicon',
    CARLOS => 'https://secure.gravatar.com/avatar/43d81f6a54ee06bf1190d16f25a2533a?s=80&d=identicon',
    FGA => 'https://secure.gravatar.com/avatar/a1a232556694ed753ac491703b7df184?s=80&d=identicon',
    SKINGTON => 'https://secure.gravatar.com/avatar/faf48a00fe1d8c7b282435f54f04c747?s=80&d=identicon',
    AKIHITO => 'https://secure.gravatar.com/avatar/3a1bdee47e9fdca1cdf3ce4f38651ba2?s=80&d=identicon',
    GLEACH => 'https://secure.gravatar.com/avatar/05cb19d7843c358211bfdc98be476b68?s=80&d=identicon',
    MAXS => 'https://secure.gravatar.com/avatar/55768f8a3f6cbfde7396a0a34b590181?s=80&d=identicon',
    ARUN => 'https://secure.gravatar.com/avatar/8a7e477f0a86af02355043e612baad57?s=80&d=identicon',
    CKRAS => 'https://secure.gravatar.com/avatar/4745757ad4050f5a2b1ec9c9fb2ff370?s=80&d=identicon',
    EAST => 'https://secure.gravatar.com/avatar/3cda0d4a4bad85c3b735812b00f8bd23?s=80&d=identicon',
    INFRARED => 'https://secure.gravatar.com/avatar/a6c59d0a6c1f0042e922ffc033710de0?s=80&d=identicon',
    NMELNICK => 'http://en.gravatar.com/userimage/885723/e55ab962842497b9bf4b7eaf1291cb22.png',
    BAHOOTYPR => 'https://secure.gravatar.com/avatar/297175ea2bf4953bce22d24a1aacc102?s=80&d=identicon',
    BENW => 'https://secure.gravatar.com/avatar/351511a02e1c1342d2626cb19e2bdd90?s=80&d=identicon',
    BIGREDS => 'https://secure.gravatar.com/avatar/0d456579ab7f4822420e87d6159bc9fa?s=80&d=identicon',
    DAIBA => 'https://secure.gravatar.com/avatar/f64fa36a1fe3c8e7b52cf6e5a21da302?s=80&d=identicon',
    EUGENEK => 'https://secure.gravatar.com/avatar/a4b9d7b53f4cdbee844f7c572fc3569c?s=80&d=identicon',
    ROBMAN => 'https://secure.gravatar.com/avatar/755e4df78c1aee18b172a67659ecc870?s=80&d=identicon',
    GAURAV => 'https://secure.gravatar.com/avatar/9a3fa34c402691c2f623cba58d01292e?s=80&d=identicon',
    ORCHEW => 'https://secure.gravatar.com/avatar/4a66363f9a279ce1a2914752a3b02b17?s=80&d=identicon',
    PERLPIE => 'https://secure.gravatar.com/avatar/cb9aa3bf6f061556cf82b103c62ebbfe?s=80&d=identicon',
    SZARATE => 'https://secure.gravatar.com/avatar/236a2d411a6c0ed05f9cc9e766b3df4e?s=80&d=identicon',
    ZHDA => 'https://secure.gravatar.com/avatar/404694046d02a4714216c13dce0761f4?s=80&d=identicon',
);
# end data generated at build time

sub authors { wantarray ? %authors : \%authors }

sub category { 'Nonhuman' }

sub avatar_url { return $avatar_urls{$_[1]} }

1;

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Nonhuman - We are non-human CPAN authors

=head1 VERSION

version 0.025

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Nonhuman;

    my $authors = Acme::CPANAuthors->new('Nonhuman');
    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('ETHER');
    my $url      = $authors->avatar_url('MITHALDU');
    my $kwalitee = $authors->kwalitee('GAURAV');

    my %authorshash    = Acme::CPANAuthors::Nonhuman->authors;
    my $authorshashref = Acme::CPANAuthors::Nonhuman->authors;
    my $category       = Acme::CPANAuthors::Nonhuman->category;

=head1 DESCRIPTION

This class provides a hash of PAUSE IDs and names of non-human CPAN authors.
On the internet, no one knows you're a cat (unless your avatar gives it away)!

=begin html

<div style="text-align:center;padding:0px!important;overflow-y:hidden;
margin-left: auto; margin-right: auto; max-width: 50%">

<!-- this data was generated at build time via __DATA__ section and Dist::Zilla::Plugin::MungeFile::WithDataSection 0.009 -->
<a href="http://metacpan.org/author/ETHER"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/bdc5cd06679e732e262f6c1b450a0237?s=80&d=identicon" alt="ETHER" title="ETHER (Karen Etheridge), 205 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/VOJ"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="http://www.gravatar.com/avatar/9827ddb7c8cb132375cf55bf7e624250?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fdcad11c6680a6c59cc31d2bf1b3975e5%3Fs%3D130%26d%3Didenticon" alt="VOJ" title="VOJ (Jakob Vo&szlig;), 73 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/IVANWILLS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/c668586858d59a94f3eb761903175f27?s=80&d=identicon" alt="IVANWILLS" title="IVANWILLS (Ivan Wills), 46 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/MITHALDU"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/d9c28af939032ab0c30fd7be8fdc1040?s=80&d=identicon" alt="MITHALDU" title="MITHALDU (Christian Walde), 35 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/DOLMEN"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/70d9b050bfe39350c234d710fadfcd39?s=80" alt="DOLMEN" title="DOLMEN (Olivier Mengu&eacute;), 26 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ZDM"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/f99956427457624457d0b626f492747d.png" alt="ZDM" title="ZDM (Dmytro Zagashev), 25 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ALTREUS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://s.gravatar.com/avatar/f6ff3f40f3b6fdf036bff73832357634?s=80" alt="ALTREUS" title="ALTREUS (Alastair McGowan-Douglas), 21 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/HIROSE"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/9fdc92e131d7950e81895ca892b7a384?s=80&d=identicon" alt="HIROSE" title="HIROSE (HIROSE Masaaki), 19 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/KAARE"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/4981bb322567b621afe038246f4dce1a?s=80&d=identicon" alt="KAARE" title="KAARE (Kaare Rasmussen), 14 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/AKXLIX"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/22376afdd53ef1adc944c7168349cd8d?s=80&d=identicon" alt="AKXLIX" title="AKXLIX (azuma, kuniyuki), 9 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/BBAXTER"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/af7986efb2374332f4babfaaef3b55d4?s=80&d=identicon" alt="BBAXTER" title="BBAXTER (Brad Baxter), 9 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ABERNDT"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/888b4060c4844235ed6897de4946f9dd?s=80&d=identicon" alt="ABERNDT" title="ABERNDT (Alan Berndt), 7 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ARUNBEAR"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/dc46344b5cdbf99fb62291b4eb9c4aef?s=80&d=identicon" alt="ARUNBEAR" title="ARUNBEAR (Arun Prasaad), 6 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/IANKENT"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/7d3b3b7b9d22aadba754cade8781518c?s=80&d=identicon" alt="IANKENT" title="IANKENT (Ian Kent), 6 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/JTRAMMELL"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="http://www.gravatar.com/avatar/6e8ddfd51613a0bb512abb09b64dafef?s=80&d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F7fe2f580391d8c9089747010fada9d22%3Fs%3D130%26d%3Didenticon" alt="JTRAMMELL" title="JTRAMMELL (John J. Trammell), 6 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/SIMCOP"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/064ea1cf6dd27118fdbbc2b23d12266f?s=80&d=identicon" alt="SIMCOP" title="SIMCOP (Ryan Voots), 6 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/CARLOS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/43d81f6a54ee06bf1190d16f25a2533a?s=80&d=identicon" alt="CARLOS" title="CARLOS (Carlos Lima), 5 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/FGA"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/a1a232556694ed753ac491703b7df184?s=80&d=identicon" alt="FGA" title="FGA (Fabrice Gabolde), 5 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/SKINGTON"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/faf48a00fe1d8c7b282435f54f04c747?s=80&d=identicon" alt="SKINGTON" title="SKINGTON (Sam Kington), 4 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/AKIHITO"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/3a1bdee47e9fdca1cdf3ce4f38651ba2?s=80&d=identicon" alt="AKIHITO" title="AKIHITO (Akihito Takeda), 3 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/GLEACH"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/05cb19d7843c358211bfdc98be476b68?s=80&d=identicon" alt="GLEACH" title="GLEACH (Geoffrey Leach), 3 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/MAXS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/55768f8a3f6cbfde7396a0a34b590181?s=80&d=identicon" alt="MAXS" title="MAXS (Maxime Soul&eacute;), 3 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ARUN"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/8a7e477f0a86af02355043e612baad57?s=80&d=identicon" alt="ARUN" title="ARUN (Arun Venkataraman), 2 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/CKRAS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/4745757ad4050f5a2b1ec9c9fb2ff370?s=80&d=identicon" alt="CKRAS" title="CKRAS (Christiaan Kras), 2 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/EAST"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/3cda0d4a4bad85c3b735812b00f8bd23?s=80&d=identicon" alt="EAST" title="EAST (Robert Ginko), 2 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/INFRARED"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/a6c59d0a6c1f0042e922ffc033710de0?s=80&d=identicon" alt="INFRARED" title="INFRARED (Michael Kroher), 2 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/NMELNICK"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="http://en.gravatar.com/userimage/885723/e55ab962842497b9bf4b7eaf1291cb22.png" alt="NMELNICK" title="NMELNICK (Nicholas Melnick), 2 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/BAHOOTYPR"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/297175ea2bf4953bce22d24a1aacc102?s=80&d=identicon" alt="BAHOOTYPR" title="BAHOOTYPR (Bahootyper), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/BENW"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/351511a02e1c1342d2626cb19e2bdd90?s=80&d=identicon" alt="BENW" title="BENW (Ben Wilber), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/BIGREDS"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/0d456579ab7f4822420e87d6159bc9fa?s=80&d=identicon" alt="BIGREDS" title="BIGREDS (Avi Greenbury), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/DAIBA"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/f64fa36a1fe3c8e7b52cf6e5a21da302?s=80&d=identicon" alt="DAIBA" title="DAIBA (&#x53F0;&#x5834; &#x572D;&#x4E00;), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/EUGENEK"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/a4b9d7b53f4cdbee844f7c572fc3569c?s=80&d=identicon" alt="EUGENEK" title="EUGENEK (Eugene Kuzin), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/ROBMAN"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/755e4df78c1aee18b172a67659ecc870?s=80&d=identicon" alt="ROBMAN" title="ROBMAN (Rob Manson), 1 distribution" /></span></a><!--
--><a href="http://metacpan.org/author/GAURAV"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/9a3fa34c402691c2f623cba58d01292e?s=80&d=identicon" alt="GAURAV" title="GAURAV (Gaurav Vaidya), 0 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ORCHEW"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/4a66363f9a279ce1a2914752a3b02b17?s=80&d=identicon" alt="ORCHEW" title="ORCHEW (Cooper Vertz), 0 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/PERLPIE"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/cb9aa3bf6f061556cf82b103c62ebbfe?s=80&d=identicon" alt="PERLPIE" title="PERLPIE (perlpie), 0 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/SZARATE"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/236a2d411a6c0ed05f9cc9e766b3df4e?s=80&d=identicon" alt="SZARATE" title="SZARATE (Santiago Zarate), 0 distributions" /></span></a><!--
--><a href="http://metacpan.org/author/ZHDA"><span><img style="margin: 0 5px 5px 0;" width="80" height="80" src="https://secure.gravatar.com/avatar/404694046d02a4714216c13dce0761f4?s=80&d=identicon" alt="ZHDA" title="ZHDA (Denis Zhdanov), 0 distributions" /></span></a>

</div>

=end html

The original list of authors was determined via
L<The Faces of CPAN|http://hexten.net/cpan-faces/>.

=for stopwords programmatically

I wrote this module initially as a reaction to a previous L<Acme::CPANAuthors>
distribution that inappropriately highlighted a particular demographic (it has
now since been deleted).  Then, I realized that so much of the content I
wanted to include in this module could be programmatically generated, so I
continued on as an exercise in templating code at build time using raw data in
the C<__DATA__> section.  That support code has since been split off into its
own distribution, L<Dist::Zilla::Plugin::MungeFile::WithDataSection>.

This module has continued to evolve, as rough edges in bits of the toolchain
are polished.  These improvements include:

=for stopwords metacpan

=over 4

=item *

better HTML rendering in L<metacpan|https://metacpan.org>

=item *

proper encoding handling in L<Dist::Zilla> and many of its plugins

=item *

parsing improvements in L<PPI>

=item *

heuristic refinement in kwalitee metrics in L<Module::CPANTS::Analyse>

=item *

additional interfaces added to L<Acme::CPANAuthors>

=back

=head1 METHODS

=head2 authors

Returns the hash of authors in list context, or a hashref in scalar context.

=head2 category

Returns C<'Nonhuman'>.

=head2 avatar_url

=for stopwords gravatar

Returns the gravatar url of the id shown on L<https://metacpan.org>. Note this
is B<not> necessarily the same result as C<< Acme::CPANAuthors->url($id) >>:
this module queries metacpan directly, where a user may have overridden the
gravatar in their profile; whereas L<Acme::CPANAuthors> (via L<Gravatar::URL>)
performs a lookup on the email address registered with PAUSE.

=head1 SEE ALSO

=over 4

=item *

L<Acme::CPANAuthors> - the main class to manipulate this one.

=back

=head1 SUPPORT

It may well be the case that some of the authors listed here are B<not>
actually non-human, in which case this absolutely must be reported immediately
so this module can be corrected! We of the furry and clawed will not stand for
imposters in our midst.

On the other hand, occasionally new brothers and sisters join the Perl family
and are not recognized here -- please let me know so they can be added to the
list.

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Nonhuman>
(or L<bug-Acme-CPANAuthors-Nonhuman@rt.cpan.org|mailto:bug-Acme-CPANAuthors-Nonhuman@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Graham Knop Carlos Lima Сергей Романов

=over 4

=item *

Graham Knop <haarg@haarg.org>

=item *

Carlos Lima <carlos@cpan.org>

=item *

Сергей Романов <sromanov@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# this list isn't sorted by name but by the date they were added
ETHER
MITHALDU
AKIHITO
BAHOOTYPR
BIGREDS
GAURAV
HIROSE
GLEACH
KAARE
ARUN
INFRARED
DOLMEN
AKXLIX
ARUNBEAR
IVANWILLS
BBAXTER
ABERNDT
MAXS
FGA
PERLPIE
DAIBA
ORCHEW
VOJ
ROBMAN
SIMCOP
SKINGTON
SZARATE
ZHDA
CARLOS
JTRAMMELL
BENW
NMELNICK
CKRAS
EAST
EUGENEK
ZDM
IANKENT
ALTREUS
