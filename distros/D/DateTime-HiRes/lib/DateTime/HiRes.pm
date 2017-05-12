package DateTime::HiRes;

use strict;

use vars qw( $VERSION );
$VERSION = '0.01';

use DateTime;
use Time::HiRes;

sub now { shift; DateTime->from_epoch( epoch => Time::HiRes::time, @_ ) }

1;

__END__
