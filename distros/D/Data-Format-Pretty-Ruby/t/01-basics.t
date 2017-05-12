#!perl -Tw
use strict;

use Data::Format::Pretty::Ruby qw(format_pretty);
use Test::More 0.98;

test_format_pretty(
    name => 'default',
    data => {a=>1, b=>2},
    opts => {},
    output => q({ "a" => 1, "b" => 2 }),
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
