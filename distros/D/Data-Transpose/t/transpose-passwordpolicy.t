# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Data-Transpose-PasswordPolicy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 83;
BEGIN { use_ok('Data::Transpose::PasswordPolicy') };



use Data::Transpose::PasswordPolicy;
use Data::Dumper;

my %credential = (username => " marco ",
		  password => " ciao ",
		 );

my $pv = Data::Transpose::PasswordPolicy->new(\%credential);

print "Checking accessors\n";

ok((not $pv->is_valid), "simple password is not valid");

is($pv->password, "ciao", "password method works");

is($pv->username, "marco", "username method works");

is($pv->password_length, 4, "password_length works");

is($pv->minlength, 12, "minlength works (12)");

is($pv->maxlength, 255, "maxlength works (255)");

is($pv->mindiffchars, 6, "mindiffchars works (6)");

$pv->password("Aklsxdflasjdflaj89q3klasxwdd!");

# $pv->reset_errors;

ok($pv->is_valid, "password '". $pv->password . "' is valid");

# $pv->reset_errors;

ok($pv->is_valid("AXvx&/ad832kdzidsk43dlsf"),
   $pv->password . 'is valid too (passed via ->is_valid($pass)');

print $pv->error;

# $pv->reset_errors;

$pv->password("Aklsxdflasjdflaj89q3klasxwdd_");

ok($pv->is_valid, $pv->password . " is valid");

# $pv->reset_errors;
# print $pv->error;

# try the settings
$pv->maxlength(10);
$pv->minlength(3);
ok(!$pv->is_valid, "password is not valid with limits 3 and 10");

# $pv->reset_errors;

$pv->maxlength(length $pv->password);
ok($pv->is_valid, "password now is valid with lenght " . $pv->maxlength);
# print $pv->error;


$pv->password("\n   hello there    \n\n");
is ($pv->password, "hello there", "Spaces stripped correctly");
$pv->username("\n \n \n myself \n \n \n");
is ($pv->username, "myself", "Spaces in username stripped correctly");


## starting tests with default values

password_not_ok("marcopess", 'IamM4rC0P3$$X_X');

password_not_ok("marco", "123123123123123");

password_not_ok("Marco", "P455w0rdP455w0rd");

password_not_ok("Marco", "000000000Fu*Kfu*k");

password_ok("Marco", "1.Long.pazzword.but.will.have.too.many.repeatitions");

password_not_ok("Marco", "will.have.too.many.repeatitions.000000000000000000");

password_ok("Marco", "This.style.of.passwd.is.ok.3");

password_not_ok("Marco", "as.long.as.we.avoid.words.like.fuck");

password_not_ok("Marco", "this.have.too.repet.llllllllllllllll");

password_not_ok("Marco", "this.cant.do.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");

password_not_ok("Marco", "this.cant.aaaa");

password_not_ok("Marco", "this.bbbbbbbbbbbb.aaaa");

password_not_ok("Marco", "");

sub password_ok {
    my ($user, $pass) = @_;
    my $pasvad = Data::Transpose::PasswordPolicy->new({username => $user,
							 password => $pass,
							});
#    $pasvad->password($pass);
    ok($pasvad->is_valid, "$pass for $user is valid");
    ok(!$pasvad->error, "No errors");
    print $pasvad->error if $pasvad->error;
}

sub password_not_ok {
    my ($user, $pass) = @_;
    my $pasvad = Data::Transpose::PasswordPolicy->new({username => $user});
    $pasvad->password($pass);
    ok(!$pasvad->is_valid, "$pass for $user is not valid");
    ok(($pasvad->error), "With errors:  " . $pasvad->error);
    #    print Dumper($pasvad);
}


print "Checking constructor\n";

$pv = Data::Transpose::PasswordPolicy->new(
					     {
					      username => "marco",
					      password => "password",
					      minlength => 2,
					      maxlength => 10,
					      mindiffchars => 8,
					      disabled => {
							   mixed => 1,
							   digits => 1,
							   patterns => 1,
							   common => 1,
							   letters => 1,
							   specials => 1,
							   username => 1,
							   varchars => 1,
							  }
					     }
					    );

# print $pv->error;

foreach my $enable (qw/mixed digits common specials varchars/) {
    ok($pv->is_valid,
       $pv->password . " is surprisingly valid because we disabled everything");
    $pv->enable($enable);
    ok(!$pv->is_valid, "But not anymore, with $enable enabled...");
    ok($pv->error, $pv->error);
    my ($errcode) = $pv->error_codes; # pick the first value
    is($errcode, $enable, "Checking the error code $enable");
    $pv->disable($enable);
    #    $pv->reset_errors;
}

my %checks = ("m4rc0" => "username",
	      "23867934" => "letters",
	      "aadf123" => "patterns",
	      "asdfasdf" => "patterns");

while (my ($password, $enable) = each %checks) {
    ok($pv->is_valid,
       $pv->password . " is valid (?)! because everything is off");
    $pv->password($password);
    $pv->enable($enable);
    ok(!$pv->is_valid, "But not anymore, with $enable enabled...");
    ok($pv->error, $pv->error);
    my ($errcode) = $pv->error_codes; # pick the first value
    is($errcode, $enable, "Checking the error code $enable");
    $pv->disable($enable);
    # $pv->reset_errors;
}

$pv->enable("patterns");
$pv->patternlength(4);
$pv->password("asd123");
ok($pv->is_valid, $pv->password . " is valid when patternlength is 4");
# $pv->reset_errors;
$pv->patternlength(3);
ok(!$pv->is_valid, "After setting to 3, it's not anymore: " . $pv->error);
my ($errcode) = $pv->error_codes;
is($errcode, 'patterns', "Checking error code length");

# speed test;

my $time = time();
my $tries = 200;

for (1 .. $tries) {
    my $pasvad = Data::Transpose::PasswordPolicy->new({username => "marco",
							 password => "this.is.a.pazzword.I.could.Consider.Safe.5"});
    print "." if $pasvad->is_valid;
}
print "\n";
my $newtime = time();
my $average = ($newtime - $time) / $tries;
ok(($average < 0.2), "checking that each password takes less then 0.2 second: $average");

my $lasttest = Data::Transpose::PasswordPolicy->new(
                                                    {username => "marco",
                                                     password => "pass1234",
                                                    });

$lasttest->is_valid;
my @errors = $lasttest->error;

print Dumper(\@errors);
my @expected = (
                [
                 'length',
                 'Wrong length (it should be long at least 12 characters)'
                ],
                [
                 'specials',
                 'No special characters'
                ],
                [
                 'common',
                 'Found common password'
                ],
                [
                 'mixed',
                 'No mixed case'
                ],
                [
                 'patterns',
                 'Found common patterns: 123, 234'
                ]
               );

is_deeply(\@errors, \@expected, "Checking resulting array");
is($lasttest->error, join("; ", map { $_->[1] } @expected),
   "Checking error string");
