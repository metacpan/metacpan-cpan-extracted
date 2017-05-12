package Anarres::Mud::Driver::Compiler::Visitor;

use strict;
use warnings;
use vars qw(@ISA);
use Exporter;

@ISA = qw(Exporter);

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	return bless $self, $class;
}

sub visit_child {
	my ($self, $node, $index) = @_;
	my $child = $node->value($index);
	$child->accept($self);
}
