use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use List::Util ();   # called fully-qualified below: PDL (loaded later, conditionally) exports
                      # its own sum/min/max, and importing both into this package would collide
use Data::NDArray::Shared;

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/frozen.nda";

# 3x4 f64 array (12 elements); build a known pattern and one overwritten cell.
my @expected = map { $_ * 1.5 } 0 .. 11;
$expected[6] = 99.5;   # flat index 6 == multi-index (1,2) in a (3,4) row-major array

# ---- producer: build, populate, freeze ----
{
    my $a = Data::NDArray::Shared->new($path, "f64", 3, 4);
    ok !$a->frozen,   'freshly created array is not frozen';
    ok !$a->readonly, 'read-write handle is not read-only';

    $a->set_flat($_, $_ * 1.5) for 0 .. 11;
    $a->set(1, 2, 99.5);                       # multi-index write -> flat 6
    is_deeply $a->to_list, \@expected, 'producer data matches the expected pattern';
    my $s = $a->sum;

    $a->freeze;
    ok $a->frozen,   'frozen after ->freeze';
    ok $a->readonly, 'freezing handle becomes read-only';
    is $a->sum, $s, 'sum unchanged by freeze';

    # ---- every mutator croaks on the (now read-only) producer handle ----
    ok !eval { $a->set(0, 0, 1); 1 },              'set on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'set frozen message';
    ok !eval { $a->set_flat(0, 1); 1 },            'set_flat on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'set_flat frozen message';
    ok !eval { $a->fill(1); 1 },                   'fill on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'fill frozen message';
    ok !eval { $a->zero; 1 },                      'zero on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'zero frozen message';
    ok !eval { $a->reshape(4, 3); 1 },             'reshape on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'reshape frozen message';
    ok !eval { $a->add_scalar(1); 1 },             'add_scalar on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'add_scalar frozen message';
    ok !eval { $a->mul_scalar(2); 1 },             'mul_scalar on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'mul_scalar frozen message';
    ok !eval { $a->update_from_bytes("x" x 96); 1 }, 'update_from_bytes on frozen handle croaks';
    like $@, qr/frozen|read-only/,                 'update_from_bytes frozen message';
    {
        my $other = Data::NDArray::Shared->new(undef, "f64", 12);
        ok !eval { $a->add($other); 1 },           'add on frozen handle croaks';
        like $@, qr/frozen|read-only/,             'add frozen message';
        ok !eval { $a->subtract($other); 1 },      'subtract on frozen handle croaks';
        like $@, qr/frozen|read-only/,             'subtract frozen message';
        ok !eval { $a->multiply($other); 1 },      'multiply on frozen handle croaks';
        like $@, qr/frozen|read-only/,             'multiply frozen message';
    }
    ok !eval { $a->freeze; 1 },                    'freeze on an already-read-only handle croaks';
    like $@, qr/read-only/,                        'freeze-again message';

    # data must be byte-for-byte unchanged after every refused mutator
    is_deeply $a->to_list, \@expected, 'data unchanged after every refused mutator';
}

# ---- post-wrlock seal re-check: a SECOND handle that never called freeze
#      itself (its own local readonly flag is still false) must still be
#      refused, because the check that matters is the shared hdr->sealed
#      re-read taken AFTER the write lock, not just the local fast path ----
{
    my $rpath = "$dir/race.nda";
    my $A = Data::NDArray::Shared->new($rpath, "f64", 2, 2);
    my $B = Data::NDArray::Shared->new($rpath, "f64", 2, 2);   # 2nd read-write handle, same file
    $B->freeze;                                                # B knows it is sealed
    ok !$A->readonly, "A's own local readonly flag was never set (freeze happened via B)";
    ok !eval { $A->set(0, 0, 1); 1 },
        'A is still refused: the post-wrlock seal re-check catches it';
    like $@, qr/frozen|read-only/, 'post-wrlock seal re-check message';
}

# ---- consumer: read-only attach (the shipped artifact) ----
{
    my $ro = Data::NDArray::Shared->new_readonly($path);
    isa_ok $ro, 'Data::NDArray::Shared';
    ok $ro->frozen,   'read-only view reports frozen';
    ok $ro->readonly, 'read-only view reports readonly';

    # every read method on the read-only (PROT_READ) handle -- a method that
    # still takes the rwlock here would SIGSEGV.
    is $ro->ndim, 2, 'ndim readable read-only';
    is $ro->size, 12, 'size readable read-only';
    is $ro->itemsize, 8, 'itemsize readable read-only';
    is $ro->dtype, 'f64', 'dtype readable read-only';
    is_deeply [ $ro->shape ], [ 3, 4 ], 'shape readable read-only';
    is_deeply [ $ro->strides ], [ 4, 1 ], 'strides readable read-only';

    for my $e (0 .. 11) {
        is $ro->get_flat($e), $expected[$e], "get_flat($e) matches producer via read-only view";
    }
    is $ro->get(1, 2), 99.5, 'get(1,2) matches the overwritten cell via read-only view';
    is $ro->get(0, 0), 0,    'get(0,0) matches via read-only view';
    is $ro->get(2, 3), $expected[11], 'get(2,3) (last element) matches via read-only view';

    is_deeply $ro->to_list, \@expected, 'to_list matches producer via read-only view';

    my $exp_sum = List::Util::sum(@expected);
    my $exp_min = List::Util::min(@expected);
    my $exp_max = List::Util::max(@expected);
    is $ro->sum, $exp_sum, 'sum works read-only (lock-free)';
    ok abs($ro->mean - $exp_sum / 12) < 1e-9, 'mean works read-only (lock-free)';
    is $ro->min, $exp_min, 'min works read-only (lock-free)';
    is $ro->max, $exp_max, 'max works read-only (lock-free)';

    is length($ro->buffer), 12 * 8, 'buffer length works read-only (lock-free)';
    is_deeply [ unpack "d*", $ro->buffer ], \@expected, 'buffer bytes match read-only';

    my $st = $ro->stats;
    is $st->{frozen},   1, 'stats.frozen set';
    is $st->{readonly}, 1, 'stats.readonly set';
    is $st->{dtype}, 'f64', 'stats.dtype read-only';
    is $st->{size}, 12, 'stats.size read-only';
    is_deeply $st->{shape}, [ 3, 4 ], 'stats.shape read-only';

    is $ro->path, $path, 'path readable read-only';
    is $ro->memfd, -1, 'memfd readable read-only (file-backed => -1)';
    eval { $ro->sync };
    ok !$@, 'sync on read-only view is a silent no-op';

    # bounds/arg-count errors still croak correctly (lock-free) on a read-only view
    ok !eval { $ro->get(0); 1 }, 'get wrong-ndim still croaks read-only';
    like $@, qr/expected 2 indices/, 'get wrong-ndim message read-only';
    ok !eval { $ro->get(5, 0); 1 }, 'get out-of-range still croaks read-only';
    like $@, qr/out of range/, 'get out-of-range message read-only';
    ok !eval { $ro->get_flat(12); 1 }, 'get_flat out-of-range still croaks read-only';

    # every mutator still refused via the read-only handle too
    ok !eval { $ro->set(0, 0, 1); 1 },   'set on read-only view croaks';
    like $@, qr/read-only/,              'set read-only message';
    ok !eval { $ro->set_flat(0, 1); 1 }, 'set_flat on read-only view croaks';
    ok !eval { $ro->fill(1); 1 },        'fill on read-only view croaks';
    ok !eval { $ro->zero; 1 },           'zero on read-only view croaks';
    ok !eval { $ro->reshape(4, 3); 1 },  'reshape on read-only view croaks';
    ok !eval { $ro->add_scalar(1); 1 },  'add_scalar on read-only view croaks';
    ok !eval { $ro->mul_scalar(2); 1 },  'mul_scalar on read-only view croaks';
    ok !eval { $ro->update_from_bytes("x" x 96); 1 }, 'update_from_bytes on read-only view croaks';
    ok !eval { $ro->freeze; 1 },         'freeze on read-only view croaks';
    like $@, qr/read-only/,              'freeze-on-readonly message';

    # ---- PDL interop on a frozen/read-only handle (skip gracefully if PDL is absent) ----
  SKIP: {
        my $have_pdl = eval { require PDL; PDL->import; 1 };
        skip 'PDL not installed', 6 unless $have_pdl;

        # as_pdl_alias MUST refuse: a zero-copy alias over a PROT_READ mapping
        # cannot be made safe against every PDL write path (verified: PDL's own
        # read-only flag blocks .=/+=/inplace ops, but $piddle->set(...) pokes
        # the buffer directly and bypasses it) -- so it must croak, not crash.
        ok !eval { $ro->as_pdl_alias; 1 }, 'as_pdl_alias on a frozen handle croaks (not crash)';
        like $@, qr/frozen|read-only/, 'as_pdl_alias frozen message';

        # to_pdl is the safe (copying) alternative and must still work read-only.
        my $p = $ro->to_pdl;
        isa_ok $p, 'PDL', 'to_pdl still works on a read-only handle';
        is_deeply [ $p->dims ], [ 4, 3 ], 'to_pdl dims are reverse(shape)';
        # READ from the piddle -- assert no fault, values match the producer.
        my $ok = 1;
        for my $i (0 .. 2) { for my $j (0 .. 3) {
            $ok = 0 if $p->at($j, $i) != $ro->get($i, $j);
        } }
        ok $ok, 'to_pdl values read back correctly (no fault) and match get()';
    }

    # ---- two independent read-only views of the same file, concurrently ----
    {
        my $a = Data::NDArray::Shared->new_readonly($path);
        my $b = Data::NDArray::Shared->new_readonly($path);
        is $a->get_flat(6), 99.5, 'view a reads the shared file';
        is $b->get_flat(6), 99.5, 'view b reads the same shared file concurrently';
        is $a->sum, $b->sum, 'two read-only views agree';
    }
}

# ---- add/subtract/multiply: a MUTABLE array combined with a FROZEN other
#      (lock-free read of the frozen other's PROT_READ mapping) ----
{
    my $bpath = "$dir/other.nda";
    my $Bw = Data::NDArray::Shared->new($bpath, "f64", 4, 3);   # size 12
    $Bw->fill(2);
    $Bw->freeze;
    my $Bro = Data::NDArray::Shared->new_readonly($bpath);

    my $M = Data::NDArray::Shared->new(undef, "f64", 2, 6);     # size 12, same dtype
    $M->fill(10);
    $M->add($Bro);                                              # must not lock Bro's PROT_READ map
    is_deeply $M->to_list, [ (12) x 12 ], 'add() from a frozen (read-only) other works lock-free';

    my $M2 = Data::NDArray::Shared->new(undef, "f64", 2, 6);
    $M2->fill(10);
    $M2->subtract($Bro);
    is_deeply $M2->to_list, [ (8) x 12 ], 'subtract() from a frozen other works lock-free';

    my $M3 = Data::NDArray::Shared->new(undef, "f64", 2, 6);
    $M3->fill(10);
    $M3->multiply($Bro);
    is_deeply $M3->to_list, [ (20) x 12 ], 'multiply() from a frozen other works lock-free';

    # the reverse direction (mutating INTO the frozen receiver) is still refused
    ok !eval { $Bro->add($M); 1 }, 'add() INTO a frozen receiver still croaks';
    like $@, qr/frozen|read-only/, 'add-into-frozen message';
}

# ---- refuse a read-write reopen of a sealed file (new() and new_from_fd()) ----
ok !eval { Data::NDArray::Shared->new($path, "f64", 3, 4); 1 },
    'read-write reopen of a sealed file is refused';
like $@, qr/frozen|read-only/, 'read-write reopen message';

{
    open my $fh, '<', $path or die "open $path: $!";
    my $fd = fileno $fh;
    ok !eval { Data::NDArray::Shared->new_from_fd($fd); 1 },
        'new_from_fd on a sealed file is refused';
    like $@, qr/frozen|read-only/, 'new_from_fd-on-sealed message';
    close $fh;
}

# ---- new_readonly rejects a non-frozen file ----
{
    my $u = "$dir/unsealed.nda";
    { my $a = Data::NDArray::Shared->new($u, "f64", 4); $a->set_flat(0, 1); }
    ok !eval { Data::NDArray::Shared->new_readonly($u); 1 },
        'new_readonly on an unsealed file croaks';
    like $@, qr/not frozen/, 'new_readonly-not-frozen message';
}

# ---- new_readonly error paths ----
ok !eval { Data::NDArray::Shared->new_readonly("$dir/does-not-exist.nda"); 1 },
    'new_readonly on a missing path croaks';
like $@, qr/open|No such/, 'new_readonly-missing message';
ok !eval { Data::NDArray::Shared->new_readonly(undef); 1 },
    'new_readonly requires a path';
like $@, qr/required/, 'new_readonly-undef message';

done_testing;
