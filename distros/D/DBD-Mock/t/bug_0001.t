# This is RT #15602
# The bug that was reported did not appear, but it did expose
# another bug with consecutive executes()

use strict;

use Test::More tests => 4;

use_ok('DBI');

my $dbh = DBI->connect( 'dbi:Mock:', '', '', { PrintError => 0 } );
isa_ok($dbh, 'DBI::db');

my $SQL = "select foo from bar where a = ? and b = ?";

my $s = DBD::Mock::Session->new("bugdemo",
    {
      statement=> $SQL,
      bound_params=>[1,2],
      results=>[['foo'],[1]]
    },
    {
      statement=> $SQL,
      bound_params=>[3,4],
      results=>[['foo'],[1]],
    },
);

$dbh->{mock_session} = $s;

my $sth=$dbh->prepare($SQL);
eval {
    ok( !$sth->execute(3,4), "Bind failed" );
    ok( $sth->execute(1,2), "Bind passed" );
};

# Shuts up warning when object is destroyed
undef $dbh->{mock_session};
