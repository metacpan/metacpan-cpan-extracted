use v5.12;
use strict;
use warnings;

package Data::Validate::CSV;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Data::Validate::CSV::Cell;
use Data::Validate::CSV::Column;
use Data::Validate::CSV::MultiValueCell;
use Data::Validate::CSV::Note;
use Data::Validate::CSV::Row;
use Data::Validate::CSV::Schema;
use Data::Validate::CSV::SingleValueCell;
use Data::Validate::CSV::Table;
use Data::Validate::CSV::Types;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Validate::CSV - read and validate CSV

=head1 SYNOPSIS

CSV Schema (JSON):

  {
    "@context": "http://www.w3.org/ns/csvw",
    "url": "countries.csv",
    "tableSchema": {
      "columns": [{
        "name": "country",
        "datatype": { "base": "string", "length": 2 }
      },{
        "name": "country group",
        "datatype": "string"
      },{
        "name": "name (en)",
        "datatype": "string"
      },{
        "name": "name (fr)",
        "datatype": "string"
      },{
        "name": "name (de)",
        "datatype": "string"
      },{
        "name": "latitude",
        "datatype": { "base": "number", "maximum": 90, "minimum": -90 }
      },{
        "name": "longitude",
        "datatype": { "base": "number", "maximum": 180, "minimum": -180 }
      }]
    }
  }

CSV Data:

  "at","eu","Austria","Autriche","Österreich","47.6965545","13.34598005"
  "be","eu","Belgium","Belgique","Belgien","50.501045","4.47667405"
  "bg","eu","Bulgaria","Bulgarie","Bulgarien","42.72567375","25.4823218"

Perl:

  use Path::Tiny qw(path);
  use Data::Validate::CSV;
  
  my $table = Data::Validate::CSV::Table->new(
    schema     => path('countries.csv-metadata.json'),
    input      => path('countries.csv'),
    has_header => !!0,
  );
  
  while (my $row = $table->get_row) {
    for my $e (@{$row->errors}) {
      warn $e;
    }
    printf(
      "%s is at latitude %f, longitude %f.\n",
      $row->get("name (en)")->value,
      $row->get("latitude")->value,
      $row->get("longitude")->value,
    );
  }

=head1 DESCRIPTION

There's not really a lot of documentation right now.

Mostly there's three interfaces you need to know about: tables, rows,
and cells. (There are also columns, schemas, and notes, but for most
day-to-day usage, those can be considered internal implementation
details.)

=head2 Table interface

The table is constructed with the following attributes:

=over

=item C<< schema >>

A schema for the table. Can be a hashref, a JSON string, a scalar ref to
a JSON string, or a L<Path::Tiny> path to a file containing the schema.

=item C<< input >>

The CSV data for the table. Can be a filehandle, a scalar ref to a string
of data, or a L<Path::Tiny> path to a file.

=item C<< has_header >>

A boolean indicating whether the CSV contains a header row. This will be
used to supply any column names missing from the schema, and will be 
skipped from being returned by C<get_row>.

=item C<< reader >>

A coderef which, if given a filehandle, will return a parsed line of CSV.
The default is basically something like:

  sub { Text::CSV_XS->new->getline($_[0]) }

That's probably sufficient for most cases, but you may need to supply your
own reader for handling tab-delimited files.

=item C<< skip_rows >>

An integer, number of additional rows to skip I<before> the header.
Some CSV files contain a title or credit line. Defaults to 0.

=item C<< skip_rows_after_header >>

An integer, number of additional rows to skip I<after> the header.
Defaults to 0.

=back

The table provides the following methods:

=over

=item C<< get_row >>

Returns a row object for the next row of the table.

=item C<< all_rows >>

Gets all the rows as a list.

=item C<< row_count >>

The number of non-skipped, non-header lines read so far.

=back

=head2 Row interface

The rows returned by C<get_row> and C<all_rows> are blessed objects.
They provide the following methods:

=over

=item C<< raw_values >>

The values returned by L<Text::CSV_XS> without any further processing.

=item C<< values >>

The values returned by L<Text::CSV_XS>, processed by datatype. Date and
time datatypes will be reformatted from any CLDR-based format to ISO 8601.
Booleans using non-standard representations will be changed to "1" and "0".
Fields that have a separator defined will be split into an arrayref.
Numbers given as percentages will be divided by 100. And so forth.

=item C<< cells >>

Returns the same values as C<values> but wrapped in cell objects. The
following are equivalent:

  $row->values->[0];
  $row->cells->[0]->value;
  $row->[0];  # $row overloads @{}

Why fetch a cell instead of directly fetching the value? The cell object
offers a few other useful methods.

=item C<< get($name) >>

Gets a single cell from the row by its name. Names are defined in the
schema, or the header row if missing from the schema.

  $row->get("country")->value;

=item C<< row_number >>

The row number for this row in the table. Rows are numbered starting at
1. Headers and skipped rows are not counted.

=item C<< key_string >>

For tables that has a primary key, this returns a string formed by joining
together the primary key columns. It ought to be a unique identifier for this
row within the table, and if it is not, this will be raised as an error.

=item C<< errors >>

An arrayref of strings of errors associated with this row. This includes
data validation problems.

=back

=head2 Cell interface

It is possible to bypass using the cell interface and access cell values
directly from the rows, but if accessing cells, these are the methods they
provide:

=over

=item C<< raw_value >>

The value returned by L<Text::CSV_XS> without any further processing.

=item C<< value >>

The value returned by L<Text::CSV_XS>, processed by datatype.

=item C<< inflated_value >>

Like C<value> but inflates some values to blessed objects. Date and time
related datatypes will be returned as L<DateTime>, L<DateTime::Incomplete>,
or L<DateTime::Duration> objects. Booleans will be returned as
L<JSON::PP::Boolean> objects.

=item C<< row_number >>

The row number for the cell's parent row in the table. Rows are numbered
starting at 1. Headers and skipped rows are not counted.

=item C<< col_number >>

The column number of this cell within the parent row. Columns are numbered
starting at 1.

=item C<< datatype >>

The datatype for this cell as a hashref.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Data-Validate-CSV>.

=head1 SEE ALSO

L<https://www.w3.org/TR/2016/NOTE-tabular-data-primer-20160225/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

