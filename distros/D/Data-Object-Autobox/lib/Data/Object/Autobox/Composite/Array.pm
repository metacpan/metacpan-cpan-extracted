package Data::Object::Autobox::Composite::Array;

use 5.010;
use strict;
use warnings;

use parent 'Data::Object::Autobox::Common';

use Data::Object::Class 'with';

with 'Data::Object::Role::Array';

sub data {
    goto &detract;
}
 
sub detract {
    return shift;
}

sub list {
    goto &values;
}

1;
