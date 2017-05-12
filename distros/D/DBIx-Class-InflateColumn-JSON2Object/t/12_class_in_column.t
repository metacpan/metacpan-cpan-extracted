#!/usr/bin/perl
use Test::More;
use lib 't';
use utf8;
use Encode;
binmode( STDERR, ":utf8" );
binmode( STDOUT, ":utf8" );
use testlib::TestDB qw($dbh $schema);

my $id;
use JSON::MaybeXS;
use testlib::Object::Various::Food;
use testlib::Object::Various::Drink;

subtest 'insert object' => sub {
    my $obj = testlib::Object::Various::Food->new({
        name=>'Falafel',
        vegetarian=>1
    });

    my $row = $schema->resultset('Test')->create({data=>$obj});
    $id = $row->id;

    my ($via_dbi,$type) = $dbh->selectrow_array("select data,type from test where id = ?",undef, $id);
    is($type, 'food','set correct type from object');
    like($via_dbi,qr/"name":"Falafel"/,'string');
    like($via_dbi,qr/"vegetarian":true/,'bool');
};

subtest 'fetch JSON as object' => sub {
    my $row = $schema->resultset('Test')->find($id);
    my $obj = $row->data;
    is(ref($obj),'testlib::Object::Various::Food','class');
    is($obj->name,'Falafel','name');
    is($obj->vegetarian,1,'vegetarian');
};

subtest 'replace with other object' => sub {
    my $row = $schema->resultset('Test')->find($id);

    my $obj = testlib::Object::Various::Drink->new({
        name=>'Mango Lassi',
        alcoholic=>0
    });

    $row->update({data=>$obj});

    my $fresh = $schema->resultset('Test')->find($id);
    my $obj = $fresh->data;
    is(ref($obj),'testlib::Object::Various::Drink','class');
    is($obj->name,'Mango Lassi','name');
    is($obj->alcoholic,0,'not alcoholic');
};

subtest 'update object from raw json' => sub {
    my $raw_json = '{"name":"Frozen Mango Daiquiri","alcoholic":true}';
    my $data = decode_json($raw_json);

    my $row = $schema->resultset('Test')->find($id);
    $row->update({data=>$data});
    $row->discard_changes;
    my $obj = $row->data;
    is(ref($obj),'testlib::Object::Various::Drink','class');
    is($obj->name,'Frozen Mango Daiquiri','name');
    is($obj->alcoholic,1,'alcoholic');
};

subtest 'update object from raw json with type change' => sub {
    my $raw_json = '{"name":"Kebab","vegetarian":false}';
    my $data = decode_json($raw_json);

    my $row = $schema->resultset('Test')->find($id);

    # DANGER: type has to be changed before data can be changed!
    $row->update({ type=>'food'});
    $row->update({data=>$data});
    $row->discard_changes;

    my $obj = $row->data;
    is(ref($obj),'testlib::Object::Various::Food','class');
    is($obj->name,'Kebab','name');
    is($obj->vegetarian,0,'with meat');
};

done_testing();
