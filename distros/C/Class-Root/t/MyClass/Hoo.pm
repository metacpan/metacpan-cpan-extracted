package MyClass::Hoo;

use MyClass::Bar 'isa';
use MyClass::Baz 'isa';

package MyClass::Hoo::LOCAL;

use strict;
use warnings;

declare setvalue cname => "Hoo";

class_initialize;

declare attribute hoos => "HOOS";

class_verify;
