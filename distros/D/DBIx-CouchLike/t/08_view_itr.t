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
        $emit->( $tag, $obj->{name} );
    }
}
            |,
        }
    }
});

my $itr = $couch->view("tags/name");
isa_ok $itr => "DBIx::CouchLike::Iterator";
my @res;
push @res, $_ while $_ = $itr->next;
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
    { key => "dog",  value => "animal",       id => $a_id },
    { key => "less", value => "unix command", id => $u_id },
    { key => "more", value => "unix command", id => $u_id },
];
undef @res;


$itr = $couch->view("tags/name", { key => "cat" });
push @res, $_ while $_ = $itr->next;
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
    { key => "cat",  value => "unix command", id => $u_id },
];
undef @res;


$itr = $couch->view("tags/name", { key => "cat", limit => 1 });
push @res, $_ while $_ = $itr->next;
is_deeply \@res => [
    { key => "cat",  value => "animal",       id => $a_id },
];
undef @res;

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
$itr = $couch->view("tags/name");
push @res, $_ while $_ = $itr->next;
is_deeply \@res => [
    { key => "cat",  value => "name is animal",       id => $a_id },
    { key => "cat",  value => "name is unix command", id => $u_id },
    { key => "dog",  value => "name is animal",       id => $a_id },
    { key => "less", value => "name is unix command", id => $u_id },
    { key => "more", value => "name is unix command", id => $u_id },
];
undef @res;


$itr = $couch->view("tags/name", { key => "dog", include_docs => 1 });
push @res, $_ while $_ = $itr->next;
is_deeply \@res => [
    {
        id       => $a_id,
        key      => "dog",
        value    => "name is animal",
        document => { tags => ['dog', 'cat'], name => 'animal', _id => 1 },
    }
];

ok $couch->delete("_design/tags");
ok !$couch->get("_design/tags");
my $res = $couch->view("tags/name");
is_deeply $res => undef;


$dbh->commit unless $ENV{DSN};
$dbh->disconnect;

