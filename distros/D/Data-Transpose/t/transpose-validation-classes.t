use strict;
use warnings;
use Test::More tests => 117;
use Data::Transpose::Validator::Subrefs;
use Data::Transpose::Validator::Base;
use Data::Transpose::Validator::String;
use Data::Transpose::Validator::URL;
use Data::Transpose::Validator::NumericRange;
use Data::Transpose::Validator::Set;

use Data::Dumper;

print "Testing Base\n";
my $v = Data::Transpose::Validator::Base->new;
ok($v->is_valid("string"), "A string is valid");
ok($v->is_valid([]), "Empty array is valid");
ok($v->is_valid({}), "Empty hash is valid");
ok(!$v->is_valid(undef), "undef is not valid");
undef $v;

print "Testing coderefs\n";

sub custom_sub {
    my $field = shift;
    return $field
      if $field =~ m/\w/;
    return (undef, "Not a \\w");
}

my $vcr = Data::Transpose::Validator::Subrefs->new( \&custom_sub );

ok($vcr->is_valid("H!"), "Hi! is valid");
ok(!$vcr->is_valid("!"), "! is not");
is($vcr->error, "Not a \\w", "error displayed correctly");

sub validator_call {
    my $field = shift;
    if ( $field =~ /^[01]$/ ) {
        return 1;
    }
    else {
        return ( undef, "Not a boolean yes/no (1/0)" );
    }
}


$vcr = Data::Transpose::Validator::Subrefs->new(call => \&validator_call);
ok($vcr->is_valid(0), "0 is valid");
ok($vcr->is_valid(1), "1 is valid");
ok(!$vcr->is_valid(3), "3 is not valid");
is($vcr->error, "Not a boolean yes/no (1/0)");

undef $vcr;




print "Testing strings\n";

my $vs = Data::Transpose::Validator::String->new;

ok($vs->is_valid(" "), "Space is valid");
ok($vs->is_valid("\n"), "Newline is valid");
ok(!$vs->error, "No error");
ok(!$vs->is_valid([]), "Arrayref is not valid");
is($vs->error, "Not a string");
ok($vs->is_valid("0"), '"0" is valid');
ok(!$vs->is_valid(""), 'empty string is not valid');
is($vs->error, "Empty string");
ok(!$vs->is_valid(undef), "undef is invalid");
is($vs->error, "String is undefined");
undef $vs;

print "Testing urls\n";

my $vu = Data::Transpose::Validator::URL->new;

my @goodurls = ("http://google.com",
                "https://google.com",
                "https://this.doesnt-exists.but-is-valid.co.gov");

my @badurls = ("http://this@.doesnt@-exists.but-is-valid.co.gov",
               "__http://__",
               "http:\\google.com",
               "htp://google.com",
               "http:/google.com",
               "https:/google.com",
              );


foreach my $url (@goodurls) {
    ok($vu->is_valid($url), "$url is valid")
};

foreach my $url (@badurls) {
    ok(!$vu->is_valid($url), "$url is not valid");
    my @errors = $vu->error;
    is_deeply($errors[0], ["badurl",
                           "URL is not correct (the protocol is required)"],
              "Error code for $url is correct" . $vu->error);
}


my $vnr = Data::Transpose::Validator::NumericRange->new(
                                                        min => -90,
                                                        max => 90,
                                                       );

foreach my $val (-90, 10.5, 0, , 80.234, 90) {
    ok($vnr->is_valid($val), "$val is valid");
    ok(!$vnr->error, "No errors");
    if (my $error = $vnr->error) {
        print $error, "\n";
    }
}

foreach my $val (-91, -110.5, 1234, , 181.234, 90.1) {
    ok(!$vnr->is_valid($val), "$val is not valid");
    ok($vnr->error, "$val output an error: " . $vnr->error);
}


my $vnri = Data::Transpose::Validator::NumericRange->new(
                                                        min => 0,
                                                        max => 15,
                                                        integer => 1,
                                                       );

foreach my $val (0, 15, 8) {
    ok($vnri->is_valid($val), "$val is valid");
    ok(!$vnri->error, "No errors");
}

foreach my $val (-1, 0.5, 8.5, 14.99, 15.1) {
    ok(!$vnri->is_valid($val), "$val is not valid");
    ok($vnri->error, "Error returned: " . $vnri->error);
}

my $vset = Data::Transpose::Validator::Set->new(
                                                list => [qw/Yes No Maybe/],
                                                multiple => 0,
                                               );

foreach my $val ("Yes", "No", "Maybe") {
    ok($vset->is_valid($val), "$val is valid in Set");
    ok(!$vset->error, "No error");
}

foreach my $val ("yes", "no", "\n", "maybe", ".", ["Yes", "No"]) {
    ok(!$vset->is_valid($val), "$val is not valid in Set");
    ok($vset->error, "Error: " . $vset->error);
}

ok(!$vset->is_valid("Yes", "No"), "Multiple values are not valid");


print "Checkin multiple values\n";

$vset = Data::Transpose::Validator::Set->new(
                                             list => [qw/Yes No Maybe/],
                                             multiple => 1,
                                            );

foreach my $val (["Yes", "No"],
                 "No",
                 ["Yes", "Maybe"],
                 ["Yes", "No", "Maybe"]) {
    ok($vset->is_valid($val), "$val is valid in Set");
    ok(!$vset->error, "No error");
    print $vset->error . "\n" if ($vset->error);
}

foreach my $val ("yes", "no", "\n", "maybe", ".") {
    ok(!$vset->is_valid($val), "$val is not valid in Set");
    ok($vset->error, "Error: " . $vset->error);
}

ok($vset->is_valid("Yes", "No", "Maybe"));
ok($vset->is_valid("Yes", "No"));
ok($vset->is_valid("Yes"));
ok($vset->is_valid("No", "Maybe"));
ok(!$vset->is_valid("Yes", "cioa"), "One good and one bad => fail");
ok($vset->error, $vset->error);
ok(!$vset->is_valid("bad", "cioa"), "Two bad => fail");
ok($vset->error, $vset->error);


