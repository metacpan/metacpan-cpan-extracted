package Thing;
use strict;
use Class::Spiffy -base;
use base 'Class::Spiffy';
our @EXPORT = qw(thing);

field volume => 11;

sub thing { Thing->new(@_) }

1;
