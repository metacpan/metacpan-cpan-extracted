use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Data::NestedParams;

use Data::Dumper;

filters {
    input => [qw(eval)],
    expected => [qw(eval)],
};

sub ddf {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper(@_);
}

for (blocks) {
    my $input = $_->input;
    my $expected = $_->expected;

    diag "--- Testing --- ";
    diag "--- input: " . ddf($input);
    diag "--- expected: " . ddf($expected);
    my $got = expand_nested_params($input);
    diag "--- got: " . ddf($got);
    is_deeply( $got, $expected );
}

done_testing;

__DATA__

===
--- input
+[
    'a' => 'x',
],
--- expected
+{
    'a' => 'x',
}

===
--- input
+[
    'foo' => 'bar',
    'foo' => 'quux',
],
--- expected
+{
    'foo' => 'quux',
}


===
--- input
+[
    'a[]' => 'x',
    'a[]' => 'y',
],
--- expected
+{
    'a' => [qw(x y)],
}

===
--- input
+[
    'a[foo]' => 'x',
],
--- expected
+{
    'a' => {
        foo => 'x',
    }
}

===
--- input
+[
    'a[foo][bar]' => 'x',
],
--- expected
+{
    'a' => {
        foo => {
            bar => 'x',
        }
    }
}

===
--- input
+[
    'a[foo][bar][]' => 'x',
],
--- expected
+{
    'a' => {
        foo => {
            bar => ['x'],
        }
    }
}

===
--- input
+[
    'a[fo-o]' => 'x',
    'a[ba_r]' => 'x',
],
--- expected
+{
    'a' => {
        'fo-o' => 'x',
        'ba_r' => 'x'
    }
}

===
--- input
+[
    'a[]' => 'J',
    'a[]' => 'T',
    'a[]' => 'K',
],
--- expected
+{
    'a' => ['J', 'T', 'K']
}

===
--- input
[
    'r[p1]' => 'a',
    'r[p2]' => 'c'
]
--- expected
{
    'r' => {
        p1 => 'a',
        p2 => 'c',
    }
}
