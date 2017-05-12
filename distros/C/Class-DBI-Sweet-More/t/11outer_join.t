use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 8;

use lib 't/lib';

use_ok('SweetTest');

{
  my @artists = SweetTest::Artist->search({ 'twokeys' => undef });
  is scalar @artists, 0, "Correct number of Artists returned by INNER JOIN";
}
{
  my @artists = SweetTest::Artist->search({ 'twokeys_outer' => undef });
  is scalar @artists, 1, "Correct number of Artists returned by OUTER JOIN";
  my $artist = shift @artists;
  is $artist->id, 3, "Correct Artist returned by OUTER JOIN";
}

{
  my ($cd) = SweetTest::CD->search({cdid => 3}, {prefetch => [qw/liner_notes/]});
  ok +(not defined $cd), "INNER JOIN prefetch";
  my @cds = SweetTest::CD->search( { 'liner_notes.notes' => undef } );
  is scalar @cds, 0, "Correct number of CD returned by INNER JOIN";
}
{
  my ($cd) = SweetTest::CD->search({cdid => 3}, {prefetch => [qw/linernotes_outer/]});
  is $cd->id, 3, "OUTER JOIN prefetch";
  my @cds = SweetTest::CD->search( { 'linernotes_outer.notes' => undef } );
  is scalar @cds, 2, "Correct number of CD returned by OUTER JOIN";
}

