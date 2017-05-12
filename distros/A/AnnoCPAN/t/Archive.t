use strict;
use warnings;
use Test::More;
use AnnoCPAN::Archive;

#plan 'no_plan';
plan tests => 8;

# tar.gz archive
my $arch = AnnoCPAN::Archive->new(
    't/CPAN/authors/id/A/AL/ALICE/My-Dist-0.10.tar.gz');

isa_ok ( $arch, 'AnnoCPAN::Archive' );
isa_ok ( $arch, 'AnnoCPAN::Archive::Tar' );
is ( scalar $arch->files, 5, 'files (tar)');

my $file = $arch->read_file('My-Dist-0.10/Makefile.PL');
like ( $file, qr/WriteMakefile/,    'read_file (tar)' );


# zip archive
$arch = AnnoCPAN::Archive->new(
    't/CPAN/authors/id/A/AL/ALICE/My-Dist-0.40.zip');

isa_ok( $arch, 'AnnoCPAN::Archive' );
isa_ok( $arch, 'AnnoCPAN::Archive::Zip' );
is (scalar $arch->files, 7, 'files (zip)');

$file = $arch->read_file('My-Dist-0.40/Makefile.PL');
like ( $file, qr/WriteMakefile/,    'read_file (zip)' );
