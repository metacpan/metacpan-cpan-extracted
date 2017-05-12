package TestC;
#
use strict;
sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}
sub load1 {
    my ($self) = shift;
    sleep 1;
    return "one_value";
}
sub load2 {
    my ($self) = shift;
    sleep 2;
    return ("two","values");
}
###################################################################
1;
