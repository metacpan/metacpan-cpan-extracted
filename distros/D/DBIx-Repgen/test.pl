
# This is _very_ small test set, but it checks building and executing
# of a simple report with groups.

use Test;
BEGIN { plan tests => 1 };
use DBIx::Repgen;
use DBI;

my $dbh = DBI->connect("dbi:Sponge:", "", "", {RaiseError => 1});
my $sth = $dbh->prepare
  ("dummy",
   {NAME => [qw/COUNTRY CITY POPULATION/],
    rows => [
	     [qw/Australia Kanberra 900000/],
	     [qw/Australia Sidney   6400000/],
	     [qw/Russia Moscow 9500000/],
	     [qw/Russia Rostov-on-Don 1200000/],
	     [qw/Russia St.Petersberg 4500000/],
	     [qw/Russia Taganrog 250000/],
	     ['USA', 'Los Angeles', 4000000],
	     ['USA', 'New York', 12000000],
	     ['USA', 'Washington', 2000000],

	    ],
   });

my $r = DBIx::Repgen->new
  (
   sth => $sth,
   group => [qw/COUNTRY/],
   total => [qw/POPULATION/],

   header => [\&makeheader,
              '=', "Countries, cities and thier population"],
   footer => ["Total %d countries, %d cities, %d people\n",
              qw/num_COUNTRY num_report total_POPULATION/],

   header_COUNTRY => sub {
     my (undef, $d) = @_;
     return makeheader(undef, undef, '-', $d->{COUNTRY});
   },
   footer_COUNTRY => ["%d cities, %d people in %s\n\n",
          qw/num_item total_COUNTRY_POPULATION prev_COUNTRY/],

   item => ["\t\t%-20s %10d\n", qw/CITY POPULATION/],
  );

my $out = $r->run();

ok($out, <<EOM);
======================================
Countries, cities and thier population
======================================
---------
Australia
---------
		Kanberra                 900000
		Sidney                  6400000
2 cities, 7300000 people in Australia

------
Russia
------
		Moscow                  9500000
		Rostov-on-Don           1200000
		St.Petersberg           4500000
		Taganrog                 250000
4 cities, 15450000 people in Russia

---
USA
---
		Los Angeles             4000000
		New York               12000000
		Washington              2000000
3 cities, 18000000 people in USA

Total 3 countries, 9 cities, 40750000 people
EOM

sub makeheader {
  my (undef, undef, $c, $s) = @_;
  return sprintf("%s\n%s\n%s\n", $c x length($s), $s, $c x length($s));
}


$dbh->disconnect;
