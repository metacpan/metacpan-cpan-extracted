package Person::SimpleAddress;
use warnings;
use strict;
use parent 'Person::Base';

sub fulladdr {
    return $_[0]->{fulladdr} if @_ == 1;
    $_[0]->{fulladdr} = $_[1];
}
1;
