#!/usr/local/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class) = shift;
    return bless {}, $class;
}

sub PRINT  {
    my($self) = shift;
    $main::_STDOUT_ .= join '', @_;
}

sub READ {}
sub READLINE {}
sub GETC {}

package main;

local $SIG{__WARN__} = sub { $_STDERR_ .= join '', @_ };
tie *STDOUT, 'Catch' or die $!;


{
#line 57 lib/CPAN/Test/Reporter.pm
BEGIN: use_ok('CPAN::Test::Reporter', "use CPAN::Test::Reporter");
my $r = new CPAN::Test::Reporter;
ok($r->isa('CPAN::Test::Reporter'), "Got a CPAN::Test::Reporter object");

}

{
#line 85 lib/CPAN/Test/Reporter.pm
my $r = new CPAN::Test::Reporter;
$r->grade('pass');
is($r->{grade}, 'pass', "Set the grade");

}

{
#line 129 lib/CPAN/Test/Reporter.pm
my $r = new CPAN::Test::Reporter;
$r->package("Foo-Bar-0.01");
is($r->{package}, "Foo-Bar-0.01", "Set the package");

}

{
#line 146 lib/CPAN/Test/Reporter.pm
my $r = new CPAN::Test::Reporter;
$r->test_results("here are my test results");
is($r->{test_results}, "here are my test results", "Set the test results");

}

{
#line 162 lib/CPAN/Test/Reporter.pm
my $r = new CPAN::Test::Reporter;
$r->comments("here are my comments");
is($r->{comments}, "here are my comments", "Set the comments");

}

{
#line 221 lib/CPAN/Test/Reporter.pm
is(CPAN::Test::Reporter::build_cc('skud@infotrope.net', 'skud@e-smith.com'), 'skud@infotrope.net, skud@e-smith.com', "Building CC list from email addresses");

}

