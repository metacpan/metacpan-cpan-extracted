package t::AppYGParserTest;
use strict;
use warnings;
use Test::More;
use Test::Warn;
use parent qw/Exporter/;
our @EXPORT_OK = qw/
    can_parse
    parse_fail
/;

sub can_parse {
    my ($class, $log, $expected_list) = @_;

    note($log);
    my $parsed;
    {
        no strict 'refs';
        $parsed = &{ "${class}::parse" }($log);
    }
    is ref($parsed), 'ARRAY', 'type of value';
    is scalar(@{$parsed}), scalar(@{$expected_list}), 'count elements';
    for my $i ( 0 .. scalar(@{$parsed}) - 1 ) {
        is $parsed->[$i], $expected_list->[$i], "element: $i";
    }

    return $parsed;
}

sub parse_fail {
    my ($class, $log) = @_;

    note($log);
    my $parsed;
    warning_like {
        no strict 'refs';
        $parsed = &{ "${class}::parse" }($log);
    } qr/failed to parse line:/,
    "warn: failed to parse";
    is ref($parsed), 'ARRAY', 'type of value';
    for my $i ( 0 .. scalar(@{$parsed}) - 1 ) {
        is $parsed->[$i], '', "element is blank: $i";
    }

    return $parsed;
}

1;
