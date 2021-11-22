#!perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use_ok 'Archive::Peek';

my @filenames
    = ( 'archive/README', 'archive/a/A', 'archive/a/b/B', 'archive/c/C' );

test_archive('t/archive.zip');
test_archive('t/archive.tgz')     if Archive::Tar->has_zlib_support;
test_archive('t/archive.tar.bz2') if Archive::Tar->has_bzip2_support;

subtest "Test opening empty file" => sub {
	my ($empty_fh, $empty_path) = tempfile( SUFFIX => '.zip' );
	my $empty_peek = Archive::Peek->new( filename => $empty_path );
	eval { $empty_peek->files; 1 } and fail 'No exception on empty file';
	pass "Exception on empty file: $@" if $@;
};

done_testing();

sub test_archive {
    my $filename = shift;
    my $peek = Archive::Peek->new( filename => $filename );
    isa_ok( $peek, 'Archive::Peek', "Can read $filename" );
    is_deeply( [ $peek->files ],
        \@filenames, "Can read files inside $filename" );
    is( $peek->file('archive/README'), 'This is in the root directory.

It is a file.
', "Can read archive/README inside $filename"
    );
}
