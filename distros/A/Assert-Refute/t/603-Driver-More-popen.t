#!perl

# This test verifies integration with Test::More
# the brutal way.
# It spits out tiny `perl -e` spnippets and collects their output.
# This is probably a dead end considering there's Test::Tester.
# But we have to keep it for some edge cases for now.

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

# Make sure to work under cover -t
$ENV{HARNESS_PERL_SWITCHES} ||= '';

# Calculate where Assert::Refute loads from
my $path;
eval {
    my $mod = 'Assert/Refute.pm';
    require $mod;
    my $full = $INC{$mod};
    $full =~ s#/\Q$mod\E$## or die "Cannot determine location from path $full";
    $path = $full;
} || do {
    plan tests => 1;
    ok 0, "Failed to load Assert::Refute: $@";
    exit 1;
};

if ($path =~ /["'\$]/) {
    plan skip_all => "Path not suitable for subshelling: $path";
    exit;
};

# This boilerplate protects from printing to STDERR
# And also lets Assert::Refute know it's under Test::More
my $preamble = <<"PERL";
BEGIN {open STDERR, q{>&STDOUT} or die \$!};
use Test::More;
use warnings FATAL=>qw(all);
use lib q{$path};
use Assert::Refute;

PERL
# Avoid variable interpolation
my $q = $^O eq 'MSWin32' ? q{"} : q{'};

# Pack all boilerplate together and output a string
sub run_cmd {
    my $cmd = shift;

    $cmd =~ /"'/ and die "No quotes in command, use qq{...} instead";

    my $pid = open my $fd, "-|"
        , qq{$^X $ENV{HARNESS_PERL_SWITCHES} -e ${q}$preamble$cmd${q}}
            or die "Failed to run perl: $!";

    local $/;
    my $out = <$fd>;
    die "Failed to read from pipe: $!"
        unless defined $out;

    return $out;
};

# Actual tests begin

my $diag = run_cmd( "diag q{IF YOU SEE THIS, TEST FAILED}" );
like $diag, qr/IF YOU SEE/, "(self-test) STDERR is captured";

note "HAPPY PATH";
my $smoke = run_cmd( "refute 0, q{good}; done_testing;" );
is $smoke, "ok 1 - good\n1..1\n", "Happy case";

note "FAIL";
my $smoke_bad = run_cmd( "refute q{reason}, q{bad}; done_testing;" );
like $smoke_bad, qr/^not ok 1/, "test failed";
like $smoke_bad, qr/\n# *reason/, "reason preserved";
like $smoke_bad, qr/\n1..1\n/s, "plan present";

note "SUBTEST";
my $smoke_subtest = run_cmd( "subcontract inner => sub { refute reason => q{fail} for 1..2 }; done_testing;" );
like $smoke_subtest, qr/\nnot ok 1 - inner/, "subtest failed";
like $smoke_subtest, qr/\n +not ok 2/, "Inner test there";
like $smoke_subtest, qr/\n +# reason/, "Fail reason present";

note "NOTE";
my $smoke_note = run_cmd( "current_contract->note(q{it works}); done_testing" );
like $smoke_note, qr/^# it works/, "Note works";

note "SUBTEST CONTENT\n$smoke_subtest/SUBTEST CONTENT";

my $getters = run_cmd( <<'PERL' );
    ok 1;
    note q{pre_pass=}.current_contract->is_passing;
    ok 0;
    current_contract->refute( q{foo bared}, q{fail} );
    current_contract->refute( 0, q{pass} );

    note q{#########};
    note q{count=}.current_contract->get_count;
    note q{post_pass=}.current_contract->is_passing;
    note q{res2=}.current_contract->get_result(2);
    note q{res3=}.current_contract->get_result(3);
    done_testing;
PERL

like $getters, qr/# count=4\n/s, "Count";
like $getters, qr/# pre_pass=1\n/s, "is_passing (pre)";
like $getters, qr/# post_pass=(0|)\n/s, "is_passing (post)";
like $getters, qr/# res2=1\n/s, "unknown reason";
like $getters, qr/# res3=foo bared\n/s, "known reason";

done_testing;
