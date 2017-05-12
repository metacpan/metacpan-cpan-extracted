package CAM::DBF;

require 5.005_62;
use warnings;
use strict;
use Carp;

our $VERSION = '1.02';

## Package globals

# Performance tests showed that a rowcache of 100 is better than
# rowcaches of 10 or 1000 (presumably due to tradeoffs in overhead
# vs. processor data cache usage vs. memory allocation)

our $ROWCACHE = 100;  # how many rows to cache at a time
# Set that to 0 for debugging


=for stopwords Borland DBF XBase dBASE

=head1 NAME

CAM::DBF - Perl extension for reading and writing dBASE III DBF files

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Please see the L<XBase> modules on CPAN for more complete
implementations of DBF file reading and writing.  This module differs
from those in that it is designed to be error-correcting for corrupted
DBF files.  If you already know how to use L<DBI>, then L<DBD::XBase>
will likely make you happier than this module.

I don't do much DBF work any longer, so updates to this module will be
infrequent.

=head1 SYNOPSIS

  use CAM::DBF;
  my $dbf = CAM::DBF->new($filename);
  
  # Read routines:
  
  print join('|', $dbf->fieldnames()),"\n";
  for my $row (0 .. $dbf->nrecords()-1) {
     print join('|', $dbf->fetchrow_array($row)),"\n";
  }
  
  my $row = 100;
  my $hashref = $dbf->fetchrow_hashref($row);
  my $arrayref = $dbf->fetchrow_hashref($row);
  
  # Write routines:
  
  $dbf->delete($row);
  $dbf->undelete($row);

=head1 DESCRIPTION

This package facilitates reading and writing dBASE III PLUS DBF files.
This is made possible by documentation generously released by Borland
at L<http://community.borland.com/article/0,1410,15838,00.html>

Currently, only version III PLUS files are readable.  This module does
not support dBASE version IV or 5.0 files.  See L<XBase> for better
support.

=head1 CLASS METHODS

=over 4

=cut

#----------------

# Internal function, called by new() or create()

my %filemode_open_map = (
   'r'  => '<',
   'r+' => '+<',
   'w'  => '>',
   'w+' => '+>',
   'a'  => '>>',
   'a+' => '+>>',
);

sub _init
{
   my $pkg = shift;
   my $filename = shift;
   my $filemode = shift;

   my %flags;
   if (@_ % 2 == 0)
   {
      %flags = @_;
   }

   if (!defined $filemode || $filemode eq q{})
   {
      $filemode = 'r';
   }

   if (!$filemode_open_map{$filemode})
   {
      croak 'Invalid file mode';
   }

   my @times = localtime;
   my $year = $times[5]+1900;
   my $month = $times[4]+1;
   my $date = $times[3];

   my $self = bless {
      filename => $filename, 
      filemode => $filemode,
      fh       => undef,
      fields   => [],
      columns  => [],

      valid        => 0x03,
      year         => $year,
      month        => $month,
      date         => $date,
      nrecords     => 0,
      nheaderbytes => 0,
      nrecordbytes => 0,
      packformat   => 'C',

      flags => \%flags,
   }, $pkg;

   $self->_open_fh();

   return $self;
}
sub _open_fh
{
   my $self = shift;

   if ($self->{filename} eq q{-})
   {
      # This might be fragile, since seek won't work
      if ($self->{filemode} =~ m/r/xms)
      {
         $self->{fh} = \*STDIN;
      }
      else
      {
         $self->{fh} = \*STDOUT;
      }
   }
   else
   {
      my $fh;
      if (open $fh, $filemode_open_map{$self->{filemode}}, $self->{filename})
      {
         $self->{fh} = $fh;
      }
   }
   if (!$self->{fh})
   {
      croak "Cannot open DBF file $self->{filename}: $!";
   }
   binmode $self->{fh};

   return;
}

#----------------

=item $pkg->new($filename)

=item $pkg->new($filename, $mode)

=item $pkg->new($filename, $mode, $key => $value, ...)

Open and read a dBASE file.  The optional mode parameter defaults to
C<r> for read-only.  If you plan to alter the DBF, open it as C<r+>.

Additional behavior flags can be passed after the file mode.
Available flags are:

=over

=item C<< ignoreHeaderBytes => 0|1 >>

Looks for the 0x0D end-of-header marker instead of trusting the 
stated header length. Default 0.

=item C<< allowOffByOne => 0|1 >>

Only matters if C<ignoreHeaderBytes> is on.  If the computed header size
differs from the declared header size by one byte, use the
latter. Default 0.

=item C<< verbose => 0|1 >>

Print warning messages about header problems, or stay quiet. Default
0.

=back

=cut

sub new
{
   my $pkg = shift;
   my $filename = shift;
   my $filemode = shift;

   my $self = $pkg->_init($filename, $filemode, @_);

   ## Parse the header

   my $header;
   read $self->{fh}, $header, 32;
   ($self->{valid},
    $self->{year},
    $self->{month},
    $self->{date},
    $self->{nrecords},
    $self->{nheaderbytes},
    $self->{nrecordbytes}) = unpack 'CCCCVvv', $header;
   
   if (!$self->{valid} || $self->{valid} != 0x03 && $self->{valid} != 0x83)
   {
      croak "This does not appear to be a dBASE III PLUS file ($filename)";
   }

   my $filesize = ($self->{nheaderbytes} + 
                   $self->{nrecords} * $self->{nrecordbytes});
   $self->{filesize} = -s $filename;

   if ($self->{filesize} < $self->{nheaderbytes})
   {
      if (!$self->{flags}->{ignoreHeaderBytes})
      {
         croak "DBF file $filename appears to be severely truncated:\n" .
               "Header says it should be $filesize bytes, but it's only $self->{filesize} bytes\n" .
               "  Records = $self->{nrecords}\n";
      }
   }
   
   # correct 2 digit year
   $self->{year} += 1900;
   if ($self->{year} < 1970)
   {
      $self->{year} += 100;  # Y2K fix
   }

   my $field;
   my $pos = 64;
   read $self->{fh}, $field, 1;

   # acording to the Borland spec 0x0D marks the end of the header block
   # however we have seen this fail so $pos ensures we do not read beyond
   # the header block for table columns
   # We've also found flaky files which use 0x0A instead of 0x0D
   while ($field && (0x0D != unpack 'C', $field) && (0x0A != unpack 'C', $field) && 
          ($self->{flags}->{ignoreHeaderBytes} || $pos < $self->{nheaderbytes}))
   {
      read $self->{fh}, $field, 31, 1;
      my ($name, $type, $len, $dec) = unpack 'a11a1xxxxCC', $field;

      $name =~ s/\A(\w+).*?\z/$1/xms;
      
      push @{$self->{fields}}, {
         name => $name,
         type => $type,
         length => $len,
         decimals => $dec,
      };
      push @{$self->{columns}}, $name;

      $pos += 32;
      read $self->{fh}, $field, 1;
   }

   if ($self->{flags}->{ignoreHeaderBytes})
   {
      # replace stated header size with the actual, computed value
      my $oldvalue = $self->{nheaderbytes};
      my $newvalue = (@{$self->{fields}} + 1) * 32 + 1;
      # skip the replacement if the flags say to be lenient
      unless ($self->{flags}->{allowOffByOne} && abs($oldvalue-$newvalue) <= 1) ## no critic
      {
         $self->{nheaderbytes} = $newvalue;
         if ($self->{flags}->{verbose} && $oldvalue != $self->{nheaderbytes})
         {
            warn "Corrected header size from $oldvalue to $self->{nheaderbytes} for $self->{filename}\n";
         }
      }
   }

   $self->{packformat} = 'C';
   for my $field (@{$self->{fields}})
   {
      if ($field->{type} =~ m/\A[CLND]\z/xms)
      {
         $self->{packformat} .= 'a' . $field->{length};
      }
      else
      {
         croak 'unrecognized field type ' . $field->{type} . ' in field ' . $field->{name};
      }
   }
   seek $self->{fh}, $self->{nheaderbytes}, 0;

   return $self;
}
#----------------

=item $pkg->create($filename, [flags,] $column, $column, ...)

=item $pkg->create($filename, $filemode, [flags,] $column, $column, ...)

Create a new DBF file in C<$filename>, initially empty.  The optional
C<$filemode> argument defaults to C<w+>.  We can't think of any reason to
use any other mode, but if you can think of one, go for it.

The column structure is specified as a list of hash references, each
containing the fields: name, type, length and decimals.  The name
should be 11 characters or shorted.  The type should be one of C<C>, C<N>,
C<D>, or C<L> (for character, number, date or logical).

The optional flags are:

  -quick => 0|1 (default 0) -- skips column format checking if set

Example:

   my $dbf = CAM::DBF->create('new.dbf',
                              {name=>'id',
                               type=>'N', length=>8,  decimals=>0},
                              {name=>'lastedit',
                               type=>'D', length=>8,  decimals=>0},
                              {name=>'firstname',
                               type=>'C', length=>15, decimals=>0},
                              {name=>'lastname',
                               type=>'C', length=>20, decimals=>0},
                              );

=cut

sub create
{
   my $pkg = shift;
   my $filename = shift;

   # Optional args:
   my $quick = 0;
   my $filemode = 'w+';
   while (@_ > 0 && $_[0] && (!ref $_[0]))
   {
      if ($_[0] eq '-quick')
      {
         shift;
         $quick = shift;
      }
      elsif ($filemode_open_map{$_[0]})
      {
         $filemode = shift;
      }
      else
      {
         carp "Argument $_[0] not understood";
         return;
      }
   }

   # The rest of the args are the data structure definition
   my @columns = @_;

   # Validate the column structure
   if ($quick)
   {
      if (!$pkg->validateColumns(@columns))
      {
         return;
      }
   }

   my $self = $pkg->_init($filename, $filemode);
   return if (!$self);

   $self->{fields} = [@columns];
   $self->{columns} = map {$_->{name}} @columns;
   $self->{packformat} = 'C' . join q{}, map {'a'.$_->{length}} @columns;

   if (!$self->writeHeader())
   {
      return;
   }

   return $self;
}
#----------------

=item $pkg_or_self->validateColumns($column, $column, ...)

=item $self->validateColumns()

Check an array of DBF columns structures for validity.  Emits warnings
and returns undef on failure.

=cut

sub validateColumns
{
   my $pkg_or_self = shift;
   my @columns = @_;

   if (@columns == 0 && ref $pkg_or_self)
   {
      my $self = $pkg_or_self;
      @columns = @{$self->{fields}};
   }

   my $n_columns = 0; # used solely for error messages
   my %col_names;  # used to detect duplicate column names
   for my $column (@columns)
   {
      $n_columns++;
      if (!$column || (!ref $column) || 'HASH' ne ref $column)
      {
         carp "Column $n_columns is not a hash reference";
         return;
      }
      for my $key ('name', 'type', 'length', 'decimals')
      {
         if (!defined $column->{$key} || $column->{$key} =~ m/\A\s*\z/xms)
         {
            carp "No $key field in column $n_columns";
            return;
         }
      }
      if (11 < length $column->{name})
      {
         carp "Column name '$column->{name}' is too long (max 11 characters)";
         return;
      }
      if ($col_names{$column->{name}}++)
      {
         carp "Duplicate column name '$column->{name}'";
         return;
      }
      if ($column->{type} !~ m/\A[CNDL]\z/xms)
      {
         carp "Unknown column type '$column->{type}'";
         return;
      }
      if ($column->{length} !~ m/\A\d+\z/xms)
      {
         carp "Column length must be an integer ('$column->{length}')";
         return;
      }
      if ($column->{decimals} !~ m/\A\d+\z/xms)
      {
         carp "Column decimals must be an integer ('$column->{decimals}')";
         return;
      }
      if ($column->{type} eq 'L' && $column->{length} != 1)
      {
         carp 'Columns of type L (logical) must have length 1';
         return;
      }
      if ($column->{type} eq 'D' && $column->{length} != 8)
      {
         carp 'Columns of type D (date) must have length 8';
         return;
      }
   }
   return $pkg_or_self;
}
#----------------

=back

=head1 INSTANCE METHODS

=over 4

=cut

#----------------

=item $self->writeHeader()

Write all of the DBF header data to the file.  This truncates the file first.

=cut

sub writeHeader
{
   my $self = shift;

   my $file_handle = $self->{fh};
   my $fields = q{};
   $self->{nrecordbytes} = 1; # allow one for the delete byte

   for my $column (@{$self->{fields}})
   {
      $self->{nrecordbytes} += $column->{length};
      $fields .= pack 'a11a1CCCCCCCCCCCCCCCCCCCC',
                      $column->{name}, $column->{type}, (0) x 4,
                      $column->{length}, $column->{decimals}, (0) x 14;
   }
   $fields .= pack 'C', 0x0D;

   my $header
       = pack 'CCCCVvvCCCCCCCCCCCCCCCCCCCC',
              $self->{valid}, 
              $self->{year}%100, $self->{month}, $self->{date}, 
              $self->{nrecords}, length($fields)+32, 
              $self->{nrecordbytes}, (0)x20;

   truncate $file_handle, 0;
   print {$file_handle} $header;
   print {$file_handle} $fields;
   return $self;
}
#----------------

=item $self->appendrow_arrayref($data_arrayref)

Add a new row to the end of the DBF file immediately.  The argument
is treated as a reference of fields, in order. The DBF file is altered
as little as possible.

The record count is incremented but is NOT written to the file until
the C<closeDB()> method is called (for speed increase).

=cut

sub appendrow_arrayref
{
   my $self = shift;
   my $row  = shift;

   $self->appendrows_arrayref([$row]);
   return;
}
#----------------

=item $self->appendrows_arrayref($arrayref_data_arrayrefs)

Add new rows to the end of the DBF file immediately.  The argument
is treated as a reference of references of fields, in order. The DBF
file is altered as little as possible. The record count is incremented
but is NOT written until the C<closeDB()> method is called (for speed increase).

=cut

sub appendrows_arrayref
{
   my $self = shift;
   my $rows = shift;

   my $file_handle = $self->{fh};
   seek $file_handle, 0, 2;

   for my $row (@{$rows})
   {
      if (defined $row)
      {
         $self->{nrecords}++;
         print {$file_handle} $self->_packArrayRef($row);
      }
   }

   delete $self->{rowcache};  # wipe cache, just in case
   return;
}
#----------------

=item $self->appendrow_hashref($data_hashref)

Just like C<appendrow_arrayref()>, except the incoming data is in a
hash.  The DBF columns are used to reorder the data.  Missing values
are converted to blanks.

=cut

sub appendrow_hashref
{
   my $self = shift;
   my $row  = shift;

   $self->appendrows_hashref([$row]);
   return;
}
#----------------

=item $self->appendrows_hashref($arrayref_data_hashref)

Just like C<appendrows_arrayref()>, except the incoming data is in a
hash.  The DBF columns are used to reorder the data.  Missing values
are converted to blanks.

=cut

sub appendrows_hashref
{
   my $self = shift;
   my $hashrows = shift;

   # Convert hashes to arrays
   my @column_names = map {$_->{name}} @{$self->{fields}};
   my @arrayrows;
   for my $row (@{$hashrows})
   {
      push @arrayrows, [map {$row->{$_}} @column_names];
   }

   $self->appendrows_arrayref(\@arrayrows);
   return;
}
#----------------

sub _packArrayRef
{
   my $self = shift;
   my $A_row = shift;
   
   die 'Bad row' if (!$A_row);

   my $row = q{ };  # start with an undeleted flag
   for my $i (0 .. @{$self->{fields}}-1)
   {
      my $column = $self->{fields}->[$i];
      my $v = $A_row->[$i];

      if (defined $v)
      {
         $v = "$v"; # stringify
      }
      else
      {
         $v = q{};
      }

      my $l = length $v;
      if ($column->{type} eq 'N') ##no critic(ProhibitCascadingIfElse)
      {
         if ($v =~ m/\d/xms)
         {
            $v = sprintf "%$column->{length}.$column->{decimals}f", $v;
         }
         else
         {
            $v = q{ } x $column->{length};
         }
      }
      elsif ($column->{type} eq 'C')
      {
         $v = sprintf "%-$column->{length}s", $v;
      }
      elsif ($column->{type} eq 'L')
      {
         $v = !$v || $v =~ m/[nNfF]/xms ? 'F' : 'T';
      }
      elsif ($column->{type} eq 'D')
      {
         # pass on OK
      }
      else
      {
         die "Unknown type $column->{type}";
      }

      if ($l > $column->{length})
      {
         $v = substr $v, 0, $column->{length};
      }
      $row .= $v;
   }
   return $row;
}
#----------------

=item $self->closeDB()

Closes a DBF file after updating the record count.
This is only necessary if you append new rows.

=cut

sub closeDB
{
   my $self = shift;

   $self->writeRecordNumber();
   $self->{fh}->close();
   return $self;
}
#----------------

=item $self->writeRecordNumber()

Edits the DBF file to record the current value of nrecords().  This is
useful after appending rows.

=cut

sub writeRecordNumber
{
   my $self = shift;

   my $file_handle = $self->{fh};
   seek $file_handle, 4, 0;
   print {$file_handle} pack 'V', $self->{nrecords};
   return $self;
}
#----------------

sub _readrow
{
   my $self = shift;
   my $rownum = shift;

   if ($ROWCACHE == 0)
   {
      my $A_rows = $self->_readrows($rownum, 1);
      return $A_rows ? $A_rows->[0] : undef;
   }
   elsif ($self->{rowcache} && $rownum < $self->{rowcache2} && $rownum >= $self->{rowcache1})
   {
      return $self->{rowcache}->[$rownum - $self->{rowcache1}];
   }
   else
   {
      my $num = $ROWCACHE;
      if ($rownum + $num >= $self->{nrecords})
      {
         $num = $self->{nrecords} - $rownum;
      }
      $self->{rowcache} = $self->_readrows($rownum, $num);
      $self->{rowcache1} = $rownum;
      $self->{rowcache2} = $rownum + $num;

      return $self->{rowcache}->[0];
   }
}
#----------------

sub _readrows
{
   my $self = shift;
   my $row_start = shift;
   my $row_count = shift;

   my @data_rows;

   my $offset = $self->{nheaderbytes} + $row_start * $self->{nrecordbytes};
   seek $self->{fh}, $offset, 0;

   for (my $r=1; $r<=$row_count; $r++)
   {
      my $datarow;
      read $self->{fh}, $datarow, $self->{nrecordbytes};
      my @records = unpack $self->{packformat}, $datarow;
      my $delete = shift @records;
      if ($delete != 32) # 32 is decimal ascii for " "
      {
         # This is a deleted row
         push @data_rows, undef;
         next;
      }

      my $col = 0;
      for (@records)
      {
         my $type = $self->{fields}->[$col++]->{type};
         if ($type eq 'C')
         {
            s/[ ]*\z//xms;
         }
         elsif ($type eq 'N')
         {
            s/\A[ ]*//xms;
         }
         elsif ($type eq 'L')
         {
            tr/yYtTnNfF?/111100000/;
         }
      }
      push @data_rows, \@records;
   }

   return \@data_rows;
}
#----------------

=item $self->nfields()

Return the number of columns in the data table.

=cut

sub nfields
{
   my $self = shift;

   return scalar @{$self->{fields}};
}
#----------------

=item $self->fieldnames()

Return a list of field header names.

=cut

sub fieldnames
{
   my $self = shift;

   return @{$self->{columns}};
}

# Retrieve header metadata for the column spcified by name or number
sub _getfield
{
   my $self = shift;
   my $col = shift;

   if ($col =~ m/\D/xms)
   {
      for my $field (@{$self->{fields}})
      {
         return $field if ($field->{name} eq $col);
      }
      return;
   }
   else
   {
      return $self->{fields}->[$col];
   }
}
#----------------

=item $self->fieldname($column)

Return a the title of the specified column.  C<$column> can be a column
name or number.  Column numbers count from zero.

=cut

sub fieldname
{
   my $self = shift;
   my $col = shift;

   my $field = $self->_getfield($col);
   return if (!$field);
   return $field->{name};
}
#----------------

=item $self->fieldtype($column)

Return the dBASE field type for the specified column.  C<$column> can be a
column name or number.  Column numbers count from zero.

=cut

sub fieldtype
{
   my $self = shift;
   my $col = shift;

   my $field = $self->_getfield($col);
   return if (!$field);
   return $field->{type};
}
#----------------

=item $self->fieldlength($column)

Return the byte width for the specified column.  C<$column> can be a
column name or number.  Column numbers count from zero.

=cut

sub fieldlength
{
   my $self = shift;
   my $col = shift;

   my $field = $self->_getfield($col);
   return if (!$field);
   return $field->{length};
}
#----------------

=item $self->fielddecimals($column)

Return the decimals for the specified column.  C<$column> can be a column
name or number.  Column numbers count from zero.

=cut

sub fielddecimals
{
   my $self = shift;
   my $col = shift;

   my $field = $self->_getfield($col);
   return if (!$field);
   return $field->{decimals};
}
#----------------

=item $self->nrecords()

Return number of records in the file.

=cut

sub nrecords
{
   my $self = shift;

   return $self->{nrecords};
}
#----------------

=item $self->fetchrow_arrayref($rownumber)

Return a record as a reference to an array of fields.  Row numbers
count from zero.

=cut

sub fetchrow_arrayref
{
   my $self   = shift;
   my $rownum = shift;

   if ($rownum < 0 || $rownum >= $self->{nrecords})
   {
      carp "Invalid DBF row: $rownum";
      return;
   }

   return $self->_readrow($rownum);
}
#----------------

=item $self->fetchrows_arrayref($rownumber, $count)

Return array reference of records as a reference to an array of fields.
Row numbers start from zero and count is trimmed if it exceeds table
limits.

=cut

sub fetchrows_arrayref
{
   my $self = shift;
   my $row_start = shift;
   my $row_count = shift;

   if ($row_start + $row_count > $self->{nrecords})
   {
      $row_count = $self->{nrecords} - $row_start;
   }

   if ($row_start < 0 || $row_start >= $self->{nrecords})
   {
      if ($row_start >= $self->{nrecords})
      {
         carp "Invalid DBF row: $row_start";
      }
      return;
   }

   return $self->_readrows($row_start, $row_count);
}
#----------------

=item $self->fetchrow_hashref($rownum)

Return a record as a reference to a hash of C<(field name => field value)>
pairs.  Row numbers count from zero.

=cut

sub fetchrow_hashref
{
   my $self = shift;
   my $rownum = shift;

   my $ref = $self->fetchrow_arrayref($rownum);
   return if (!$ref);
   my %hash;
   for my $col (0 .. $#{$ref})
   {
      $hash{$self->{columns}->[$col]} = $ref->[$col];
   }
   return \%hash;
}
#----------------

=item $self->fetchrow_array($rownum)

Return a record as an array of fields.  Row numbers count from zero.

=cut

sub fetchrow_array
{
   my $self   = shift;
   my $rownum = shift;

   my $ref = $self->fetchrow_arrayref($rownum);
   return if (!$ref);
   return @{$ref};
}
#----------------

=item $self->delete($rownum);

Flags a row as deleted.  This alters the DBF file immediately.

=cut

sub delete  ##no critic(ProhibitBuiltinHomonyms)
{
   my $self   = shift;
   my $rownum = shift;

   return $self->_delete($rownum, q{*});
}
#----------------

=item $self->undelete($rownum)

Removes the deleted flag from a row.  This alters the DBF file
immediately.

=cut

sub undelete
{
   my $self   = shift;
   my $rownum = shift;

   return $self->_delete($rownum, q{ });
}

## Internal method only.  Use wrappers above.
sub _delete
{
   my $self   = shift;
   my $rownum = shift;
   my $flag   = shift;

   return if (!$rownum);
   return if ($rownum < 0 || $rownum >= $self->{nrecords});

   $self->{fh}->close();
   $self->{fh} = undef;
   
   my $fh;
   my $result;
   if (open $fh, '+<', $self->{filename})
   {
      binmode $fh;
      my $offset = $self->{nheaderbytes} + $rownum * $self->{nrecordbytes};
      seek $fh, $offset, 0;
      print {$fh} $flag;
      close $fh;
      $result = 1;
   }

   # Reopen main filehandle
   $self->_open_fh();

   delete $self->{rowcache};  # wipe cache, just in case
   return $result ? $self : ();
}
#----------------

=item $self->toText([$startrow,] [$endrow,] [C<-arg> => $value, ...])

Return the contents of the file in an ASCII character-separated
representation.  Possible arguments (with default values) are:

    -field      =>  ','
    -enclose    =>  '"'
    -escape     =>  '\'
    -record     =>  '\n'
    -showheader => 0
    -startrow   => 0
    -endrow     => nrecords()-1

Alternatively, if the C<-arg> switches are not used, the first two
arguments are interpreted as:

    $dbf->toText($startrow, $endrow)

Additional C<-arg> switches are permitted after these.  For example:

    print $dbf->toText(100, 100, -field => '\n', -record => '');
    print $dbf->toText(300, -field => '|');

=cut

sub toText
{
   my $self = shift;

   my %args = (
               field => q{,},
               enclose => q{'},
               escape => q{\\},
               record => "\n",
               showheader => 0,
               startrow => 0,
               endrow => $self->nrecords()-1,
               );

   for my $arg (qw(startrow endrow))
   {
      if (@_ > 0 && $_[0] !~ m/\A\-/xms)
      {
         $args{$arg} = shift;
      }
   }

   while (@_ > 0)
   {
      my $key = shift;
      if ($key =~ m/\A\-(\w+)\z/xms && exists $args{$1} && @_ > 0)
      {
         $args{$1} = shift;
      }
      else
      {
         carp "Unexpected tag '$key' in argument list";
         return;
      }
   }

   if ($args{startrow} < 0 || $args{endrow} >= $self->nrecords())
   {
      carp 'Invalid start and/or end row';
      return;
   }
   return if ($args{startrow} > $args{endrow});

   my $out = q{};
   if ($args{showheader}) {
      my @names = map {$args{enclose} eq q{} && $args{escape} eq q{} ?
                       $_ : _escape($_, $args{enclose}, $args{escape})} $self->fieldnames();
      $out .= join $args{field}, @names; 
      $out .= $args{record};
   }
   for (my $row = $args{startrow}; $row <= $args{endrow}; $row++)
   {
      my $aref = $self->_readrow($row);
      next if (!$aref);
      if ($args{enclose} ne q{} || $args{escape} ne q{})
      {
         for (@{$aref})
         {
            $_ = _escape($_, $args{enclose}, $args{escape});
         }
      }
      $out .= join($args{field}, @{$aref}) . $args{record};
   }
   return $out;
}
#----------------

=item $self->computeRecordBytes()

Useful primarily for debugging.  Recompute the number of bytes needed
to store a record.

=cut

sub computeRecordBytes
{
   my $self = shift;

   my $length = 1;
   for my $column (@{$self->{fields}})
   {
      $length += $column->{length};
   }
   return $length;
}
#----------------

=item $self->computeHeaderBytes()

Useful primarily for debugging.  Recompute the number of bytes needed
to store the header.

=cut

sub computeHeaderBytes
{
   my $self = shift;

   my $fh = $self->{fh};
   my $length = 0;
   my ($buffer, $value);
   do
   {
      $length += 32;
      seek $fh, $length, 0;
      read $fh, $buffer, 1;
      $value = unpack 'C', $buffer;
   }
   while (defined $buffer && $value != 0x0D && $value != 0x0A); ##no critic(ProhibitPostfixControls)
   return $length + 1; # Add one for the terminator character
}
#----------------

=item $self->computeNumRecords()

Useful primarily for debugging.  Recompute the number of records in
the file, given the header size, file size and bytes needed to store a
record.

=cut

sub computeNumRecords
{
   my $self = shift;

   my $size = -s $self->{filename};
   my $num = ($size - $self->nHeaderBytes()) / $self->nRecordBytes();
   return int $num
}
#----------------

=item $self->nHeaderBytes()

Useful primarily for debugging.  Returns the number of bytes for the
file header.  This date is read from the header itself, not computed.

=cut

sub nHeaderBytes
{
   my $self = shift;
   return $self->{nheaderbytes};
}
#----------------

=item $self->nRecordBytes()

Useful primarily for debugging.  Returns the number of bytes for a
record.  This date is read from the header itself, not computed.

=cut

sub nRecordBytes
{
   my $self = shift;
   return $self->{nrecordbytes};
}
#----------------

=item $self->repairHeaderData()

Test and fix corruption of the C<nrecords> and C<nrecordbytes> header
fields.  This does NOT alter the file, just the in-memory
representation of the header metadata.  Returns a boolean indicating
whether header repairs were necessary.

=cut

sub repairHeaderData
{
   my $self = shift;

   my $repairs = 0;

   my $row_size = $self->computeRecordBytes();
   if ($self->nRecordBytes() != $row_size)
   {
      $repairs++;
      $self->{nrecordbytes} = $row_size;
   }

   my $n_records = $self->computeNumRecords();
   if ($n_records != $self->nrecords())
   {
      $repairs++;
      $self->{nrecords} = $n_records;
   }

   return $repairs;
}
#----------------

# Internal function
sub _escape
{
   my $string = shift;
   my $enclose = shift;
   my $escape = shift;

   if ($escape ne q{})
   {
      $string =~ s/\Q$escape\E/$escape$escape/gxms;
      if ($enclose ne q{})
      {
         $string =~ s/\Q$enclose\E/$escape$enclose/gxms;
      }
   }
   return $enclose . $string . $enclose;
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=cut
