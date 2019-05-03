#!/usr/bin/perl -w

use Test::More tests => 5;
use t::app::Main;
use t::lib::Utils;
use Try::Tiny;
use Data::Dumper;
#use DBIx::Class::Core;
#DBIx::Class::Core->load_components(qw/Result::Validation/);
#my $obj = DBIx::Class::Core->new();
#ok $obj->validate, "validate return 1 when _validate is not redefined";
#ok !defined $obj->result_errors, "result_errors is null when _validate is not redefined";


my $schema = t::app::Main->connect('dbi:SQLite:t/example.db');
$schema->deploy({ add_drop_table => 1 });
populate_database($schema);

subtest "Enum Validation" => sub {
    my $obj1;
    $obj1 = $schema->resultset('Object')->create({name => "good", my_enum => "val1", my_enum_def => "val1", attribute => "attr1", ref_id => 1});
    ok($obj1->id, "create Object with name 'good' is Ok");

    my $obj2;
    my $error;
    try {
        $obj2 = $schema->resultset('Object')->create({name => "goodx", my_enum=>"valx", my_enum_def => "val1", attribute => "attr1", ref_id => 1});
    }
    catch {
        $error = $_;
    };
    ok(!defined $obj2, "can not object with a non valid my_enum");
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined$error->object->result_errors->{my_enum}, "error exists on my_enum");


    my $obj3;
    $error="";
    try {
        $obj3 = $schema->resultset('Object')->create({name => "goodx", my_enum_def => "val2", attribute => "attr1", ref_id => 1});
    }
    catch {
        $error = $_;
    };
    ok($obj3->id, "create Object with name 'goodx' is Ok, default value works on my_enum");


    my $obj4;
    $error="";
    try {
        $obj4 = $schema->resultset('Object')->create({name => "goodxy", my_enum_def => "val666",attribute => "attr1", ref_id => 1});
    }
    catch {
        $error = $_;
    };
    ok(!defined $obj4, "can not object with a non valid my_enum_def");
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{my_enum_def}, "error exists on my_enum_def");
    is $error->object->result_errors->{my_enum_def}->[0], "my_enum_def must be set with one of the following value: val1, val2, val3", "correct error message is set on my_enum_def";
    
    
    my $obj5;
    $error="";
    try {
        $obj5 = $schema->resultset('Object')->create({name => "goodxy"});
    }
    catch {
        $error = $_;
    };
    ok(!defined $obj5, "can not object with a non valid my_enum_def");
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{my_enum_def}, "error exists on my_enum_def : must be defined");
};

subtest "Unvalid param Validation" => sub {
    my $obj_ko;
    $error="";
    try{
        $obj_ko = $schema->resultset('ObjectKo')->create({label => "good", my_enum => "val1"});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    is $error->message, "Validation : fake is not valid", "the correct error is returned when a validation param that does exist is used";
};


subtest "Defined / Empty Validation" => sub {
    my $obj_ok;
    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "", my_enum => "val1", my_enum_def => "val1", attribute => "xxx", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{name}, "name can not be empty");
    is $error->object->result_errors->{name}->[0], "can not be empty", "correct message is set";


    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "hé", my_enum => "val1", my_enum_def => "val1", attribute => "xxx", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{name}, "only ascii characters are authorized");
    is $error->object->result_errors->{name}->[0], "only ascii characters are authorized", "correct message is set";

    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({ my_enum => "val1", my_enum_def => "val1", attribute => "xxx", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{name}, "name must be set");
    is $error->object->result_errors->{name}->[0], "must be set", "correct message is set";


    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "my object", my_enum => "val1", my_enum_def => "val1", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{attribute}, "name must be set");
    is $error->object->result_errors->{attribute}->[0], "must be set", "correct message is set";


    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "my object", my_enum => "val1", my_enum_def => "val1", attribute => "", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    is $error, "", "No error set because attribute can be set to empty";
};

subtest "Not null or not zero Validation" => sub {
    my $obj_ok;
    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "yop", my_enum => "val1", my_enum_def => "val1", attribute => "attr1"});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{ref_id}, "ref_id can not be null");
    is $error->object->result_errors->{ref_id}->[0], "can not be null or equal to 0", "correct message is set";


    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "yop", my_enum => "val1", my_enum_def => "val1", attribute => "attr1", ref_id => 0});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{ref_id}, "ref_id can not be equal to 0");
    is $error->object->result_errors->{ref_id}->[0], "can not be null or equal to 0", "correct message is set";
};

subtest "prohibit field update" => sub {
    my $obj_ok;
    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->create({name => "prohib", my_enum => "val1", my_enum_def => "val1", attribute => "attr1", ref_id => 1});
    }
    catch{
        $error = $_;
    };
    is $error, "", "No error set at Object creation";


    $error="";
    try{
        $obj_ok = $schema->resultset('Object')->find($obj_ok->id)->update({name => "prohib1", my_enum => "val1", my_enum_def => "val1", attribute => "attr1", ref_id => 2});
    }
    catch{
        $error = $_;
    };
    isa_ok( $error, "DBIx::Class::Result::Validation::VException", "error returned is a DBIx::Class::Result::Validation::VException");
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{ref_id}, "ref_id can not be updated from 1 to 2");


    try{
        $obj_ok = $schema->resultset('Object')->find($obj_ok->id)->update({name => "prohib1", my_enum => "val1", my_enum_def => "val1", attribute => "attr1", info => "new info"});
    }
    catch{
        $error = $_;
    };
    ok( $error->object->result_errors, "error returned object with result_error");
    ok (defined $error->object->result_errors->{info}, "info can not be updated from undef to new info, even if info was undef");
};

