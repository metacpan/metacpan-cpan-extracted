use strict;
use warnings;

use FindBin;
use Path::Class qw/ dir /;
use HTML::Mason::Interp;

my $interp = HTML::Mason::Interp->new(
    comp_root => ''.dir( $FindBin::Bin, 'root' )->absolute,
);

$interp->exec( '/hello.mason', name => 'Georges' );


