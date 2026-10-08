use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# A list-returning keyword must follow the caller's context: in scalar context
# its surplus return values must not spill into the enclosing call.  The
# reference in every case below is the method form.

my $dir = tempdir(CLEANUP => 1);
my $m = Data::HashMap::Shared::SS->new("$dir/ctx.hm", 1024);
$m->put("b", "1");
$m->put("c", "2");

sub take { return scalar @_ }
sub lst  { return join '|', @_ }

is( take("x", (shm_ss_keys $m) ? "T" : "F"),
    take("x", ($m->keys)       ? "T" : "F"),
    'keyword in a boolean sub-expression passes no extra arguments' );

is( lst("x", (shm_ss_keys $m) ? "T" : "F"),
    lst("x", ($m->keys)       ? "T" : "F"),
    '  ...and the argument values match the method form' );

is( lst("pre" . (shm_ss_keys $m)),
    lst("pre" . ($m->keys)),
    'keyword in a concatenation yields one value' );

{
    my $kw = shm_ss_keys $m;
    my $mm = $m->keys;
    is( $kw, $mm, 'keyword in scalar assignment matches the method' );
}

{
    my @kw = sort(shm_ss_keys $m);
    my @mm = sort($m->keys);
    is_deeply( \@kw, \@mm, 'list context still yields every key' );
    my $n = () = shm_ss_keys $m;
    is( $n, 2, 'count idiom still sees both keys' );
}

{
    my %seen;
    while (my ($k, $v) = shm_ss_each $m) { $seen{$k} = $v }
    is_deeply( \%seen, { b => "1", c => "2" }, 'each keyword loop yields all pairs' );

    my $cur = shm_ss_cursor $m;
    my %cseen;
    while (my ($k, $v) = shm_ss_cursor_next $cur) { $cseen{$k} = $v }
    is_deeply( \%cseen, { b => "1", c => "2" }, 'cursor_next keyword loop yields all pairs' );
}

{
    ok !eval q{ 0 and shm_ss_put($m, 'x', 'y'); 1 }, 'a multi-argument keyword refuses parentheses';
    like $@, qr/^Expected ','/, '  ... when the code is compiled';
    ok !eval q{ my @r = (shm_ss_get($m, 'x'), 1); 1 },
        'a parenthesized keyword with a trailing item swallows it and dies at run time';
    like $@, qr/^Usage: Data::HashMap::Shared::SS::get\(/, '  ... with the method usage message';
    is shm_ss_size($m), (shm_ss_size $m), 'a one-argument keyword takes either form';
    {
        no Data::HashMap::Shared::SS;
        ok !eval q{ shm_ss_size $m; 1 }, 'no Data::HashMap::Shared::SS switches the keywords off';
    }
    ok eval q{ shm_ss_size $m; 1 }, '  ... for the enclosing scope only' or diag $@;

    my ($x, $y) = ('a', 'b');
    { no warnings 'void'; shm_ss_put $m, 'p', ($x) . $y; }
    is $m->get('p'), 'a', 'a last argument ($x) . $y passes only $x';
    shm_ss_put $m, 'q', +($x) . $y;
    is $m->get('q'), 'ab', '  ... and +($x) . $y passes the whole expression';
    $m->put(a => 'A');
    is scalar(shm_ss_get $m, ($x) . $y), 'Ab', '  ... in a lookup, the concatenation applies to the result';
}

done_testing;
