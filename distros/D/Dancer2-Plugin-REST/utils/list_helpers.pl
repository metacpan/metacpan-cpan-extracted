# prints out the status helpers, mostly for the POD

use 5.10.0;

use Dancer2::Plugin::REST;

use List::Util qw/ pairgrep pairmap pairs /;
use List::UtilsBy qw/ sort_by /;

say join ' ' x 4, map { "status_$_" } reverse @$_
    for sort_by { $_->[1] } 
        pairs
        pairgrep { $a =~ /[^0-9]/ } Dancer2::Plugin::REST::_status_helpers;
