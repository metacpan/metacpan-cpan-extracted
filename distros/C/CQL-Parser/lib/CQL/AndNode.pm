package CQL::AndNode;

use strict;
use warnings;
use base qw( CQL::BooleanNode );

=head1 NAME

CQL::AndNode - represents an AND node in a CQL parse tree

=head1 SYNOPSIS

    use CQL::AndNode;
    my $node = CQL::AndNode->new( left => $left, right => $right );

=head1 DESCRIPTION

CQL::AndNode inherits from CQL::BooleanNode, where you will find
most of the functionality.

=cut

sub op { return 'and'; }

1;
