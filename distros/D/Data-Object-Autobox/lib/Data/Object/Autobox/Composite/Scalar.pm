package Data::Object::Autobox::Composite::Scalar;

use 5.010;
use strict;
use warnings;

use parent 'Data::Object::Autobox::Common';

use Data::Object::Class 'with';

with 'Data::Object::Role::Scalar';

sub data {
    goto &detract;
}
 
sub detract {
    return shift;
}

1;
