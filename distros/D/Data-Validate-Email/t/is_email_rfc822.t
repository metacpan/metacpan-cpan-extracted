#!/usr/bin/perl

# -------------------------------------------------------------------------------
# test harness for Data::Validate::is_email_rfc822
#
# Author: Richard Sonnen (http://www.richardsonnen.com/)
# -------------------------------------------------------------------------------

use lib './t';
use ExtUtils::TBone;

use lib './blib';
use Data::Validate::Email qw(is_email_rfc822);

my $t = ExtUtils::TBone->typical();

$t->begin(15);
$t->msg("testing is_email_rfc822...");

# valid
$t->ok(defined(is_email_rfc822('bob@test.com')), 'bob@test.com');
$t->ok(defined(is_email_rfc822('bob@test.com.au')), 'bob@test.com.au');
$t->ok(defined(is_email_rfc822('foo.bob@test.com.au')), 'foo.bob@test.com.au');
$t->ok(defined(is_email_rfc822('foo-bob@test-com.au')), 'foo-bob@test-com.au');
$t->ok(defined(is_email_rfc822('foo-bob@test.uk')), 'foo-bob@test.uk');
$t->ok(defined(is_email_rfc822('Richard Sonnen <sonnen@frii.com>')), 'Richard Sonnen <sonnen@frii.com>');
$t->ok(defined(is_email_rfc822('<sonnen@frii.com>')), '<sonnen@frii.com>');
$t->ok(defined(is_email_rfc822('"Richard Sonnen" <sonnen@frii.com>')), '"Richard Sonnen" <sonnen@frii.com>');
$t->ok(defined(is_email_rfc822('"Richard Sonnen" <sonnen@frii.com> (comments)')), '"Richard Sonnen" <sonnen@frii.com> (comments)');

# invalid
$t->ok(!defined(is_email_rfc822('')), "bad: ''");
$t->ok(!defined(is_email_rfc822('foo')), 'bad: foo');
$t->ok(!defined(is_email_rfc822('foo bar@bar.com')), 'bad: foo bar@bar.com');
$t->ok(!defined(is_email_rfc822('<foo bar>@bar.com')), 'bad: "<foo bar>@bar.com');


# as an object
my $v = Data::Validate::Email->new();
$t->ok(defined($v->is_email_rfc822('bob@test.com')), 'bob@test.com (object)');
$t->ok(!defined($v->is_email_rfc822('foo bar@bar.com')), 'bad: foo bar@bar.com (object)');

# we're done
$t->end();

