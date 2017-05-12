#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use t::app::Main;
use t::lib::Utils;
use Try::Tiny;

plan tests => 2;

my @objects2;
my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({ add_drop_table => 1 });
populate_database($schema);


subtest "Insert Validation" => sub {
    my $obj1;
    my $error;
    $obj1 = $schema->resultset('Object')->create({name => "good", my_enum=>"val1", my_enum_def =>"val1", attribute => "", ref_id => 1});
    ok($obj1->id, "create Object with name 'good' is Ok");
    my @objects1 = $schema->resultset('Object')->search({name => "good"});
    is( scalar(@objects1),1,"validation is ok, object was create");

    my $obj2;
    try {
        $obj2 = $schema->resultset('Object')->create({name => "good", my_enum=>"val1", my_enum_def =>"val1", attribute => "", ref_id => 1});
    }
    catch {
        $error = $_;
    };
    ok(!defined $obj2, "can not create 2 objects with the same name");

    @objects2 = $schema->resultset('Object')->search({name => "good"});
    is( scalar(@objects2),1,"can not create 2 objects with the same name");
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    isa_ok( $error->object, "t::app::Main::Result::Object", "error returned object t::app::Main::Result::Object");
    ok( $error->object->result_errors, "error returned object with result_error");
    like( $error->message, qr/Validation failed\./, "error returned message Validation Failed");
    like( "$error", qr/Validation failed\./, "error object should stringify correctly");
    like( "$error", qr/name must be unique/, "... and we should get actual errors listed");
};

subtest "Update Validation" => sub {
    my $object3 = $objects2[0];
    $object3->name('error');
    my $result3;
    my $error3;
    try {
        $result3 = $object3->update();
    }
    catch
    {
        $error3 = $_;
    };
    isa_ok( $error3, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    isa_ok( $error3->object, "t::app::Main::Result::Object", "error returned object t::app::Main::Result::Object");
    ok( $error3->object->result_errors, "error returned object with result_error");
    like( $error3->message, qr/Validation failed\./, "error returned message Validation Failed");
    ok( $object3->result_errors, "can not update object with an error");
    my @objects3 = $schema->resultset('Object')->search({name => "error"});
    is( scalar(@objects3),0,"can not update object with the name 'error'");

    my @objects4 = $schema->resultset('Object')->search({name => "good"});
    is( scalar(@objects4),1,"can not update object with the name 'error'");
};
