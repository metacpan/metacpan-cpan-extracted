#!perl

use strict;
use warnings;

use Test::More;

use Capture::Tiny qw/capture_stderr/;
use Data::JSONSchema::Ajv;
use Path::Tiny qw/path/;
use Cpanel::JSON::XS qw/decode_json/;
use Data::Dumper;

my $path = path(qw/t JSON-Schema-Test-Suite tests/);
die "Missing JSON test suite at $path" unless $path->exists;

# Dive through the multi-hierarchy tests!
for my $version (qw/4 6 7/) {

    my $ajv = Data::JSONSchema::Ajv->new({},{ draft => "0$version" });

    subtest "Draft $version", sub {
        my $version_directory = $path->child("draft$version");
        my @test_files        = $version_directory->children(qr/\.json$/);
        for my $test_file (@test_files) {
            subtest "Test file: $test_file", sub {
                my @test_groups = @{ decode_json $test_file->slurp_raw() };
                for my $test_group (@test_groups) {
                    subtest "Test group: " . $test_group->{'description'},
                        sub {

                        # Root out any kind of remote reference
                        my $schema = $test_group->{'schema'};
                        if ( ref($schema) eq 'HASH' ) {
                            my $important = ( $schema->{'$ref'} // "" )
                                . ( $schema->{'$id'} // "" ) .  ($schema->{'id'} // "" );;
                            if ( $important =~ m!://! ) {
                                plan skip_all =>
                                    'Remote reference test detected, skipped';
                                return;
                            }
                        }

                        # Manually fix-up numbers in some draft4 tests
                        if ( $test_file =~ m/maximum.json/ && $version == 4 ) {
                            $schema->{'maximum'} += 0;
                        }

                        my $validator;
                        my $js_errors = capture_stderr {
                            $validator = $ajv->make_validator($schema)
                        };

                        ok( ( !$js_errors ), "Schema built with no errors" );
                        if ($js_errors) {
                            diag "Failed to build schema: $js_errors";
                            diag( Dumper $schema );
                            diag "Skipping tests for this schema";
                            return;
                        }

                        for my $test_case ( @{ $test_group->{'tests'} } ) {
                            $js_errors = "";

                            my $description = $test_case->{'description'};
                            my $data        = $test_case->{'data'};
                            my $valid       = $test_case->{'valid'};

                            my @errors;
                            my $js_errors = capture_stderr {
                                @errors = $validator->validate($data)
                            };

                            if ($js_errors) {
                                ok( 0, "$description: JS errors detected" );
                                diag($js_errors);
                                die;
                                next;
                            }

                            if ($valid) {
                                ok( ( !@errors ), "$description: is valid" )
                                    && next;

                            }
                            else {
                                ok( (@errors), "$description: not valid" )
                                    && next;
                                diag
                                    "Expected to find errors, but found none";
                            }

                            diag( Dumper($schema) );
                            diag( Dumper($data) );
                            diag( Dumper(@errors) );

                        }

                        }
                }
                }
        }
    };
}

done_testing();

__DATA__



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
