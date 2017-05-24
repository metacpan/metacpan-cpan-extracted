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

subtest 'insert objects' => sub {
    my $list = [map {testlib::Object::Element->new({text=>$_})} qw(Tick Trick Track)];

    my $row = $schema->resultset('Test')->create({array=>$list});
    $id = $row->id;

    my ($via_dbi) = $dbh->selectrow_array("select array from test where id = ?",undef, $id);
    is($via_dbi,'[{"text":"Tick"},{"text":"Trick"},{"text":"Track"}]','raw string in db');
};

subtest 'fetch JSON as object' => sub {
    my $row = $schema->resultset('Test')->find($id);
    my $obj = $row->array;
    is(ref($obj),'ARRAY','array');
    is($obj->[0]{text},'Tick','text 0');
    is($obj->[2]{text},'Track','text 2');
};

subtest 'fetch and update' => sub {
    my $row = $schema->resultset('Test')->find($id);

    my $obj = $row->array;

    my $new = testlib::Object::Element->new({text=>'Donald'});
    push(@$obj,$new);
    $row->update({array=>$obj});

    my $fresh = $schema->resultset('Test')->find($id);
    is($fresh->array->[1]->{text},'Trick','text 1');
    is($fresh->array->[3]->{text},'Donald','text 3');

    my $raw = $fresh->get_column('array');
    is($raw,'[{"text":"Tick"},{"text":"Trick"},{"text":"Track"},{"text":"Donald"}]','raw');
};

subtest 'insert raw json' => sub {

    my $raw_json = '[{"text":"176-167"},{"text":"176-176"}]';

    my $row = $schema->resultset('Test')->create({array=>$raw_json});
    $row->discard_changes;
    is($row->array->[0]->text,'176-167','text 0');
    is($row->array->[1]->text,'176-176','text 1');
};

done_testing();
