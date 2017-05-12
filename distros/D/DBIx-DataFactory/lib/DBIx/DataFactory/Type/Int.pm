package DBIx::DataFactory::Type::Int;

use strict;
use warnings;
use Carp;

use base qw(DBIx::DataFactory::Type);

use Smart::Args;

sub type_name { 'Int' }

sub make_value {
    args my $class => 'ClassName',
         my $size  => 'Int';
    my $max = 10 ** $size - 1;
    return int rand($max);
}

1;
