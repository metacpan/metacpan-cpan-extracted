use 5.018;
use strict;
use warnings;
use Test::More;
use Scalar::Util         qw(blessed refaddr);
use Symbol               ();
use Data::Dump::Streamer qw(Dump);

sub reconstruct {
    my ($hook)= @_;
    my $input= [ map { bless { which => $_ }, 'DDSFalseProxy' } 1 .. 2 ];
    my $text=
        Dump()->Names('value')->Freezer('DDSFalseProxy', $hook)->Data($input)
        ->Out;
    my $value;
    my $copy= eval $text . '$value';
    die "$@\n$text" if $@;
    return $copy;
}

for my $false ('', '0', 0) {
    my $calls= 0;
    my $copy= reconstruct(sub { $calls++; return $false });
    is($calls, 2, 'a false result retains the selected freezer');
    for my $item (@$copy) {
        like(
            $item,
            qr/^Ignored Obj \[DDSFalseProxy=HASH\(0x[0-9a-f]+\)\]$/,
            'a defined false proxy ignores the original object'
        );
    }
}

for my $empty_list (0, 1) {
    my $calls= 0;
    my $copy= reconstruct(sub { $calls++; return $empty_list ? () : undef });
    is($calls, 1, 'the first undef result disables the hook for the class');
    is(blessed($copy->[0]),
        'DDSFalseProxy', 'first undef keeps the original object');
    is(blessed($copy->[1]),
        'DDSFalseProxy', 'later objects use their original representation');
}

for my $empty_list (0, 1) {
    my $calls= 0;
    my $copy= reconstruct(
        sub {
            return [1] if !$calls++;
            return $empty_list ? () : undef;
        });
    is_deeply($copy->[0], [1], 'the initial proxy reference is serialized');
    like(
        $copy->[1],
        qr/^Ignored Obj \[/,
        'later undef or empty results ignore the object'
    );
    is($calls, 2, 'the selected hook ran for both objects');
}

{

    package DDSFalseBooleanProxy;
    use overload
        bool     => sub { die "proxy bool overload called\n" },
        fallback => 1;

    package main;
    my $copy= reconstruct(sub { return bless [1], 'DDSFalseBooleanProxy' });
    is(blessed($copy->[0]),
        'DDSFalseBooleanProxy', 'proxy references do not invoke bool overload');
    is($copy->[0][0], 1, 'overloaded proxy content survives');
}

for my $layout (qw(elements globs mixed)) {
    for my $reentrant (0, 1) {
        my $proxy= { x => 1 };
        my @originals= map { bless { which => $_ }, 'DDSSharedProxy' } 1 .. 2;
        my @globs= map     { Symbol::gensym() } 1 .. 2;
        *{ $globs[$_] }= $originals[$_] for 0 .. 1;
        my $input=
              $layout eq 'elements' ? [ @originals, @originals ]
            : $layout eq 'globs'    ? [ @globs, @globs ]
            :                         [ @globs, @originals ];
        my (%calls, @seen, @nested);
        my $d= Dump()->Names('value');
        $d->Freezer(
            'DDSSharedProxy',
            sub {
                return (
                    $proxy, undef,
                    sub {
                        my ($original)= @_;
                        $calls{ $original->{which} }++;
                        push @seen,   $original;
                        push @nested, scalar($d->Data([9])->Out) if $reentrant;
                    });
            });
        my $text= $d->Data($input)->Out;
        my $label= "shared proxy $layout reentrant=$reentrant";
        is_deeply(
            \%calls,
            { 1 => 1, 2 => 1 },
            "$label: each original gets one postdump hook"
        );
        is_deeply(
            [ sort map { refaddr($_) } @seen ],
            [ sort map { refaddr($_) } @originals ],
            "$label: hooks receive the original objects"
        );
        is_deeply(
            \@nested,
            $reentrant ? [ ("\$value = [ 9 ];\n") x 2 ] : [],
            "$label: postdump reentry preserves the outer operation"
        );
        my $value;
        my $copy= eval $text . '$value';
        is($@, '', "$label: output evaluates") or diag $text;
        my @values=
              $layout eq 'elements' ? @$copy
            : $layout eq 'globs'    ? map { *{$_}{HASH} } @$copy
            :   (*{ $copy->[0] }{HASH}, *{ $copy->[1] }{HASH}, @$copy[ 2, 3 ]);
        is_deeply($values[0], $proxy, "$label: proxy content survives");
        is_deeply(
            [ map { refaddr($_) } @values ],
            [ (refaddr($values[0])) x @values ],
            "$label: all original occurrences share one reconstructed proxy"
        );
        %calls= ();
        @seen= @nested= ();
        my $again= $d->Out;
        is_deeply(
            \%calls,
            { 1 => 1, 2 => 1 },
            "$label: repeated Out resets postdump completion"
        );
        is($again, $text, "$label: repeated output preserves reconstruction");

        # Break the intentional callback -> dumper cycle after reentry.
        $d->ResetFreezer->Data([]);
    }
}

{
    for my $glob (0, 1) {
        my $proxy= { x => 1 };
        my @originals= map { bless { which => $_ }, 'DDSSharedProxy' } 1 .. 2;
        my $first= $originals[0];
        if ($glob) {
            $first= Symbol::gensym();
            *{$first}= $originals[0];
        }
        my %calls;
        my $input= [ [$first], $originals[1] ];
        my $d= Dump()->Names('value')->Freezer(
            'DDSSharedProxy',
            sub {
                return (
                    $proxy, undef,
                    sub {
                        $calls{ $_[0]{which} }++;
                        $proxy->{x}= 99 if $_[0]{which} == 1;
                    });
            });
        my $text= $d->Data($input)->Out;
        is_deeply(
            \%calls,
            { 1 => 1, 2 => 1 },
            "deferred occurrence glob=$glob: both hooks run"
        );
        is($proxy->{x}, 99,
            "deferred occurrence glob=$glob: postdump restores source state");
        my $value;
        my $copy= eval $text . '$value';
        is($@, '', "deferred occurrence glob=$glob: output evaluates")
            or diag $text;
        is($copy->[1]{x}, 1,
            "deferred occurrence glob=$glob: proxy serialized before restoration"
        );
        my $left= $glob ? *{ $copy->[0][0] }{HASH} : $copy->[0][0];
        is(
            refaddr($left),
            refaddr($copy->[1]),
            "deferred occurrence glob=$glob: sharing survives"
        );
    }
}

for my $glob (0, 1) {
    my $proxy=   { x     => 1 };
    my $a= bless { which => 'A' }, 'DDSProxyChainA';
    my $b= bless { which => 'B' }, 'DDSProxyChainB';
    my %calls;
    my @seen;
    my $postdump= sub { $calls{ $_[0]{which} }++; push @seen, $_[0] };
    my $d=
        Dump()->Names('value')
        ->Freezer('DDSProxyChainA', sub { return ($b,     undef, $postdump) })
        ->Freezer('DDSProxyChainB', sub { return ($proxy, undef, $postdump) });
    my @input= ($a, $b);

    if ($glob) {
        @input= map { my $g= Symbol::gensym(); *{$g}= $_; $g } @input;
    }
    my $text= $d->Data(\@input)->Out;
    is_deeply(
        \%calls,
        { A => 1, B => 1 },
        "proxy chain glob=$glob: every original hook runs once"
    );
    is_deeply(
        [ sort map { refaddr($_) } @seen ],
        [ sort map { refaddr($_) } ($a, $b) ],
        "proxy chain glob=$glob: invocants are the original objects"
    );
    my $value;
    my $copy= eval $text . '$value';
    is($@, '', "proxy chain glob=$glob: output evaluates") or diag $text;
    my @values= $glob ? map { *{$_}{HASH} } @$copy : @$copy;
    is_deeply($values[0], $proxy,
        "proxy chain glob=$glob: final proxy is reconstructed");
    is(
        refaddr($values[0]),
        refaddr($values[1]),
        "proxy chain glob=$glob: final proxy stays shared"
    );
}

{
    my $proxy= { x => 1 };
    my $d= Dump()->Names('value')->Freezer(
        'DDSSharedProxy',
        sub {
            return ($proxy, undef,
                sub { die "second postdump failed\n" if $_[0]{which} == 2 });
        });
    my $input= [ map { bless { which => $_ }, 'DDSSharedProxy' } 1 .. 2 ];
    my $ok= eval { my $text= $d->Data($input)->Out; 1 };
    ok(!$ok, 'a noncanonical original postdump exception propagates');
    like($@, qr/second postdump failed/, 'postdump exception survives cleanup');
    is(
        scalar($d->Data([7])->Out),
        "\$value = [ 7 ];\n",
        'dumper is reusable after postdump failure'
    );
}

{

    package DDSPostdumpTiedSource;

    sub TIESCALAR {
        bless { original => $_[1], alternate => $_[2], calls => 0 }, $_[0];
    }

    sub FETCH {
        my ($self)= @_;
        return ++$self->{calls} == 6 ? $self->{alternate} : $self->{original};
    }

    package main;
    my $original= bless  { id => 'A' }, 'DDSPostdumpMagic';
    my $alternate= bless { id => 'B' }, 'DDSPostdumpMagic';
    tie my $input, 'DDSPostdumpTiedSource', $original, $alternate;
    my @seen;
    my $d= Dump()->Names('value')->Freezer(
        'DDSPostdumpMagic',
        sub {
            my ($object)= @_;
            return ({ id => $object->{id} }, undef, sub { push @seen, $_[0] });
        });
    my $text= $d->Data($input)->Out;
    my $value;
    my $copy= eval $text . '$value';
    is($@,          '',  'magical original output evaluates');
    is($copy->{id}, 'A', 'magical original uses the selected object proxy');
    is_deeply(
        [ map { refaddr($_) } @seen ],
        [ refaddr($original) ],
        'postdump snapshots the selected referent without another FETCH'
    );
}

for my $glob (0, 1) {
    my $original= bless { id => 1 }, 'DDSIgnoredPostdump';
    my $input= $original;
    if ($glob) { $input= Symbol::gensym(); *{$input}= $original }
    my $calls= 0;
    my $text= Dump()->Freezer(
        'DDSIgnoredPostdump',
        sub {
            return (0, undef, sub { $calls++ });
        })->Data($input)->Out;
    is($calls, 0, "ignored proxy glob=$glob: no irrelevant postdump hook runs");
}

done_testing;
