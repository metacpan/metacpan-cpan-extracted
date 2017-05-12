package Data::Random::Contact::Types::Internal;
BEGIN {
  $Data::Random::Contact::Types::Internal::VERSION = '0.05';
}

use strict;
use warnings;
use namespace::autoclean;

use Class::Load qw( load_class );

use MooseX::Types -declare => [
    qw(
          Country
          Language
        )
];
use MooseX::Types::Moose qw( ClassName );

#<<<
subtype Country,
    as ClassName;

subtype Language,
    as ClassName;
#>>>

1;
