#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_username
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::Email qw(is_username);

my $t = ExtUtils::TBone->typical();

$t->begin(11);
$t->msg("testing is_username...");

# valid
$t->ok(defined(is_username('sonnen')), 'sonnen');
$t->ok(defined(is_username('bob.smith')), 'bob.smith');
$t->ok(defined(is_username('bob-smith')), 'bob-smith');
$t->ok(defined(is_username('a')), 'a');
$t->ok(defined(is_username('bob-smith+cpan')), 'bob-smith+cpan');



# invalid
$t->ok(!defined(is_username('')), "bad: ''");
$t->ok(!defined(is_username('bob@test.com')), 'bad: bob@test.com');
$t->ok(!defined(is_username('bob smith')), "bad: bob smith");
$t->ok(!defined(is_username('bob*smith')), "bad: bob*smith");




# as an object
my $v = Data::Validate::Email->new();
$t->ok(defined($v->is_username('sonnen')), 'sonnen (object)');
$t->ok(!defined($v->is_username('foobar@bar.com')), 'bad: foobar@bar.com (object)');

# we're done
$t->end();

