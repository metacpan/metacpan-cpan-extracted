package Person::ComplexName;
use warnings;
use strict;
use parent 'Person::Base';

sub firstname {
    return $_[0]->{firstname} if @_ == 1;
    $_[0]->{firstname} = $_[1];
}

sub lastname {
    return $_[0]->{lastname} if @_ == 1;
    $_[0]->{lastname} = $_[1];
}
1;
