#!perl -Tw
use strict;

use Data::Format::Pretty qw(format_pretty);
use Test::More;

test_format_pretty(
    name => 'default format is Console',
    data => [1, 2, 3],
    opts => {},
# since we normally run under harness, output is non-interactive
    #    output_re => qr/^\|\s*1\s*\|\n
    #                    ^\|\s*2\s*\|\n
    #                    ^\|\s*3\s*\|\n
    #                   /mx,
    output_re => qr/^1\n
                    ^2\n
                    ^3\n/mx,
);

{
    local $ENV{PLACK_ENV} = 'development';
    test_format_pretty(
        name => 'default format is HTML for CGI/PSGI apps',
        data => [1, 2, 3],
        opts => {},
        output_re => qr/<table.+<td/is,
    );
}

test_format_pretty(
    name => 'opt: module',
    data => ["a"],
    opts => {module=>'JSON'},
    output_re => qr/\[\s*"a"\s*\]/ms,
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
