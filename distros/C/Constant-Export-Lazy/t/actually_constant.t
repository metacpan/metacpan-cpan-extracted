package TestConstant;
use strict;
use warnings;
use Constant::Export::Lazy (
    constants => {
        TRUE   => sub { 1 },
        FALSE  => sub { 0 },
        ARRAY  => sub { [qw/sub what/] },
        HASH   => sub {
            +{
                fmt => "The <%s> constant is CONST according to (B::svref_2object(SUB)->CvFLAGS[%d] & CVf_CONST[%d]) == CVf_CONST[%d]",
                out => "We shouldn't even have this in the syntax tree on -MO=Deparse",
            },
        },
    }
);

package main;
BEGIN {
    TestConstant->import(qw(
        TRUE
        FALSE
        ARRAY
        HASH
    ));
}
use Test::More tests => 4;
use B qw(svref_2object CVf_CONST);

my @tests = (
    {
        what => 'TRUE',
        sub  => \&TRUE,
    },
    {
        what => 'FALSE',
        sub  => \&FALSE,
    },
    {
        what => 'ARRAY',
        sub  => \&ARRAY,
    },
    {
        what => 'HASH',
        sub  => \&HASH,
    },
);

if (TRUE) {
    for my $test (@tests) {
        my ($sub, $what) = @$test{@{ARRAY;}};
        my $CvFLAGS = svref_2object($test->{sub})->CvFLAGS;
        my $CvFLAGS_and_CVf_CONST = $CvFLAGS & CVf_CONST;
        my $CVf_CONST = CVf_CONST;
        is($CvFLAGS_and_CVf_CONST, $CVf_CONST, sprintf HASH->{fmt}, $what, $CvFLAGS, $CvFLAGS_and_CVf_CONST, $CVf_CONST);
    }
} else {
    fail(HASH->{out});
}
