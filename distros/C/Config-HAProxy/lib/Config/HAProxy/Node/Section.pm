package Config::HAProxy::Node::Section;
use strict;
use warnings;
use parent 'Config::HAProxy::Node';
use Carp;

=head1 NAME

Config::HAProxy::Node::Section - HAProxy configuration section

=head1 DESCRIPTION

Objects of this class represent a C<section> in the HAProxy configuration file.
A section is a statement that can contain sub-statements. The following
statements form sections: B<global>, B<defaults>, B<frontend>, and B<backend>.

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

Takes a list of objects of B<Config::HAProxy::Node> derived classes as
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

=head2 tree

    @nodes = $section->tree;

Returns subnodes as a list of B<Config::HAProxy::Node> derived objects.

    $node = $section->tree($i);

Returns B<$i>th subnode from the B<$section>.

=cut

sub tree {
    my ($self, $n) = @_;
    if ($n) {
	return undef if $n >= @{$self->{_tree}};
	return $self->{_tree}[$n];
    }
    return @{shift->{_tree}}
};

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
    name => {
	wantarg => 1,
	matcher => sub {
	    my ($node, $value) = @_;
	    return $node->kw && $node->kw eq $value;
	}
    },
    arg => {
	wantarg => 1,
	matcher => sub {
	    my ($node, $value) = @_;
	    my $arg = $node->arg($value->{n});
	    return $arg && $arg eq $value->{v};
	}
    },
    section => {
	matcher => sub {
	    my $node = shift;
	    return $node->is_section;
	}
    },
    statement => {
	matcher => sub {
	    my $node = shift;
	    return $node->is_statement;
	}
    },
    comment => {
	matcher => sub {
	    my $node = shift;
	    return $node->is_comment;
	}
    }
);
		
=head2 select

    @nodes = $section->select(%cond);

Returns nodes from B<$section> that match conditions in B<%cond>. Valid
conditions are:

=over 4

=item B<name =E<gt>> I<$s>

Node matches if its keyword (B<kw>) equals I<$s>.

=item B<arg =E<gt>> B<{ n =E<gt>> I<$n>, B<v> =E<gt> I<$s> B<}>

Node mathches if its I<$n>th argument equals I<$s>.

=item B<section =E<gt>> I<$bool>

Node matches if it is (or is not, if I<$bool> is false) a section.

=item B<statement =E<gt>> I<$bool>

Node matches if it is (not) a simple statement.

=item B<comment =E<gt>> I<$bool>

Node matches if it is (not) a comment.

=back

Multiple conditions are checked in the order of their appearance in the
argument list and are joined by the short-circuit logical C<and>. 

For example, to return all B<frontend> statements:

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
	if ($m->{wantarg}) {
	    push @prog, [ $m->{matcher}, $arg ];
	} elsif ($arg) {
	    push @prog, $m->{matcher};
	}
    }
    grep { _test_node($_, @prog) } $self->tree;
}

sub _test_node {
    my $node = shift;
    foreach my $f (@_) {
	if (ref($f) eq 'ARRAY') {
	    return 0 unless &{$f->[0]}($node, $f->[1]);
	} else {
	    return 0 unless &{$f}($node);
	}
    }
    return 1;
}

=head1 SEE ALSO

B<Config::HAProxy::Node>, B<Config::HAProxy>, B<Text::Locus>.

=cut

1;


