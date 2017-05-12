use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', undef, undef);


my $sth = $dbh->prepare('SELECT * FROM my_table WHERE id = ?');
subtest 'before execute' => sub {
    is $sth->FETCH('FetchHashKeyName'), 'NAME';
    is $sth->FETCH('NUM_OF_FIELDS'), -1;
};

$sth->execute(1);
subtest 'after execute' => sub {
    is $sth->FETCH('FetchHashKeyName'), 'NAME';
    is $sth->FETCH('NUM_OF_FIELDS'), 1;
    is $sth->FETCH('NUM_OF_PARAMS'), 0;
    is_deeply $sth->FETCH('NAME'), [qw/dummy/];
    is_deeply $sth->FETCH('NAME_lc'), [qw/dummy/];
    is_deeply $sth->FETCH('NAME_uc'), [qw/DUMMY/];
    is_deeply $sth->FETCH('NAME_hash'), { dummy => 0 };
    is_deeply $sth->FETCH('NAME_lc_hash'), { dummy => 0 };
    is_deeply $sth->FETCH('NAME_uc_hash'), { DUMMY => 0 };
};

done_testing;

