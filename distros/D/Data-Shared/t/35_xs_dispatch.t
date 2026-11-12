use strict;
use warnings;
use Test::More;
use B ();
use File::Temp qw(tempdir);
use Data::Shared ();

# Each case runs through an XSUB and its _pp_ twin on identical stores, which must
# agree on results, errors, store state, and the flags left on the caller's scalars.

my $probe = Data::Shared->new;
eval { $probe->mount('p', 'hashmap:ii', undef, 16); $probe->mount('q', 'hashmap:ss', undef, 16); 1 }
    or plan skip_all => "hashmap backends unavailable: $@";
my $have_buffer = eval { $probe->mount('b', 'buffer:i64', undef, 8); 1 };
my $have_bloom  = eval { $probe->mount('f', 'bloomfilter', undef, 100, 0.01); 1 };
my $have_users  = eval { $probe->mount('u', ['hashmap:ss', 16, ['hashmap:ss', 8]]); 1 };

sub populate {
    my ($root) = @_;
    $root->mount('ii', 'hashmap:ii', undef, 64);
    $root->mount('ss', 'hashmap:ss', undef, 64);
    $root->mount('si', 'hashmap:si', undef, 64);
    $root->mount('buf', 'buffer:i64', undef, 8) if $have_buffer;
    $root->mount('seen', 'bloomfilter', undef, 100, 0.01) if $have_bloom;
    Data::Shared::_pp_shared_set($root, "/ii/$_", $_ * 10) for 1 .. 3;
    Data::Shared::_pp_shared_set($root, '/ss/a', 'x');
    Data::Shared::_pp_shared_set($root, "/ss/caf\xc3\xa9", 'bytes');
    if ($have_users) {
        $root->mount('users', ['hashmap:ss', 16, ['hashmap:ss', 8]]);
        Data::Shared::_pp_shared_set($root, '/users/alice/name', 'Alice');
    }
    return $root;
}

sub fresh {
    my ($kind) = @_;
    return populate(Data::Shared->new) unless $kind;
    my $dir = tempdir(CLEANUP => 1);
    my $root = populate(Data::Shared->new($dir));
    if ($kind eq 'nested') {
        $root->mount('deep/map', 'hashmap:ii', undef, 16);
        return $root;
    }
    $root->unmount('seen') if $have_bloom;
    $root->unmount('buf') if $have_buffer;
    $root->freeze_all;
    return Data::Shared->open_readonly($dir);
}

sub state_of {
    my ($root) = @_;
    my @out;
    push @out, Data::Shared::_pp_shared_get($root, "/ii/$_") for 1 .. 9;
    push @out, Data::Shared::_pp_shared_get($root, "/ss/$_") for 'a', 'b', 'k', "caf\xc3\xa9", 5, 7;
    push @out, Data::Shared::_pp_shared_get($root, '/si/hits');
    push @out, map { Data::Shared::_pp_shared_get($root, "/buf/$_") } 0 .. 7 if $root->mount_info('buf');
    push @out, Data::Shared::_pp_shared_exists($root, "/seen/$_") for grep { $root->mount_info('seen') } 'x', 'y';
    push @out, Data::Shared::_pp_shared_get($root, '/users/alice/name') if $have_users;
    return join ',', map { defined $_ ? $_ : 'undef' } @out;
}

sub flags {
    my ($ref) = @_;
    my $f = B::svref_2object($ref)->FLAGS;
    return join '', map { $f & $_->[1] ? $_->[0] : '-' }
        ['I', B::SVf_IOK], ['N', B::SVf_NOK], ['P', B::SVf_POK], ['R', B::SVf_ROK];
}

# $args reaches $fn by alias, so its flags afterwards are what the caller would see.
sub outcome {
    my ($fn, $ctx, $root, $args) = @_;
    my @r;
    my $ok = eval {
        if    ($ctx eq 'list')   { @r = $fn->($root, @$args) }
        elsif ($ctx eq 'scalar') { $r[0] = $fn->($root, @$args) }
        else                     { $fn->($root, @$args); }
        1;
    };
    my $err = $ok ? '' : "$@";
    $err =~ s/ at \S+ line \d+\.?\n\z//;
    return {
        results => [map { [ref $_ ? ref $_ : defined $_ ? "$_" : 'undef', flags(\$_)] } @r],
        error => $err,
        args => [map { ref $_ eq 'ARRAY' ? [map { flags(\$_) } @$_] : flags(\$_) } @$args],
    };
}

my @cases;
sub case { push @cases, [@_] }      # name, function, store kind, args builder, calls

for my $path ('/ii/1', '//ii//1/', 'ii/1', '/ii/01', '/ii/-1', '/ii/1.0', '/ii/abc', '/ii/-',
              '/ii/', '/ii', '/', '', '/ii/1/2', '/nope/1', '/users/alice/name', '/ss/a',
              "/ss/caf\xc3\xa9", '/ss/missing', '/si/hits', '/buf/3', '/buf/99', '/buf/x', '/seen/x') {
    case("shared_$_ $path", "shared_$_", undef, sub { ($path) }) for qw(get exists delete incr);
    case("shared_set $path", 'shared_set', undef, sub { my $v = 42; ($path, $v) });
    case("shared_incr $path by 5", 'shared_incr', undef, sub { my $d = 5; ($path, $d) });
}
case('shared_incr undef delta', 'shared_incr', undef, sub { ('/ii/1', undef) });
case('shared_incr string delta', 'shared_incr', undef, sub { ('/ii/1', '3') });
case('shared_incr si by 2', 'shared_incr', undef, sub { ('/si/hits', 2) });
case('shared_get undef path', 'shared_get', undef, sub { (undef) });
case('shared_get ref path', 'shared_get', undef, sub { (['ii', 1]) });
case('shared_get numeric path', 'shared_get', undef, sub { my $p = 7; ($p) });
case('shared_get utf8-flagged path', 'shared_get', undef, sub { my $p = '/ss/a'; utf8::upgrade($p); ($p) });
case('shared_get extra argument', 'shared_get', undef, sub { ('/ii/1', 'extra') });
case('shared_set IV into ss', 'shared_set', undef, sub { my $v = 7; ('/ss/b', $v) });
case('shared_set NV into ss', 'shared_set', undef, sub { my $v = 1.5; ('/ss/b', $v) });
case('shared_set no value', 'shared_set', undef, sub { ('/ii/4') });
case('shared_get no arguments', 'shared_get', undef, sub { () });
case('shared_get nested root', 'shared_get', 'nested', sub { ('/ii/1') });
case('shared_get nested mount', 'shared_get', 'nested', sub { ('/deep/map/1') });
case('shared_get readonly', 'shared_get', 'readonly', sub { ('/ii/1') });
case('shared_exists readonly', 'shared_exists', 'readonly', sub { ('/ii/zz') });
case("shared_$_ readonly", "shared_$_", 'readonly', sub { ('/ii/1', 5) }) for qw(set incr delete);

for my $path (['ii', 1], ['ii', '1'], ['ii', 1.5], ['ii', 1.0], ['ii', -2], ['ii', 'abc'],
              ['ii', undef], ['ii'], ['ii', 1, 2], [], ['nope', 1], ['ss', 'a/b'], ['ss', 5],
              ['ss', 'a'], ['users', 'alice', 'name'], ['buf', 3], [7, 1]) {
    my $label = join '|', map { defined $_ ? $_ : 'undef' } @$path;
    case("shareda_$_ [$label]", "shareda_$_", undef, sub { ([@$path]) }) for qw(get exists delete incr);
    case("shareda_set [$label]", 'shareda_set', undef, sub { my $v = 11; ([@$path], $v) });
}
case('shareda_get blessed path', 'shareda_get', undef, sub { (bless ['ii', 1], 'Foo') });
case('shareda_set readonly', 'shareda_set', 'readonly', sub { (['ii', 1], 5) });

# Compiled cases call twice: the first binds through Perl, the second runs the binding.
for my $path ('/ii/1', '/ii/abc', '/ss/a', '/si/hits', '/buf/3', '/buf/x', '/seen/x',
              '/users/alice/name', ['ii', 2], ['ss', 5]) {
    my $label = ref $path ? join('|', @$path) : $path;
    case("sharedc_$_ $label", "sharedc_$_", undef, sub { (Data::Shared::shared_compile($path)) }, 2)
        for qw(get exists delete incr);
    case("sharedc_set $label", 'sharedc_set', undef, sub { my $v = 13; (Data::Shared::shared_compile($path), $v) }, 2);
    case("sharedc_incr $label by 2", 'sharedc_incr', undef, sub { (Data::Shared::shared_compile($path), 2) }, 2);
}
case('sharedc_incr undef delta', 'sharedc_incr', undef, sub { (Data::Shared::shared_compile('/ii/1'), undef) }, 2);
case("sharedc_$_ readonly", "sharedc_$_", 'readonly', sub { (Data::Shared::shared_compile('/ii/1'), 4) }, 2)
    for qw(get set exists delete incr);
case('sharedc_get not compiled', 'sharedc_get', undef, sub { ('/ii/1') });
case('sharedc_get root path', 'sharedc_get', undef, sub { (Data::Shared::shared_compile('/')) }, 2);

for my $c (['/ii', 'get', 1], ['/ii/1', 'get'], ['/ii', 'size'], ['/ii', 'nope'], ['/ii', ''],
           ['/ii', undef], ['/ii', 'Data::HashMap::Shared::II::get', 1], ['/', 'get'],
           ['/users', 'size'], ['/ss', 'get', 'a'], ['/ii', 'put', 8, 80], ['/ss', 'put', 'k', 7]) {
    my ($path, $m, @a) = @$c;
    my $label = join ' ', map { defined $_ ? $_ : 'undef' } @$c;
    my @ap = grep { length } split m{/}, $path;
    case("shared_call $label", 'shared_call', undef, sub { ($path, $m, @a) });
    case("shareda_call $label", 'shareda_call', undef, sub { ([@ap], $m, @a) });
    case("sharedc_call $label", 'sharedc_call', undef, sub { (Data::Shared::shared_compile($path), $m, @a) }, 2);
}

my $compared = 0;
for my $case (@cases) {
    my ($name, $fn, $kind, $build, $calls) = @$case;
    next if $name =~ /\bbuf\b/ && !$have_buffer;
    next if $name =~ /\bseen\b/ && !$have_bloom;
    next if $name =~ /\busers\b/ && !$have_users;
    for my $ctx (qw(scalar list void)) {
        my %side;
        for my $side (qw(xs pp)) {
            my $root = fresh($kind);
            my $fn_ref = Data::Shared->can($side eq 'xs' ? $fn : "_pp_$fn");
            my $args = [$build->()];
            $side{$side} = [map { outcome($fn_ref, $ctx, $root, $args) } 1 .. ($calls || 1)];
            push @{ $side{$side} }, state_of($root);
        }
        is_deeply $side{xs}, $side{pp}, "$name ($ctx)" or diag explain \%side;
        $compared++;
    }
}
cmp_ok $compared, '>', 500, 'the cases ran';

{
    package Counted;
    sub TIESCALAR { my ($c, $v) = @_; return bless { v => $v, fetch => 0 }, $c }
    sub FETCH { $_[0]{fetch}++; return $_[0]{v} }
    sub STORE { $_[0]{v} = $_[1] }
}

subtest 'a tied argument is read as often as the Perl path reads it' => sub {
    # Each runs twice: for a compiled path the second call is the bound one.
    my %call = (
        'shared_set value'   => sub { my ($f, $r, $t) = @_; $f->($r, '/ii/2', $$t) },
        'shared_incr delta'  => sub { my ($f, $r, $t) = @_; $f->($r, '/ii/2', $$t) },
        'shared_get path'    => sub { my ($f, $r, $t) = @_; $f->($r, $$t) },
        'shareda_get key'    => sub { my ($f, $r, $t, $p) = @_; $f->($r, $p) },
        'shared_call arg'    => sub { my ($f, $r, $t) = @_; $f->($r, '/ii', 'get', $$t) },
        'sharedc_incr delta' => sub { my ($f, $r, $t, $p, $cp) = @_; $f->($r, $cp, $$t) },
    );
    for my $name (sort keys %call) {
        my ($fn) = $name =~ /^(\S+)/;
        my %seen;
        for my $side (qw(xs pp)) {
            my $root = fresh();
            my $f = Data::Shared->can($side eq 'xs' ? $fn : "_pp_$fn");
            my $v;
            tie $v, 'Counted', $name =~ /path/ ? '/ii/2' : 2;
            my @p = ('ii');
            tie $p[1], 'Counted', 2;
            my $cp = Data::Shared::shared_compile('/ii/2');
            $call{$name}->($f, $root, \$v, \@p, $cp) for 1 .. 2;
            $seen{$side} = [tied($v)->{fetch}, tied($p[1])->{fetch}, state_of($root)];
        }
        is_deeply $seen{xs}, $seen{pp}, "$name: same fetches and store";
    }
};

{
    package Reentrant;
    sub new { return bless { n => 7 }, shift }
    # Reads $_[0] only after the callback, which unmounts this handle.
    sub run { $_[1]->(); my @churn = map { "x$_" x 8 } 1 .. 200; return ref($_[0]) . ':' . $_[0]{n} }
}

subtest 'a callee that unmounts its own mount' => sub {
    my %call = (
        shared_call  => sub { Data::Shared::shared_call($_[0], '/x', 'run', $_[1]) },
        shareda_call => sub { Data::Shared::shareda_call($_[0], ['x'], 'run', $_[1]) },
        sharedc_call => sub { Data::Shared::sharedc_call($_[0], $_[2], 'run', $_[1]) },
    );
    for my $fn (sort keys %call) {
        my $root = Data::Shared->new;
        $root->mount('x', Reentrant->new);
        my $cp = Data::Shared::shared_compile('/x');
        $call{$fn}->($root, sub {}, $cp) for 1 .. 2;
        is $call{$fn}->($root, sub { $root->unmount('x') }, $cp), 'Reentrant:7', "$fn keeps the handle alive";
        ok !$root->mount_info('x'), 'and the mount is gone';
    }
};

{
    package Pick;     # a tied scalar handing out whichever value is selected
    sub TIESCALAR { my ($c, $v) = @_; return bless { v => $v }, $c }
    sub FETCH { my $s = shift; $s->{on_fetch}->() if $s->{on_fetch}; return $s->{v} }
    sub STORE { $_[0]{v} = $_[1] }
}
{
    package Zapper;
    sub new { return bless {}, shift }
    sub zap { $_[0] = undef; return 1 }
}
{
    package SubRoot;
    our @ISA = ('Data::Shared');
    use overload '==' => sub { die "compared\n" }, fallback => 1;
}

subtest 'arguments only Perl can resolve' => sub {
    my %case = (
        # A tied scalar whose cached value is stale: the call must FETCH it.
        'tied root' => sub {
            my ($fn, $a, $b) = @_;
            tie my $t, 'Pick', $a;
            my $warm = $t;
            tied($t)->{v} = $b;
            $fn->{shared_set}->($t, '/ii/1', 99);
        },
        'tied array path' => sub {
            my ($fn, $a, $b) = @_;
            tie my $t, 'Pick', ['ii', 1];
            my $warm = $t;
            tied($t)->{v} = ['ii', 2];
            $fn->{shareda_set}->($a, $t, 77);
        },
        'tied compiled path' => sub {
            my ($fn, $a, $b) = @_;
            my ($c1, $c2) = map { Data::Shared::shared_compile("/ii/$_") } 1, 2;
            $fn->{sharedc_set}->($a, $_, 0) for $c1, $c2;
            tie my $t, 'Pick', $c1;
            my $warm = $t;
            tied($t)->{v} = $c2;
            $fn->{sharedc_set}->($a, $t, 55);
        },
        'sharedc_call argument that retires its mount' => sub {
            my ($fn, $a, $b) = @_;
            $a->mount('gone', 'hashmap:ii', undef, 8);
            my $cp = Data::Shared::shared_compile('/gone');
            $fn->{sharedc_call}->($a, $cp, 'put', 1, 1) for 1 .. 2;
            tie my $t, 'Pick', 5;
            tied($t)->{on_fetch} = sub { $a->unmount('gone') };
            $fn->{sharedc_call}->($a, $cp, 'put', 2, $t);
        },
        'invocant assignment' => sub {
            my ($fn, $a, $b) = @_;
            $a->mount('z', Zapper->new);
            $fn->{shared_call}->($a, '/z', 'zap') for 1 .. 2;
            return defined $a->handle('/z') ? 'kept' : 'cleared';
        },
        'subclass root with overloaded ==' => sub {
            my ($fn) = @_;
            my $s = bless Data::Shared->new, 'SubRoot';
            $s->mount('ii', 'hashmap:ii', undef, 8);
            my $cp = Data::Shared::shared_compile('/ii/1');
            $fn->{sharedc_get}->($s, $cp) for 1 .. 2;
        },
    );
    for my $name (sort keys %case) {
        my %got;
        for my $side (qw(xs pp)) {
            my %fn = map { ($_ => Data::Shared->can($side eq 'xs' ? $_ : "_pp_$_")) }
                qw(shared_set shareda_set sharedc_set sharedc_call shared_call sharedc_get);
            my ($a, $b) = (fresh(), fresh());
            my $r = eval { $case{$name}->(\%fn, $a, $b) };
            (my $err = $@) =~ s/ at \S+ line \d+\.?\n\z//;
            $got{$side} = [$r, $err, state_of($a), state_of($b)];
        }
        is_deeply $got{xs}, $got{pp}, $name or diag explain \%got;
    }
};

# The comparison above also passes if every call falls back to Perl.
subtest 'the common calls never reach the Perl implementation' => sub {
    my %slow;
    no strict 'refs';
    no warnings 'redefine';
    for my $name (grep { /^_pp_/ } keys %Data::Shared::) {
        my $orig = \&{"Data::Shared::$name"};
        *{"Data::Shared::$name"} = sub { $slow{$name}++; goto &$orig };
    }
    my $root = fresh();
    my $cp = Data::Shared::shared_compile('/ii/1');
    my $ccall = Data::Shared::shared_compile('/ii');
    my @calls = (
        sub { Data::Shared::shared_get($root, '/ii/1') },
        sub { Data::Shared::shared_set($root, '/ii/1', 5) },
        sub { Data::Shared::shared_exists($root, '/ii/abc') },
        sub { Data::Shared::shared_delete($root, '/ii/9') },
        sub { Data::Shared::shared_incr($root, '/ii/1') },
        sub { Data::Shared::shared_incr($root, '/ii/1', 3) },
        sub { Data::Shared::shared_incr($root, '/si/hits', 2) },
        sub { Data::Shared::shared_get($root, '/ss/a') },
        sub { Data::Shared::shareda_get($root, ['ii', 1]) },
        sub { Data::Shared::shareda_set($root, ['ss', 'k'], 'v') },
        sub { Data::Shared::sharedc_get($root, $cp) },
        sub { Data::Shared::sharedc_incr($root, $cp, 2) },
        sub { Data::Shared::sharedc_exists($root, $cp) },
        sub { Data::Shared::shared_call($root, '/ii', 'get', 1) },
        sub { Data::Shared::shareda_call($root, ['ii'], 'get', 1) },
        sub { Data::Shared::sharedc_call($root, $ccall, 'get', 1) },
        sub { $root->get('/ii/1') },
    );
    push @calls, sub { Data::Shared::shared_get($root, '/buf/3') },
                 sub { Data::Shared::shared_exists($root, '/buf/99') } if $have_buffer;
    push @calls, sub { Data::Shared::shared_set($root, '/seen/y', 1) },
                 sub { Data::Shared::shared_exists($root, '/seen/y') } if $have_bloom;
    $_->() for @calls;
    %slow = ();
    $_->() for @calls;
    is_deeply \%slow, {}, 'no fallback once bound';

    # The root holds a binding's only strong reference to its closure. Without
    # it, only the descriptor can keep the call off the Perl path.
    my $cd = Data::Shared::shared_compile('/ii/2');
    Data::Shared::sharedc_get($root, $cd);
    delete $root->{_compiled}{ Scalar::Util::refaddr($cd) };
    %slow = ();
    is Data::Shared::sharedc_get($root, $cd), 20, 'a compiled read without its closure';
    is_deeply \%slow, {}, 'runs from the descriptor';

    if ($have_users) {
        Data::Shared::shared_get($root, '/users/alice/name');
        ok $slow{_pp_shared_get}, 'a composite path falls back';
        %slow = ();
    }
    eval { Data::Shared::shared_get($root, '/ii/abc') };
    ok $slow{_pp_shared_get}, 'a malformed integer key falls back';
    %slow = ();
    $root->mount('more', 'hashmap:ii', undef, 8);
    Data::Shared::sharedc_get($root, $cp);
    ok $slow{_pp_sharedc_get}, 'a topology change makes a compiled path rebind';
    %slow = ();
    Data::Shared::sharedc_get($root, $cp);
    is_deeply \%slow, {}, 'and the new binding is used';
};

done_testing;
