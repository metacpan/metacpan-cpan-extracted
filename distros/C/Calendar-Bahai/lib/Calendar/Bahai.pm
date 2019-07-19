package Calendar::Bahai;

$Calendar::Bahai::VERSION   = '0.53';
$Calendar::Bahai::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Bahai - Interface to the calendar used by Bahai faith.

=head1 VERSION

Version 0.53

=cut

use 5.006;
use Data::Dumper;

use Date::Bahai::Simple;
use Moo;
use namespace::autoclean;
with 'Calendar::Plugin::Renderer';

use overload q{""} => 'as_string', fallback => 1;

has year  => (is => 'rw', predicate => 1);
has month => (is => 'rw', predicate => 1);
has date  => (is => 'ro', default   => sub { Date::Bahai::Simple->new });

sub BUILD {
    my ($self) = @_;

    $self->date->validate_month($self->month) if $self->has_month;
    $self->date->validate_year($self->year)   if $self->has_year;

    unless ($self->has_year && $self->has_month) {
        $self->year($self->date->get_year);
        $self->month($self->date->month);
    }
}

=head1 DESCRIPTION

The  Bahai  calendar started from the original Badi calendar, created by the Bab.
The  Bahai  calendar  is  composed  of 19 months, each with 19 days. Years in the
Bahai  calendar  are  counted  from Thursday, 21 March 1844, the beginning of the
Bahai  Era  or Badi Era (abbreviated BE or B.E.). Year 1 BE thus began at sundown
20  March  1844.  Using the Bahai names for the weekday and month, day one of the
Bahai Era was Istijlal (Majesty), 1 Baha (Splendour) 1 BE.

   +----------------------------------------------------------------------------+
   |                             Baha      [172 BE]                             |
   +----------+----------+----------+----------+----------+----------+----------+
   |    Jamal |    Kamal |    Fidal |     Idal | Istijlal | Istiqlal |    Jalal |
   +----------+----------+----------+----------+----------+----------+----------+
   |                                                                 |        1 |
   +----------+----------+----------+----------+----------+----------+----------+
   |        2 |        3 |        4 |        5 |        6 |        7 |        8 |
   +----------+----------+----------+----------+----------+----------+----------+
   |        9 |       10 |       11 |       12 |       13 |       14 |       15 |
   +----------+----------+----------+----------+----------+----------+----------+
   |       16 |       17 |       18 |       19 |                                |
   +----------+----------+----------+----------+----------+----------+----------+

The package L<App::calendr> provides command line tool  C<calendr> to display the
supported calendars on the terminal.

=head1 SYNOPSIS

    use strict; use warnings;
    use Calendar::Bahai;

    # prints current month bahai calendar
    print Calendar::Bahai->new, "\n";
    print Calendar::Bahai->new->current, "\n";

    # prints bahai month calendar for the first month of year 172.
    print Calendar::Bahai->new({ month => 1, year => 172 }), "\n";

    # prints bahai month calendar in which the given gregorian date falls in.
    print Calendar::Bahai->new->from_gregorian(2015, 1, 14), "\n";

    # prints bahai month calendar in which the given julian date falls in.
    print Calendar::Bahai->new->from_julian(2457102.5), "\n";

    # prints current month bahai calendar in SVG format.
    print Calendar::Bahai->new->as_svg;

    # prints current month bahai calendar in text format.
    print Calendar::Bahai->new->as_text;

=head1 BAHAI MONTHS

    +-------+-------------+----------------+------------------------------------+
    | Month | Arabic Name | English Name   | Gregorian Dates                    |
    +-------+-------------+----------------+------------------------------------+
    | 1     | Baha        | Splendour      | 21 Mar - 08 Apr                    |
    | 2     | Jalal       | Glory          | 09 Apr - 27 Apr                    |
    | 3     | Jamal       | Beauty         | 28 Apr - 16 May                    |
    | 4     | Azamat      | Grandeur       | 17 May - 04 Jun                    |
    | 5     | Nur         | Light          | 05 Jun - 23 Jun                    |
    | 6     | Rahmat      | Mercy          | 24 Jun - 12 Jul                    |
    | 7     | Kalimat     | Words          | 13 Jul - 31 Jul                    |
    | 8     | Kamal       | Perfection     | 01 Aug - 19 Aug                    |
    | 9     | Asma        | Names          | 20 Aug - 07 Sep                    |
    | 10    | Izzat       | Might          | 08 Sep - 26 Sep                    |
    | 11    | Mashiyyat   | Will           | 27 Sep - 15 Oct                    |
    | 12    | Ilm         | Knowledge      | 16 Oct - 03 Nov                    |
    | 13    | Qudrat      | Power          | 04 Nov - 22 Nov                    |
    | 14    | Qawl        | Speech         | 23 Nov - 11 Dec                    |
    | 15    | Masail      | Questions      | 12 Dec - 30 Dec                    |
    | 16    | Sharaf      | Honour         | 31 Dec - 18 Jan                    |
    | 17    | Sultan      | Sovereignty    | 19 Jan - 06 Feb                    |
    | 18    | Mulk        | Dominion       | 07 Feb - 25 Feb                    |
    |       | Ayyam-i-Ha  | The Days of Ha | 26 Feb - 01 Mar                    |
    | 19    | Ala         | Loftiness      | 02 Mar - 20 Mar (Fasting Month)    |
    +-------+-------------+----------------+------------------------------------+

=head1 BAHAI DAYS

    +-------------+--------------+----------------------------------------------+
    | Arabic Name | English Name | Day of the Week                              |
    +-------------+--------------+----------------------------------------------+
    | Jamal       | Beauty       | Sunday                                       |
    | Kamal       | Perfection   | Monday                                       |
    | Fidal       | Grace        | Tuesday                                      |
    | Idal        | Justice      | Wednesday                                    |
    | Istijlal    | Majesty      | Thursday                                     |
    | Istiqlal    | Independence | Friday                                       |
    | Jalal       | Glory        | Saturday                                     |
    +-------------+--------------+----------------------------------------------+

=head1 KULL-i-SHAY / VAHID

Also  existing in the Bahai calendar system is a 19-year cycle called Vahid and a
361-year (19x19) supercycle called Kull-i-Shay (literally, "All Things"). Each of
the 19 years in a Vahid has been given a name as shown in the table below.The 9th
Vahid of the 1st Kull-i-Shay  started  on 21 March 1996,  and the 10th Vahid will
begin in 2015. The current Bahai year,year 168 BE (21 March 2011 - 20 March 2012)
,  is year Badi of the 9th Vahid of the 1st Kull-i-Shay. The 2nd Kull-i-Shay will
begin in 2205.

=head2 1st Kull-i-Shay

    +----+--------+---------------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+
    | No.| Name   | Meaning       | 1    | 2    | 3    | 4    | 5    | 6    | 7    | 8    | 9    | 10   | 11   | 12   | 13   | 14   | 15   | 16   | 17   | 18   | 19   |
    +----+--------+---------------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+
    |  1 | Alif   | A             | 1844 | 1863 | 1882 | 1901 | 1920 | 1939 | 1958 | 1977 | 1996 | 2015 | 2034 | 2053 | 2072 | 2091 | 2110 | 2129 | 2148 | 2167 | 2186 |
    |  2 | Ba     | B             | 1845 | 1864 | 1883 | 1902 | 1921 | 1940 | 1959 | 1978 | 1997 | 2016 | 2035 | 2054 | 2073 | 2092 | 2111 | 2130 | 2149 | 2168 | 2187 |
    |  3 | Ab     | Father        | 1846 | 1865 | 1884 | 1903 | 1922 | 1941 | 1960 | 1979 | 1998 | 2017 | 2036 | 2055 | 2074 | 2093 | 2112 | 2131 | 2150 | 2169 | 2188 |
    |  4 | Dal    | D             | 1847 | 1866 | 1885 | 1904 | 1923 | 1942 | 1961 | 1980 | 1999 | 2018 | 2037 | 2056 | 2075 | 2094 | 2113 | 2132 | 2151 | 2170 | 2189 |
    |  5 | Bab    | Gate          | 1848 | 1867 | 1886 | 1905 | 1924 | 1943 | 1962 | 1981 | 2000 | 2019 | 2038 | 2057 | 2076 | 2095 | 2114 | 2133 | 2152 | 2171 | 2190 |
    |  6 | Vav    | V             | 1849 | 1868 | 1887 | 1906 | 1925 | 1944 | 1963 | 1982 | 2001 | 2020 | 2039 | 2058 | 2077 | 2096 | 2115 | 2134 | 2153 | 2172 | 2191 |
    |  7 | Abad   | Eternity      | 1850 | 1869 | 1888 | 1907 | 1926 | 1945 | 1964 | 1983 | 2002 | 2021 | 2040 | 2059 | 2078 | 2097 | 2116 | 2135 | 2154 | 2173 | 2192 |
    |  8 | Jad    | Generosity    | 1851 | 1870 | 1889 | 1908 | 1927 | 1946 | 1965 | 1984 | 2003 | 2022 | 2041 | 2060 | 2079 | 2098 | 2117 | 2136 | 2155 | 2174 | 2193 |
    |  9 | Baha   | Splendour     | 1852 | 1871 | 1890 | 1909 | 1928 | 1947 | 1966 | 1985 | 2004 | 2023 | 2042 | 2061 | 2080 | 2099 | 2118 | 2137 | 2156 | 2175 | 2194 |
    | 10 | Hubb   | Love          | 1853 | 1872 | 1891 | 1910 | 1929 | 1948 | 1967 | 1986 | 2005 | 2024 | 2043 | 2062 | 2081 | 2100 | 2119 | 2138 | 2157 | 2176 | 2195 |
    | 11 | Bahhaj | Delightful    | 1854 | 1873 | 1892 | 1911 | 1930 | 1949 | 1968 | 1987 | 2006 | 2025 | 2044 | 2063 | 2082 | 2101 | 2120 | 2139 | 2158 | 2177 | 2196 |
    | 12 | Javab  | Answer        | 1855 | 1874 | 1893 | 1912 | 1931 | 1950 | 1969 | 1988 | 2007 | 2026 | 2045 | 2064 | 2083 | 2102 | 2121 | 2140 | 2159 | 2178 | 2197 |
    | 13 | Ahad   | Single        | 1856 | 1875 | 1894 | 1913 | 1932 | 1951 | 1970 | 1989 | 2008 | 2027 | 2046 | 2065 | 2084 | 2103 | 2122 | 2141 | 2160 | 2179 | 2198 |
    | 14 | Vahhab | Bountiful     | 1857 | 1876 | 1895 | 1914 | 1933 | 1952 | 1971 | 1990 | 2009 | 2028 | 2047 | 2066 | 2085 | 2104 | 2123 | 2142 | 2161 | 2180 | 2199 |
    | 15 | Vidad  | Affection     | 1858 | 1877 | 1896 | 1915 | 1934 | 1953 | 1972 | 1991 | 2010 | 2029 | 2048 | 2067 | 2086 | 2105 | 2124 | 2143 | 2162 | 2181 | 2200 |
    | 16 | Badi   | Beginning     | 1859 | 1878 | 1897 | 1916 | 1935 | 1954 | 1973 | 1992 | 2011 | 2030 | 2049 | 2068 | 2087 | 2106 | 2125 | 2144 | 2163 | 2182 | 2201 |
    | 17 | Bahi   | Luminous      | 1860 | 1879 | 1898 | 1917 | 1936 | 1955 | 1974 | 1993 | 2012 | 2031 | 2050 | 2069 | 2088 | 2107 | 2126 | 2145 | 2164 | 2183 | 2202 |
    | 18 | Abha   | Most Luminous | 1861 | 1880 | 1899 | 1918 | 1937 | 1956 | 1975 | 1994 | 2013 | 2032 | 2051 | 2070 | 2089 | 2108 | 2127 | 2146 | 2165 | 2184 | 2203 |
    | 19 | Vahid  | Unity         | 1862 | 1881 | 1900 | 1919 | 1938 | 1957 | 1976 | 1995 | 2014 | 2033 | 2052 | 2071 | 2090 | 2109 | 2128 | 2147 | 2166 | 2185 | 2204 |
    +----+--------+---------------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+------+

=head1 NOTE

On July 10, 2014, the  Universal  House  of  Justice  announced  three  decisions
regarding the Badi` (Bahai) calendar,  which  will affect the dates of Feasts and
Holy Days. Naw Ruz will usually fall on March 20th,which means that all the Feast
days will be one day earlier,and the births of the Bab and of Baha'u'llah will be
celebrated on two consecutive days in the Autumn.The changes take effect from the
next Bahai New Year, from sunset on March 20, 2015. The definitive tables showing
the new dates have not yet been released (as of September 24, 2014), but there is
a preliminary discussion L<here|http://senmcglinn.wordpress.com/2014/09/22/changes-in-bahai-calendar-what-how-why>.

=head1 CONSTRUCTOR

It expects month and year  optionally. By default it gets current Bahai month and
year.

=head1 METHODS

=head2 current()

Returns current month of the Bahai calendar.

=cut

sub current {
    my ($self) = @_;

    return $self->as_text($self->date->month, $self->date->year);
}

=head2 from_gregorian($year, $month, $day)

Returns bahai month calendar in which the given gregorian date falls in.

=cut

sub from_gregorian {
    my ($self, $year, $month, $day) = @_;

    return $self->from_julian($self->date->gregorian_to_julian($year, $month, $day));
}

=head2 from_julian($julian_date)

Returns bahai month calendar in which the given julian date falls in.

=cut

sub from_julian {
    my ($self, $julian_date) = @_;

    my $date = $self->date->from_julian($julian_date);
    return $self->as_text($date->month, $date->year);
}

=head2 as_svg($month, $year)

Returns  calendar  for  the given C<$month> and C<$year> rendered  in SVG format.
C<$month>  can  be  a  number  between  1 and  19 or a valid Bahai month name. If
C<$month> and C<$year> missing, it would return current calendar month.

=cut

sub as_svg {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = $self->date->get_date(1, $month, $year);

    return $self->svg_calendar(
        {
            adjust_height => 21,
            start_index   => $date->day_of_week,
            month_name    => $date->get_month_name,
            days          => 19,
            year          => $year
        });
}

=head2 as_text($month, $year)

Returns color coded Bahai calendar for the given C<$month> and C<$year>. C<$month>
can  be  a  number between 1 and 19 or a valid Bahai month name. If C<$month> and
C<$year> missing, it would return current calendar month.

=cut

sub as_text {
    my ($self, $month, $year) = @_;

    ($month, $year) = $self->validate_params($month, $year);
    my $date = $self->date->get_date(1, $month, $year);

    return $self->text_calendar(
        {
            start_index => $date->day_of_week,
            month_name  => $date->get_month_name($month),
            days        => 19,
            day_names   => $date->days,
            year        => $year
        });
}

sub as_string {
    my ($self) = @_;

    return $self->as_text($self->month, $self->year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Bahai>

=head1 SEE ALSO

=over 4

=item L<Calendar::Gregorian>

=item L<Calendar::Hijri>

=item L<Calendar::Persian>

=item L<Calendar::Saka>

=back

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-bahai at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Bahai>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Bahai

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Bahai>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Bahai>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Bahai>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Bahai/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Calendar::Bahai
