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

done_testing;
