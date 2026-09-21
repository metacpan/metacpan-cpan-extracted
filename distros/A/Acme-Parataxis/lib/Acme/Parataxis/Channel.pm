use v5.40;
no warnings 'experimental::class', 'recursion';
use feature 'class';
use Acme::Parataxis::Semaphore;
class Acme::Parataxis::Channel v0.1.0 {
    field $capacity : param //= 2_000_000_000;
    field $sem_get = Acme::Parataxis::Semaphore->new( count => 0 );
    field $sem_put = Acme::Parataxis::Semaphore->new( count => $capacity );
    field @data : reader;
    ADJUST {
        $capacity >= 1 or die "Channel capacity must be >= 1 (got $capacity)\n";
    }

    method put ($value) {
        $sem_put->down;
        push @data, $value;
        $sem_get->up;
        1;
    }

    method get () {
        $sem_get->down;
        $sem_put->up;
        shift @data;
    }
    method size ()        { scalar @data }
    method shutdown ()    { $sem_get->adjust(1_000_000_000); 1 }
    method adjust ($diff) { $sem_put->adjust($diff) }
};
#
1;
