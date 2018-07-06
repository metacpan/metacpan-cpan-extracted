# The underlying node structure of the abstract code tree built
# that is built.
# Copyright (c) 2015, 2018 Rocky Bernstein
use strict; use warnings;
package B::DeparseTree::TreeNode;
use Carp;
use Config;
my $is_cperl = $Config::Config{usecperl};
use Data::Printer;

use Hash::Util qw[ lock_hash ];

# A custom Data::Printer for a TreeNode object
sub _data_printer {
    my ($self, $properties) = @_;
    my $indent = "\n    ";
    my $subindent = $indent . '    ';
    my $msg = "B::DeparseTree::TreeNode {";
    foreach my $field (
	qw(addr child_pos cop fmt indexes maybe_parens op other_ops
	omit_next_semicolon_position prev_expr
	parent text texts type)) {
	next if not exists $self->{$field};
	my $data = $self->{$field};
	next if not defined $data;
	$msg .= sprintf("%s%-10s:\t", $indent, $field);
	if ($field eq 'addr' or $field eq 'parent') {
	    $msg .= sprintf("0x%x", $data);
	} elsif ($field eq 'cop') {
	    if (defined $data) {
		$msg .=  sprintf("%s:%s", $data->file, $data->line);
		$msg .= ", " . $data->name if $data->can("name");
	    }
	} elsif ($field eq 'indexes') {
	    my $str = np @{$data};
	    my @lines = split(/\n/, $str);
	    if (@lines < 4) {
		$str = sprintf("[%s]", join(", ", @{$data}));
	    } else {
		$str = join($subindent, @lines);
	    }
	    $msg .=  $str;
	} elsif ($field eq 'op') {
	    $msg .= $data->name . ', ' if $data->can("name");
	    $msg .=  $data;
	} elsif ($field eq 'prev_expr') {
	    $msg .= sprintf("B::DeparseTree::TreeNode 0x%x %s",
			    $data->{addr}, $data->{type});
	} elsif ($field eq 'texts' or $field eq 'other_ops') {
	    if (!@$data) {
		$msg .= '[]';
	    } else {
		$msg .= '[';
		my $i=0;
		foreach my $item (@$data) {
		    $msg .= sprintf("%s[%d]: ", $subindent, $i++);
		    if (ref($item) eq 'B::DeparseTree::TreeNode') {
			$msg .= sprintf("B::DeparseTree::TreeNode 0x%x %s",
					$item->{addr}, $item->{type});
		    } else {
			$msg .= sprintf("%s", $item);
		    }
		}
		$msg .= $indent . ']';
	    }
	} else {
	    $msg .=  np $data;
	}
    }
    $msg .= "\n}";
    return $msg;
};

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

    foreach my $optname (qw(child_pos
			 maybe_parens
			 omit_next_semicolon
			 other_ops
			 parent_ops
			 position
			 prev_expr)) {
	$self->{$optname} = $opts->{$optname} if $opts->{$optname};
    }
    if (exists $self->{other_ops}) {
	my $ary = $self->{other_ops};
	unless (ref $ary eq 'ARRAY') {
	    Carp::confess("expecting other_ops to be a ref ARRAY; is $ary");
	}
	my $position = 0;
	for my $other_addr (@$ary) {
	    if ($other_addr == $addr) {
		Carp::confess("other_ops contains my address $addr at position $position");
	    }
	    $position++;
	}
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
    package B::DeparseTree::TreeNodeDemo;
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
