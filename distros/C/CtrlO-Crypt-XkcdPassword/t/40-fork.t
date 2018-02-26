#!/usr/bin/perl
use Test::More;
use strict;
use warnings;
use 5.010;
use lib 'lib';
use Test::SharedFork;
use CtrlO::Crypt::XkcdPassword;
use File::Spec;

# this is a rather complex test: it forks off two child processes and
# generates two pwds per child (containing of one word and some digits).
# The parent process also generates two pwds (only a word, no digits).
# To make sure that the entropy source is reset after a fork, the pwds
# are written to a temp file. After all pwds have been generated, we
# read in the tempfile, discard the digits, and count the distinct pwds.
# If you disable _reinit_after_fork in CtrlO::Crypt::XkcdPassword this
# test will fail
# This test might also fail in various non-Linux environments...

if ( $^O eq 'MSWin32' ) {
    plan( skip_all => 'skip fork tests on MSWin32' ) ;
}

my $tmpfile =
    File::Spec->catfile( File::Spec->tmpdir, 'CtrlO_Crypt_XkcdPassword.txt' );
unlink($tmpfile);

subtest 'create pwds with forks' => sub {
    my $pwgen      = CtrlO::Crypt::XkcdPassword->new;
    my $parent_pid = $$;
    open( my $pwds, ">>", $tmpfile );

    is( $pwgen->_pid, $parent_pid, 'in parent' );
    my @pwds;

    for my $i ( 1 .. 2 ) {
        my $pid = fork();
        if ( not $pid ) {
            is( $pwgen->_pid, $parent_pid,
                'xkcd not called, so still parent pid' );
            isnt( $pwgen->_pid, $$, 'pwgen->_pid not pid of fork' );

            my $pw = $pwgen->xkcd( words => 1, digits => $i );
            like( $pw, qr/^\p{Uppercase}\p{Lowercase}+\d+$/, "fork $i: $pw" );
            say $pwds $pw;

            is( $pwgen->_pid, $$, 'xkcd called, so _pid is pid of fork' );

            sleep $i;

            my $pw2 = $pwgen->xkcd( words => 1, digits => $i );
            like(
                $pw2,
                qr/^\p{Uppercase}\p{Lowercase}+\d+$/,
                "fork $i: $pw2"
            );
            say $pwds $pw2;

            exit;
        }
    }

    is( $pwgen->_pid, $parent_pid, 'in parent, pid is unchanged' );
    my $pw = $pwgen->xkcd( words => 1 );
    say $pwds $pw;
    like( $pw, qr/^\p{Uppercase}\p{Lowercase}+$/, "parent: $pw" );

    sleep 2;

    for ( 1 .. 2 ) {
        my $finished = wait();
    }

    is( $pwgen->_pid, $parent_pid, 'in parent, pid is still unchanged' );
    my $pw2 = $pwgen->xkcd( words => 1 );
    like( $pw2, qr/^\p{Uppercase}\p{Lowercase}+$/, "parent: $pw2" );
    say $pwds $pw2;

    close $tmpfile;
};

subtest 'passwords are all different' => sub {
    open( my $generated, '<', $tmpfile );
    my %seen;
    while ( my $line = <$generated> ) {
        chomp($line);
        $line =~ s/\d//g;
        $seen{$line}++;
    }
    is( scalar keys %seen, 6, 'got 6 distinct passwords (ignoring digits)' );
    unlink($tmpfile);
};

done_testing();
