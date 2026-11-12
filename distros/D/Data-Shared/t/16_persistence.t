use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Scalar::Util qw(weaken);
use JSON::PP;
use POSIX qw(_exit);
use Data::Shared qw(shared_compile sharedc_call);

{
    package Data::Shared::PersistentTest;
    our $CALLS = 0;
    sub new {
        my ($class, $path, @args) = @_;
        $CALLS++;
        if (defined $path && !-e $path) {
            open my $fh, '>', $path or die $!;
            print {$fh} 'test storage';
            close $fh or die $!;
        }
        $args[0]{value} = 999 if ref $args[0] eq 'HASH' && $args[0]{mutate};
        return bless { args => \@args }, $class;
    }
    sub answer { 42 }
    sub args { $_[0]{args} }
    $INC{'Data/Shared/PersistentTest.pm'} = __FILE__;
}

sub text_of {
    open my $fh, '<', $_[0] or die $!;
    return do { local $/; <$fh> };
}

sub put_json {
    my ($path, $value) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} JSON::PP->new->canonical->encode($value);
    close $fh or die $!;
}

subtest 'reopen preflights every mount before calling constructors' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount($_, 'Data::Shared::PersistentTest', undef, 32) for qw(first second);
    unlink "$dir/second.shm" or die $!;
    for my $open (
        sub { Data::Shared->open($dir) },
        sub { Data::Shared->new($dir) },
        sub { Data::Shared->open_readonly($dir) },
    ) {
        my $calls = $Data::Shared::PersistentTest::CALLS;
        ok !eval { $open->(); 1 }, 'missing backing file refused';
        like $@, qr/missing backing file.*second\.shm/, 'missing path identified';
        is $Data::Shared::PersistentTest::CALLS, $calls, 'no constructor ran';
        ok !-e "$dir/second.shm", 'file was not recreated';
    }
    my $empty = tempdir(CLEANUP => 1);
    ok !eval { Data::Shared->open($empty); 1 }, 'open requires a manifest';
};

subtest 'manifest revisions reject stale writers before factory execution' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $first = Data::Shared->new($dir);
    my $stale = Data::Shared->open($dir);
    $first->mount('first', 'Data::Shared::PersistentTest', undef, 32);
    my $manifest = text_of("$dir/manifest.json");
    my $called = 0;
    ok !eval { $stale->mount('lost', sub { $called++; Data::Shared::PersistentTest->new }); 1 }, 'stale mutation refused';
    like $@, qr/stale manifest revision/, 'stale error';
    is $called, 0, 'factory not called';
    is text_of("$dir/manifest.json"), $manifest, 'manifest unchanged';
    is_deeply [$stale->mounts], [], 'stale namespace unchanged';
    ok !eval { $stale->unlink_all; 1 }, 'stale root cannot remove shared storage';
    ok !eval { $stale->freeze_all; 1 }, 'stale root cannot freeze a subset of mounts';
    my $fresh = Data::Shared->open($dir);
    $fresh->mount('second', 'Data::Shared::PersistentTest', undef, 32);
    is_deeply [Data::Shared->open($dir)->mounts], [qw(first second)], 'explicit reopen allows next mutation';
};

subtest 'failed publication rolls back namespace and new files' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('old', 'Data::Shared::PersistentTest', undef, 32);
    my $manifest = text_of($root->manifest_path);
    my $generation = $root->{gen};
    {
        no warnings 'redefine';
        local *Data::Shared::_write_manifest = sub { die "injected publication failure\n" };
        ok !eval { $root->mount('new', 'Data::Shared::PersistentTest', undef, 64); 1 }, 'mount failed';
        like $@, qr/injected publication failure/, 'original failure propagated';
        is_deeply [$root->mounts], ['old'], 'mount not published locally';
        ok !-e $root->dir . '/new.shm', 'new file removed';
        ok !eval { $root->unmount('old'); 1 }, 'unmount failed';
        is_deeply [$root->mounts], ['old'], 'unmount rolled back';
    }
    is text_of($root->manifest_path), $manifest, 'old manifest retained';
    is $root->{gen}, $generation, 'failed changes did not invalidate generation';
    is sharedc_call($root, shared_compile('/old'), 'answer'), 42, 'original handle usable';
};

subtest 'configuration is copied and cycles are rejected before construction' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    my $args = [undef, { value => 17 }];
    $root->mount('copy', { spec => 'Data::Shared::PersistentTest', args => $args });
    $args->[1]{value} = 99;
    my $again = Data::Shared->open($root->dir);
    is $again->handle('/copy')->args->[0]{value}, 17, 'manifest owns a snapshot';
    my $cyclic = []; push @$cyclic, $cyclic;
    my $calls = $Data::Shared::PersistentTest::CALLS;
    ok !eval { $root->mount('cycle', 'Data::Shared::PersistentTest', undef, $cyclic); 1 }, 'cycle refused';
    like $@, qr/cyclic mount configuration/, 'cycle error';
    is $Data::Shared::PersistentTest::CALLS, $calls, 'constructor not called';
    pop @$cyclic;
    my $handle = $root->mount('mutating', { spec => 'Data::Shared::PersistentTest',
        args => [undef, { mutate => 1, value => 17 }] });
    is $handle->args->[0]{value}, 999, 'constructor can modify its own arguments';
    my $data = decode_json(text_of($root->manifest_path));
    my ($saved) = grep { $_->{name} eq 'mutating' } @{ $data->{mounts} };
    is $saved->{spec}{args}[1]{value}, 17, 'constructor did not modify persisted configuration';
};

subtest 'legacy manifests and malformed schemas' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    $root->mount('old', 'Data::Shared::PersistentTest', undef, 32);
    my $data = decode_json(text_of($root->manifest_path));
    delete $data->{revision};
    put_json($root->manifest_path, $data);
    my $legacy = Data::Shared->open($root->dir);
    $legacy->mount('new', 'Data::Shared::PersistentTest', undef, 32);
    is decode_json(text_of($root->manifest_path))->{revision}, 1, 'legacy revision advances from zero';
    for my $invalid (
        [], { version => 2, mounts => [] }, { version => 1, mounts => {} },
        { version => 1, mounts => [{ name => 'bad', spec => 'Data::Shared::PersistentTest', args => {} }] },
    ) {
        put_json($root->manifest_path, $invalid);
        my $calls = $Data::Shared::PersistentTest::CALLS;
        ok !eval { Data::Shared->open($root->dir); 1 }, 'invalid manifest refused';
        is $Data::Shared::PersistentTest::CALLS, $calls, 'no constructors on invalid manifest';
    }
};

subtest 'compiled paths do not own native handles' => sub {
    my $path = shared_compile('/handle');
    my $weak;
    {
        my $root = Data::Shared->new;
        my $handle = $root->mount('handle', Data::Shared::PersistentTest->new);
        $weak = $handle; weaken($weak);
        is sharedc_call($root, $path, 'answer'), 42, 'compiled binding populated';
    }
    ok !defined $weak, 'root destruction released the bound handle';
    my $root = Data::Shared->new;
    {
        my $handle = $root->mount('handle', Data::Shared::PersistentTest->new);
        $weak = $handle; weaken($weak);
        sharedc_call($root, $path, 'answer');
    }
    $root->unmount('handle');
    ok !defined $weak, 'unmount released handle while compiled path remains alive';
};

subtest 'failed atomic rename cleans its temporary file' => sub {
    my $base = tempdir(CLEANUP => 1);
    my $destination = "$base/directory";
    mkdir $destination or die $!;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    ok !eval { Data::Shared::Manifest::write($destination, {}); 1 }, 'directory cannot be replaced by manifest';
    like $@, qr/cannot rename manifest/, 'publication failure explained';
    is_deeply [glob("$base/.manifest-*")], [], 'temporary file removed';
    is_deeply \@warnings, [], 'cleanup emitted no extra warnings';
};

subtest 'concurrent manifest writers commit once and reject the stale update' => sub {
    local $SIG{ALRM} = sub { die "manifest writers timed out\n" };
    alarm 20;
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    pipe my $ready_r, my $ready_w or die $!;
    pipe my $go_r, my $go_w or die $!;
    # PERL_UNICODE puts a :utf8 layer on new handles, which sysread and syswrite refuse.
    binmode $_, ':raw' for $ready_r, $ready_w, $go_r, $go_w;
    my @pids;
    for my $name (qw(a b)) {
        my $pid = fork(); die $! unless defined $pid;
        if (!$pid) {
            $SIG{ALRM} = sub { _exit(124) }; alarm 15;
            close $ready_r; close $go_w;
            my $child = Data::Shared->open($root->dir);
            syswrite($ready_w, 'r') == 1 or _exit(1);
            sysread($go_r, my $go, 1) == 1 or _exit(1);
            my $ok = eval { $child->mount($name, 'Data::Shared::PersistentTest', undef, 32); 1 };
            _exit($ok ? 0 : $@ =~ /stale manifest revision/ ? 3 : 1);
        }
        push @pids, $pid;
    }
    close $ready_w; close $go_r;
    my $ready = '';
    while (length $ready < 2) {
        sysread($ready_r, my $next, 2 - length $ready) > 0 or die 'writer exited before barrier';
        $ready .= $next;
    }
    syswrite($go_w, 'gg') == 2 or die $!;
    close $go_w;
    my @status;
    for my $pid (@pids) { waitpid $pid, 0; push @status, $? >> 8 }
    is_deeply [sort @status], [0, 3], 'one commit and one explicit stale failure';
    my $again = Data::Shared->open($root->dir);
    my @names = $again->mounts;
    is scalar(@names), 1, 'one mount published';
    my @files = glob($root->dir . '/*.shm');
    is scalar(@files), 1, 'rejected writer did not create another backing file';
    alarm 0;
};

subtest 'Unicode configuration survives revision checks and reopen' => sub {
    my $root = Data::Shared->new(tempdir(CLEANUP => 1));
    my $name = chr(945);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $root->mount($name, 'Data::Shared::PersistentTest', undef, 32);
    $root->mount('other', 'Data::Shared::PersistentTest', undef, 32);
    my $again = Data::Shared->open($root->dir);
    is_deeply [$again->mounts], ['other', $name], 'names preserved';
    is_deeply \@warnings, [], 'manifest writes emit no encoding warnings';
};

subtest 'a manifest the facade refuses names the store it came from' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $root = Data::Shared->new($dir);
    $root->mount('old', 'Data::Shared::PersistentTest', undef, 32);
    my $path = $root->manifest_path;
    my $good = decode_json(text_of($path));

    # Manifest::read compares names raw; only the replay canonicalises both to 'old'.
    my $dup = decode_json(text_of($path));
    push @{ $dup->{mounts} }, { %{ $dup->{mounts}[0] }, name => '/old/' };
    put_json($path, $dup);
    ok !eval { Data::Shared->open($dir); 1 }, 'a duplicate under another spelling is refused';
    like $@, qr/\AData::Shared: failed to replay manifest '\Q$path\E': .*duplicate mount 'old'/s,
        'under the documented prefix, naming the store';

    SKIP: {
        skip 'composite backends unavailable', 2
            unless eval { Data::Shared->new(tempdir(CLEANUP => 1))
                ->mount('p', ['hashmap:ss', 8, ['sortedset:strings', { max => 8 }]]); 1 };
        my $bad = { %$good, mounts => [ { args => [], name => 'u', spec =>
            ['hashmap:ss', 64, ['sortedset:strings',
                { max => 8, set => "$dir/s.set", keys => "$dir/s.keys" }],
             { max_children => 4 }] } ] };
        put_json($path, $bad);
        ok !eval { Data::Shared->open($dir); 1 }, 'a child spec naming its own path is refused';
        like $@, qr/\AData::Shared: failed to replay manifest '\Q$path\E': .*cannot name its own backing path/s,
            'under the same prefix';
    }
};

done_testing;
