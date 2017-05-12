package Data::Object::Autobox::Common;

use 5.010;

use strict;
use warnings;

use Data::Object ();

our $VERSION = '0.14'; # VERSION

sub array {
    goto &Data::Object::data_array;
}

sub code {
    goto &Data::Object::data_code;
}

sub float {
    goto &Data::Object::data_float;
}

sub hash {
    goto &Data::Object::data_hash;
}

sub integer {
    goto &Data::Object::data_integer;
}

sub number {
    goto &Data::Object::data_number;
}

sub regexp {
    goto &Data::Object::data_regexp;
}

sub scalar {
    goto &Data::Object::data_scalar;
}

sub string {
    goto &Data::Object::data_string;
}

sub undef {
    goto &Data::Object::data_undef;
}

sub universal {
    goto &Data::Object::data_universal;
}

1;
