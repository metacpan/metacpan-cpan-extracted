# The underlying node structure of the abstract code tree built
# that is built.
# Copyright (c) 2015, 2018 Rocky Bernstein
use strict; use warnings;
package B::DeparseTree::Node;
use Carp;

our($VERSION, @EXPORT, @ISA);
$VERSION = '1.0.0';
@ISA = qw(Exporter);
@EXPORT = qw(new($$$$ from_str($$$) from_list($$$) parens_test($$$)));

=head2 Node structure

Fields in a node structure:

=over

*item B<type>

The string name for the node. It can be used to determine the overall
structure. For example a 'binop' node will have a I<body> with a node
left-hand side, the string operation name and a I<body> right-hand
side. Right now the type names are a little funky, but over time I
hope these will less so.

* item B<sep>

A string indicating how to separate the the strings derived from
the body. To indicate statement separation, the separator is ';' and the
B<indent_type> is '{'. The indent program can also use the type
to help out with statement boundaries.

* item B<texts>

A reference to a list containing either strings, a Node references, or Hash references
containing the keys I<sep> and a I<body>.

* item B<body>

A reference to a list of a Node references. Eventually this will this and
texts will be merged.

* item B<text>

Text representation of the node until. Eventually this will diasppear
and, you'll use one of the node-to-string conversion routines.

* item B<maybe_parens>

If this node is embedded in the parent above, whether we need to add parenthesis.
The keys is a hash ref hash reference

=over

=item B<context>

A number passed from the parent indicating its precidence context

=item B<precidence>

A number as determined by the operator at this level.

=item B<parens>

'true' if we should to add parenthesis based on I<context> and
I<precidence> values; '' if not.

=back

=back
=cut


sub parens_test($$$)
{
    my ($obj, $cx, $prec) = @_;
    return ($prec < $cx or
	    $obj->{'parens'} or
	    # unary ops nest just fine
	    $prec == $cx and $cx != 4 and $cx != 16 and $cx != 21)
}

sub new($$$$$)
{
    my ($class, $op, $deparse, $texts, $sep, $type, $opts) = @_;
    my $addr = -1;
    if (ref($op)) {
	if (ref($op) eq 'B::DeparseTree') {
	    # use Enbugger 'trepan'; Enbugger->stop;
	    Carp::confess("Rocky got the order of \$self, and \$op confused again");
	    $addr = -2;
	} else {
	    eval { $addr = $$op };
	}
    }
    my $self = bless {
	addr => $addr,
	op => $op,
	deparse => $deparse,
	texts => $texts,
	type => $type,
	sep => $sep,
    }, $class;

    $self->{text} = $self->combine($sep, $texts);

    foreach my $optname (qw(other_ops body parent_ops child_pos)) {
	$self->{$optname} = $opts->{$optname} if $opts->{$optname};
    }
    if ($opts->{maybe_parens}) {
	my ($obj, $context, $precidence) = @{$opts->{maybe_parens}};
	my $parens = parens_test($obj, $context, $precidence);
	$self->{maybe_parens} = {
	    context => $context,
	    precidence => $precidence,
	    force => $obj->{'parens'},
	    parens => $parens ? 'true' : ''
	};
    }
    return $self;
}

# Simplified class constructors
sub from_str($$$$$)
{
    my ($op, $self, $str, $type, $opts) = @_;
    __PACKAGE__->new({body=>[$str]}, '', $type, $opts);
}

sub from_list($$$$$$)
{
    my ($op, $self, $list, $sep, $type, $opts) = @_;
    __PACKAGE__->new({body=>$list}, $sep, $type, $opts);
}

sub combine($$$)
{
    my ($self, $sep, $items) = @_;
    # FIXME: loop over $item, testing type.
    return $items unless ref $items;
    Carp::confess("should be a reference to a hash: is $items") unless
	ref $items eq 'ARRAY';
    my $result = '';
    foreach my $item (@{$items}) {
	my $add;
	if (ref $item) {
	    if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
		# First item is text and second item is op address.
		$add = $item->[0];
	    } elsif (eval{$item->isa("B::DeparseTree::Node")}) {
		$add = $item->{text};
		# First item is text and second item is op address.
	    } else {
		$add = $self->combine($item->{sep}, $item->{texts});
	    }
	} else {
	    $add = $item;
	}
	if ($result) {
	    $result .= ($sep . $add);
	} else {
	    $result = $add;
	}
    }
    return $result;
}

# FIXME: replace with routines to build text on from the tree
#
sub text($)
{
    return shift()->{text};
}


# Possibly add () around $text depending on precidence $prec and
# context $cx. We return a string.
sub maybe_parens($$$$)
{
    my($self, $info, $cx, $prec) = @_;
    if (parens_test($info, $cx, $prec)) {
	$info->{text} = $self->combine('', "(", $info->{text}, ")");
	# In a unop, let parent reuse our parens; see maybe_parens_unop
	if ($cx == 16) {
	    $info->{text} = "\cS" . $info->{text};
	    $info->{parens} = 'reuse';
	}  else {
	    $info->{parens} = 'true';
	}
	return $info->{text};
    } else {
	$info->{parens} = '';
	return $info->{text};
    }
}

# Demo code
unless(caller) {
    my $deparse = undef;
    *fs = \&B::DeparseTree::Node::from_str;
    *fl = \&B::DeparseTree::Node::from_list;
    my @list = ();
    push @list, fs('root', undef, "X", 'string', {}),
	fl('root', undef, ['A', 'B'], ':', 'simple-list', {});
    push @list, fl('root', undef, \@list, '||', 'compound-list', {});
    foreach my $item (@list) {
	print $item->text, "\n";
    }
}
1;
