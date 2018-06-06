# The underlying node structure of the abstract code tree built
# that is built.
# Copyright (c) 2015, 2018 Rocky Bernstein
use strict; use warnings;
package B::DeparseTree::Node;
use Carp;
use Config;
my $is_cperl = $Config::Config{usecperl};

use Hash::Util qw[ lock_hash ];

# Set of unary precedences
our %UNARY_PRECEDENCES = (
         4 => 1,  # right not
        16 => 'sub, %, @',   # "sub", "%", "@'
        21 => '~', # steal parens (see maybe_parens_unop)
    );

unless ($is_cperl) {
    lock_hash %UNARY_PRECEDENCES;
}


our $VERSION = '3.2.0';
our @ISA = qw(Exporter);
our @EXPORT = qw(
    new($$$$)
    parens_test($$$)
    %UNARY_PRECEDENCES
    update_other_ops($$)
);

=head2 Node structure

Fields in a node structure:

=over

*item B<type>

The string name for the node. It can be used to determine the overall
structure. For example a 'binop' node will have a I<body> with a node
left-hand side, the string operation name and a I<body> right-hand
side. Right now the type names are a little funky, but over time I
hope these will less so.

* item B<sep> (optional)

A string indicating how to separate the the strings extracted from the
C<texts> field. The field is subject to format expansion. In particular
tt can have '%;' in it to indicate we are separating statements.
the body.

* item B<texts>

A reference to a list containing either:

=over

* item a tuple with a strings, and a op address
* a DeparseTreee::Node object

=back

* item B<text>

Text representation of the node. Eventually this will diasppear
and, you'll use one of the node-to-string conversion routines.

* item B<maybe_parens>

If this node is embedded in the parent above, whether we need to add parenthesis.
The keys is a hash ref hash reference

=over

=item B<context>

A number passed from the parent indicating its precedence context that
the expression is embedded it.

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
    return ($prec < $cx
	    # Unary ops which nest just fine
	    or ($prec == $cx && !exists $UNARY_PRECEDENCES{$cx}));
}

sub new($$$$$)
{
    my ($class, $op, $deparse, $data, $sep, $type, $opts) = @_;
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
	type => $type,
    }, $class;

    $self->{sep} = $sep if defined $sep;
    if (ref($data)) {
	# Passed in a ref ARRAY
	$self->{texts} = $data;
	$self->{text} = $deparse->combine2str($sep, $data) if defined $sep;
    } elsif (defined $data) {
	# Passed in a string
	$self->{text} = $data;
    } else {
	# Leave {text} and {texts} uninitialized
    }

    foreach my $optname (qw(other_ops parent_ops child_pos maybe_parens
                            omit_next_semicolon position)) {
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
    if ($opts->{prev_expr}) {
	$self->{prev_expr} = $opts->{prev_expr};
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

# Update $self->{other_ops} to add $info
sub update_other_ops($$)
{
    my ($self, $info) = @_;
    $self->{other_ops} ||= [];
    my $other_ops = $self->{other_ops};
    push @{$other_ops}, $info;
    $self->{other_ops} = $other_ops;
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
	my ($self, $sep, $data) = @_;
	join($sep, @$data);
    }
    my $deparse = __PACKAGE__->new();
    my $node = $old_pkg->new('op', $deparse, ['X'], 'test', {});
    print $node->{text}, "\n";
}
1;
