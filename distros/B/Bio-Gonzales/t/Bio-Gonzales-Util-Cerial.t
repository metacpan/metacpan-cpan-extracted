use warnings;
use Test::More;
use Data::Dumper;
use YAML::XS qw/LoadFile DumpFile/;
use JSON::XS;
use File::Temp qw/tempfile/;

BEGIN { use_ok( 'Bio::Gonzales::Util::Cerial', 'yspew', 'yslurp', 'jspew', 'jslurp' ); }

my ( $fh, $filename ) = tempfile();

my %data = ( 1 => 'eins', 2 => 'zwei', 3 => 'drei' );

yspew( $filename, \%data );

{
  my $check_data = LoadFile($filename);
  is_deeply( $check_data, \%data );
}
{
  my $check_data = yslurp($filename);
  is_deeply( $check_data, \%data );
}

jspew( $filename, \%data );

open my $fhx, '<', $filename or die "Can't open filehandle: $!";
my $check_json_data = do { local $/; <$fhx> };
$fhx->close;

{
  my $check_data = decode_json($check_json_data);
  is_deeply( $check_data, \%data );
}
{
  my $check_data = jslurp($filename);
  is_deeply( $check_data, \%data );
}

done_testing();

