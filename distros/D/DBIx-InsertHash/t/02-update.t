#!/perl

use strict;
use warnings;

use FindBin;
use Test::More tests => 2;
use Test::Deep;

use DBIx::InsertHash;

use lib $FindBin::Bin;
use DBIx::InsertHash::DBI;


my $dbh = DBIx::InsertHash::DBI->new;


# simple
{
    DBIx::InsertHash->update({a => 1, b => 2}, [3, 4], 'A=B', 'T', $dbh);

    is($dbh->{sql}, 'UPDATE T SET a = ?, b = ? WHERE A=B');
    cmp_bag($dbh->{val}, [1, 2, 3, 4]);
}

###TODO### object defaults

###TODO### quoting

###TODO### warnings/errors
