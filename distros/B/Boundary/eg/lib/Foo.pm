package Foo;
use strict;
use warnings;

use Boundary::Impl qw(IFoo);

sub hello { ... }
sub world { ... }

sub new { my $class = shift; bless {} => $class }

1;
