#!perl -Tw
use strict;

use Data::Format::Pretty::JSON qw(format_pretty);
use Test::More 0.98;

test_format_pretty(
    name => 'default',
    data => {a=>1, b=>2},
    opts => {},
    output_re => qr/a.*:.*1/,
);

test_format_pretty(
    name => 'opt: pretty=0',
    data => {a=>1, b=>2},
    opts => {pretty=>0},
    output_re => qr/a.*:.*1/,
);

done_testing();

sub test_format_pretty {
    my %args = @_;
    my $data   = $args{data};
    my $opts   = $args{opts} // {};

    subtest $args{name} => sub {
        my $output = format_pretty($data, $opts);
        if ($args{output}) {
            is($output, $args{output}, "output (exact match)")
                or diag $output;
        }
        if ($args{output_re}) {
            like($output, $args{output_re}, "output (re match)")
                or diag $output;
        }
    };
}
