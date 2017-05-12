# BioPerl module for Bio::Community::Role::Table
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Table - Role to read/write data tables and provide random
access to their cells

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  extends 'Bio::Root::IO';
  with 'Bio::Community::Role::Table';

  # Use the new(), _read_table(), _get_value(), _set_value(), _insert_line(),
  # _delete_col() and _write_table()
  # methods as needed
  # ...

  1;

=head1 DESCRIPTION

This role implements methods to read and write file structured as a table
containing rows and columns. When reading a table from a file, an index is kept
to provide random-access to any cell of the table. When writing a table to a file,
cell data can also be given in any order. It is kept in memory until the file is
written to disk.

Objects are constructed with the new() method. Since Table-consuming classes
must inherit from Bio::Root::IO, all Bio::Root::IO options are accepted, e.g.
-file, -fh, -string, -flush, etc. Other constructors are detailed in the
L<APPENDIX>.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


package Bio::Community::Role::Table;

use Moose::Role;
use Method::Signatures;
use namespace::autoclean;
use Fcntl;


# Consuming class has to inherit from Bio::Root::IO
requires '_fh',
         '_readline',
         '_print';


=head2 delim

 Usage   : my $delim = $in->delim;
 Function: When reading or writing a table, get or set the delimiter, i.e. the
           characters that delimit the columns of the table. The default is the
           tab character "\t".
 Args    : A string
 Returns : A string

=cut

has 'delim' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => '-delim',
   lazy => 1,
   default => "\t",
);


# New lines can be: \n, \r\n, ... Record number of newline chars here
has '_num_eol_chars' => (
   is => 'rw',
   #isa => 'PositiveInt',
   required => 0,
   lazy => 1,
   default => 0,
);


=head2 start_line

 Usage   : my $line_num = $in->start_line;
 Function: When reading a table, get or set the line number at which the table
           starts. The default is 1, i.e. the table starts at the first line of
           the file. This option is not used when writing a table, but see
           _write_table() for details.
 Args    : A strictly positive number
 Returns : A strictly positive number

=cut

has 'start_line' => (
   is => 'ro',
   isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => '-start_line',
   lazy => 1,
   default => 1,
);


=head2 end_line

 Usage   : my $line_num = $in->end_line;
 Function: When reading a table, get or set the line number at which the table
           ends. If undef (the default), the table ends at the last line of the
           file.
 Args    : A strictly positive number or undef
 Returns : A strictly positive number or undef

=cut

has 'end_line' => (
   is => 'ro',
   isa => 'Maybe[StrictlyPositiveInt]',
   required => 0,
   init_arg => '-end_line',
   lazy => 1,
   default => undef,
);


=head2 missing_string

 Usage   : my $missing = $out->missing_string;
 Function: When reading a table, get or set the line number at which the table
           ends. If undef (the default), the table ends at the last line of the
           file.
 Args    : A string, e.g. '', '0', 'n/a', '-'
 Returns : A string

=cut

has 'missing_string' => (
   is => 'ro',
   isa => 'Str',
   required => 0,
   init_arg => '-missing_string',
   lazy => 1,
   default => '0',
);


=head2 _get_start_content

 Usage   : my $txt = $in->_get_start_content;
 Function: After the table has been parsed, this returns everything before -start_line
 Args    : A strictly positive number
 Returns : A strictly positive number

=cut

has '_start_content' => (
   is => 'ro',
   isa => 'Maybe[Str]',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => '',
   reader => '_get_start_content',
   writer => '_set_start_content',
);


=head2 _get_max_line

 Usage   : my $num_lines = $in->_get_max_line;
 Function: Get the number of lines in the table
 Args    : None
 Returns : Positive integer

=cut

has '_max_line' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_line',
   writer => '_set_max_line',
);


=head2 _get_max_col

 Usage   : my $num_cols = $in->_get_max_col;
 Function: Get the number of columns in the table
 Args    : None
 Returns : Positive integer

=cut

has '_max_col' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_col',
   writer => '_set_max_col',
);


method BUILD ($args) {
   # After object constructed with new(), index table if filehandle is readable
   if ($self->mode eq 'r') {
      $self->_read_table;
   }
}


# Index of the location of the cells (when reading a table)
has '_index' => (
   is => 'rw',
   #isa => 'ArrayRef[PositiveInt]',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => sub { [] },
   predicate => '_has_index',
);


# Value contained in the table cells (when writing a table)
has '_values' => (
   is => 'rw',
   #isa => 'ArrayRef[Str]'
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => sub { [] },
);


has '_was_written' => (
   is => 'rw',
   #isa => 'Bool',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
);


=head2 _read_table

 Usage   : $in->_read_table;
 Function: Read the table in the file and index the position of its cells.
 Args    : None
 Returns : 1 on success

=cut

method _read_table () {
   # Index the file the first time

   if ( $self->_has_index ) {
      return 1;
   }

   my $start_line = $self->start_line;
   my $end_line   = $self->end_line;
   if ( (defined $end_line) && ($end_line < $start_line) ) {
      $self->throw("Error: Got start ($start_line) greater than end ($end_line)\n");
   }

   my @index; # array of file offsets 
   my ($max_line, $max_col) = (0, 0);

   my $delim = $self->delim;
   my $delim_length = length $delim;

   my $file_offset = 0;
   my $num_eol_chars;

   # In Windows, text files have '\r\n' as line separator, but when reading in
   # text mode Perl will only show the '\n'. This means that for a line "ABC\r\n",
   # "length $_" will report 4 although the line is 5 bytes in length.
   # We assume that all lines have the same line separator and only read current line.
   my $fh         = $self->_fh;
   my $init_pos   = tell($fh);
   my $init_line  = $.;
   my $curr_line  = <$fh> || '';
   my $pos_diff   = tell($fh) - $init_pos;
   my $correction = $pos_diff - length $curr_line;
   $fh->input_line_number($init_line); # Rewind line number $.
   seek $fh, $init_pos, 0;             # Rewind position to proceed to read the file

   while (my $line = $self->_readline(-raw => 1)) { # _readline is from Bio::Root::IO

      next if $line =~ m/^\s*$/;

      if (not defined $num_eol_chars) {
         # Count line length
         $line =~ m/([\r\n]?\n)$/; # last line may not match
         $num_eol_chars = length($1||'') + $correction;
      }

      my $line_length = length($line) + $correction;

      # Do not index the line if it is before or after the table
      if ($. < $start_line) {
         $self->_set_start_content( $self->_get_start_content . $line );
         $file_offset += $line_length;
         next;
      }
      if ( (defined $end_line) && ($. > $end_line) ) {
         next;
      }

      # Save the offset of the first line of the table
      if (scalar @index == 0) {
         push @index, $file_offset;
      }

      # Index the line
      my $line_offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $delim, $line_offset);
         if ($match == -1) {
            # Reached end of line. Register it and move on to next line.
            $match = length( $line ) + $correction - $num_eol_chars;
            push @matches, $match + $file_offset;
            $file_offset += $line_length;
            last;
         } else {
            # Save the match
            push @matches, $match + $file_offset;
            $line_offset = $match + $delim_length;
         }
      }
      my $nof_cols = scalar @matches;
      if ($nof_cols != $max_col) {
         if ($max_col == 0) {
            # Initialize the number of columns
            $max_col = $nof_cols;
         } else {
            $self->throw( "Error: Got $nof_cols columns at line $. but got a ".
               "different number ($max_col) at the previous line\n" );
         }
      }
      $max_line++;
      push @index, @matches;
   }

   $self->_num_eol_chars( $num_eol_chars );
   $self->_index(\@index);
   $self->_set_max_line($max_line);
   $self->_set_max_col($max_col);

   return 1;
}


=head2 _get_value

 Usage   : my $value = $in->_get_value(1, 3);
 Function: Get the value of the cell given its position in the table (line and
           column).
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
 Returns : A string for the value of the table at the given line and column
             or
           undef if line or column was out-of-bounds

=cut

#method _get_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col) {
method _get_value ($line, $col) { # this function is called a lot, keep it lean
   my $val;
   my $max_col = $self->_get_max_col;
   if ( ($line <= $self->_get_max_line) && ($col <= $max_col) ) {

      # Retrieve the value if it is within the bounds of the table
      my $pos = ($line - 1) * $max_col + $col - 1;
      my $offset = $self->_index->[$pos];

      # Adjust offset
      if ( $pos % $max_col ) {
         # For columns (except first one), account for prepended delimiter
         my $delim_len = length $self->delim;
         $offset += $delim_len;
      } else {
         if ($pos) {
            # For lines (except first one), account for preprended new line chars
            $offset += $self->_num_eol_chars;
         }
      }

      # Read value
      seek( $self->_fh, $offset, 0 ) or $self->throw("Could not seek on filehandle at offset $offset: $!\n");
      defined( read( $self->_fh, $val, $self->_index->[$pos+1] - $offset ) ) or $self->throw("Could not read from filehandle: $!\n");
      # Note: read() returns the number of characters read, 0 at end of file, or undef if there was an error
 
   }
   return $val;
}


=head2 _set_value

 Usage   : $out->_set_value(1, 3, $value);
 Function: Set the element at the given line and column of the table.
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
           A string for the value of the table at the given line and column
 Returns : 1 for success

=cut

#method _set_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col, $value) {
method _set_value ($line, $col, $value) {  # this function is called a lot, keep it lean
   my $pos = 0;
   my $values = $self->_values;
   my $max_lines = $self->_get_max_line;
   my $max_cols  = $self->_get_max_col;

   # Extend table with columns if needed
   if ($col > $max_cols) {
      my $new_max_cols = $col;
      my $max_idx = $new_max_cols * $max_lines - 1;
      my @padding = ($self->missing_string) x ($new_max_cols - $max_cols);
      for ( my $idx  = $max_cols;
               $idx <= $max_idx;
               $idx += $new_max_cols ) {
         splice @$values, $idx, 0, @padding;
      }
      $max_cols = $new_max_cols;
      $self->_set_max_col($new_max_cols);
   }

   # Extend table with lines if needed
   if ($line > $max_lines) {
      my $new_max_lines = $line;
      my $max_idx = $max_cols * $new_max_lines - 1;
      my @padding = ($self->missing_string) x $max_cols;
      for ( my $idx  = $max_cols * $max_lines;
               $idx <= $max_idx;
               $idx += $max_cols ) {
         splice @$values, $idx, 0, @padding;
      }
      $max_lines = $new_max_lines;
      $self->_set_max_line($new_max_lines);
   }

   # Set new value
   $pos = ($line - 1) * $max_cols + $col - 1;
   $values->[$pos] = $value;

   return 1;
}


=head2 _insert_line

 Usage   : $out->_insert_line(3, ['sample1', 3, 10.9, 'Mus musculus']);
 Function: Insert a line of values in the table, at the indicated line, shifting
           all other lines down. You can also append a line to the table by
           providing the maximum line number + 1.
 Args    : A strictly positive integer for the line at which to insert
           An arrayref containing the values to insert (must match table width)
 Returns : 1 for success

=cut

#method _insert_line (StrictlyPositiveInt $line, ArrayRef $values) {
method _insert_line ($line, $insert_values) {  # this function is called a lot, keep it lean
   my $max_lines = $self->_get_max_line;
   if ($line > $max_lines + 1) {
      $self->throw("Could not insert line beyond last line of table.");
   }

   my $max_cols  = $self->_get_max_col;
   if ( ($max_cols > 0) && (scalar @$insert_values != $max_cols) ) {
      $self->throw("Could not insert a line because it did not match table width ($max_cols).");
   }

   my $idx = $max_cols * ($line - 1);
   splice @{$self->_values}, $idx, 0, @$insert_values;

   $self->_set_max_line($max_lines + 1);
   if ($max_cols == 0) {
      $self->_set_max_col(scalar @$insert_values);
   }

   return 1;
}


=head2 _delete_col

 Usage   : $out->_delete_col(3);
 Function: Delete a column of the table.
 Args    : A strictly positive integer for the column to delete.
 Returns : 1 for success

=cut

#method _delete_col (StrictlyPositiveInt $col) {
method _delete_col ($col) {  # this function is called a lot, keep it lean

   my $max_cols = $self->_get_max_col;
   if ( $col > $max_cols ) {
      $self->throw("Could not delete column $col because the table has only $max_cols columns.");
   }

   # Extend table with columns if needed
   my $max_lines = $self->_get_max_line;
   my $max_idx = $max_cols * $max_lines - 1;
   my $values = $self->_values;
   for (my $idx = $max_idx; $idx >= 0; $idx -= $max_cols) {
      splice @$values, $idx, 1;
   }

   $self->_set_max_col( $max_cols - 1 );

   if ($self->_get_max_col == 0) {
      $self->_set_max_line( 0 );
   }

   return 1;
}


=head2 _write_table

 Usage   : $out->_write_table;
 Function: Write the content of the cells in the table to a file. It is
           generally called automatically when closing the object. However, if
           you want header lines before or after the table, you can write them
           to file using the _print() method of Bio::Root::IO prior and after
           calling _write_table().
 Args    : None
 Returns : 1 on success

=cut

method _write_table () {
   my $delim    = $self->delim;
   my $values   = $self->_values;
   my $max_cols = $self->_get_max_col;
   for my $line ( 1 .. $self->_get_max_line ) {
      my $start = ($line - 1) * $max_cols;
      my $end   =  $line      * $max_cols - 1;
      $self->_print( join( $delim, @$values[$start..$end] ) . "\n" );
   }
   $self->_was_written(1);
   return 1;
}


1;
