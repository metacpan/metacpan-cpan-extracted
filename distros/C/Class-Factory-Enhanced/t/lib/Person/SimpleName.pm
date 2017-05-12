package Person::SimpleName;
use warnings;
use strict;
use parent 'Person::Base';

sub fullname {
    return $_[0]->{fullname} if @_ == 1;
    $_[0]->{fullname} = $_[1];
}
1;
