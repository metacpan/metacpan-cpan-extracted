package DBM::Deep::Engine::Test;

use strict;
use warnings FATAL => 'all';

use base qw( DBM::Deep::Engine );

use DBM::Deep::Storage::Test;

sub new {
    return bless {
        storage => DBM::Deep::Storage::Test->new,
    }, shift;
}

1;
__END__
