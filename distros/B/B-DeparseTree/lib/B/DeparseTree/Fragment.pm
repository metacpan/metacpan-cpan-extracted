package B::DeparseTree::Fragment;

use B::DeparseTree;
use strict; use warnings;
use Data::Printer;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');
@EXPORT = qw(deparse_offset
             dump
             extract_node_info
             get_addr_info
             get_parent_addr_info get_parent_op
             get_prev_addr_info
             get_prev_info
             trim_line_pair
             underline_parent
    );

sub deparse_offset
{
    my ($funcname, $address) = @_;

    my $deparse = B::DeparseTree->new();
    if ($funcname eq "DB::DB") {
	$deparse->main2info;
    } else {
	$deparse->coderef2info(\&$funcname);
    }
    get_addr_info($deparse, $address);
}

sub get_addr($$)
{
    my ($deparse, $addr) = @_;
    return undef unless $addr;
    return $deparse->{optree}{$addr};
}

sub get_addr_info($$)
{
    my ($deparse, $addr) = @_;
    my $op_info = get_addr($deparse, $addr);
    return $op_info;
}

sub get_parent_op($)
{
    my ($op_info) = @_;
    return undef unless $op_info;
    my $deparse = $op_info->{deparse};

    # FIXME:
    return $deparse->{ops}{$op_info->{addr}}{parent};
}

sub get_parent_addr_info($)
{
    my ($op_info) = @_;
    my $deparse = $op_info->{deparse};
    # FIXME
    # my $parent_op = get_parent_op($op_info);
    my $parent_addr = $op_info->{parent};
    return undef unless $parent_addr;
    return $deparse->{optree}{$parent_addr};
}

sub get_prev_info($);
sub get_prev_info($)
{
    my ($op_info) = @_;
    return undef unless $op_info;
    return $op_info->{prev_expr}
}

sub get_prev_addr_info($);
sub get_prev_addr_info($)
{
    my ($op_info) = @_;
    return undef unless $op_info;
    if (!exists $op_info->{prev_expr}) {
	my $parent_info = get_parent_addr_info($op_info);
	if ($parent_info) {
	    return get_prev_addr_info($parent_info);
	} else {
	    return undef;
	}
    }
    return $op_info->{prev_expr}
}

sub underline_parent($$$) {
    my ($child_text, $parent_text, $char) = @_;
    my $start_pos = index($parent_text, $child_text);
    return  (' ' x $start_pos) . ($char  x length($child_text));

}
# Return either 2 or 3 strings in an array reference.
# There are various cases to consider.
# 1. Child and parent texts are no more than a single line:
#    return and the underline, two entries. For example:
#  my ($a, $b) = (5, 6);
#                -----
# 2. The parent spans more than a line but the child is
#    on that line. Return an array of the first line of the parent
#    with elision and the child underline, two entries. Example
#    if the child is $a in:
# if ($a) {
#    $b
# }
# return:
# if ($a) {...
#     --
#                -----
# 3. The parent spans more than a line and the child is
#    not that line. Return an array of the first line of the parent
#    with elision, then the line containing the child and the child underline,
#    three entries. Example:
#    if the child is $b in:
# if ($a) {
#    $b;
#    $c;
# }
# return:
# if ($a) {...
#   $b;
#   --

# 4. The parent spans more than a line and the child is
#    not that line and also spans more than a single line.
#    Do the same as 3. but add eplises to the underline.
#    Example:
#    if the child is "\$b;\n  \$c" in:
# if ($a) {
#    $b;
#    $c;
# }
# return:
# if ($a) {...
#   $b;
#   ---...
# 5. Like 4, but the child is on the first line. A cross between
# 3 and 4. No elipses for the first line is needed, just one on the
# underline
#
sub trim_line_pair($$$$) {
    my ($parent_text, $child_text, $parent_underline, $start_pos) = @_;
    # If the parent text is longer than a line, use just the line.
    # The underline indicator adds an elipsis to show it is elided.
    my @parent_lines = split(/\n/, $parent_text);
    my $i = 0;
    if (scalar(@parent_lines) > 1) {
	for ($i=0; $start_pos > length($parent_lines[$i]); $i++) {
	    my $l = length($parent_lines[$i]);
	    $start_pos -= ($l+1);
	    $parent_underline = substr($parent_underline, $l+1);
	}
    }
    my @result = ();
    if ($i > 0) {
    	push @result, $parent_lines[0] . '...';
    }
    my $stripped_parent = $parent_lines[$i];
    my @child_lines = split(/\n/, $child_text);
    if (scalar(@child_lines) > 1) {
    	$parent_underline = substr($parent_underline, 0, length($child_lines[0])+1) . '...';
    }

    push @result, $stripped_parent, $parent_underline;
    return \@result;
}

# FIXME: this is a mess

# return an ARRAY ref to strings that can be joined with "\n" to
# give a position in the text. Here are some examples
# after joining
#
#   my ($x, $y) = (1, 2)
#                 ------
#   my ($x, $y) = (1, 2)
#                 ~~~~~
#   my ($x, $y) = (1, 2)
#                     -
#  (1, 2)
#
#  if ($x) { ...
#     my ($x, $y = (1, 2)
#     -------------------
#
#  if ($x) { ...
#     my ($x, $y = (1, 2)...
#     -------------------

# When we can, we text in the context of the surrounding
# text which is obtained by going up levels of the tree
# form the instruction. We might have to go a few levels
# up the tree before we find a text that spans more than
# a single line.  In the fourth case where we don't
# have an underline but simply have "(1, 2)" that means
# were unable to get the parent text.

# We hope that in the normal case, using the place holders in the
# format specifiers, we can know for sure where a child fits in as
# that child's node is stored in the parent as some "texts"
# entry. However this isn't always possible right now. So in the
# second example where "~" was used instead of "-", to
# indicate that the result was obtained the result by string matching
# rather than by exact node matching inside the parent.
# We can also use the "|" instead for instructions that really
# don't have an equivalent concept in the source code, so we've
# artificially tagged a location that is reasonable. "pushmark"
# and "padrange" instructions would be in this category.
#
# In the last two examples, we show how we do elision. The ...
# in the parent text means that we have only given the first line
# of the parent text along with the line that the child fits in.
# if there is an elision in the child text it means that that
# spans more than one line.

sub extract_node_info($)
{
    my ($info) = @_;

    my $child_text = $info->{text};
    my $parent_text = undef;
    my $candidate_pair = undef;
    my $marked_position = undef;

    # Some opcodes like pushmark , padrange, and null,
    # don't have an well-defined correspondence to a string in the
    # source code, so we have made a somewhat arbitrary association fitting
    # into the parent string. Examples of such artificial associations are
    # the function name part of call, or an open brace of a scope.
    # You can tell these nodes because they have a "position" field.
    if (exists $info->{position}) {
	my $found_pos = $info->{position};
	$marked_position = $found_pos;
	$parent_text = $child_text;
	$child_text = substr($parent_text,
			     $found_pos->[0], $found_pos->[1]);
	my $parent_underline = ' ' x $found_pos->[0];
	$parent_underline .= '|' x $found_pos->[1];
	$candidate_pair = trim_line_pair($parent_text, $child_text,
					 $parent_underline,
					 $found_pos->[0]);

    }

    my $parent = $info->{parent} ? $info->{parent} : undef;
    unless ($parent) {
	return $candidate_pair ? $candidate_pair : [$child_text];
    }

    my $child_addr = $info->{addr};
    my $deparsed = $info->{deparse};
    my $parent_info = $deparsed->{optree}{$parent};

    unless ($parent_info) {
	return $candidate_pair ? $candidate_pair : [$child_text];
    }

    my $separator = exists $parent_info->{sep} ? $parent_info->{sep} : '';
    my @texts = exists $parent_info->{texts} ? @{$parent_info->{texts}} : ($parent_info->{text});
    my $parent_line = '';
    my $text_len = $#texts;
	my $result = '';

    if (!exists $parent_info->{fmt}
	and scalar(@texts) == 1
	and eval{$texts[0]->isa("B::DeparseTree::TreeNode")}) {
	$parent_info = $texts[0];
    }
    if (exists $parent_info->{fmt} || exists $parent_info->{position}) {
	# If the child text is the same as the parent's, go up the parent
	# chain until we find something different.
	while ($parent_info->{text} eq $child_text
	       && $parent_info->{parent}
	       && $deparsed->{optree}{$parent_info->{parent}}
	    ) {
	    last if ! exists $deparsed->{optree}{$parent_info->{parent}};
	    $parent_info = $deparsed->{optree}{$parent_info->{parent}};
	}
	my $fmt = $parent_info->{fmt};
	my $indexes = $parent_info->{indexes};
	my $args = $parent_info->{texts};
	my ($str, $found_pos) = $deparsed->template_engine($fmt, $indexes, $args,
							   $child_addr);

	# Keep gathering parent text until we have at least one full line.
	while (index($str, "\n") == -1 && $parent_info->{parent}) {
	    $child_addr = $parent_info->{addr};
	    last if ! exists $deparsed->{optree}{$parent_info->{parent}};
	    $parent_info = $deparsed->{optree}{$parent_info->{parent}};
	    $fmt = $parent_info->{fmt};
	    $indexes = $parent_info->{indexes};
	    $args = $parent_info->{texts};
	    my ($next_str, $next_found_pos) = $deparsed->template_engine($fmt,
									 $indexes, $args,
									 $child_addr);
	    last unless $next_found_pos;
	    my $nl_pos = index($next_str, "\n");
	    while ($nl_pos >= 0 and $nl_pos  < $next_found_pos->[0]) {
		$next_str = substr($next_str, $nl_pos+1);
		$next_found_pos->[0] -= ($nl_pos+1);
		$nl_pos = index($next_str, "\n");
	    }
	    $str = $next_str;
	    if ($found_pos) {
		$found_pos->[0] += $next_found_pos->[0];
	    } else {
		$found_pos = $next_found_pos;
	    }
	}

	if (defined($found_pos)) {
	    my $parent_underline;
	    if ($marked_position) {
		$parent_underline = ' ' x ($found_pos->[0] + $marked_position->[0]);
		$parent_underline .= '|' x $marked_position->[1];
	    } else {
		$parent_underline = ' ' x $found_pos->[0];
		$parent_underline .= '-' x $found_pos->[1];
	    }
	    return trim_line_pair($str, $child_text, $parent_underline, $found_pos->[0]);
	}
	$result = $str;
    } else {
	for (my $i=0; $i <= $text_len; $i++) {
	    my $text = $texts[$i];
	    $result .= $separator if $result;

	    if (ref($text)) {
		if (ref($text) eq 'ARRAY' and (scalar(@$text) == 2)) {
		    if ($text->[1] == $child_addr) {
			$child_text = $text->[0];
			my $parent_underline = ' ' x length($result);
			$result .= $text->[0];
			$parent_underline .= '-' x length($text->[0]);
			if ($i < $text_len) {
			    $result .= $separator;
			    my @remain_texts = @texts[$i+1..$#texts];
			    my $tail = $deparsed->combine2str($separator, \@remain_texts);
			    $result .=  $tail;
			}
			return trim_line_pair($result, $child_text, $parent_underline, 0);
		    } else {
			$result .= $text->[0];
		    }
		} elsif ($text->{addr} == $child_addr) {
		    my $parent_underline = ' ' x length($result);
		    $result .= $text->{text};
		    $parent_underline .= '-' x length($text->{text});
		    if ($i < $text_len) {
			$result .= $separator;
			my @remain_texts = @texts[$i+1..$#texts];
			my $tail = $deparsed->combine2str($separator, \@remain_texts);
			$result .=  $tail;
		    }
		    return trim_line_pair($result, $child_text, $parent_underline, 0);
		} else {
		    $result .= $text->{text};
		}
	    } else {
		$result .= $text;
	    }
	}
    }
    # Can't find by node address info, so just try to find the string
    # inside of the parent.
    $parent_text = $parent_info->{text};
    my $start_index = index($parent_text, $child_text);
    if ($start_index >= 0) {
	if (index($parent_text, $child_text, $start_index+1) < 0) {
	    # It is in there *uniquely*!
	    my $parent_underline = underline_parent($child_text, $parent_text, '~');
	    return trim_line_pair($parent_text, $child_text, $parent_underline, $start_index);
	}
    }
}

# Dump out full information of a node in relation to its
# parent
sub dump($) {
    my ($deparse_tree) = @_;
    my @addrs = sort keys %{$deparse_tree->{optree}};
    for (my $i=0; $i < $#addrs; $i++) {
	printf("%d: %s\n", $i, ('=' x 50));
	my $info = get_addr_info($deparse_tree, $addrs[$i]);
	if ($info) {
	    printf "0x%0x\n", $addrs[$i];
	    p $info ;
	}
	if ($info->{parent}) {
	    my $parent = get_parent_addr_info($info);
	    if ($parent) {
		p $parent ;
		my $texts = extract_node_info($info);
		if ($texts) {
		    print join("\n", @$texts), "\n";
		}
	    }
	}
	printf("%d: %s\n", $i, ('=' x 50));
    }
}

# Dump out essention information of a node in relation to its
# parent
sub dump_relations($) {
    my ($deparse_tree) = @_;
    my @addrs = sort keys %{$deparse_tree->{optree}};
    for (my $i=0; $i < $#addrs; $i++) {
	my $info = get_addr_info($deparse_tree, $addrs[$i]);
	next unless $info && $info->{parent};
	my $parent = get_parent_addr_info($info);
	next unless $parent;
	printf("%d: %s\n", $i, ('=' x 50));
	print "Child info:\n";
	printf "\taddr: 0x%0x, parent: 0x%0x\n", $addrs[$i], $parent->{addr};
	printf "\top: %s\n", $info->{op}->can('name') ? $info->{op}->name : $info->{op} ;
	printf "\ttext: %s\n\n", $info->{text};
	# p $parent ;
	my $texts = extract_node_info($info);
	if ($texts) {
	    print join("\n", @$texts), "\n";
	}
	printf("%d: %s\n", $i, ('=' x 50));
    }
}

sub dump_tree($$);

# Dump out the entire texts in tree format
sub dump_tree($$) {
    my ($deparse_tree, $info) = @_;
    if (ref($info) and (ref($info->{texts}) eq 'ARRAY')) {
	foreach my $child_info (@{$info->{texts}}) {
	    if (ref($child_info)) {
		if (ref($child_info) eq 'ARRAY') {
		    p $child_info;
		} elsif (ref($child_info) eq 'B::DeparseTree::TreeNode') {
		    dump_tree($deparse_tree, $child_info)
		} else {
		    printf "Unknown child_info type %s\n", ref($child_info);
		    p $child_info;
		}
	    }
	}
	print '-' x 50, "\n";
    }
    p $info ;
    print '=' x 50, "\n";
}

unless (caller) {
    sub bug() {
	my ($a, $b) = @_;
	($a, $b) = ($b, $a) if ($a > $b);
	# -((1, 2) x 2);
	# no strict;
	# for ( $i=0; $i;) {};
	# my ($a, $b, $c);
	# CORE::exec($foo $bar);
	# exec $foo $bar;
	# exec $foo $bar;
    }

    my $child_text = '$foo $bar';
    my $result = 'exec $foo $bar';
    my $parent_underline = "     ---------";
    my $start_pos = 0;
    my $lines = trim_line_pair($result, $child_text, $parent_underline,
			       $start_pos);
    print join("\n", @$lines), "\n";

    my $deparse = B::DeparseTree->new();
    use B;
    $deparse->pessimise(B::main_root, B::main_start);
    # my @addrs = sort keys %{$deparse->{ops}}, "\n";
    # use Data::Printer;
    # p @addrs;

    # my @info_addrs = sort keys %{$deparse->{optree}}, "\n";
    # print '-' x 40, "\n";
    # p @info_addrs;

    # $deparse->init();
    # my $svref = B::svref_2object(\&bug);
    # my $x =  $deparse->deparse_sub($svref, $addrs[9]);
    # my $x =  $deparse->deparse_sub($svref);
    # dump_tree($deparse, $x);

    # # my @info_addrs = sort keys %{$deparse->{optree}}, "\n";
    # # print '-' x 40, "\n";
    # # p @info_addrs;

    # #my $info = get_addr_info($deparse, $addrs[10]);
    # # p $info;
    # exit 0;

    $deparse->coderef2info(\&bug);
    # $deparse->coderef2info(\&get_addr_info);
    my @addrs = sort keys %{$deparse->{optree}}, "\n";
    B::DeparseTree::Fragment::dump($deparse);

    # my ($parent_text, $pu);
    # $parent_text = "now is the time";
    # $child_text = 'is';
    # $start_pos = index($parent_text, $child_text);
    # $pu = underline_parent($child_text, $parent_text, '-');
    # print join("\n", @{trim_line_pair($parent_text, $child_text,
    # 				    $pu, $start_pos)}), "\n";
    # $parent_text = "if (\$a) {\n\$b\n}";
    # $child_text = '$b';
    # $start_pos = index($parent_text, $child_text);
    # $pu = underline_parent($child_text, $parent_text, '-');
    # print join("\n", @{trim_line_pair($parent_text, $child_text,
    # 				    $pu, $start_pos)}), "\n";

    # $parent_text = "if (\$a) {\n  \$b;\n  \$c}";
    # $child_text = '$b';
    # $start_pos = index($parent_text, $child_text);
    # $pu = underline_parent($child_text, $parent_text, '-');
    # print join("\n", @{trim_line_pair($parent_text, $child_text,
    #  				    $pu, $start_pos)}), "\n";
    # $parent_text = "if (\$a) {\n  \$b;\n  \$c}";
    # $child_text = "\$b;\n  \$c";
    # $start_pos = index($parent_text, $child_text);
    # $pu = underline_parent($child_text, $parent_text, '-');
    # print join("\n", @{trim_line_pair($parent_text, $child_text,
    #  				    $pu, $start_pos)}), "\n";
}

1;
