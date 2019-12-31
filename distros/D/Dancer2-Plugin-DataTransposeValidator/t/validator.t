#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use aliased 'Dancer2::Plugin::DataTransposeValidator::Validator';

subtest test_required_constructor_args => sub {
    my %args = (
        params => { a       => 1 },
        rules  => { options => {}, prepare => {} },
        css_error_class => 'foo',
        errors_hash     => 'joined',
    );

    for my $key ( sort keys %args ) {
        my %args = %args;
        delete $args{$key};
        like exception { Validator->new(%args) },
          qr/Missing required arguments: $key/,
          "constructor dies as expected when '$key' is missing";

    }
};

subtest test_validator => sub {
    my %args = (
        params => {
            foo => " some string   ",
            bar => "sksadukqpc"
        },
        rules => {
            options => { stripwhite => 1 },
            prepare => {
                foo => { validator => 'String' },
                bar => {
                    validator => {
                        class => 'PasswordPolicy',
                        options =>
                          { minlength => 20, disabled => { username => 1, } }
                    }
                }
            }
        },
        css_error_class => 'foo',
        errors_hash     => 'joined',
    );

    my $data = Validator->new(%args);
    cmp_deeply $data,
      methods(
        valid  => 0,
        values => { foo => "some string", bar => "sksadukqpc" },
        css    => { bar => "foo" },
        errors => {
            bar =>
"Wrong length (it should be long at least 20 characters). No special characters. No digits in the password. No mixed case"
        },
      ),
"testing one good and one bad value with joined errors_hash and css_error_class 'foo'";

    $args{css_error_class} = 'invalid';
    $args{errors_hash}     = 'arrayref';
    $data                  = Validator->new(%args);
    cmp_deeply $data,
      methods(
        valid  => 0,
        values => { foo => "some string", bar => "sksadukqpc" },
        css    => { bar => "invalid" },
        errors => {
            bar => [
                "Wrong length (it should be long at least 20 characters)",
                "No special characters",
                "No digits in the password",
                "No mixed case"
            ]
        },
      ),
"testing one good and one bad value with arrayref errors_hash and css_error_class 'invalid'";

    $args{params}{bar} = "ahM7feeTho9oof4Zeefoolohcoolo4(";
    $data = Validator->new(%args);
    cmp_deeply $data,
      methods(
        valid => 1,
        values =>
          { foo => "some string", bar => "ahM7feeTho9oof4Zeefoolohcoolo4(" },
      ),
      "testing good values should have no 'css' or 'errors'";
};

done_testing;
