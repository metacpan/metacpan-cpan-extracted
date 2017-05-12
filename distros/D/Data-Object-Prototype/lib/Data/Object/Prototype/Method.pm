# Data::Object::Prototype Method Class
package Data::Object::Prototype::Method;

use 5.10.0;

use strict;
use warnings;

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Library -types;

our $VERSION = '0.06'; # VERSION

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'routine' => (
    is       => 'ro',
    isa      => CodeObj,
    required => 1,
    coerce   => 1,
);

1;

