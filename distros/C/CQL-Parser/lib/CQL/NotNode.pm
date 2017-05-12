package CQL::NotNode;

use strict;
use warnings;
use base qw( CQL::BooleanNode );

=head1 NAME

CQL::NotNode - represents a NOT node in a CQL parse tree

=head1 SYNOPSIS

    use CQL::NotNode;
    my $node = CQL::NotNode->new( left => $left, right => $right );

=head1 DESCRIPTION

CQL::NotNode inherits from CQL::BooleanNode, where you'll find most of
the functionality.

=cut

sub op { return 'not'; }

1;
