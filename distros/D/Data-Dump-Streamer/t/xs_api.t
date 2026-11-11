use 5.018;
use strict;
use warnings;
use Test::More;
use B                    ();
use Scalar::Util         qw(refaddr);
use Data::Dump::Streamer qw(Dump DumpVars DumpLex Dumper :undump);

for my $method (
    qw(new Dump DumpVars DumpLex Dumper Data Out Names Indent
    Rle SortKeys KeyOrder Freezer ResetFreezer Ignore To
    DeparseOpts Declare Purity)
) {
    my $cv= Data::Dump::Streamer->can($method);
    ok(
        $cv && B::svref_2object($cv)->XSUB,
        "$method has a native implementation"
    );
}

{

    package DDSApiSubclass;
    our @ISA= ('Data::Dump::Streamer');

    sub new {
        my $self= shift->SUPER::new;
        $self->{constructed}= 1;
        return $self;
    }

    package main;
    my $d= DDSApiSubclass->Indent(1);
    isa_ok($d, 'DDSApiSubclass');
    ok($d->{constructed},
        'class-call options respect the subclass constructor');
    is($d->Indent,   1,   'native option getter');
    is($d->OptSpace, ' ', 'default optional space');
    $d->OptSpace('  ')->Indent(0);
    is($d->OptSpace, '', 'compact indentation saves optional space');
    $d->Indent(2);
    is($d->OptSpace, '  ', 'restoring indentation restores optional space');
    $d->Names([ '@items', '$value', '%hash' ]);
    is_deeply(
        scalar $d->Names,
        [ '*items', 'value', '*hash' ],
        'Names normalizes an array argument'
    );
    my @names= $d->Names;
    is_deeply(\@names, [ '*items', 'value', '*hash' ], 'Names list context');
    $d->Names;
    is_deeply(scalar $d->Names, [], 'Names void context clears names');
    my $literal= '@items';
    $d->Names($literal);
    is($literal, '@items',
        'normalizing a name leaves its source scalar unchanged');
    my $ok= eval { $d->Names('not a name'); 1 };
    ok(!$ok, 'Names rejects an invalid name');
    $d->DeparseOpts('-sC', '-i4');
    my @opts= $d->DeparseOpts;
    is_deeply(\@opts, [ '-sC', '-i4' ],       'DeparseOpts list context');
    is_deeply(scalar $d->DeparseOpts, \@opts, 'DeparseOpts scalar context');
    $d->SortKeys('lex');
    is($d->SortKeys, 'lex', 'sorter getter retains the requested abbreviation');
    $d->SortKeys([ 'b', 'a' ]);
    my $text= $d->Names('value')->Data({ a => 1, b => 2 })->Out;
    like($text, qr/b\s+=>\s+2,\s+a\s+=>\s+1/,
        'an explicit key array replaces the built-in sorter');
    $d->Ignore('Ignored' => 1);
    ok($d->Ignore('Ignored'), 'Ignore policy getter');
    my @ignore= $d->Ignore;
    is_deeply(\@ignore, ['Ignored'], 'Ignore list getter');
    $d->Ignore('Ignored' => 0);
    ok(!$d->Ignore('Ignored'), 'Ignore policy removal');
}

{
    my ($a, $b);
    my $shared= [];
    my ($left, $right)= ($shared, $shared);
    my $text= DumpVars(a => $left, b => $right)->Out;
    eval $text;
    is($@, '', 'DumpVars output evaluates');
    is(refaddr($a), refaddr($b),
        'DumpVars preserves sharing across named roots');
    $text= DumpVars(a => $shared, b => $shared)->Out;
    my $copy= eval 'my ($a,$b);' . $text . '[$a,$b]';
    is($@, '', 'aliased root output evaluates in its construction pad');
    is(
        refaddr($copy->[0]),
        refaddr($copy->[1]),
        'DumpVars also retains aliased root identities'
    );
    my $value= [7];
    my $d= DumpLex($value);
    my @names= $d->Names;
    is_deeply(\@names, ['value'], 'native DumpLex sees the caller pad')
        if $Data::Dump::Streamer::HasPadWalker;
    like(scalar $d->Out, qr/\[ 7 \]/, 'native DumpLex output');
    like(Dumper([8]),    qr/\[ 8 \]/, 'Dumper always returns scalar output');
}

{
    my @names;
    $names[2]= 'foo';
    $names[4]= undef;
    $names[6]= '@items';
    my $d= Dump()->Names(\@names);
    is_deeply(
        scalar $d->Names,
        [ 'foo', '*items' ],
        'Names skips sparse and undefined array entries'
    );
    require Tie::Array;
    tie my @tied, 'Tie::StdArray';
    $tied[2]= '$bar';
    $tied[4]= '%hash';
    $d->Names(\@tied);
    is_deeply(
        scalar $d->Names,
        [ 'bar', '*hash' ],
        'Names fetches tied array entries'
    );
}

{

    package DDSApiTiedOption;
    sub TIESCALAR { bless { fetch => $_[1], count => 0 }, $_[0] }
    sub FETCH { my $self= shift; $self->{count}++; return $self->{fetch}->() }

    package main;
    my $d= Dump();
    my $tie= tie my $option, 'DDSApiTiedOption', sub { undef $d; return 0 };
    my $retained= $d->Indent($option);
    is($tie->{count}, 1, 'native option conversion invokes FETCH once');
    ok(!defined $d, 'option FETCH can release the caller dumper variable');
    is($retained->Indent, 0, 'option setter retains its receiver across FETCH');
}

{

    package DDSApiPrinter;

    sub print {
        my $self= shift;
        $self->{globals}= [ $\, $,, $" ];
        $self->{text} .= join('', @_);
    }

    package main;
    my $printer= bless {}, 'DDSApiPrinter';
    my @after;
    {
        local ($\, $,, $")= ('record', 'field', 'list');
        Dump()->To($printer)->Data([1])->Out;
        @after= ($\, $,, $");
    }
    is_deeply(
        $printer->{globals},
        [ '', '', '' ],
        'Out localizes print globals during callbacks'
    );
    is_deeply(
        \@after,
        [ 'record', 'field', 'list' ],
        'Out restores the caller print globals'
    );
    my $text= '';
    open my $handle, '>', \$text or die $!;
    Dump()->Names('value')->To($handle)->Data([3])->Out;
    is(
        $text,
        "\$value = [ 3 ];\n",
        'native To supports an ordinary Perl filehandle'
    );
}

for my $deleting (0, 1) {
    for my $sort ('smart', 'each') {
        my %hash= map { ("key$_", $_) } 0 .. 63;
        my (%seen, $steps);
        while (my ($key)= each %hash) {
            last if ++$steps > 128;   # Bound a regression that restarts each().
            $seen{$key}++;
            delete $hash{$key} if $deleting;
            my $text= Dump(\%hash)->SortKeys($sort)->Out;
        }
        is($steps, 64,
            "dump preserves each iterator: delete=$deleting sort=$sort");
        is(scalar keys %seen, 64, 'each visits every original key once');
    }
}

{
    my $d= Dump()->Names('value')->SortKeys(
        sub {
            return ([ sort keys %{ $_[0] } ], undef, (1) x 10000);
        });
    is(
        scalar $d->Data({ a => 1 })->Out,
        "\$value = { a => 1 };\n",
        'callback stack growth preserves native arguments and results'
    );
}

{

    package DDSApiError;
    use overload
        bool     => sub { 0 },
        '""'     => sub { 'false exception' },
        fallback => 1;

    package DDSApiFrozen;
    sub DDS_freeze { return { data => 7 } }

    package main;
    my $error= bless [], 'DDSApiError';
    my $d= Dump()->Names('value')->Freezer('DDSApiFrozen', sub { die $error });
    is(
        scalar $d->Data(bless([], 'DDSApiFrozen'))->Out,
        "\$value = { data => 7 };\n",
        'initial freezer fallback handles a false exception object'
    );
    my $calls= 0;
    $d->Freezer('DDSApiFrozen', sub { return {} if !$calls++; die $error });
    my $ok= eval {
        $d->Data([ map { bless [], 'DDSApiFrozen' } 1 .. 2 ]); 1;
    };
    my $caught= $@;
    ok(!$ok, 'cached freezer errors propagate');
    is(refaddr($caught), refaddr($error),
        'cached freezer preserves the exception object');
}

{
    no warnings 'redefine';
    my $lexical_calls= 0;
    local *Data::Dump::Streamer::_xs_lexical_names= sub {
        ++$lexical_calls;
        return [];
    };
    for my $available (0, 1) {
        local $Data::Dump::Streamer::HasPadWalker= $available;
        my $d= DumpLex([9]);
        isa_ok($d, 'Data::Dump::Streamer', 'DumpLex scalar result');
        is(
            scalar($d->Names('value')->Out),
            "\$value = [ 9 ];\n",
            'DumpLex captures values with or without lexical naming'
        );
        my @empty= DumpLex();
        is(
            scalar(@empty),
            $available ? 0 : 1,
            'empty list-context DumpLex retains its naming/fallback behavior'
        );
        isa_ok($empty[0], 'Data::Dump::Streamer',
            'fallback empty DumpLex result')
            unless $available;
    }
    is($lexical_calls, 2, 'lexical name callback is used only when available');
}

done_testing;
