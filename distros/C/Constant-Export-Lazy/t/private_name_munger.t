package TestSimple;
use strict;
use warnings;
use Exporter 'import';
use constant {
    CONST_OLD_1 => 123,
    CONST_OLD_2 => 456,
};
BEGIN {
    our @EXPORT_OK = qw(CONST_OLD_1 CONST_OLD_2);
}

our $NOW; BEGIN { $NOW = time }
use Constant::Export::Lazy (
    constants => {
        FOO => sub { 'FOO' },
        BAR => sub { 'BAR' },
        BAZ => {
            call => sub { 'BAZ' },
            options => {
                private_name_munger => sub { "$_[0]_BLAH_NAME" },
            },
        },
        BLAH => {
            call => sub {
                $main::NUM_BLAH_CUSTOM_CALLS++;
                return 'BLAH_CUSTOM';
            },
            options => {
                private_name_munger => sub { $_[0] . '_' . $main::BLAH_NAME },
            },
        },
        ALWAYS_DEFINED_BLAH => sub { 'BLAH' },
    },
    options => {
        wrap_existing_import => 1,
        private_name_munger => sub {
            my ($gimme) = @_;

            return if $gimme =~ /^ALWAYS_DEFINED_/;

            return $gimme . '_TIME_' . $NOW;
        },
    },
);

package main;
use strict;
use warnings;
use lib 't/lib';
use Test::More 'no_plan';
BEGIN {
    TestSimple->import(qw(
        CONST_OLD_1
        CONST_OLD_2
        FOO
        BAR
        BAZ
        ALWAYS_DEFINED_BLAH
    ));
}

is(CONST_OLD_1, 123, "We got a constant from the Exporter::import");
is(CONST_OLD_2, 456, "We got a constant from the Exporter::import");
ok(!exists &TestSimple::FOO, "We didn't define a FOO");
ok(!exists &TestSimple::BAR, "We didn't define a BAR");
ok(!exists &TestSimple::BAZ, "We didn't define a BAZ");
is(TestSimple::BAZ_BLAH_NAME(), 'BAZ',  "We *did* define a BAZ as BAZ_BLAH_NAME");
is(TestSimple::ALWAYS_DEFINED_BLAH(), 'BLAH', "We *did* define a ALWAYS_DEFINED_BLAH");
$main::BLAH_NAME = 'FOO';
TestSimple->import('BLAH');
is(BLAH(), "BLAH_CUSTOM", "We return BLAH from BLAH()");
is(eval("TestSimple::BLAH_FOO()"), "BLAH_CUSTOM", "Importing BLAH with \$main::BLAH_NAME gives us 'BLAH_CUSTOM'");
$main::BLAH_NAME = 'BAR';
{
    my $warnings = 0;
    my $warning = '';
    local $SIG{__WARN__} = sub { $warnings++; $warning = $_[0] };
    TestSimple->import('BLAH');
    is($warnings, 1, "We got 1 warning about redefining main::BLAH");
    like($warning, qr/^Constant subroutine main::BLAH redefined/, "We got a warning for redefining main::BLAH");
}
is(eval("TestSimple::BLAH_BAR()"), "BLAH_CUSTOM", "Importing BLAH with \$main::BLAH_NAME gives us 'BLAH_CUSTOM'");
is($main::NUM_BLAH_CUSTOM_CALLS, 2, "We re-called BLAH because you fucked up private_name_munger");

{
    no strict 'refs';
    my $tmp;

    for my $n (qw(FOO BAR)) {
        $tmp = "TestSimple::${n}_TIME_${TestSimple::NOW}";
        is(&$tmp(), $n, "Defined the $n constant as $tmp");
    }
}
