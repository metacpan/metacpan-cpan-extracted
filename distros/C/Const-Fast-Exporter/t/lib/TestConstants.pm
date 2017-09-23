package TestConstants;

use 5.010;
use Const::Fast::Exporter;

const our $SCALAR => 42;
const our @ARRAY  => qw/ there can be only one /;
const our %HASH   => ( x => 12, y => 67 );

our $MUTABLE = 12;

1;
