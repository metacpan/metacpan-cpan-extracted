use strict;
use warnings;
use utf8;

use FindBin '$RealBin';
use lib "$RealBin/lib";
use MySubclass;

my $obj = MySubclass->new;

warn Dumper $obj->bar;
__END__