use Test::More tests => 2;
use Test::Exception;

use Backup::Hanoi;

dies_ok { Backup::Hanoi->new( ['A', 'B'] ) } 'die with two devices';

lives_ok { Backup::Hanoi->new( ['A', 'B', 'C'] ) } 'live with three devices';
