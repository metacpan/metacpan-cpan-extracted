#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use POSIX ();
use Time::HiRes ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

my $have_sharedmem = eval { require Hash::SharedMem; Hash::SharedMem->import(qw(shash_open shash_set shash_get)); 1 };
my $have_lmdb      = eval { require LMDB_File; LMDB_File->import(':flags'); 1 };
my $have_bdb       = eval { require BerkeleyDB; BerkeleyDB->import(); 1 };
my $have_cfm       = eval { require Cache::FastMmap; 1 };

my $N = $ARGV[0] || 10_000;
my $TMPDIR = tempdir(CLEANUP => 1);
my $LMDB_MAPSIZE = 128 * 1024 * 1024;
my $seq = 0;

sub tmppath { "$TMPDIR/b" . $seq++ }
sub commify { my $n = reverse $_[0]; $n =~ s/(\d{3})(?=\d)/$1,/g; scalar reverse $n }

sub cleanup_shm {
    for my $ref (@_) {
        if (ref $ref eq 'ARRAY') {
            my ($map_ref, $path) = @$ref;
            undef $$map_ref;
            unlink $path if defined $path;
        }
    }
}

sub mk_lmdb {
    my $dir = tmppath();
    mkdir $dir;
    my $env = LMDB::Env->new($dir, {
        mapsize => $LMDB_MAPSIZE, mode => 0600,
        flags => LMDB_File::MDB_NOSYNC() | LMDB_File::MDB_NOMETASYNC()
               | LMDB_File::MDB_NORDAHEAD() | LMDB_File::MDB_WRITEMAP(),
    });
    return ($dir, $env);
}

sub mk_bdb {
    my $dir = tmppath();
    mkdir $dir;
    my $env = BerkeleyDB::Env->new(
        -Home  => $dir,
        -Flags => BerkeleyDB::DB_CREATE() | BerkeleyDB::DB_INIT_MPOOL()
                | BerkeleyDB::DB_PRIVATE(),
        -Cachesize => 128 * 1024 * 1024,
    );
    return ($dir, $env);
}

print "=" x 70, "\n";
print "Data::HashMap::Shared vs competitors  (N=$N)\n";
print "Contenders: Shared::II/SS/SI";
print ", Hash::SharedMem" if $have_sharedmem;
print ", LMDB_File"       if $have_lmdb;
print ", BerkeleyDB"      if $have_bdb;
print ", Cache::FastMmap"  if $have_cfm;
print "\n", "=" x 70, "\n";

# =====================================================================
# Section 1: Integer key -> Integer value
# =====================================================================

print "\n", "=" x 70, "\n";
print "INTEGER KEY -> INTEGER VALUE  ($N entries)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT\n";
print "-" x 70, "\n";
{
    my $p = tmppath(); my $m = Data::HashMap::Shared::II->new($p, $N);
    my %bench;
    $bench{'Shared::II'} = sub {
        shm_ii_clear $m;
        for my $i (1 .. $N) { shm_ii_put $m, $i, $i; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->put($i, $i); }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{$i} = $i; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m; unlink $p;
}

print "\n", "-" x 70, "\n";
print "LOOKUP (all hits)\n";
print "-" x 70, "\n";
{
    my $p = tmppath();
    my $m = Data::HashMap::Shared::II->new($p, $N);
    for my $i (1 .. $N) { shm_ii_put $m, $i, $i; }

    my ($ld, $le);
    if ($have_lmdb) {
        ($ld, $le) = mk_lmdb();
        my $txn = $le->BeginTxn; my $db = $txn->OpenDB;
        for my $i (1 .. $N) { $db->put($i, $i); }
        $txn->commit;
    }

    my (%bh, $bd, $be);
    if ($have_bdb) {
        ($bd, $be) = mk_bdb();
        tie %bh, "BerkeleyDB::Hash",
            -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $be;
        for my $i (1 .. $N) { $bh{$i} = $i; }
    }

    my %bench;
    $bench{'Shared::II'} = sub {
        for my $i (1 .. $N) { my $v = shm_ii_get $m, $i; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my $txn = $le->BeginTxn(LMDB_File::MDB_RDONLY());
            my $db = $txn->OpenDB;
            for my $i (1 .. $N) { my $v = $db->get($i); }
            $txn->abort;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            for my $i (1 .. $N) { my $v = $bh{$i}; }
        };
    }
    cmpthese(-3, \%bench);

    undef $m; unlink $p;
    if ($have_bdb) { untie %bh; undef $be; rmtree $bd; }
    if ($have_lmdb) { undef $le; rmtree $ld; }
}

print "\n", "-" x 70, "\n";
print "INCREMENT (atomic incr vs get+put)\n";
print "-" x 70, "\n";
{
    my $p = tmppath(); my $m = Data::HashMap::Shared::II->new($p, $N);
    my %bench;
    $bench{'Shared::II'} = sub {
        shm_ii_clear $m;
        for my $i (1 .. $N) { shm_ii_incr $m, $i; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) {
                my $v = $db->get($i) // 0;
                $db->put($i, $v + 1);
            }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{"$i"} = ($h{"$i"} // 0) + 1; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m; unlink $p;
}

# =====================================================================
# Section 2: Integer key -> String value
# =====================================================================

print "\n", "=" x 70, "\n";
print "INTEGER KEY -> STRING VALUE  ($N entries)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT\n";
print "-" x 70, "\n";
{
    my %bench;
    my $p_is = tmppath(); my $m_is = Data::HashMap::Shared::IS->new($p_is, $N);
    $bench{'Shared::IS'} = sub {
        shm_is_clear $m_is;
        for my $i (1 .. $N) { shm_is_put $m_is, $i, "val$i"; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->put($i, "val$i"); }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{$i} = "val$i"; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m_is; unlink $p_is;
}

print "\n", "-" x 70, "\n";
print "LOOKUP (all hits)\n";
print "-" x 70, "\n";
{
    my $p = tmppath();
    my $m = Data::HashMap::Shared::IS->new($p, $N);
    for my $i (1 .. $N) { shm_is_put $m, $i, "val$i"; }

    my ($ld, $le);
    if ($have_lmdb) {
        ($ld, $le) = mk_lmdb();
        my $txn = $le->BeginTxn; my $db = $txn->OpenDB;
        for my $i (1 .. $N) { $db->put($i, "val$i"); }
        $txn->commit;
    }

    my (%bh, $bd, $be);
    if ($have_bdb) {
        ($bd, $be) = mk_bdb();
        tie %bh, "BerkeleyDB::Hash",
            -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $be;
        for my $i (1 .. $N) { $bh{$i} = "val$i"; }
    }

    my %bench;
    $bench{'Shared::IS'} = sub {
        for my $i (1 .. $N) { my $v = shm_is_get $m, $i; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my $txn = $le->BeginTxn(LMDB_File::MDB_RDONLY());
            my $db = $txn->OpenDB;
            for my $i (1 .. $N) { my $v = $db->get($i); }
            $txn->abort;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            for my $i (1 .. $N) { my $v = $bh{$i}; }
        };
    }
    cmpthese(-3, \%bench);

    undef $m; unlink $p;
    if ($have_bdb) { untie %bh; undef $be; rmtree $bd; }
    if ($have_lmdb) { undef $le; rmtree $ld; }
}

# =====================================================================
# Section 3: String key -> String value
# =====================================================================

print "\n", "=" x 70, "\n";
print "STRING KEY -> STRING VALUE  ($N entries)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT\n";
print "-" x 70, "\n";
{
    my %bench;
    my $p_ss = tmppath(); my $m_ss = Data::HashMap::Shared::SS->new($p_ss, $N);
    $bench{'Shared::SS'} = sub {
        shm_ss_clear $m_ss;
        for my $i (1 .. $N) { shm_ss_put $m_ss, "key$i", "val$i"; }
    };
    if ($have_sharedmem) {
        $bench{'SharedMem'} = sub {
            my $d = tmppath(); mkdir $d;
            my $sh = shash_open($d, "rwc");
            for my $i (1 .. $N) { shash_set($sh, "key$i", "val$i"); }
            undef $sh; rmtree $d;
        };
    }
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->put("key$i", "val$i"); }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{"key$i"} = "val$i"; }
            untie %h; undef $env; rmtree $d;
        };
    }
    if ($have_cfm) {
        $bench{'FastMmap'} = sub {
            my $p = tmppath();
            my $c = Cache::FastMmap->new(
                share_file => $p, init_file => 1, raw_values => 1,
                cache_size => ($N * 32 > 512*1024 ? $N * 32 : 512*1024),
            );
            for my $i (1 .. $N) { $c->set("key$i", "val$i"); }
            undef $c; unlink $p;
        };
    }
    cmpthese(-3, \%bench);
    undef $m_ss; unlink $p_ss;
}

print "\n", "-" x 70, "\n";
print "LOOKUP (all hits)\n";
print "-" x 70, "\n";
{
    my $p = tmppath();
    my $m = Data::HashMap::Shared::SS->new($p, $N);
    for my $i (1 .. $N) { shm_ss_put $m, "key$i", "val$i"; }

    my ($hsm, $hsm_dir);
    if ($have_sharedmem) {
        $hsm_dir = tmppath(); mkdir $hsm_dir;
        $hsm = shash_open($hsm_dir, "rwc");
        for my $i (1 .. $N) { shash_set($hsm, "key$i", "val$i"); }
    }

    my ($ld, $le);
    if ($have_lmdb) {
        ($ld, $le) = mk_lmdb();
        my $txn = $le->BeginTxn; my $db = $txn->OpenDB;
        for my $i (1 .. $N) { $db->put("key$i", "val$i"); }
        $txn->commit;
    }

    my (%bh, $bd, $be);
    if ($have_bdb) {
        ($bd, $be) = mk_bdb();
        tie %bh, "BerkeleyDB::Hash",
            -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $be;
        for my $i (1 .. $N) { $bh{"key$i"} = "val$i"; }
    }

    my $cfm;
    if ($have_cfm) {
        my $cp = tmppath();
        $cfm = Cache::FastMmap->new(
            share_file => $cp, init_file => 1,
            cache_size => ($N * 32 > 512*1024 ? $N * 32 : 512*1024),
        );
        for my $i (1 .. $N) { $cfm->set("key$i", "val$i"); }
    }

    my %bench;
    $bench{'Shared::SS'} = sub {
        for my $i (1 .. $N) { my $v = shm_ss_get $m, "key$i"; }
    };
    if ($have_sharedmem) {
        $bench{'SharedMem'} = sub {
            for my $i (1 .. $N) { my $v = shash_get($hsm, "key$i"); }
        };
    }
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my $txn = $le->BeginTxn(LMDB_File::MDB_RDONLY());
            my $db = $txn->OpenDB;
            for my $i (1 .. $N) { my $v = $db->get("key$i"); }
            $txn->abort;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            for my $i (1 .. $N) { my $v = $bh{"key$i"}; }
        };
    }
    if ($have_cfm) {
        $bench{'FastMmap'} = sub {
            for my $i (1 .. $N) { my $v = $cfm->get("key$i"); }
        };
    }
    cmpthese(-3, \%bench);

    undef $m; unlink $p;
    undef $hsm; rmtree $hsm_dir if defined $hsm_dir;
    undef $cfm;
    if ($have_bdb) { untie %bh; undef $be; rmtree $bd; }
    if ($have_lmdb) { undef $le; rmtree $ld; }
}

print "\n", "-" x 70, "\n";
print "DELETE (insert + delete)\n";
print "-" x 70, "\n";
{
    my %bench;
    my $p_ssd = tmppath(); my $m_ssd = Data::HashMap::Shared::SS->new($p_ssd, $N);
    $bench{'Shared::SS'} = sub {
        shm_ss_clear $m_ssd;
        for my $i (1 .. $N) { shm_ss_put $m_ssd, "key$i", "val$i"; }
        for my $i (1 .. $N) { shm_ss_remove $m_ssd, "key$i"; }
    };
    if ($have_sharedmem) {
        $bench{'SharedMem'} = sub {
            my $d = tmppath(); mkdir $d;
            my $sh = shash_open($d, "rwc");
            for my $i (1 .. $N) { shash_set($sh, "key$i", "val$i"); }
            for my $i (1 .. $N) { shash_set($sh, "key$i", undef); }
            undef $sh; rmtree $d;
        };
    }
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->put("key$i", "val$i"); }
            $txn->commit;
            $txn = $env->BeginTxn; $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->del("key$i"); }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{"key$i"} = "val$i"; }
            for my $i (1 .. $N) { delete $h{"key$i"}; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m_ssd; unlink $p_ssd;
}

# =====================================================================
# Section 4: String key -> Integer value  (atomic counters)
# =====================================================================

print "\n", "=" x 70, "\n";
print "STRING KEY -> INTEGER VALUE  ($N entries)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT\n";
print "-" x 70, "\n";
{
    my %bench;
    my $p_si = tmppath(); my $m_si = Data::HashMap::Shared::SI->new($p_si, $N);
    $bench{'Shared::SI'} = sub {
        shm_si_clear $m_si;
        for my $i (1 .. $N) { shm_si_put $m_si, "key$i", $i; }
    };
    if ($have_sharedmem) {
        $bench{'SharedMem'} = sub {
            my $d = tmppath(); mkdir $d;
            my $sh = shash_open($d, "rwc");
            for my $i (1 .. $N) { shash_set($sh, "key$i", pack("q", $i)); }
            undef $sh; rmtree $d;
        };
    }
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) { $db->put("key$i", $i); }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{"key$i"} = $i; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m_si; unlink $p_si;
}

print "\n", "-" x 70, "\n";
print "ATOMIC INCREMENT (Shared::SI has native incr; others: get+put)\n";
print "-" x 70, "\n";
{
    my $p_si2 = tmppath(); my $m_si2 = Data::HashMap::Shared::SI->new($p_si2, $N);
    my %bench;
    $bench{'Shared::SI'} = sub {
        shm_si_clear $m_si2;
        for my $i (1 .. $N) { shm_si_incr $m_si2, "key$i"; }
    };
    if ($have_lmdb) {
        $bench{'LMDB'} = sub {
            my ($d, $env) = mk_lmdb();
            my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
            for my $i (1 .. $N) {
                my $v = $db->get("key$i") // 0;
                $db->put("key$i", $v + 1);
            }
            $txn->commit;
            undef $env; rmtree $d;
        };
    }
    if ($have_bdb) {
        $bench{'BerkeleyDB'} = sub {
            my ($d, $env) = mk_bdb();
            my %h; tie %h, "BerkeleyDB::Hash",
                -Filename => "b.db", -Flags => BerkeleyDB::DB_CREATE(), -Env => $env;
            for my $i (1 .. $N) { $h{"key$i"} = ($h{"key$i"} // 0) + 1; }
            untie %h; undef $env; rmtree $d;
        };
    }
    cmpthese(-3, \%bench);
    undef $m_si2; unlink $p_si2;
}

# =====================================================================
# Section 5: Cross-process read latency
# =====================================================================

print "\n", "=" x 70, "\n";
print "CROSS-PROCESS: parent writes, child reads ($N SS entries)\n";
print "=" x 70, "\n\n";

{
    my $xp_path = tmppath();
    my $m_xp = Data::HashMap::Shared::SS->new($xp_path, $N);
    for my $i (1 .. $N) { shm_ss_put $m_xp, "key$i", "val$i"; }

    my @cases;
    push @cases, ['Shared::SS', sub {
        my $m2 = Data::HashMap::Shared::SS->new($xp_path, $N);
        for my $i (1 .. $N) { my $v = shm_ss_get $m2, "key$i"; }
    }];

    my ($xp_hsm, $xp_hsm_dir);
    if ($have_sharedmem) {
        $xp_hsm_dir = tmppath(); mkdir $xp_hsm_dir;
        $xp_hsm = shash_open($xp_hsm_dir, "rwc");
        for my $i (1 .. $N) { shash_set($xp_hsm, "key$i", "val$i"); }
        push @cases, ['SharedMem', sub {
            my $sh2 = shash_open($xp_hsm_dir, "r");
            for my $i (1 .. $N) { my $v = shash_get($sh2, "key$i"); }
        }];
    }

    my ($xp_lmdb_d, $xp_lmdb_env);
    if ($have_lmdb) {
        ($xp_lmdb_d, $xp_lmdb_env) = mk_lmdb();
        my $txn = $xp_lmdb_env->BeginTxn; my $db = $txn->OpenDB;
        for my $i (1 .. $N) { $db->put("key$i", "val$i"); }
        $txn->commit;
        push @cases, ['LMDB', sub {
            my $env2 = LMDB::Env->new($xp_lmdb_d, {
                mapsize => $LMDB_MAPSIZE, mode => 0600,
                flags => LMDB_File::MDB_NOSYNC() | LMDB_File::MDB_NOMETASYNC()
                       | LMDB_File::MDB_NORDAHEAD() | LMDB_File::MDB_WRITEMAP(),
            });
            my $txn = $env2->BeginTxn(LMDB_File::MDB_RDONLY());
            my $db = $txn->OpenDB;
            for my $i (1 .. $N) { my $v = $db->get("key$i"); }
            $txn->abort;
        }];
    }

    for my $case (@cases) {
        my ($label, $reader) = @$case;
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $rd;
            my $t0 = Time::HiRes::time();
            $reader->();
            my $elapsed = Time::HiRes::time() - $t0;
            printf $wr "%.6f\n", $elapsed;
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        my $elapsed = <$rd>;
        close $rd;
        waitpid($pid, 0);
        chomp $elapsed;
        printf "  %-14s  %8.3f ms  (%s reads/sec)\n",
            $label,
            $elapsed * 1000,
            commify(int($N / $elapsed));
    }

    undef $m_xp; unlink $xp_path;
    undef $xp_hsm; rmtree $xp_hsm_dir if defined $xp_hsm_dir;
    if ($have_lmdb) { undef $xp_lmdb_env; rmtree $xp_lmdb_d; }
}

# ---- Cross-process writes ----

print "\n", "=" x 70, "\n";
print "CROSS-PROCESS: concurrent writes from 2 processes ($N SS entries)\n";
print "=" x 70, "\n\n";

{
    my @cases;

    push @cases, ['Shared::SS', sub {
        my $p = tmppath();
        my $m = Data::HashMap::Shared::SS->new($p, $N * 2);
        my $half = int($N / 2);
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $rd;
            my $c = Data::HashMap::Shared::SS->new($p, $N * 2);
            my $t0 = Time::HiRes::time();
            for my $i (1 .. $half) { shm_ss_put $c, "b$i", "val$i"; }
            printf $wr "%.6f\n", Time::HiRes::time() - $t0;
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        my $t0 = Time::HiRes::time();
        for my $i (1 .. $half) { shm_ss_put $m, "a$i", "val$i"; }
        my $parent_t = Time::HiRes::time() - $t0;
        my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
        undef $m; unlink $p;
        return ($parent_t > $child_t ? $parent_t : $child_t, $N);
    }];

    if ($have_sharedmem) {
        push @cases, ['SharedMem', sub {
            my $d = tmppath(); mkdir $d;
            my $sh = shash_open($d, "rwc");
            my $half = int($N / 2);
            pipe(my $rd, my $wr) or die "pipe: $!";
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $rd;
                my $c = shash_open($d, "rwc");
                my $t0 = Time::HiRes::time();
                for my $i (1 .. $half) { shash_set($c, "b$i", "val$i"); }
                printf $wr "%.6f\n", Time::HiRes::time() - $t0;
                close $wr;
                POSIX::_exit(0);
            }
            close $wr;
            my $t0 = Time::HiRes::time();
            for my $i (1 .. $half) { shash_set($sh, "a$i", "val$i"); }
            my $parent_t = Time::HiRes::time() - $t0;
            my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
            undef $sh; rmtree $d;
            return ($parent_t > $child_t ? $parent_t : $child_t, $N);
        }];
    }

    if ($have_lmdb) {
        push @cases, ['LMDB', sub {
            my ($d, $env) = mk_lmdb();
            my $half = int($N / 2);
            pipe(my $rd, my $wr) or die "pipe: $!";
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $rd;
                my $env2 = LMDB::Env->new($d, {
                    mapsize => $LMDB_MAPSIZE, mode => 0600,
                    flags => LMDB_File::MDB_NOSYNC() | LMDB_File::MDB_NOMETASYNC()
                           | LMDB_File::MDB_NORDAHEAD() | LMDB_File::MDB_WRITEMAP(),
                });
                my $t0 = Time::HiRes::time();
                for my $i (1 .. $half) {
                    my $txn = $env2->BeginTxn; my $db = $txn->OpenDB;
                    $db->put("b$i", "val$i"); $txn->commit;
                }
                printf $wr "%.6f\n", Time::HiRes::time() - $t0;
                close $wr;
                POSIX::_exit(0);
            }
            close $wr;
            my $t0 = Time::HiRes::time();
            for my $i (1 .. $half) {
                my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
                $db->put("a$i", "val$i"); $txn->commit;
            }
            my $parent_t = Time::HiRes::time() - $t0;
            my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
            undef $env; rmtree $d;
            return ($parent_t > $child_t ? $parent_t : $child_t, $N);
        }];
    }

    for my $case (@cases) {
        my ($label, $bench) = @$case;
        my ($elapsed, $count) = $bench->();
        printf "  %-14s  %8.3f ms  (%s writes/sec)\n",
            $label, $elapsed * 1000, commify(int($count / $elapsed));
    }
}

# ---- Cross-process mixed (50% reads, 50% writes) ----

print "\n", "=" x 70, "\n";
print "CROSS-PROCESS: mixed 50/50 read/write ($N SS entries)\n";
print "=" x 70, "\n\n";

{
    my @cases;

    push @cases, ['Shared::SS', sub {
        my $p = tmppath();
        my $m = Data::HashMap::Shared::SS->new($p, $N * 2);
        for my $i (1 .. $N) { shm_ss_put $m, "key$i", "val$i"; }
        my $half = int($N / 2);
        pipe(my $rd, my $wr) or die "pipe: $!";
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            close $rd;
            my $c = Data::HashMap::Shared::SS->new($p, $N * 2);
            my $t0 = Time::HiRes::time();
            # child: reads
            for my $i (1 .. $N) { my $v = shm_ss_get $c, "key$i"; }
            printf $wr "%.6f\n", Time::HiRes::time() - $t0;
            close $wr;
            POSIX::_exit(0);
        }
        close $wr;
        my $t0 = Time::HiRes::time();
        # parent: writes (overwrite existing keys)
        for my $i (1 .. $N) { shm_ss_put $m, "key$i", "upd$i"; }
        my $parent_t = Time::HiRes::time() - $t0;
        my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
        undef $m; unlink $p;
        return ($parent_t > $child_t ? $parent_t : $child_t, $N * 2);
    }];

    if ($have_sharedmem) {
        push @cases, ['SharedMem', sub {
            my $d = tmppath(); mkdir $d;
            my $sh = shash_open($d, "rwc");
            for my $i (1 .. $N) { shash_set($sh, "key$i", "val$i"); }
            pipe(my $rd, my $wr) or die "pipe: $!";
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $rd;
                my $c = shash_open($d, "r");
                my $t0 = Time::HiRes::time();
                for my $i (1 .. $N) { my $v = shash_get($c, "key$i"); }
                printf $wr "%.6f\n", Time::HiRes::time() - $t0;
                close $wr;
                POSIX::_exit(0);
            }
            close $wr;
            my $t0 = Time::HiRes::time();
            for my $i (1 .. $N) { shash_set($sh, "key$i", "upd$i"); }
            my $parent_t = Time::HiRes::time() - $t0;
            my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
            undef $sh; rmtree $d;
            return ($parent_t > $child_t ? $parent_t : $child_t, $N * 2);
        }];
    }

    if ($have_lmdb) {
        push @cases, ['LMDB', sub {
            my ($d, $env) = mk_lmdb();
            { my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
              for my $i (1 .. $N) { $db->put("key$i", "val$i"); }
              $txn->commit; }
            pipe(my $rd, my $wr) or die "pipe: $!";
            my $pid = fork // die "fork: $!";
            if ($pid == 0) {
                close $rd;
                my $env2 = LMDB::Env->new($d, {
                    mapsize => $LMDB_MAPSIZE, mode => 0600,
                    flags => LMDB_File::MDB_NOSYNC() | LMDB_File::MDB_NOMETASYNC()
                           | LMDB_File::MDB_NORDAHEAD() | LMDB_File::MDB_WRITEMAP(),
                });
                my $t0 = Time::HiRes::time();
                for my $i (1 .. $N) {
                    my $txn = $env2->BeginTxn(LMDB_File::MDB_RDONLY());
                    my $db = $txn->OpenDB;
                    my $v = $db->get("key$i");
                    $txn->abort;
                }
                printf $wr "%.6f\n", Time::HiRes::time() - $t0;
                close $wr;
                POSIX::_exit(0);
            }
            close $wr;
            my $t0 = Time::HiRes::time();
            for my $i (1 .. $N) {
                my $txn = $env->BeginTxn; my $db = $txn->OpenDB;
                $db->put("key$i", "upd$i"); $txn->commit;
            }
            my $parent_t = Time::HiRes::time() - $t0;
            my $child_t = <$rd>; close $rd; waitpid($pid, 0); chomp $child_t;
            undef $env; rmtree $d;
            return ($parent_t > $child_t ? $parent_t : $child_t, $N * 2);
        }];
    }

    for my $case (@cases) {
        my ($label, $bench) = @$case;
        my ($elapsed, $count) = $bench->();
        printf "  %-14s  %8.3f ms  (%s ops/sec)\n",
            $label, $elapsed * 1000, commify(int($count / $elapsed));
    }
}

# =====================================================================
# Section 6: LRU cache performance
# =====================================================================

print "\n", "=" x 70, "\n";
print "LRU CACHE  ($N entries, max_size=$N)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT (fill to capacity)\n";
print "-" x 70, "\n";
{
    my %bench;
    my $lp1 = tmppath(); my $lm1 = Data::HashMap::Shared::II->new($lp1, $N);
    my $lp2 = tmppath(); my $lm2 = Data::HashMap::Shared::II->new($lp2, $N, $N);
    my $lp3 = tmppath(); my $lm3 = Data::HashMap::Shared::SS->new($lp3, $N);
    my $lp4 = tmppath(); my $lm4 = Data::HashMap::Shared::SS->new($lp4, $N, $N);
    $bench{'II plain'} = sub {
        shm_ii_clear $lm1;
        for my $i (1 .. $N) { shm_ii_put $lm1, $i, $i; }
    };
    $bench{'II LRU'} = sub {
        shm_ii_clear $lm2;
        for my $i (1 .. $N) { shm_ii_put $lm2, $i, $i; }
    };
    $bench{'SS plain'} = sub {
        shm_ss_clear $lm3;
        for my $i (1 .. $N) { shm_ss_put $lm3, "key$i", "val$i"; }
    };
    $bench{'SS LRU'} = sub {
        shm_ss_clear $lm4;
        for my $i (1 .. $N) { shm_ss_put $lm4, "key$i", "val$i"; }
    };
    if ($have_cfm) {
        $bench{'FastMmap'} = sub {
            my $p = tmppath();
            my $c = Cache::FastMmap->new(
                share_file => $p, init_file => 1, raw_values => 1,
                cache_size => ($N * 32 > 512*1024 ? $N * 32 : 512*1024),
            );
            for my $i (1 .. $N) { $c->set("key$i", "val$i"); }
            undef $c; unlink $p;
        };
    }
    cmpthese(-3, \%bench);
    undef $lm1; unlink $lp1; undef $lm2; unlink $lp2;
    undef $lm3; unlink $lp3; undef $lm4; unlink $lp4;
}

print "\n", "-" x 70, "\n";
print "LOOKUP (LRU promotes on read vs plain lock-free seqlock)\n";
print "-" x 70, "\n";
{
    my $p1 = tmppath(); my $m1 = Data::HashMap::Shared::II->new($p1, $N);
    my $p2 = tmppath(); my $m2 = Data::HashMap::Shared::II->new($p2, $N, $N);
    my $p3 = tmppath(); my $m3 = Data::HashMap::Shared::SS->new($p3, $N);
    my $p4 = tmppath(); my $m4 = Data::HashMap::Shared::SS->new($p4, $N, $N);
    for my $i (1 .. $N) {
        shm_ii_put $m1, $i, $i;
        shm_ii_put $m2, $i, $i;
        shm_ss_put $m3, "key$i", "val$i";
        shm_ss_put $m4, "key$i", "val$i";
    }

    my ($cfm_obj, $cfm_path);
    if ($have_cfm) {
        $cfm_path = tmppath();
        $cfm_obj = Cache::FastMmap->new(
            share_file => $cfm_path, init_file => 1, raw_values => 1,
            cache_size => ($N * 32 > 512*1024 ? $N * 32 : 512*1024),
        );
        for my $i (1 .. $N) { $cfm_obj->set("key$i", "val$i"); }
    }

    my %bench;
    $bench{'II plain'} = sub {
        for my $i (1 .. $N) { my $v = shm_ii_get $m1, $i; }
    };
    $bench{'II LRU'} = sub {
        for my $i (1 .. $N) { my $v = shm_ii_get $m2, $i; }
    };
    $bench{'SS plain'} = sub {
        for my $i (1 .. $N) { my $v = shm_ss_get $m3, "key$i"; }
    };
    $bench{'SS LRU'} = sub {
        for my $i (1 .. $N) { my $v = shm_ss_get $m4, "key$i"; }
    };
    if ($have_cfm) {
        $bench{'FastMmap'} = sub {
            for my $i (1 .. $N) { my $v = $cfm_obj->get("key$i"); }
        };
    }
    cmpthese(-3, \%bench);

    undef $m1; unlink $p1;
    undef $m2; unlink $p2;
    undef $m3; unlink $p3;
    undef $m4; unlink $p4;
    undef $cfm_obj; unlink $cfm_path if defined $cfm_path;
}

print "\n", "-" x 70, "\n";
print "EVICTION (insert 2*N into max_size=N, steady-state eviction)\n";
print "-" x 70, "\n";
{
    my %bench;
    my $ep1 = tmppath(); my $em1 = Data::HashMap::Shared::II->new($ep1, 2 * $N, $N);
    my $ep2 = tmppath(); my $em2 = Data::HashMap::Shared::SS->new($ep2, 2 * $N, $N);
    $bench{'II LRU'} = sub {
        shm_ii_clear $em1;
        for my $i (1 .. 2 * $N) { shm_ii_put $em1, $i, $i; }
    };
    $bench{'SS LRU'} = sub {
        shm_ss_clear $em2;
        for my $i (1 .. 2 * $N) { shm_ss_put $em2, "key$i", "val$i"; }
    };
    if ($have_cfm) {
        $bench{'FastMmap'} = sub {
            my $p = tmppath();
            my $c = Cache::FastMmap->new(
                share_file => $p, init_file => 1, raw_values => 1,
                cache_size => ($N * 32 > 512*1024 ? $N * 32 : 512*1024),
            );
            for my $i (1 .. 2 * $N) { $c->set("key$i", "val$i"); }
            undef $c; unlink $p;
        };
    }
    cmpthese(-3, \%bench);
    undef $em1; unlink $ep1; undef $em2; unlink $ep2;
}

# =====================================================================
# Section 7: TTL overhead and flush performance
# =====================================================================

print "\n", "=" x 70, "\n";
print "TTL  ($N entries, ttl=60s)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "INSERT (plain vs TTL-enabled)\n";
print "-" x 70, "\n";
{
    my %bench;
    my $tp1 = tmppath(); my $tm1 = Data::HashMap::Shared::II->new($tp1, $N);
    my $tp2 = tmppath(); my $tm2 = Data::HashMap::Shared::II->new($tp2, $N, 0, 60);
    my $tp3 = tmppath(); my $tm3 = Data::HashMap::Shared::II->new($tp3, $N, 0, 60);
    my $tp4 = tmppath(); my $tm4 = Data::HashMap::Shared::SS->new($tp4, $N);
    my $tp5 = tmppath(); my $tm5 = Data::HashMap::Shared::SS->new($tp5, $N, 0, 60);
    $bench{'II plain'} = sub {
        shm_ii_clear $tm1;
        for my $i (1 .. $N) { shm_ii_put $tm1, $i, $i; }
    };
    $bench{'II TTL'} = sub {
        shm_ii_clear $tm2;
        for my $i (1 .. $N) { shm_ii_put $tm2, $i, $i; }
    };
    $bench{'II put_ttl'} = sub {
        shm_ii_clear $tm3;
        for my $i (1 .. $N) { shm_ii_put_ttl $tm3, $i, $i, 30; }
    };
    $bench{'SS plain'} = sub {
        shm_ss_clear $tm4;
        for my $i (1 .. $N) { shm_ss_put $tm4, "key$i", "val$i"; }
    };
    $bench{'SS TTL'} = sub {
        shm_ss_clear $tm5;
        for my $i (1 .. $N) { shm_ss_put $tm5, "key$i", "val$i"; }
    };
    cmpthese(-3, \%bench);
    undef $tm1; unlink $tp1; undef $tm2; unlink $tp2; undef $tm3; unlink $tp3;
    undef $tm4; unlink $tp4; undef $tm5; unlink $tp5;
}

print "\n", "-" x 70, "\n";
print "LOOKUP (plain seqlock vs TTL expiry check)\n";
print "-" x 70, "\n";
{
    my $p1 = tmppath(); my $m1 = Data::HashMap::Shared::II->new($p1, $N);
    my $p2 = tmppath(); my $m2 = Data::HashMap::Shared::II->new($p2, $N, 0, 60);
    my $p3 = tmppath(); my $m3 = Data::HashMap::Shared::SS->new($p3, $N);
    my $p4 = tmppath(); my $m4 = Data::HashMap::Shared::SS->new($p4, $N, 0, 60);
    for my $i (1 .. $N) {
        shm_ii_put $m1, $i, $i;
        shm_ii_put $m2, $i, $i;
        shm_ss_put $m3, "key$i", "val$i";
        shm_ss_put $m4, "key$i", "val$i";
    }

    cmpthese(-3, {
        'II plain' => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m1, $i; } },
        'II TTL'   => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m2, $i; } },
        'SS plain' => sub { for my $i (1 .. $N) { my $v = shm_ss_get $m3, "key$i"; } },
        'SS TTL'   => sub { for my $i (1 .. $N) { my $v = shm_ss_get $m4, "key$i"; } },
    });

    undef $m1; unlink $p1;
    undef $m2; unlink $p2;
    undef $m3; unlink $p3;
    undef $m4; unlink $p4;
}

print "\n", "-" x 70, "\n";
print "FLUSH_EXPIRED (full scan vs partial, all entries expired)\n";
print "-" x 70, "\n";
{
    my $p1 = tmppath();
    my $m1 = Data::HashMap::Shared::II->new($p1, $N, 0, 1);
    my $p2 = tmppath();
    my $m2 = Data::HashMap::Shared::II->new($p2, $N, 0, 1);
    my $p3 = tmppath();
    my $m3 = Data::HashMap::Shared::SS->new($p3, $N, 0, 1);
    for my $i (1 .. $N) {
        shm_ii_put $m1, $i, $i;
        shm_ii_put $m2, $i, $i;
        shm_ss_put $m3, "key$i", "val$i";
    }
    sleep 2;

    my $t0 = Time::HiRes::time();
    my $f1 = shm_ii_flush_expired $m1;
    my $t1 = Time::HiRes::time() - $t0;

    $t0 = Time::HiRes::time();
    my ($total, $rounds) = (0, 0);
    while (1) {
        my ($f, $done) = shm_ii_flush_expired_partial $m2, 1000;
        $total += $f;
        $rounds++;
        last if $done;
    }
    my $t2 = Time::HiRes::time() - $t0;

    $t0 = Time::HiRes::time();
    my $f3 = shm_ss_flush_expired $m3;
    my $t3 = Time::HiRes::time() - $t0;

    printf "  II flush_expired:          %s entries in %.3f ms  (%s entries/sec)\n",
        commify($f1), $t1 * 1000, commify(int($f1 / $t1));
    printf "  II flush_expired_partial:  %s entries in %.3f ms  (%d rounds of 1000)  (%s entries/sec)\n",
        commify($total), $t2 * 1000, $rounds, commify(int($total / $t2));
    printf "  SS flush_expired:          %s entries in %.3f ms  (%s entries/sec)\n",
        commify($f3), $t3 * 1000, commify(int($f3 / $t3));

    undef $m1; unlink $p1;
    undef $m2; unlink $p2;
    undef $m3; unlink $p3;
}

# =====================================================================
# Section 8: LRU + TTL combined
# =====================================================================

print "\n", "=" x 70, "\n";
print "LRU + TTL COMBINED  ($N entries, max_size=$N, ttl=60s)\n";
print "=" x 70, "\n";

print "\n", "-" x 70, "\n";
print "LOOKUP (plain vs LRU vs TTL vs LRU+TTL)\n";
print "-" x 70, "\n";
{
    my $p1 = tmppath(); my $m1 = Data::HashMap::Shared::II->new($p1, $N);
    my $p2 = tmppath(); my $m2 = Data::HashMap::Shared::II->new($p2, $N, $N);
    my $p3 = tmppath(); my $m3 = Data::HashMap::Shared::II->new($p3, $N, 0, 60);
    my $p4 = tmppath(); my $m4 = Data::HashMap::Shared::II->new($p4, $N, $N, 60);
    for my $i (1 .. $N) {
        shm_ii_put $m1, $i, $i;
        shm_ii_put $m2, $i, $i;
        shm_ii_put $m3, $i, $i;
        shm_ii_put $m4, $i, $i;
    }

    cmpthese(-3, {
        'plain'   => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m1, $i; } },
        'LRU'     => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m2, $i; } },
        'TTL'     => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m3, $i; } },
        'LRU+TTL' => sub { for my $i (1 .. $N) { my $v = shm_ii_get $m4, $i; } },
    });

    undef $m1; unlink $p1;
    undef $m2; unlink $p2;
    undef $m3; unlink $p3;
    undef $m4; unlink $p4;
}

print "\nDone.\n";
