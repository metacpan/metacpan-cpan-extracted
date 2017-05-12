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

my $id = $couch->post( { tags => ['cat'], name => 'animal' });
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
    { key => "cat", value => 1 },
];

my $itr = $couch->view("tags/name");
isa_ok $itr => "DBIx::CouchLike::Iterator";
my $r = $itr->next;
is_deeply $r => { key => "cat", value => 1 };
$r = $itr->next;
is $r => undef;

ok $couch->delete($id);
@res = $couch->view("tags/name");
is_deeply \@res => [];

$itr = $couch->view("tags/name");
$r = $itr->next;
is $r => undef;


ok $couch->put("_design/tags" => {
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
        }
    }
});
@res = $couch->view("tags/name");
is_deeply \@res => [];

$itr = $couch->view("tags/name");
$r = $itr->next;
is $r => undef;

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
