package Ace::Freesubs;

use strict;
use vars qw($VERSION @ISA);
require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '1.00';

bootstrap Ace::Freesubs $VERSION;

1;

__END__
