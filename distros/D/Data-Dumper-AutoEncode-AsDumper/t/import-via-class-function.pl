use strict;
use warnings;
use utf8;

use FindBin '$RealBin';
use lib "$RealBin/lib";
use MyClass;

my $obj = MyClass->new;

warn Dumper $obj->foo;
__END__