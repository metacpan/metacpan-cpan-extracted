use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use Apophis;

plan skip_all => 'a file in the way of a directory behaves differently on Windows' if $^O eq 'MSWin32';

my $root = tempdir(CLEANUP => 1);
my $text = 'content under test';
my $ns   = 'test-fs';
my $id   = Apophis->new(namespace => $ns)->identify(\$text);
my ($s1, $s2) = (substr($id, 0, 2), substr($id, 2, 2));

sub touch { my ($path) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh "in the way\n"; close $fh }
sub store_in { Apophis->new(namespace => $ns, store_dir => shift) }

sub socket_at {
    my ($path) = @_;
    my ($vol, $dir, $base) = File::Spec->splitpath($path);
    my $here = File::Spec->rel2abs('.');
    chdir File::Spec->catpath($vol, $dir, '') or die "$dir: $!";
    my $sock = IO::Socket::UNIX->new(Local => $base, Listen => 1) or die "$path: $!";
    chdir $here or die "$here: $!";
    close $sock;
    return;
}

my $blocked = File::Spec->catfile($root, 'blocked');
touch($blocked);
ok(!eval { store_in($blocked)->store(\$text); 1 }, 'a store directory that is a file cannot hold a shard');
like($@, qr{^Apophis: cannot create directory '\Q$blocked\E/$s1': }, 'and the shard directory that failed is named');

my $shard = File::Spec->catdir($root, 'shard');
make_path($shard);
touch(File::Spec->catfile($shard, $s1));
ok(!eval { store_in($shard)->store(\$text); 1 }, 'a first shard level that is a file cannot hold the second');
like($@, qr{^Apophis: cannot create directory '\Q$shard\E/$s1/$s2': }, 'and the second level is named');

my $leaf = File::Spec->catdir($root, 'leaf');
make_path(File::Spec->catdir($leaf, $s1));
touch(File::Spec->catfile($leaf, $s1, $s2));
ok(!eval { store_in($leaf)->store(\$text); 1 }, 'a second shard level that is a file cannot take the blob');
like($@, qr{^Apophis: cannot write '\Q$leaf\E/$s1/$s2/\Q$id\E\.tmp\.\d+': }, 'and the temporary file that could not be opened is named');

my $good = File::Spec->catdir($root, 'good');
my $ca   = store_in($good);
is($ca->store(\$text), $id, 'a writable store takes the blob');
my $path = $ca->path_for($id);

my $tmp_dir = "$path.meta.tmp.$$";
make_path($tmp_dir);
ok(!eval { $ca->store(\$text, meta => { k => 'v' }); 1 }, 'a directory sitting where the metadata is written first stops the store');
like($@, qr{^Apophis: cannot write metadata '\Q$tmp_dir\E': }, 'and is named');
rmdir $tmp_dir or die "$tmp_dir: $!";

make_path("$path.meta");
ok(!eval { $ca->store(\$text, meta => { k => 'v' }); 1 }, 'a directory sitting where the metadata lands stops the rename');
like($@, qr{^Apophis: cannot rename metadata '\Q$path\E\.meta\.tmp\.\d+': }, 'and the temporary file is named');
ok(!-e "$path.meta.tmp.$$", 'which was removed');
ok(!defined $ca->meta($id), 'and metadata that cannot be read as a file is no metadata');
rmdir "$path.meta" or die "$path.meta: $!";

open my $mh, '>', "$path.meta" or die "$path.meta: $!";
print $mh "first=one\nno equals sign here\nlast=two";
close $mh;
is_deeply($ca->meta($id), { first => 'one', last => 'two' }, 'a sidecar without a final newline and with a line that is no pair reads the pairs it has');

unlink "$path.meta" or die "$path.meta: $!";
socket_at("$path.meta");
ok(!defined $ca->meta($id), 'metadata that is there but cannot be opened, here a socket, is no metadata');
unlink $path or die "$path: $!";
socket_at($path);
ok($ca->exists($id), 'a socket at the path counts as present to exists');
ok(!eval { $ca->fetch($id); 1 }, 'but a blob that is there and cannot be opened is an error, not a miss');
like($@, qr{^Apophis::fetch: cannot open '\Q$path\E': }, 'naming it');
ok(!eval { $ca->op_fetch($id); 1 }, 'through the fused fetch too');
like($@, qr{^Apophis::op_fetch: cannot open '\Q$path\E': }, 'with its own name');
ok(!$ca->verify($id), 'and it does not verify');

ok($ca->remove($id), 'the blob is removed');
ok(!-e "$path.meta", 'and its sidecar with it');

my $short = 'abcdef';
my $short_path = $ca->path_for($short);
Apophis::_abi_write($short_path, \$text);
ok($ca->exists($short), 'a file planted at the path of an id too short to be a UUID exists');
ok(!$ca->verify($short), 'but does not verify, whatever it holds');
unlink $short_path or die "$short_path: $!";
make_path($path);
ok($ca->exists($id), 'a directory at the path counts as present to exists, which only asks the file system');
ok(!eval { $ca->fetch($id); 1 }, 'but fetching it is a read error');
like($@, qr{^Apophis::fetch: read error on '\Q$path\E'}, 'that names the path');
ok(!eval { $ca->op_fetch($id); 1 }, 'through the fused fetch too');
like($@, qr{^Apophis::op_fetch: read error on '\Q$path\E'}, 'with its own name');
ok(!$ca->verify($id), 'and it does not verify');
ok(!eval { Apophis::_abi_write($path, \$text); 1 }, 'the table cannot rename a blob over a directory');
like($@, qr{^Apophis: cannot rename '\Q$path\E\.tmp\.\d+' -> '\Q$path\E': }, 'and names both');
ok(!-e "$path.tmp.$$", 'leaving no temporary file behind');
rmdir $path or die "$path: $!";
ok(!$ca->remove($id), 'nothing left to remove');

my $deep = File::Spec->catfile($root, 'made', 'by', 'the', 'table');
Apophis::_abi_write($deep, \$text);
open my $dh, '<', $deep or die "$deep: $!";
is(do { local $/; <$dh> }, $text, 'the table writes a blob under directories it creates');
close $dh;
ok(!eval { Apophis::_abi_write($deep, 'not a ref'); 1 }, 'but wants a reference to the content');
like($@, qr/^Apophis::_abi_write: content must be a scalar reference/, 'and says so');
ok(!eval { Apophis::_abi_write(File::Spec->catfile($root, 'y' x 4200), \$text); 1 }, 'a path longer than the buffer is refused');
like($@, qr/^Apophis: path too long/, 'and says so');
{
    my $here = File::Spec->rel2abs('.');
    chdir $root or die "$root: $!";
    Apophis::_abi_write('bare', \$text);
    ok(-f File::Spec->catfile($root, 'bare'), 'a bare file name lands in the current directory, with no parent to create');
    chdir $here or die "$here: $!";
}

done_testing;
