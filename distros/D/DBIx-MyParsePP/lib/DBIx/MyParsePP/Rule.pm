package DBIx::MyParsePP::Rule;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(MYPARSEPP_SHRINK_IDENTICAL MYPARSEPP_SHRINK_LEAFS MYPARSEPP_SHRINK_SINGLES MYPARSEPP_SHRINK_CHILDREN);

use strict;

1;

use constant RULE_NAME	=> 0;

use constant MYPARSEPP_SHRINK_IDENTICAL	=> 1;
use constant MYPARSEPP_SHRINK_LEAFS	=> 2;
use constant MYPARSEPP_SHRINK_SINGLES	=> 4;
use constant MYPARSEPP_SHRINK_CHILDREN	=> 8;

sub new {
	my $class = shift;
	my $rule = bless (\@_, $class);
	return $rule;
}

sub getName {
	return $_[0]->[RULE_NAME];
}

sub name {
	return $_[0]->[RULE_NAME];
}

sub children {
	my @rule = @{$_[0]};
	return @rule[1..$#rule];
}

sub getChildren {
	my @rule = @{$_[0]};
	return @rule[1..$#rule];
}

sub toString {
	my $rule = shift;

	if ($#{$rule} > -1) {
		return join('', map {
			$rule->[$_]->toString();	
		} (1..$#{$rule}) );
	} else {
		return undef;
	}
}

sub shrink {
	my ($parent, $flags) = @_;

	$flags = MYPARSEPP_SHRINK_IDENTICAL | MYPARSEPP_SHRINK_LEAFS | MYPARSEPP_SHRINK_SINGLES | MYPARSEPP_SHRINK_CHILDREN if not defined $flags;
	
	if (($#{$parent} == 0) && ($flags & MYPARSEPP_SHRINK_LEAFS)) {
		return undef;
	} elsif (($#{$parent} == 1) && ($flags & MYPARSEPP_SHRINK_SINGLES)) {
		if ($flags & MYPARSEPP_SHRINK_CHILDREN) {
			return $parent->[1]->shrink($flags);
 		} else {
			return $parent->[1];
		}
	} elsif ($flags & MYPARSEPP_SHRINK_CHILDREN) {
		my @new_children;

		foreach my $i (1..$#{$parent}) {
			my $child = $parent->[$i]->shrink($flags);
			if (
				($flags & MYPARSEPP_SHRINK_IDENTICAL) &&
				(ref($child) eq 'DBIx::MyParsePP::Rule') &&
				($child->name() eq $parent->name())
			) {
				push @new_children, $child->children() if defined $child->children();
			} else {
				push @new_children, $child if defined $child;
			}
		}

		my $new_rule = DBIx::MyParsePP::Rule->new($parent->name(), @new_children);
		return $new_rule->shrink($flags & ~MYPARSEPP_SHRINK_CHILDREN);
	} else {
		return $parent;	
	}
}


sub extractInner {
	my $rule = shift;
	return undef if ($#{$rule} == 0);

	my @matches;
	foreach my $i (1..$#{$rule}) {
		my $extract = $rule->[$i]->extract(@_);
		next if not defined $extract;
		if (ref($extract) eq 'ARRAY') {
			push @matches, @{$extract};
		} else {
			push @matches, $extract;
		}
	}

	if ($#matches == -1) {
		return undef;
	} elsif ($#matches == 0) {
		return $matches[0];
	} else {
		return \@matches;
	}
}

sub getFields {
	return $_[0]->extract('simple_ident_q','table_ident','ident');
}

sub fields {
	return $_[0]->getFields();
}

sub tables {
	return $_[0]->getTables();
}

sub getTables {
	my $rule = shift;

	my @tables_array;
	my %tables_hash;

	my $idents = $rule->extract('table_wild','table_ident','simple_ident_q');
	$idents = [$idents] if ref($idents) ne 'ARRAY';
	
	foreach my $ident (@{$idents}) {
		my $shrinked_ident = $ident->shrink();
		my @children = $shrinked_ident->children();

		my $table;

		if ($#children == -1) {			# No children
			$table = $shrinked_ident;
		} elsif ($#children == 0) {		# One child
			$table = $children[0];
		} elsif ($#children == 2) {
			if (
				($shrinked_ident->name() eq 'simple_ident_q') ||
				($shrinked_ident->name() eq 'table_wild')
			) {
				$table = $children[0];			# We have "database.table"
			} elsif ($shrinked_ident->name() eq 'table_ident') {
				$table = $children[2];			# We have "table.field"
			} else {
				print STDERR "Assertion: \$\#children == $#children but name() = ".$shrinked_ident->name()."\n";
				return undef;
			}
		} elsif ($#children == 4) {				# We have "database.table.field"
			$table = DBIx::MyParsePP::Rule->new( $ident->name(), @children[0..2] );
		} else {
			print STDERR "Assertion: \$\#children == $#children\n";
			return undef;
		}

		if (not exists $tables_hash{$table->toString()}) {
			push @tables_array, $table;
			$tables_hash{$table->toString()} = 1;	
		}
	}

	return \@tables_array;
		
}

sub extract {
	my $rule = shift;
	foreach my $match (@_) {
		return $rule if ($rule->name() eq $match);
	}
	return $rule->extractInner(@_);
}

sub print {
	return $_[0]->toString();
}

sub isEqual {
    return 0 if !$_[1]->isa( 'DBIx::MyParsePP::Rule' );
    return 0 if $_[0]->name() ne $_[1]->name();

    my @left_children = $_[0]->children();
    my @right_children = $_[1]->children();
    return 0 if @left_children != @right_children;

    for( my $i = 0; $i < @left_children; $i++ ) {
        return 0 if !$left_children[$i]->isEqual( $right_children[$i] );
    }

    return 1;
}

1;

__END__

=pod

=head1 NAME

DBIx::MyParsePP::Rule - Access individual elements from the DBIx::MyParsePP parse tree

=head1 SYNOPSIS

	use DBIx::MyParsePP;
	use DBIx::MyParsePP::Rule;

	my $parser = DBIx::MyParsePP->new();

	my $query = $parser->parse("SELECT 1");	# $query is a DBIx::MyParsePP::Rule object
	my $root = $query->root();
	print $root->name();			# prints 'query', the top-level grammar rule

	my @children = $root->chilren();	#
	print $children[0]->name();		# prints 'verb_clause', the second-level rule

	print ref($chilren[1]);			# prints 'DBIx::MyParsePP::Token'
	print $chilren[1]->type();		# prints END_OF_INPUT

	print [[[$root->chilren()]->[0]->chilren()]->[0]->chilren()]->[0]->name(); # Prints 'select'

=head1 DESCRIPTION

L<DBIx::MyParsePP> uses the C<sql_yacc.yy> grammar from the MySQL source to parse SQL strings. A
parse tree is produced which contains one branch for every rule encountered during parsing. This means
that very deep trees can be produced where only certain branches are important.

=head1 METHODS

C<new($rule_name, @chilren)> constructs a new rule

C<name()> and C<getName()> returns the name of the rule

C<chilren()> and C<getChildren()> return (as array) the right-side items that were matched for that rule, e.g.
its "child branches" in the parse tree.

C<toString()> converts the parse tree back into SQL by walking the tree and gathering all tokens in sequence.

=head1 EXTRACTING PARTS

C<extract(@names)> can be used to walk the tree and extract relevant parts. The method returns undef if no
part of the tree matched, a L<DBIx::MyParse::Rule> or a L<DBIx::MyParse::Token> object if a sigle match
was made, or a reference to an array of such objects if several parts matched. Names to the front of the
C<@names> list are matched first.

C<getFields()> or C<fields()> can be used to obtain all fields referenced in a parse tree or a part of it. Those functions
will return <undef> if no fields were referenced or a reference to an array containing C<Rule> objects for each field.
The Rule object can contain several 'ident' subrules if a database and/or a table name was specified for the given field.

C<getTables()> or C<tables()> can be used in the same manner to obtain all tables referenced in the parse tree. 

=head1 SHRINKING THE TREE

The raw tree produced by L<DBIx::MyParsePP> contains too many branches, many of them not containing any useful information.
The C<shrink($flags)> method is used to convert the tree into a more manageable form. C<$flags> can contain the
following constants joined by C<|>:

C<MYPARSEPP_SHRINK_IDENTICAL> if a parent and a child node are of the same type, they will be merged together. This way
expressions such as C<1 + 1 + 1> or C<col1, col2, col3> will be converted from a nested tree with one item per branch
into a single Rule containing a list of all the items and the tokens between them (e.g. C<+> or C<,>). Expressions
such as C<1 + 2 * 3> will remain as a tree because multiplication and addition have different precedence.

C<MYPARSEPP_SHRINK_LEAFS> will remove any Rules that have no children.

C<MYPARSEPP_SHRINK_SINGLES> will remove any Rules that have just a single child, linking the child directly
to the upper-level Rule.

C<MYPARSEPP_SHRINK_CHILDREN> will apply C<schrink()> recursively for all children.

If no flags are specified, all listed transformations are applied recursively.

=cut

# Please note that if you use C<MYPARSEPP_SHRINK_IDENTICAL> on expressions such as "1 + 1 + 1"



