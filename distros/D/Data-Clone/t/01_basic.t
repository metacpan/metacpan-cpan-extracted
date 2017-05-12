#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;
use Data::Dumper;

use Data::Clone;

use Tie::Hash;
use Tie::Array;

$Data::Dumper::Indent   = 0;
$Data::Dumper::Sortkeys = 1;

ok defined(&clone), 'clone() is exported by default';
ok!defined(&data_clone), 'data_clone() is not exported by default';

for(1 .. 2){ # do it twice to test internal data

    foreach my $data(
        "foo",
        3.14,
        1 != 1,
        *STDOUT,
        ["foo", "bar", undef, 42],
        [qr/foo/, qr/bar/],
        [\*STDOUT, \*STDOUT],
        { key => [ 'value', \&ok ] },
        { foo => { bar => { baz => 42 } } },
    ){
        note("for $data");
        is Dumper(clone($data)),  Dumper($data),  'data';
        is Dumper(clone(\$data)), Dumper(\$data), 'data ref';
    }


    my $s;
    $s = \$s;
    is Dumper(clone(\$s)), Dumper(\$s), 'ref to self (scalar)';

    my @a;
    @a = \@a;
    is Dumper(clone(\@a)), Dumper(\@a), 'ref to self (array)';

    my %h;
    $h{foo} = \%h;
    is Dumper(clone(\%h)), Dumper(\%h), 'ref to self (hash)';

    @a = ('foo', 'bar', \%h, \%h);
    is Dumper(clone(\@a)), Dumper(\@a), 'ref to duplicated refs';

    # correctly cloned?

    $s = 99;
    %h = (foo => 10, bar => 10, baz => [10], qux => \$s);

    my $cloned = clone(\%h);
    $cloned->{foo}++;
    $cloned->{baz}[0]++;

    cmp_ok $cloned, '!=', \%h, 'different entity';

    is Dumper($cloned), Dumper({foo => 11, bar => 10, baz => [11], qux => \$s}),
        'deeply copied';

    is Dumper(\%h), Dumper({foo => 10, bar => 10, baz => [10], qux => \$s}),
        'the original is not touched';

    $s++;

    is ${$h{qux}},        100;
    is ${$cloned->{qux}}, 100, 'scalar ref is not copied deeply';
}

done_testing;
