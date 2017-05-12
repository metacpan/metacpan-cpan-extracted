use strict;

use Test::More tests => 22;

BEGIN {
    use_ok('DBD::Mock');
}

# just test the iterator plain
{
    my $i = DBD::Mock::StatementTrack::Iterator->new([ 1 .. 5 ]);
    isa_ok($i, 'DBD::Mock::StatementTrack::Iterator');
    
    is($i->next(), 1, '... got 1');
    is($i->next(), 2, '... got 2');
    is($i->next(), 3, '... got 3');
    is($i->next(), 4, '... got 4');
    is($i->next(), 5, '... got 5');
    ok(!defined($i->next()), '... got undef');
    
    $i->reset();
        
    is($i->next(), 1, '... got 1');
    is($i->next(), 2, '... got 2');
    is($i->next(), 3, '... got 3');
    is($i->next(), 4, '... got 4');
    is($i->next(), 5, '... got 5');
    ok(!defined($i->next()), '... got undef');    
}

# and now test it within context

my $dbh = DBI->connect('DBI:Mock:', '', '');
isa_ok($dbh, 'DBI::db'); 

my $i = $dbh->{mock_all_history_iterator};
isa_ok($i, 'DBD::Mock::StatementTrack::Iterator');

ok(!defined($i->next()), '... nothing in the iterator');

$dbh->prepare("INSERT INTO nothing (nothing) VALUES('nada')");

ok(defined($i->next()), '... now something in the iterator (which is what we want)');

$dbh->prepare("INSERT INTO nothing (nothing) VALUES('nada')");

my $next = $i->next();
ok(defined($next), '... something in the iterator');
isa_ok($next, 'DBD::Mock::StatementTrack');
is($next->statement, "INSERT INTO nothing (nothing) VALUES('nada')", '... its our old insert statement too');

ok(!defined($i->next()), '... now nothing in the iterator');
