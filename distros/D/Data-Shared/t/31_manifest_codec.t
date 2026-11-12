use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON::PP ();
use Data::Shared qw(shared_get shared_set);
use Data::Shared::Manifest ();

# Skipped per subtest, not per file: the codec subtests need no backend.
my $probe = Data::Shared->new(tempdir(CLEANUP => 1));
my $HASHMAP = eval { $probe->mount('p', 'hashmap:ss', undef, 8); 1 }
    ? '' : "hashmap backend unavailable: $@";

subtest 'a non-ASCII backing path survives a round trip' => sub {
    plan skip_all => $HASHMAP if $HASHMAP;
    my @forms = (
        ['ASCII',        'store.shm'],
        ['UTF-8 bytes',  "caf\xc3\xa9.shm"],
        ['Latin-1 byte', "caf\xe9.shm"],
        ['flagged char', "caf\x{e9}.shm"],
        ['wide char',    "snow\x{263a}.shm"],
    );
    for my $form (@forms) {
        my ($label, $leaf) = @$form;
        my $dir = tempdir(CLEANUP => 1);
        {
            my $root = Data::Shared->new($dir);
            $root->mount('x', 'hashmap:ss', "$dir/$leaf", 100);
            shared_set($root, '/x/k', 'v');
        }
        my $reopened = eval { Data::Shared->open($dir) };
        ok $reopened, "$label: reopens" or diag $@;
        is eval { shared_get($reopened, '/x/k') }, 'v', "$label: reads the value"
            if $reopened;
    }

    my $dir = tempdir(CLEANUP => 1);
    {
        my $root = Data::Shared->new($dir);
        $root->mount('x', 'hashmap:ss', "$dir/caf\xc3\xa9.shm", 100);
        shared_set($root, '/x/k', 'v');
        $root->freeze_all;
    }
    my $ro = eval { Data::Shared->open_readonly($dir) };
    ok $ro, 'a frozen store with a byte path opens read-only' or diag $@;
    is eval { shared_get($ro, '/x/k') }, 'v', 'and reads back' if $ro;
};

subtest 'an unrepresentable mount argument is refused at mount time' => sub {
    plan skip_all => $HASHMAP if $HASHMAP;
    my @bad = (
        ['NaN capacity', sub { $_[0]->mount('x', 'hashmap:ss', undef, 'NaN' + 0) },
         qr/not a serializable mount argument/],
        ['Inf capacity', sub { $_[0]->mount('x', 'hashmap:ss', undef, 'Inf' + 0) },
         qr/not a serializable mount argument/],
        ['lone surrogate in a path', sub {
            no warnings 'utf8';
            $_[0]->mount('x', 'hashmap:ss', $_[0]->dir . '/a' . chr(0xD800) . '.shm', 100) },
         qr/not representable in a manifest/],
    );
    for my $case (@bad) {
        my ($label, $code, $like) = @$case;
        my $dir = tempdir(CLEANUP => 1);
        my $root = Data::Shared->new($dir);
        $root->mount('good', 'hashmap:ss', undef, 100);
        shared_set($root, '/good/k', 'v');
        ok !eval { $code->($root); 1 }, "$label is refused";
        like $@, $like, "$label says why";
        is_deeply [$root->mounts], ['good'], "$label leaves the mounts alone";
        is shared_get($root, '/good/k'), 'v', "$label leaves the store usable";
        ok eval { $root->mount('later', 'hashmap:ss', undef, 100); 1 },
            "$label does not block a later mount";
        ok eval { Data::Shared->open($dir); 1 }, "$label leaves a parsable manifest";
    }
};

# JSON::PP writes an NV with %.15g and reads 1e+15 back as an integer.
subtest 'a float argument does not fake a stale revision' => sub {
    plan skip_all => 'histogram backend unavailable'
        unless eval { require Data::Histogram::Shared; 1 };
    plan skip_all => $HASHMAP if $HASHMAP;
    for my $value (1e15, 1000000000000000, 2**50) {
        my $dir = tempdir(CLEANUP => 1);
        my $root = Data::Shared->new($dir);
        $root->mount('h', 'histogram', undef, 1, $value, 3);
        ok eval { $root->mount('m', 'hashmap:ss', undef, 100); 1 },
            "$value: a later mount still works" or diag $@;
        ok eval { Data::Shared->open($dir); 1 }, "$value: the store reopens";
    }
};

subtest 'only a real Inf or NaN is refused, not a string that looks like one' => sub {
    # The unused `+ 0` and "$x" copies set flags on their source: before perl
    # 5.40 a numified string and a stringified real Inf carry identical flags.
    my $looks_numeric = 'inf';
    my $forced = $looks_numeric + 0;
    my ($kept) = Data::Shared::Manifest::snapshot($looks_numeric);
    is $kept, 'inf', 'a string used numerically is kept as a string';
    my $lower_nan = 'nan';
    my $forced_nan = $lower_nan + 0;
    my ($kept_nan) = Data::Shared::Manifest::snapshot($lower_nan);
    is $kept_nan, 'nan', 'and so is one that numifies to NaN';
    # Nothing separates perl's own spelling from a stringified real Inf.
    my $canonical = 'Inf';
    my $forced_canon = $canonical + 0;
    ok !eval { Data::Shared::Manifest::snapshot($canonical); 1 },
        "a string spelled exactly as perl spells Inf is refused with it";
    for my $label ('nan', 'NaN.shm', 'Infinity.shm', '-inf') {
        my ($keep) = Data::Shared::Manifest::snapshot($label);
        is $keep, $label, "the string '$label' is kept";
    }
    my $real_inf = 'Inf' + 0;
    my $stringified = "$real_inf";
    ok !eval { Data::Shared::Manifest::snapshot($real_inf); 1 },
        'a real Inf is refused even after being stringified';
    ok !eval { Data::Shared::Manifest::snapshot('NaN' + 0); 1 }, 'and a real NaN';
    my $rounded = 9**9**9;
    my $rounded_pv = "$rounded";
    my $rounded_nan = 'NaN' + 0;
    my $nan_pv = "$rounded_nan";
    my $lookalike = 'inf';
    my $lookalike_nv = $lookalike + 0;
    ok !eval { Data::Shared::Manifest::snapshot($rounded); 1 },
        'an Inf written as 9**9**9 and printed is refused too';
    ok !eval { Data::Shared::Manifest::snapshot($rounded_nan); 1 }, 'and such a NaN';
    my ($still) = Data::Shared::Manifest::snapshot($lookalike);
    is $still, 'inf', 'while the lookalike string is still kept';
};

subtest 'an upgraded string argument is published as a string' => sub {
    my $canonical = 'Inf';
    my $forced = $canonical + 0;
    utf8::upgrade($canonical);
    ok !eval { Data::Shared::Manifest::snapshot($canonical); 1 },
        'an upgraded canonical Inf spelling is refused like the downgraded one';
    for my $text ('123', '1e9999', 'Infinity') {
        my $value = $text;
        my $numified = 0 + $value;
        no warnings 'numeric';
        utf8::upgrade($value);
        my ($stored) = Data::Shared::Manifest::snapshot($value);
        my $json = JSON::PP->new->canonical(1)->ascii(1)->encode([$stored]);
        like $json, qr/\A\["/, "'$text' upgraded and numified is published quoted";
        is(JSON::PP->new->decode($json)->[0], $text, "and reads back as '$text'");
    }
};

subtest 'a numeric mount argument survives the round trip exactly' => sub {
    # A fraction needs every digit its NV has: 17 for a double, more on a
    # -Duselongdouble or -Dusequadmath perl; perl's own spelling has NV_DIG.
    for my $value (2**50, 2**53, 2**62, -(2**63), 2**63, 1e15,
                   1125899906842624, 3600000000, 0.1, 1.5, -2**50, 1e300,
                   1 + 2**-52, 4 * atan2(1, 1), 1.2345678901234567,
                   2**-1074, 1 / 3) {
        my ($stored) = Data::Shared::Manifest::snapshot($value);
        my $json = JSON::PP->new->canonical(1)->ascii(1)->encode([$stored]);
        my $back = JSON::PP->new->decode($json)->[0];
        cmp_ok $back, '==', $value, "$value round trips exactly";
        # 'F', not 'd': rounding both to a double would pass on a long-double perl.
        is pack('F', $back), pack('F', $value), "$value keeps every bit";
    }
};

subtest 'a number stays a number through a reopen and the next write' => sub {
    plan skip_all => $HASHMAP if $HASHMAP;
    my $dir = tempdir(CLEANUP => 1);
    my $read = sub { open my $fh, '<', "$dir/manifest.json" or die $!; local $/; <$fh> };
    { my $r = Data::Shared->new($dir); $r->mount('cache', 'hashmap:ss', undef, 1000) }
    like $read->(), qr/"args":\[null,1000\]/, 'written unquoted';
    { my $r = Data::Shared->open($dir); $r->mount('other', 'hashmap:ss', undef, 8) }
    like $read->(), qr/"args":\[null,1000\]/, 'and still unquoted after a reopen rewrote it';
};

# JSON::XS and Cpanel::JSON::XS bless into JSON::PP::Boolean without loading it.
subtest 'a boolean from another JSON module needs no JSON::PP loaded' => sub {
    my $code = 'require Data::Shared::Manifest;'
        . ' my ($v, $ok) = Data::Shared::Manifest::snapshot(bless \(my $b = 1), "JSON::PP::Boolean");'
        . ' print $ok && $v ? "kept" : "lost"';
    open my $ph, '-|', $^X, (map { "-I$_" } @INC), '-e', $code or die $!;
    my $out = do { local $/; <$ph> };
    close $ph;
    is $out, 'kept', 'the boolean snapshots as true';
};

# perl spells 2**53 as 9.00719925474099e+15, which is 2 short.
subtest 'an exact integer survives the JSON round trip' => sub {
    my ($stored)   = Data::Shared::Manifest::snapshot(2**53);
    my ($pristine) = Data::Shared::Manifest::snapshot(1e300);
    my $json = JSON::PP->new->canonical(1)->ascii(1)->encode([$stored]);
    cmp_ok(JSON::PP->new->decode($json)->[0], '==', 2**53, '2**53 round trips');
    cmp_ok($pristine, '==', 1e300, 'and a value its own spelling survives keeps it');
    unlike(JSON::PP->new->encode([$pristine]), qr/"/, 'and is still written as a number');
};

# \d matches non-ASCII digits, which numify to a prefix of the value.
subtest 'a non-ASCII digit is not a composite option' => sub {
    plan skip_all => $HASHMAP if $HASHMAP;
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    ok !eval {
        $root->mount('m', ['hashmap:ss', 1000, ['hashmap:ss', 16],
                           { max_children => "1\x{661}" }]);
        1;
    }, 'max_children with a non-ASCII digit is refused';
    like $@, qr/must be an integer/, 'and says what it wanted';
    ok eval { $root->mount('ok', ['hashmap:ss', 1000, ['hashmap:ss', 16],
                                  { max_children => 11 }]); 1 },
        'a plain integer still mounts';
};

subtest 'a manifest the reader cannot trust is refused, naming the store' => sub {
    plan skip_all => $HASHMAP if $HASHMAP;
    my @cases = (
        ['a revision that is not a number' => qr/invalid manifest revision/,
            sub { $_[0]{revision} = 'seven' }],
        ['a negative revision'              => qr/invalid manifest revision/,
            sub { $_[0]{revision} = -1 }],
        ['a mount with no name'             => qr/invalid mount name/,
            sub { $_[0]{mounts}[0]{name} = undef }],
        ['a mount name that is a reference' => qr/invalid mount name/,
            sub { $_[0]{mounts}[0]{name} = ['x'] }],
        ['two mounts with one name'         => qr/duplicate mount 'cache'/,
            sub { push @{ $_[0]{mounts} }, { %{ $_[0]{mounts}[0] } } }],
        ['a retained ledger that is not a list' => qr/invalid retained storage/,
            sub { $_[0]{retained} = 'nope' }],
        ['a retained entry that is empty'   => qr/invalid retained storage/,
            sub { $_[0]{retained} = [''] }],
    );
    for my $case (@cases) {
        my ($label, $expect, $break) = @$case;
        my $dir = tempdir(CLEANUP => 1);
        my $path;
        {
            my $root = Data::Shared->new($dir);
            $root->mount('cache', 'hashmap:ss', undef, 8);
            $path = $root->manifest_path;
        }
        my $data = JSON::PP->new->decode(do {
            open my $fh, '<', $path or die $!; local $/; <$fh> });
        $break->($data);
        open my $out, '>', $path or die $!;
        print $out JSON::PP->new->canonical(1)->ascii(1)->encode($data), "\n";
        close $out or die $!;
        ok !eval { Data::Shared->open($dir); 1 }, "$label is refused";
        like $@, $expect, "and says why: $label";
        like $@, qr/\Q$path\E/, "and which store: $label";
    }
};

done_testing;
