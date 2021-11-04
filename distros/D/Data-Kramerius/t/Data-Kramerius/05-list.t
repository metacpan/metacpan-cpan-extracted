use strict;
use warnings;

use Data::Kramerius;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Kramerius->new;
my @ret = $obj->list;
is(@ret, 47, 'Number of Kramerius systems in data is 47.');
