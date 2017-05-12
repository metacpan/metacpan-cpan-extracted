use strict;
no warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
require "$Bin/testutil.pl";

use Test::More tests => 2;

my $errs = "";
OQ::foreachdb(sub {
  my $oq = OQ::schema(
    'select' => {
      'U_ID' => ['movie','movie.movie_id','Movie ID'],
      'NAME' => ['movie', 'movie.name', 'Name'],
      'CAST' => ['moviecastperson', 'moviecastperson.name', 'All Cast (seprated by commas)']
    },
    filter => "[CAST] not contains 'Hamill'",
    'module' => 'CSV',
    'joins' => {
      'movie' => [undef, "oqtest_movie movie"],
      'moviecast' => ['movie', 'JOIN oqtest_moviecast moviecast ON (movie.movie_id = moviecast.movie_id)', undef, { new_cursor => 1 }],
      'moviecastperson' => ['moviecast', 'JOIN oqtest_person moviecastperson ON (moviecast.person_id=moviecastperson.person_id)']
    }
  );
  $oq->output();
  $errs .= "$OQ::DBTYPE has Hamill; " if $OQ::BUF =~ /Hamill/s;
});

is($errs, '', "notcontainsmultival");


{ my $errs = "";
  OQ::foreachdb(sub {
  my $oq = OQ::schema(
    'select' => {
      'U_ID' => ['movie','movie.movie_id','Movie ID'],
      'NAME' => ['movie', 'movie.name', 'Name'],
      'CAST' => ['moviecastperson', 'moviecastperson.name', 'All Cast (seprated by commas)']
    },
    filter => "[CAST] not contains ''",
    'module' => 'CSV',
    'joins' => {
      'movie' => [undef, "oqtest_movie movie"],
      'moviecast' => ['movie', 'JOIN oqtest_moviecast moviecast ON (movie.movie_id = moviecast.movie_id)', undef, { new_cursor => 1 }],
      'moviecastperson' => ['moviecast', 'JOIN oqtest_person moviecastperson ON (moviecast.person_id=moviecastperson.person_id)']
    }
  );
  $oq->output();
  $errs .= "$OQ::DBTYPE does not have Hamill; " unless $OQ::BUF =~ /Hamill/s;
  });

  is($errs, '', "notcontainsmultivalempty");
}
