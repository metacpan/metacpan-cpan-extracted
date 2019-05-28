#!perl

use strict;
use warnings;

use Test::More;
use JSON::PP;

use_ok 'Data::JSONSchema::Ajv';

subtest new => sub {
    my $ajv = eval { Data::JSONSchema::Ajv->new() };
    ok $ajv, 'object successfully created when no parameters passed';
    
    $ajv = eval { Data::JSONSchema::Ajv->new( {}, { draft => '07', beep => 12 } ) };
    ok !$ajv, 'object not created when unknown module parameter passed';
    
    $ajv = eval { Data::JSONSchema::Ajv->new( {}, { draft => 7 } ) };
    ok !$ajv, 'object not created when unknown draft value passed';
    
    for my $draft (qw( 04 06 07 )) {
        $ajv = eval { Data::JSONSchema::Ajv->new( {}, { draft => $draft } ) };
        ok $ajv, "object successfully created for draft $draft";
    }
    
    open my $fh, ">&STDERR";
    close STDERR; # this test produces some garbage to stderr;
    $ajv = eval { Data::JSONSchema::Ajv->new( {}, { ajv_src => 'perl + js = love' } ) };
    open STDERR, ">&" . fileno($fh);
    ok !$ajv, 'object not created when invalid source code of ajv passed';
    
    $ajv = eval { Data::JSONSchema::Ajv->new( {}, { ajv_src => 'function Ajv() {}' } ) };
    ok $ajv, 'object successfully created for valid ajv_src';
};

subtest make_validator => sub {
    my $ajv = Data::JSONSchema::Ajv->new();
    
    open my $fh, ">&STDERR";
    close STDERR; # this test produces some garbage to stderr;
    my $validator = eval { $ajv->make_validator("my first schema") };
    open STDERR, ">&" . fileno($fh);
    ok !$validator, "can't create validator for invalid schema";
    
    $validator = eval { $ajv->make_validator({ type => 'integer', minimum => 1, maximum => 1000 }) };
    ok $validator, 'validator successfully created for valid schema';
    
    $validator = eval { $ajv->make_validator('{ "type": "integer", "minimum": 1, "maximum": 1000 }') };
    ok $validator, 'validator successfully created for valid schema passed as JSON';
    
    isa_ok $validator, 'Data::JSONSchema::Ajv::Validator';
};

subtest validate => sub {
    my $ajv = Data::JSONSchema::Ajv->new();
    my $validator = $ajv->make_validator({ type => 'integer', minimum => 1, maximum => 1000 });
    
    my $errors = $validator->validate("smth");
    ok $errors, "can't validate invalid data";
    
    $errors = $validator->validate(99);
    ok !$errors, 'valid data validated successfully';
    
    $errors = $validator->validate(\99);
    ok !$errors, 'can validate scalars passed by reference';
    
    $ajv = Data::JSONSchema::Ajv->new({ coerceTypes => $JSON::PP::true });
    $validator = $ajv->make_validator({ type => 'object', properties => {
        rectype  => {type => 'string'},
        prio     => {type => 'integer'},
        can_edit => {type => 'boolean'} } 
    });
    
    my $data = { rectype => 'A', prio => '1', can_edit => 'true' };
    my $copy = { %$data };
    
    $errors = $validator->validate($data);
    ok !$errors, "can validate non valid types when `coerceTypes' option specified";
    is_deeply $data, $copy, 'original data not modified';
    
    $errors = $validator->validate(\$data);
    ok !$errors, "can validate non valid types when `coerceTypes' option specified and data passed by reference";
    $copy->{prio} = 1;
    $copy->{can_edit} = $JSON::PP::true;
    is_deeply $data, $copy, 'original data modified to pass schema';
    is encode_json( [@$data{qw(rectype prio can_edit)}] ),
       encode_json( ['A', 1, $JSON::PP::true] ), 'all types are correct when modified data converted to JSON';
};

done_testing();
