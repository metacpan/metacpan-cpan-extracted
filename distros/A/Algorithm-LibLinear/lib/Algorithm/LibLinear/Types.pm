package Algorithm::LibLinear::Types;

use 5.014;
use List::MoreUtils qw//;
use Type::Library -base;
use Types::Standard qw/Dict Int Map Num/;

my $Feature = __PACKAGE__->add_type(
    constraint => q!List::MoreUtils::all { $_ > 0 } keys %$_!,
    name => 'Feature',
    parent => Map[Int, Num],
);

__PACKAGE__->add_type(
    name => 'FeatureWithLabel',
    parent => Dict[ feature => $Feature, label => Num ],
);

1;
