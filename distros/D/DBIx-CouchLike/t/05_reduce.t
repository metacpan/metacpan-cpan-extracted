# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
use Data::Dumper;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "view" });
isa_ok $couch => "DBIx::CouchLike";
is $couch->dbh => $dbh;
ok $couch->dbh->ping;
ok $couch->create_table;

ok $couch->post( { tags => ['dog', 'cat'], name => 'animal' });
ok $couch->post( { tags => ['cat', 'less', 'more'], name => 'unix command' });
ok $couch->post( { tags => ['cat', 'medaka'], name => 'fish' });

ok $couch->post("_design/tags" => {
    language => 'perl',
    views => {
        name => {
            map => q|
sub {
    my ($obj, $emit) = @_;
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag, $obj->{name} );
    }
}
            |,
            reduce => q|
sub {
    my ($keys, $values) = @_;
    return scalar @$values;
}
            |,
        }
    }
});

my @res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",    value => 3 },
    { key => "dog",    value => 1 },
    { key => "less",   value => 1 },
    { key => "medaka", value => 1 },
    { key => "more",   value => 1 },
];

my $itr = $couch->view("tags/name");
isa_ok $itr => "DBIx::CouchLike::Iterator";
my $r = $itr->next;
is_deeply $r => { key => "cat",    value => 3 };
$r = $itr->next;
is_deeply $r => { key => "dog",    value => 1 };
$r = $itr->next;
is_deeply $r => { key => "less",   value => 1 };
$r = $itr->next;
is_deeply $r => { key => "medaka", value => 1 };
$r = $itr->next;
is_deeply $r => { key => "more",   value => 1 };
$r = $itr->next;
is $r => undef;

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
