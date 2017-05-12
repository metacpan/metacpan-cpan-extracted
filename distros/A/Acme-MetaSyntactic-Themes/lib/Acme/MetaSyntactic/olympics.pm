package Acme::MetaSyntactic::olympics;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.002';

=head1 NAME

Acme::MetaSyntactic::olympics - Olympic cities theme

=head1 DESCRIPTION

This theme lists the cities who have hosted, or will host, Olympic Games.
Cities for both the Summer and Winter games are listed.

The list was originally fetched from L<http://www.olympic.org/>.

The following cities have held, or will hold, the Olympic games:

=cut

{
    my $data;
    my $season;

    for my $line ( split /\n/ => <<'=cut' ) {

=pod

    Summer Games
    ============

    2020   Tokyo
    2016   Rio de Janeiro
    2012   London
    2008   Beijing
    2004   Athens
    2000   Sydney
    1996   Atlanta
    1992   Barcelona
    1988   Seoul
    1984   Los Angeles
    1980   Moscow
    1976   Montreal
    1972   Munich
    1968   Mexico City
    1964   Tokyo
    1960   Rome
    1956   Melbourne
    1952   Helsinki
    1948   London
    1936   Berlin
    1932   Los Angeles
    1928   Amsterdam
    1924   Paris
    1920   Antwerp
    1912   Stockholm
    1908   London
    1904   Saint-Louis
    1900   Paris
    1896   Athens


    Winter Games
    ============

    2018   Pyeongchang
    2014   Sochi
    2010   Vancouver
    2006   Torino
    2002   Salt Lake City
    1998   Nagano
    1994   Lillehammer
    1992   Albertville
    1988   Calgary
    1984   Sarajevo
    1980   Lake Placid
    1976   Innsbruck
    1972   Sapporo
    1968   Grenoble
    1964   Innsbruck
    1960   Squaw Valley
    1956   Cortina d'Ampezzo
    1952   Oslo
    1948   Saint-Moritz
    1936   Garmisch-Partenkirchen
    1932   Lake Placid
    1928   Saint-Moritz
    1924   Chamonix

=cut

        $season = lc $1 and next if $line =~ /(\w+) Games/;
        next if $line !~ /^\s+(\d+)\s+(.*)/;
        my ( $year, $city ) = ( $1, $2 );
        $city =~ s/\W+/_/g;
        $data->{names}{$year}{$season} = $city;
        $data->{names}{$season}{$year} = $city;
    }
    $data->{default} = ':all';

    __PACKAGE__->init($data);
}

1;

__END__

=head1 CONTRIBUTORS

Abigail, Philippe Bruhat.

=head1 CHANGES

=over 4

=item *

2013-09-16 - v1.002

Turned into a multilist, with all combinations of year and seasons
as categories and the location for the 2020 summer olympics
in Acme-MetaSyntactic-Themes version 1.036.

=item *

2012-05-14 - v1.001

Updated by Abigail in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Updated with recent future Olympic cities, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-07-10

Introduced in Acme-MetaSyntactic version 0.82.

=item *

2006-01-26

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut
