use strict;
use warnings;

use Test::More tests => 3;

use Brat::Handler;

my $brat = Brat::Handler->new();
ok( defined($brat) && ref $brat eq 'Brat::Handler',     'Brat::Handler->new() works' );

$brat->loadList('examples/list.txt');
ok(scalar(@{$brat->_inputFiles}) == 3 , 'inputFiles/loadList works');
ok(scalar(@{$brat->_bratAnnotations}) == 3 , 'loadList and bratAnnotations works');
