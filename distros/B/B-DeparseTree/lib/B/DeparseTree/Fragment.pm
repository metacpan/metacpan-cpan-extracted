package B::DeparseTree::Fragment;

use strict; use warnings;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');
@EXPORT = qw(deparse_offset get_addr_info get_parent_addr_info extract_node_info);

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

sub get_addr_info($$)
{
    my ($deparse, $addr) = @_;
    return unless $addr;
    my $op_info = $deparse->{optree}{$addr};
    if ($op_info) {
	# use Data::Printer; Data::Printer::p $op_info;
	# my $text = $deparse->indent_info($op_info);
	return $op_info;
    }
    return undef;
}

sub get_parent_addr_info($)
{
    my ($op_info) = @_;

    return undef unless $op_info && $op_info->{parent};
    my $deparse = $op_info->{deparse};
    return undef unless $deparse;
    my $parent_addr = $op_info->{parent};
    return $deparse->{optree}{$parent_addr};
}

sub trim_line_pair($$$$) {
    my ($parent_text, $child_text, $parent_underline, $start_pos) = @_;
    # If the parent text is longer than a line, use just the line.
    # The underline indicator adds an elipsis to show it is elided.
    my @parent_lines = split(/\n/, substr($parent_text, $start_pos));
    my $stripped_parent = $parent_lines[0];
    if (length($parent_underline) > length($stripped_parent)) {
	$parent_underline = substr($parent_underline, 0, length($stripped_parent)) . '...';
    }
    return [$stripped_parent, $parent_underline];
}

sub extract_node_info($)
{
    my ($info) = @_;
    my $child_text = $info->{text};
    my $parent = $info->{parent} ? $info->{parent} : undef;
    return [$child_text] unless $parent;
    my $child_addr = $info->{addr};
    my $deparsed = $info->{deparse};
    my $parent_info = $deparsed->{optree}{$parent};
    return [$child_text] unless $parent_info;
    my $separator = $parent_info->{sep};
    my @texts = @{$parent_info->{texts}};
    my $parent_line = '';
    my $text_len = $#texts;
    my $result = '';

    for (my $i=0; $i <= $text_len; $i++) {
	my $text = $texts[$i];
	$result .= $separator if $result;

	if (ref($text)) {
	    if ((ref($text) eq 'ARRAY') and scalar(@$text) == 2) {
		if ($text->[1] == $child_addr) {
		    # Note $text->[0] may be different from $child_text.
		    # as in exec "$foo $bar" vs "$foo"
		    # FIXE: What do we do then?
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
	    } elsif (eval{$text->isa("B::DeparseTree::Node")}) {
		if ($text->{addr} == $child_addr) {
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
	    }
	} else {
	    $result .= $text;
	}
    }
    # Can't find by node address info, so just try to find the string
    # inside of the parent.
    my $parent_text = $parent_info->{text};
    my $start_index = index($parent_text, $child_text);
    if ($start_index >= 0) {
	if (index($parent_text, $child_text, $start_index+1) < 0) {
	    # It is in there *uniquely*!
	    # Remove any \n's before the text.
	    my $last_pos = 0;
	    my $start_search = index($parent_text, $child_text);
	    while ($start_search >= 0) {
		$last_pos = $start_search;
		$start_search = index($parent_text, $child_text, $last_pos+1);
	    }
	    my $start_pos = ($start_index - $last_pos);
	    my $parent_underline = ' ' x $start_pos ;

	    $parent_underline .= '~' x length($child_text);
	    return trim_line_pair($parent_text, $child_text, $parent_underline, $start_index);
	}
    }
}

unless (caller) {
    sub bug() {
	no strict;
	CORE::exec($foo $bar);
    }

    my $child_text = '$foo $bar';
    my $result = 'exec $foo $bar';
    my $parent_underline = "     ---------";
    my $start_pos = 0;
    my $lines = trim_line_pair($result, $child_text, $parent_underline,
			       $start_pos);
    print join("\n", @$lines), "\n";

    my $deparse = B::DeparseTree->new();
    $deparse->coderef2info(\&bug);
    # $deparse->coderef2info(\&get_addr_info);
    my @addrs = sort keys %{$deparse->{optree}}, "\n";
    use Data::Printer;
    # for (my $i=9; $i<=15; $i++) {
    for (my $i=0; $i < $#addrs; $i++) {
	print $i, '-' x 50, "\n";
	my $info = get_addr_info($deparse, $addrs[$i]);
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
	print $i, '-' x 50, "\n";
    }
}

1;
