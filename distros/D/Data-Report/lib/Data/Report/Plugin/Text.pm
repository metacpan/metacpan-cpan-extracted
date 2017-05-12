# Data::Report::Plugin::Text.pm -- Text plugin for Data::Report
# RCS Info        : $Id: Text.pm,v 1.10 2008/08/18 09:51:23 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Dec 28 13:21:11 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 18 11:46:04 2008
# Update Count    : 149
# Status          : Unknown, Use with caution!

package Data::Report::Plugin::Text;

use strict;
use warnings;
use base qw(Data::Report::Base);
use Carp;

################ User API ################

sub start {
    my $self = shift;
    $self->_argcheck(0);
    $self->SUPER::start;
    $self->_make_format;
    $self->{lines} = 0;
    $self->{page} = $=;
}

sub add {
    my ($self, $data) = @_;

    my $style = delete($data->{_style});
    if ( $style && !$self->_checkname($style) ) {
	croak("Invalid style name: \"$style\"");
    }
    $self->SUPER::add($data);

    $self->_checkhdr;

    my $skip_after = 0;
    my $line_after = 0;
    my $cancel_skip = 0;
    if ( $style and my $t = $self->_getstyle($style) ) {
	return	     if $t->{ignore};
	$self->_skip if $t->{skip_before};
	$skip_after   = $t->{skip_after};
	$self->_line if $t->{line_before};
	$line_after   = $t->{line_after};
	$cancel_skip  = $t->{cancel_skip};
    }
    $style = "*" unless defined($style);
    $self->_checkskip($cancel_skip);

    my @values;
    my @widths;
    my @indents;
    my $linebefore;
    my $lineafter;

    foreach my $col ( @{$self->_get_fields} ) {
	my $fname = $col->{name};
	my $t = $style ? $self->_getstyle($style, $fname) : {};
	next if $t->{ignore};

	push(@values, defined($data->{$fname}) ? $data->{$fname} : "");
	push(@widths, $col->{width});
	if ($col->{truncate} ) {
	    $values[-1] = substr($values[-1], 0, $widths[-1]);
	}

	# Examine style mods.
	my $indent = 0;
	my $wrapindent = 0;
	my $excess = 0;
	if ( $t ) {
	    $indent = $t->{indent} || 0;
	    $wrapindent = defined($t->{wrap_indent}) ? $t->{wrap_indent} : $indent;
	    croak("Row $style, column $fname, ".
		  "illegal value for indent property: $indent")
	      if $indent < 0 || $indent >= $self->_get_fdata->{$fname}->{width};
	    croak("Row $style, column $fname, ".
		  "illegal value for wrap_indent property: $wrapindent")
	      if $wrapindent < 0 || $wrapindent >= $self->_get_fdata->{$fname}->{width};
	    if ( $t->{line_before} ) {
		$linebefore->{$fname} =
		  ($t->{line_before} eq "1" ? "-" : $t->{line_before}) x $col->{width};
	    }
	    if ( $t->{line_after} ) {
		$lineafter->{$fname} =
		  ($t->{line_after} eq "1" ? "-" : $t->{line_after}) x $col->{width};
	    }
	    if ( $t->{excess} ) {
		$widths[-1] += 2;
	    }
	    if ( $t->{truncate} || $col->{truncate} ) {
		$values[-1] = substr($values[-1], 0, $widths[-1] - $indent);
	    }
	}
	push(@indents, [$indent, $wrapindent]);

    }

    if ( $linebefore ) {
	$linebefore->{_style} = "";
	$self->add($linebefore);
    }

    my @lines;
    while ( 1 ) {
	my $more = 0;
	my @v;
	foreach my $i ( 0..$#widths ) {
	    my ($ind, $wind) = @{$indents[$i]};
	    $ind = $wind if @lines;
	    my $maxw = $widths[$i] - $ind;
	    $ind = " " x $ind;
	    if ( length($values[$i]) <= $maxw ) {
		push(@v, $ind.$values[$i]);
		$values[$i] = "";
	    }
	    else {
		my $t = substr($values[$i], 0, $maxw);
		if ( substr($values[$i], $maxw, 1) eq " " ) {
		    push(@v, $ind.$t);
		    substr($values[$i], 0, length($t) + 1, "");
		}
		elsif ( $t =~ /^(.*)([ ]+)/ ) {
		    my $pre = $1;
		    push(@v, $ind.$pre);
		    substr($values[$i], 0, length($pre) + length($2), "");
		}
		else {
		    push(@v, $ind.$t);
		    substr($values[$i], 0, $maxw, "");
		}
		$more++;
	    }
	}
	my $t = sprintf($self->{format}, @v);
	$t =~ s/ +$//;
	push(@lines, $t) if $t =~ /\S/;
	last unless $more;
    }

    if ( $self->{lines} < @lines ) {
	$self->_needhdr(1);
	$self->_checkhdr;
    }
    $self->_print(@lines);

    # Post: Lines for cells.
    if ( $lineafter ) {
	$lineafter->{_style} = "";
	$self->add($lineafter);
    }
    # Post: Line for row.
    if ( $line_after ) {
	$self->_line;
    }
    # Post: Skip after this row.
    elsif ( $skip_after ) {
	$self->_skip;
    }
}

sub finish {
    my $self = shift;
    $self->_argcheck(0);
    $self->_checkskip(1);	# cancel skips.
    $self->SUPER::finish();
}

################ Pseudo-Internal (used by Base class) ################

sub _std_heading {
    my ($self) = @_;

    # Print column names.
    my $t = sprintf($self->{format},
		    map { $_->{title} }
		    grep {
			my $t = $self->_getstyle("_head", $_->{name});
			! $t->{ignore};
		    }
		    @{$self->_get_fields});

    # Add separator line.
    $t .= "-" x ($self->{width});
    $t .= "\n";

    # Remove trailing blanks.
    $t =~ s/ +$//gm;

    # Print it.
    $self->_print($t);

    $self->_needskip(0);

}

################ Internal methods ################

sub _print {
    my ($self, @values) = @_;
    my $value = join("", @values);
    $self->SUPER::_print($value);
    $self->{lines} -= ($value =~ tr/\n//);
}

sub _pageskip {
    my ($self) = @_;
    $self->{lines} = $self->{page};
}

sub _make_format {
    my ($self) = @_;

    my $width = 0;		# new width
    my $format = "";		# new format

    foreach my $a ( @{$self->_get_fields} ) {

	my $t = $self->_getstyle("_head", $a->{name});
	next if $t->{ignore};

	# Never mind the trailing blanks -- we'll trim anyway.
	$width += $a->{width} + 2;
	if ( $a->{align} eq "<" ) {
	    $format .= "%-".
	      join(".", ($a->{width}+2) x 2) .
		"s";
	}
	else {
	    $format .= "%".
	      join(".", ($a->{width}) x 2) .
		"s  ";
	}
    }

    # Store format and width in object.
    $self->{format} = $format . "\n";
    $self->{width}  = $width - 2;

    # PBP: Return nothing sensible.
    return;
}

sub _checkskip {
    my ($self, $cancel) = @_;
    return if !$self->_does_needskip || $self->{lines} <= 0;
    $self->_print("\n") unless $cancel;
    $self->_needskip(0);
}

sub _needskip {
    my $self = shift;
    $self->{needskip } = shift;
}
sub _does_needskip {
    my $self = shift;
    $self->{needskip};
}

sub _line {
    my ($self) = @_;

    $self->_checkhdr;
    $self->_checkskip(1);	# cancel skips.

    $self->_print("-" x ($self->{width}), "\n");
}

sub _skip {
    my ($self) = @_;

    $self->_checkhdr;
    $self->_needskip(1);
}

sub _center {
    my ($self, $text, $width) = @_;
    (" " x (($width - length($text))/2)) . $text;
}

sub _expand {
    my ($self, $text) = @_;
    $text =~ s/(.)/$1 /g;
    $text =~ s/ +$//;
    $text;
}

1;
