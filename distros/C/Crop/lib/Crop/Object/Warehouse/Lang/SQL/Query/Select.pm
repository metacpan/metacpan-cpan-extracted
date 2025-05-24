package Crop::Object::Warehouse::Lang::SQL::Query::Select;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Select
	The SELECT query.
	
	The point is to parse declaration to the inner presentation and to store it in the 'parsed' attribute.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Util 'load_class';
use Crop::Object::Constants;
use Crop::Object::Collection;
use Crop::Object::Warehouse::Lang::SQL::Query::Select::Node;
use Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Root;
use Crop::Object::Warehouse::Lang::SQL::Clause;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	clause      - WHERE clause for initial part;
	expression  - raw expression to execute directly after 'SELECT'
	ext         - arrayref to EXT in form of [doc => {visible => 1} => ['file']
	limit       - LIMIT restriction, such 'LIMIT 5'; optional string or undef
	offset      - SQL offset
	order       - optinal 'order by' clause including asc/desc directive; arrayref with item for each field
	parsed      - inner tree presents the Query; see <Crop::Object::Warehouse::Lang::SQL::Query::Select::Node>.
	              Value of 'parsed' is a top level Root node.
	stack       - parsed nodes; arrayref of <Crop::Object::Warehouse::Lang::SQL::Query::Select::Node>
	start_class - class of the main table
	table       - hash of real tables used in query already; values is a number of privious use
	value       - array of values that uses 'WHERE' for their clauses; has personal getter 'val'
=cut
our %Attributes = (
	clause      => undef,
	expression  => undef,
	ext         => {default => []},
	limit       => undef,
	offset      => undef,
	order       => undef,
	parsed      => {mode => 'read'},
	stack       => {default => []},
	start_class => undef,
	table       => undef,
	value       => {default => []},  # has a personal getter 'val'
);

=begin nd
Method: build ( )
	Parse incomming structure to the inner presentation.
	
Returns:
	$self;
=cut
sub build {
	my $self = shift;
	
	return $self if defined $self->{expression};
	
	my $root = Crop::Object::Warehouse::Lang::SQL::Query::Select::Node::Root->new(
		class  => $self->{start_class},
	);

	++$self->{table}{$root->table};
	
	$root->clause(Crop::Object::Warehouse::Lang::SQL::Clause->new($self->{clause})) if $self->{clause};
	
	$self->{parsed} = $root;
	push @{$self->{stack}}, $root;

	my $table = $root->table_effective;
	if (defined $self->{order}) {
		/\./ or $_ = "$table.$_" for @{$self->{order}};
	}
	
	$self->_parse_ext($self->{ext});
}

=begin nd
Method: DESTROY ( )
	Clean up recursive references.
=cut
sub DESRTOY {
	my $self = shift;
	
	$self->foreach_prepared($self->{parsed}, sub {
		my $node = shift;
		
		$node->parent(undef);
	});
}

=begin nd
Method: foreach_prepared ($node, $cb)
	Execute routine $cb for each $node.
=cut
sub foreach_prepared {
	my ($self, $node, $cb) = @_;
	
	$cb->($node);
	$self->foreach_prepared($_, $cb) for $node->child->List;
}

=begin nd
Method: _parse_ext ($ext)
	Parse EXT for current node.
	
	Could be called recursively for each arrayref it the EXT-tree.
	
Parameters:
	$ext - arrayref to the extended declaration in form of call.
	>  $ext = [doc => {visible => 1} => ['file'], qw/ picture units /]
	
Returns:
	$self - if ok
	undef - otherwise
=cut
sub _parse_ext {
	my ($self, $ext) = @_;
	
	return $self unless defined $ext;

	my $i = 0;
	while ($i < @$ext) {
		return warn 'OBJECT: Extend of non-scalar name is prohibited' if ref $ext->[$i];
	
		my $parent = $self->{stack}[-1];
		my $extern = $parent->class->Attributes->extern($ext->[$i]);

		++$i;  # next token

		my $clause;
		if ($i < @$ext and ref $ext->[$i] eq 'HASH') {
			$clause = Crop::Object::Warehouse::Lang::SQL::Clause->new($ext->[$i]);
			++$i;
		}
		
		my $node = $extern->make_link($parent);
		$node->clause($clause) if $clause;
		
		my $child;
		$child = $ext->[$i] if $i < @$ext and ref $ext->[$i] eq 'ARRAY';
		if ($child) {
			push @{$self->{stack}}, $node;
			$self->_parse_ext($child);
			pop @{$self->{stack}};
			
			++$i;
		}
	}

	$self;
}

=begin nd
Method: print_sql ( )
	Compose query string based on the inner presentation.
	
Returns:
	SQL string + values
=cut
sub print_sql {
	my $self = shift;
	
	my $query = 'SELECT ';
	
	if (defined $self->{expression}) {
		$query .= $self->{expression};
	} else {
		my @from;
		my @field;
		my @where;
		$self->foreach_prepared($self->{parsed}, sub {
			my $node = shift;
			
			for (@{$node->attr}) {
				push @field, $node->table_effective . '.' . $_->name . ' AS ' . $node->table_effective . '$' . $_->name;
			}

			my $table;
			my $parent = $node->parent;
			$table .= 'LEFT JOIN ' if $parent;
			$table .= $node->table;
			$table .= ' AS ' . $node->table_effective if $node->table_effective ne $node->table;
			if ($parent) {
				$table .= ' ON ';

				my @link;
				while (my ($src, $dst) = each %{$node->parent_link}) {
					push @link, $parent->table_effective . '.' . $src . ' = ' . $node->table_effective . '.' . $dst;
				}
				$table .= join ' AND ', @link;
			}
			push @from, $table;
			
			if ($node->clause) {
				my ($sql, $val) = $node->clause->print_sql($node->table_effective);  # clause->print_sql returns two-element array

				if ($sql) {
				      push @where, $sql;
				      push @{$self->{value}}, @$val;
				}
			}
		});
		
		$query .= join ', ', @field;
		$query .= " FROM @from";
		$query .= " WHERE " . join ' AND ', @where if @where;
		$query .= ' ORDER BY ' . join ' AND ', @{$self->{order}} if defined $self->{order};
		$query .= " OFFSET $self->{offset} " if defined $self->{offset};
		$query .= " LIMIT $self->{limit}" if defined $self->{limit};
	}
	
	($query, $self->{value});
}

1;
