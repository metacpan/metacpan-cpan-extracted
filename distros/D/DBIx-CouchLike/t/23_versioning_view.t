# -*- mode:perl -*-
use strict;
use Test::More;

use Test::Requires qw/ DBD::SQLite /;
BEGIN { use_ok 'DBIx::CouchLike' }

my $dbh = require 't/connect.pl';
ok $dbh;

my $couch = DBIx::CouchLike->new({
    dbh => $dbh, table => "view", versioning => 1,
});
isa_ok $couch => "DBIx::CouchLike";
is $couch->dbh => $dbh;
ok $couch->dbh->ping;
ok $couch->create_table;

my $a_id = $couch->post( 1 => { tags => ['dog', 'cat'], name => 'animal' });
my $u_id = $couch->post( 2 => { tags => ['cat', 'more', 'less'], name => 'unix command' });
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
my @all = $couch->all();
my @v = ( _version => 0 );
is_deeply \@all => [
    { id => 1, value => { tags => ['dog', 'cat'], name => 'animal', @v } },
    { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command', @v } },
    { id => "_design/tags", value => {
        language => 'perl',
        views => {
            name => { map => $func, }
        },
        @v,
    }},
];

@all = $couch->all({ exclude_designs => 1 });
is_deeply \@all => [
    { id => 1, value => { tags => ['dog', 'cat'], name => 'animal', @v } },
    { id => 2, value => { tags => ['cat', 'more', 'less'], name => 'unix command', @v } },
];

@all = $couch->all_designs();
is_deeply \@all => [
    { id => "_design/tags", value => {
        language => 'perl',
        views => {
            name => { map => $func, }
        },
        @v
    }},
];


my @res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "dog",  value => "animal",       id => $a_id },
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key => "cat" });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key_like => "c%" });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key_like => "d%" });
is_deeply \@res => [
    { key => "dog",  value => "animal",       id => $a_id },
];


@res = $couch->view("tags/name", { key_start_with => "c" });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key_start_with => "d" });
is_deeply \@res => [
    { key => "dog",  value => "animal",       id => $a_id },
];

@res = $couch->view("tags/name", { key => {"<>" => "dog"} });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key => {">" => "dog"} });
is_deeply \@res => [
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key => ["dog", "cat"] });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "dog",  value => "animal",       id => $a_id },
];

@res = $couch->view("tags/name", { key => \"> 'less'" });
is_deeply \@res => [
    { key => "more", value => "unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key => "cat", limit => 1 });
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
];

# replace design
ok $couch->put("_design/tags" => {
    language => 'perl',
    views => {
        name => {
            map => q|
sub {
    my ($obj, $emit) = @_;
    for my $tag ( @{ $obj->{tags} } ) {
        $emit->( $tag, "name is " . $obj->{name} );
    }
}
            |,
        }
    }
});
@res = $couch->view("tags/name");
is_deeply \@res => [
    { key => "cat",  value => "name is animal",       id => $a_id },
    { key => "cat",  value => "name is unix command", id => $u_id },
    { key => "dog",  value => "name is animal",       id => $a_id },
    { key => "less", value => "name is unix command", id => $u_id },
    { key => "more", value => "name is unix command", id => $u_id },
];

@res = $couch->view("tags/name", { key => "dog", include_docs => 1 });
is_deeply \@res => [
    {
        id       => $a_id,
        key      => "dog",
        value    => "name is animal",
        document => { tags => ['dog', 'cat'], name => 'animal', _id => 1, @v },
    }
];

ok $couch->delete("_design/tags");
ok !$couch->get("_design/tags");
my $res = $couch->view("tags/name");
is_deeply $res => undef;


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;

done_testing;
