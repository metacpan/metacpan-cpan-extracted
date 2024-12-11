package Config::Proxy::Node::Section;
use strict;
use warnings;
use parent 'Config::Proxy::Node';
use Carp;

=head1 NAME

Config::Proxy::Node::Section - proxy configuration section

=head1 DESCRIPTION

Objects of this class represent a C<section> (or a C<compound statement>),
in a proxy configuration file.  A section is a statement that can contain
sub-statements.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{_tree} = [];
    return $self;
}

=head1 ATTRIBUTES

=head2 is_section

Always true.

=cut

sub is_section { 1 }

=head1 METHODS

=head2 kw

Returns the configuration keyword.

=head2 argv

Returns the list of arguments to the configuration keyword.

=head2 arg

    $s = $node->arg($n)

Returns the B<$n>th argument.

=head2 orig

Returns original line as it appeared in the configuration file.

=head2 locus

Returns the location of this statement in the configuration file (the
B<Text::Locus> object).

=head2 append_node

    $section->append_node(@nodes);

Takes a list of objects of B<Config::Proxy::Node> derived classes as
arguments. Adds these objects after the last node in the subtree in this
section.

=cut

sub append_node {
    my $self = shift;
    my $n = @{$self->{_tree}};
    push @{$self->{_tree}},
	 map {
	     $_->parent($self);
	     $_->index($n++);
	     $_
	 }  @_;
}

=head2 append_node_nonempty

    $section->append_node_nonempty(@nodes);

Same as B<append_node>, but adds new nodes after the last non-empty
node in the subtree.

=cut

sub append_node_nonempty {
    my $self = shift;
    my $n = $#{$self->{_tree}};
    while ($n >= 0 && $self->{_tree}[$n]->is_empty) {
	$n--;
    }
    $self->insert_node($n+1, @_);
}

=head2 insert_node

    $section->insert_node($idx, @nodes);

Inserts B<@nodes> after subnode in position B<$idx> (0-based).

=cut

sub insert_node {
    my $self = shift;
    my $n = shift;
    my $i = $n;
    splice @{$self->{_tree}}, $n, 0,
	 map {
	     $_->parent($self);
	     $_->index($i++);
	     $_
	 }  @_;
    for (; $i < @{$self->{_tree}}; $i++) {
	$self->{_tree}[$i]->index($i);
    }
}

=head2 delete_node

    $section->delete_node($i);

Deletes B<$i>th subnode from the B<$section>.

=cut

sub delete_node {
    my ($self, $n) = @_;
    splice @{$self->{_tree}}, $n, 1;
    for (; $n < @{$self->{_tree}}; $n++) {
	$self->{_tree}[$n]->index($n);
    }
    $self->root->mark_dirty;
}

=head2 mark_dirty

A dummy method provided so that delete_node doesn't bail out when
root is a section (e.g. when removing node from a partially constructed
tree).

=cut

sub mark_dirty {
}

=head2 tree

    @nodes = $section->tree;

Returns subnodes as a list of B<Config::Proxy::Node> derived objects.

    $node = $section->tree($i);

Returns B<$i>th subnode from the B<$section>.  Use negative $i to
index array from its end, e.g.

    $section->tree(-1)

returns last element.

=cut

sub tree {
    my ($self, $n) = @_;
    if (defined($n)) {
	if ($n < 0) {
	    $n += @{$self->{_tree}};
	}
	return undef if $n >= @{$self->{_tree}};
	return $self->{_tree}[$n];
    }
    return @{shift->{_tree}}
};

=head2 first

   $node = $section->first;

Returns first node from the section.  It is a shortcut for

   $section->tree(0)

=cut

sub first {
    my ($self) = @_;
    return $self->tree(0)
}

=head2 last

    $node = $section->last

Returns last node from the section.  It is a shortcut for

    $section->tree(-1)

=cut

sub last {
    my ($self) = @_;
    return $self->tree(-1)
}

=head2 ends_in_empty

    $bool = $section->ends_in_empty

Returns true if the last node in the list of sub-nodes in B<$section> is
an empty node.

=cut

sub ends_in_empty {
    my $self = shift;
    while ($self->is_section) {
	$self = $self->tree(-1);
    }
    return $self->is_empty;
}

my %match = (
    name => sub {
	my ($node, $value) = @_;
	return $node->kw && $node->kw eq $value;
    },
    name_ci => sub {
	my ($node, $value) = @_;
	return $node->kw && lc($node->kw) eq lc($value);
    },
    arg => sub {
	my ($node, $value) = @_;
	my $arg = $node->arg($value->{n});
	return $arg && $arg eq $value->{v};
    },
    section => sub {
	my $node = shift;
	return $node->is_section;
    },
    statement => sub {
	my $node = shift;
	return $node->is_statement;
    },
    comment => sub {
	my $node = shift;
	return $node->is_comment;
    },
    is => sub {
	my ($node, $value) = @_;
	return ref($node) eq $value;
    },
    code => sub {
	my ($node, $value) = @_;
	return &{$value}($node);
    }
);

=head2 select

    @nodes = $section->select(%cond);

Returns nodes from B<$section> that match conditions in B<%cond>. Valid
conditions are:

=over 4

=item B<name =E<gt>> I<$s>

Node matches if its keyword (B<kw>) equals I<$s>.

=item B<name_ci =E<gt>> I<$s>

Same as B<name>, but strict comparison is case-insensitive.

=item B<arg =E<gt>> B<{ n =E<gt>> I<$n>, B<v> =E<gt> I<$s> B<}>

Node matches if its I<$n>th argument equals I<$s>.

=item B<section =E<gt>> I<$bool>

Node matches if it is (or is not, if I<$bool> is false) a section.

=item B<statement =E<gt>> I<$bool>

Node matches if it is (not) a simple statement.

=item B<comment =E<gt>> I<$bool>

Node matches if it is (not) a comment.

=item B<is =E<gt>> I<$class>

Node matches if it is of the given class, i.e. B<ref($node) eq $class>.

=item B<code =E<gt> $func>

Node matches if the function B<$func> returns true.  The function is
called with B<$node> as its argument.

=back

Multiple conditions are checked in the order of their appearance in the
argument list and are joined by the short-circuit logical C<and>.

For example, to return all B<frontend> statements from a HAProxy
configuration:

  @fe = $section->select(name => 'frontend');

To return the frontend named C<in>:

  ($fe) = $section->select( name => 'frontend',
			    arg => { n => 0, v => 'in' } );

=cut

sub select {
    my $self = shift;
    my @prog;
    while (my $p = shift) {
	my $arg = shift or croak "missing argument";
	my $m = $match{$p} or croak "unknown matcher: $p";
	push @prog, [ $m, $arg ];
    }
    grep { _test_node($_, @prog) } $self->tree;
}

sub _test_node {
    my $node = shift;
    foreach my $f (@_) {
	return 0 unless &{$f->[0]}($node, $f->[1]);
    }
    return 1;
}

=head1 SEE ALSO

L<Config::Proxy::Node>, L<Config::Proxy>, L<Text::Locus>.

=cut

1;
