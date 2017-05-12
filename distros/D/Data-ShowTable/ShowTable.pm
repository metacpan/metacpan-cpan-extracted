# perl -w
# ShowTable.pm
#
#    Copyright (C) 1996-2013 Alan K. Stebbens <aks@stebbens.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

package Data::ShowTable;

$VERSION = '4.6';

=head1 NAME

B<ShowTable> - routines to display tabular data in several formats.

=head1 USAGE

C<use Data::ShowTable;>

B<ShowTable> { I<parameter> => I<value>, ... };

B<ShowTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub> ];


B<ShowDatabases> I<\@dbnames>;

B<ShowDatabases> { I<parameter> => I<value>, ... };


B<ShowTables> I<\@tblnames>;

B<ShowTables> { I<parameter> => I<value>, ... };


B<ShowColumns> I<\@columns>, I<\@col_types>, I<\@col_lengths>, I<\@col_attrs>;

B<ShowColumns> { I<parameter> => I<value>, ... };


B<ShowBoxTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub> ];

B<ShowBoxTable> { I<parameter> => I<value>, ... };


B<ShowSimpleTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub>];

B<ShowSimpleTable> { I<parameter> => I<value>, ... };


B<ShowHTMLTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub>];

B<ShowHTMLTable> { I<parameter> => I<value>, ... };


B<ShowListTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub>];

B<ShowListTable> { I<parameter> => I<value>, ... };

C<package Data::ShowTable>;

B<$Show_Mode> = 'I<mode>';

B<$Max_Table_Width> = I<number>;

B<$Max_List_Width> = I<number>;

B<$No_Escape> = I<flag>;

B<%URL_Keys> = { "I<$colname>" => "I<$col_URL>", ... };

B<@Title_Formats> = ( I<fmt1_html>, <fmt2_html>, ... );

B<@Data_Formats> = ( I<fmt1_html>, <fmt2_html>, ... );

B<ShowRow> I<$rewindflag>, I<\$index>, I<$col_array_1> [, I<$col_array_2>, ...;]

I<$fmt> = B<ShowTableValue> I<$value>, I<$type>, I<$max_width>, I<$width>, I<$precision>, I<$showmode>;

[I<$plaintext> = ] B<PlainText> [I<$htmltext>];

=head1 DESCRIPTION

The B<ShowTable> module provides subroutines to display tabular data,
typially from a database, in nicely formatted columns, in several formats.
Its arguments can either be given in a fixed order, or, as
a single, anonymous hash-array.

The output format for any one invocation can be one of four possible styles:

=over 10

=item Box

A tabular format, with the column titles and the entire table surrounded by a
"box" of "C<+>", "C<->", and "C<|>" characters.  See L<"ShowBoxTable"> for details.

=item Table

A simple tabular format, with columns automatically aligned, with column titles.
See L<"ShowSimpleTable">.

=item List

A I<list> style, where columns of data are listed as a I<name>:I<value> pair, one
pair per line, with rows being one or more column values, separated by an empty line.
See L<"ShowListTable">.

=item HTML

The data is output as an HTML I<TABLE>, suitable for display through a I<Web>-client.
See L<"ShowHTMLTable">.  Input can either be plain ASCII text, or text
with embedded HTML elements, depending upon an argument or global parameter.

=back

The subroutines which perform these displays are listed below.

=head1 EXPORTED NAMES

This module exports the following subroutines: 

 ShowDatabases    - show list of databases
 ShowTables       - show list of tables
 ShowColumns      - show table of column info
 ShowTable        - show a table of data
 ShowRow          - show a row from one or more columns
 ShowTableValue   - show a single column's value
 ShowBoxTable     - show a table of data in a box
 ShowListTable    - show a table of data in a list
 ShowSimpleTable  - show a table of data in a simple table
 ShowHTMLTable    - show a table of data using HTML
 PlainText	  - convert HTML text into plain text

All of these subroutines, and others, are described in detail in the
following sections.

=cut

use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw(   ShowDatabases 
                ShowTables 
                ShowColumns 
                ShowTable 
                ShowRow 
                ShowBoxTable 
                ShowHTMLTable 
                ShowListTable
                ShowSimpleTable 
		ShowTableValue
                Show_Mode
		PlainText
                URL_Keys 
            );

@EXPORT_OK = qw( Show_Mode
		 URL_Keys
		 Title_Formats
		 Data_Formats
		);

# Some control variables -- the user may set these

$Show_Mode        = 'Box';      # one of: List, Table, Box, or HTML
$List_Wrap_Margin = 10;         # break words up to this long
$Max_Table_Width  = '';         # if defined, scale tables
$Max_List_Width   = $ENV{'COLUMNS'} || 80;
$No_Escape        = '';		# escape by default

%URL_Keys = ();
@Title_Formats	  = ();		# formats for HTML formatting
@Data_Formats	  = ();

use Carp;

unshift(@INC, '.');

sub ShowDatabases;
sub ShowTables;
sub ShowColumns;
sub ShowTable;
sub ShowRow;
sub PlainText;
sub htmltext;

sub get_params;
sub html_formats;
sub center;
sub max_length;
sub max;
sub out;
sub put;

=head1 MODULES

=head1 ShowTable 

Format and display the contents of one or more rows of data.

S<  >B<ShowTable> { I<parameter> => I<value>, ... };

S<  >B<ShowTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> 
[, I<\&fmt_sub> [, I<$max_width> ] [, I<$show_mode> ] ];

The B<ShowTable> subroutine displays tabular data aligned in columns,
with headers.  B<ShowTable> supports four I<modes> of display: B<Box>, B<Table>,
B<List>, and B<HTML>.  Each mode is described separately below.

The arguments to B<ShowTable> may be given in one of two ways: as a
hashed-array, or by a combination of fixed order arguments, and some
package-global variable settings.  The hash-array parameters correspond
to the fixed arguments and the global-parameter settings.

In the list below, both the hash-array parameter name and the
fixed-order argument name is given as the value.  In the case where
there is no fixed-order argument for a given parameter-value pair, then
the corresponding global variable name is given.

=over 10

=item C<titles> => I<\@titles>

A reference to an array of column names, or titles.  If a particular column name
is null, then the string C<Field_I<num>> is used by default.  To have a column
have no title, use the empty string.

=item C<types> => I<\@types>

A reference to an array of types, one for each column.  These types are
passed to the I<fmt_sub> for appropriate formatting.  Also, if a column
type matches the regexp "C</text|char|string/i>", then the column
alignment will be left-justified, otherwise it will be right-justified.

=item C<widths> => I<\@widths>

A reference to an array of column widths, which may be given as an integer, or
as a string of the form: "I<width>.I<precision>".

=item C<row_sub> => I<\&row_sub>

A reference to a subroutine which successively returns rows of values in an array.
It is called for two purposes, each described separately:

* To fetch successive rows of data:

    @row = &$row_sub(0);

When given a null, zero, or empty argument, the next row is returned.

* To initialize or rewind the data traversal.

    $rewindable = &$row_sub(1);

When invoked with a non-null argument, the subroutine should rewind its
row pointer to start at the first row of data.  If the data which
I<row_sub> is traversing is not rewindable, it must return zero or null.
If the data is rewindable, a non-null, non-zero value should be returned.

The I<row_sub> must expect to be invoked once with a non-null argument,
in order to discover whether or not the data is rewindable.  If the data
cannot be rewound, I<row_sub> will thereafter only be called with a zero
argument. 

Specifically, I<row_sub> subroutine is used in this manner:

    $rewindable = &$row_sub(1);
    if ($rewindable) {
        while ((@row = &$row_sub(0)), $#row >= 0) {
            # examine lengths for optimal formatting
        }
        &$row_sub(1);   # rewind
    }
    while ((@row = &$row_sub(0)), $#row >= 0) {
        # format the data
    }

The consequence of data that is not rewindable, a reasonably nice table
will still be formatted, but it may contain fairly large amounts of
whitespace for wide columns.

=item C<fmtsub> => I<\&fmt_sub>

A reference to a subroutine which formats a value, according to its
type, width, precision, and the current column width.  It is invoked
either with a fixed list of arguments, or with a hash-array of parameter
and value pairs.

  $string = &fmt_sub { I<parameter> => I<value>, ... };

  $string = &fmt_sub($value, $type, $max_width, $width, $precision)

If I<\&fmt_sub> is omitted, then a default subroutine, B<ShowTableValue>, 
will be used, which will use Perl's standard string formatting rules.

The arguments to I<\&fmt_sub>, either as values passed in a fixed
order, or as part of the parameter value pair, are described in the
section on L<"ShowTableValue> below.

=item C<max_width> => I<number>,

The maximum table width, including the table formatting characters.  If
not given, defaults to the global variable B<$Max_Table_Width>;

=item C<show_mode> => 'I<mode>',

The display mode of the output.  One of five strings: C<'Box'>,
C<'Table'>, C<'Simple'>, C<'List'>, and C<'HTML'>.

=back

=cut

sub ShowTable {
    my @argv = @_;
    local ($_,$titles,$types,$widths,$row_sub,$fmt_sub,
    	   $max_width, $show_mode, $wrap_margin, $url_keys,
	   $no_escape, $title_formats, $data_formats);
    my $args = 
    	get_params \@argv, 
	{   titles        => \$titles,     
	    types	  => \$types,
	    widths        => \$widths,
	    row_sub       => \$row_sub,
	    fmt_sub       => \$fmt_sub,
	    max_width     => \$max_width,
	    show_mode     => \$show_mode,
	},
	[qw(titles types widths row_sub fmt_sub max_width show_mode)];

    # Default mode is from $Show_Mode global
    $show_mode = $args->{'show_mode'} = $Show_Mode unless $show_mode ne '';
    $_ = $show_mode;
    if    (/List/i)     { &ShowListTable($args); }
    elsif (/HTML/i)     { &ShowHTMLTable($args); }
    elsif (/Table/i)    { &ShowSimpleTable($args);  }
    else                { &ShowBoxTable($args); }
}

=head1 ShowDatabases 

Show a list of database names.

S<  >B<ShowDatabases> I<\@dbnames>;

S<  >B<ShowDatabases> { 'data' => I<\@dbnames>, I<parameter> =>
I<value>, ...};

B<ShowDatabases> is intended to be used to display a list of database
names, under the column heading of "Databases".  It is a special case
usage of B<ShowTable> (and can thus be passed any parameter suitable 
for B<ShowTable>.

The argument, I<\@dbnames>, is a reference to an array of strings, used
as the values of the single column display.

=cut

sub ShowDatabases {
    my @argv = @_;
    local $databases;
    my $args = get_params \@argv, {data => \$databases}, ['data'];
    $databases ne '' or croak "Missing array of databases.\n";

    $args->{'titles'}	= 'Databases' unless exists $args->{'titles'};
    $args->{'types'}	= [ 'char' ];
    $args->{'width'}	= max_length $databases;
    $args->{'lengths'}	= $args->{'width'};
    local( $current_row ) = 0;
    $args->{'row_sub'}	= sub { &ShowRow( $_[0], \$current_row, $databases ); };
    ShowTable $args;
}

=head1 ShowTables 

Show an array of table names.

S<  >B<ShowTables> I<\@tblnames>;

S<  >B<ShowTables> { 'data' => I<\@tblnames>, I<parameter> => I<value>, ...};

B<ShowTables> is used to display a list of table names, under the column
heading of "Tables".  It is a special case usage of B<ShowTable>, and can
be passed any L<"ShowTable"> argument parameter.

=cut

sub ShowTables {
    my @argv = @_;
    local $tables;
    my $args = get_params \@argv, {data => \$tables}, ['data'];
    $tables ne '' or croak "Missing array of tables.\n";

    $args->{'titles'}	= 'Tables' unless exists $args->{'titles'};
    $args->{'types'}	= 'char';
    $args->{'width'}	= max_length $tables;
    $args->{'lengths'}	= $args->{'width'};
    local( $current_row ) = 0;
    $args->{'row_sub'}	= sub { &ShowRow( $_[0], \$current_row, $tables ); };
    ShowTable $args;
}

=head1 ShowColumns 

Display a table of column names, types, and attributes.

S<  >B<ShowColumns> { I<parameter> => I<values>, ... };

S<  >B<ShowColumns> I<\@columns>, I<\@col_types>, I<\@col_lengths>, I<\@col_attrs>;

The B<ShowColumns> subroutine displays a table of column names, types, lengths,
and other attributes in a nicely formatted table.  It is a special case usage
of B<ShowTable>, and can be passed any argument suitable for L<"ShowTable">;

The arguments are:

=over 10

=item C<columns> = I<\@columns>

An array of column names.  This provides the value for the first column
of the output.

=item C<col_types> = I<\@col_types>

An array of column types names.  This provides the value for the second
column. 

=item C<col_lengths> = I<\@col_lengths>

An array of maximum lengths for corresponding columns.  This provides
the value for the third column of the output.

=item C<col_attrs> = I<\@col_attrs>

An array of column attributes array references (ie: an array of arrays).
The attributes array for the first column are at "I<$col_attrs>-\>[0]".
The first attribute of the second column is "I<$col_attrs>-\>[1][0]".

=back

The columns, types, lengths, and attributes are displayed in a table
with the column headings: "Column", "Type", "Length", and "Attributes".
This is a special case usage of B<ShowTable>, and can be passed
additional arguments suitable for L<"ShowTable">.

=cut

sub ShowColumns {
    my @argv = @_;
    local ($col_names, $col_types, $col_lengths, $col_attributes);
    my $args = 
	get_params 
	    \@argv, 
	    { col_names	     => \$col_names,
	      col_types	     => \$col_types,
	      col_lengths    => \$col_lengths,
	      col_attributes => \$col_attributes,
	    },[qw(col_names col_types col_lengths col_attributes)];

    $col_names ne ''      or croak "Missing array of column names.\n";
    $col_types ne ''      or croak "Missing array of column types.\n";
    $col_lengths ne ''    or croak "Missing array of column lengths.\n";
    $col_attributes ne '' or croak "Missing array of column attributes.\n";

    # setup the descriptor arrays
    $args->{'titles'} = [ qw(Column Type Length Attributes) ];
    $args->{'types'}  = [ qw(varchar varchar int varchar) ];

    # Do some data conversions before displaying
    # Convert attribute array to a string of attributes
    local @col_attrs = ();
    my $i;
    for ($i = 0; $i <= $#{$col_attributes}; $i++) {
	$col_attrs[$i] = join(', ',@{$col_attributes->[$i]});
    }

    # count the widths, to setup the Column name column width
    $args->{'lengths'} = [ (max_length $col_names),   (max_length $col_types), 
		           (max_length $col_lengths), (max_length \@col_attrs) ];

    local($current_row) = 0;
    $args->{'row_sub'} = sub { &ShowRow($_[0], \$current_row, $col_names, 
    				   $col_types, $col_lengths, \@col_attrs); };

    # Finally, show the darn thing
    ShowTable $args;
}


=head1 ShowBoxTable 

Show tabular data in a box.

S<  >B<ShowBoxTable> { I<parameter> = I<value>, ... };

S<  >B<ShowBoxTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub>
S<      >[, [ I<\&fmt_sub> ] [, I<$max_width> ] ];

The B<ShowBoxTable> displays tabular data in titled columns using a "box" 
of ASCII graphics, looking something like this:
 

	+------------+----------+-----+----------+ 
	| Column1    | Column2  | ... | ColumnN  |
	+------------+----------+-----+----------+
	| Value11    | Value12  | ... | Value 1M |
	| Value21    | Value22  | ... | Value 2M |
	| Value31    | Value32  | ... | Value 3M |
	|  ...       |  ...     | ... |  ...     |
	| ValueN1    | ValueN2  | ... | Value NM |
	+------------+----------+-----+----------+


The arguments are the same as with L<"ShowTable">.  If the I<@titles> array
is empty, the header row is omitted.

=cut

sub ShowBoxTable {
    my @argv = @_;
    local ($titles, $types, $col_widths, $row_sub, $fmt_sub, $max_width);
    my $args = 
	get_params 
	    \@argv, 
	    { titles	=> \$titles,
	      types	=> \$types, 
	      widths	=> \$col_widths,
	      row_sub   => \$row_sub, 
	      fmtsub	=> \$fmt_sub,
	      max_width => \$max_width,
	    },
	    [qw(titles types widths row_sub fmtsub max_width)];

    $titles      ne ''  or croak "Missing column names array.\n";
    $types       ne ''  or croak "Missing column types array.\n";
    $col_widths  ne ''  or croak "Missing column width array.\n";
    $row_sub     ne ''  or croak "Missing row subroutine.\n";
    $fmt_sub   = \&ShowTableValue if !defined($fmt_sub)   || $fmt_sub eq '';
    $max_width = $Max_Table_Width if !defined($max_width) || $max_width eq '';

    my $rewindable  = &$row_sub(1);	# see if data is rewindable

    my ($num_cols, $widths, $precision, $max_widths) = 
    	&calc_widths($col_widths, $titles, $rewindable, 
		     $row_sub, $fmt_sub, $types, 'box', $max_width);

    my $width = 1;
    my $dashes = ' +';
    my $title_line = ' |';
    my $title;
    my $fmt = ' |';		# initial format string
    my $c;

    # Compose the box header
    for ($c = 0; $c < $num_cols; $c++) {
	$width = $max_widths->[$c];	# get previously calculated max col width
	$width += 2; 			# account for a blank on either
					# side of each value
	$dashes .= ('-' x $width);
	$dashes .= '+';

	$title = $#$titles >= 0 && defined($titles->[$c]) ? $titles->[$c] :
		sprintf("Field_%d", $c+1);
	$title_line .= center $title, $width;
	$title_line .= '|';
    }
    out $dashes;
    if ($#$titles >= 0) {
	out $title_line;
	out $dashes;
    }

    my @values;
    my @prefix = (" ", "<");
    my @suffix = (" |", ">|");
    my @cell;

    # loop over the data, formatting it into cells, one row at a time.
    while ((@values = &$row_sub(0)), $#values >= $[) {
	# first pass -- format each value into a string
	@cell = ();
	for ($c = 0; $c <= $#values; $c++) {
	    $cell[$c] = &$fmt_sub($values[$c], $types->[$c], $max_widths->[$c],
				  $widths->[$c], $precision->[$c], 'box');
	}
	# second pass -- output each cell, wrapping if necessary
	my $will_wrap;
	my $wrapped = 0;
	do { $will_wrap = 0;
	    put " |";		# start a line
	    for ($c = 0; $c <= $#cell; $c++) {
		$will_wrap |= &putcell(\@cell, $c, $max_widths->[$c],
				       \@prefix, \@suffix, $wrapped);
	    }
	    out "";
	    $wrapped++;
	} while ($will_wrap);
    }
    out $dashes;
    out "";
}


=head1 ShowSimpleTable 

Display a table of data using a simple table format.

S<  >B<ShowSimpleTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> [, I<\&fmt_sub>];

S<  >B<ShowSimpleTable> { I<parameter> => I<values>, ... };

The B<ShowSimpleTable> subroutine formats data into a simple table of
aligned columns, in the following example:

   Column1  Column2  Column3
   -------  -------  -------
   Value1   Value2   Value3
   Value12  Value22  Value32

Columns are auto-sized by the data's widths, plus two spaces between columns.
Values which are too long for the maximum colulmn width are wrapped within
the column.

=cut

sub ShowSimpleTable {
    my @argv = @_;
    local ($titles, $types, $col_widths, $row_sub, $fmt_sub, $max_width);
    my $args = 
    	get_params 
	    \@argv, 
	    { titles	=> \$titles,
	      types	=> \$types, 
	      widths	=> \$col_widths,
	      row_sub   => \$row_sub, 
	      fmtsub	=> \$fmt_sub,
	      max_width => \$max_width,
	    },
	    [qw(titles types widths row_sub fmtsub max_width)];

    $titles      ne ''  or croak "Missing column names array.\n";
    $types       ne ''  or croak "Missing column types array.\n";
    $col_widths  ne ''  or croak "Missing column width array.\n";
    $row_sub     ne ''  or croak "Missing row sub array.\n";
    $fmt_sub  = \&ShowTableValue  if !defined($fmt_sub)   || $fmt_sub eq '';
    $max_width = $Max_Table_Width if !defined($max_width) || $max_width eq '';

    my $rewindable  = &$row_sub(1);		# see if data is rewindable

    my ($num_cols, $widths, $precision, $max_widths) = 
    	&calc_widths($col_widths, $titles, $rewindable, 
		     $row_sub, $fmt_sub, $types, 'table', $max_width);

    my $width  = 1;
    my $dashes      = ' ';
    my $title_line  = ' ';
    my $title ;
    my $postfix = shift;
    my $c ;

    # Calculate the maximum widths
    for ($c = 0; $c < $num_cols; $c++) {
	$width = $max_widths->[$c];
	$dashes .= ('-' x $width);
	$dashes .= '  ';

	next if $#$titles < 0;
	$title = center $titles->[$c], $width;
	$title_line .= $title;
	$title_line .= '  ';

    }
    out $title_line if $#$titles >= 0;
    out $dashes;

    my @values;
    my @prefix = (" ", "<");
    my @suffix = (" ", ">");

    while ((@values = &$row_sub(0)), $#values >= $[) {
	# first pass -- format each value into a string
	my @cell;
	for ($c = 0; $c <= $#values; $c++) {
	    $cell[$c] = &$fmt_sub($values[$c], $types->[$c], $max_widths->[$c],
				  $widths->[$c], $precision->[$c], 'table');
	}
	# second pass -- output each cell, wrapping if necessary
	my $will_wrap;
	my $wrapped = 0;
	do { $will_wrap = 0;
	    for ($c = 0; $c <= $#cell; $c++) {
		$will_wrap |= &putcell(\@cell, $c, $max_widths->[$c],
		             	       \@prefix, \@suffix, $wrapped);
	    }
	    out "";
	    $wrapped++;
	} while ($will_wrap);
    }
    out "";
}

=head1 ShowHTMLTable 

Display a table of data nicely using HTML tables.

S<  >B<ShowHTMLTable> { I<parameter> => I<value>, ... };

S<  >B<ShowHTMLTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub>
[, I<\&fmt_sub> [, I<$max_width> [, I<\%URL_Keys> [, I<$no_escape> 
[, I<\@title_formats> [, I<\@data_formats> [, I<$table_attrs> ] ] ] ] ] ] ];

The B<ShowHTMLTable> displays one or more rows of columns of data using
the HTML C<\<TABLE\>> feature.  In addition to the usual parameter arguments
of L<"ShowTable">, the following parameter arguments are defined:

=over 10

=item C<url_keys> => I<\%URL_Keys>,

This is a hash array of column names (titles) and corresponding base
URLs.  The values of any column names or indexes occuring as keys in
the hash array will be generated as hypertext anchors using the
associated I<printf>-like string as the base URL. Either the column name
or the column index (beginning with 1) may be used as the hash key.

In the string value, these macros can be substituted:  

"C<%K>" is replaced with the column name.

"C<%V>" is replaced with the column value;

"C<%I>" is replaced with the column index.

For example, if we define the array:

    $base_url = "http://www.$domain/cgi/lookup?col=%K?val=%V";
    %url_cols = ('Author' => $base_url,
		 'Name'   => $base_url);

Then, the values in the C<Author> column will be generated with the following
HTML text:

    <A HREF="http://www.$domain/cgi/lookup?col=Author?val=somevalue>somevalue</A>

and the values in the C<Name> column will be generated with the URL:

    <A HREF="http://www.$domain/cgi/lookup?col=Name?val=othervalue>othervalue</A>

If this variable is not given, it will default to the global variable
C<\%URL_Keys>.

=item C<no_escape> => I<boolean>,

Unless B<$no_escape> is set, HTML-escaping is performed on the data
values in order to properly display the special HTML formatting
characters : '\<', '\>', and '&'.  If you wish to display data with
embedded HTML text, you must set B<$no_escape>.

Enabling embedded HTML, turns on certain heuristics which enable the
user to more completely define appearance of the table.  For instance,
any C<\<TR\>> tokens found embedded *anywhere* within a row of data will
be placed at the front of the row, within the generated C<\<TR\>>.

Similarly, a row of data containing the C<\<THEAD\>> or C<\<TFOOT\>>
tokens, and their closing counterparts, will begin and end, respectively
a table header or footer data.

=item C<title_formats> => I<\@title_formats>,

=item C<tformats> => I<\@title_formats>,

An array of HTML formatting elements for the column titles, one for each
column.  Each array element is a list of one or more HTML elements,
given as C<\<ELEMENT\>> or plainly, C<ELEMENT>, and separated by a comma
C<','>, semi-colon C<';'>, or vertical bar C<'|'>.  Each given HTML
element is prepended to the corresponding column title, in the order
given.  The corresponding HTML closing elements are appended in the
opposite order.

For example, if I<\@title_formats> contains the two elements:

    [ 'FONT SIZE=+2,BOLD', 'FONT COLOR=red,EM' ]

then the text output for the title of the first column would be:

    <FONT SIZE=+2><BOLD>I<column_1_title></BOLD></FONT>

If C<title_formats> is omitted, the global variable B<@Title_Formats>
is used by default.

=item C<data_formats> => I<\@data_formats>,

=item C<dformats> => I<\@data_formats>,

Similar to C<title_formats>, this array provides HTML formatting for
the columns of each row of data.  If C<data_formats> is omitted or
null, then the global variable B<\@Data_Formats> is used by default.

=item C<table_attrs> => I<$table_attrs>,

This variable defines a string of attributes to be inserted within the
C<\<TABLE\>> token.  For example, if the user wishes to have no table
border:

    ShowHTMLTable { 
	...
    	table_attrs => 'BORDER=0', 
        ...
    };

=back

=cut

sub ShowHTMLTable {
    my @argv = @_;
    local ($titles, $types, $col_widths, $row_sub, $fmt_sub, $max_width, 
    	   $url_keys, $no_escape, $title_formats, $data_formats, 
	   $show_mode, $table_attrs);
    my $args = 
    	get_params 
	    \@argv, 
	    { titles	    => \$titles,
	      types	    => \$types, 
	      widths	    => \$col_widths,
	      row_sub       => \$row_sub, 
	      fmtsub	    => \$fmt_sub,
	      max_width     => \$max_width,
	      url_keys	    => \$url_keys,
	      no_escape     => \$no_escape,
	      tformats 	    => \$title_formats,
	      dformats      => \$data_formats,
	      table_attrs   => \$table_attrs,
	      data_formats  => 'tformats',
	      title_formats => 'tformats',
	    },
	    [qw(titles types widths row_sub fmtsub max_width 
	        url_keys no_escape title_formats data_formats
		table_attrs)];

    $titles      ne ''  or croak "Missing column names array.\n";
    $types       ne ''  or croak "Missing column types array.\n";
    $col_widths  ne ''  or croak "Missing column width array.\n";
    $row_sub     ne ''  or croak "Missing row sub array.\n";

    # Defaults
    $fmt_sub  = \&ShowTableValue     if !defined($fmt_sub)       || $fmt_sub eq '';
    $max_width = $Max_Table_Width    if !defined($max_width)     || $max_width eq '';
    $url_keys = \%URL_Keys 	     if !defined($url_keys)      || $url_keys eq '';
    $title_formats = \@Title_Formats if !defined($title_formats) || $title_formats eq '';
    $data_formats = \@Data_Formats   if !defined($data_formats)  || $data_formats eq '';
    $no_escape = $No_Escape 	     if !defined($no_escape);

    my $rewindable = &$row_sub(1);		# see if rewindable

    my ($num_cols, $widths, $precision, $max_widths) = 
	&calc_widths($col_widths, $titles, $rewindable, 
		     $row_sub, $fmt_sub, $types, 'html', $max_width);

    my $width  = 1;
    my $total_width = 0;
    my $title_line = '';
    my $title;
    my ($c,$x);
    my ($tprefixes,$tsuffixes,$dprefixes,$dsuffixes);

    # prepare the HTML prefixes and suffixes, if any
    ($tprefixes,$tsuffixes) = html_formats $title_formats 
    	if defined($title_formats) && $title_formats ne '';
    ($dprefixes,$dsuffixes) = html_formats $data_formats  
    	if defined($data_formats) && $data_formats ne '';

    if ($table_attrs) {			# any table attributes?
	local($_) = $table_attrs;
	$table_attrs .= ' BORDER=1'      unless /\bBORDER=/i;
	$table_attrs .= ' CELLPADDING=1' unless /\bCELLPADDING=/i;
	$table_attrs .= ' CELLSPACING=1' unless /\bCELLSPACING=/i;
    } else {
	$table_attrs = 'BORDER=2 CELLPADDING=1 CELLSPACING=1';
    }
	
    out "<TABLE $table_attrs>\n<TR>" ;
    map { $total_width += defined($_) ? $_ : 0; } @$max_widths;
    for ($c = 0; $c < $num_cols; $c++) {
	# If the user specified a width, then use it.
	$width = defined($widths->[$c]) ? $widths->[$c] : $max_widths->[$c];
	my $pct_width = int(100 * $width/$total_width);
	$title_line .= " <TH ALIGN=CENTER WIDTH=$pct_width%%>";
	if ($#$titles >= 0) {
	    if (($x = $#$tprefixes) >= 0) {
		$title_line .= $tprefixes->[$c > $x ? $x : $c];
	    }
	    $title_line .= $no_escape ? $titles->[$c] : &htmltext($titles->[$c]);
	    if (($x = $#$tsuffixes) >= 0) {
		$title_line .= $tsuffixes->[$c > $x ? $x : $c];
	    }
	}
	$title_line .= "</TH>\n";
    }
    out $title_line;
    out "</TR>";

    my ($href, $key, $val, $out);
    while ((@values = &$row_sub(0)), $#values >= $[) {
	out "<TR> ";
	# Walk through the values
	for ($c = 0; $c <= $#values; $c++) {
	    $out = "<TD";
	    if (defined($val = $values[$c])) { # only worry about defined values
		# In HTML mode, all CHAR, TEXT, SYMBOL, or STRING data should
		# be escaped to protect HTML syntax "<", ">", "\", and "&".
		if ($types->[$c] =~ /char|text|symbol|string/i) {
		    $val = &htmltext($val) unless $no_escape;
		    $out .= " ALIGN=LEFT";
		} else {
		    $out .= " ALIGN=RIGHT";
		}
		$out .= ">";
		# Discover if either the column name or column index
		# have been mapped to a URL.
		$href = '';
		foreach $key ( $#$titles >= 0 && &PlainText($titles->[$c]),
				sprintf("%d", $c+1)) {
		    next unless $key ne '' && defined($url_keys->{$key});
		    $href = $url_keys->{$key};
		    last;
		}
		if ($href ne '') {
		    if ($href =~ /%K/) {
			my $s = &htmltext(&PlainText($titles->[$c]), 1);
			$href =~ s/%K/$s/g;
		    }
		    if ($href =~ /%V/) {
			my $s = &htmltext($val, 1);
			$href =~ s/%V/$s/g;
		    }
		    if ($href =~ /%I/) {
			my $s = sprintf("%d", $c+1);
			$href =~ s/%I/$s/g;
		    }
		    $out .= sprintf("<A HREF=\"%s\">",$href);
		}
		$val = &$fmt_sub($val, $types->[$c], 0, $widths->[$c], 
				 $precision->[$c], 'html');
		$val =~ s/^\s+//;		# don't try to align
		$val =~ s/\s+$//;

		if (($x = $#$dprefixes) >= 0) {
		    $out .= $dprefixes->[$c > $x ? $x : $c];
		}
		$out .= $val;
		if (($x = $#$dsuffixes) >= 0) {
		    $out .= $dsuffixes->[$c > $x ? $x : $c];
		}
		$out .= "</A>" if $href;
	    } else {
		$out .= ">";
	    }
	    $out .= "</TD>";
	    out $out;
	}
	out "</TR>";
    }
    out "</TABLE>";
}

=head1 ShowListTable

Display a table of data using a list format.

S<  >B<ShowListTable> { I<parameter> => I<value>, ... };

S<  >B<ShowListTable> I<\@titles>, I<\@types>, I<\@widths>, I<\&row_sub> 
[, I<\&fmt_sub> [, I<$max_width> [, I<$wrap_margin> ] ] ];

The arguments for B<ShowListTable> are the same as for L<"ShowTable">,
except for those described next.

=over 10

=item C<max_width> = I<number>,

=item C<wrap_margin> = I<number>,

Lines are truncated, and wrapped when their length exceeds
I<$max_width>.  Wrapping is done on a word-basis, unless the resulting
right margin exceeds I<$wrap_margin>, in which case the line is simply
truncated at the I<$max_width> limit.

The I<$max_width> variable defaults to B<$Max_List_Width>.  The
I<$wrap_margin> defaults to B<$List_Wrap_Margin>.

=back

In I<List> mode, columns (called "fields" in List mode) are displayed
wth a field name and value pair per line, with records being one or
more fields .  In other words, the output of a table would
look something like this:

    Field1_1: Value1_1
    Field1_2: Value1_2
    Field1_3: Value1_3
    ...
    Field1-N: Value1_M
    <empty line>
    Field2_1: Value2_1
    Field2_2: Value2_2
    Field2_3: Value2_3
    ...
    Field2_N: Value2_N
    ...
    FieldM_1: ValueM_1
    FieldM_2: ValueM_2
    ...
    FieldM_N: ValueM_N
    <empty line>
    <empty line>

Characteristics of I<List> mode:

=over 10

=item *

two empty lines indicate the end of data.

=item *

An empty field (column) may be omitted, or may have a label, but no
data.

=item *

A long line can be continue by a null field (column):

    Field2: blah blah blah
          : blah blah blah

=item *

On a continuation, the null field is an arbitrary number of leading
white space, a colon ':', a single blank or tab, followed by the
continued text.

=item *

Embedded newlines are indicated by the escape mechanism "\n".
Similarly, embedded tabs are indicated with "\t", returns with "\r". 

=item *

If the I<@titles> array is empty, the field names "C<Field_>I<NN>" are used
instead.

=back

=cut

sub ShowListTable {
    my @argv = @_;
    local ($titles, $types, $col_widths, $row_sub, $fmt_sub, $max_width, 
    	   $wrap_margin);
    my $args = 
    	get_params 
	    \@argv, 
	    { titles 	  => \$titles,
	      types	  => \$types,
	      widths 	  => \$col_widths,
	      row_sub	  => \$row_sub,
	      fmtsub 	  => \$fmt_sub,
	      max_width   => \$max_width,
	      wrap_margin => \$wrap_margin,
	    },
	    [qw(titles types widths row_sub fmt_sub max_width wrap_margin)];

    defined($titles)     && $titles ne ''       or croak "Missing column names array.\n";
    defined($types)      && $types  ne ''       or croak "Missing column types array.\n";
    defined($col_widths) && $col_widths  ne ''  or croak "Missing column width array.\n";
    defined($row_sub)    && $row_sub ne ''      or croak "Missing row sub array.\n";

    $fmt_sub  = \&ShowTableValue     if !defined($fmt_sub)     || $fmt_sub eq '';
    $max_width = $Max_List_Width     if !defined($max_width)   || $max_width eq '';
    $wrap_margin = $List_Wrap_Margin if !defined($wrap_margin) || $wrap_margin eq '';

    my $rewindable = &$row_sub(1);	# init the row pointer

    my ($num_cols, $widths, $precision, $max_widths) = 
	&calc_widths($col_widths, $titles, $rewindable,
    		     $row_sub, $fmt_sub, $types, 'list', '');

    my $fmt = sprintf("%%-%ds : %%s\n", ($#$titles >= 0 ? &max_length($titles) : 8));
    my @values;
    my ($value, $c, $cut, $line);
    my $col_limit = $max_width - 2;

    while ((@values = &$row_sub(0)), $#values >= $[) {
	for ($c = 0; $c <= $#values; $c++) {
	    # get this column's title
	    $title = $#$titles >= 0 ? $titles->[$c] : sprintf("Field_%d", $c+1);
	    my $type  = $types->[$c];
	    my $width = 0;
	    my $prec  = $precision->[$c];
	    $value = &$fmt_sub($values[$c], $type, 0, $width, $prec, 'list');
	    while (length($value)) {
		if (length($value) > ($cut = $col_limit)) {
		    $line = substr($value, 0, $cut);
		    if ($line =~ m/([-,;? \t])([^-,;? \t]*)$/ && 
			length($2) <= $wrap_margin) {
			$cut = $col_limit - length($2);
			$line = substr($value, 0, $cut);
		    }
		    ($value = substr($value, $cut)) =~ s/^\s+//;
		} else {
		    $line = $value;
		    $value = '';
		}
		out $fmt, $title, $line;
		$title = '';
	    }
	}
	out "";
    }
}

=head1 ShowRow 

Fetch rows successively from one or more columns of data.

S<  >B<ShowRow> I<$rewindflag>, I<\$index>, I<$col_array_1> [, I<$col_array_2>, ...;]

The B<ShowRow> subroutine returns a row of data from one or more
columns of data.  It is designed to be used as a I<callback> routine,
within the B<ShowTable> routine.   It can be used to select elements
from one or more array reference arguments.

If passed two or more array references as arguments, elements of the
arrays selected by I<$index> are returned as the "row" of data.

If a single array argument is passed, and each element of the array is
itself an array, the subarray is returned as the "row" of data.

If the I<$rewindflag> flag is set, then the I<$index> pointer is reset
to zero, and "true" is returned (a scalar 1).  This indicates that the
data is rewindable to the B<ShowTable> routines.

When the I<$rewindflag> is not set, then the current row of data, as
determined by I<$index> is returned, and I<$index> will
have been incremented.

An actual invocation (from B<ShowColumns>) is:

  ShowTable \@titles, \@types, \@lengths, 
      sub { &ShowRow( $_[0], \$current_row, $col_names, $col_types,
                      $col_lengths, \@col_attrs); };

In the example above, after each invocation, the I<$current_row> argument 
will have been incremented.

=cut

sub ShowRow {
    my $rewind_flag = shift;
    my $index_ref = shift;              # an indirect index
    my @columns = @_;                   # get rest of columns
    my @row;                            # we're selecting a row
    if ($rewind_flag) {
        $$index_ref = 0;                # reset the pointer
        return 1;
    }
    return () if $#{$columns[0]} < $$index_ref;
    if ($#columns == 0) {               # exactly one array ref argument
        my $data = $columns[0]->[$$index_ref];  # get the current data
        if (ref($data) eq 'ARRAY') {    # if an array..
            @row = @$data;              # ..return the array of data
        } elsif (ref($data) eq 'HASH') {# if a hash..
            @row = values %$data;       # ..return the values 
        } else {                        # otherwise..
            @row = ($data);             # ..return the data element
        }
    } else {                            # with two or more array refs..
        my $col;                        # select elements from each
        for ($col = 0; $col <= $#columns; $col++) {
            push(@row, ${$columns[$col]}[$$index_ref]);
        }
    }
    ${$index_ref}++;                    # increment the index for the next call
    @row;                               # return this row of data
}

=head1 ShowTableValue

Prepare and return a formatted representation of a value.  A value
argument, using its corresponding type, effective width, and precision
is formatted into a field of a given maximum width. 

S<  >I<$fmt> = B<ShowTableValue> I<$value>, I<$type>, I<$max_width>, I<$width>, I<$precision>, I<$showmode>;

=over 10

=item C<width> => I<$width>

=item I<$width>

The width of the current value.  If omittied, I<$max_width> is assumed.

=item C<precision> => I<$precision>

=item I<$precision>

The number of decimal digits; zero is assumed if omittied.

=item C<value> => I<$value>

=item I<$value>

The value to be formatted.

=item I<$type>

The type name of the value; eg: C<char>, C<varchar>, C<int>, etc.

=item C<maxwidth> => I<$max_width>

=item I<$max_width>

The maximum width of any value in the current value's column.  If I<$width>
is zero or null, I<$max_width> is used by default.  I<$max_width> is also
used as a I<minimum> width, in case I<$width> is a smaller value.

=item I<$width>

The default width of the value, obtained from the width specification of the
column in which this value occurs.

=item I<$precision>

The precision specification, if any, from the column width specification.

=item I<$showmode>

The mode of the output: one of "table", "list", "box", or "html".  Currently,
only the "html" mode is significant: it is used to avoid using HTML tokens
as part of the formatted text and length calculations.

=back

=cut
    
sub ShowTableValue { 
    my $value     = shift;
    my $type      = shift;
    my $max_width = shift;
    my $width     = shift;
    my $prec      = shift || 2;
    my $showmode  = shift;
    my $fmt       = ($Type2Format{lc($type)} || $Type2Format{'char'});
    my $str;

    $max_width = 0 if !defined($max_width) || $max_width eq '';
    $width = $max_width if !defined($width) || $width eq '';

    $width = min($width, $max_width) if $max_width > 0;
    if ($type =~ /money/i) {	# money formatting is special
	if (($str = $value) !~ /[\$,]/) {	# not already formatted?
	    my ($d,$c) = split(/\./,$value,2);
	    # reverse the digits
	    $d = join('',reverse(split(//,abs($d))));
	    # do the grouping from the rightmost to the left
	    $d =~ s/(...)(?=.)/$1,/g;
	    # reverse the digits and grouping char
	    $d = '$'.join('',reverse(split(//,$d)));
	    # If there is any precision, add on pennies (allow for > 2 precision)
	    $d .= sprintf($prec > 2 ? "%0${prec}d" : ".%02d",$c) if $prec > 0;
	    # Mark as negative with '(xxx)'
	    $d = '-'.$d if $value < 0;
	    $str = $d;
	}
    } else {
	$fmt = sprintf ($fmt,$width,$prec);

	# If we are in HTML mode, and the value has any HTML tokens,
	# then format it always as a string (even if it might
	# be a decimal--this is a kluge but seems to work).

	if ($showmode =~ /html/i && $value =~ /<\/?($HTML_Elements)/) {
	    $fmt =~ s/[df]/s/;	# convert to string sub
	}
	$str = sprintf($fmt,$value);
    }
    if ($width > length(&PlainText($str))) {
	# right align the value if any kind of number
	$str = sprintf("%${width}s", $str) 
	    if $type =~ /int|float|pct|real|numeric|money/i;
    }
    $str;
}

%Type2Format = (
  'char'	=> '%%-%ds',
  'varchar'	=> '%%-%ds',
  'symbol'	=> '%%-%ds',
  'tinyint'	=> '%%%dd',
  'shortint'	=> '%%%dd',
  'int'		=> '%%%dd',
  'pct'	        => '%%%d.%df%%%%',
  'real'	=> '%%%d.%df',
  'float'	=> '%%%d.%df',
  'numeric'	=> '%%%d.%df',
  'text'	=> '%%-%ds',

  # The money types do not actually need to be in this table, since 
  # ShowTableValue handle money formatting explicitly.  However, some
  # one else might use this table, so we treat them like right-aligned
  # strings.
  'money'	=> '%%%d.%df',
  'smallmoney'	=> '%%%d.%df',

  );

=head1 PlainText

S<  >I<$plaintext> = B<&PlainText>(I<$htmltext>);

S<  >B<&PlainText>

This function removes any HTML formatting sequences from the input argument,
or from C<$_> if no argument is given.  The resulting plain text is returned
as the result.

=cut

#   $plaintext = &PlainText($htmltext);
# or:
#   &PlainText;
#
# Convert the argument and return as a string, or convert $_.

sub PlainText {
    local($_) = shift if $#_ >= 0;	# set local $_ if there's an argument
					# skip unless there's a sequence
    return $_ unless m=</?($HTML_Elements)=i;	# HTML text?
    s{</?(?:$HTML_Elements)#		# match and remove any HTML token..
	 (?:\ \w+#			# ..then PARAM or PARAM=VALUE
	     (?:\=(?:"(?:[^"]|\\")*"|#	# ...."STRING" or..
		    [^"> ]+#		# ....VALUE
		 )#
	     )?#			# ..=VALUE is optional
	 )*#				# zero or more PARAM or PARAM=VALUE
      >}{}igx;				# up to the closing '>'
    $_;					# return the result
}

BEGIN {

@HTML_Elements = qw(
    A ABBREV ACRONYM ADDRESS APP APPLET AREA AU B BANNER BASE BASEFONT BDO
    BGSOUND BIG BLINK BLOCKQUOTE BODY BQ BR CAPTION CENTER CITE CODE COL
    COLGROUP CREDIT DD DEL DFN DIR DIV DL DT EM EMBED FN FIG FONT FORM FRAME
    FRAMESET H1 H2 H3 H4 H5 H6 HEAD HP HR HTML I IMG INPUT INS ISINDEX KBD
    LANG LH LI LINK LISTING MAP MARQUEE MENU META NEXTID NOBR NOEMBED
    NOFRAMES NOTE OL OPTION OVERLAY P PARAM PERSON PLAINTEXT PRE Q S SAMP
    SELECT SMALL SPAN STRIKE STRONG SUB SUP TAB TABLE TBODY TD TEXTAREA
    TFOOT TH THEAD TITLE TR TT U UL VAR WBR XMP 
);

$HTML_Elements = join("|",@HTML_Elements);

}

=head1 VARIABLES

The following variables may be set by the user to affect the display (with
the defaults enclosed in square brackets [..]):

=over 10

=item B<$Show_Mode> [Box]

This is the default display mode when using B<ShowTable>.  The
environment variable, C<$ENV{'SHOW_MODE'}>, is used when this variable is
null or the empty string.  The possible values for this variable are:
C<"Box">, C<"List">, C<"Table">, and C<"HTML">.  Case is insignificant.

=item B<$List_Wrap_Margin> [2]

This variable's value determines how large a margin to keep before wrarpping a
long value's display in a column.  This value is only used in "List" mode.

=item B<$Max_List_Width> [80]

This variable, used in "List" mode, is used to determine how long an output line
may be before wrapping it.  The environment variable, C<$ENV{'COLUMNS'}>, is
used to define this value when it is null.

=item B<$Max_Table_Width> ['']

This variable, when set, causes all tables to have their columns scaled
such that their total combined width does not exceed this value.  When
this variable is not set, which is the default case, there is no maximum
table width, and no scaling will be done.

=item B<$No_Escape> ['']

If set, allows embedded HTML text to be included in the data displayed
in an HTML-formatted table.  By default, the HTML formatting characters
("<", ">", and "&") occuring in values are escaped.

=item B<%URL_Keys>

In HTML mode, this variable is used to recognize which columns are to be 
displayed with a corresponding hypertext anchor.  See L<"ShowHTMLTable"> 
for more details.

=item B<@HTML_Elements>

An array of HTML elements (as of HTML 3.0) used to recognize and strip for 
width calculations.

=item B<$HTML_Elements>

A regular expression string formed from the elements of B<@HTML_Elements>.

=back

=cut

##############################

=head1 INTERNAL SUBROUTINES

=head1 get_params

S<  >my I<$args> = B<&get_params> I<\@argv>, I<\%params>, I<\@arglist>;

Given the I<@argv> originally passed to the calling sub, and the hash of
named parameters as I<%params>, and the array of parameter names in the
order expected for a pass-by-value invocation, set the values of each of
the variables named in I<@vars>.  

If the only element of the I<@argv> is a hash array, then set the
variables to the values of their corresponding parameters used as keys
to the hash array.  If the parameter is not a key of the I<%params>
hash, and is not a key in the global hash B<%ShowTableParams>, then an
error is noted.

When I<@argv> has multiple elements, or is not a hash array, set each
variable, in the order given within I<@arglist>, to the values from the
I<@argv>, setting the variables named by each value in I<%params>.

Variables may given either by name or by reference.

The result is a HASH array reference, either corresponding directly to
the HASH array passed as the single argument, or one created by
associating the resulting variable values to the parameter names
associated with the variable names.

=cut

sub get_params {
    my $argvref = shift or croak "Missing required argument.\n";
    my $params  = shift or croak "Missing required parameters hash.\n";
    my $arglist = shift or croak "Missing required arglist array.\n";
    my %args;
    my ($param, $var);
    if ($#$argvref == 0 && ref($argvref->[0]) eq 'HASH') {
	my $href = $argvref->[0];
	%args = %$href;			# initialize result with input hash
	foreach $param (keys %$href) {	# for each named argument...
	    # Is this a known parameter?
	    if (exists($params->{$param})) {
		$var = $params->{$param};
		while ($var ne '' && ref($var) eq '') {	# indirect refs?
		    $var = $params->{$param = $var};
		}
		if ($var ne '') {
		    $$var = $href->{$param}; # assign the param's variable
		    $args{$param} = $$var;	# make sure canonical param gets defined
		    next;		# go to the next parameter
		}
	    }
	    if (!exists($show_table_params{$param})) {
		croak "Unknown parameter: \"$param\"\n";
	    }
	}
    } else {			# use args in the order given for variables
	my $i;
	for ($i = 0; $i <= $#$arglist; $i++) {
	    $param = $arglist->[$i];	# get the next argument
	    $var = $params->{$param};	# get it's variable
	    next unless defined($var);
	    while ($var ne '' && ref($var) eq '') {
		$var = $params->{$param = $var};
	    }
	    if ($var ne '') {
		$$var = $i <= $#$argvref ? $argvref->[$i] : '';
		$args{$param} = $$var;	# assign to the hash
	    } elsif (!exists($show_table_params{$param})) {
		croak "Unknown parameter: \"$param\" for argument $i.\n";
	    }
	}
    }
    # Now, make sure all variables get initialized
    foreach $param (keys %$params) {
	$var = $params->{$param};
	while ($var ne '' && ref($var) eq '') {
	    $var = $params->{$param = $var};
	}
	if ($var ne '' && !exists($args{$param})) {
	    $$var = $args{$param} = undef;
	}
    }
    \%args;			# return the HASH ref
}

BEGIN {

# A table of parameters used by all the external subroutines For
# example, in order for parameters applicable to ShowHTMLTable to be
# passed through ShowTable, they need to be defined in this table.

@show_table_params = qw(
	caption
	col_attributes
	col_lengths
	col_names
	col_types
	data
	data_formats
	dformats
	fmt_sub
	fmtsub
	max_width
	no_escape
	row_sub
	show_mode
	table_attrs
	tformats
	title_formats
	titles
	types
	url_keys
	widths
	wrap_margin
    );
@show_table_params{@show_table_params} = () x (1 + $#show_table_params);
undef @show_table_params;

}

=head1 html_formats

S<  >(I<$prefixes>,I<$suffixes>) = B<html_formats> I<\@html_formats>;

The B<html_format> function takes an array reference of HTML formatting
elements I<\@html_formats>, and builds two arrays of strings: the first:
I<$prefixes>, is an array of prefixes containing the corresponding HTML
formatting elements from I<\@html_formats>, and the second,
I<$suffixes>, containing the appropriate HTML closing elements, in the
opposite order.

The result is designed to be used as prefixes and suffixes for the
corresponding titles and column values.

The array I<\@html_formats> contains lists of HTML formatting elements,
one for each column (either title or data).  Each array element is a
list of one or more HTML elements, either given in HTML syntax, or as a
"plain" name (ie: given as C<\<ELEMENT\>> or plainly, C<ELEMENT>).
Multiple elements are separated by a comma C<','>.

The resulting array of I<$prefixes> contains the corresponding opening
elements, in the order given, with the proper HTML element syntax.  The
resulting array of I<$suffixes> contains the closing elements, in the
opposite order given, with the proper HTML element syntax.

For example, if I<\@html_formats> contains the two elements:

    [ 'FONT SIZE=+2,BOLD', 'FONT COLOR=red,EM' ]

then the resulting two arrays will be returned as:

    [ [ '<FONT SIZE=+2><BOLD>', '<FONT COLOR=red><EM>' ],
      [ '</FONT></BOLD>',	'</FONT></EM>' ] ]

=cut

sub html_formats {
    my $html_formats = shift;		# array ref
    my $i;
    my (@prefixes, @suffixes);
    my ($html, $elt, $html_list, @html_list);
    my ($prefixes, $suffixes);
    local($_);

    foreach $html_list (@$html_formats) {
	@html_list = split(/,/,$html_list);
	$prefixes = $suffixes = '';	# initialize the list
	my %formats;			# keep track of formats
	foreach (@html_list) {
	    ($html, $elt) = ();
	    if (($html, $elt) = /^(<)?\s*(\w+)/) {# <KEYWORD or KEYWORD
		next if $formats{$elt}++ > 0;	# only do an element once
		$html = '<' unless $html;
		$prefixes .= $html.$elt.$';
		$prefixes .= '>' unless $prefixes =~ />$/;
		$suffixes = $html.'/'.$elt.'>'.$suffixes;
	    }
	}
	push(@prefixes, $prefixes);	# even push empty items
	push(@suffixes, $suffixes);
    }
    ( \@prefixes, \@suffixes );
}


=head1 calc_widths

S<  >(I<$num_cols>, I<$widths>, I<$precision>, I<$max_widths>) =
S<  >B<&calc_widths>( I<$widthspec>, I<$titles>, I<$rewindable>,
S<      >I<$row_sub>, I<$fmt_sub>, I<$types>, I<$showmode>, 
S<      >I<$max_width>);

=head2 B<DESCRIPTION>

B<calc_widths> is a generalized subroutine used by all the B<ShowTable>
variant subroutines to setup internal variables prior to formatting for
display.  B<Calc_widths> handles the column width and precision
analysis, including scanning the data (if rewindable) for appropriate
default values.

The number of columns in the data is returned, as well as three arrays:
the declared column widths, the column precision values, and the maximum
column widths.

=head2 B<RETURN VALUES>

=over 10

=item I<$num_cols>

is the number of columns in the data.  If the data is not rewindable,
this is computed as the maximum of the number of elements in the
I<$widthspec> array and the number of elements in the I<$titles>
array.  When the data is rewindable, this is the maximum of the number
of columns of each row of data.

=item I<$widths>

is the column widths array ref, without the precision specs (if any).
Each column's width value is determined by the original I<$widthspec>
value and/or the maximum length of the formatted data for the column.

=item I<$precision>

is the precision component (if any) of the original I<$widthspec>
array ref.  If there was no original precision component from the I<$widthspec>,
and the data is rewindable, then the data is examined to determine the
maximum default precision.

=item I<$max_widths>

is the ref to the array of maximum widths for the given columns.

=back

=head2 B<ARGUMENTS>

=over 10

=item I<$widthspec>

A reference to an array of column width (or length) values, each given
as an integer, real number, or a string value of
"I<width>.I<precision>".  If a value is zero or null, the length of the
corresponding formatted data (if rewindable) and column title length are
used to determine a reasonable default.

If a column's I<width> portion is a positive, non-zero number, then the
column will be this wide, regardless of the values lengths of the data
in the column.

If the column's I<width> portion is given as a negative number, then the
positive value is used as a minimum column width, with no limit on the
maximum column width.  In other words, the column will be at least
I<width> characters wide.

If the data is not rewindable, and a column's width value is null or
zero, then the length of the column title is used.  This may cause severe
wrapping of data in the column, if the column data lengths are much
greater than the column title widths.

=item I<$titles>

The array ref to the column titles; used to determine the minimum
acceptable width, as well as the default number of columns.  If the
C<$titles> array is empty, then the C<$widthspec> array is used to
determine the default number of columns.

=item I<$rewindable>

A flag indicating whether or not the data being formatted is rewindable.
If this is true, a pass over the data will be done in order to calculate
the maximum lengths of the actual formatted data, using I<$fmt_sub>
(below), rather than just rely on the declared column lengths.  This
allows for optimal column width adjustments (ie: the actual column
widths may be less than the declared column widths).

If it is not desired to have the column widths dynamically adjusted,
then set the I<$rewindable> argument to 0, even if the data is
rewindable.

=item I<$row_sub>

The code reference to the subroutine which returns the data; invoked
only if I<$rewindable> is non-null.

=item I<$fmt_sub>

The subroutine used to determine the length of the data when formatted;
if this is omitted or null, the length of the data is used by default.
The I<$fmt_sub> is used only when the data is rewindable.

=item I<$types>

An array reference to the types of each of the value columns; used only 
when I<$fmt_sub> is invoked.

=item I<$showmode>

A string indicating the mode of the eventual display; one of four strings:
"C<box>", "C<table>", "C<list>", and "C<html>".  Used to adjust widths
for formatting requirements.

=item I<$max_width>

The maximum width of the table being formatted.  If set, and the total
sum of the individual columns exceeds this value, the column widths are
scaled down uniformly.  If not set (null), no column width scaling is done.

=back

=cut

sub calc_widths {
    my $widthspec	= shift;
    my $titles		= shift;
    my $rewindable	= shift;
    my $row_sub		= shift;
    my $fmt_sub		= shift;
    my $types		= shift;
    my $showmode	= shift;
    my $max_width 	= shift;

    my @precision;			# array of precision values
    my @setprec;			# array of flags to set default precision
    my @widths;				# array of widths
    my @max_widths;			# array of max widths
    my @expandable;			# flag if widths expandable
    my $num_cols;
    my $c;

    if ($#$widthspec >= 0) {
	@precision = @$widthspec;
	foreach (@precision) { s/^.*\.(\d+)/$1/ || ($_ = ''); }

	# The setprec array indicates which columns need a default precision
	@setprec = map { !length } @precision;

	# Get the integer portions
	@widths = map { length($_) ? int : 0 } @$widthspec;

	# Set @expandable if negative widths
	@expandable = map { $_ < 0 } @widths;

	# Convert widths to all positive values
	@widths = map abs, @widths;
	@max_widths = (0) x (1 + $#widths);	# no maximums yet
	$num_cols = 1 + $#widths;
    } else {
	# No widths given
	@expandable = (1) x (1 + $#$titles);
	@precision = ('') x (1 + $#$titles);
	@setprec   = @expandable;
	@max_widths = map length, @$titles;	# initialize maximums to title widths 
	$num_cols = 1 + $#$titles;
    }

    # If the data is rewindable, scan and accumulate *actual* widths for
    # each column, using the title lengths as a minimum.
    if ($rewindable) {
	my @values;
	my @prectype;
	if (ref($types) eq 'ARRAY') {
	    @prectype = map {/float|num(eric|ber)|money|dec|real|precision|double/i } @$types;
	}

	# Scan the values
	while ((@values = &$row_sub(0)), $#values >= $[) {
	    # If the new row is larger than the number of titles, adjust
	    # the info arrays..
	    if ($num_cols < 1 + $#values) {	# new column?
		$num_cols = 1 + $#values;	# new # of columns
		for ($c = $#expandable + 1; $c <= $#values; $c++) {
		    $expandable[$c] = 1;
		    $precision[$c] = '';
		    $setprec[$c] = 1;
		    $max_widths[$c] = 0;
		}
	    }
	    my $len;
	    my $value;
	    for ($c = 0; $c < $num_cols; $c++) {
		# Does this column's precision need setting?
		if ($setprec[$c]) {
		    # Yes, is it a type of value which can use the precision?
		    if ($prectype[$c]) {
			# yes, how much is the current value's default precision?
		    	if ($values[$c] =~ /\.(.*)$/) {
			    $precision[$c] = length($1) if length($1) > $precision[$c];
			}
		    } else {
			# No, this column can't use the precision value -- don't
			# do this check on this column again
			$precision[$c] = $setprec[$c] = 0;
		    }
		}

		# Now, let's get the formatted value so we can guess the best
		# default widths
		$value = 
		    # If a fmt_sub is available, use it to format the value
		    $fmt_sub ? 
			&$fmt_sub($values[$c], $types->[$c], 0, 0, $precision[$c], $showmode)
			# If no fmt sub, then use Perl stringify
		        : length($showmode eq 'html' ?  # in HTML mode?
				&PlainText($values[$c]) # use plain text
			        : $values[$c]); 	# else, use raw text
		$len = length($value);

		$max_widths[$c] = $len if 
			$c > $#max_widths || $len > $max_widths[$c];
	    }
	}
	# okay -- maximums scanned.  
	# If the maximum table width set, scale the max_widths
	$max_width = 0 unless 
		defined($max_width) && $max_width ne '';
	if ($max_width > 0) {
	    # Start with the given maximum, but adjust it to account for
	    # the formatting and space characters.
	    my $max_width = $max_width;
	    $max_width -= $num_cols * 3 + 2 if $showmode eq 'box';
	    $max_width -= $num_cols * 2 - 1 if $showmode eq 'table';
	    my $total = 0;
	    # Calculate the total table width
	    for ($c = 0; $c <= $#max_widths; $c++) {
		$total += $max_widths[$c];
	    }
	    if ($max_width < $total) {
		# Now scale it to the adjusted maximum table width
		for ($c = 0; $c <= $#max_widths; $c++) {
		    $max_widths[$c] = int($max_widths[$c] *
					  $max_width / $total); 
		}
	    }
	}
		
	# If the column is expandable, allow the width to grow to the max_width.
	# If the column is not expandable, allow the width to shrink to
	# the max_width if it is smaller.

	if ($#widths < 0) {		# were there any widths?
	    @widths = @max_widths;	# nope, set them to the scanned values
	} else {
	    $num_cols = max($num_cols, 1 + $#widths) if $#widths >= 0;
	    my $len;
	    for ($c = 0; $c < $num_cols; $c++) {
	    	# provide defaults first
		$max_widths[$c] = 0 if !defined($max_widths[$c]);
		$widths[$c] = $max_widths[$c] 
		    if $c > $#widths || !defined($widths[$c]);
		# if the column can shrink, let it
		if ($max_widths[$c] < $widths[$c]) {
		    $widths[$c] = $max_widths[$c];
		} elsif ($expandable[$c] || !$widths[$c]) {
		    # allow the width to grow to the maximum width
		    $widths[$c] = $max_widths[$c] if $widths[$c] < $max_widths[$c];
		} elsif ($max_widths[$c] > $widths[$c] && $widths[$c] > 0) {
		    # not expandable -- set the max width to the width value
		    $max_widths[$c] = $widths[$c];
		}
		# In either case, however, ensure that the widths are at
		# least as long as the title length
		if ($c <= $#$titles) {
		    if (defined($titles->[$c])) {
			# If we're in HTML mode, get the length of the plaintext
			$len = length($showmode eq 'html' ? &PlainText($titles->[$c])
							  # else, use raw text.
							  : $titles->[$c]);
		    } else { 
			$len = length("Field_$c");
		    }
		    $widths[$c] = $len 
			if $widths[$c] < $len;
		    $max_widths[$c] = $len
			if $max_widths[$c] < $len;
		}
	    }
	}
	&$row_sub(1);			# reset the pointer for the next scan
    } else {
	# Use title width as default if original width is null or zero
	my $len;
	for ($c = 0; $c <= $#widths; $c++) {
	    next unless $c <= $#$titles;
	    # Get the length of the title (sans HTML text if in that mode)
	    $len = length($showmode eq 'html' ? &PlainText($titles->[$c])
					      : $titles->[$c]);
	    $widths[$c] = $len if $widths[$c] < $len;
	}
	# Can't scan the data, so the maximums can only be set by using the
	# explicit widths.
	@max_widths = @widths;
    }
    ($num_cols, \@widths, \@precision, \@max_widths);
}

##############################

=head1 putcell

S<  >I<$wrapped> = B<&putcell>( I<\@cells>, I<$c>, I<$cell_width>, I<\@prefix>, I<\@suffix>, I<$wrap_flag> );

Output the contents of an array cell at I<$cell>[I<$c>], causing text
longer than I<$cell_width> to be saved for output on subsequent calls.
Prefixing the output of each cell's value is a string from the
two-element array I<@prefix>.  Suffixing each cell's value is a string
from the two-element array I<@suffix>.  The first element of either 
array is selected when I<$wrap_flag> is zero or null, or when there is
no more text in the current to be output.  The second element
is selected when I<$wrap_flag> is non-zero, and when there is more text in
the current cell to be output.

In the case of text longer than I<$cell_width>, a non-zero value is
returned. 

Cells with undefined data are not output, nor are the prefix or suffix
strings. 

=cut

sub putcell {
    my $cells      = shift;	# ref to cell array
    my $c          = shift;	# index
    my $cell_width = shift;	# maximum width of the cell
    my $prefix     = shift;	# 2-elt array of prefix strings
    my $suffix     = shift;	# 2-elt array of suffix strings
    my $wrap_flag  = shift;	# non-zero for wrapped lines
    my $more;

    my $v = $cells->[$c];	# get the data
    my $px = 0;			# prefix index
    my $sx = 0;			# suffix index
    if (defined $v) {		# not undef data?
	my $text = $v;		# save the text
        $cell_width = 1 if !defined($cell_width) || $cell_width == 0;
	if ($cell_width <= length($text)) {
	    $more = substr($text,$cell_width);
	    $v = substr($text,0,$cell_width);
	} else {
	    $v = $text; $more = '';
	}

	# wrapping?
	if ($more ne '' &&

	    # See if we can wrap on a word boundary, instead of 
	    # arbitrarily splitting one; note that we try to not 
	    # split grouped numbers (1,345) or reals (1.234).

	    $v =~ /([-,;? \t])([^-,;? \t0-9]*)$/ && 

	    # but also make sure that it is not too long

	    length($2) <= $List_Wrap_Margin ) 
	{

	    # Okay, cut on the word boundary, leaving the break char
	    # on the tail end of the current output value

	    my $cut = $cell_width - length($2);
	    $v = substr($text,0,$cut);		# get new value
	    $more = substr($text, $cut);	# new remainder
	}
	$cells->[$c] = $more;	# leave the rest for later
	$px = $wrap_flag != 0 && length($v) > 0;
	$sx = length($more) > 0;
    }
    my $fmt        = sprintf("%%s%%-%ds%%s",$cell_width);
    put $fmt,$prefix->[$px],$v,$suffix->[$sx];	# output something (could be blanks)
    $sx;			# leave wrapped flag
}

##############################

=head1 center 

Center a string within a given width.

S<  >I<$field> = B<center> I<$string>, I<$width>;

=cut

sub center {
    my($string,$width) = @_;
    $width = 0 if !defined($width);
    return $string if length($string) >= $width;
    my($pad) = int(($width - length($string))/2);	# pad left half
    my($center) = (' ' x $pad) . $string;
    $pad = $width - length($center);
    $center .= ' ' x $pad;	# pad right half
    $center;			# return with the centered string
}

##############################

=head1 max

Compute the maximum value from a list of values.

S<  >I<$max> = B<&max>( I<@values> );

=cut

sub max {
    my ($max) = shift;
    foreach (@_) { $max = $_ if $max < $_; }
    $max;
}

##############################

=head1 min

Compute the minum value from a list of values.

S<  >I<$min> = B<&min>( I<@values> );

=cut

sub min {
    my ($min) = shift;
    foreach (@_) { $min = $_ if $min > $_; }
    $min;
}

##############################

=head1 max_length

Compute the maximum length of a set of strings in an array reference.

S<  >I<$maxlength> = B<&max_length>( I<\@array_ref> );

=cut

sub max_length {
    my($aref) = shift;
    my(@lens) = map { length } @$aref;
    my($maxlen) = max( @lens );
    $maxlen;
}

##############################

=head1 htmltext

Translate regular text for output into an HTML document.  This means
certain characters, such as "&", ">", and "<" must be escaped. 

S<  >I<$output> = B<&htmltext>( I<$input> [, I<$allflag> ] );

If I<$allflag> is non-zero, then all characters are escaped.  Normally,
only the four HTML syntactic break characters are escaped.

=cut

# htmltext -- translate special text into HTML esacpes
sub htmltext {
    local($_) = shift;
    my $all = shift;
    return undef unless defined($_);
    s/&(?!(?:amp|quot|gt|lt|#\d+);)/&amp;/g; 
    s/\"/&quot;/g;
    s/>/&gt;/g;
    s/</\&lt;/g;
    if ($all) {
	s/ /\&#32;/g;
	s/\t/\&#09;/g;
    }
    $_;
}

##############################

=head1 out

Print text followed by a newline.

S<  >B<out> I<$fmt> [, I<@text> ];

=cut

sub out {
    my $fmt = shift;
    $fmt .= "\n" unless $fmt =~ /\n$/;
    printf STDOUT $fmt, @_;
}

##############################

=head1 put

Print text (without a trailing newline).

S<  >B<out> I<$fmt> [, I<@text> ];

=cut

sub put {
    printf STDOUT @_;
}

##############################

=head1 AUTHOR

Alan K. Stebbens <aks@stebbens.org>

=cut

=head1 BUGS

=over 10

=item *

Embedded HTML is how the user can insert formatting overrides.  However,
the HTML formatting techniques have not been given much consideration --
feel free to provide constructive feedback.

=back

=cut

#
1;
