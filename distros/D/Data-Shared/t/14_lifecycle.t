use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path ();
use Scalar::Util qw(weaken);
use POSIX ();
use Data::Shared qw(shared_compile sharedc_call);

{
    package Data::Shared::TestHandle;
    our $CONSTRUCTIONS = 0;
    sub new {
        my ($class, $path, @args) = @_;
        $CONSTRUCTIONS++;
        if (defined $path && !-e $path) {
            open my $fh, '>', $path or die $!;
            close $fh or die $!;
        }
        return bless { path => $path, args => \@args }, $class;
    }
    sub path { $_[0]{path} }
    sub args { $_[0]{args} }
    sub answer { 42 }
    $INC{'Data/Shared/TestHandle.pm'} = __FILE__;
}

subtest 'compiled dispatch does not keep the root alive' => sub {
    my $cp = shared_compile('/handle');
    my $weak;
    {
        my $root = Data::Shared->new;
        $root->mount('handle', Data::Shared::TestHandle->new);
        is sharedc_call($root, $cp, 'answer'), 42, 'compiled call bound';
        $weak = $root;
        weaken($weak);
    }
    ok !defined $weak, 'root released while compiled path remains alive';
    my $next = Data::Shared->new;
    $next->mount('handle', Data::Shared::TestHandle->new);
    is sharedc_call($next, $cp, 'answer'), 42, 'compiled path can bind another root';
};

subtest 'path accessors preserve compiled dispatch' => sub {
    my $input = ['handle'];
    my $cp = shared_compile($input);
    $input->[0] = 'changed';
    is_deeply $cp->raw, ['handle'], 'raw array is a snapshot';
    my $root = Data::Shared->new;
    $root->mount('handle', Data::Shared::TestHandle->new);
    is sharedc_call($root, $cp, 'answer'), 42, 'cache primed';
    $cp->components->[0] = 'changed';
    is_deeply $cp->components, ['handle'], 'components accessor returns a copy';
    is sharedc_call($root, $cp, 'answer'), 42, 'cache and path remain consistent';
    my $node = $root->node('/handle');
    $node->components->[0] = 'changed';
    is eval { $node->call('answer') }, 42, 'node components accessor returns a copy';
    is eval { $root->handle([]) }, $root, 'empty array addresses root handle';
    is eval { $root->handle(shared_compile('/')) }, $root, 'compiled root addresses root handle';
};

subtest 'read-only lifecycle cannot modify the namespace or files' => sub {
    my $dir = tempdir(CLEANUP => 1);
    Data::Shared->new($dir);
    my $root = Data::Shared->open_readonly($dir);
    for my $case (
        ['mount', sub { $root->mount('x', Data::Shared::TestHandle->new) }],
        ['unmount', sub { $root->unmount('x') }],
        ['unlink_all', sub { $root->unlink_all }],
    ) {
        my ($name, $code) = @$case;
        ok !eval { $code->(); 1 }, "$name refused";
        like $@, qr/read-only/, "$name explains read-only restriction";
    }
    ok -e "$dir/manifest.json", 'manifest retained';
    is_deeply [$root->mounts], [], 'namespace unchanged';
};

subtest 'backing path aliases fail before constructing another handle' => sub {
    for my $pair (['a/b', 'a__b'], ['a b', 'a_b']) {
        my $root = Data::Shared->new(tempdir(CLEANUP => 1));
        $root->mount($pair->[0], 'Data::Shared::TestHandle', undef, 100);
        my $before = $Data::Shared::TestHandle::CONSTRUCTIONS;
        ok !eval { $root->mount($pair->[1], 'Data::Shared::TestHandle', undef, 100); 1 },
            "$pair->[1] cannot alias $pair->[0]";
        like $@, qr/backing path.*already used/, 'collision explains backing path';
        is $Data::Shared::TestHandle::CONSTRUCTIONS, $before, 'constructor not called';
        is_deeply [$root->mounts], [$pair->[0]], 'original mount retained';
        my $again = Data::Shared->open($root->dir);
        is_deeply [$again->mounts], [$pair->[0]], 'manifest retained';
    }
};

subtest 'a retargeted symlink cannot hide a collision' => sub {
    my $dir = tempdir(CLEANUP => 1);
    mkdir "$dir/real1"; mkdir "$dir/real2";
    plan skip_all => 'no symlinks here' unless eval { symlink "$dir/real1", "$dir/link" };
    my $root = Data::Shared->new("$dir/store");
    $root->mount('a', 'Data::Shared::TestHandle', "$dir/link/x.shm", 16);
    $root->mount('c', 'Data::Shared::TestHandle', "$dir/real1/other.shm", 16);
    unlink "$dir/link";
    symlink "$dir/real2", "$dir/link" or die "symlink: $!";
    ok !eval { $root->mount('b', 'Data::Shared::TestHandle', "$dir/real2/x.shm", 16); 1 },
        'the collision is still caught after the retarget';
    like $@, qr/backing path.*already used/, 'and explains itself';
    is scalar(keys %{ $root->{_abs_cache} || {} }), 0, 'no resolved paths outlive the operation';
};

subtest 'hashref specs preserve external constructor arguments on replay' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    my $handle = $root->mount('x', { spec => 'Data::Shared::TestHandle' }, undef, 123);
    is_deeply $handle->args, [123], 'original constructor arguments';
    my $again = Data::Shared->open($root->dir);
    is_deeply $again->handle('/x')->args, [123], 'replayed constructor arguments';
};

subtest 'full class names use the declared loader and constructor' => sub {
    for my $pair (
        ['Data::Deque::Shared::Int', 'Data::Deque::Shared'],
        ['Data::Pool::Shared::I64', 'Data::Pool::Shared'],
        ['Data::RingBuffer::Shared::Int', 'Data::RingBuffer::Shared'],
        ['Data::Stack::Shared::Str', 'Data::Stack::Shared'],
    ) {
        my $resolved = Data::Shared::Registry::resolve_spec($pair->[0]);
        is $resolved->{load}, $pair->[1], "$pair->[0] loads its defining module";
    }
    for my $class ('Data::Reservoir::Shared', 'Data::TopK::Shared') {
        is Data::Shared::Registry::resolve_spec($class)->{ctor}, 'new', "$class uses default constructor";
    }
    # bloomfilter declares no variants, so it relies on the default-class match.
    SKIP: {
        my $r = Data::Shared->new;
        skip 'bloomfilter unavailable', 2
            unless eval { $r->mount('bf', 'Data::BloomFilter::Shared', undef, 10000, 0.01); 1 };
        ok eval { Data::Shared::shared_set($r, '/bf/alice', 1); 1 },
            'a class name with no variants still takes the generic verbs' or diag $@;
        is Data::Shared::shared_exists($r, '/bf/alice'), 1, 'and answers through them';
    }
    is Data::Shared::Registry::resolve_spec('Data::HashMap::Shared::II')->{variant}, 'ii',
        'full class retains canonical variant';
};

# The manifest lock is not re-entrant, so a regression would block on it:
# run in a child with a deadline.
{
    my $kid = fork();
    fail 'cannot fork to test the nested-mutation guard' unless defined $kid;
    if (defined $kid) {
        if ($kid == 0) {
            # _exit skips File::Temp's cleanup, so this one is removed by hand.
            my $tmp = tempdir();
            my $root = Data::Shared->new($tmp);
            my $accepted = eval {
                $root->mount('outer', sub {
                    my ($r) = @_;
                    $r->mount('inner', 'Data::Shared::TestHandle', undef, 16);
                    return Data::Shared::TestHandle->new(undef, 16);
                });
                1;
            };
            undef $root;
            File::Path::remove_tree($tmp);
            POSIX::_exit($accepted ? 1 : 0);     # 0 = refused
        }
        my $reaped = 0;
        my $deadline = time + 30;
        while (time < $deadline) {
            last if $reaped = (waitpid($kid, POSIX::WNOHANG()) == $kid);
            select undef, undef, undef, 0.1;
        }
        if (!$reaped) { kill 9, $kid; waitpid $kid, 0 }
        ok $reaped, 'a nested mount mutation does not deadlock';
        is $?, 0, 'it is refused' if $reaped;
    }
}

subtest 'teardown sweeps the root directory by extension' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    eval { $root->mount('m', 'hashmap:ii', undef, 64); 1 }
        or plan skip_all => "hashmap unavailable: $@";
    for my $leaf (qw(not-ours.shm notes.txt)) {
        open my $fh, '>', "$dir/$leaf" or die $!;
        print {$fh} 'x';
        close $fh or die $!;
    }
    mkdir "$dir/keep.shm" or die $!;
    ok $root->unlink_all, 'teardown removed something';
    ok !-e "$dir/not-ours.shm", 'a foreign .shm in the root directory goes too';
    ok -e "$dir/notes.txt", 'a file with another extension is left alone';
    ok -d "$dir/keep.shm", 'and a directory named like one is not unlinked';
};

done_testing;
