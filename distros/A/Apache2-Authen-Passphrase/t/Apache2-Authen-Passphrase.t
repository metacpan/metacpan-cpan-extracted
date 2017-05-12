use v5.14;
use strict;
use warnings;

use File::Temp qw/tempdir/;
use Test::More tests => 7;
BEGIN { $ENV{AAP_ROOTDIR} = tempdir CLEANUP => 1 }
BEGIN { use_ok('Apache2::Authen::Passphrase', qw/pwset pwcheck/) };

sub pw_ok {
	my ($user, $pass, $testname) = @_;
	eval { pwcheck $user, $pass };
	is $@, '', $testname;
}

sub pw_nok {
	my ($user, $pass, $testname) = @_;
	eval { pwcheck $user, $pass };
	isnt $@, '', $testname;
}

pwset marius => 'password';
pw_ok marius => 'password', 'Set password and check it';
pw_nok marius => 'anotherpassword', 'Check an incorrect password';

pwset marius => 'anotherpassword';
pw_ok marius => 'anotherpassword', 'Change the password and check it';

pw_nok 'BadUsername++', 'a', 'Bad username';
pw_nok 'a', 'a', 'Short username';
pw_nok 'asfwe0g3girg4ih45jho45ih45hi45h045jh4oh', 'a', 'Long username';
