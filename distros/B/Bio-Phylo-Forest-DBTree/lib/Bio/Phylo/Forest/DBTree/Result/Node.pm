package Bio::Phylo::Forest::DBTree::Result::Node;
use strict;
use warnings;
use Bio::Phylo::Forest::DBTree;
use Bio::Phylo::Forest::Node;
use Bio::Phylo::Util::Logger;
use base 'DBIx::Class::Core';
use base 'Bio::Phylo::Forest::Node';

my $log = Bio::Phylo::Util::Logger->new;

__PACKAGE__->table("node");

=head1 NAME

Bio::Phylo::Forest::DBTree::Result::Node - Phylogenetic database record as a node object

=head1 SYNOPSIS

 # same API is Bio::Phylo::Forest::Node
 
=head1 DESCRIPTION

This package implements an object-relational interface to records in a phylogenetic 
database. This way, the record can be used as if it's a tree node with the same 
programming interface as is used by L<Bio::Phylo>, but without making the demands that
loading an entire tree in memory would make.

=head1 DATABASE ACCESSORS

The following methods directly access fields of the database-backed node record. In 
principle, these methods can also be used as setters, although for the indexes and keys
you really need to know what you're doing or the topology of the tree could become 
irreparably corrupted.

=head2 id()

Returns primary key of the node object, an integer.

=head2 parent()

Returns the foreign key of the node object's parent, an integer.

=head2 left()

Returns the pre-order index of the node object, an integer.

=head2 right()

Returns the post-order index of the node object, an integer.

=head2 name()

Returns the node name, a string.

=head2 length()

Returns the node's branch length, a floating point number.

=head2 height()

Returns the node's height from the root, a floating point number.

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "int", is_nullable => 0 },
  "parent",
  { data_type => "int", is_nullable => 0 },
  "left",
  { data_type => "int", is_nullable => 1 },  
  "right",
  { data_type => "int", is_nullable => 1 },  
  "name",
  { data_type => "string", is_nullable => 0 },
  "length",
  { data_type => "float", is_nullable => 0 },
  "height",
  { data_type => "float", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

my $schema;
sub _schema {
	if ( not $schema ) {
		$schema = Bio::Phylo::Forest::DBTree->connect->resultset('Node');
	}
	return $schema;
}

=head1 NODE METHODS

These methods override methods of the same name in L<Bio::Phylo>, to make more efficient
use of the database.

=head2 get_parent()

Returns the node's parent, if any.

=cut

sub get_parent {
	my $self = shift;
	return $self->_schema->find($self->parent);
}

=head2 get_children_rs()

Returns the node's children, if any, as a L<DBIx::Class> result set.

=cut

sub get_children_rs {
	my $self = shift;
	my $id = $self->id;
	return $self->_schema->search({
		'-and' => [ 
			'parent' => { '==' => $id },
			'id'     => { '!=' => $id },
		]
	});
}

=head2 get_children()

Returns the node's children, if any, as an array reference.

=cut

sub get_children { [ shift->get_children_rs->all ] }

=head2 get_descendants_rs()

Returns the node's descendants, if any, as a L<DBIx::Class> result set.

=cut

sub get_descendants_rs {
	my $self = shift;
	return $self->_schema->search(
		{
			'-and' => [
				'left'  => { '>' => $self->left },
				'right' => { '<' => $self->right },
			]
		}
	)
}

=head2 get_descendants()

Returns the node's descendants, if any, as an array reference.

=cut

sub get_descendants { [ shift->get_descendants_rs->all ] }

=head2 get_terminals_rs()

Returns the node's descendant tips, if any, as a L<DBIx::Class> result set.

=cut

sub get_terminals_rs {
	my $self = shift;
	my $scalar = 'right';
	return $self->_schema->search(
		{
			'-and' => [
				'left'  => { '>' => $self->left },
				'right' => { '<' => $self->right },
				'left'  => { '==' => \$scalar },
			]
		}
	)	
}

=head2 get_terminals()

Returns the node's descendant tips, if any, as an array reference.

=cut

sub get_terminals { [ shift->get_terminals_rs->all ] }

=head2 get_internals_rs()

Returns the node's descendant internal nodes, if any, as a L<DBIx::Class> result set.

=cut

sub get_internals_rs {
	my $self = shift;
	my $scalar = 'right';
	return $self->_schema->search(
		{
			'-and' => [
				'left'  => { '>' => $self->left },
				'right' => { '<' => $self->right },
				'left'  => { '!=' => \$scalar },
			]
		}
	)
}

=head2 get_internals()

Returns the node's descendant internal nodes, if any, as an array reference.

=cut

sub get_internals { [ shift->get_internals_rs->all ] }

=head2 get_ancestors_rs()

Returns the node's ancestors, if any, as a L<DBIx::Class> result set.

=cut

sub get_ancestors_rs {
	my $self = shift;
	return $self->_schema->search(
		{
			'-and' => [
				'left'  => { '<' => $self->left },
				'right' => { '>' => $self->right },
			]
		}
	)
}

=head2 get_ancestors()

Returns the node's ancestors, if any, as an array ref.

=cut

sub get_ancestors { [ shift->get_ancestors_rs->all ] }

=head2 get_siblings_rs()

Returns the node's siblings, if any, as a L<DBIx::Class> result set.

=cut

sub get_siblings_rs {
	my $self = shift;
	return $self->_schema->search(
		{
			'-and' => [
				'parent' => { '==' => $self->parent },
				'id'     => { '!=' => $self->id },
			]
		}
	)
}

=head2 get_siblings()

Returns the node's siblings, if any, as an array ref.

=cut

sub get_siblings { [ shift->get_siblings_rs->all ] }

=head2 get_mrca()

Given another node in the same tree, returns the most recent common ancestor of the two.

=cut

sub get_mrca {
	my ( $self, $other ) = @_;
	my @lefts = sort { $a <=> $b } $self->left, $other->left;
	my @rights = sort { $a <=> $b } $self->right, $other->right;
	return $self->_schema->search(
		{ 
			'-and' => [ 
				'left'  => { '<' => $lefts[0] },
				'right' => { '>' => $rights[1] },
			]
		},
		{
			'order_by' => 'right',
			'rows'     => 1,
		}
	)->single;			
}

{
	no warnings 'recursion';
	sub _index {
		my ( $self, $counter, $height ) = @_;
		$height += ( $self->get_branch_length || 0 );
		
		# initialize or update counter
		if ( ref($counter) eq 'SCALAR' ) {
			$$counter = $$counter + 1;
		}
		else {
			my $i = 1;
			$counter = \$i;
		}
		
		# report progress
		if ( not $$counter % 1000 ) {
			$log->info("updated index ".$$counter);
		}
		
		# update and recurse
		$self->update({ 'left' => $$counter, 'height' => $height });		
		my @c = @{ $self->get_children };
		for my $child ( @c ) {
			$child->_index($counter, $height);
		}
		if ( @c ) {
			$$counter = $$counter + 1;
		}
		$self->update({ 'right' => $$counter });
	}
}

=head2 get_id()

Same as C<id()>, see above.

=cut

sub get_id { shift->id }

=head2 get_name()

Same as C<name()>, see above.

=cut

sub get_name { shift->name }

=head2 get_branch_length()

Same as C<length()>, see above.

=cut

sub get_branch_length { shift->length }

=head2 is_descendant_of()

Given another node, determines of the invocant is the descendant of the argument.

=cut

sub is_descendant_of {
	my ( $self, $other ) = @_;
	return ( $self->left > $other->left ) && ( $self->right < $other->right );
}

=head2 calc_patristic_distance()

Given another node, calculates the patristic distance between the two.

=cut

sub calc_patristic_distance {
	my ( $self, $other ) = @_;
	my $mrca = $self->get_mrca($other);
	my $mh = $mrca->height;
	my $sh = $self->height;
	my $oh = $other->height;
	return ( $sh - $mh ) + ( $oh - $mh );
}

1;