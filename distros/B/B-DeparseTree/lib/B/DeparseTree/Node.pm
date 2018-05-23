# The underlying node structure of the abstract code tree built
# that is built.
# Copyright (c) 2015, 2018 Rocky Bernstein
use strict; use warnings;
package B::DeparseTree::Node;
use Carp;

use Hash::Util qw[ lock_hash ];

# Set of unary precedences
our %UNARY_PRECEDENCES = (
         4 => 1,  # right not
        16 => 'sub, %, @',   # "sub", "%", "@'
        21 => '~', # steal parens (see maybe_parens_unop)
);
lock_hash %UNARY_PRECEDENCES;


our $VERSION = '1.0.0';
our @ISA = qw(Exporter);
our @EXPORT = qw(new($$$$ parens_test($$$)) %UNARY_PRECEDENCES);

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

* item B<text>

Text representation of the node until. Eventually this will diasppear
and, you'll use one of the node-to-string conversion routines.

* item B<maybe_parens>

If this node is embedded in the parent above, whether we need to add parenthesis.
The keys is a hash ref hash reference

=over

=item B<context>

A number passed from the parent indicating its precedence context

=item B<precedence>

A number as determined by the operator at this level.

=item B<parens>

'true' if we should to add parenthesis based on I<context> and
I<precedence> values; '' if not. We don't nest equal precedence
for unuary ops. The unary op precedence is given by
UNARY_OP_PRECEDENCE

=back

=back
=cut


sub parens_test($$$)
{
    my ($obj, $cx, $prec) = @_;
    # Unary ops which nest just fine
    return 1 if ($prec == $cx && !exists $UNARY_PRECEDENCES{$cx});
    return ($prec < $cx || $obj->{'parens'});
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

    if (ref($texts)) {
	# Passed in a ref ARRAY
	$self->{text} = $deparse->combine2str($sep, $texts) if defined $sep;
    } elsif (defined $texts) {
	# Passed in a string
	$self->{text} = $texts;
    } else {
	# Leave {texts} uninitialized
    }

    foreach my $optname (qw(other_ops parent_ops child_pos maybe_parens
                            omit_next_semicolon)) {
	$self->{$optname} = $opts->{$optname} if $opts->{$optname};
    }
    if ($opts->{maybe_parens}) {
	my ($obj, $context, $precedence) = @{$opts->{maybe_parens}};
	my $parens = parens_test($obj, $context, $precedence);
	$self->{maybe_parens} = {
	    context => $context,
	    precedence => $precedence,
	    force => $obj->{'parens'},
	    parens => $parens ? 'true' : ''
	};
	$self->{text} = "($self->{text})" if exists $self->{text} and $parens;
    }
    return $self;
}

# Possibly add () around $text depending on precedence $prec and
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
    my $old_pkg = __PACKAGE__;
    package B::DeparseTree::NodeDemo;
    sub new($) {
	my ($class) = @_;
	bless {}, $class;
    }
    sub combine2str($$$) {
	my ($self, $sep, $texts) = @_;
	join($sep, @$texts);
    }
    my $deparse = __PACKAGE__->new();
    my $node = $old_pkg->new('op', $deparse, ['X'], 'test', {});
    print $node->{text}, "\n";
}
1;
