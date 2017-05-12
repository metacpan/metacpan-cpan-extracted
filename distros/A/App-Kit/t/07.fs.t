use Test::More;
use Test::Exception;
use Class::Unload;

use App::Kit;

diag("Testing fs() App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

is( $app, $app->fs->_app, '_app() returns instantiation app' );

# $app->fs->cwd
ok( !exists $INC{'Cwd.pm'}, 'Sanity: Cwd not loaded before cwd()' );
is( $app->fs->cwd, Cwd::cwd(), 'cwd() meth returns same Cwd::cwd' );    # since the method loads the module the second arg works without an explicit use statement
ok( exists $INC{'Cwd.pm'}, 'Cwd lazy loaded on initial cwd()' );

# $app->fs->spec
Class::Unload->unload('File::Spec');                                    # Class::Unload brings File::Spec in
ok( !exists $INC{'File/Spec.pm'}, 'Sanity: File::Spec not loaded before spec()' );
is( $app->fs->spec, 'File::Spec', 'spec returns class name for method calls' );
ok( exists $INC{'File/Spec.pm'}, 'File::Spec lazy loaded on initial spec()' );

# $app->fs->bindir
Class::Unload->unload('FindBin');
ok( !exists $INC{'FindBin.pm'}, 'Sanity: Findbin not loaded before bindir()' );
is( $app->fs->bindir, $FindBin::Bin, 'bindir() returns $Findbin::Bin first' );
ok( exists $INC{'FindBin.pm'}, 'Findbin lazy loaded on initial bindir()' );
{
    local $FindBin::Bin = undef;
    no warnings 'redefine';
    local *FindBin::again = sub { return "foo" };

    delete $app->fs->{bindir};
    is( $app->fs->bindir, 'foo', 'bindir() returns FindBin->again second' );

    *FindBin::again = sub { return };
    delete $app->fs->{bindir};
    is( $app->fs->bindir, $app->fs->cwd, 'bindir() returns cwd third' );
}
is( $app->fs->bindir("mybin"), 'mybin', 'bindir() sets and returns manually set value' );
is( $app->fs->bindir,          'mybin', 'bindir() returns manually set value' );

# $app->fs->tmpdir
ok( !exists $INC{'File/Temp.pm'}, 'Sanity: File::Temp not loaded before tmpdir()' );
my $dir = $app->fs->tmpdir;
ok( -d $dir,                     'tmpdir() returns file name' );
ok( exists $INC{'File/Temp.pm'}, 'File::Temp lazy loaded on initial tmpdir()' );

# $app->fs->tmpfile
Class::Unload->unload('File::Temp');
ok( !exists $INC{'File/Temp.pm'}, 'Sanity: File::Temp not loaded before tmpfile()' );
my $file;
{    # hack to silence warnings due to Class::Unload not being able to fully do some things (see rt 88888)
    local $SIG{__WARN__} = sub { 1 };
    $file = $app->fs->tmpfile;
}
ok( -f $file,                    'tmpfile() returns file name' );
ok( exists $INC{'File/Temp.pm'}, 'File::Temp lazy loaded on initial tmpfile()' );

# ########################
# #### File::Path::Tiny ##
# ########################

my $fpt_dir = $app->fs->tmpdir;
my $mk_me = $app->fs->spec->catdir( $fpt_dir, qw(foo bar baz wop) );

# $app->fs->mkpath
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny  not loaded before mkpath()' );
ok $app->fs->mkpath($mk_me), 'mkpath() returns true';
ok -d $mk_me, 'mkpath() creates path';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial mkpath()' );

# $app->fs->rmpath
Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before rmpath()' );
ok $app->fs->rmpath($mk_me), 'rmpath() returns true';
ok !-d $mk_me, 'rmpath() removes path';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial rmpath()' );

# $app->fs->empty_dir
Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before empty_dir()' );
ok $app->fs->empty_dir($fpt_dir), 'empty_dir() rereturns true';
ok -d $fpt_dir, 'empty_dir() does not remove given dir';
opendir my $dh, $fpt_dir || die "Could not open “$fpt_dir”: $!";
my @con = grep { !m/^..?$/ } readdir($dh);
close $dh;
is_deeply \@con, [], 'empty_dir() empties dir';
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial empty_dir()' );

# $app->fs->mk_parent
my $fpt_prnt = $app->fs->spec->catdir( $fpt_dir, "jibby" );
my $fpt_file = $app->fs->spec->catfile( $fpt_dir, "jibby", "wonka" );

Class::Unload->unload('File::Path::Tiny');
ok( !exists $INC{'File/Path/Tiny.pm'}, 'Sanity: File::Path::Tiny not loaded before mk_parent()' );
ok $app->fs->mk_parent($fpt_file), 'mk_parent() returns true';
ok -d $fpt_prnt,  "mk_parent() creates path's parent";
ok !-e $fpt_file, "mk_parent() does not create path";
ok( exists $INC{'File/Path/Tiny.pm'}, 'File::Path::Tiny lazy loaded on initial mk_parent()' );

ok( !exists $INC{'Path/Iter.pm'}, 'Sanity: Path::Iter not loaded before get_iterator()' );

my $iter = $app->fs->get_iterator($fpt_dir);
is( ref($iter), 'CODE', 'get_iterator() returns code ref' );
my @list;
while ( my $p = $iter->() ) {
    push @list, $p;
}
is_deeply( [ sort @list ], [ $fpt_dir, $fpt_prnt ], 'iterator returns expected' );
ok( exists $INC{'Path/Iter.pm'}, 'Path::Iter lazy loaded on initial get_iterator()' );

# ###################
# #### File::Slurp ##
# ###################

my $fsdir = $app->fs->tmpdir;
my $fsfile = $app->fs->spec->catfile( $fsdir, 'foo' );

# $app->fs->read_dir
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before read_dir()' );
is_deeply [ $app->fs->read_dir($fsdir) ], [], 'read_dir() on empty dir';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial read_dir()' );

# $app->fs->write_file
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before write_file()' );
ok $app->fs->write_file( $fsfile, "foo\nbar\n" ), 'write_file() returns true on success';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial write_file()' );
dies_ok { $app->fs->write_file( $fsdir, "foo\n" ) } 'write_file() failure is fatal';

# $app->fs->read_file
Class::Unload->unload('File::Slurp');
ok( !exists $INC{'File/Slurp.pm'}, 'Sanity: File::Slurp not loaded before read_file()' );
is_deeply [ $app->fs->read_file($fsfile) ], [ "foo\n", "bar\n" ], 'read_file() in array context';
ok( exists $INC{'File/Slurp.pm'}, 'File::Slurp lazy loaded on initial read_file()' );
is $app->fs->read_file($fsfile), "foo\nbar\n", 'read_file() in scalar context';
dies_ok { $app->fs->read_file($fsdir) } 'read_file() failure is fatal';

# more $app->fs->read_dir
is_deeply [ $app->fs->read_dir($fsdir) ], ['foo'], 'read_dir() on dir w/ files';
dies_ok { $app->fs->read_dir('no-exist') } 'read_dir() failure is fatal';

#############################
#### File::Copy::Recursive ##
#############################

# TODO use (forth coming AOTW) modern version

#################################
#### TODO: $app->fs->file_lookup ## Sprtin tailstails
#################################

my $tmp = $app->fs->tmpdir;
$app->fs->bindir($tmp);
my $main_dir = $app->fs->spec->catdir( $tmp, '.appkit.d' );

is_deeply( [ $app->fs->file_lookup ], [$main_dir], 'file_lookup(): no args gives inc dirs' );
is_deeply( [ $app->fs->file_lookup('fiddle.conf') ], [ $app->fs->spec->catfile( $main_dir, 'fiddle.conf' ) ], 'file_lookup(): one arg is file name' );
is_deeply( [ $app->fs->file_lookup( 'config', 'fiddle.conf' ) ], [ $app->fs->spec->catfile( $main_dir, 'config', 'fiddle.conf' ) ], 'file_lookup(): multi arg is paths parts' );

# { inc => […], }
is_deeply( [ $app->fs->file_lookup( { inc => [ 'myhack', 'yourhack' ], } ) ], [ 'myhack', 'yourhack', $main_dir ], 'file_lookup(): inc hash, no args gives inc dirs' );
is_deeply(
    [ $app->fs->file_lookup( 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fs->spec->catfile( 'myhack',   'fiddle.conf' ),
        $app->fs->spec->catfile( 'yourhack', 'fiddle.conf' ),
        $app->fs->spec->catfile( $main_dir,  'fiddle.conf' ),
    ],
    'file_lookup(): inc hash,one arg is file name'
);
is_deeply(
    [ $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fs->spec->catfile( 'myhack',   'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'yourhack', 'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( $main_dir,  'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc hash,multi arg is paths parts'
);

# fs->inc([…])
$app->fs->inc( [ 'foo', 'bar' ] );
is_deeply( [ $app->fs->file_lookup ], [ $main_dir, 'foo', 'bar' ], 'file_lookup(): inc(), no args gives inc dirs' );
is_deeply(
    [ $app->fs->file_lookup('fiddle.conf') ],
    [
        $app->fs->spec->catfile( $main_dir, 'fiddle.conf' ),
        $app->fs->spec->catfile( 'foo',     'fiddle.conf' ),
        $app->fs->spec->catfile( 'bar',     'fiddle.conf' ),
    ],
    'file_lookup(): inc(), one arg is file name'
);
is_deeply(
    [ $app->fs->file_lookup( 'config', 'fiddle.conf' ) ],
    [
        $app->fs->spec->catfile( $main_dir, 'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'foo',     'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'bar',     'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc(), multi arg is paths parts'
);

# { inc => […], } and  fss->inc([…])
is_deeply( [ $app->fs->file_lookup( { inc => [ 'myhack', 'yourhack' ], } ) ], [ 'myhack', 'yourhack', $main_dir, 'foo', 'bar' ], 'file_lookup(): inc() and inc hash, no args gives inc dirs' );
is_deeply(
    [ $app->fs->file_lookup( 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fs->spec->catfile( 'myhack',   'fiddle.conf' ),
        $app->fs->spec->catfile( 'yourhack', 'fiddle.conf' ),
        $app->fs->spec->catfile( $main_dir,  'fiddle.conf' ),
        $app->fs->spec->catfile( 'foo',      'fiddle.conf' ),
        $app->fs->spec->catfile( 'bar',      'fiddle.conf' ),
    ],
    'file_lookup(): inc() and inc hash, one arg is file name'
);
is_deeply(
    [ $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', 'yourhack' ], } ) ],
    [
        $app->fs->spec->catfile( 'myhack',   'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'yourhack', 'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( $main_dir,  'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'foo',      'config', 'fiddle.conf' ),
        $app->fs->spec->catfile( 'bar',      'config', 'fiddle.conf' ),
    ],
    'file_lookup(): inc() and inc hash, multi arg is paths parts'
);

# scalar context:

my $hack_dir = $app->fs->spec->catdir( $tmp, 'yourhack' );
my $foo_dir  = $app->fs->spec->catdir( $tmp, 'foo' );

my $hack_dir_c = $app->fs->spec->catdir( $hack_dir, 'config' );
my $cnfg_dir_c = $app->fs->spec->catdir( $main_dir, 'config' );
my $foo_dir_c  = $app->fs->spec->catdir( $foo_dir,  'config' );
$app->fs->mkpath($hack_dir_c) || die "Could not mkpath “$hack_dir_c”: $!";
$app->fs->mkpath($cnfg_dir_c) || die "Could not mkpath “$cnfg_dir_c”: $!";
$app->fs->mkpath($foo_dir_c)  || die "Could not mkpath “$foo_dir_c”: $!";
$app->fs->inc( [ $foo_dir, 'bar' ] );

$file = $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, undef, 'file_lookup() in scalar returns nothing when the path does not exist' );

$app->fs->write_file( $app->fs->spec->catfile( $foo_dir_c, 'fiddle.conf' ), '' );
$file = $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, undef, 'file_lookup() in scalar returns nothing when the path does exist but is empty' );

$app->fs->write_file( $app->fs->spec->catfile( $foo_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fs->spec->catfile( $foo_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns path when the path does exist and is not empty (inc)' );

$app->fs->write_file( $app->fs->spec->catfile( $cnfg_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fs->spec->catfile( $cnfg_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns first file found (prefix dir)' );

$app->fs->write_file( $app->fs->spec->catfile( $hack_dir_c, 'fiddle.conf' ), 'howdy' );
$file = $app->fs->file_lookup( 'config', 'fiddle.conf', { inc => [ 'myhack', $hack_dir ], } );
is( $file, $app->fs->spec->catfile( $hack_dir_c, 'fiddle.conf' ), 'file_lookup() in scalar returns first file found inc arg (inc arg)' );

#####################
#### YAML and JSON ##
#####################

my $yaml_file = $app->fs->spec->catfile( $hack_dir, 'my.yaml' );
my $json_file = $app->fs->spec->catfile( $hack_dir, 'my.json' );

my $my_data = {
    'str'   => 'I am a string.',
    'true'  => 1,
    'false' => 0,
    'undef' => undef,
    'empty' => "",
    'hash'  => {
        'nested' => {
            zop => 'bar',
        },
        'array' => [qw(a b c 42)],
    },
    'utf8' => "I \xe2\x99\xa5 Perl",    # (utf8 bytes)
    'int'  => int(42.42),
    'abs'  => abs(42.42),
};

my $yaml_cont = q{--- 
"abs": '42.42'
"empty": ''
"false": 0
"hash": 
  "array": 
    - 'a'
    - 'b'
    - 'c'
    - 42
  "nested": 
    "zop": 'bar'
"int": 42
"str": 'I am a string.'
"true": 1
"undef": ~
"utf8": 'I ♥ Perl'
};

#### YAML ##

ok( $app->fs->yaml_write( $yaml_file, $my_data ), 'yaml_write returns true on success' );
is( $app->fs->read_file($yaml_file), $yaml_cont, 'yaml_write had expected content written' );

my $data = $app->fs->yaml_read($yaml_file);
is_deeply( $data, $my_data, 'yaml_read loads expected data' );

ok( $app->fs->yaml_write( $yaml_file, $data ), 'yaml_write returns true on success again' );
is( $app->fs->read_file($yaml_file), $yaml_cont, 'yaml_write had expected content written' );

$data = $app->fs->yaml_read($yaml_file);
is_deeply( $data, $my_data, 'yaml_read loads expected data again' );

$app->fs->yaml_write( $yaml_file, { 'unistr' => "I \x{2665} Unicode" } );
is( $app->fs->read_file($yaml_file), qq{--- \n"unistr": 'I ♥ Unicode'\n}, 'yaml_write does unicode string as bytes (i.e. a utf8 string)' );
$data = $app->fs->yaml_read($yaml_file);
is_deeply( $data, { 'unistr' => "I \xe2\x99\xa5 Unicode" }, 'yaml_read reads previsouly unicode string written as bytes string as bytes' );

dies_ok { $app->fs->yaml_write($hack_dir) } 'yaml_write dies on failure';
dies_ok { $app->fs->yaml_read( $$ . 'asfvadfvdfva' . time ) } 'yaml_read dies on failure';

#### JSON ##

ok( $app->fs->json_write( $json_file, $my_data ), 'json_write returns true on success' );
like( $app->fs->read_file($json_file), qr/"utf8": "I ♥ Perl"/, 'json_write had expected content written' );    # string can change, no way to SortKeys like w/ YAML::Syck, so just make sure utf8 not written in escape syntax

$data = $app->fs->json_read($json_file);
is_deeply( $data, $my_data, 'json_read loads expected data' );

ok( $app->fs->json_write( $json_file, $data ), 'json_write returns true on success again' );
like( $app->fs->read_file($json_file), qr/"utf8": "I ♥ Perl"/, 'json_write had expected content written' );    # string can change, no way to SortKeys like w/ YAML::Syck, so just make sure utf8 not written in escape syntax

$data = $app->fs->json_read($json_file);
is_deeply( $data, $my_data, 'json_read loads expected data again' );

$app->fs->json_write( $json_file, { 'unistr' => "I \x{2665} Unicode" } );
is( $app->fs->read_file($json_file), '{"unistr": "I ♥ Unicode"}' . "\n", 'json_write does unicode string as bytes (i.e. a utf8 string)' );
$data = $app->fs->json_read($json_file);
is_deeply( $data, { 'unistr' => "I \xe2\x99\xa5 Unicode" }, 'json_read reads previsouly unicode string written as bytes string as bytes' );

dies_ok { $app->fs->json_write($hack_dir) } 'json_write dies on failure';
dies_ok { $app->fs->json_read( $$ . 'asfvadfvdfva' . time ) } 'json_read dies on failure';

done_testing;
