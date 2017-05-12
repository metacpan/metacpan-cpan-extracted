package Curses::UI::DelimitedTextViewer;
###############################################################################
# subclass of Curses::UI::TextViewer that display delimited files onscreen
# in fixed width columns
#
# (c) 2002 by Garth Sainio. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as perl itself.
###############################################################################
use strict;
use warnings;
use Curses;
use Curses::UI::Common;
use Curses::UI::TextViewer;

use vars qw(
    $VERSION
    @ISA
);

$VERSION = '0.10';

@ISA = qw(
          Curses::UI::TextViewer
);

sub new () {
    my $class = shift;

    my %userargs = @_;
    keys_to_lowercase(\%userargs);

    my %args = (
        %userargs,
    );
    my $obj =  $class->SUPER::new( %args);

    # set the delimiter, default to tab
    $obj->{'-delimiter'} = $userargs{'-delimiter'} || "\t";

    # set the fieldSeparator
    $obj->{'-fieldSeparator'} = $userargs{'-fieldSeparator'} || "|";

    # Caclulate the widths of the columns
    $obj->{'-widths'} = $obj->calculate_widths($userargs{'-text'});
    $obj->{'-maxcolumns'} = scalar(@{$obj->{'-widths'}});
    $obj->{'-current_column'} = 0;

    # Turn the delimited text into fixed width text
    $obj->{'-text'} = $obj->process_text($obj->{'-text'});

    # Check to see if the user wants to scroll by column
    if($userargs{'-columnScroll'}) {
        $obj = $obj->set_routine('cursor-right', \&scroll_column_right);
        $obj = $obj->set_routine('cursor-left', \&scroll_column_left);
    }

    return $obj;
}

###############################################################################
# process_text
# reformat the incoming text and get a list of the width of each delimited
# field. Store those widths for future scrolling
###############################################################################
sub process_text {
    my ($self, $text) = @_;

    my $out_text = "";
    my $column_width = $self->{'-widths'};

    # split on new lines
    my @lines = split($/, $text);

    # Now format the lines
    foreach my $line (@lines) {
        chomp($line);
        my @parts = split("\t", $line);
        foreach my $i (0..$#parts) {
            # pad the part
            my $spaces = $column_width->[$i] - length($parts[$i]);
            $out_text .= $parts[$i] . " " x $spaces;
            $out_text .= $self->{'-fieldSeparator'};
        }

        if($self->{'-addBlankColumns'}) {
            # Check to see if there were fewer columns in the line
            # than in the column_width array
            my $missing = scalar(@{$column_width}) - scalar(@parts);
            foreach my $i (1..$missing) {
                $out_text .= " " x $column_width->[$#parts + $i];
                $out_text .= $self->{'-fieldSeparator'};
            }
        }

        $out_text .= "$/";
    }

    return $out_text;
}

###############################################################################
# calculate_widths
###############################################################################
sub calculate_widths {
    my($self, $text) = @_;
    my @column_widths;

    # calculate the column widths
    # split on new lines
    my @lines = split("$/", $text);
    foreach my $line (@lines) {
        # then split on the delimiter
        my @parts = split("\t", $line);
        # Check to see if the width of the column is greater than the
        # already existing width
        foreach my $i (0..$#parts) {
            my $length = length($parts[$i]);
            unless(defined($column_widths[$i])) {
                $column_widths[$i] = $length;
            }
            $column_widths[$i] = $length if($length > $column_widths[$i]);
        }
    }
    return \@column_widths;
}

###############################################################################
# scroll the cursor by a column width at a time
###############################################################################

sub scroll_column_right {
    my $self = shift;

    # Check to make sure that the cursor is not already at the last
    # column

    return $self->dobeep 
      if($self->{'-current_column'} == $self->{'-maxcolumns'});

    # Look up the current columns width and use that as the offset
    my $index = $self->{'-current_column'};
    my @widths = @{$self->{'-widths'}};
    my $offset = $self->{'-widths'}->[$self->{'-current_column'}];

    # Don't scroll if the last column is already completely on screen
    return $self->dobeep 
      if(($self->{-xscrpos}) >= ($self->{-hscrolllen} - $self->canvaswidth));

    # The first column should only be shifted the width the column
    # whereas the others should be shifted the width of the column
    # plus one. This keep the left edge of the screen (where the $
    # appears) as the last space in the previous column.
    if($index > 0) {
        $offset++;
    }

    # update the current column
    $self->{'-current_column'}++;

    $self->{-xscrpos} += $offset;
    $self->{-hscrollpos} = $self->{-xscrpos};
    $self->{-xpos} = $self->{-xscrpos};

    return $self;
}

###############################################################################
# scroll the cursor by a column width at a time
###############################################################################

sub scroll_column_left {
    my $self = shift;

    # Check to make sure that the cursor is not already at the first column

    return $self->dobeep if($self->{'-current_column'} == 0);

    # Look up the previous column's width and use that as the offset
    my $index = $self->{'-current_column'};
    $index--;
    my $offset = $self->{'-widths'}->[$index];

    # The first column should only be shifted the width the column
    # whereas the others should be shifted the width of the column
    # plus one. This keep the left edge of the screen (where the $
    # appears) as the last space in the previous column.
    if($index > 0) {
        $offset++;
    }

    # update the current column
    $self->{'-current_column'}--;

    $self->{-xscrpos} -= $offset;
    $self->{-hscrollpos} = $self->{-xscrpos};
    $self->{-xpos} = $self->{-xscrpos};

    return $self;
}


1;

=pod

=head1 NAME
Curses::UI::DelimitedTextViewer - Displays delimited files as fixed width.

=head1 CLASS HIERARCHY

 Curses::UI::Widget
 Curses::UI::Searchable
    |
    +----Curses::UI::TextEditor
            |
            +----Curses::UI::TextViewer
                    |
                    +----Curses::UI::DelimitedTextViewer

=head1 SYNOPSIS

  my $editor = $screen->add(
        'editor', 'DelimitedTextViewer',
        -border          => 1,
        -padtop          => 0,
        -padbottom       => 3,
        -showlines       => 0,
        -sbborder        => 0,
        -vscrollbar      => 1,
        -hscrollbar      => 1,
        -showhardreturns => 0,
        -wrapping        => 0,
        -text            => $text,
        -columnScroll    => 1,
        -addBlankColumns => 1,
        -fieldSeparator  => "*",
  );

=head1 DESCRIPTION

Curses::UI::DelimitedTextViewer is subclass of Curses::UI::TextViewer
which allows a delimited file to be viewed on screen as a fixed width
file. This class adds the following arguments to those used by
Curses::UI::TextViewer:

-delimiter specifies the delimiter used in incoming data

-scrollColumn sets to 1 to scroll left and right column by column

-fieldSeparator  character used to seperate one column from another, the 
default is a |

-addBlankColumns adds extra columns of spaces and seperators if the incoming 
data line did not have the maximum number of fields in it


=head1 SEE ALSO

L<Curses::UI|Curses::UI>,
L<Curses::UI::TextViewer>


=head1 AUTHOR

Copyright (c) 2002 Garth Sainio. All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty. It may be used, redistributed and/or modified
under the same terms as perl itself.


=cut
