use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More tests => 32;

# two ways to set the same thing

sub get_schema {
    my @schema = (
                  {
                   name => 'password',
                   validator => {
                                 class => 'Data::Transpose::PasswordPolicy',
                                 absolute => 1,
                                 options => {
                                             minlength => 10,
                                             maxlength => 50,
                                             patternlength => 4,
                                             mindiffchars => 5,
                                             disabled => {
                                                          digits => 1,
                                                          mixed => 1,
                                                          username => 1,
                                                         }
                                            }
                                }
                  },
                  {
                   name => 'confirm_password',
                   required => 1,
                  },
                  {
                   name => 'passwords',
                   validator => 'Group',
                   fields => [
                              qw/password confirm_password/,
                             ],
                   equal => 1,
                  },
                 );
    return \@schema;
}

sub get_hash_schema {
    my %hash = (
                password => {
                             validator => {
                                           class => 'Data::Transpose::PasswordPolicy',
                                           absolute => 1,
                                           options => {
                                                       minlength => 10,
                                                       maxlength => 50,
                                                       patternlength => 4,
                                                       mindiffchars => 5,
                                                       disabled => {
                                                                    digits => 1,
                                                                    mixed => 1,
                                                                    username => 1,
                                                                   }
                                                      }
                                          },
                            },
                confirm_password => {
                                     required => 1,
                                    },
                passwords => {
                              validator => 'Group',
                              fields => [
                                         qw/password confirm_password/,
                                        ],
                              equal => 1,
                             }
                );
    return %hash;
}


my $dtv = Data::Transpose::Validator->new;

$dtv->field(password => { required => 1 });
$dtv->field(confirm_password => { required => 1 });
$dtv->group(passwords => "password", "confirm_password")->equal;

my $form = { password => 'a',
             confirm_password => 'b' };

my $res = $dtv->transpose($form);

ok(!$res);
ok($dtv->packed_errors); # and diag $dtv->packed_errors;

$res = $dtv->transpose({ password => 'a', confirm_password => 'a' });
ok ($res);
ok (!$dtv->errors);

$res = $dtv->transpose({ password => 'a', confirm_password => 'c' });
ok (!$res);
ok ($dtv->errors);
ok ($dtv->packed_errors);

$res = $dtv->transpose( { password => '', confirm_password => 'c' });
ok (!$res);
ok ($dtv->errors);
# diag $dtv->packed_errors;


$dtv = Data::Transpose::Validator->new;
$dtv->field(password => { required => 1 });
$dtv->field(confirm_password => { required => 1 });
$dtv->group(passwords => "password", "confirm_password")->equal(0);

$res = $dtv->transpose({password => "a", confirm_password => "c" });
ok($res);
my $group = $dtv->group('passwords');
ok($group, "Object retrieved");
ok($group->warnings, "Warning found"); # diag $group->warnings;

# even if equal, the validation doesn't pass because of the empty strings
$res = $dtv->transpose({password => "", confirm_password => "" });
ok(!$res);
ok($dtv->errors); # diag join("\n", $dtv->packed_errors);


# first test bad configurations
$dtv = Data::Transpose::Validator->new;
eval {
    $dtv->prepare([
                   { name => 'pass',
                     validator => 'String' },
                   { name => 'cpass',
                     validator => 'String' },
                   {
                    validator => 'Group',
                   }
                  ]);
};
ok ($@, "Exception with Group when passing no name");

$dtv = Data::Transpose::Validator->new;
eval {
    $dtv->prepare([
                   { name => 'pass',
                     validator => 'String' },
                   { name => 'cpass',
                     validator => 'String' },
                   { name => 'passwords',
                     validator => 'Group' }
                  ]);
};
ok ($@, "Exception with Group when passing no fields");

$dtv = Data::Transpose::Validator->new;
eval {
    $dtv->prepare([
                   { name => 'pass',
                     validator => 'String' },
                   { name => 'cpass',
                     validator => 'String' },
                   { name => 'passwords',
                     validator => 'Group',
                     fields => [qw/pass mpass/],
                   }
                  ]);
};
ok ($@, "Exception with Group when passing unexistent fields");

$dtv = Data::Transpose::Validator->new;
eval {
    $dtv->prepare([
                   { name => 'pass',
                     validator => 'String' },
                   { name => 'cpass',
                     validator => 'String' },
                   { name => 'passwords',
                     validator => 'Group',
                     fields => [qw/pass cpass/],
                     blabla => 1,
                   }
                  ]);
};
ok ($@, "Exception with Group when passing unknown keys");


# diag "Testing the group in config with passwords";
$dtv = Data::Transpose::Validator->new;
$dtv->prepare(get_schema());

$res = $dtv->transpose({ password => "abc", confirm_password => "abc" });
ok ((!$res && $dtv->errors), "Passwords match, but too easy");

$res = $dtv->transpose({ password => "a1xd8,3z90j241efs0", confirm_password => "abc" });
ok ((!$res && $dtv->errors), "Good password, but no match");

$res = $dtv->transpose({ password => "a1xd8,3z90j241efs0",
                         confirm_password => "a1xd8,3z90j241efs0" });
ok (($res && !$dtv->errors), "Good passwords and match, fully validated");


# diag "Testing with hash";
$dtv = Data::Transpose::Validator->new;
$dtv->prepare(get_hash_schema());

ok(!$dtv->field("password")->required);
$dtv->field("password")->required(1);
ok $dtv->field("password")->required, "Changing the requirement works";
ok $dtv->field("confirm_password")->required;


$res = $dtv->transpose({ password => "abc", confirm_password => "abc" });
ok ((!$res && $dtv->errors), "Passwords match, but too easy");
#  and diag ($dtv->packed_errors . "");


$res = $dtv->transpose({ password => "a1xd8,3z90j241efs0", confirm_password => "abc" });
ok ((!$res && $dtv->errors), "Good password, but no match");
#  and diag ($dtv->packed_errors . "");

$res = $dtv->transpose({ password => "a1xd8,3z90j241efs0",
                         confirm_password => "a1xd8,3z90j241efs0" });
ok (($res && !$dtv->errors), "Good passwords and match, fully validated");

# but if we are so dumb to set equal 0, no check on matching is done

$dtv = Data::Transpose::Validator->new;
$dtv->prepare(get_hash_schema());
$dtv->group("passwords")->equal(0);
$res = $dtv->transpose({ password => "", confirm_password => "abc" });
ok(($res && !$dtv->errors), "Unfortunately no check on match is done now");
$dtv->group("passwords")->equal(0);
$res = $dtv->transpose({ password => "", confirm_password => "" });
ok(!$res && $dtv->errors); #  and diag $dtv->packed_errors . "";
$res = $dtv->transpose({ password => "a1xd8,3z90j241efs0",
                         confirm_password => "a1xd8,3z90j241efs0" } );
ok($res && !$dtv->errors);


$dtv = Data::Transpose::Validator->new;
$dtv->prepare(password => { required => 1 },
              confirm_password => { required => 1 },
              passwords_matching => {
                                     validator => 'Group',
                                     fields => [ "password", "confirm_password" ]
                                    });

ok $dtv->transpose({ password => "a", confirm_password => "a" });
ok !$dtv->transpose({ password => "a", confirm_password => "b" });
