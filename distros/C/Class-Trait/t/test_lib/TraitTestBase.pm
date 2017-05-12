package TraitTestBase;

use strict;
use warnings;

use Class::Trait "TPrintable";

use overload (
    '==' => "_equals"
);    

sub new {
    my ($class, $value) = @_;
    my $test = {
        value => $value || 0
    };
    bless($test, $class);
    return $test;
}

sub _equals {
    my ($self, $value) = @_;
    return ($self->{value} == $value);
}

sub toString {
    my ($self) = @_;
    return $self->{value};
}  

1;
