package SpecialClass;
use strict;use warnings;
use overload
    '""' => \&to_string,
    '0+' => \&to_number,
        fallback=>1;

sub new { my ($class,%data) = @_; bless {%data},$class }
sub to_string { return $_[0]->{str} || 'foo' }
sub to_number { return $_[0]->{num} || 12 }

1;
