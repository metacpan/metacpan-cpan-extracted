package CQL::OrNode;

use strict;
use warnings;
use base qw( CQL::BooleanNode );

=head1 NAME

CQL::OrNode - represents an OR node in a CQL parse tree

=head1 SYNOPSIS

    use CQL::OrNode;
    my $node = CQL::OrNode->new( left => $left, right => $right );

=head1 DESCRIPTION

CQL::OrNode inherits from CQL::BooleanNode, where you'll find most of
the functionality.

=cut

sub op { return 'or'; }

1;
