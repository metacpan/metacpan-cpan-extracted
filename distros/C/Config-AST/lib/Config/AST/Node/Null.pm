package Config::AST::Node::Null;
use parent 'Config::AST::Node';
use strict;
use warnings;
use Carp;

=head1 NAME

Config::AST::Node::Null - a null node    

=head1 DESCRIPTION

Implements null node - a node returned by direct retrieval if the requested
node is not present in the tree.    

In boolean context, null nodes evaluate to false.
    
=head1 METHODS

=head2 $node->is_null

Returns true.

=cut    
    
sub is_null { 1 }

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $key = $AUTOLOAD;
    $key =~ s/.*:://;
    if ($key =~ s/^([A-Z])(.*)/\l$1$2/) {
	return $self;
    }
    confess "Can't locate method $AUTOLOAD";
}

=head2 $node->as_string

Returns the string "(null)".

=cut    

sub as_string { '(null)' }

=head2 $node->value

Returns C<undef>.    

=cut

sub value { undef }

use overload
    bool => sub { 0 };

=head1 SEE ALSO

B<Config::AST>,    
B<Config::AST::Node>.

=cut    

1;
