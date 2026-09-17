use Test2::V0;
use App::Pasar;
use File::Temp qw(tempdir);

{
    my $stdout = '';
    open my $fh, '>', \$stdout or die $!;
    my $oldfh = select $fh;
    eval {
        App::Pasar::main '-l', 't/data/dummy.asar';
    };
    select $oldfh;
    is $@, '';
    is $stdout, <<~'_EOT_';
        DIR   dir1
        FILE  dir1/file1.txt  9
        DIR   dir2
        FILE  dir2/file2.png  182
        FILE  dir2/file3.txt  3
        FILE  emptyfile.txt  0
        FILE  file0.txt  13
        _EOT_
}

{
    my $tmpdir = tempdir 'app-pasar-test.XXXXXX', TMPDIR => 1, CLEANUP => 1;
    eval {
        App::Pasar::main '-x', 't/data/dummy.asar', "$tmpdir";
    };
    is $@, '';
    ok -d "$tmpdir/dir1";
    ok -f "$tmpdir/dir1/file1.txt";
    is -s "$tmpdir/dir1/file1.txt", 9;
    ok -d "$tmpdir/dir2";
    ok -f "$tmpdir/dir2/file2.png";
    is -s "$tmpdir/dir2/file2.png", 182;
    ok -f "$tmpdir/dir2/file3.txt";
    is -s "$tmpdir/dir2/file3.txt", 3;
    ok -f "$tmpdir/emptyfile.txt";
    is -s "$tmpdir/emptyfile.txt", 0;
    ok -f "$tmpdir/file0.txt";
    is -s "$tmpdir/file0.txt", 13;
}

done_testing;
