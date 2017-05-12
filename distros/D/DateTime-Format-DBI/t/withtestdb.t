# $Id$
#
use strict;
use warnings;

use Test::More;
use DateTime::Format::DBI;

eval "use Test::Database;";
plan skip_all => "Test::Database required for real database test" if $@;

my @dbkeys = sort keys %DateTime::Format::DBI::db_to_parser;
my @handles = Test::Database->handles;

plan tests => $#dbkeys + 1;

my(@done,@skip);

foreach my $dbkey ( @dbkeys )
{
  my($handle,) = grep { lc($_->dbd) eq $dbkey  } @handles;

  subtest "with $dbkey" => sub {
    if($handle) {
      push @done, $dbkey;
      plan tests => 3;
    } else {
      push @skip, $dbkey;
      plan skip_all => "Test::Database not configured for $dbkey";
    }

    my $dbd = $handle->dbd;

    my $parser = eval { DateTime::Format::DBI->new($handle->dbh); };
    ok(defined $parser, "generate parser for DBD::$dbd");

    isa_ok($parser, $DateTime::Format::DBI::db_to_parser{lc $dbd}, 
      "correct parser class for DBD::$dbd");

    isnt($parser->format_datetime(DateTime->now), '',
      "working parser for DBD::$dbd");
  }
}

my @mess;
push @mess, "tested: @done" if @done;
push @mess, "skipped: @skip" if @skip;

diag join ", ", @mess;
