use strict;
use warnings;

use Algorithm::Diff::JSON 'json_diff' => { -as => 'jsondiff' };
use Cpanel::JSON::XS qw(decode_json);

use Test::Differences;
use Test::More;

eq_or_diff(
    decode_json(jsondiff(
        file_to_list('t/algorithm-diff-json-base'),
        file_to_list('t/algorithm-diff-json-additions'),
    )),
    [
        { element => 0,  add => 'aardvark' },
        { element => 5,  add => 'earwig'   },
        { element => 11, add => 'isopod'   },
    ],
    "Additions reported correctly"
);
eq_or_diff(
    decode_json(jsondiff(
        file_to_list('t/algorithm-diff-json-base'),
        file_to_list('t/algorithm-diff-json-removals'),
    )),
    [
        { element => 0, remove => 'ant'      },
        { element => 4, remove => 'elephant' },
        { element => 8, remove => 'impala'   },
    ],
    "Removals reported correctly"
);
eq_or_diff(
    decode_json(jsondiff(
        file_to_list('t/algorithm-diff-json-base'),
        file_to_list('t/algorithm-diff-json-changes'),
    )),
    [
        { element => 0, change => { remove => 'ant',      add => 'aardvark' } },
        { element => 4, change => { remove => 'elephant', add => 'earwig'   } },
        { element => 8, change => { remove => 'impala',   add => 'isopod'   } },
    ],
    "Changes reported correctly"
);
eq_or_diff(
    decode_json(jsondiff(
        file_to_list('t/algorithm-diff-json-base-big'),
        file_to_list('t/algorithm-diff-json-all_changes-big'),
    )),
    [
        { element => 3,  remove => 'four' },
        { element => 33, add    => 'i added this' },
        { element => 59, change => { add => 'changed', remove => 'sixty' } },
        { element => 60, change => { add => 'also changed', remove => 'sixtyone' } },
        { element => 61, change => { add => 'also also changed', remove => 'sixtytwo' } },
        { element => 62, add    => 'added' },
    ],
    "Bigger changes reported correctly"
);

sub file_to_list {
    my $fn = shift;
    open(my $fh, '<', $fn) || die("Can't open $fn: $!\n");
    [map { s/^\s+|\s+$//g; $_ } <$fh>];
}

done_testing();
