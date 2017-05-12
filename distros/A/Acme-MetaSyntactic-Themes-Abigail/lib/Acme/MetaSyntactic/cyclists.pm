package Acme::MetaSyntactic::cyclists;

use strict;
use warnings;
no  warnings 'syntax';

use Acme::MetaSyntactic::MultiList;
our @ISA = qw [Acme::MetaSyntactic::MultiList];

our $VERSION = '2013072602';

my $data;

$$data {default} = "world_championships/road";

=pod

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::cyclists - Winners of major cycling events

=head1 DESCRIPTION

This C<< Acme::MetaSyntactic >> theme provides winners of major 
cycling events. 

The following subthemes are provided:

=over 1

=item C<< world_championships/road >>

The winners of the World Championships Men's Road Race, held annually
since 1927:

=cut

$$data {names} {world_championships} {road} = do {
    my %seen;
    join ' ' =>
    grep {!$seen {$_} ++}
    map  {Acme::MetaSyntactic::RemoteList::tr_nonword ($_)}
    map  {Acme::MetaSyntactic::RemoteList::tr_accent  ($_)}
    map  {/^\s+[0-9]{4}\s+(.*?)\s+[A-Z]{3}$/ ? $1 : ()}
    split /\n/ => <<'=cut'};

=pod

  2012      Philippe Gilbert      BEL
  2011      Mark Cavendish        GBR
  2010      Thor Hushovd          NOR
  2009      Cadel Evans           AUS
  2008      Alessandro Ballan     ITA
  2007      Paolo Bettini         ITA
  2006      Paolo Bettini         ITA
  2005      Tom Boonen            BEL
  2004      Óscar Freire          ESP
  2003      Igor Astarloa         ESP
  2002      Mario Cipollini       ITA
  2001      Óscar Freire          ESP
  2000      Romans Vainsteins     LAT
  1999      Óscar Freire          ESP
  1998      Oscar Camenzind       SUI
  1997      Laurent Brochard      FRA
  1996      Johan Museeuw         BEL
  1995      Abraham Olano         ESP
  1994      Luc Leblanc           FRA
  1993      Lance Armstrong       USA
  1992      Gianni Bugno          ITA
  1991      Gianni Bugno          ITA
  1990      Rudy Dhaenens         BEL
  1989      Greg LeMond           USA
  1988      Maurizio Fondriest    ITA
  1987      Stephen Roche         IRL
  1986      Moreno Argentin       ITA
  1985      Joop Zoetemelk        NED
  1984      Claude Criquielion    BEL
  1983      Greg LeMond           USA
  1982      Giuseppe Saronni      ITA
  1981      Freddy Maertens       BEL
  1980      Bernard Hinault       FRA
  1979      Jan Raas              NED
  1978      Gerrie Knetemann      NED
  1977      Francesco Moser       ITA
  1976      Freddy Maertens       BEL
  1975      Hennie Kuiper         NED
  1974      Eddy Merckx           BEL
  1973      Felice Gimondi        ITA
  1972      Marino Basso          ITA
  1971      Eddy Merckx           BEL
  1970      Jean-Pierre Monseré   BEL
  1969      Harm Ottenbros        NED
  1968      Vittorio Adorni       ITA
  1967      Eddy Merckx           BEL
  1966      Rudi Altig            FRG
  1965      Tom Simpson           GBR
  1964      Jan Janssen           NED
  1963      Benoni Beheyt         BEL
  1962      Jean Stablinski       FRA
  1961      Rik van Looy          BEL
  1960      Rik van Looy          BEL
  1959      André Darrigade       FRA
  1958      Ercole Baldini        ITA
  1957      Rik Van Steenbergen   BEL
  1956      Rik Van Steenbergen   BEL
  1955      Stan Ockers           BEL
  1954      Louison Bobet         FRA
  1953      Fausto Coppi          ITA
  1952      Heinz Müller          FRG
  1951      Ferdi Kübler          SUI
  1950      Briek Schotte         BEL
  1949      Rik Van Steenbergen   BEL
  1948      Briek Schotte         BEL
  1947      Theo Middelkamp       NED
  1946      Hans Knecht           SUI
  1939-1945 Suspended due to World War II
  1938      Marcel Kint           BEL
  1937      Eloi Meulenberg       BEL
  1936      Antonin Magne         FRA
  1935      Jean Aerts            BEL
  1934      Karel Kaers           BEL
  1933      Georges Speicher      FRA
  1932      Alfredo Binda         ITA
  1931      Learco Guerra         ITA
  1930      Alfredo Binda         ITA
  1929      Georges Ronsse        BEL
  1928      Georges Ronsse        BEL
  1927      Alfredo Binda         ITA

=cut

=item C<< tour >>

The winners of the I<< Tour de France >>, held annually since 1903, and
suspended due to World War I and World War II:

=cut

$$data {names} {tour} = do {
    my %seen;
    join ' ' =>
    grep {!$seen {$_} ++}
    map  {Acme::MetaSyntactic::RemoteList::tr_nonword ($_)}
    map  {Acme::MetaSyntactic::RemoteList::tr_accent  ($_)}
    map  {/^\s+[0-9]{4}\s+(.*?)\s+[A-Z]{3}$/ ? $1 : ()}
    split /\n/ => <<'=cut'};

=pod

  2013      Chris Froome          GBR
  2012      Bradley Wiggins       GBR
  2011      Cadel Evans           AUS
  2010      Andy Schleck          LUX
  2009      Alberto Contador      ESP
  2008      Carlos Sastre         ESP
  2007      Alberto Contador      ESP
  2006      Óscar Pereiro         ESP
  2005      (vacated)
  2004      (vacated)
  2003      (vacated)
  2002      (vacated)
  2001      (vacated)
  2000      (vacated)
  1999      (vacated)
  1998      Marco Pantani         ITA
  1997      Jan Ullrich           GER
  1996      Bjarne Riis           DEN
  1995      Miguel Indurain       ESP
  1994      Miguel Indurain       ESP
  1993      Miguel Indurain       ESP
  1992      Miguel Indurain       ESP
  1991      Miguel Indurain       ESP
  1990      Greg Lemond           USA
  1989      Greg Lemond           USA
  1988      Pedro Delgado         ESP
  1987      Stephen Roche         IRL
  1986      Greg Lemond           USA
  1985      Bernard Hinault       FRA
  1984      Laurent Fignon        FRA
  1983      Laurent Fignon        FRA
  1982      Bernard Hinault       FRA
  1981      Bernard Hinault       FRA
  1980      Joop Zoetemelk        NED
  1979      Bernard Hinault       FRA
  1978      Bernard Hinault       FRA
  1977      Bernard Thévenet      FRA
  1976      Lucien Van Impe       BEL
  1975      Bernard Thévenet      FRA
  1974      Eddy Merckx           BEL
  1973      Luis Ocana            ESP
  1972      Eddy Merckx           BEL
  1971      Eddy Merckx           BEL
  1970      Eddy Merckx           BEL
  1969      Eddy Merckx           BEL
  1968      Jan Janssen           NED
  1967      Roger Pingeon         FRA
  1966      Lucien Aimar          FRA
  1965      Felice Gimondi        ITA
  1964      Jacques Anquetil      FRA
  1963      Jacques Anquetil      FRA
  1962      Jacques Anquetil      FRA
  1961      Jacques Anquetil      FRA
  1960      Gastone Nencini       ITA
  1959      Federico Bahamontès   ESP
  1958      Charly Gaul           LUX
  1957      Jacques Anquetil      FRA
  1956      Roger Walkowiak       FRA
  1955      Louison Bobet         FRA
  1954      Louison Bobet         FRA
  1953      Louison Bobet         FRA
  1952      Fausto Coppi          ITA
  1951      Hugo Koblet           SUI
  1950      Ferdi Kubler          SUI
  1949      Fausto Coppi          ITA
  1948      Gino Bartali          ITA
  1947      Jean Robic            FRA
  1940-1946 Suspended due to World War II
  1939      Sylvère Maes          BEL
  1938      Gino Bartali          ITA
  1937      Roger Labépie         FRA
  1936      Sylvère Maes          BEL
  1935      Romain Maes           BEL
  1934      Antonin Magne         FRA
  1933      Georges Speicher      FRA
  1932      André Leducq          FRA
  1931      Antonin Magne         FRA
  1930      André Leducq          FRA
  1929      Maurice Dewaele       BEL
  1928      Nicolas Frantz        LUX
  1927      Nicolas Frantz        LUX
  1926      Lucien Buysse         BEL
  1925      Ottavio Bottecchia    ITA
  1924      Ottavio Bottecchia    ITA
  1923      Henri Pélissier       FRA
  1922      Firmin Lambot         BEL
  1921      Léon Scieur           BEL
  1920      Philippe Thijs        BEL
  1919      Firmin Lambot         BEL
  1915-1918 Suspended due to World War I
  1914      Philippe Thijs        BEL
  1913      Philippe Thijs        BEL
  1912      Odile Defraye         BEL
  1911      Gustavo Garrigou      FRA
  1910      Octave Lapize         FRA
  1909      François Faber        LUX
  1908      Lucien Petit-Breton   FRA
  1907      Lucien Petit-Breton   FRA
  1906      René Pottier          FRA
  1905      Louis Trousselier     FRA
  1904      Henri Cornet          FRA
  1903      Maurice Garin         FRA

=cut

=item C<< giro >>

The winners of the I<< Giro d'Italia >>, held annually since 1909, and
suspended due to World War I and World War II:

=cut

$$data {names} {giro} = do {
    my %seen;
    join ' ' =>
    grep {!$seen {$_} ++}
    map  {Acme::MetaSyntactic::RemoteList::tr_nonword ($_)}
    map  {Acme::MetaSyntactic::RemoteList::tr_accent  ($_)}
    map  {/^\s+[0-9]{4}\s+(.*?)\s+[A-Z]{3}$/ ? $1 : ()}
    split /\n/ => <<'=cut'};

=pod

  2013      Vincenzo Nibali       ITA
  2012      Ryder Hesjedal        CAN
  2011      Michele Scarponi      ITA
  2010      Ivan Basso            ITA
  2009      Denis Menchov         RUS
  2008      Alberto Contador      ESP
  2007      Danilo Di Luca        ITA
  2006      Ivan Basso            ITA
  2005      Paolo Savoldelli      ITA
  2004      Damiano Cunego        ITA
  2003      Gilberto Simoni       ITA
  2002      Paolo Savoldelli      ITA
  2001      Gilberto Simoni       ITA
  2000      Stefano Garzelli      ITA
  1999      Ivan Gotti            ITA
  1998      Marco Pantani         ITA
  1997      Ivan Gotti            ITA
  1996      Pavel Tonkov          RUS
  1995      Tony Rominger         SUI
  1994      Evgeni Berzin         RUS
  1993      Miguel Indurain       ESP
  1992      Miguel Indurain       ESP
  1991      Franco Chioccioli     ITA
  1990      Gianni Bugno          ITA
  1989      Laurent Fignon        FRA
  1988      Andrew Hampsten       USA
  1987      Stephen Roche         IRL
  1986      Roberto Visentini     ITA
  1985      Bernard Hinault       FRA
  1984      Francesco Moser       ITA
  1983      Giuseppe Saronni      ITA
  1982      Bernard Hinault       FRA
  1981      Giovanni Battaglin    ITA
  1980      Bernard Hinault       FRA
  1979      Giuseppe Saronni      ITA
  1978      Johan de Muynck       BEL
  1977      Michel Pollentier     BEL
  1976      Felice Gimondi        ITA
  1975      Fausto Bertoglio      ITA
  1974      Eddy Merckx           BEL
  1973      Eddy Merckx           BEL
  1972      Eddy Merckx           BEL
  1971      Gösta Pettersson      SWE
  1970      Eddy Merckx           BEL
  1969      Felice Gimondi        ITA
  1968      Eddy Merckx           BEL
  1967      Felice Gimondi        ITA
  1966      Gianni Motta          ITA
  1965      Vittorio Adorni       ITA
  1964      Jacques Anquetil      FRA
  1963      Franco Balmamion      ITA
  1962      Franco Balmamion      ITA
  1961      Arnaldo Pambianco     ITA
  1960      Jacques Anquetil      FRA
  1959      Charly Gaul           LUX
  1958      Ercole Baldini        ITA
  1957      Gastone Nencini       ITA
  1956      Charly Gaul           LUX
  1955      Fiorenzo Magni        ITA
  1954      Carlo Clerici         SUI
  1953      Fausto Coppi          ITA
  1952      Fausto Coppi          ITA
  1951      Fiorenzo Magni        ITA
  1950      Hugo Koblet           SUI
  1949      Fausto Coppi          ITA
  1948      Fiorenzo Magni        ITA
  1947      Fausto Coppi          ITA
  1946      Gino Bartali          ITA
  1941-1945 Suspended due to World War II
  1940      Fausto Coppi          ITA
  1939      Giovanni Valetti      ITA
  1938      Giovanni Valetti      ITA
  1937      Gino Bartali          ITA
  1936      Gino Bartali          ITA
  1935      Vasco Bergamaschi     ITA
  1934      Learco Guerra         ITA
  1933      Alfredo Binda         ITA
  1932      Antonio Pesenti       ITA
  1931      Francesco Camusso     ITA
  1930      Luigi Marchisio       ITA
  1929      Alfredo Binda         ITA
  1928      Alfredo Binda         ITA
  1927      Alfredo Binda         ITA
  1926      Giovanni Brunero      ITA
  1925      Alfredo Binda         ITA
  1924      Giuseppe Enrici       ITA
  1923      Costante Girardengo   ITA
  1922      Giovanni Brunero      ITA
  1921      Giovanni Brunero      ITA
  1920      Gaetano Belloni       ITA
  1919      Costante Girardengo   ITA
  1915-1918 Suspended due to World War I
  1914      Alfonso Calzolari     ITA
  1913      Carlo Oriani          ITA
  1912      Team Atala            ITA
  1911      Carlo Galetti         ITA
  1910      Carlo Galetti         ITA
  1909      Luigi Ganna           ITA

=cut

=item C<< vuelta >>

The winners of the I<< Vuelta a EspaE<241>a >>, held since 1935, annually 
since 1955:

=cut

$$data {names} {vuelta} = do {
    my %seen;
    join ' ' =>
    grep {!$seen {$_} ++}
    map  {Acme::MetaSyntactic::RemoteList::tr_nonword ($_)}
    map  {Acme::MetaSyntactic::RemoteList::tr_accent  ($_)}
    map  {/^\s+[0-9]{4}\s+(.*?)\s+[A-Z]{3}$/ ? $1 : ()}
    split /\n/ => <<'=cut'};

=pod

  2012   Alberto Contador      ESP
  2011   Juan José Cobo        ESP
  2010   Vincenzo Nibali       ITA
  2009   Alejandro Valverde    ESP
  2008   Alberto Contador      ESP
  2007   Denis Menchov         RUS
  2006   Alexandre Vinokourov  KAZ
  2005   Denis Menchov         RUS
  2004   Roberto Heras         ESP
  2003   Roberto Heras         ESP
  2002   Aitor González        ESP
  2001   Ángel Casero          ESP
  2000   Roberto Heras         ESP
  1999   Jan Ullrich           GER
  1998   Abraham Olano         ESP
  1997   Alex Zülle            SUI
  1996   Alex Zülle            SUI
  1995   Laurent Jalabert      FRA
  1994   Tony Rominger         SUI
  1993   Tony Rominger         SUI
  1992   Tony Rominger         SUI
  1991   Melchor Mauri         ESP
  1990   Marco Giovannetti     ITA
  1989   Pedro Delgado         ESP
  1988   Sean Kelly            IRL
  1987   Lucho Herrera         COL
  1986   Álvaro Pino           ESP
  1985   Pedro Delgado         ESP
  1984   Eric Caritoux         FRA
  1983   Bernard Hinault       FRA
  1982   Marino Lejarreta      ESP
  1981   Giovanni Battaglin    ITA
  1980   Faustino Rupérez      ESP
  1979   Joop Zoetemelk        NED
  1978   Bernard Hinault       FRA
  1977   Freddy Maertens       BEL
  1976   José Pesarrodona      ESP
  1975   Agustín Tamames       ESP
  1974   José Manuel Fuente    ESP
  1973   Eddy Merckx           BEL
  1972   José Manuel Fuente    ESP
  1971   Ferdinand Bracke      BEL
  1970   Luis Ocaña            ESP
  1969   Roger Pingeon         FRA
  1968   Felice Gimondi        ITA
  1967   Jan Janssen           NED
  1966   Francisco Gabica      ESP
  1965   Rolf Wolfshohl        GER
  1964   Raymond Poulidor      FRA
  1963   Jacques Anquetil      FRA
  1962   Rudi Altig            GER
  1961   Angelino Soler        ESP
  1960   Franz De Mulder       BEL
  1959   Antonio Suárez        ESP
  1958   Jean Stablinski       FRA
  1957   Jesús Loroño          ESP
  1956   Angelo Conterno       ITA
  1955   Jean Dotto            FRA
  1950   Emilio Rodríguez      ESP
  1948   Bernardo Ruiz         ESP
  1947   Edouard van Dyck      BEL
  1946   Dalmacio Langarica    ESP
  1945   Delio Rodríguez       ESP
  1942   Julián Berrendero     ESP
  1941   Julián Berrendero     ESP
  1936   Gustaaf Deloor        BEL
  1935   Gustaaf Deloor        BEL

=cut

=pod

=back

This module is part of the set of C<< Acme::MetaSyntactic >> themes
found in the C<< Acme::MetaSyntactic::Themes::Abigail >> package.

=head1 NOTES

=over 1

=item *

The C<< cyclists/tour >> theme is identical to the C<< tour_de_france >>
theme from the C<< Acme::MetaSyntactic::Themes >> package.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=head1 AUTHOR

Abigail, L<< mailto:cpan@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2013 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


=cut

__PACKAGE__ -> init ($data);

1;
