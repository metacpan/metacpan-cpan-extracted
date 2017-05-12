package Data::Object::Autobox::Composite::Integer;

use 5.010;
use strict;
use warnings;

use parent 'Data::Object::Autobox::Common';

use Data::Object::Class 'with';

with 'Data::Object::Role::Integer';

sub data {
    goto &detract;
}
 
sub detract {
    return shift;
}

1;
