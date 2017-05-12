use strict;
package cvExpall;    # test  export of all symbols
use Config::Vars 'exportall';

var $cat   = 'Mittens';
var @dogs  = ('Rover', 'Fido');
var %hamsters = (Fang => 1, Reaper => 2, Death => 3);
1;
