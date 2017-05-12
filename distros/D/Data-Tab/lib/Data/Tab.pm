package Data::Tab;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

=head1 NAME

Data::Tab - Iterators as tabular data structures

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

C<Data::Tab> is inspired by L<Data::Table>, in that the central data
structure is a two-dimensional matrix of data values with named headers.
However, there are some significant differences, chief of which is that the data sources
can be lazily evaluated, that is, they can be either iterators or static arrays.

BE WARNED: this module defines a lot of API that isn't actually implemented yet.
It is a work in slow progress.  (By "slow" I mean I need something every year or so and put it in.)

=head1 METHODS

=head2 new (data, [headers], [types], [rowheaders], [underlying])

Creates a new table, with data being either an arrayref of arrayrefs, or a coderef that should iterate a series of arrayrefs,
or an arrayref of arrayrefs with a terminal coderef.  Case 1 is a set of static data.  Case 2 is an unbuffered iterator; it
cannot be rewound, just read.  Finally, Case 3 is a buffered iterator; during a read series the arrayref rows will be returned
until the coderef is encountered, after which the coderef will be asked for more rows, which will be inserted into the buffer,
until there are no more rows and the table is left as a static dataset.

The headers are an optional arrayref of strings to be used as the column names.

The types are an optional arrayref of (advisory) types to be used for formatting the data, or a single scalar indicating
the datatype for I<all> the elements in the table.

The rowheaders are either an arrayref of names for each row (primarily useful for static datasets, obviously) or a coderef
for generating a name based on the data in the row. Rowheaders are not yet implemented.

The "underlying" parameter is an object inheriting from <Data::Tab::Underlying> that is responsible for passing
changes to the data table through to the underlying object, if this is applicable.  This makes the data table a live view.
It's not yet implemented.

=cut

sub new {
    my $class = shift;
    my $self = {
        data => shift,   # The buffered data, if any
        more => undef,   # The iterator, if any
        headers => shift,
        types => shift,
        rowheaders => shift,
        underlying => shift,
        buffer => undef, # 0 if we don't want to keep a buffer
        cursor => 0,
    };
    
    if (ref $self->{data} eq 'CODE') {
       $self->{more} = $self->{data};
       $self->{data} = undef;
    } elsif (ref $self->{data} eq 'ARRAY') {
       # TODO: split out the iterator now, if there is one.
    } else {
       # TODO: consider other handy ways of wrapping these.
       croak "invalid data type creating $class instance";
    }
    
    bless ($self, $class);
}

=head2 query (dbh, sql, [parameters])

If you have DBI installed - and who doesn't? - then you can query the database with this function in a single step and have a
lazy table returned.  Clearly, if you don't have DBI installed, you can't have a dbh handle, so no error checking is done.

At some point there will be an underlying class for SQL that will allow changes made to the lazy table to be reflected in the
database, but that's a fight for another day.

By default, an SQL query is unbuffered, a pure iterator.  Use query()->buffer() to turn the buffer on before retrieval if that's
what you want.

Suggested usage:

   my $query = Data::Tab->query($dbh, "select * from my_table where name like ?", '%this%');
   while ($query->get) {
      my ($col1, $col2) = @$_;
      ...
   }
   
Or this:

   print Data::Tab->query($dbh, "select * from my table where customer=?", $customer)->read->show;
   
Magic SQL query formatting!

=cut

sub query {
    my $class = shift;
    my $dbh = shift;
    my $sql = shift;
   
    my $sth = $dbh->prepare ($sql) || croak $dbh->errstr();
    $sth->execute(@_);
    
    my $self = {
        data => undef,  # no buffer by default
        more => sub {  $sth->fetchrow_arrayref },
        headers => $sth->{NAME_lc},
        types => undef, # TODO: later
        rowheaders => undef,
        underlying => undef,
        buffer => 0, # 0 if we don't want to keep a buffer
        cursor => 0,
    };
    
    bless ($self, $class);
}

=head2 buffer, unbuffer

Switches the table from buffered mode to unbuffered mode, or vice versa.  If a table is currently buffered, the buffer is
discarded when unbuffering.  Switching from buffered to unbuffered and back again is a good way to free up memory for longer
queries that still need buffering.

The buffer can also be set to a given number of rows with e.g. C<buffer(5)>.  Then any incoming rows will discard old rows
from the beginning of the buffer.  A call to C<buffer(0)> is equivalent to C<unbuffer()>.

=cut

sub buffer {
   my $self = shift;
   $self->{buffer} = shift;
   $self->{data} = [] unless defined $self->{data};
   return unless defined $self->{buffer};
   if ($self->{buffer} == 0) {
      $self->{data} = undef;
      return;
   }
   shift @{$self->{data}} while scalar @{$self->{data}} > $self->{buffer};
}
sub unbuffer { shift->buffer(0); }

=head2 headers, rowheaders, types, header(n), rowheader(n), type(n)

Getter/setter functions for the various parameters of the table.  That is, C<header(n)> will retrieve the header for the
n-th row, while C<header(n, 'new header')> will set it.  Similarly, C<types(0,0,' ')> will set the scalar type array
for all rows.

Returns a list in list context, an arrayref in scalar context.

Of these, only C<headers> is implemented.

=cut

sub headers {
   my $self = shift;
   if (@_) {
      my @headers = ();
      push @headers, @_;
      $self->{headers} = \@headers;
   }
   return unless defined wantarray;
   my @return = @{$self->{headers} || []};
   return @return if wantarray;
   return \@return;
}
sub rowheaders {
}
sub types {
}

sub header {
}
sub rowheader {
}
sub type {
}

=head2 dimensions (not yet implemented)

Another getter/setter.  So C<dimensions()> will retrieve the current dimensions of the buffered or static data,
C<dimensions(10)> will discard rows numbered 10 and up, C<dimensions(0)> is a way to truncate the buffer,
C<dimensions(undef,5)> will discard columns numbered 5 and up, and C<dimensions(5, 5)> will force the dimensions
of the table to be 5x5.  If the data is currently smaller in a dimension specified, then "blank" data will be filled
in; the "blank" value is the type value of the column, or C<undef>.

=cut

sub dimensions {
}

=head2 truncate

If there is a coderef at the end of the data, removes it.  This converts an iterated, buffered data table into a
static one.  Used on an unbuffered iterator, renders the table useless.

=cut

sub truncate { shift->{more} = undef; }

=head2 reiterate

Tacks a new iterator on the end of a static table, converting it into an iterated table.

=cut

sub reiterate { shift->{more} = shift; }

=head2 get, rewind

The table has a cursor row that starts at 0.  The C<rewind> function resets that row to 0 if it's been changed.
The C<get()> function with no parameters gets the cursor row and advances the cursor.  If there's no buffer, it
just gets the next row from the iterator; if there is a buffer, then the cursor advances along the buffer until
it gets to the iterator (if there is one) and then returns/buffers rows as it goes.

However, C<get(1)> will get row 1 in the buffer as an arrayref, and C<get(1, 3)> will get the value from row 1,
column 3 in the buffer.  A call with an C<undef> row (e.g. C<get(undef, 2)>) will get the numbered column.

A call to C<get(undef, 'taxes')> will get the column headed taxes, as an arrayref, while C<get('taxes')> will get the
I<row> labeled 'taxes', if the rowheaders are defined and there is such a row.  If these fail, the call will croak.
There is no column cursor, so there is no need for syntax for a columnar get with unspecified column.

The return value is always a scalar or arrayref.

=cut

sub get {
    my $self = shift;
    my $row  = shift;
    my $col  = shift;
    
    if (not defined $self->{data}) {
       return undef unless defined $self->{more};
       my $ret = $self->{more}->($self);
       $self->{more} = undef unless defined $ret;
       return undef unless defined $ret;
       return ref $ret? $ret : [$ret];
    }
    
    if (not defined $row and not defined $col) {
       $row = $self->{cursor};
       $self->{cursor} += 1;
    }
    
    if (defined $row) {
        # TODO: ignoring dimensions for the moment.
        my $therow = $self->{data}->[$row];
        if (not defined $therow and $self->{more}) {
           my $bufsize = scalar @{$self->{data}};
           while ($bufsize < $row+1) {
              $bufsize += 1;
              $therow = $self->{more}->($self);
              if (not defined $therow) {
                 $self->{more} = undef;
                 return undef;
              }
              my @values = ref $therow ? @$therow : ($therow);
              $therow = \@values;  # Have to take a copy, not reuse the same arrayref.
              push @{$self->{data}}, $therow;
              shift @{$self->{data}} while defined $self->{buffer} and scalar @{$self->{data}} > $self->{buffer};
           }
        }
           
        return $therow unless defined $col;
        return undef unless defined $therow;
        return $therow->[$col];
    }
    if (defined $col) {
       my @values;
       foreach my $r (@{$self->{data}}) {
          push @values, $r->[$col];
       }
       return \@values;
    }
}

sub rewind { shift->{cursor} = 0; }

=head2 read (limit)

The C<read> method, called on a buffered table with an iterator, reads the entire iterated query result list
into the buffer, then truncates the table to render it static.  Pass a number to limit the read.

If the table is unbuffered, read turns on buffering before it starts retrieval.

=cut

sub read {
   my ($self, $limit) = @_;
   $self->buffer;
   while ($self->get()) {
      if (defined $limit) {
         $limit -= 1;
         last unless $limit > 0;
      }
   }
   $self;
}

=head2 set, setrow, setcol (not yet implemented)

A call to C<setrow (row, [values])> sets an entire row in the table, while a single element can be set with 
C<set (row, col, value)>.  To set a column, use C<setcol (col, [values])> on a buffered or static table.
As usual, row and col can be numbers or labels.

If an C<underlying> is defined for the table, then it will be notified of the change and can take appropriate 
action to update the table's underlying object.

=cut

sub set {
}
sub setrow {
}
sub setcol {
}

=head2 show, show_generic

Calling C<show> returns the table as text, with C<+-----+> type delineation.  (This method only works if
Text::Table is installed.)  This only shows the rows actually in the buffer; it will not retrieve iterator
rows; this allows you to set up a paged display.

The column delimiters only appear for a table with headers; this is because Text::Table is easier to
use this way - but think of a table with headers as a database table, and one without as a simple
matrix.

The C<show> method is actually implemented using C<show_generic>, which takes as parameters the separator, a flag
whether the headers should be shown (if the 'flag' is an arrayref, you can simply specify your own headers here),
and a flag whether a rule should be shown at the top and bottom of the table and between the header and body - by 
default, this rule is of the form +----+----+, but again, the 'flag' can be an arrayref of any two other characters
to be used instead (in the order '-' and '+' in the example).

The C<show> method is thus C<show_generic('|', 1, 1)>.

Unfortunately, C<show_generic> isn't generic enough to express an HTML table, and I considered putting a show_html
method here as well (L<Data::Table> has one) - but honestly, it's rare to use undecorated HTML these days, so I
elected to remove temptation from your path.  To generate HTML, you should use a template engine to generate
I<good> HTML.  Eventually I'll write one that works with Data::Tab out of the box - drop me a line if you'd like me
to accelerate that.

=cut

sub show { shift->show_generic ('|', 1, 1); }
sub show_generic {
   eval { require Text::Table; };
   croak "Text::Table not installed" if $@;

   my $self = shift;
   return '' unless defined $self->{data};
   my $sep = shift;
   my $headers = shift;
   my $rule = shift;
   
   my @headers = ();
   if ($headers) {
      if (ref $headers eq 'ARRAY') {
         @headers = @$headers;
      } else {
         @headers = $self->headers;
      }
   }
   my @c = ();
   if (defined $sep and @headers) {
      push @c, \$sep if defined $sep;
      foreach my $h (@headers) {
         push @c, $h, \$sep;
      }
   }
   my $t = Text::Table->new($sep ? @c : @headers);
   $t->load (@{$self->{data}});
   
   my @rule_p = ('-', '+');
   @rule_p = @$rule if $rule and ref $rule eq 'ARRAY';
   my $rule_text = '';
   $rule_text = $t->rule(@rule_p) if @headers and $rule;

   my $text = '';
   $text .= $rule_text;
   $text .= $t->title() if @headers;
   $text .= $rule_text;
   $text .= $t->body();
   $text .= $rule_text;
   return $text;
}

=head2 report (not yet implemented)

The C<report> method is a little different from C<show> - it's essentially good for formatting things with a sprintf
and suppressing repeat values, making it useful for simple presentation of things like dated entries (the date appears
only when it changes).  I use this kind of thing a lot in my everyday utilities, so it's convenient to bundle it
here in generalized form.

=cut

sub report {
}

=head2 add, glue, insert (not yet implemented)

On the other hand, maybe you just want to append one or more rows.  To do that, just C<add (arrayref)> to add
a single row, or C<add (table object)> to append all the rows from another table object.  The second parameter,
if provided, is the header for the new row.

To do the same thing on the column dimension, use C<glue (arrayref)> to tack a new column onto the left of the
table, or C<glue (table object)> to glue all the columns of a table onto the left.  To insert the columns somewhere
other than the left, use C<insert (column, table object or arrayref)> and they'll be inserted to the right of
the column with that number.  Or, if the column isn't a number, then the column headers will be used.

If C<add> or C<glue> is passed a coderef, then the new row will be made by repeated calls to the coderef, each
call passing the table and the column for arbitrary calculation.  (Or the new column will be made with each row.)

=cut

sub add {
}
sub glue {
}
sub insert {
}

=head2 copy (not yet implemented)

The C<copy> method copies an entire table's contents into a segment of the current table.  We specify the upper
left corner of the target, so to copy the contents without further ado, simply C<copy(0, 0, source)>.  The
dimensions of the target will be expanded to match.  This doesn't affect the headers.

=cut

sub copy {
}

=head2 slice (row, rows, col, cols) (not yet implemented)

The C<slice> method is used to extract sections from a table to make a new table object.  For example,
C<slice<2, 2, 2, 2> slices out a two-by-two chunk from row/column 2,2.  (0-indexed).
C<slice('total', 1)> slices out the "total" row only.

The return is always a new table object.

=cut

sub slice {
}

=head2 crop (row, rows, col, cols) (not yet implemented)

Does the same as C<slice>, but destructively in place.

=cut

sub crop {
}

=head2 sort (function), sortcols (not yet implemented)

Returns a sorting array for the entire table (if buffered, just the part in the buffer) that is produced
by applying the coderef C<function> to an array [0, 1, 2, ... n].  The C<sort> method does this for the 
rows, with C<sortcols> doing the same for the columns.

=cut

sub sort {
}
sub sortcols {
}

=head2 shuffle, shufflecols (not yet implemented)

Given an array of row numbers, builds a new table with those rows.  (Or, column numbers for columns for C<shufflecols>.)
Yes, you can just pass sort's return into shuffle to produce a sorted array - but you don't I<have> to.
If there are row/column numbers missing, then those rows/columns won't appear in the new table.  Finally, all header,
type, and rowheader data will be shuffled appropriately as well.

=cut

sub shuffle {
}
sub shufflecols {
}

=head2 filter (function), filtercols (not yet implemented)

Returns an array of rows (or columns) that return a positive result from a coderef.  Again, this can then be used with
shuffle or shufflecols to produce a new array.

=cut

sub filter {
}
sub filtercols {
}

=head2 flip (not yet implemented)

Flips the entire array rows for columns.  If there was a coderef iterator after the last row, it is discarded.  (That is,
the table is truncated first.)

If there's an underlying object, the link will be broken.  If you really want to flip the underlying object, say you want
to flip a section of an Excel spreadsheet, then read it in, flip the array, and write out a new sheet segment - which is
probably going to be messy unless the section was square to start with.  In the case of an SQL database, what does flipping
even mean?  Probably nothing.  You probably want to rethink your strategy.

=cut

sub flip {
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Data-Tab at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Tab>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 Data::Tab::db

Just for simplicity's sake (and to save typing) we also provide a simple wrapper for the DBI class that allows us to say:

   use Data::Tab::db;
   
   my $db = Data::Tab::db->connect (my connection parameters)
   $db->query("select * from my_table")->read->show;
   
Done.

=cut

package Data::Tab::db;

use Data::Tab;
use Carp;

sub connect {
   my $self = bless ({}, shift);
   eval "use DBI";
   croak "DBI not installed" if $@;
   $self->{dbh} = DBI->connect(@_);
   $self;
}

sub query {
   my $self = shift;
   Data::Tab->query($self->{dbh}, @_);
}

sub dbh { shift->{dbh}; }


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Tab


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Tab>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Tab>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Tab>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Tab/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::Tab
