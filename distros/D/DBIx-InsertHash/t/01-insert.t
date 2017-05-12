#!/perl

use strict;
use warnings;

use FindBin;
use Test::More tests => 10;
use Test::Deep;

use DBIx::InsertHash;

use lib $FindBin::Bin;
use DBIx::InsertHash::DBI;


my $dbh = DBIx::InsertHash::DBI->new;


# single values
{
    my $id = DBIx::InsertHash->insert({abc => 123}, 'TABLE_NAME', $dbh);

    is($id, 999);
    is($dbh->{sql}, 'INSERT INTO TABLE_NAME (abc) VALUES (?)');
    cmp_bag($dbh->{val}, [123]);
}

# multiple values
{
    DBIx::InsertHash->insert({abc => 123, def => 456},
                             'TABLE_NAME', $dbh,
                            );

    is($dbh->{sql}, 'INSERT INTO TABLE_NAME (abc, def) VALUES (?, ?)');
    cmp_bag($dbh->{val}, [123, 456]);
}

# object defaults
{
    my $dbix = DBIx::InsertHash->new(table => 'TABLE_NAME_2',
                                     dbh   => $dbh,
                                    );
    my $id = $dbix->insert({xyz => 'test'});

    is($id, 999);
    is($dbh->{sql}, 'INSERT INTO TABLE_NAME_2 (xyz) VALUES (?)');
    cmp_bag($dbh->{val}, ['test']);
}

# quoting 1
{
    my $dbix = DBIx::InsertHash->new(table => 'T',
                                     dbh   => $dbh,
                                     quote => 1,
                                    );
    $dbix->insert({abc => 1});

    is($dbh->{sql}, 'INSERT INTO T (`abc`) VALUES (?)');
}

# quoting 2
{
    my $dbix = DBIx::InsertHash->new(table => 'T2',
                                     quote_func => sub { $_[0] eq 'abc' },
                                     quote_char => '#',
                                    );
    $dbix->insert({abc => 1, def => 2}, '', $dbh);

    is($dbh->{sql}, 'INSERT INTO T2 (#abc#, def) VALUES (?, ?)');
}

###TODO### warnings/errors
