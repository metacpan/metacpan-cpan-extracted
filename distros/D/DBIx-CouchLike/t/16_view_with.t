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

my $func = q|
sub {
    my ($obj, $emit) = @_;
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag, $obj->{name} );
    }
}
|;
ok $couch->post("_design/tags" => {
    language => 'perl',
    views => {
        name => { map => $func, }
    }
});

$func = q|
sub {
    my ($obj, $emit) = @_;
    $emit->( $obj->{_id} => 1 );
}
|;
ok $couch->post("_design/id" => {
    language => 'perl',
    views => {
        all => { map => $func, }
    }
});

my $a_id = $couch->post_with_views("tags")
    ->( { _id => 1, tags => ['dog', 'cat'], name => 'animal' } );

my $u_id = $couch->post_with_views("tags")
    ->( { _id => 2, tags => ['cat', 'more', 'less'], name => 'unix command' } );

my @res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "dog",  value => "animal",       id => $a_id },
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("tags/id");
is_deeply \@res => [];
$a_id = $couch->put_with_views("tags","id")
    ->( { _id => 1, tags => ['dog', 'cat'], name => 'animal' },
        { _id => 2, tags => ['cat', 'more', 'less'], name => 'unix command' }
    );

@res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "dog",  value => "animal",       id => $a_id },
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("id/all");
is_deeply \@res => [
    { key => 1, value => 1, id => 1 },
    { key => 2, value => 1, id => 2 },
];

$dbh->commit unless $ENV{DSN};
$dbh->disconnect;
