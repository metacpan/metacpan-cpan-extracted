use strict;
use warnings;
use Test::More;
use File::Temp 'tmpnam';

use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# A creator killed between ftruncate() and header init leaves a full-size,
# all-zero (magic==0) file.  new() must recover it instead of bricking the
# path, but must never clobber a valid or foreign file.  Covers BOTH
# file-backed create paths: reqrep_create (Str) and reqrep_create_int (Int).

# ---------------------------------------------------------------------------
# Str variant: Data::ReqRep::Shared / Data::ReqRep::Shared::Client
# ---------------------------------------------------------------------------
{
    my $p = tmpnam();

    # Learn the on-disk size for this geometry.
    { my $s = Data::ReqRep::Shared->new($p, 8, 4, 64); }
    my $total = -s $p;
    unlink $p;

    # 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
    {
        open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
        is(-s $p, $total, "Str: abandoned file is $total bytes (a killed creator's ftruncate)");
        my $srv = eval { Data::ReqRep::Shared->new($p, 8, 4, 64) };
        ok($srv, "Str: new() recovers an abandoned mid-init file instead of bricking") or diag $@;
      SKIP: {
            skip "no handle", 3 unless $srv;
            ok($srv->is_empty, "Str: recovered channel starts empty");
            my $cli = Data::ReqRep::Shared::Client->new($p);
            my $id = $cli->send("hello");
            my ($req, $rid) = $srv->recv;
            is($req, "hello", "Str: recovered channel works (send/recv)");
            $srv->reply($rid, "world");
            is($cli->get($id), "world", "Str: recovered channel works (reply/get)");
        }
        undef $srv; unlink $p;
    }

    # 2. No clobber: a file with nonzero (foreign) magic still errors.
    {
        open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
        my $srv = eval { Data::ReqRep::Shared->new($p, 8, 4, 64) };
        ok(!$srv, "Str: new() refuses a foreign nonzero-magic file (no clobber)");
        like($@, qr/invalid/i, "  ... reporting an invalid file");
        undef $srv; unlink $p;
    }

    # 3. No recovery for the wrong size: magic==0 but size != total still errors.
    {
        open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
        my $srv = eval { Data::ReqRep::Shared->new($p, 8, 4, 64) };
        ok(!$srv, "Str: new() refuses an uninitialized file of the wrong size");
        undef $srv; unlink $p;
    }

    # 4. A valid file is attached, never re-initialized (its data survives).
    {
        {
            my $a = Data::ReqRep::Shared->new($p, 8, 4, 64);
            my $acli = Data::ReqRep::Shared::Client->new($p);
            $acli->send("keep");   # left queued, unconsumed
        }
        my $r = Data::ReqRep::Shared->new($p, 8, 4, 64);
        is($r->size, 1, "Str: reopening a valid file preserves queued data");
        my ($req, $rid) = $r->recv;
        is($req, "keep", "Str: ... and the request content survives reopen");
        undef $r; unlink $p;
    }
}

# ---------------------------------------------------------------------------
# Int variant: Data::ReqRep::Shared::Int / Data::ReqRep::Shared::Int::Client
# ---------------------------------------------------------------------------
{
    my $p = tmpnam();

    # Learn the on-disk size for this geometry.
    { my $s = Data::ReqRep::Shared::Int->new($p, 8, 4); }
    my $total = -s $p;
    unlink $p;

    # 1. Recovery: an abandoned all-zero file of exactly $total bytes is re-initialized.
    {
        open my $f, '>', $p or die $!; truncate $f, $total or die $!; close $f;
        is(-s $p, $total, "Int: abandoned file is $total bytes (a killed creator's ftruncate)");
        my $srv = eval { Data::ReqRep::Shared::Int->new($p, 8, 4) };
        ok($srv, "Int: new() recovers an abandoned mid-init file instead of bricking") or diag $@;
      SKIP: {
            skip "no handle", 3 unless $srv;
            ok($srv->is_empty, "Int: recovered channel starts empty");
            my $cli = Data::ReqRep::Shared::Int::Client->new($p);
            my $id = $cli->send(42);
            my ($val, $rid) = $srv->recv;
            is($val, 42, "Int: recovered channel works (send/recv)");
            $srv->reply($rid, 99);
            is($cli->get($id), 99, "Int: recovered channel works (reply/get)");
        }
        undef $srv; unlink $p;
    }

    # 2. No clobber: a file with nonzero (foreign) magic still errors.
    {
        open my $f, '>', $p or die $!; print $f "XXXX"; truncate $f, $total or die $!; close $f;
        my $srv = eval { Data::ReqRep::Shared::Int->new($p, 8, 4) };
        ok(!$srv, "Int: new() refuses a foreign nonzero-magic file (no clobber)");
        like($@, qr/invalid/i, "  ... reporting an invalid file");
        undef $srv; unlink $p;
    }

    # 3. No recovery for the wrong size: magic==0 but size != total still errors.
    {
        open my $f, '>', $p or die $!; truncate $f, $total + 8 or die $!; close $f;
        my $srv = eval { Data::ReqRep::Shared::Int->new($p, 8, 4) };
        ok(!$srv, "Int: new() refuses an uninitialized file of the wrong size");
        undef $srv; unlink $p;
    }

    # 4. A valid file is attached, never re-initialized (its data survives).
    {
        {
            my $a = Data::ReqRep::Shared::Int->new($p, 8, 4);
            my $acli = Data::ReqRep::Shared::Int::Client->new($p);
            $acli->send(777);   # left queued, unconsumed
        }
        my $r = Data::ReqRep::Shared::Int->new($p, 8, 4);
        is($r->size, 1, "Int: reopening a valid file preserves queued data");
        my ($val, $rid) = $r->recv;
        is($val, 777, "Int: ... and the request content survives reopen");
        undef $r; unlink $p;
    }
}

# 5. A magic==0 file of the right size but with NON-zero data (not a fresh
#    ftruncate) is NOT recovered -- recovery only re-inits a provably-empty file.
{
    my $p = tmpnam();
    { my $s = Data::ReqRep::Shared->new($p, 8, 4, 64); }
    my $total = -s $p; unlink $p;
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $srv = eval { Data::ReqRep::Shared->new($p, 8, 4, 64) };
    ok(!$srv, "Str: new() refuses a magic==0 file that is not all-zero (no clobber)");
    undef $srv; unlink $p;
}
{
    my $p = tmpnam();
    { my $s = Data::ReqRep::Shared::Int->new($p, 8, 4); }
    my $total = -s $p; unlink $p;
    open my $zfh, '>', $p or die $!; truncate $zfh, $total or die $!; close $zfh;
    open $zfh, '+<', $p or die $!; seek $zfh, $total - 1, 0; print $zfh "\x01"; close $zfh;
    my $srv = eval { Data::ReqRep::Shared::Int->new($p, 8, 4) };
    ok(!$srv, "Int: new() refuses a magic==0 file that is not all-zero (no clobber)");
    undef $srv; unlink $p;
}

done_testing;
