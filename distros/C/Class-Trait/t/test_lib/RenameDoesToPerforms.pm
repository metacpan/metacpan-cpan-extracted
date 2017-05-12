package RenameDoesToPerforms;

use strict;
use warnings;

use Class::Trait qw/base performs/;

sub reverse {
    my ($proto, $message) = @_;
    return scalar reverse $message;
}
    
1;
