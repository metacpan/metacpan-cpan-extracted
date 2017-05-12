use Test::More;
use Beagle::Model::Task;

my $bark = Beagle::Model::Task->new();

isa_ok( $bark, 'Beagle::Model::Task' );
isa_ok( $bark, 'Beagle::Model::Entry' );

done_testing();
