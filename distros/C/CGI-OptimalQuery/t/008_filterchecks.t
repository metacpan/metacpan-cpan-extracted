use strict;
no warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
require "$Bin/testutil.pl";

use Test::More tests => 1;

{ my $errs = "";
  OQ::foreachdb(sub {
    my $oq = OQ::schema(
      'select' => {
        'U_ID' => ['movie','movie.movie_id','Movie ID'],
        'NAME' => ['movie', 'movie.name', 'Name']
      },
      filter => '[NAME] CONTAINS "Mark\\\\"',
      'module' => 'CSV',
      'joins' => {
        'movie' => [undef, "oqtest_movie movie"]
      }
    );
    $oq->output();
    $errs .= "$OQ::DBTYPE should not match anything; " if $OQ::BUF =~ /Hamill/s;
  });
  is($errs, '', "filterchecks");
}
