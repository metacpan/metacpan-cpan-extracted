use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 4;

use lib 't/lib';

use_ok('SweetTest');

use Data::Dumper;

{
  my @cds = SweetTest::CD->search({'tags.tag' => {-and => [qw/ Blue Cheesy /]} });
  is scalar @cds, 2, "Correct number of CD returned";
}

{
  my @cds = SweetTest::CD->search({'tags.tag' => {-and => [qw/ Blue Cheesy Shiny /]} });
  is scalar @cds, 1, "Correct number of CD returned";
  is $cds[0]->id, 2, "Correct CD returned";
}

