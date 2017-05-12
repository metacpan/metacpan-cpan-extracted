use strict;
use warnings;
use Test::More tests => 104;
use Data::Transpose::Validator::CreditCard;
use Data::Transpose::Validator;
use Data::Dumper;

my $v = Data::Transpose::Validator::CreditCard->new;
ok( $v->is_valid("4111111111111111"), "visa card is valid");
ok(!$v->error, "no error");
ok(!$v->is_valid("4111111112111111"), "Invalid cc");
ok($v->error, "Invalid cc returned an error " . $v->error);
is( $v->is_valid(" 4111 1111 1111 1111 "), "4111111111111111", "CC returned without spaces");

my $test_nums = $v->test_cc_numbers;

foreach my $type (keys  %$test_nums) {
    foreach my $num (@{$test_nums->{$type}}) {
        ok ($v->is_valid($num), "$num is valid");
        $num =~ m/^(\d{8})(\d)(.+)/;
        my ($prefix, $change, $rest) = ($1, $2, $3);
        # change a number to test the failure
        if ($change ne '0') {
            $num = $prefix . '0' . $rest;
        }
        else {
            $num = $prefix . '1' . $rest;
        }
        ok(!$v->is_valid($num), "$num is not valid");
        my $errorstring = $v->error;
        ok($errorstring, $errorstring || "failed");
        like($errorstring, qr/^\Q$type\E \(invalid\)/, "$type => $errorstring");
    }
}

# diag "Testing types";

$v = Data::Transpose::Validator::CreditCard->new(country => 'DE',
                                                 types => ["visa card",
                                                           "mastercard"]);

$test_nums = $v->test_cc_numbers;

foreach my $type (keys %$test_nums) {
    if ($type eq 'VISA card' or
        $type eq 'MasterCard') {
        foreach my $num (@{$test_nums->{$type}}) {
            ok($v->is_valid($num), "$type $num is valid") or diag Dumper($v);
        }
    }
    else {
        foreach my $num (@{$test_nums->{$type}}) {
            ok(!$v->is_valid($num), "$type $num is not valid");
            ok($v->error, "$type $num " . $v->error);
        }
    }
        
}

# diag "Testing a cc form with DTV";
my $dtv = Data::Transpose::Validator->new();
$dtv->prepare(
              cc_number => {
                            validator => {
                                          class => 'CreditCard',
                                          options => {
                                                      types => [ "visa card",
                                                                "mastercard",
                                                                "American Express card",
                                                                "Discover card" ],
                                                      country => 'DE',
                                                     },
                                         },
                            required => 1,
                           },
              cc_month => {
                           validator => {
                                         class => 'NumericRange',
                                         options => {
                                                     min => 1,
                                                     max => 12,
                                                    },
                                        },
                           required => 1,
                          },
              cc_year => {
                          validator => {
                                        class => 'NumericRange',
                                        options => {
                                                    min => 2013,
                                                    max => 2023,
                                                   },
                                       },
                          required => 1,
                         }
             );
my $form = {
            cc_number => ' 4111111111111111 ',
            cc_month => '12',
            cc_year => '2014',
           };

my $clean = $dtv->transpose($form);

ok($clean, "validation ok");

is_deeply($clean, {
                   cc_number => '4111111111111111',
                   cc_month => '12',
                   cc_year => '2014',
                  }, "Returned hash ok");


delete $form->{cc_year};
$clean = $dtv->transpose($form);
ok(!$clean);
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

delete $form->{cc_month};
$clean = $dtv->transpose($form);
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);
delete $form->{cc_number};

$clean = $dtv->transpose($form);
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

$form = {
         cc_number => '4111111112111111 ',
         cc_month => '12',
         cc_year => '2014',
        };
$clean = $dtv->transpose($form);
ok(!$clean, "wrong number fail");
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

$form->{cc_number} = '5610591081018250';
$clean = $dtv->transpose($form);
ok(!$clean, "Card valid but not of valid type => fail");
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

$form->{cc_number} = 'abcd';
$clean = $dtv->transpose($form);
ok(!$clean, "Card totally invalid");
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

$form->{cc_number} = '4111111111111112';
$clean = $dtv->transpose($form);
ok(!$clean, "Card invalid");
ok($dtv->errors, "Errors found:" . $dtv->packed_errors);

