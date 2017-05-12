package Data::Object::Autobox::Composite::Number;

use 5.010;
use strict;
use warnings;

use parent 'Data::Object::Autobox::Common';

use Data::Object::Class 'with';

with 'Data::Object::Role::Number';

sub data {
    goto &detract;
}
 
sub detract {
    return shift;
}

1;
