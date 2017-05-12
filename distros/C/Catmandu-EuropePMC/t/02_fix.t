use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Catmandu::Importer::EuropePMC;
use Catmandu::Fix qw/epmc_dblinks/;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::epmc_dblinks';
    use_ok $pkg;
}

require_ok $pkg;

my $db_rec = Catmandu::Importer::EuropePMC->new(
    pmid   => '10779411',
    module => 'databaseLinks',
    db     => 'uniprot',
    page   => '1',
)->first;

my $count = $db_rec->{dbCount};
ok( $count>1, "count after fix" );
my $fixer = Catmandu::Fix->new( fixes => ["epmc_dblinks('UNIPROT')"] );
my $fixed = $fixer->fix($db_rec);

is( $fixed->[0]->{info1}->{label}, "UniProt database number", "DB label" );
like( $fixed->[0]->{info1}->{content}, qr/\d+$/, "DB id" );
is( $fixed->[0]->{info4}->{content}, "PDB", "Source ok" );

done_testing;
