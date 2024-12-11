package Config::Proxy::Node;
use strict;
use warnings;
use Carp;
use Config::Proxy::Iterator;

sub new {
    my $class = shift;
    local %_ = @_;
    bless {
	_kw => $_{kw},
	_argv => $_{argv} // [],
	_orig => $_{orig},
	_locus => $_{locus},
	_parent => $_{parent},
	_index => -1
    }, $class;
}

my @ATTRIBUTES = qw(kw orig locus parent index);

{
    no strict 'refs';
    foreach my $attribute (@ATTRIBUTES) {
	*{ __PACKAGE__ . '::' . $attribute } = sub {
	    my $self = shift;
	    if (defined(my $val = shift)) {
		croak "too many arguments" if @_;
		$self->{'_'.$attribute} = $val;
	    }
	    return $self->{'_'.$attribute};
	}
    }
}

sub argv {
    my $self = shift;
    if (my $val = shift) {
	croak "too many arguments" if @_;
	$self->{_argv} = $val;
	delete $self->{_orig};
    }
    return @{$self->{_argv}};
}

sub arg {
    my $self = shift;
    my $n = shift;
    if (my $val = shift) {
	croak "too many arguments" if @_;
	$self->{_argv}[$n] = $val;
    }
    return $self->{_argv}[$n];
}

sub drop {
    my $self = shift;
    $self->parent->delete_node($self->index);
}

sub iterator {
    return new Config::Proxy::Iterator(@_);
}

sub write {
    my $self = shift;
    my $file = shift;
    my $fh;

    if (!defined($file)) {
	$file = \*STDOUT
    }
    if (ref($file) eq 'GLOB') {
	$fh = $file;
    } else {
	open($fh, '>', $file) or croak "can't open $file: $!";
    }

    $self->format($fh, @_) if $self->is_section && !$self->is_root;

    my $itr = $self->iterator(inorder => 1);

    while (defined(my $node = $itr->next)) {
	$node->format($fh, @_);
    }

    close $fh unless ref($file) eq 'GLOB';
}

sub format {
    my ($self, $fh, %opts) = @_;

    my $s = $self->as_string;
    if ($opts{indent}) {
	if ($self->is_comment) {
	    if ($opts{reindent_comments}) {
		my $indent = ' ' x ($opts{indent} * $self->depth);
		$s =~ s/^\s+//;
		$s = $indent . $s;
	    }
	} else {
	    my $indent = ' ' x ($opts{indent} * $self->depth);
	    if ($opts{tabstop}) {
		$s = $indent . $self->kw;
		for (my $i = 0; my $arg = $self->arg($i); $i++) {
		    my $off = 1;
		    if ($i < @{$opts{tabstop}}) {
			if (($off = $opts{tabstop}[$i] - length($s)) <= 0) {
			    $off = 1;
			}
		    }
		    $s .= (' ' x $off) . $arg;
		}
	    } else {
		$s =~ s/^\s+//;
		$s = $indent . $s;
	    }
	}
    }
    print $fh $s,"\n";
}

sub depth {
    my $self = shift;
    my $n = 0;
    while ($self = $self->parent) {
	$n++;
    }
    return $n - 1;
}

sub root {
    my $self = shift;
    while ($self->parent()) {
	$self = $self->parent();
    }
    return $self;
}

sub as_string {
    my $self = shift;
    if (defined(my $v = $self->orig)) {
	return $v;
    }
    return '' unless $self->kw;
    return $self->orig(join(' ', ($self->kw, $self->argv())));
}

# use overload
#     '""' => sub { shift->as_string };

sub is_root { 0 }
sub is_section { 0 }
sub is_statement { 0 }
sub is_empty { 0 }
sub is_comment { 0 }

1;
__END__

=head1 NAME

Config::Proxy::Node - Abstract Proxy configuration node

=head1 DESCRIPTION

The class B<Config::Proxy::Node> represents an abstract node in the
Proxy configuration parse tree. It serves as a base class for classes
representing configuration tree, section, simple statement, comment and
empty line.

=head1 CONSTRUCTOR

    $obj = new Config::Proxy::Node(%args);

Returns new object. B<%args> can contain the following keys:

=over 4

=item B<kw>

Configuration keyword (string),

=item B<argv>

Reference to the list of arguments.

=item B<orig>

Original text as read from the configuration file.

=item B<locus>

Locus (a B<Text::Locus> object) where this statement occurred.

=item B<parent>

Parent node.

=back

=head1 METHODS

=head2 B<kw>, B<argv>, B<orig>, B<locus>, B<parent>

These methods return the corresponding field of the node. When called
with an argument, they set the field prior to returning it. The B<argv>
method returns array of strings and takes as its argument a reference to
the array of strings:

    @a = $node->argv;

    $node->argv([@a]);

=head2 index

Index (0-based) of this node in the parent node.

=head2 arg

    $a = $node->arg($n)

Returns the B<$n>th argument (0-based) from the argument list.

=head2 drop

    $node->drop;

Removes this node and destroys it.

=head2 iterator

    $itr = $node->iterator(@args);

Returns the iterator for this node. See L<Config::Proxy::Iterator> for
a detailed discussion.

=head2 depth

    $n = $node->depth;

Returns the depth of this node in the configuration tree. Depth is the
number of parent nodes between the root of tree and this node. Top-level
nodes have depth 0.

=head2 root

    $root_node = $node->root;

Returns the root node of the parse tree this node belongs to.

=head2 as_string

    $s = $node->as_string;

Returns canonical string representation of this node. The canonical
representation consists of the keyword followed by arguments delimited
with horizontal space characters.

=head2 write

    $node->write([$file, %hash]);

Writes the node to the named file or file handle. First argument
can be a file name, file handle or a string reference. If it is the
only argument, the original indentation is preserved. Otherwise, if
B<%hash> controls the indentation of the output. It must contain at least
the B<indent> key, which specifies the amount of indentation per nesting
level. If B<tabstop> key is also present, its value must be a reference to
the list of tabstop columns. For each statement with arguments, this array
is consulted to determine the column number for each subsequent argument.
Arguments are zero-indexed. Starting column where the argument should be
placed is determined as B<$tabstop[$i]>, where B<$i> is the argument index.
Arguments with B<$i> greater than or equal to B<@tabstop> are appended to
the resulting output, preserving their original offsets.

Normally, comments retain their original indentation. However, if the
key B<reindent_comments> is present, and its value is evaluated as true,
then comments are reindented following the rules described above.

Called without arguments, this method writes the node content to standard
output in unaltered form.

=head2 format

    $node->format($file, %hash);

Writes the node to the B<$file>.  See B<write> for a detailed discussion.
The difference between B<format> and B<write> is that B<format> outputs only
the node itself, and does not descend into its subordinate nodes.

=head1 ABSTRACT METHODS

Derived classes must overload at least one of the following methods:

=head2 is_root

True if the node is a root node, false otherwise.

=head2 is_section

True if the node represents a section (i.e. contains subnodes).

=head2 is_statement

True if the node is a simple statement.

=head2 is_empty

True if the node represents an empty line.

=head2 is_comment

True if the node represents a comment.

=head1 SEE ALSO

L<Config::Proxy::Node::Comment>,
L<Config::Proxy::Node::Empty>,
L<Config::Proxy::Node::Root>,
L<Config::Proxy::Node::Section>,
L<Config::Proxy::Node::Statement>,
L<Config::Proxy::Iterator>,
L<Config::Proxy>,
L<Text::Locus>,
L<Config::HAProxy>,
L<Config::Pound>.

=cut
