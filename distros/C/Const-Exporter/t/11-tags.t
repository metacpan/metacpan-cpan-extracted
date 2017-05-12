use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Const::Exporter;

lives_ok {
    Const::Exporter->import( 'default' => [ foo => 1 ] );
} "default tag is not allowed";

dies_ok {
    Const::Exporter->import( 'all' => [ bar => 1 ] );
} "all tag is not allowed";

done_testing;
