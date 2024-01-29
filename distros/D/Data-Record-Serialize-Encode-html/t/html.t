#! perl

use Test2::V0;

use Data::Record::Serialize;

my $enc = Data::Record::Serialize->new(
    encode      => 'html',
    sink        => 'array',
    table_class => 'table',
    th_class    => 'th',
    td_class    => 'td',
    tr_class    => 'tr',
    thead_class => 'thead',
    tbody_class => 'tbody',
    fields      => [ 'a', 'c' ],    # so output order is deterministic
);

$enc->send( { a => 'b', c => 'd' } );
$enc->close;

is(
    $enc->output,
    [
        qq{<table class="table">},
        qq{<thead><tr class="tr"><th class="th">a</th><th class="th">c</th></tr>\n</thead>},
        qq{<tbody>},
        qq{<tr><td class="td">b</td><td class="td">d</td></tr>\n},
        qq{</tbody>},
        qq{</table>},
    ] );
done_testing;
