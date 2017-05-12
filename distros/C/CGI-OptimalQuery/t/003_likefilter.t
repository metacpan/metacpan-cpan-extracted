use strict;
use FindBin qw($Bin);
require "$Bin/testutil.pl";

use Test::More tests => 1;

my $errs = "";
OQ::foreachdb(sub {
  my $oq = OQ::schema(
    'select' => {
      'U_ID' => ['movie','movie.movie_id','Movie ID'],
      'NAME' => ['movie', 'movie.name', 'Name']
    },
    filter => "[NAME] like 'Return of the Jedi'",
    'module' => 'CSV',
    'joins' => {
      'movie' => [undef, "oqtest_movie movie"]
    }
  );
  $oq->output();
  $errs .= "$OQ::DBTYPE missing return of the jedi" unless $OQ::BUF =~ /Return\ of\ the\ Jedi/s;
  $errs .= "$OQ::DBTYPE should not have Empire listed" if $OQ::BUF =~ /Empire/s;
});

is($errs, '', 'like test');
