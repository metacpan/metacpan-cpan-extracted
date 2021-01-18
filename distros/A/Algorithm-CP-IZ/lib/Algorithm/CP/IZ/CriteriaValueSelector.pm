#
# criteria function to ValueSelector
#
package Algorithm::CP::IZ::CriteriaValueSelector;

use strict;
use warnings;

# Set by search method
our $CriteriaFunction;

sub new {
    my $class = shift;
    my ($v, $index) = @_;

    my $values = $v->domain;
    my %map;

    for my $val (@$values) {
	$map{$val} = &$CriteriaFunction($index, $val);
    }

    $values = [
	sort {
	    $map{$a} <=> $map{$b}
	    || $a <=> $b;
	} @$values];
    
    my $self = {
	_values => $values,
	_pos => 0,
    };
    
    bless $self, $class;
}

sub next {
    my $self = shift;
    my ($v, $index) = @_;

    my $pos = $self->{_pos};
    my $values = $self->{_values};
    return if ($pos >= @$values);

    my @ret = (&Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ, $values->[$pos]);
    $self->{_pos} = ++$pos;

    return @ret;
}


1;
