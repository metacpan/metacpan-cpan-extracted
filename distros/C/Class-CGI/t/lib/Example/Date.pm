package Example::Date;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    bless \%args, $class;
}

sub day   { shift->{day} }
sub month { shift->{month} }
sub year  { shift->{year} }

1;
