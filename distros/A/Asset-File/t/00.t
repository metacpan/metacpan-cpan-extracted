use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw(catdir catfile);
use Asset::File;

# File asset
my $file = Asset::File->new;
is $file->size, 0, 'file is empty';
is $file->mtime, (stat $file->handle)[9], 'right mtime';
is $file->slurp, '', 'file is empty';
$file->add_chunk('abc');
is $file->contains('abc'), 0, '"abc" at position 0';
is $file->contains('bc'), 1, '"bc" at position 1';
is $file->contains('db'), -1, 'does not contain "db"';
is $file->size, 3, 'right size';
is $file->mtime, (stat $file->handle)[9], 'right mtime';
# Cleanup
my $path = $file->path;
ok -e $path, 'temporary file exists';
undef $file;
ok !-e $path, 'temporary file has been cleaned up';
# Open existing and upgrade to rw
Asset::File->new({path => $path, cleanup => 0})->add_chunk('foo');
my $stat = [(stat($path))];
$file = Asset::File->new(path => $path);
is_deeply [(stat($path))], $stat, "opening didn't affect stat";
ok eval { $file->add_chunk('bar') }, "didn't die";
is $file->get_chunk, 'foobar', 'right content';
undef $file;
ok -e $path, 'file exists';
unlink $path;
# Empty file asset
$file = Asset::File->new;
is $file->contains('a'), -1, 'does not contain "a"';
# File asset range support (a[bcdefabc])
$file = Asset::File->new();
$file->add_chunk('abcdefabc');
$file->start_range(1);
ok $file->is_range, 'has range';
is $file->contains('bcdef'), 0, '"bcdef" at position 0';
is $file->contains('cdef'), 1, '"cdef" at position 1';
is $file->contains('abc'), 5, '"abc" at position 5';
is $file->contains('db'), -1, 'does not contain "db"';
# File asset write range support (a[bcdefabc])
$file = Asset::File->new();
$file->start_range(10);
$file->add_chunk('abcdefabc');
$file->start_range(0);
is $file->contains('bcdef'), 11, '"bcdef" at position 11';
is $file->contains('cdef'), 12, '"cdef" at position 12';
is $file->contains('abc'), 10, '"abc" at position 10';
is $file->contains('db'), -1, 'does not contain "db"';
# File asset range support (ab[cdefghi]jk)
$file = Asset::File->new();
$file->add_chunk('abcdefghijk');
$file->start_range(2);
$file->end_range(8);
ok $file->is_range, 'has range';
is $file->contains('cdefghi'), 0, '"cdefghi" at position 0';
is $file->contains('fghi'), 3, '"fghi" at position 3';
is $file->contains('f'), 3, '"f" at position 3';
is $file->contains('hi'), 5, '"hi" at position 5';
is $file->contains('db'), -1, 'does not contain "db"';
is $file->get_chunk(0), 'cdefghi', 'chunk from position 0';
is $file->get_chunk(1), 'defghi', 'chunk from position 1';
is $file->get_chunk(5), 'hi', 'chunk from position 5';
is $file->get_chunk(0, 2), 'cd', 'chunk from position 0 (2 bytes)';
is $file->get_chunk(1, 3), 'def', 'chunk from position 1 (3 bytes)';
is $file->get_chunk(5, 1), 'h', 'chunk from position 5 (1 byte)';
is $file->get_chunk(5, 3), 'hi', 'chunk from position 5 (2 byte)';
# Huge file asset
$file = Asset::File->new;
ok !$file->is_range, 'no range';
$file->add_chunk('a' x 131072);
$file->add_chunk('b');
$file->add_chunk('c' x 131072);
$file->add_chunk('ddd');
is $file->contains('a'), 0, '"a" at position 0';
is $file->contains('b'), 131072, '"b" at position 131072';
is $file->contains('c'), 131073, '"c" at position 131073';
is $file->contains('abc'), 131071, '"abc" at position 131071';
is $file->contains('ccdd'), 262143, '"ccdd" at position 262143';
is $file->contains('dd'), 262145, '"dd" at position 262145';
is $file->contains('ddd'), 262145, '"ddd" at position 262145';
is $file->contains('e'), -1, 'does not contain "e"';
is $file->contains('a' x 131072), 0, '"a" x 131072 at position 0';
is $file->contains('c' x 131072), 131073, '"c" x 131072 at position 131073';
is $file->contains('b' . ('c' x 131072) . "ddd"), 131072, '"b" . ("c" x 131072) . "ddd" at position 131072';
# Huge file asset with range
$file = Asset::File->new();
$file->add_chunk('a' x 131072);
$file->add_chunk('b');
$file->add_chunk('c' x 131072);
$file->add_chunk('ddd');
$file->start_range(1);
$file->end_range(262146);
is $file->contains('a'), 0, '"a" at position 0';
is $file->contains('b'), 131071, '"b" at position 131071';
is $file->contains('c'), 131072, '"c" at position 131072';
is $file->contains('abc'), 131070, '"abc" at position 131070';
is $file->contains('ccdd'), 262142, '"ccdd" at position 262142';
is $file->contains('dd'), 262144, '"dd" at position 262144';
is $file->contains('ddd'), -1, 'does not contain "ddd"';
is $file->contains('b' . ('c' x 131072) . 'ddd'), -1,
'does not contain "b" . ("c" x 131072) . "ddd"';
# Move file asset to file
$file = Asset::File->new;
$file->add_chunk('bcd');
my $tmp = Asset::File->new;
$tmp->add_chunk('x');
isnt $file->path, $tmp->path, 'different paths';
$path = $tmp->path;
ok -e $path, 'file exists';
undef $tmp;
ok !-e $path, 'file has been cleaned up';
is $file->move_to($path)->slurp, 'bcd', 'right content';
undef $file;
ok -e $path, 'file exists';
unlink $path;
ok !-e $path, 'file has been cleaned up';
is(Asset::File->new->move_to($path)->slurp, '', 'no content');
ok -e $path, 'file exists';
unlink $path;
ok !-e $path, 'file has been cleaned up';
# Custom temporary file
{
$file = Asset::File->new(path => $path);
is $file->path, $path, 'right path';
ok !-e $path, 'file still does not exist';
$file->add_chunk('works!');
ok -e $path, 'file exists';
is $file->slurp, 'works!', 'right content';
undef $file;
ok !-e $path, 'file has been cleaned up';
}
# Temporary file without cleanup
$file = Asset::File->new(cleanup => 0)->add_chunk('test');
ok $file->is_file, 'stored in file';
is $file->slurp, 'test', 'right content';
is $file->size, 4, 'right size';
is $file->mtime, (stat $file->handle)[9], 'right mtime';
is $file->contains('es'), 1, '"es" at position 1';
$path = $file->path;
undef $file;
ok -e $path, 'file exists';
unlink $path;
ok !-e $path, 'file has been cleaned up';
$file = Asset::File->new(cleanup => 0)->add_chunk('test');
is $file->md5sum, '098f6bcd4621d373cade4e832627b4f6', "md5 is ok";
is $file->sha1sum, 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3', "sha1 is ok";
done_testing()
