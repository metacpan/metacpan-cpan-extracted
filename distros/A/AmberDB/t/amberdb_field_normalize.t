use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use AmberDB;

my $temp_dir = tempdir( CLEANUP => 1 );
my $schema_dir = File::Spec->catdir( $temp_dir, 'schema' );
mkdir $schema_dir;

# Write test norm file
my $norm_file = File::Spec->catfile( $schema_dir, 'catalog_attributes.norm' );
open my $nfh, '>:encoding(UTF-8)', $norm_file or die $!;
print $nfh <<'NORM';
{
	name  => "Test Normalization",
	table => "catalog_attributes",
	preprocess => [
		[ qr/([A-Za-zÇĞİÖŞÜçğıöşü])(\d)/, '$1 $2' ],
		[ qr/(\d)([A-Za-zÇĞİÖŞÜçğıöşü])/, '$1 $2' ],
	],
	rules => [
		{
			field => "page_count",
			match => qr/\b(\d+)\s*s\.\b/i,
			type  => "integer",
		},
		{
			field => "paper_type",
			map   => [
				[ qr/2\.?\s*Hamur/i => "2. Hamur" ],
				[ qr/1\.?\s*Hamur/i => "1. Hamur" ],
			],
		},
		{
			field => "publish_year",
			match_all => qr/\b(19\d\d|20[0-2]\d)\b/,
			select => "max",
			type  => "integer",
		},
	],
}
NORM
close $nfh;

my $adb = AmberDB->new(
    path => {
        dbase_dir  => $temp_dir,
        schema_dir => $schema_dir,
    }
);

subtest "1. Basic field_normalize functionality" => sub {
    my $raw = "14 x 20 cmTürkçe133 s.İstanbul2. HamurAralık 2002";
    my $res = $adb->field_normalize( "catalog_attributes", $raw );

    is( $res->{page_count}, 133, 'page_count extracted as 133' );
    is( $res->{paper_type}, '2. Hamur', 'paper_type mapped to 2. Hamur' );
    is( $res->{publish_year}, 2002, 'publish_year extracted as 2002' );
    is( $res->{raw_features}, $raw, 'raw_features preserved intact' );
};

subtest "2. Missing norm file fallback" => sub {
    my $res = $adb->field_normalize( "non_existent_table", "Some text" );
    is_deeply( $res, { raw_features => "Some text" }, 'Fallback preserves raw_features without dying' );
};

done_testing();
