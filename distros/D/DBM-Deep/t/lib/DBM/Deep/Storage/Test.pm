package DBM::Deep::Storage::Test;

use strict;
use warnings FATAL => 'all';

use base qw( DBM::Deep::Storage );

sub new {
    return bless {
    }, shift;
}

1;
__END__
