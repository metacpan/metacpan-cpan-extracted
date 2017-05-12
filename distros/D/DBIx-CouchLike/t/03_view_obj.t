# -*- mode:perl -*-
use strict;
use Test::More qw/ no_plan /;

use Test::Requires qw/ DBD::SQLite /;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({ dbh => $dbh, table => "view2" });
isa_ok $couch => "DBIx::CouchLike";
is $couch->dbh => $dbh;
ok $couch->dbh->ping;
ok $couch->create_table;

my $a_id = $couch->post( 1 => { tags => ['dog', 'cat'], name => 'animal' });
my $u_id = $couch->post( 2 => { tags => ['cat', 'more', 'less'], name => 'unix command' });
ok $couch->post("_design/tags" => {
    language => 'perl',
    views => {
        name => {
            map => q|
sub {
    my ($obj, $emit) = @_;
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag, +{ name => $obj->{name} } );
    }
}
            |,
        }
    }
});

my @res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => { name => "animal" },       id => $a_id },
    { key => "cat",  value => { name => "unix command" }, id => $u_id },
    { key => "dog",  value => { name => "animal" },       id => $a_id },
    { key => "less", value => { name => "unix command" }, id => $u_id },
    { key => "more", value => { name => "unix command" }, id => $u_id },
];

@res = $couch->view("tags/name", { key => "cat" });
is_deeply \@res => [
    { key => "cat",  value => { name => "animal" },       id => $a_id },
    { key => "cat",  value => { name => "unix command" }, id => $u_id },
];

@res = $couch->view("tags/name", { key => "cat", limit => 1 });
is_deeply \@res => [
    { key => "cat",  value => { name => "animal" },       id => $a_id },
];

@res = $couch->view("tags/name", { key => "cat", limit => 1, offset => 1, });
is_deeply \@res => [
    { key => "cat",  value => { name => "unix command" }, id => $u_id },
];

# replace view
ok $couch->put("_design/tags" => {
    language => 'perl',
    views => {
        name => {
            map => q|
sub {
    my ($obj, $emit) = @_;
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag, [ $obj->{name} ] );
    }
}
            |,
        }
    }
});
@res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => [ "animal" ],       id => $a_id },
    { key => "cat",  value => [ "unix command" ], id => $u_id },
    { key => "dog",  value => [ "animal" ],       id => $a_id },
    { key => "less", value => [ "unix command" ], id => $u_id },
    { key => "more", value => [ "unix command" ], id => $u_id },
];


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
