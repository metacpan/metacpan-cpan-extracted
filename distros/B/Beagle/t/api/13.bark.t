use Test::More;
use Beagle::Model::Bark;

my $bark = Beagle::Model::Bark->new();

isa_ok( $bark, 'Beagle::Model::Bark' );
isa_ok( $bark, 'Beagle::Model::Entry' );

done_testing();
