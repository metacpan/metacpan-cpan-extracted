# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "view" });
isa_ok $couch => "DBIx::CouchLike";
is $couch->dbh => $dbh;
ok $couch->dbh->ping;
ok $couch->create_table;

$couch->post( 1 => { tags => ['dog', 'cat'], name => 'animal' });
$couch->post( 2 => { tags => ['cat', 'more', 'less'], name => 'unix command' });
$couch->post( 3 => { tags => ['cat', 'cut'], name => 'start with c' });

my $itr = $couch->all;
isa_ok $itr => "DBIx::CouchLike::Iterator";

{
    my @res;
    push @res, $_ while $_ = $itr->next;
    is_deeply \@res => [
        { id => 1, value => { tags => ['dog', 'cat'], name => 'animal' } },
        { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command' } },
        { id => 3, value => { tags => ['cat', 'cut'], name => 'start with c' } },
    ];
}

{
    my @res = $couch->all({ offset => 1, limit => 2 });
    is_deeply \@res => [
        { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command' }},
        { id => 3, value => { tags => ['cat', 'cut'], name => 'start with c' } },
    ];
}

{
    my @res = $couch->all({ limit => 1 });
    is_deeply \@res => [
        { id => 1, value => { tags => ['dog', 'cat'], name => 'animal' } },
    ];
}

{
    my @res = $couch->all({ offset => 1, limit => 1 });
    is_deeply \@res => [
        { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command' } },
    ];
}

# reverse
{
    my @res = $couch->all({ reverse => 1 });
    is_deeply \@res => [
        { id => 3, value => { tags => ['cat', 'cut'], name => 'start with c' } },
        { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command' } },
        { id => 1, value => { tags => ['dog', 'cat'], name => 'animal' } },
    ];
}

{
    my @res = $couch->all({ offset => 1, limit => 2, reverse => 1, });
    is_deeply \@res => [
        { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command' }},
        { id => 1, value => { tags => ['dog', 'cat'], name => 'animal' } },
    ];
}

{
    my @res = $couch->all({ limit => 1, reverse => 1, });
    is_deeply \@res => [
        { id => 3, value => { tags => ['cat', 'cut'], name => 'start with c' } },
    ];
}

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;

