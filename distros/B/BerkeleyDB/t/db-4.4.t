#!./perl -w

use strict ;

use lib 't' ;
use BerkeleyDB;
use Test::More ;
use util ;

plan(skip_all => "this needs Berkeley DB 4.4.x or better\n" )
    if $BerkeleyDB::db_version < 4.4;

plan tests => 12;

{
    title "Testing compact";

    # db->db_compact

    my $Dfile;
    my $lex = new LexFile $Dfile ;
    my ($k, $v) ;
    ok my $db = new BerkeleyDB::Btree -Filename => $Dfile,
				     -Flags    => DB_CREATE ;

    # create some data
    my %data =  (
		"red"	=> 2,
		"green"	=> "house",
		"blue"	=> "sea",
		) ;

    my $ret = 0 ;
    while (($k, $v) = each %data) {
        $ret += $db->db_put($k, $v) ;
    }
    ok $ret == 0, "  Created some data" ;

    my $key;
    my $end;
    my %hash;
    $hash{compact_filepercent} = 20;

    ok $db->compact("red", "green", \%hash, 0, $end) == 0, "  Compacted ok";

    if (0)
    {
        diag "end at $end";
        for my $key (sort keys %hash)
        {
            diag "[$key][$hash{$key}]\n";
        }
    }

    ok $db->compact() == 0, "  Compacted ok";
}

{
    title "Testing lg_filemode";

    # switch umask
    my $omask = umask 077;

    use Cwd ;
    my $cwd = cwd() ;
    my $home = "$cwd/test-log-perms" ;
    my $data_file = "data.db" ;
    ok my $lexD = new LexDir($home) ;
    my $env = new BerkeleyDB::Env
        -Home        => $home,
        -LogFileMode => 0641, # something weird
        -Flags       => DB_CREATE|DB_INIT_TXN|DB_INIT_LOG|
                        DB_INIT_MPOOL|DB_INIT_LOCK ;
    ok $env ;

    # something crazy small
    #is($env->set_lg_max(1024), 0);

    ok my $txn = $env->txn_begin() ;

    my %hash ;
    ok tie %hash, 'BerkeleyDB::Hash', -Filename => $data_file,
                                       -Flags     => DB_CREATE ,
                                       -Env       => $env,
                                       -Txn       => $txn  ;


    $hash{"abc"} = 123 ;
    $hash{"def"} = 456 ;

    $txn->txn_commit() ;

    ok(my ($log) = glob("$home/log.*"), "log.* file is present");

    SKIP: {
        skip "POSIX only", 1 if $^O eq 'MSWin32';

        my (undef, undef, $perms) = stat $log;

        is($perms, 0100641, "log perms match");
    };

    # meh this one is gonna be harder to test because it would entail
    # spurring the database into generating a second log file

    # $env->set_lg_filemode(0777);
    # $env->txn_checkpoint(0, 0);
    # $txn = $env->txn_begin;
    # $txn->Txn(tied %hash);
    # for my $i (0..10_000) {
    #     $hash{$i} = $i x 10;
    # }

    # $txn->txn_commit;
    # $env->txn_checkpoint(0, 0);

    #diag(`ls -l $home`);

    untie %hash ;

    undef $txn ;
    undef $env ;
    umask $omask;
}
