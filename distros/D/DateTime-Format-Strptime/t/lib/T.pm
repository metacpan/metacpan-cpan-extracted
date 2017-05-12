package    # hide from PAUSE
    T;

use strict;
use warnings;

use Test::Builder;
use Test::More 0.96;
use Test::Fatal;

use DateTime::Format::Strptime;

use Exporter qw( import );

our @EXPORT_OK = qw( run_tests_from_data test_datetime_object utf8_output );

sub run_tests_from_data {
    my $fh = shift;

    for my $test ( _tests_from_fh($fh) ) {
        subtest(
            qq{$test->{name}},
            sub {
                utf8_output();

                my $parser;
                is(
                    exception {
                        $parser = DateTime::Format::Strptime->new(
                            pattern => $test->{pattern},
                            (
                                $test->{locale}
                                ? ( locale => $test->{locale} )
                                : ()
                            ),
                            strict   => $test->{strict},
                            on_error => 'croak',
                        );
                    },
                    undef,
                    "no exception building parser for $test->{pattern}"
                ) or return;

                # Thursday changed from "Thu" to "Thu." and December went from
                # "Dec" to "Dec." between CLDR versions.
                $test->{input}
                    =~ s/AU_THU/DateTime::Locale->load('en-AU')->day_format_abbreviated->[3]/e;
                $test->{input}
                    =~ s/AU_DEC/DateTime::Locale->load('en-AU')->month_format_abbreviated->[11]/e;

                ( my $real_input = $test->{input} ) =~ s/\\n/\n/g;

                my $dt;
                is(
                    exception { $dt = $parser->parse_datetime($real_input) },
                    undef,
                    "no exception parsing $test->{input}"
                ) or return;

                test_datetime_object( $dt, $test->{expect} );

                unless ( $test->{skip_round_trip} ) {
                    is(
                        $parser->format_datetime($dt),
                        $real_input,
                        'round trip via strftime produces original input'
                    );
                }
            }
        );
    }
}

sub utf8_output {
    binmode $_, ':encoding(UTF-8)'
        or die $!
        for map { Test::Builder->new->$_ }
        qw( output failure_output todo_output );
}

sub test_datetime_object {
    my $dt     = shift;
    my $expect = shift;

    for my $meth ( sort keys %{$expect} ) {
        is(
            $dt->$meth,
            $expect->{$meth},
            "$meth is $expect->{$meth}"
        );
    }
}

sub _tests_from_fh {
    my $fh = shift;

    my @tests;

    my $d = do { local $/ = undef; <$fh> };

    my $test_re = qr/
        \[(.+?)\]\n              # test name
        (.+?)\n                  # pattern
        (.+?)\n                  # input
        (?:locale\ =\ (.+?)\n)?  # optional locale
        (skip\ round\ trip\n)?   # skip a round trip?
        (strict\n)?              # strict parsing flag?
        (.+?)\n                  # k-v pairs for expected values
        (?:\n|\z)                # end of test
                    /xs;

    while ( $d =~ /$test_re/g ) {
        push @tests, {
            name            => $1,
            pattern         => $2,
            input           => $3,
            locale          => $4,
            skip_round_trip => $5,
            strict          => ( $6 ? 1 : 0 ),
            expect          => {
                map { split /\s+=>\s+/ } split /\n/, $7,
            },
        };
    }

    return @tests;
}

1;
