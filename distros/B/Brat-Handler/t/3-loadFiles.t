use strict;
use warnings;

use Test::More tests => 3;

use Brat::Handler;

my $brat = Brat::Handler->new();
ok( defined($brat) && ref $brat eq 'Brat::Handler',     'Brat::Handler->new() works' );

$brat->loadDir('examples');
ok(scalar(@{$brat->_inputFiles}) == 3 , 'inputFiles/loadFile works');
ok(scalar(@{$brat->_bratAnnotations}) == 3 , 'loadFile and bratAnnotations works');
