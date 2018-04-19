#!/perl

use strict;
use warnings;

use Test::Most;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";


use_ok 'DBIx::Result::Convert::JSONSchema';
use_ok 'Test::SchemaMock';

throws_ok {
    DBIx::Result::Convert::JSONSchema->new();
} qr/Missing required arguments: schema/;

throws_ok {
    DBIx::Result::Convert::JSONSchema->new( schema => 1 );
} qr/Value "1" did not pass type constraint/;

my $schema_mock = Test::SchemaMock->new();

throws_ok {
    DBIx::Result::Convert::JSONSchema->new( schema_source => 'Rat', schema => $schema_mock->schema );
} qr/Value "Rat" did not pass type constraint/;

isa_ok
    my $converter = DBIx::Result::Convert::JSONSchema->new( schema => $schema_mock->schema ),
    'DBIx::Result::Convert::JSONSchema';

done_testing;
