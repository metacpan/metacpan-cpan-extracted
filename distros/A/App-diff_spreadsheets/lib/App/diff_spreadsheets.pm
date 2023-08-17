# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and 
# related or neighboring rights to the content of this file.  
# Attribution is requested but is not required.

package App::diff_spreadsheets;

our $DATE = '2023-07-03'; # DATE
our $VERSION = '1.017'; # VERSION

1;

# ABSTRACT: Diff spreadsheets or CSVs showing changed cells

__END__

=pod

=encoding UTF-8

=head1 NAME

diff_spreadsheets - show differences between spreadsheets/csvs readably

=head1 SYNOPSIS

diff_spreadsheets [OPTIONS] file1.csv file2.xlsx!Sheet1 

diff_spreadsheets [OPTIONS] file1.xls file2.ods  # all coresponding sheets

=head1 DESCRIPTION

CSV files may be always used.  Spreadsheets may be used if 
Libre Office 7.2 or later is installed.

If each input has only one sheet then they are compared regardless
of sheet names.  Each file could be a .CSV, a spreadsheet workbook
containing a single sheet, or a multi-sheet workbook with a
sheet name specified (using the syntax shown).

Otherwise, I<every> sheet contained in each workbook is comapred with the
same-named sheet in the other file, warning about any un-paired sheets.

Tabs, newlines, etc. and non-printable characters are replaced with
escapes like "\t" or "\n" for human consumption.

=head1 OPTIONS

=head2 -m --method [native | diff | tkdiff | git]

I<native> (the default) shows only the changed I<cells> in rows which
differ.   Corresponding columns are identified by title,
and need not be in the same order 
(see also C<--id-columns>).

I<diff>, I<tkdiff>, or I<git> run an external tool on
temporary text (CSV) files created from the inputs, in which ignored columns
have been removed and non-graphic characters changed to escapes.

Most diff(1) options are accepted and passed through, but are not
documented here.

I<git> uses C<git diff> to, by default, color-code changed words;
most git(1) diff options are passed through.

=head2 --title-row [ROWNUMBER]

The row number containing column titles (first==1).
Auto-detected by default if the choice is obvious.
Specify zero if there are no titles.

=head2 --columns COLSPEC[,COLSPEC ...]

=head2 --columns -COLSPEC[,-COLSPEC ...]

Ignore differences in certain columns.

In the first form (not negated), the specified columns are used for
comparisons and others are ignored when deciding if a row changed.
When negated ("-" prefix) the specified columns are ignored.

I<COLSPEC> may be a column title, a /regex/ or m{regex} matching 
one or more titles, a column letter code (A, B, etc.), or an identifer
as described in L<Spreadsheet::Edit>.

=head2 --id-columns COLSPEC[,COLSPEC ...] 

Specify columns which together uniquely B<identify records> (i.e. rows).

Before running any "diff" operation, the data rows in each file are
sorted on the specified columns (comparison is alphabetic), so
that corresponding rows are in the same relative vertical position
in each file.  This makes it more likely that a change 
is detected as a CHANGE and not as confusing separate DELETE and INSERT.

B<C<--no-sort-rows>> disables this sorting so you can pre-sort the
data yourself (for example, if "id columns" should be sorted
numerically).

When using the default "native" diff algorithm, the I<original>
row numbers in each file are displayed in the results, hiding
the effects of sorting.

The "native" algorithm always displays the values of the "id" columns
in changed rows.

=head2 The following options apply only to the 'native' method:


=head2 --always-show COLSPEC[,COLSPEC ...]

When a changed row is displayed the changed cells are shown
plus all cells implied by C<--id-columns> whether changed or not.

The C<--always-show> option supplies an alternative set of columns
to always show instead of those given by C<--id-columns>.  The input
data is still sorted using C<--id-columns>.

=head2 Gory internals of the native diff method

The Diff algorithm is first applied using I<only> the C<id-column>s;
matching rows are assumed to correspond, and the other columns are
then compared and a "change" is reported if there are differences.
If --id-columns is not used, the Diff algorithm is applied using all
columns, and can get temporarily out of sync;
if a row was inserted or deleted adjacent to other rows
which were merely changed,
the result can be a string of "changed" reports which
actually describe pairs of unrelated records.

For even more control, see the B<--hashid-func> option.

=head2 --hashid-func PERLCODE

=head2 --hash-func PERLCODE

These options allow arbitrary filtering of row data before use.
PERLCODE must be an anonymous C<sub> declaration which is called with
two arguments for each row:

  ([cells], $row_index)

and must return a string representing those values, or undef
to ignore the row.

Both default to

  sub { join ",", @{$_[0]} }  # concatenate all cells separated by commas

During the Diff algorithm, I<hashid-func> is used to identify
pairs of rows which represent the same data record,
and then I<hash-func> is used to determine if a pair has
reportable changes.

Specifically: I<hashid-func> is called for each row
passing only values from C<--id-column> (or if
not specified then all columns).  
If undef is returned then that row is ignored.  

If the B<same> string is returned for a pair of
rows from the two files then any reportable differences are shown
as a "change" to the record. I<hash-func> is later called to determine
if there are reportable changes.  

If a B<unique> string is returned by I<hashid_func>,
i.e. there is no corresponding row in the other file, then that row
will be reported as "deleted" or "inserted" and I<hash-func> is not
used for that row.

When I<hash-func> is called it is passed I<all> cells in a row (or those
specified with C<--columns>).  If the result is different for
corresponding rows then a "change" is reported.

B<Argument order:>
When called with a row from the first file, cell values are passed in their natural order;
when called with a row from the second file, 
columns which also exist in the first file are passed first, 
I<in the order they appear in the first file>, 
followed by any columns which exist only in the second file.

If there are no titles then all columns are passed in their natural order.

=for notnow =head2 --setup-code PERLCODE
=for notnow 
=for notnow Allows arbitrary initialization, possibly editing the data in memory
=for notnow or declaring global variables (with C<our>) to be later used by
=for notnow C<--hashid-func> or C<--hash-func> subs.
=for notnow 
=for notnow The setup sub is called with parameters
=for notnow ($sheet1, $sheet2, \@idcxlist1, \@idcxlist2);

The user-defined PERLCODE subs are compiled into the same package.

=head2 --quote-char CHARACTER   (default is ")

=head2 --sep-char CHARACTER     (default is ,)

=head2 --encoding ENCODING      (default is UTF-8)

Used when reading CSV files (see L<Text::CSV>).  The same options are
applied to both input files.

=head2 --quiet

=head2 --verbose

=head2 --debug

=head2 --keep-temps

=head2 -h --help

Probably what you expect.

=head1 SEE ALSO

L<Spreadsheet::Edit>, L<Sreadsheet::Edit::IO>

=head1 AUTHOR

Jim Avera (jim.avera  gmail)

=head1 LICENSE

CC0 1.0 / Public Domain

=cut
