#!perl
# libucl-0.8.1/python/tests/test_validation.py

use strict;
use warnings;
use Test::Most;
use File::Basename;
use JSON::PP qw(decode_json);

die_on_fail;

use Config::UCL;

sub json_remove_comments { $_[0] =~ s{/\*((?!\*/).)*?\*/}{}msr }
sub slurp { open my $in, "<", $_[0] or die $!; local $/; <$in> }

my @schema_files = glob "libucl-0.8.1/tests/schema/*.json";
for my $schema_file (@schema_files) {
    my $root = decode_json json_remove_comments slurp $schema_file;
    subtest $schema_file => sub {
        for my $testgroup (@$root) {
            subtest $testgroup->{description} => sub {
                for my $test (@{$testgroup->{tests}}) {
                    my $schema = $testgroup->{schema};
                    my $data   = $test->{data};
                    my $valid  = $test->{valid};
                    my $msg    = "$test->{description} (valid=@{[ $valid ? 'True' : 'False' ]})";
                    my $diag   = sub {
                        #use Devel::Peek ();
                        #use YAML::Syck;
                        #diag Dump { schema => $schema, data => $data };
                        diag ucl_dump($schema);
                        diag ucl_dump($data);
                        #Devel::Peek::Dump($data);
                    };
                    my $ret = ucl_validate($schema, $data);
                    my $err = ucl_schema_error();
                    SKIP: {
                        # Validation failed: cannot fetch reference http://highsecure.ru/ucl-schema/schema: URL support is disabled
                        skip $err, 1 if $err and $err =~ /support is disabled/;
                        is !!$ret, !!$valid, $msg or $diag->();
                    }
                }
            };
        }
    };
}

done_testing;
