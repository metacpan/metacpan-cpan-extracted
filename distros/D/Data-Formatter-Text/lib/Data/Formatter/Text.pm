package Data::Formatter::Text;
use strict;
use warnings;

use List::Util qw(max);
use Roman;

our $VERSION = 1.0;
use base qw(Data::Formatter);

######################################
# Constants                          #
######################################
our $HEADING_WIDTH      = 50;    # 50 chars is just an arbitrary default
our @BULLETS            = ('*', '-', '~');
our $COLUMN_SEPARATOR   = '|';
our $ROW_SEPARATOR      = '-';

######################################
# Overriden Public Methods           #
######################################
sub heading 
{
    my ($self, $text) = @_;
    
    # Headers are centered, all caps, and enclosed in a wide thick box
    return _box('#', '=', _centreAlign(uc($text), $HEADING_WIDTH));
}

sub emphasized 
{
    my ($self, $text) = @_;
    
    # Emphasized text is just all caps enclosed in a narrow thin box
    return _box(' !! ', '~', uc($text));
}

######################################
# Overriden Protected Methods        #
######################################
sub _write 
{
    my ($self, $text) = @_;
    my $handle = $self->{__OUTPUT_HANDLE} or return;
    
    print $handle ($text);
}

sub _text 
{
    my ($self, $text) = @_;
    return split(/\n/, $text);
}

sub _table 
{
    my ($self, $rows, %options) = @_;
    
    # Determine the dimensions of the table
    my @rowHeights;
    my @colWidths;
    foreach my $row (@{$rows})
    {
        my $rowHeight = -1;
        foreach my $colNum (0 .. $#{$row})
        {
            my @cellContents = $self->_formatCell($row->[$colNum]);
            if (@cellContents > $rowHeight)
            {
                $rowHeight = @cellContents;
            }
            
            # Get the width of the cell in characters
            my $cellWidth = max(map {length} @cellContents) || 0;
            if (!defined $colWidths[$colNum] || $cellWidth > $colWidths[$colNum])
            {
                $colWidths[$colNum] = $cellWidth;
            }
        }
        push(@rowHeights, $rowHeight);
    }
    
    # Generate a row separation line
    my $rowSepLine = join($COLUMN_SEPARATOR,  map { $ROW_SEPARATOR x $_ } @colWidths);
    
    # Output the table
    my @buffer;
    foreach my $rowIdx (0 .. $#{$rows})
    {
        my $row = $rows->[$rowIdx];
        
        # Get an array of all the cells in this row
        my @columns = map { [$self->_formatCell($_)] } @{$row};
       
        # Create an array of lines that constitute this row
        my @rowBuffer;
        foreach my $lineIdx (0 .. $rowHeights[$rowIdx] - 1)
        {
            my @parallelLines;
            foreach my $colNum (0 .. $#{$row})
            {
                my @cell = @{$columns[$colNum]};
                
                if (defined $cell[$lineIdx])
                {
                    push(@parallelLines, _leftAlign($cell[$lineIdx], $colWidths[$colNum]));
                }
                else
                {
                    push(@parallelLines, _leftAlign('', $colWidths[$colNum]));
                }
            }
            push(@rowBuffer, join($COLUMN_SEPARATOR, @parallelLines));
        }
        push(@buffer, @rowBuffer);
        
        if ($rowIdx != $#{$rows})
        {
            push(@buffer, $rowSepLine);
        }
    }
    
    # Draw a border around the table
    @buffer = _box($COLUMN_SEPARATOR, $ROW_SEPARATOR, @buffer);
    
    return @buffer;
}

sub _list
{
    my ($self, $list, %options) = @_;
    my $listType = $options{listType} || 'UNORDERED';
    my $bulletTypeIdx = $options{bulletType} || 0;
    my $numTypeIdx = $options{numberType} || 0;

    # Determine the type of bullet or number we will use
    my $point;
    if ($listType eq 'ORDERED')
    {
        $options{numberType} = $numTypeIdx + 1;
    }
    else
    {   
        $point = @BULLETS[$bulletTypeIdx % @BULLETS];
        $options{bulletType} = $bulletTypeIdx + 1;
    }

    my @buffer = ();
    foreach my $elementIdx (0 .. $#{$list})
    {
        my $element = $list->[$elementIdx];

        # Alternate between latin and roman numbering for ordered lists        
        if ($listType eq 'ORDERED')
        {
            $point = $numTypeIdx % 2 
                ? roman($elementIdx + 1) . '.'
                : ($elementIdx + 1) . '.';
        }
        
        my $prefix = "$point  ";
        my @elementLines = $self->_format($element, %options);

        # Nested lists are not printed "inside" a list element, or
        # it would look weird. Hence, a nested list is not prefixed
        # by a bullet or a number.         
        if ($self->_getStructType($element) =~ /\w+_LIST/)
        {            
            push(@buffer, map { ' ' x length($prefix) . $_ } @elementLines);
        }
        else
        {   
            push(@buffer, "$prefix$elementLines[0]",
                map { ' ' x length($prefix) . $_ } @elementLines[1 .. $#elementLines]);
        }
    }
    return @buffer;
}


sub _unorderedList 
{
    my ($self, $list, %options) = @_;
    
    return $self->_list($list, %options, listType => 'UNORDERED');
}

sub _orderedList 
{
    my ($self, $list, %options) = @_;
    
    return $self->_list($list, %options, listType => 'ORDERED');
}

sub _definitionList 
{
    my ($self, $pairs) = @_;
    my @buffer = ();
            
    # Output the pairs in alphabetical order with respect to the key
    my @keys = sort (keys %{$pairs});
    
    # Determine the max length of a key to perform some nice indenting.
    my $maxKeyLength = max(map {length} @keys);
    
    foreach my $key (@keys)
    {
        my $value = $pairs->{$key};
        my @valueLines = $self->_format($value);
        
        my $structType = $self->_getStructType($value);
        # Tables go below and are indented a constant 4 spaces
        if ($structType eq 'TABLE')
        {
            push(@buffer, 
                "$key:",
                map {"    $_"} @valueLines);
        }
        # The first line of text goes on the same line as the definition and subsequent
        # lines are indented by the maximum key length
        elsif ($structType eq 'TEXT')
        {
            push(@buffer, 
                "$key:" . ' ' x ($maxKeyLength - length($key) + 1) .  $valueLines[0],
                map {' ' x ($maxKeyLength + 2) . "  $_"} @valueLines[1..$#valueLines] );
        }
        # Everything else but text and tables goes on the following line and is indented
        # to line up with the end of the key
        else
        {
            push(@buffer, 
                "$key:",
                 map { ' ' x ($maxKeyLength + 2) . "  $_" } @valueLines);
        }
    }

    return @buffer;
}

######################################
# Private Methods                    #
######################################
sub _formatCell
{
    my ($self, $cell) = @_;
    
    if (ref($cell) && ref($cell) =~ /SCALAR/)
    {
        return (uc ${$cell});
    }
   
    return $self->_format($cell);
}

sub _leftAlign
{
    my ($text, $width) = @_;    
    if ($width <= length $text)
    {
        return $text;
    }

    return $text . (' ' x ($width - length($text))); 
}

sub _centreAlign
{
    my ($text, $width) = @_;
    
    my $lengthDiff = $width - length($text);
    if ($lengthDiff <= 0)
    {
        return $text;
    }

    my $leftMargin = ' ' x ($lengthDiff / 2);
    my $rightMargin = ' ' x ($lengthDiff - int($lengthDiff / 2));
    return $leftMargin . $text . $rightMargin;
}

sub _underline
{
    my ($text) = @_;
    
    return ($text, '-' x length($text));
}

sub _rightAlign
{
    my ($text, $width) = @_;
    if ($width <= length $text)
    {
        return $text;
    }

    return  (' ' x ($width - length($text))) . $text; 
}

sub _box
{
    my ($vertChar, $horizChar, @lines) = @_;
    
    # Determine the width of the whole block of text (the length of its longest line)
    my $width = max(map {length} @lines);
    
    # Insert the left and right side lines and, if necesary, append spaces to
    # any lines that aren't as long as the longest line
    @lines = map {$vertChar . _leftAlign($_, $width) . $vertChar} @lines;
    
    # Add two to the width to account for the side lines
    $width += 2 * length($vertChar);
    
    # Insert the top border line
    unshift(@lines, $horizChar x $width);
    
    # Insert the bottom border line
    push(@lines, $horizChar x $width);
    
    return @lines;
}

1;

=head1 NAME

Data::Formatter::Text - Perl extension for formatting data stored in scalars, hashes, and arrays into strings, definition lists, and bulletted lists, etc. using plain ASCII text. 

=head1 SYNOPSIS

  use Data::Formatter::Text;

  # The only argument to the constructor is a file handle. 
  # If no file handle is specified, output is sent to STDOUT
  my $text = new Data::Formatter::Text(\*STDOUT);

  $text->out('The following foods are tasty:',
             ['Pizza', 'Pumpkin pie', 'Sweet-n-sour Pork']);

  # Outputs,
  #
  # The following foods are tasty:
  #  * Pizza
  #  * Pumpkin pie
  #  * Sweet-n-sour Pork
  #

  $text->out('Do these things to eat an orange:',
            \['Peal it', 'Split it', 'Eat it']);

  # Outputs,
  #
  # Do these things to eat an orange: 
  #  1. Peal it 
  #  2. Split it 
  #  3. Eat it 
  #

  # If you don't need to output to a file, you can also use the format() class method
  # instead of the out() instance method.
  my $nums = Data::Formatter::Text->format(
      'Phone numbers' =>
       { 
           Pat => '123-4567',
           Joe => '999-9999',
           Xenu => '000-0000',
       }); 
		 
  # Stores in $nums:
  #
  # Phone numbers 
  # Joe:  999-9999
  # Pat:  123-4567
  # Xenu: 000-0000
  #

=head1 DESCRIPTION

A module that converts Perl data structures into formatted text,
much like Data::Dumper, except for that it formats the data nicely
for presentation to a human. For instance, refs to arrays are
converted into bulleted lists, refs to arrays that contain only refs
to arrays are converted into tables, and refs to hashes are
converted to definition lists.

All in all, data structures are mapped to display elements as follows:

 SCALAR                    => Text,
 REF to an ARRAY of ARRAYs => Table
 REF to an ARRAY           => Unordered (bulleted) list
 REF to a REF to an ARRAY  => Ordered (numbered) list
 REF to a HASH             => Definition list

Elements can be nested, so, for instance, you may have an array that 
contains one or more references to arrays, and it will be translated 
into a nested bulletted list.

=head2 Methods

=over 4

=item I<PACKAGE>->new()

Returns a newly created C<Data::Formatter::Text> object.

=item I<PACKAGE>->format(I<ARRAY>)

Returns the string representation of the arguments, formatted nicely.

=item I<$OBJ>->out(I<ARRAY>)

Outputs the string representation of the arguments to the file stream specified in the constructor.

=item I<$OBJ>->heading(I<SCALAR>)

Returns a new data-structure containing the same data as I<SCALAR>, but which will be displayed as a heading if passed to out().
Headings are center aligned, made all uppercase, and surrounded by a thick border.

For example,

	$text->out($text->heading("Test Results"), "All is well!");
 
=item I<$OBJ>->emphasized(I<SCALAR>)

Returns a new data-structure containing the same data as I<SCALAR>, but which will be displayed as emphasized text if passed to out().
Emphasized text is made all uppercase and surrounded by a thin border.

For example,
	
    $text->out($text->emphasized("Cannot find file!"));

=back

=head2 Configuration

=over 4

=item I<$PACKAGE>::HEADING_WIDTH

The minimum width of a heading, as created by the I<heading()> method, excluding its surrounding box and measured in characters. By default, this is 50.

=item I<@PACKAGE>::BULLETS

An array of all the styles of bullet used for bulleted lists, in the order they are used as you move deeper into a nested list. This array must contain
at least one element, and by default is equal to ('*', '-', '~').

=item I<$PACKAGE>::COLUMN_SEPARATOR

The string used to separate columns in a table and draw the vertical portions of its border.

=item I<$PACKAGE>::ROW_SEPARATOR

The string used to separate rows in a table and draw the horizontal portions of its border.

=back

=head2 Example

    $formatter->out('Recipes',
        {
            "Peanutbutter and Jam Sandwich" =>
            [
                ['Ingredient', 'Amount', 'Preparation'],
                ['Bread', '2 slices', ''],
                ['Jam', 'Enough to cover inner face of slice 1', ''],
                ['Peanutbutter', 'Enough to cover inner face of slice 2', '']
            ]
        }
    );

The code above will output the text:

 Recipes
 Peanutbutter and Jam Sandwich:
     ----------------------------------------------------------------
     |Ingredient  |Amount                               |Preparation|
     |------------|-------------------------------------|-----------|
     |Bread       |2 slices                             |           |
     |------------|-------------------------------------|-----------|
     |Jam         |Enough to cover inner face of slice 1|           |
     |------------|-------------------------------------|-----------|
     |Peanutbutter|Enough to cover inner face of slice 2|           |
     ----------------------------------------------------------------

Note that the order of elements in a hash is not necessarily the same as the order the elements are printed in; instead, hash elements are sorted alphabetically by their keys before being output.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
