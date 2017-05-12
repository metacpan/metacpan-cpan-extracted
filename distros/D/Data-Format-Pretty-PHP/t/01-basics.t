#!perl -Tw
use strict;

use Data::Format::Pretty::PHP qw(format_pretty);
use Test::More;

test_format_pretty(
    name => 'default',
    data => {a=>1, b=>2},
    opts => {},
    output_re => qr/array.+"a"\s*=>\s*1/,
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
