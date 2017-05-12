package TestApp::Types;
use MooseX::Types -declare => [qw( NotFoo NotBar )];
use MooseX::Types::Moose qw( Str );

subtype NotFoo, as Str, where { $_ ne 'foo' };
subtype NotBar, as Str, where { $_ ne 'bar' };

1;
