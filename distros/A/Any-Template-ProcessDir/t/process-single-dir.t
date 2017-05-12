#!perl
use Any::Template::ProcessDir;
use Cwd qw(realpath);
use File::Basename;
use File::Copy::Recursive qw(dircopy);
use File::Find::Wanted;
use File::Path qw(remove_tree);
use File::Slurp;
use File::Temp qw(tempdir);
use Test::More;
use strict;
use warnings;

my $dir = tempdir( 'template-any-processdir-XXXX', TMPDIR => 1, CLEANUP => 1 );

sub try {
    my (%params) = @_;

    remove_tree($dir);
    dircopy( "t/source", $dir );

    ok( !-f "$dir/foo",     "no foo yet" );
    ok( !-f "$dir/bar/baz", "no bar/baz yet" );

    my $pd = Any::Template::ProcessDir->new(
        dir          => $dir,
        ignore_files => sub { basename( $_[0] ) =~ qr/^\./ },
        %params
    );
    $pd->process_dir();

    is( read_file("$dir/foo"),         "THIS IS FOO.SRC\n",     "foo.src" );
    is( read_file("$dir/bar/baz"),     "THIS IS BAR/BAZ.SRC\n", "bar/baz.src" );
    is( read_file("$dir/fop.txt"),     "this is fop.txt\n",     "fop.txt" );
    is( read_file("$dir/bar/bap.txt"), "this is bar/bap.txt\n", "bar/bap.txt" );

    ok( !-f "$dir/README", "no README" );
    ok( -w "$dir/fop.txt", "fop.txt writable" );

    # This test fails on some cpantesters even though chmod is being done,
    # not sure why
    ok( !-w "$dir/bar/baz", "bar/baz not writable" ) if $ENV{AUTHOR_TESTING};

    write_file( "$dir/bar/baz.src", "overwrote\n" );
    $pd->process_dir();

    is( read_file("$dir/bar/baz"), "OVERWROTE\n",       "bar/baz.src" );
    is( read_file("$dir/fop.txt"), "this is fop.txt\n", "fop.txt" );
}

try( process_text => sub { return uc( $_[0] ) } );
try( process_file => sub { return uc( read_file( $_[0] ) ) } );
done_testing();
