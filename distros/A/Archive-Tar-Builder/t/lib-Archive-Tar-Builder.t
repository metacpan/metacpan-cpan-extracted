#!/usr/bin/perl

# Copyright (c) 2019 cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use ExtUtils::testlib;
use FindBin;

use Cwd        ();
use File::Temp ();
use File::Path ();
use IPC::Open3 ();
use Symbol     ();
use Errno;

use Archive::Tar::Builder ();

use Test::More tests => 74;
use Test::Exception;

sub find_tar {
    my @PATH     = qw( /usr/local/bin /usr/bin /bin );
    my @PROGRAMS = qw( gtar ustar star bsdtar tar );

    foreach my $program (@PROGRAMS) {
        foreach my $dir (@PATH) {
            my $name = "$dir/$program";

            return $name if -x $name;
        }
    }

    die('Could not locate a tar binary');
}

sub is_bsd_tar {
    my ($tar) = @_;
    my $is_bsd_tar = 0;

    open( my $in,  '<', '/dev/null' ) or die("Unable to open /dev/null for reading: $!");
    open( my $out, '>', '/dev/null' ) or die("Unable to open /dev/null for writing: $!");

    my $err = Symbol::gensym();

    my $pid = IPC::Open3::open3( $in, $out, $err, $tar, '--help' );

    close $in;
    close $out;

    while ( my $line = readline($err) ) {
        chomp $line;
        $is_bsd_tar = 1 if $line =~ /^usage: tar .*crtux/;
    }

    close $err;

    waitpid( $pid, 0 ) or die("Unable to waitpid() on $pid: $!");

    return $is_bsd_tar;
}

sub find_unused_ids {
    my ( $uid, $gid );

    for ( $uid = 99999; getpwuid($uid); $uid-- ) { }
    for ( $gid = 99999; getgrgid($gid); $gid-- ) { }

    return ( $uid, $gid );
}

sub build_tree {
    my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );
    my $file   = "$tmpdir/foo/exclude.txt";

    File::Path::mkpath("$tmpdir/foo/bar/baz/foo/cats");
    File::Path::mkpath("$tmpdir/foo/poop");
    File::Path::mkpath("$tmpdir/foo/cats/meow");
    File::Path::mkpath("$tmpdir/home/prrr/1327342027.M926735P26547V000000000000FD00I0000000001888287_0.one.two.threefour.five.S=2486:2.");

    open( my $fh, '>', $file ) or die("Unable to open $file for writing: $!");
    print {$fh} "cats\n";
    close $fh;

    my $long   = 'bleh' x 50;
    my $subdir = "$tmpdir/$long/$long";
    $file = "$subdir/thingie.txt";

    File::Path::mkpath($subdir);

    open( $fh, '>', $file ) or die("Unable to open $file for writing: $!");
    print {$fh} "Meow\n";
    close $fh;

    return $tmpdir;
}

my $badfile = '/dev/null/impossible';
my $tar     = find_tar();

{
    my $builder = Archive::Tar::Builder->new;

    eval { $builder->archive(); };

    like( $@ => qr/No paths to archive specified/, '$builder->archive() dies if no paths are specified' );

    eval { $builder->archive('foo'); };

    like( $@ => qr/No file handle set/, '$builder->archive() dies if no file handle is set' );

    eval { $builder->archive_as( 'foo' => 'bar' ); };

    like( $@ => qr/No file handle set/, '$builder->archive_as() dies if no file handle is set' );
}

SKIP: {
    skip( 'Cannot test permissions failures as root', 2 ) if $< == 0;

    my $tmp = File::Temp::tempdir( 'CLEANUP' => 1 );
    my $dir = "$tmp/foo";

    mkdir( $dir, 0000 );

    my $builder = Archive::Tar::Builder->new( 'quiet' => 1 );

    open( my $fh, '>', '/dev/null' ) or die("Unable to open /dev/null: $!");

    $builder->set_handle($fh);
    $builder->archive($tmp);

    eval { $builder->finish(); };

    like( $@ => qr/^Delayed nonzero exit/, '$builder->finish() still die()s with "quiet" but not "ignore_errors" for non-fatals' );

    undef $@;

    $builder = Archive::Tar::Builder->new(
        'quiet'         => 1,
        'ignore_errors' => 1
    );

    $builder->set_handle($fh);
    $builder->archive($tmp);

    eval { $builder->finish(); };

    ok( !$@, '$builder->finish() does not die() if "ignore_errors" is set for non-fatals' );

    chmod( 0600, $dir );
}

#
# Test external functionality
#
{
    my $oldpwd = Cwd::getcwd();
    my $tmpdir = build_tree();

    chdir($tmpdir) or die("Unable to chdir() to $tmpdir: $!");

    my $archive = Archive::Tar::Builder->new;

    my %paths = (
        'foo'  => 'foo',
        'bar'  => 'foo',
        'baz'  => 'foo',
        'home' => 'home'
    );

    #
    # Test Archive::Tar::Builder's ability to exclude files
    #
    $archive->exclude_from_file("$tmpdir/foo/exclude.txt");
    $archive->exclude('baz');

    ok( $archive->is_excluded("$tmpdir/baz"),           '$archive->is_excluded() works when excluding added with $archive->exclude()' );
    ok( $archive->is_excluded("$tmpdir/foo/cats/meow"), '$archive->is_excluded() works when exclusion added with $archive->exclude_from_file()' );

    #
    # Test to see the expected contents are written.
    #
    my $reader_pid = IPC::Open3::open3( my ( $in, $out ), undef, $tar, '-tf', '-' );
    my $writer_pid = fork();

    $archive->set_handle($in);

    if ( !defined $writer_pid ) {
        die("Unable to fork(): $!");
    }
    elsif ( $writer_pid == 0 ) {
        close $out;

        foreach my $member ( sort keys %paths ) {
            my $path = $paths{$member};

            $archive->archive_as( $path => $member );
        }

        $archive->finish();

        #
        # This may seem a bit gratuitous, but this is needed because Perl 5.6.2's
        # distribution of File::Temp has a bug in which directories are cleaned
        # up regardless if the process exiting is a child of the process that
        # created the directory in question, or not.  execve() is the easiest way
        # to clear away atexit() handlers in this case.
        #
        exec( '/bin/sh', '-c', 'true' );
    }

    close $in;

    my %EXPECTED = map { $_ => 1 } qw(
      foo
      foo/exclude.txt
      foo/bar
      foo/poop
      bar
      bar/exclude.txt
      bar/bar
      bar/poop
      home/prrr/1327342027.M926735P26547V000000000000FD00I0000000001888287_0.one.two.threefour.five.S=2486:2.
    );

    my $entries = scalar keys %EXPECTED;
    my $found   = 0;

    while ( my $line = readline($out) ) {
        chomp $line;

        $line =~ s/^\///;
        $line =~ s/\/$//;

        $found++ if $EXPECTED{$line};
    }

    close $out;

    my %statuses = map {
        waitpid( $_, 0 );
        $_ => $? >> 8;
    } ( $writer_pid, $reader_pid );

    is( $found                 => $entries, '$archive->finish() wrote the appropriate number of items' );
    is( $statuses{$writer_pid} => 0,        '$archive->finish() subprocess exited with 0 status' );
    is( $statuses{$reader_pid} => 0,        'tar subprocess exited with 0 status' );

    #
    # Exercise $archive->finish() in the parent process; we cannot capture output
    # if we are to do this reliably.
    #
    pipe my $in_read, $in or die("Unable to pipe(): $!");

    my $pid = fork();

    if ( !defined $pid ) {
        die("Unable to fork(): $!");
    }
    elsif ( $pid == 0 ) {
        close $in;

        open( STDIN,  '<&=' . fileno($in_read) );
        open( STDOUT, '>/dev/null' );
        exec( $tar, '-tf', '-' ) or die("Unable to exec() $tar: $!");
    }

    close $in_read;

    $archive->set_handle($in);

    foreach my $member ( sort keys %paths ) {
        my $path = $paths{$member};

        $archive->archive_as( $path => $member );
    }

    eval { $archive->finish(); };

    is( $@ => '', '$archive->finish() does not die when writing to handle' );

    close $in;
    waitpid( $pid, 0 );

    is( ( $? >> 8 ) => 0, 'tar exited with a zero status' );

    # Need to do this otherwise the atexit() handler File::Temp sets up won't work
    chdir($oldpwd) or die("Unable to chdir() to $oldpwd: $!");
}

# Test inclusion
{
    my $archive = Archive::Tar::Builder->new;

    my ( $fh, $file ) = File::Temp::tempfile();
    print {$fh} "feh\n";
    print {$fh} "moo/*\n";
    close $fh;

    $archive->include('cats/*');
    $archive->include_from_file($file);

    my %TESTS = (
        'foo/bar/baz/foo/cats' => 0,
        'cats/meow'            => 1,
        'bleh/poo'             => 0,
        'thing/feh'            => 0,
        'feh/thing'            => 1,
        'hrm/moo'              => 0,
        'moo/hrm'              => 1
    );

    foreach my $path ( sort keys %TESTS ) {
        my $should_be_included = $TESTS{$path};

        if ($should_be_included) {
            ok( !$archive->is_excluded($path), "Path '$path' is included" );
        }
        else {
            ok( $archive->is_excluded($path), "Path '$path' is included" );
        }
    }
}

# Test exclusions
{
    my $archive = Archive::Tar::Builder->new;

    eval { $archive->exclude('excluded'); };

    is( $@ => '', '$archive->exclude() does not die' );

    my $badfile = '/dev/null/impossible';
    my ( $fh, $file ) = File::Temp::tempfile();
    print {$fh} "skipped\n";
    print {$fh} "unwanted\n";
    print {$fh} "ignored\n";
    print {$fh} "backup-[!_]*_[!-]*-[!-]*-[!_]*_foo*\n";
    close $fh;

    eval { $archive->exclude_from_file($file); };

    is( $@ => '', '$archive->exclude_from_file() does not die when given a good file' );

    eval { $archive->exclude_from_file($badfile); };

    like( $@ => qr/Cannot add items to exclusion list from file $badfile:/, '$archive->exclude_from_file() dies when unable to read file' );

    my %TESTS = (
        'foo/bar/baz'                                    => 1,
        'cats/meow'                                      => 1,
        'this/is/allowed'                                => 1,
        'meow/excluded/really'                           => 0,
        'meow/excluded'                                  => 0,
        'poop/skipped/meow'                              => 0,
        'poop/skipped'                                   => 0,
        'bleh/unwanted'                                  => 0,
        'bleh/ignored/meow'                              => 0,
        'bleh/ignored'                                   => 0,
        '/home/backup-4.5.2012_12-10-36_foo.tar.gz/cats' => 0,
        '/home/backup-4.5.2012_12-10-36_foo.tar.gz'      => 0,
        '/home/backu-4.5.2012_12-10-36_foo.tar.gz'       => 1
    );

    print '# Excluding: "excluded", "skipped", "unwanted", "ignored"' . "\n";

    foreach my $test ( sort keys %TESTS ) {
        my $expected = $TESTS{$test};

        if ( $archive->is_excluded($test) ) {
            ok( !$expected, "Path '$test' is excluded" );
        }
        else {
            ok( $expected, "Path '$test' is NOT excluded" );
        }
    }

    unlink($file);
}

# Further test inclusions
{
    my $archive = Archive::Tar::Builder->new;

    print '# Using "foo", "bar", "baz" and "meow" as inclusions' . "\n";

    my $badfile = '/dev/null/impossible';
    my ( $fh, $file ) = File::Temp::tempfile();
    print {$fh} "foo\n";
    print {$fh} "bar\n";
    print {$fh} "baz\n";
    close $fh;

    eval { $archive->include('meow'); };

    is( $@ => '', '$archive->include() does not die when adding inclusion pattern' );

    eval { $archive->include_from_file($badfile); };

    like( $@ => qr/^Cannot add items to inclusion list from file $badfile:/, '$archive->include_from_file() dies on invalid file' );

    eval { $archive->include_from_file($file); };

    is( $@ => '', '$archive->include_from_file() does not die when adding include patterns from file' );

    my %TESTS = (
        'foo'          => 1,
        'bar/poo'      => 1,
        'baz/poo'      => 1,
        'meow/cats'    => 1,
        'haz/meow/poo' => 0,
        'haz/poo/meow' => 0,
        'bleh'         => 0
    );

    foreach my $path ( sort keys %TESTS ) {
        my $should_be_included = $TESTS{$path};

        if ($should_be_included) {
            ok( !$archive->is_excluded($path), "'$path' is included" );
        }
        else {
            ok( $archive->is_excluded($path), "'$path' is not included" );
        }
    }

    unlink($file);
}

# Test error handling
SKIP: {
    skip( 'Test will not work as root', 1 ) unless $<;

    my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );
    my $path   = "$tmpdir/foo";

    mkdir( $path, 0 );

    open( my $fh, '>', '/dev/null' );

    my $builder = Archive::Tar::Builder->new( 'quiet' => 1 );
    $builder->set_handle($fh);
    $builder->archive($tmpdir);

    eval { $builder->finish(); };

    like( $@ => qr/^Delayed nonzero exit/, '$builder->finish() dies if any errors were encountered' );

    chmod( 0600, $path );
}

# Test long filenames, symlinks
foreach my $ext (qw/gnu posix/) {
    my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );
    my $path   = "$tmpdir/" . ( 'foops/' x 60 );

    File::Path::mkpath($path) or die("Unable to create long path: $!");

    my $long_symlink = "${path}foo";
    $long_symlink =~ s/^\///;
    $long_symlink =~ s/\/$//;

    symlink( 'foo',         "$tmpdir/bar" ) or die("Unable to symlink() $tmpdir/bar to foo: $!");
    symlink( $long_symlink, "$tmpdir/baz" ) or die("Unable to symlink() $tmpdir/baz to $long_symlink: $!");

    my $archive = Archive::Tar::Builder->new( "${ext}_extensions" => 1 );

    my $err = Symbol::gensym();

    my $reader_pid = IPC::Open3::open3( my ( $in, $out ), $err, $tar, '-tvf', '-' );
    my $writer_pid = fork();

    if ( !defined $writer_pid ) {
        die("Unable to fork(): $!");
    }
    elsif ( $writer_pid == 0 ) {
        $archive->set_handle($in);
        $archive->archive($tmpdir);
        $archive->flush();
        exec( '/bin/sh', '-c', 'true' );
    }

    my ( $paths, $errors );

    my $rin = '';
    vec( $rin, fileno($out), 1 ) = 1;
    vec( $rin, fileno($err), 1 ) = 1;

    my %FOUND;
    my %SYMLINKS;

    close $in;

    while ( select( my $rout = $rin, undef, undef, undef ) > 0 ) {
        my $buf;
        my $len;

        if ( vec( $rout, fileno($out), 1 ) ) {
            $len = sysread( $out, $buf, 512 );

            if ( !$len ) {
                vec( $rin, fileno($out), 1 ) = 0;
            }
            else {
                $paths .= $buf;
            }
        }

        if ( vec( $rout, fileno($err), 1 ) ) {
            $len = sysread( $err, $buf, 512 );

            if ( !$len ) {
                vec( $rin, fileno($err), 1 ) = 0;
            }
            else {
                $errors .= $buf;
            }
        }

        last unless grep { $_ } unpack( 'C*', $rin );
    }

    foreach my $item ( split "\n", $paths ) {
        $item =~ s/^\///;
        $item =~ s/\/$//;
        $item =~ s/^.*?\s\/?(\S+)(?:\s->\s\/?(\S+))?$/$1/;

        $FOUND{$item} = 1;
        $SYMLINKS{$2} = 1 if defined $2;
    }

    close $err;
    close $out;

    my %statuses = map {
        waitpid( $_, 0 );
        $_ => $? >> 8;
    } ( $reader_pid, $writer_pid );

    if ($errors) {
        foreach my $item ( split "\n", $errors ) {
            diag("From standard error: $item");
        }
    }

    is( $statuses{$writer_pid} => 0, '$archive->finish() did not die while archiving long pathnames' );
    is( $statuses{$reader_pid} => 0, 'tar -tf - did not die while parsing tar stream with long pathnames' );

    {
        my $expected_symlink = "$tmpdir/bar";
        $expected_symlink =~ s/^\///;
        $expected_symlink =~ s/\/$//;

        $path =~ s/^\///;
        $path =~ s/\/$//;

        my $longest;

        foreach my $item ( keys %FOUND ) {
            next unless $FOUND{$item};
            $longest ||= $item;
            $longest = $item if length($item) > length($longest);
        }

        ok( $FOUND{$path},             "\$archive->finish() properly encoded a long pathname for directory for $path" );
        ok( $FOUND{$expected_symlink}, '$archive->archive() properly encoded a symlink' );
        ok( $SYMLINKS{'foo'},          '$archive->archive() found expected symlink' );
        ok( $SYMLINKS{$long_symlink},  '$archive->archive() found long symlink' );
    }
}

# Case 74517 - LongLink blocks were being written with origin path rather than member name, causing
#              archive_as not to work as expected once the member name exceeded a certain length
#              (long enough to trigger use of LongLink).
SKIP: {
    ## semantics of the test...
    skip( 'GNU tar unavailable to perform test', 1 ) if is_bsd_tar($tar);

    # The specific failure was seen at length 156 and up, but why not test a lot more than that for the heck of it?
    my @test_range = 1 .. 5_000;
    my @t_in       = map { [ '/etc/hosts', ( "X" x $_ ) ] } @test_range;
    my %t_out;
    my @expect_t_out = map { "X" x $_ } @test_range;

    go_74517();    # reads @t_in and alters %t_out

    my @failed_lengths;
    for (@test_range) {
        my $f = "X" x $_;
        unless ( $t_out{$f} || $t_out{"$f/"} ) {
            push @failed_lengths, $_;
        }
    }
    is_deeply \@failed_lengths, [], "all " . @test_range . " member_name lengths tested were successful"
      or note explain "failed the following lengths: @failed_lengths";

    ## mechanics of the test...
    sub go_74517 {
        local $SIG{CHLD} = sub { waitpid -1, 0 };
        pipe my ($atb_rd), my ($atb_wr);
        pipe my ($tar_rd), my ($tar_wr);
        if ( my $child = fork ) {
            close $atb_wr;
            if ( my $tar = fork ) {
                close $tar_wr;
                while (<$tar_rd>) {
                    chomp;
                    $t_out{$_} = 1;
                }
            }
            elsif ( defined $tar ) {
                open( STDIN,  '<&=' . fileno($atb_rd) );
                open( STDOUT, '>&=' . fileno($tar_wr) );
                exec 'tar', 'tf', '-';
            }
            else { die "fork: $!" }
        }
        elsif ( defined $child ) {
            my $atb = Archive::Tar::Builder->new( 'gnu_extensions' => 1 );

            $atb->set_handle($atb_wr);

            for (@t_in) {
                $atb->archive_as(@$_);
            }

            $atb->finish;

            close($atb_wr);

            exit;
        }
        else { die "fork: $!" }
    }
}

# Case 74781: Files with length [100,156] were being included with a trailing
# slash, causing them to be unpacked as directories in some cases.
SKIP: {
    skip( 'GNU tar unavailable to run tests which require LongLink extensions', 2 ) if is_bsd_tar($tar);

    my $tmp = File::Temp::tempdir( 'CLEANUP' => 1 );
    mkdir("$tmp/a");
    mkdir("$tmp/b");
    my @files = map { "X" x $_ } 1 .. 255;

    foreach my $name (@files) {
        open( my $fh, ">", "$tmp/a/$name" );
        print {$fh} $name;
        close($fh);
    }

    my $tarfile = "$tmp/file.tar";
    open( my $atb_wr, ">", $tarfile );

    my $atb = Archive::Tar::Builder->new( 'gnu_extensions' => 1 );

    $atb->set_handle($atb_wr);
    $atb->archive_as( "$tmp/a/$_", $_ ) for @files;
    $atb->finish;
    close($atb_wr);

    my $cwd = Cwd::getcwd();
    chdir("$tmp/b");
    my $wait = system("tar -xf $tarfile >/dev/null 2>&1");
    is( $wait, 0, "tar file unarchived successfully" );
    my $diff_output = `diff -r $tmp/a $tmp/b`;
    is( $diff_output, "", "no diff output" );
    chdir($cwd);
}

# Some of the tests below are meant to trigger a race condition and are timing-sensitive.
use constant { NORMAL => 0, APPENDING => 1, TRUNCATED => 2 };
for my $test_mode (
    NORMAL,    # File is completely written before being archived.
               # Expectation: No problems.

    APPENDING, # File is still being appended to as it is archived.
               # Expectation: Archived copy will be truncated to match the original length.

    TRUNCATED, # File is written before being archived but then is truncated as it is being archived.
               # Expectation: Archive::Tar::Builder will die, rather than silently produce a corrupt tarball.
) {
    my $tmp = File::Temp::tempdir( 'CLEANUP' => 1 );

    my ( $child, $child2 );
    if ( $child = fork ) {
    }
    elsif ( defined $child ) {
        open( my $fh, ">", "$tmp/example.txt" );
        for ( 1 .. ( $test_mode != APPENDING ? 10 : 1_000 ) ) {
            print {$fh} ( "hello" x 50 ) . "\n";
            select undef, undef, undef, 0.01;
        }
        close $fh;
        exit;
    }
    else { die "fork: $!" }

    waitpid $child, 0 if $test_mode != APPENDING;

    select undef, undef, undef, 0.1;

    if ( $test_mode == TRUNCATED ) {
        if ( $child2 = fork ) {
        }
        elsif ( defined $child2 ) {
            open( my $fh, "+<", "$tmp/example.txt" );
            for ( my $len = 100_000_000; $len >= 0; $len -= 10_000 ) {
                truncate $fh, $len;
                select undef, undef, undef, 0.05;
            }
            close $fh;
            exit;
        }
        else { die "fork: $!" }
    }

    my $tarfile = "$tmp/file2.tar";

    open( my $atb_wr, ">", $tarfile );

    my $ok = eval {
        my $atb = Archive::Tar::Builder->new(
            'gnu_extensions' => 1,
            'quiet'          => 1
        );

        $atb->set_handle($atb_wr);
        $atb->archive("$tmp/example.txt");
        $atb->finish;

        1;
    };

    my $atb_error = $@;

    close($atb_wr);

    my $output = `tar -xvf $tarfile -C $tmp 2>&1`;
    my $status = $?;

    if ( $test_mode == TRUNCATED ) {

        my $atb_died = ( !$ok && $atb_error );
        my $extract_succeeded = ( $status == 0 && $output =~ /example\.txt/ );

        # The "truncated" test is satisfied if either:
        #     1. Archive::Tar::Builder died while creating the archive.
        # or  2. A usable archive was created which includes the file in question.
        ok $atb_died || $extract_succeeded,
          "If a file is truncated while it is being read, ATB will die. Otherwise, the resulting archive will be usable." and diag "In this case, the previous test passed because "
          . (
            $atb_died
            ? "Archive::Tar::Builder died, which was the goal of the test"
            : "extract succeeded, which means the test failed to trigger the race condition, but that's OK"
          );
    }
    else {
        is $status, 0,
          sprintf(
            "for an archive created while a file being archived was %s, archive was extracted successfully",
            $test_mode == NORMAL      ? "completely written"
            : $test_mode == APPENDING ? "appended to as it was being archived"
            :                           die
          ) or diag explain [ $output, `ls -al $tmp` ];
        kill 9, $child2 if $test_mode == TRUNCATED;    # the child in this mode would go on far longer than needed
    }

    if ($child) {
        kill 9, $child;
        waitpid $child, 0;
    }
    if ($child2) {
        kill 9, $child2;
        waitpid $child2, 0;
    }
}

#
# Case 117233: Ensure Archive::Tar::Builder->archive() and archive_as() require
# 'gnu_extensions' for archiving files with impossibly long names.
#
{
    open my $fh, '>', '/dev/null' or die("Unable to open /dev/null for writing: $!");

    {
        my $builder = Archive::Tar::Builder->new( 'quiet' => 1 );

        $builder->set_handle($fh);

        eval { $builder->archive_as( '/etc/hosts' => 'BLEH' x 60 ); };

        ok( $!{'ENAMETOOLONG'}, '$builder->archive_as() croak()s and sets $! to ENAMETOOLONG on long filenames without gnu_extensions' );
    }

    {
        my $builder = Archive::Tar::Builder->new(
            'quiet'          => 1,
            'gnu_extensions' => 1
        );

        $builder->set_handle($fh);

        lives_ok {
            $builder->archive_as( '/etc/hosts' => 'BLEH' x 60 );
        }
        '$builder->archive_as() will NOT croak() on long filenames when gnu_extensions is passed';
    }

    {
        my $builder = Archive::Tar::Builder->new(
            'quiet'            => 1,
            'posix_extensions' => 1
        );

        $builder->set_handle($fh);

        lives_ok {
            $builder->archive_as( '/etc/hosts' => 'BLEH' x 60 );
        }
        '$builder->archive_as() will NOT croak() on long filenames when posix_extensions is passed';
    }

    close $fh;
}

#
# Test hardlink preservation support
#
{
    my $src  = File::Temp::tempdir( 'CLEANUP' => 1 );
    my $dest = File::Temp::tempdir( 'CLEANUP' => 1 );

    open my $fh, '>', "$src/foo" or die "Unable to open $src/foo for writing: $!";
    print {$fh} "test\n";
    close $fh;

    link "$src/foo" => "$src/bar" or die "Unable to link $src/foo to $src/bar: $!";

    my @FLAG_SETS = (
        [ 'ustar' => [ 'preserve_hardlinks' => 1 ] ],
        [ 'PAX'   => [ 'preserve_hardlinks' => 1, 'posix_extensions' => 1 ] ],
        [ 'GNU'   => [ 'preserve_hardlinks' => 1, 'gnu_extensions' => 1 ] ]
    );

    foreach my $flag_set (@FLAG_SETS) {
        my ( $format, $flags ) = @{$flag_set};

        note("Testing 'preserve_hardlinks' flag with $format output");

        my $builder = Archive::Tar::Builder->new( @{$flags} );

        my $reader_pid = IPC::Open3::open3( my $in, undef, undef, $tar, '-C', $dest, '-xf', '-' );
        my $writer_pid = fork;

        die "Unable to fork(): $!" unless defined $writer_pid;

        if ( $writer_pid == 0 ) {
            chdir $src or die "Unable to chdir() to $src: $!";

            $builder->set_handle($in);
            $builder->archive('.');
            $builder->finish;

            exit 0;
        }

        close $in;

        waitpid $writer_pid, 0 or die "Unable to waitpid() on $writer_pid: $!";
        waitpid $reader_pid, 0 or die "Unable to waitpid() on $reader_pid: $!";

        my @st1 = stat "$dest/foo" or die "Unable to stat() $dest/foo: $!";
        my @st2 = stat "$dest/bar" or die "Unable to stat() $dest/bar: $!";

        is( $st1[0] => $st2[0], "st_dev of $dest/foo matches $dest/bar" );
        is( $st1[1] => $st2[1], "st_ino of $dest/foo matches $dest/bar" );
    }
}

#
# Test for fix to CPANEL-29859; segfaulting when archiving certain numbers of
# hardlinked files
#
{
    my $tmp = File::Temp::tempdir( 'CLEANUP' => 1 );

    for ( my $i = 1; $i < 200; $i++ ) {
        my $orig = sprintf "$tmp/orig-%04d", $i;
        my $link = sprintf "$tmp/link-%04d", $i;

        open my $fh, '>', $orig or die "Unable to open() $orig for writing: $!";
        close $fh;

        link $orig => $link or die "Unable to link() $orig to $link: $!";
    }

    my $status = system $^X, "$FindBin::Bin/scripts/CPANEL-29859.pl", $tmp;
    my $signal = $? & 0x7f;

    is( $signal => 0, "\$builder->archive() exits with no signal when archiving large numbers of hardlinked files" );
}
