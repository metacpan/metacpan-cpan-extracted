#!perl
use strict;
use warnings;
use File::Path;
use File::Slurp;
use Path::Class;
use Test::More;
use_ok 'Archive::Extract::Libarchive';

my @filenames
    = ( 'archive/README', 'archive/a/A', 'archive/a/b/B', 'archive/c/C' );

my $extracted = 't/extracted/';

test_archive('t/archive.zip');
test_archive('t/archive.tgz');
test_archive('t/archive.tar.bz2');

my $ae_build = Archive::Extract::Libarchive->new( archive => 'Build.PL' );
is( $ae_build->extract, 0, 'Can not extract Build.PL' );
like( $ae_build->error, qr/Unrecognized archive format/, "Have error" );

done_testing();

sub test_archive {
    my $filename = shift;
    my $ae = Archive::Extract::Libarchive->new( archive => $filename );
    isa_ok( $ae, 'Archive::Extract::Libarchive', "Can read $filename" );

    rmtree($extracted) if -d $extracted;
    is( $ae->extract( to => $extracted ), 1, "Can extract $filename" );
    is( $ae->extract_path, $extracted, "extract_path set" );
    is( $ae->error, undef, "Do not have error" );
    is_deeply( [ sort @{ $ae->files } ],
        \@filenames, "Can read files inside $filename" );
    my %files;
    foreach my $filename (@filenames) {
        $files{$filename} = read_file( file( $extracted, $filename ) );
    }
    is_deeply(
        \%files,
        {   'archive/a/b/B' => 'And this is inside a *and* inside b.

It is a file.
',
            'archive/c/C' => 'This is inside c.

It is a file.
',
            'archive/README' => 'This is in the root directory.

It is a file.
',
            'archive/a/A' => 'And this is inside a.

It is a file.
'
        },
        'Can read all files via iterate'
    );
}
