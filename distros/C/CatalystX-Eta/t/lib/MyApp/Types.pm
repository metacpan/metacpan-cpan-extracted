package MyApp::Types;

use MooseX::Types -declare => [
    qw( DataStr
      )
];
use MooseX::Types::Moose qw(ArrayRef HashRef CodeRef Str ScalarRef);
use Moose::Util::TypeConstraints;

use DateTimeX::Easy;

subtype DataStr, as Str, where {
    eval { DateTimeX::Easy->new($_)->datetime };
    return $@ eq '';
}, message { "$_ data invalida" };

coerce DataStr, from Str, via {
    DateTimeX::Easy->new($_)->datetime;
};

1;
