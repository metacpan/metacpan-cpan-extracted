# B::DeparseTree tree-building routines.
# Copyright (c) 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module B::Deparse by Stephen McCamant.
# It has been extended save tree structure, and is addressible
# by opcode address.

# Note the package name. It is *not* B::DeparseTree::Tree.
# In the future there may be a version of this that doesn't
# save as much information, but just stores enough to extract
# a string, which would be a slightly more heavyweight version of
# B::Deparse.
package B::DeparseTree::SyntaxTree;

use B::DeparseTree::TreeNode;

our($VERSION, @EXPORT, @ISA);
$VERSION = '3.2.0';
@ISA = qw(Exporter B::DeparseTree);
@EXPORT = qw(
    combine
    combine2str
    get_info_and_str
    expand_simple_spec
    indent_less
    indent_more
    indent_value
    info2str
    info_from_list
    info_from_template
    info_from_string
    info_from_text
    template_engine
    template2str
    );

sub combine($$$)
{
    my ($self, $sep, $items) = @_;
    # FIXME: loop over $item, testing type.
    Carp::confess("should be a reference to a array: is $items") unless
	ref $items eq 'ARRAY';
    my @result = ();
    foreach my $item (@$items) {
	my $add;
	if (ref $item) {
	    if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
		$add = [$item->[0], $item->[1]];
	    } elsif (eval{$item->isa("B::DeparseTree::TreeNode")}) {
		$add = [$item->{text}, $item->{addr}];
		# First item is text and second item is op address.
	    } else {
		Carp::confess("don't know what to do with $item");
	    }
	} else {
	    $add = $item;
	}
	push @result, $sep if @result && $sep;
	push @result, $add;
    }
    return @result;
}

sub combine2str($$$)
{
    my ($self, $sep, $items) = @_;
    my $result = '';
    foreach my $item (@$items) {
	$result .= $sep if $result;
	if (ref $item) {
	    if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
		# First item is text and second item is op address.
		$result .= $self->info2str($item->[0]);
	    } elsif (eval{$item->isa("B::DeparseTree::TreeNode")}) {
		if (exists $item->{fmt}) {
		    $result .= $self->template2str($item);
		} else {
		    $result .= $self->info2str($item);
		}
	    } else {
		Carp::confess("Invalid ref item ref($item)");
	    }
	} else {
	    # FIXME: add this and remove errors
	    if (index($item, '@B::DeparseTree::TreeNode') > 0) {
	    	Carp::confess("\@B::DeparseTree::TreeNode as an item is probably wrong");
	    }
	    $result .= $item;
	}
    }
    return $result;
}

sub expand_simple_spec($$)
{
    my ($self, $fmt) = @_;
    my $result = '';
    while ((my $k=index($fmt, '%')) >= 0) {
	$result .= substr($fmt, 0, $k);
	my $spec = substr($fmt, $k, 2);
	$fmt = substr($fmt, $k+2);

	if ($spec eq '%%') {
	    $result .= '%';
	} elsif ($spec eq '%+') {
	    $result .= $self->indent_more();
	} elsif ($spec eq '%-') {
	    $result .= $self->indent_less();
	} elsif ($spec eq '%|') {
	    $result .= $self->indent_value();
	} else {
	    Carp::confess("Unknown spec $spec")
	}
    }
    $result .= $fmt if $fmt;
    return $result;
}

sub indent_less($$) {
    my ($self, $check_level) = @_;
    $check_level = 0 if !defined $check_level;

    $self->{level} -= $self->{'indent_size'};
    my $level = $self->{level};
    if ($check_level < 0) {
	Carp::confess("mismatched indent/dedent") if $check_level;
	$level = 0;
	$self->{level} = 0;
    }
    return $self->indent_value();
}

sub indent_more($) {
    my ($self) = @_;
    $self->{level} += $self->{'indent_size'};
    return $self->indent_value();
}

sub indent_value($) {
    my ($self) = @_;
    my $level = $self->{level};
    if ($self->{'use_tabs'}) {
	return "\t" x ($level / 8) . " " x ($level % 8);
    } else {
	return " " x $level;
    }
}

sub info2str($$)
{
    my ($self, $item) = @_;
    my $result = '';
    if (ref $item) {
	if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
	    # This code is going away...
	    Carp::confess("fixme");
	    $result = $item->[0];
	} elsif (eval{$item->isa("B::DeparseTree::TreeNode")}) {
	    if (exists $item->{fmt}) {
		$result .= $self->template2str($item);
		if ($item->{maybe_parens}) {
		    my $mp = $item->{maybe_parens};
		    if ($mp->{force} || $mp->{parens}) {
			$result = "($result)";
		    }
		}
	    } elsif (!exists $item->{texts} && exists $item->{text}) {
		# Is a constant string
		$result .= $item->{text};
	    } else {
		$result = $self->combine2str($item->{sep},
					     $item->{texts});
	    }

	} else {
	    Carp::confess("Invalid ref item ref($item)");
	}
    } else {
	# FIXME: add this and remove errors
	if (index($item, '@B::DeparseTree::TreeNode') > 0) {
		Carp::confess("\@B::DeparseTree::TreeNode as an item is probably wrong");
	}
	$result = $item;
    }
    return $result;
}

# Create an info structure from a list of strings
# FIXME: $deparse (or rather $self) should be first
sub info_from_list($$$$$$)
{
    my ($op, $self, $texts, $sep, $type, $opts) = @_;

    # Set undef in "texts" argument position because we are going to create
    # our own text from the $texts.
    my $info = B::DeparseTree::TreeNode->new($op, $self, $texts, undef,
					 $type, $opts);
    $info->{sep} = $sep;
    my $text = '';
    foreach my $item (@$texts) {
	$text .= $sep if $text and $sep;
	if(ref($item) eq 'ARRAY'){
	    $text .= $item->[0];
	} elsif (eval{$item->isa("B::DeparseTree::TreeNode")}) {
	    $text .= $item->{text};
	} else {
	    $text .= $item;
	}
    }

    $info->{text} = $text;
    if ($opts->{maybe_parens}) {
	my ($obj, $context, $precedence) = @{$opts->{maybe_parens}};
	my $parens = B::DeparseTree::TreeNode::parens_test($obj, $context, $precedence);
	$self->{maybe_parens} = {
	    context => $context,
	    precedence => $precedence,
	    force => $obj->{'parens'},
	    parens => $parens ? 'true' : ''
	};
	$info->{text} = "($info->{text})" if exists $info->{text} and $parens;
    }

    return $info
}

# Create an info structure a template pattern
sub info_from_template($$$$$) {
    my ($self, $type, $op, $fmt, $indexes, $args, $opts) = @_;
    $opts = {} unless defined($opts);
    # if (ref($args) ne "ARRAY") {
    # 	use Enbugger "trepan"; Enbugger->stop;
    # }
    my @args = @$args;
    my $info = B::DeparseTree::TreeNode->new($op, $self, $args, undef, $type, $opts);

    $indexes = [0..$#args] unless defined $indexes;
    $info->{'indexes'} = $indexes;
    my $text = $self->template_engine($fmt, $indexes, $args);

    $info->{'fmt'}  = $fmt;
    $info->{'text'} = $self->template_engine($fmt, $indexes, $args);

    if (! defined $op) {
	$info->{addr} = ++$self->{'last_fake_addr'};
	$self->{optree}{$info->{addr}} = $info;
    }

    if ($opts->{'relink_children'}) {
	# FIXME we should specify which children to relink
	for (my $i=0; $i < scalar @$args; $i++) {
	    if ($args[$i]->isa("B::DeparseTree::TreeNode")) {
		$args[$i]{parent} = $info->{addr};
	    }
	}
    }

    # Link the parent of Deparse::Tree::TreeNodes to this node.
    if ($opts->{'synthesized_nodes'}) {
	foreach my $node (@{$opts->{'synthesized_nodes'}}) {
	    $node->{parent} = $info->{addr};
	}
    }

    # Need to handle maybe_parens since B::DeparseNode couldn't do that
    # as it was passed a ref ARRAY rather than a string.
    if ($opts->{maybe_parens}) {
	my ($obj, $context, $precedence) = @{$opts->{maybe_parens}};
	my $parens = B::DeparseTree::TreeNode::parens_test($obj,
							   $context, $precedence);
	$info->{maybe_parens} = {
	    context => $context,
	    precedence => $precedence,
	    force => $obj->{'parens'},
	    parens => $parens ? 'true' : ''
	};
	$info->{text} = "($info->{text})" if exists $info->{text} and $parens;
    }

    return $info;
}

# Create an info structure from a single string
sub info_from_string($$$$$)
{
    my ($self, $type, $op, $str, $opts) = @_;
    $opts ||= {};
    return B::DeparseTree::TreeNode->new($op, $self, $str, undef,
					 $type, $opts);
}

# OBSOLETE: Create an info structure from a single string
# FIXME: remove this
sub info_from_text($$$$$)
{
    my ($op, $self, $text, $type, $opts) = @_;
    # Use this to smoke outt calls
    # use Enbugger 'trepan'; Enbugger->stop;
    return $self->info_from_string($type, $op, $text, $opts)
}

# List of suffix characters that are handled by "expand_simple_spec()".
use constant SIMPLE_SPEC => '%+-|';

# Extract the string at $args[$index] and if
# we are looking for that position include where we are in
# that position
sub get_info_and_str($$$)
{
    my ($self, $index, $args) = @_;
    my $info = $args->[$index];
    my $str = $self->info2str($info);
    return ($info, $str);
}

sub template_engine($$$$)
{
    my ($self, $fmt, $indexes, $args, $find_addr) = @_;

    # use Data::Dumper;
    # print "-----\n";
    # p $args;
    # print "'======\n";
    # print $fmt, "\n"
    # print $args, "\n";

    my $i = 0;
    $find_addr = -2 unless $find_addr;

    my $start_fmt = $fmt; # used in error messages
    my @args = @$args;

    my $result = '';
    my $find_pos = undef;
    while ((my $k=index($fmt, '%')) >= 0) {
	$result .= substr($fmt, 0, $k);
	my $spec = substr($fmt, $k, 2);
	$fmt = substr($fmt, $k+2);

	if (index(SIMPLE_SPEC, substr($spec, 1, 1)) >= 0) {
	    $result .= $self->expand_simple_spec($spec);
	} elsif ($spec eq "%c") {
	    # Insert child entry

	    # FIXME: turn this into a subroutine.
	    if ($i >= scalar @{$indexes}) {
		Carp::confess("Need another entry in args_spec for %c in fmt: $start_fmt");
	    }
	    my $index = $indexes->[$i++];
	    if ($index >= scalar @args) {
		Carp::confess("$index in $start_fmt for %c is too large; should be less " .
			      "than scalar(@args)");
	    }
	    my $str;
	    my ($info, $str) = $self->get_info_and_str($index, $args);
	    if (ref($info) && $info->{'addr'} == $find_addr) {
		my $len = length($result);
		$len++ if (exists $info->{maybe_parens}
			   && $info->{maybe_parens}{parens});
		$find_pos = [$len, length($str)];
	    }
	    $result .= $str;
	} elsif ($spec eq "%C") {
	    # Insert separator between child entry lists
	    my ($low, $high, $sub_spec) = @{$indexes->[$i++]};
	    my $sep = $self->expand_simple_spec($sub_spec);
	    my $list = '';
	    for (my $j=$low; $j<=$high; $j++) {
		$result .= $sep if $j > $low;

		# FIXME: Remove duplicate code
		my ($info, $str) = $self->get_info_and_str($j, $args);
		if (ref($info) && $info->{'addr'} == $find_addr) {
		    my $len = length($result);
		    $len++ if (exists $info->{maybe_parens}
			       && $info->{maybe_parens}{parens});
		    $find_pos = [$len, length($str)];
		}
		$result .= $str;
	    }
	} elsif ($spec eq "%f") {
	    # Run maybe_parens_func
	    my $fn_name = shift @args;
	    my ($cx, $prec) = @{$indexes->[$i++]};
	    my $params = $self->template_engine("%C", [[0, $#args], ', ']);
	    $result .= B::Deparse::maybe_parens_func($self, $fn_name, $params, $cx, $prec);
	} elsif ($spec eq "%F") {
	    # Run a transformation function
	    if ($i >= scalar@$indexes) {
		Carp::confess("Need another entry in args_spec for %%F fmt: $start_fmt");
	    }
	    my ($arg_index, $transform_fn) = @{$indexes->[$i++]};
	    if ($arg_index >= scalar @args) {
		Carp::confess("argument index $arg_index in $start_fmt for %%F is too large; should be less than @$args");
	    }
	    if (ref($transform_fn ne 'CODE')) {
		Carp::confess("transformation function $transform_fn is not CODE");
	    }
	    my ($arg) = $args[$arg_index];
	    $result .= $transform_fn->($arg);

	} elsif ($spec eq "%;") {
	    # Insert semicolons and indented newlines between statements.
	    # Don't insert them around empty strings - some OPs
	    # don't have an text associated with them.
	    # Finally,  replace semicolon a the end of statement that
	    # end in "}" with a \n and proper indent.
	    my $sep = $self->expand_simple_spec(";\n%|");
	    my $start_size = length($result);
	    for (my $j=0; $j< @args; $j++) {
		my $old_result = $result;
		if ($j > 0 && length($result) > $start_size) {
		    # Remove any prior ;\n
		    $result = substr($result, 0, -1) if substr($result, -1) eq "\n";
		    $result = substr($result, 0, -1) if substr($result, -1) eq ";";
		    ## The below needs to be done based on whether the previous construct is a compound statement or not.
		    ## That could be added in a trailing format specifier for it.
		    ## "sub {...}" and "$h = {..}" need a semicolon while "if () {...}" doesn't.
		    # if (substr($result, -1) eq "}" & $j < $#args) {
		    # 	# Omit ; from sep. FIXME: do this based on an option?
		    # 	$result .= substr($sep, 1);
		    # } else {
		    # 	$result .= $sep;
		    # }
		    $result .= $sep;
		}

		# FIXME: Remove duplicate code
		my ($info, $str) = $self->get_info_and_str($j, $args);
		if (ref($info) && $info->{'addr'} == $find_addr) {
		    my $len = length($result);
		    $len++ if exists $info->{maybe_parens} and $info->{maybe_parens}{parens};
		    $find_pos = [length($result), length($str)];
		}
		if (!$str) {
		    $result = $old_result;
		} else {
		    $result .= $str
		}
	    }
	    # # FIXME: Add the final ';' based on an option?
	    # if ($result and not
	    # 	(substr($result, -1) eq ';' or
	    # 	 (substr($result, -1) eq ';\n'))) {
	    # 	$result .= ';' if $result and substr($result, -1) ne ';';
	    # }

	} elsif ($spec eq "\cS") {
	    # FIXME: not handled yet
	    ;
	} else {
	    # We have % with a non-special symbol. Just preserve those.
	    $result .= $spec;
	}
    }
    $result .= $fmt if $fmt;
    if ($find_addr != -2) {
	# want result and position
	return $result, $find_pos;
    }
    # want just result
    return $result;

}

sub template2str($$) {
    my ($self, $info) = @_;
    return $self->template_engine($info->{fmt},
				  $info->{indexes},
				  $info->{texts});
}

1;
