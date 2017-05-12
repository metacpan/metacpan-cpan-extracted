#!/usr/bin/perl -w

use strict;
use Test::More tests => 22;
use File::Spec::Functions;
use File::Path;

BEGIN { use_ok('App::Info::Util') }

ok( my $util = App::Info::Util->new, "Create Util object" );

my $ext = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir = catdir 't', 'bin' unless -d $bin_dir;

# Test inheritance.
my $root = $util->rootdir;
is( $root, File::Spec::Functions::rootdir, "Inherited rootdir()" );
ok( $util->first_dir("C:\\foo", "C:\\bar", $root), "Test first_dir" );

# test first_path(). This is actually platform-dependent -- corrections
# welcome.
if ($^O eq 'MSWin32' or $^O eq 'os2') {
    is( $util->first_path("C:\\foo3424823;C:\\bar4294334834;$root"), $root,
        "Test first_path");
} elsif ($^O eq 'MacOS') {
    is( $util->first_path(":fooeijifjei:bareiojfiejfie:$root"), $root,
        "Test first_path");
} elsif ($^O eq 'VMS' or $^O eq 'epoc') {
    ok( ! defined $util->first_path,
        "first_path() returns undef on this platform" );
} else {
    # Assume unix.
    is( $util->first_path("/foo28384844:/bar949492393:$root"), $root,
        "Test first_path");
}

# Test first_file(). First, create a file to find.
my $tmpdir = $util->tmpdir;
my $tmp_file = $util->catfile($tmpdir, 'app-info.tst');
open F, ">$tmp_file" or die "Cannot open $tmp_file: $!\n";
print F "King of the who?\nWell, I didn't vote for ya.";
close F;

# Now find the file.
is( $util->first_file("this32432.foo", "that234324.foo", "C:\\foo434324.tst",
                      $tmp_file), $tmp_file, "Test first_file" );

# Now find the same file with first_cat_path().
is( $util->first_cat_path('app-info.tst', $util->path, $tmpdir),
    $tmp_file, "Test first_cat_path" );

# And test it again using an array.
is( $util->first_cat_path(['foo334.foo', 'bar224.foo', 'app-info.tst', '__ickypoo__'],
                          $util->path, $tmpdir, "C:\\mytemp"),
    $tmp_file, "Test first_cat_path with array" );

# Now find the directory housing the file.
is( $util->first_cat_dir('app-info.tst', $util->path, $tmpdir),
    $tmpdir, "Test first_cat_path" );

# And test it again using an array.
is( $util->first_cat_dir(['foo24342434.foo', 'bar4323423.foo', 'app-info.tst',
                          '__ickypoo__'], $util->path, $tmpdir, "C:\\mytemp"),
    $tmpdir, "Test first_cat_path with array" );

# Find an executable.
is( $util->first_exe('this.foo', 'that.exe', "$bin_dir/iconv$ext"),
    "$bin_dir/iconv$ext", 'Find executable' );

# Test first_cat_exe().
is( $util->first_cat_exe("iconv$ext", '.', $bin_dir),
    catfile($bin_dir, "iconv$ext"), 'Test first_cat_exe' );

# Test it again with an array.
is( $util->first_cat_exe(
    ['foowerwe.foo', 'barwere.foo', "iconv$ext", '__ickypoo__rs34'],
    '.', $bin_dir
), catfile($bin_dir, "iconv$ext"), "Test first_cat_exe with array" );

# Look for stuff in the file.
is( $util->search_file($tmp_file, qr/(of.*\?)/), 'of the who?',
    "Find 'of the who?'" );

# Look for a couple of things at once.
is_deeply( [$util->search_file($tmp_file, qr/(of\sthe)\s+(who\?)/)],
           ['of the', 'who?'], "Find 'of the' and 'who?'" );

ok( ! defined  $util->search_file($tmp_file, qr/(__ickypoo__)/),
    "Find nothing" );

# Look for a couple of things.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(di.*e)/)],
          ['of the who?', "didn't vote"], "Find a couple" );

# Look for a couple of things on the same line.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(Ki[mn]g)/)],
          ['of the who?', "King"], "Find a couple on one line" );

# Look for a couple of things, but have one be undef.
is_deeply([$util->multi_search_file($tmp_file, qr/(of.*\?)/, qr/(__ickypoo__)/)],
          ['of the who?', undef], "Find one but not the other" );

# And finally, find a couple of things where one is an array.
is_deeply([$util->multi_search_file($tmp_file, qr/(of\sthe)\s+(who\?)/,
                                    qr/(Ki[mn]g)/)],
          [['of the', 'who?'], 'King'], "Find one an array ref and a scalar" );

# Don't forget to delete our temporary file.
rmtree $tmp_file;

# Test files_in_dir.
my @dirs = (
    qw(. ..),
    (-d '.svn' ? '.svn' : ()),
    qw(mod_dir.so mod_include.so mod_perl.so not_mod.txt)
);
is_deeply [sort $util->files_in_dir(catdir(qw(t testmod))) ], \@dirs,
    'files_for_dir should return all files in a directory';

@dirs = grep { /^mod_/ } @dirs;
is_deeply
    [ sort $util->files_in_dir( catdir(qw(t testmod)), sub { /^mod_/ } ) ],
    \@dirs,
    'files_for_dir should use the filter I pass';

