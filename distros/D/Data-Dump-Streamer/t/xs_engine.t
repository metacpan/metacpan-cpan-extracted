use 5.018;
use strict;
use warnings;
use Test::More;
use Scalar::Util         qw(refaddr isweak weaken);
use Data::Dump::Streamer qw(:undump Dump);

sub rebuild {
    my $value;
    my $code= Dump($_[0])->Names('value')->Out;
    my $copy= eval $code . '$value';
    die "Cannot evaluate DDS output: $@\n$code" if $@;
    return $copy;
}

my $tree= [ map { [ 1, 2, 3 ] } 1 .. 100 ];
my $dumper= Dump($tree);
my $code= $dumper->Names('value')->Out;
my $stats= $dumper->_xs_stats;
is_deeply(rebuild($tree), $tree, 'ordinary tree round trip');
cmp_ok($stats->{candidates}, '<', 10, 'ordinary tree has a sparse catalogue');
cmp_ok($stats->{lookups},    '<', 20, 'ordinary leaves avoid identity lookups');

{
    my $shared= [];
    my $copy= rebuild([ $shared, $shared ]);
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        'distinct RV slots retain a shared referent'
    );
    push @{ $copy->[0] }, 'shared';
    is($copy->[1][0], 'shared', 'referent mutation is shared');
    $copy->[0]= [];
    is($copy->[1][0], 'shared', 'the RV slots themselves remain independent');
}

{
    my @values= ('same', 'same', 'different');
    alias_av(@values, 2, $values[0]);
    my $copy= rebuild(\@values);
    is(
        refaddr(\$copy->[0]),
        refaddr(\$copy->[2]),
        'scalar aliases retain slot identity'
    );
    isnt(
        refaddr(\$copy->[0]),
        refaddr(\$copy->[1]),
        'equal values do not become aliases'
    );
    $copy->[2]= 'changed';
    is($copy->[0], 'changed', 'assignment through an alias changes its source');
    is($copy->[1], 'same',    'equal independent slot is unchanged');
}

{
    my @values= ('value');
    push @values, \$values[0];
    my $copy= rebuild(\@values);
    is(
        refaddr($copy->[1]),
        refaddr(\$copy->[0]),
        'reference to an array slot retains identity'
    );
    ${ $copy->[1] }= 'changed';
    is($copy->[0], 'changed', 'reference to a slot permits assignment');
}

{
    my $root= [];
    push @$root, $root;
    my $copy= rebuild($root);
    is(refaddr($copy), refaddr($copy->[0]), 'self cycle');
    pop @$copy;
    pop @$root;
}

{
    my $left= [];
    my $right= { left => $left };
    push @$left, $right;
    my $copy= rebuild($left);
    is(refaddr($copy), refaddr($copy->[0]{left}),
        'mutual array and hash cycle');
    delete $copy->[0]{left};
    delete $right->{left};
}

for my $weak_first (0, 1) {
    my $root= [ { data => 1 } ];
    push @$root, $root->[0];
    weaken($root->[ $weak_first ? 0 : 1 ]);
    my $copy= rebuild($root);
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        "weak/strong referent identity, weak first=$weak_first"
    );
    ok(isweak($copy->[ $weak_first  ? 0 : 1 ]), 'weak flag survives');
    ok(!isweak($copy->[ $weak_first ? 1 : 0 ]), 'strong flag survives');
}

{
    my $root= [1];
    my $copy= rebuild([$root]);
    is_deeply($copy, [ [1] ], 'external ownership does not invent sharing');
}

{
    my $value= [1];
    my $d= Dump($value)->Names('value');
    $value= [2];
    my $first= $d->Out;
    is(
        $first,
        "\$value = [ 2 ];\n",
        'delayed capture retains the caller scalar'
    );
    is(scalar($d->Out), $first,
        'repeated output starts fresh construction state');
}

{
    my $value= [1];
    my $d= Dump()->Names('value')->Data($value);
    push @$value, 2;
    my $copy= eval $d->Out . '$value';
    is_deeply(
        $copy,
        [ 1, 2 ],
        'live descendant changes are visible between Data and Out'
    );
}

{
    my $d= Dump()->Names('value');
    my $value= [ 1, { x => "a\0b" } ];
    my @chunks= $d->Data($value)->Out;
    my $string= $d->Data($value)->Out;
    is(join('', @chunks), $string, 'list output concatenates to scalar output');
    is(scalar(Dump()->Out), '',    'an empty dumper has empty output');
}

{
    my $value= [ 0, [] ];
    push @$value, $value->[1];
    my $weak= $value->[1];
    weaken($weak);
    my $d= Dump()->Names('value')->Data($value);
    splice @$value, 1;
    ok(!defined($weak), 'catalogue does not retain removed referents strongly');
    my $copy= eval $d->Out . '$value';
    is($@, '',
        'output after removing catalogued values does not dereference their addresses'
    );
    is_deeply($copy, [0], 'remaining live values are emitted after removal');
    my @replacements= map { [] } 1 .. 100;
    @$value= ($replacements[-1], $replacements[-1]);
    $copy= eval $d->Data($value)->Out . '$value';
    is($@, '', 'replacement graph evaluates after explicit reanalysis');
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        'reanalysis records replacement sharing'
    );
}

{
    my $value= [1];
    my $d= Dump()->Names('value')->Data($value);
    $value= { changed => 1 };
    my $copy= eval $d->Out . '$value';
    is($@, '', 'a replaced root is reanalyzed');
    is_deeply($copy, { changed => 1 }, 'new root contents survive');
}

{
    my $d= Dump()->Names('value');
    $d->SortKeys(sub { die "sorter failed\n" });
    my $ok= eval { $d->Data({ a => 1 }); 1 };
    ok(!$ok, 'sorter failure propagates');
    like($@, qr/sorter failed/, 'sorter error survives cleanup');
    $d->SortKeys('smart');
    is(
        scalar($d->Data([1])->Out),
        "\$value = [ 1 ];\n",
        'object is reusable after failed analysis'
    );
}

{

    package DDSFailingPrinter;
    sub new   { bless {}, shift }
    sub print { die "printer failed\n" }

    package main;
    my $d= Dump()->Names('value')->To(DDSFailingPrinter->new);
    my $ok= eval { $d->Data([1])->Out; 1 };
    ok(!$ok, 'printer failure propagates');
    like($@, qr/printer failed/, 'printer error survives cleanup');
    $d->To(undef);
    is(
        scalar($d->Data([2])->Out),
        "\$value = [ 2 ];\n",
        'object is reusable after failed emission'
    );
}

{
    my $d= Dump()->Names('value');
    my $nested;
    $d->Freezer(
        'DDSReentrant',
        sub {
            $nested= $d->Data([7])->Out;
            return { data => 3 };
        });
    my $input= bless [], 'DDSReentrant';
    my $outer= $d->Data($input)->Out;
    is(
        $nested,
        "\$value = [ 7 ];\n",
        'callback can use the same dumper recursively'
    );
    is(
        $outer,
        "\$value = { data => 3 };\n",
        'outer working state survives recursive use'
    );
    my $twice= $d->Data([ $input, $input ])->Out;
    my $value;
    my $copy= eval $twice . '$value';
    is($@, '', 'shared freezer replacement output evaluates');
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        'shared replacement without thaw retains identity'
    );
    $d->Freezer(
        'DDSReentrant',
        sub {
            $nested= $d->Dump([8])->Out;
            return { data => 4 };
        });
    $outer= $d->Data($input)->Out;
    is(
        $nested,
        "\$value = [ 8 ];\n",
        'delayed Dump can recursively capture on the same dumper'
    );
    is(
        $outer,
        "\$value = { data => 4 };\n",
        'outer state survives recursive delayed capture'
    );
}

{
    my $copy= rebuild([ dualvar(1, 'same'), dualvar(2, 'same') ]);
    is(0 + $copy->[0], 1, 'RLE preserves the first numeric dualvar value');
    is(0 + $copy->[1], 2, 'RLE preserves a different numeric dualvar value');
    $copy= rebuild([
        Scalar::Util::dualvar(~0,       'same'),
        Scalar::Util::dualvar((~0) - 1, 'same'),
        'same'
    ]);
    is(0 + $copy->[0], ~0, 'unsigned dualvars retain every integer bit');
    is(
        0 + $copy->[1],
        (~0) - 1,
        'RLE distinguishes adjacent large unsigned values'
    );
    is($copy->[2], 'same', 'a plain string remains a plain string');
}

{
    my $text= Dump([ 'x' x 1100, 1 ])->Indent(0)->Rle(0)->Out;
    like($text, qr/,\n1\];\n\z/,
        'compact arrays retain the legacy long-line break');
    $text= Dump([ 'x' x 1100, 1 ])->Indent(0)->Rle(1)->Out;
    like($text, qr/,1\];\n\z/,
        'RLE layout retains its existing compact behavior');
    $text= Dump({ a => 'x' x 1100, b => 1 })->Indent(0)->Out;
    like($text, qr/,\nb=>1\};\n\z/,
        'compact hashes retain the legacy long-line break');
}

{

    package DDSNamedSorter;
    sub reverse_keys { [ reverse sort keys %{ $_[0] } ] }

    package main;
    my $value= bless { a => 1, b => 2 }, 'DDSNamedSorter';
    my $text=
        Dump()->KeyOrder('DDSNamedSorter', 'reverse_keys')->Data($value)->Out;
    like(
        $text,
        qr/b => 2,\s+a => 1/,
        'named class sorter runs through the callback path'
    );
    my @keys= ("\x{100}", "\x{101}", "\x{c0}", "\x{e0}", 'A', 'a');
    my $hash= { map { $_ => 1 } @keys };
    my $native= Dump()->SortKeys('smart')->Data($hash)->Out;
    my $perl= Dump()->SortKeys(
        sub {
            [ sort { lc($a) cmp lc($b) || $a cmp $b } keys %{ $_[0] } ]
        })->Data($hash)->Out;
    is($native, $perl, 'native smart sorting preserves Unicode case handling');
}

{

    package DDSMutatingPrinter;

    sub print {
        my $self= shift;
        $self->{text} .= join('', @_);
        if (!$self->{changed}++ && $self->{mutate}) { $self->{mutate}->() }
    }

    package main;
    my $value= [ [1], { a => 2 } ];
    my $printer= bless { mutate => sub { @$value= () } }, 'DDSMutatingPrinter';
    my $d= Dump()->Names('value')->Data($value)->To($printer);
    my $ok= eval { $d->Out; 1 };
    ok($ok, 'printer may remove descendants while emission is active')
        or diag $@;
    like($printer->{text}, qr/\$value =/,
        'mutating printer receives the output');
}

{

    package DDSTiedScalar;
    sub TIESCALAR { bless { value => $_[1] }, $_[0] }
    sub FETCH     { $_[0]{value} }

    package main;
    my $shared= [];
    tie my $scalar, 'DDSTiedScalar', $shared;
    my @values= (undef, $shared);
    alias_av(@values, 0, $scalar);
    my $copy= rebuild(\@values);
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        'tied scalar FETCH retains shared referents'
    );
}

{

    package DDSPostdumpOriginal;
    our ($seen, $calls);
    sub restore { $seen= shift; $calls++ }

    package main;
    for my $method (0, 1) {
        $DDSPostdumpOriginal::seen= undef;
        $DDSPostdumpOriginal::calls= 0;
        my $input= bless { original => 1 }, 'DDSPostdumpOriginal';
        my $action= $method ? 'restore' : sub {
            $DDSPostdumpOriginal::seen= shift;
            $DDSPostdumpOriginal::calls++;
        };
        my $d= Dump()->Names('value')->Freezer(
            'DDSPostdumpOriginal',
            sub {
                return ([1], undef, $action);
            });
        my $text;
        my $ok= eval { $text= $d->Data([ $input, $input ])->Out; 1 };
        ok($ok, "postdump hook completes, method=$method") or diag $@;
        is(refaddr($DDSPostdumpOriginal::seen),
            refaddr($input), 'postdump receives the original object');
        is($DDSPostdumpOriginal::calls, 1,
            'shared objects invoke postdump once');
        if ($ok) {
            my $value;
            my $copy= eval $text . '$value';
            is($@, '', 'postdump output evaluates');
            is(
                refaddr($copy->[0]),
                refaddr($copy->[1]),
                'postdump preserves shared proxy identity'
            );
        }
        $DDSPostdumpOriginal::seen= undef;
    }
}

{
    my $deep= 1;
    $deep= [$deep] for 1 .. 1200;
    my $text= Dump($deep)->Indent(0)->Rle(0)->Terse(1)->Out;
    like($text, qr/^\[.*1.*\];\n\z/s, 'deep graphs use heap emission frames');

    # Release the chain iteratively too: Perl destruction can itself recurse.
    while (ref($deep)) { $deep= pop @$deep }
}

{
    require Tie::Array;
    require Tie::Hash;
    tie my @array, 'Tie::StdArray';
    tie my %hash,  'Tie::StdHash';
    my $shared= [];
    @array= (1, $shared, $shared);
    %hash= (a => $shared, b => $shared);
    my $copy= rebuild([ \@array, \%hash ]);
    is_deeply(
        $copy,
        [ [ 1, [], [] ], { a => [], b => [] } ],
        'tied containers emit their fetched values'
    );
    is(
        refaddr($copy->[0][1]),
        refaddr($copy->[0][2]),
        'tied array sharing survives'
    );
    is(
        refaddr($copy->[0][1]),
        refaddr($copy->[1]{a}),
        'sharing crosses tied array and hash'
    );
    is(
        refaddr($copy->[1]{a}),
        refaddr($copy->[1]{b}),
        'tied hash sharing survives'
    );
}

{
    my $d= Dump([1])->Names('value')->Data;
    my $buffer= '';
    open my $handle, '>', \$buffer or die $!;
    $d->diag($handle);
    like($buffer, qr/=> \$value/,
        'diagnostics project the native candidate catalogue');
}

{

    package DDSReplacingDestructor;
    our ($dumper, $nested);
    sub DESTROY { $nested= $dumper->Data([9])->Out if $dumper }

    package main;
    my $d= Dump()->Names('value')->Data(bless [], 'DDSReplacingDestructor');
    $DDSReplacingDestructor::dumper= $d;
    my $outer= $d->Data([10])->Out;
    is(
        $DDSReplacingDestructor::nested,
        "\$value = [ 9 ];\n",
        'released input destructor can use the dumper recursively'
    );
    is(
        $outer,
        "\$value = [ 10 ];\n",
        'new input is retained before releasing old roots'
    );
    undef $DDSReplacingDestructor::dumper;
}

{

    package DDSGlobFailingPrinter;
    sub print { shift; die "glob printer failed\n" if $_[0] =~ /^\*/ }

    package main;
    require Symbol;
    my $glob= Symbol::gensym();
    ${*$glob}= 'glob value';
    my $d= Dump()->Names('value')->DumpGlob(1)
        ->To(bless {}, 'DDSGlobFailingPrinter');
    my $ok= eval { $d->Data($glob)->Out; 1 };
    ok(!$ok, 'printer can fail during deferred glob emission');
    like($@, qr/glob printer failed/, 'glob callback error survives cleanup');
    $d->To(undef);
    is(
        scalar($d->Data([3])->Out),
        "\$value = [ 3 ];\n",
        'object is reusable after a glob callback failure'
    );
}

{
    no warnings 'once';
    local @DB::argsfoo= (17, 23);
    my $text= Dump(\*DB::argsfoo)->Names('value')->Out;
    @DB::argsfoo= ();
    my $value;
    my $copy= eval $text . '$value';
    is($@, '', 'glob sharing the DB::args prefix evaluates');
    is_deeply(
        *{$copy}{ARRAY},
        [ 17, 23 ],
        'DB::argsfoo contents are analyzed and reconstructed'
    );
}

{
    my @retained;
    for my $depth (100, 200) {
        my $input= [];
        $input= { k => 1, n => [$input] } for 1 .. $depth;
        my $d= Dump()->Indent(0)->SortKeys(sub { [ sort keys %{ $_[0] } ] });
        my $text= $d->Data($input)->Out;
        push @retained, $d->_xs_stats->{keepalive};
        while (ref($input) eq 'HASH') {
            my $next= $input->{n}[0];
            delete $input->{n};
            $input= $next;
        }
    }
    cmp_ok(
        $retained[1], '<',
        3 * $retained[0],
        'callback keepalives grow linearly with nesting'
    );
    cmp_ok($retained[1], '<', 40 * 200,
        'unchanged ancestors do not accumulate duplicate keepalives');
}

SKIP: {
    require Config;
    skip 'Perl was built without ithreads', 2
        unless $Config::Config{useithreads};
    require threads;
    my $d= Dump([1]);
    my $thread= threads->create(
        sub {
            return [
                !!Scalar::Util::blessed($d),
                scalar Dump([2])->Names('value')->Out
            ];
        });
    my $result= $thread->join;
    ok(!$result->[0], 'a parent dumper is excluded from interpreter cloning');
    is(
        $result->[1],
        "\$value = [ 2 ];\n",
        'a child interpreter can create its own dumper'
    );
}

done_testing;
