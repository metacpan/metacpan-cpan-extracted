#!perl
use strict;
use warnings;
use File::Which qw(which);
use Test::More;
use_ok 'Archive::Peek::External';

my @filenames
    = ( 'archive/README', 'archive/a/A', 'archive/a/b/B', 'archive/c/C' );

test_archive('t/archive.zip')     if which('unzip');
test_archive('t/archive.tgz')     if which('tar');
test_archive('t/archive.tar.bz2') if which('tar');

done_testing();

sub test_archive {
    my $filename = shift;
    my $peek = Archive::Peek::External->new( filename => $filename );
    isa_ok( $peek, 'Archive::Peek::External', "Can read $filename" );
    is_deeply( [ $peek->files ],
        \@filenames, "Can read files inside $filename" );
    is( $peek->file('archive/README'), 'This is in the root directory.

It is a file.
', "Can read archive/README inside $filename"
    );
}
