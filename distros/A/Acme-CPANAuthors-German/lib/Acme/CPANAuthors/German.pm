package Acme::CPANAuthors::German;
BEGIN {
  $Acme::CPANAuthors::German::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Acme::CPANAuthors::German::VERSION = '0.04';
}
# ABSTRACT: We are German CPAN authors

use strict;
use warnings;
use utf8;

use Acme::CPANAuthors::Register (
    AGROLMS  => 'Achim Grolms',
    ANNO     => 'Anno Siegel',
    CFAERBER => 'Claus Färber',
    CORION   => 'Max Maischein',
    DATA     => 'Danijel Tašov',
    EIKEG    => 'Eike Grote',
    FANY     => 'Martin H. Sluka',
    FLORA    => 'Florian "rafl" Ragwitz',
    GETTY    => 'Torsten Raudssus',
    GRICHTER => 'Gerald Richter',
    HOLLI    => 'Markus Holzer',
    HORNBURG => 'Stefan Hornburg',
    HORSHACK => 'Richard Lippmann',
    JSTENZEL => 'Jochen Stenzel',
    MDOM     => 'Mario Domgörgen',
    MEMOWE   => 'Mirko Westermeier',
    MLEHMANN => 'Marc Lehmann',
    PHAYLON  => 'Robert \'phaylon\' Sedlacek',
    PLU      => 'Johannes Plunien',
    RBO      => 'Robert Bohne',
    RENEEB   => 'Renee Baecker',
    SCHWIGON => 'Steffen "renormalist" Schwigon',
    SMUELLER => 'Steffen Müller',
    SRI      => 'Sebastian Riedel',
    STEFFENW => 'Steffen Winkler',
    SULLR    => 'Steffen Ullrich',
    TINITA   => 'Tina Müller',
    TSCH     => 'Torsten Schönfeld',
    ULPFR    => 'Ulrich Pfeifer',
    UVOELKER => 'Uwe Voelker',
    WILLERT  => 'Sebastian Willert',
    WKI      => 'Wolfgang Kinkeldei',
);


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Acme::CPANAuthors::German - We are German CPAN authors

=head1 DESCRIPTION

This class provides a hash of Pause ID/name of German CPAN authors.

=head2 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::German;

    my $authors = Acme::CPANAuthors->new('German');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('RENEEB');
    my $url      = $authors->avatar_url('SCHWIGON');
    my $kwalitee = $authors->kwalitee('WILLERT');

=head1 MAINTENANCE

If you are an Austrian CPAN author and are not listed here, please mail me. If
you are listed and don't want to be, mail me as well.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

