package CQL::BooleanNode;

use strict;
use warnings;
use base qw( CQL::Node );
use CQL::Utils qw( indent xq renderPrefixes );

=head1 NAME

CQL::BooleanNode - represents a boolean node in a CQL parse tree

=head1 SYNOPSIS
    
    n/a

=head1 DESCRIPTION

Base class for boolean nodes in a CQL parse tree. See CQL::AndNode
and CQL::OrNode. CQL::BooleanNode inherits from CQL::Node. Typically
you'll want to use CQL::AndNode or CQL::OrNode to instantiate the 
object.

=head1 METHODS

=head2 new()

You must pass in both a left and right parameter, which should be
CQL::Node objects.

=cut

sub new {
    my ( $class, %args ) = @_;
    return bless { left => $args{left}, right => $args{right} }, 
        ref($class) || $class;
}

=head2 left()

=cut

sub left {
    return shift->{left};
}

=head2 right()

=cut

sub right {
    return shift->{right};
}

=head2 toCQL()

=cut

sub toCQL {
    my $self = shift;
    my $left = $self->left();
    my $right = $self->right();
    ## return: (left) op (right)
    return 
        '(' . $left->toCQL() . ') ' .
        $self->op() .
        ' (' . $right->toCQL() . ')';
}

=head2 toSwish()

=cut

sub toSwish {
    my $self = shift;
    my $left = $self->left();
    my $right = $self->right();
    my $leftStr = $left->isa('CQL::TermNode') ? $left->toSwish() 
        : '('.$left->toSwish().')';  
    my $rightStr = $right->isa('CQL::TermNode') ? $right->toSwish() 
        : '('.$right->toSwish().')';
    return  $leftStr . " " . $self->op() . " " . $rightStr;
}

=head2 toXCQL()

=cut

sub toXCQL {
    my ($self,$level,@prefixes) = @_;
    $level = 0 if ! $level;
    my $left = $self->left();
    my $right = $self->right();
    my $xml = 
        indent($level)."<triple>\n".
        renderPrefixes($level+1,@prefixes).
        $self->opXCQL($level+1).
        indent($level+1)."<leftOperand>\n".
        $left->toXCQL($level+2).
        indent($level+1)."</leftOperand>\n".
        indent($level+1)."<rightOperand>\n".
        $right->toXCQL($level+2).
        indent($level+1)."</rightOperand>\n".
        indent($level)."</triple>\n";
    return $self->addNamespace( $level, $xml );
}

=head2 toLucene()

=cut

sub toLucene {
    my $self     = shift;
    my $left     = $self->left();
    my $right    = $self->right();
    my $leftStr  = $left->isa('CQL::TermNode') ? $left->toLucene() 
        : '('.$left->toLucene().')';  
    my $rightStr = $right->isa('CQL::TermNode') ? $right->toLucene() 
        : '('.$right->toLucene().')';

    return  join( ' ', $leftStr, uc $self->op(), $rightStr ) if $self->op() !~ /prox/;

    my $distance = 1;
    $distance = $1 if $self->op() =~ /\/distance[=><]{1,2}(\d+)/;
    return "\"$leftStr $rightStr\"~$distance";
}

sub opXCQL {
    my ($self,$level) = @_;
    return 
        indent($level)."<boolean>\n".
        indent($level+1)."<value>".xq($self->op())."</value>\n".
        indent($level)."</boolean>\n";
}

1;
