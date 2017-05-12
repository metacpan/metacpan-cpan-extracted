package Bubblegum::Object::Role::Ref;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'with';
use Bubblegum::Constraints -isas, -types;

use Scalar::Util ();

with 'Bubblegum::Object::Role::Defined';

our $VERSION = '0.45'; # VERSION

sub refaddr {
    return Scalar::Util::refaddr
        type_reference CORE::shift;
}

sub reftype {
    return Scalar::Util::reftype
        type_reference CORE::shift;
}

1;
