#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::Temp 'tempdir';
use IO::Select;
use Test::Requires 'Term::TtyRec::Plus';
use Test::Requires 'IO::Pty::Easy';

alarm 60;

my $dir = tempdir(CLEANUP => 1);

my $pty = IO::Pty::Easy->new;
$pty->spawn($^X, (map {; '-I', $_ } @INC), '-e', <<SCRIPT);
use strict;
use warnings;
use App::Ttyrec;
chdir '$dir';
App::Ttyrec->new->run(\$^X, '-ple', q[last if /^\$/]);
SCRIPT

my $crlf = qr/\x0d\x0a/;

my @frames;
my @times;
{
    $pty->write("foo\n");
    my $frame = full_read($pty);
    like($frame, qr/^foo${crlf}foo${crlf}$/m);
    push @frames, $frame;
    push @times, time;
}
{
    $pty->write("bar\nbaz\n");
    my $frame = full_read($pty);
    like($frame, qr/^bar${crlf}(?:bar${crlf}baz${crlf}|baz${crlf}bar${crlf})baz${crlf}$/m);
    push @frames, $frame;
    push @times, time;
}
{
    $pty->write("\n");
    my $frame = full_read($pty);
    like($frame, qr/^${crlf}$/m);
    push @frames, $frame;
    push @times, time;
}

my $file = File::Spec->catfile($dir, 'ttyrecord');
die "couldn't find ttyrecord file" unless -e $file;

my $ttyrec = Term::TtyRec::Plus->new(
    infile => $file,
);

my $current_frame_idx = 0;
my $current_frame_data = '';
while (my $frame = $ttyrec->next_frame) {
    $current_frame_data .= $frame->{data};
    next if length($current_frame_data) < length($frames[$current_frame_idx]);
    is($current_frame_data, $frames[$current_frame_idx]);
    cmp_ok(abs($times[$current_frame_idx] - $frame->{orig_timestamp}), '<', 2);
    $current_frame_idx++;
    $current_frame_data = '';
}
fail if length($current_frame_data);
fail if $current_frame_idx != 3;

sub full_read {
    my ($fh) = @_;

    my $select = IO::Select->new($fh);
    return if $select->has_exception(0.1);

    1 while !$select->can_read(1);

    my $ret;
    while ($select->can_read(1)) {
        my $new;
        sysread($fh, $new, 4096);
        last unless defined($new) && length($new);
        $ret .= $new;
        return $ret if $select->has_exception(0.1);
    }

    return $ret;
}

done_testing;
