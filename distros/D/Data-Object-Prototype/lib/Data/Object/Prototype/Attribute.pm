# Data::Object::Prototype Attribute Class
package Data::Object::Prototype::Attribute;

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

has 'options' => (
    is       => 'ro',
    isa      => ArrayObj,
    required => 1,
    coerce   => 1,
);

1;

