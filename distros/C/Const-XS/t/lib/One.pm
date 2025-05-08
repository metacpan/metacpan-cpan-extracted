package One;

use Const::XS qw/const/;
use strict;
use warnings;

use base 'Import::Export';

our %EX = (
	'$one' => [qw/all/],
	'%two' => [qw/all/],
	'@three' => [qw/all/]
);

const our $one => "testing";
const our %two => (
	one => 1,
	two => 2,
	three => 3
);
const our @three => ( qw/1 2 3/ ); 

1;
