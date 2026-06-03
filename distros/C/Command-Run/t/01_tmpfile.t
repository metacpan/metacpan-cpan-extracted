use strict;
use warnings;
use Test::More;

use Command::Run::Tmpfile;

# new
my $tmp = Command::Run::Tmpfile->new;
ok $tmp, 'new';
isa_ok $tmp, 'Command::Run::Tmpfile';

# fh, fd
ok $tmp->fh, 'fh';
ok defined $tmp->fd, 'fd';
like $tmp->fd, qr/^\d+$/, 'fd is numeric';

# path
my $path = $tmp->path;
like $path, qr{^/(dev/fd|proc/self/fd)/\d+$}, 'path format';

# write, flush, rewind
$tmp->write("hello")->write(" world")->flush;
$tmp->rewind;
my $fh = $tmp->fh;
my $data = do { local $/; <$fh> };
is $data, "hello world", 'write and read back';

# reset
$tmp->reset;
$tmp->write("new data")->flush->rewind;
$data = do { local $/; <$fh> };
is $data, "new data", 'reset clears content';

# raw mode: byte transparency (no double encoding)
{
    my $bytes = "\343\201\202\343\201\204"; # "あい" as raw UTF-8 bytes
    ok !utf8::is_utf8($bytes), 'fixture is a byte string';

    # default mode double-encodes raw UTF-8 bytes
    my $enc = Command::Run::Tmpfile->new;
    $enc->write($bytes)->flush->rewind;
    my $efh = $enc->fh; binmode $efh;
    my $eout = do { local $/; <$efh> };
    isnt $eout, $bytes, 'default mode re-encodes byte string';

    # raw mode stores bytes unchanged
    my $raw = Command::Run::Tmpfile->new(raw => 1);
    $raw->write($bytes)->flush->rewind;
    my $rfh = $raw->fh; binmode $rfh;
    my $rout = do { local $/; <$rfh> };
    is $rout, $bytes, 'raw mode is byte-transparent';
    is length($rout), 6, 'raw mode stores 6 bytes';
}

done_testing;
