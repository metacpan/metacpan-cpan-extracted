#/usr/bin/env perl

use common::sense;
use warnings FATAL => q(all);
use English qw[-no_match_vars];
use Test::More;

my $class = q(App::BoolFindGrep::Grep);
use_ok($class) || say q(Bail out!);

my @test = (
    [   q{.*},
        [   { fixed_strings => qr{\.\*} },
            { line_regexp   => qr{\A.*\z} },
            { word_regexp   => qr{\b.*\b} },
            { ignore_case   => qr{.*}i },
            { glob_regexp   => qr{\.[^/]*} },
        ],
    ],
);

my $method = q(_process_patterns);

foreach my $test (@test) {
    my ( $input, $aoh ) = @$test;
    foreach my $hash (@$aoh) {
        my ( $attr, $value );
        foreach my $key ( keys %$hash ) {
            $attr  = $key;
            $value = $hash->{$key};
        }
        my $expected = { $input => $value };
        my $testname = sprintf q(%s+%s:'%s'), $method, $attr, $input;
        my $obj = $class->new();
        $obj->$attr(1);
        $obj->patterns( { $input => undef } );
        $obj->$method();
        my $output = $obj->patterns();
        is_deeply( $output, $expected, $testname );
    } ## end foreach my $hash (@$aoh)
} ## end foreach my $test (@test)

@test = (
    [   q(A regular expression is a pattern that describes a set of strings.),
        {   q{e}        => qr{e},
            q{regular}  => qr{\bregular\b},
            q{string}   => qr{\bstring\b}i,
            q{strings.} => qr{strings\.}i,
            q{\bre}     => qr{\bre}i,
            q{is\s*a}   => qr{\bis\s*a\b},
        },
        {   q{e}        => 1,
            q{regular}  => 1,
            q{string}   => 0,
            q{strings.} => 1,
            q{\bre}     => 1,
            q{is\s*a}   => 1,
        },
    ],
);

$method = q(_search);
foreach my $test (@test) {
    my ( $input, $patterns, $expected ) = @$test;
    my $testname = sprintf q(%s:'%s'), $method, $input;
    my $obj = $class->new();
    $obj->patterns($patterns);
    $obj->$method( $input, q(STDIN), 0 );
    my %output = %{ $obj->greped() };
    my $output;
    foreach my $key ( keys %output ) {
        $output = $output{$key};
    }
    is_deeply( $output, $expected, $testname );
}

done_testing();

# Local Variables:
# mode: perl
# coding: utf-8-unix
# End:
