use v5.14;
use warnings;
no warnings 'once';
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use JSON::PP;

use App::Greple::xlate::Cache;

my $dir = tempdir(CLEANUP => 1);
my $J = JSON::PP->new->utf8->canonical;

sub write_json {
    my($path, $data) = @_;
    open my $fh, '>', $path or die "$path: $!";
    print $fh $J->encode($data);
    close $fh;
}

sub read_json {
    my($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    local $/;
    $J->decode(scalar <$fh>);
}

# 対訳 5 ペアの list 形式キャッシュ
my @PAIRS = map [ "src$_\n" => "trans$_\n" ], 1 .. 5;

subtest 'old list order retention and query API' => sub {
    my $file = "$dir/order.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file);

    is($c->old_size, 5, 'old_size');
    is($c->old_position("src3\n"), 2, 'old_position finds key');
    is($c->old_position("nosuch\n"), undef, 'old_position returns undef');

    my @mid = $c->old_entries_slice(1, 3);
    is_deeply(\@mid, [ @PAIRS[1..3] ], 'slice returns pairs in order');

    my @clamped = $c->old_entries_slice(-5, 100);
    is_deeply(\@clamped, \@PAIRS, 'slice clamps out-of-range bounds');

    my @empty = $c->old_entries_slice(3, 1);
    is_deeply(\@empty, [], 'inverted range is empty');

    # FETCH 済み(saved→current 移動後)でも値が取れる
    $c->access("src2\n");
    my $v = $c->get("src2\n");
    is($v, "trans2\n", 'get moves saved to current');
    my @after = $c->old_entries_slice(1, 1);
    is_deeply(\@after, [ [ "src2\n" => "trans2\n" ] ],
              'old_entries_slice sees fetched values too');

    $c->name = '';   # DESTROY 時の書き出しを抑止
};

subtest 'legacy HASH format has no old order' => sub {
    my $file = "$dir/hash.json";
    write_json($file, +{ map @$_, @PAIRS });
    my $c = App::Greple::xlate::Cache->new(name => $file);
    is($c->old_size, 0, 'HASH format: old order is empty');
    is($c->old_position("src1\n"), undef, 'old_position undef');
    is($c->get("src1\n"), "trans1\n", 'values still readable');
    $c->name = '';
};

subtest 'no warning for accessed-but-unset keys (dryrun case)' => sub {
    my $file = "$dir/dryrun.json";
    write_json($file, [ $PAIRS[0] ]);
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        my $c = App::Greple::xlate::Cache->new(name => $file);
        $c->access("src1\n");
        $c->get("src1\n");                    # hit
        $c->access("newkey\n");
        $c->set("newkey\n" => undef);         # dryrun のミス相当
        $c->update;
        $c->name = '';
    }
    ok(!(grep { /not in cache/ } @warn),
       'no "not in cache" warning') or diag "@warn";
    my $data = read_json($file);
    is_deeply($data, [ $PAIRS[0] ], 'undef entry is silently dropped');
};

subtest 'checkpoint keeps unused entries (no purge)' => sub {
    my $file = "$dir/ckpt.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file);
    # src2 だけアクセスし、新規 1 件を格納
    $c->access("src2\n"); $c->get("src2\n");
    $c->access("new1\n"); $c->set("new1\n" => "NEW1\n");
    $c->checkpoint;
    my $data = read_json($file);
    is_deeply($data,
              [ @PAIRS, [ "new1\n" => "NEW1\n" ] ],
              'checkpoint: all old entries in order + new appended');
    # 最終書き出しは従来通り purge する
    $c->update;
    $data = read_json($file);
    is_deeply($data,
              [ $PAIRS[1], [ "new1\n" => "NEW1\n" ] ],
              'final update still purges unused entries');
    $c->name = '';
};

subtest 'accumulate keeps unused entries even with new translations' => sub {
    my $file = "$dir/accum.json";
    write_json($file, \@PAIRS);
    my $c = App::Greple::xlate::Cache->new(name => $file, accumulate => 1);
    $c->access("src2\n"); $c->get("src2\n");                  # 使用
    $c->access("new1\n"); $c->set("new1\n" => "NEW1\n");      # 新規翻訳あり
    $c->update;
    my $data = read_json($file);
    my %got = map @$_, @$data;
    is(scalar @$data, 6, 'accumulate: all 5 old + 1 new survive');
    is($got{"src4\n"}, "trans4\n", 'unused old entry survived');
    is($got{"new1\n"}, "NEW1\n", 'new entry saved');
    $c->name = '';
};

subtest 'accumulate with no changes skips rewrite' => sub {
    my $file = "$dir/accum2.json";
    write_json($file, \@PAIRS);
    my $mtime_probe = "$dir/probe";
    my $c = App::Greple::xlate::Cache->new(name => $file, accumulate => 1);
    $c->access("src1\n"); $c->get("src1\n");
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        $c->update;
    }
    ok(!(grep { /write cache/ } @warn), 'no rewrite when nothing changed');
    $c->name = '';
};

subtest 'seeding an empty cache' => sub {
    my $seed_file = "$dir/seed-src.json";
    write_json($seed_file, \@PAIRS);
    my $file = "$dir/seeded.json";
    write_json($file, []);          # 空のキャッシュ(saved なし)

    my $c = App::Greple::xlate::Cache->new(name => $file, seed => $seed_file);
    ok($c->seeded, 'seeded flag set');
    is($c->old_size, 5, 'seed entries loaded with order');
    is($c->get("src1\n"), "trans1\n", 'seeded value readable');

    # 全ヒット・新規なしでも update が対象ファイルへ書き出す
    $c->access($_) , $c->get($_) for map $_->[0], @PAIRS;
    $c->update;
    my $data = read_json($file);
    is_deeply($data, \@PAIRS, 'seeded content persisted to target cache');
    $c->name = '';
};

subtest 'seed ignored when cache has entries' => sub {
    my $seed_file = "$dir/seed-src2.json";
    write_json($seed_file, [ [ "other\n" => "OTHER\n" ] ]);
    my $file = "$dir/nonempty.json";
    write_json($file, [ $PAIRS[0] ]);
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, $_[0] };
        my $c = App::Greple::xlate::Cache->new(name => $file,
                                               seed => $seed_file);
        ok(!$c->seeded, 'seeded flag not set');
        is($c->old_position("other\n"), undef, 'seed content not loaded');
        $c->name = '';
    }
    ok((grep { /seed ignored/ } @warn), 'warned about ignored seed');
};

subtest 'seed implies cache creation in auto mode' => sub {
    require App::Greple::xlate;
    local $App::Greple::xlate::current_file = "$dir/newdoc.txt";
    local $App::Greple::xlate::xlate_engine = 'gpt5';
    local $App::Greple::xlate::lang_to = 'EN-US';
    local $App::Greple::xlate::cache_method = 'auto';
    {
        local $App::Greple::xlate::cache_seed = undef;
        is(App::Greple::xlate::cache_file(), undef,
           'auto without seed: no cache for a fresh document');
    }
    {
        local $App::Greple::xlate::cache_seed = "$dir/whatever.json";
        like(App::Greple::xlate::cache_file(), qr/newdoc\.txt\.xlate-gpt5-EN-US\.json$/,
           'auto with seed: cache file is created for a fresh document');
    }
};

subtest 'seeded cache persists even without any access' => sub {
    my $seed_file = "$dir/seed-src3.json";
    write_json($seed_file, \@PAIRS);
    my $file = "$dir/seed-noaccess.json";
    write_json($file, []);
    my $c = App::Greple::xlate::Cache->new(name => $file, seed => $seed_file);
    ok($c->seeded, 'seeded');
    $c->update;    # nothing accessed at all
    my $data = read_json($file);
    is_deeply($data, \@PAIRS, 'seed content persisted despite no access');
    $c->name = '';
};

subtest 'readonly cache never writes' => sub {
    my $file = "$dir/readonly.json";
    write_json($file, [ $PAIRS[0] ]);
    my $c = App::Greple::xlate::Cache->new(name => $file, readonly => 1);
    $c->access("src1\n"); $c->get("src1\n");
    $c->access("new1\n"); $c->set("new1\n" => "NEW1\n");
    $c->checkpoint;
    $c->update;
    my $data = read_json($file);
    is_deeply($data, [ $PAIRS[0] ], 'file unchanged by checkpoint and update');
    $c->name = '';
};

subtest 'pincer retry: outer flank bounds the slice when nearest is missing' => sub {
    my $file = "$dir/pincer.json";
    write_json($file, \@PAIRS);   # src1..src5 in order
    my $c = App::Greple::xlate::Cache->new(name => $file);
    is($c->old_position("not-there\n"), undef, 'nearest flank key missing from old list');
    is($c->old_position("src2\n"), 1, 'outer flank found');
    my @old = $c->old_entries_slice(2, $c->old_size - 1);
    is_deeply([ map $_->[0], @old ], [ "src3\n", "src4\n", "src5\n" ],
              'slice bounded by the outer flank position');
    $c->name = '';
};

done_testing;
