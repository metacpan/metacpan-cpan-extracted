# this test is ripped from Parse::CPAN::Authors

use strict;
use warnings;
#use lib 'lib';
#use IO::Zlib;
#use Test::Exception;
use Test::More tests => 23;
use_ok('Acme::CPANAuthors::Utils::Authors');

my $filename   = "t/data/authors/01mailrc.txt";
my $gzfilename = "t/data/authors/01mailrc.txt.gz";

#my $fh = IO::Zlib->new( $gzfilename, "rb" )
#    || die "Failed to read $filename: $!";
#my $contents = join '', <$fh>;
#$fh->close;

# try with no filename - not supported
#chdir "t";
#my $p = Acme::CPANAuthors::Utils::Authors->new();
#is_fine($p);
#chdir "..";

# try with the filename
my $p = Acme::CPANAuthors::Utils::Authors->new($filename);
is_fine($p);

# try with the gzipped filename
$p = Acme::CPANAuthors::Utils::Authors->new($gzfilename);
is_fine($p);

# try with the contents
#$p = Acme::CPANAuthors::Utils::Authors->new($contents);
#is_fine($p);

# try with fake filename
eval { Acme::CPANAuthors::Utils::Authors->new("xyzzy") };
like $@ => qr/Failed to read/;

# try with fake gzipped filename
eval { Acme::CPANAuthors::Utils::Authors->new("xyzzy.gz") };
like $@ => qr/Failed to read/;

sub is_fine {
    my $p = shift;

    isa_ok( $p, 'Acme::CPANAuthors::Utils::Authors' );

    my $a = $p->author('AASSAD');
    isa_ok( $a, 'Acme::CPANAuthors::Utils::Authors::Author' );
    is( $a->pauseid, 'AASSAD' );
    is( $a->name,    "Arnaud 'Arhuman' Assad" );
    is( $a->email,   'arhuman@hotmail.com' );

    $a = $p->author('AJOHNSON');
    isa_ok( $a, 'Acme::CPANAuthors::Utils::Authors::Author' );
    is( $a->pauseid, 'AJOHNSON' );
    is( $a->name,    'Andrew L. Johnson' );
    is( $a->email,   'andrew-johnson@shaw.ca' );

    is_deeply(
        [ sort map { $_->pauseid } $p->authors ],
        [   qw(AADLER AALLAN
                AANZLOVAR AAR AARDEN AARONJJ AARONSCA AASSAD ABARCLAY AJOHNSON)
        ]
    );
}
