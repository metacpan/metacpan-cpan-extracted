use Test::More tests => 3;
use Acme::MetaSyntactic;
use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }

my $meta = Acme::MetaSyntactic->new( 'test_ams_cover' );
eval { my $name = $meta->name; };
like( $@, qr!^Metasyntactic list test_ams_cover does not exist!, "So there!" );

$meta = Acme::MetaSyntactic->new();
eval { $meta->name( test_ams_list => 2 ); };
like( $@, qr!^Metasyntactic list test_ams_list does not exist!, "AMS::test_ams_list not there yet" );

push @INC, $dir;
eval { $meta->name( test_ams_list => 2 ); };
is( $@, '', 'AMS::test_ams_list in @INC now' );

