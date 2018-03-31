#!perl

use strict;
use warnings;

use Test::JSON::Schema::Acceptance;
use Data::Dumper;
use Data::JSONSchema::Ajv;
use Test::More;

# This file was inspired by:
# http://cpansearch.perl.org/src/JHTHORSEN/JSON-Validator-0.85/t/acceptance.t
my $ajv = Data::JSONSchema::Ajv->new();

my $accepter = Test::JSON::Schema::Acceptance->new(4);
my $json     = JSON->new->allow_nonref;
$accepter->acceptance(
    sub {
        my ( $schema, $payload ) = @_;
        $payload = $json->decode($payload);

        note "=====\nSCHEMA\n=====\n" . Dumper($schema) . "\n=====\n";
        note "PAYLOAD\n=====\n" . Dumper($payload) . "\n=====\n";

        my $validator = $ajv->make_validator($schema);
        my @errors    = $validator->validate($payload);

        if ( @errors ) {
            note( Dumper( \@errors ) );
        }

        return @errors ? 0 : 1;
    },
    { skip_tests => ["remote ref", "changed scope ref"] }
);

done_testing();
