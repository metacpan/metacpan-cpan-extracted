package App::diff_spreadsheets;

our $DATE = '2023-04-07'; # DATE
our $VERSION = '1.004'; # VERSION

1;

# ABSTRACT: Diff spreadsheets (or CSVs) showing changed cells

__END__

=pod

=encoding UTF-8

=head1 NAME

diff_spreadsheets - show differences between spreadsheets

=head1 SYNOPSIS

diff_spreadsheets [OPTIONS] file1.csv file2.xlsx!Sheet1 

diff_spreadsheets [OPTIONS] file1.xls file2.ods  # all coresponding sheets

=head1 DESCRIPTION

The files may be CSVs or any spreadsheet format supported by
Gnumeric or Open/Libre Office (if you have them installed).

If each input has only one sheet then they are compared regardless
of sheet names.  Each file could be a .CSV, a spreadsheet workbook
containing a single sheet, or a multi-sheet workbook with a
sheet name specified (using the syntax shown).

Otherwise, I<every> sheet contained in each workbook is comapred with the
same-named sheet in the other file, warning about any un-paired sheets.
This feature is available
only if the Gnumeric I<ssconvert> utility is installed.

Tabs, newlines, etc. and non-printable characters are replaced with
escapes like "\t" or "\n" for human consumption.

=head1 OPTIONS

=head2 -m --method [native|diff|tkdiff]

I<native> (the default) shows only the changed I<cells> in rows which
differ.   Corresponding columns are identified by title,
and need not be in the same order (see also the C<--id-columns> option).

I<diff>, and I<tkdiff> run the indicated external tool on
temporary text (CSV) files created from the inputs, in which ignored columns
have been removed and non-graphic characters changed to escapes.
Most diff(1) options are accepted and passed through, but are not
documented here.

I<git> and I<gitchars> use C<git diff> with options to color-code
the changed parts within changed lines.  I<git> shows words which were
added in C<file2> in green and deleted words in red.  I<gitchars> highlights
individual characters.  These are the defaults; most git(1) diff options
are accepted and passed through, such as --word-diff-regex.

=head2 --title-row [ROWNUMBER]

The row number containing column titles (first==1).
Auto-detected by default if the choice is obvious.
Specify zero if there are no titles.

=head2 --columns COLSPEC[,COLSPEC ...]

=head2 --columns -COLSPEC[,-COLSPEC ...]

Ignore differences in certain columns.

In the first form (not negated), the specified columns are used for
comparisons and others are ignored when deciding if a row changed.

If COLSPECs are negated (prefixed by "-"), then those columns are
ignored when deciding if a row changed.

COLSPEC may be a column title, a /regex/ or m{regex} matching a title,
a column letter code (A, B, etc.), or an identifer
as described in L<Spreadsheet::Edit>.


=head2 The following options apply only to the I<native> method:

=head2

=head2 Differences are reported in one of three ways:

  1) An existing row was changed;
  2) A new row was inserted; or
  3) A existing row was deleted.

=head2 --id-columns COLSPEC[,COLSPEC ...]

Specify columns which together uniquely identify records (i.e. rows).
An error occurs if multiple rows exist in the same file with identical
content in these columns.  

This is used to recognized when a row is changed vs. added or deleted.

When a pair of rows in the two files match in these columns,
differences in other columns are reported as "changes" to the record.
A row in the first file without a counterpart in the second file
is reported as "deleted", and a row in the second file without a counterpart
in the first is reported as "inserted".

Gory detail: The Diff algorithm is applied using I<only> the C<id-column>s;
matching rows are assumed to correspond, and the other columns are
then compared and a "change" is reported if there are differences.
If --id-columns is not used, the Diff algorithm is applied using all
columns, and can get temporarily out of sync;
if a row was inserted or deleted adjacent to other rows
which were merely changed,
the result can be a string of "changed" reports which
actually describe pairs of unrelated records.

For even more control, see the B<--hashid-func> option.

=head2 --always-show COLSPEC[,COLSPEC ...]

By default only changed cells are displayed.  
However cells from C<--always-show>, or if not specified then C<--id-columns>,
are always shown even if unchanged.

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
and then I<hash-func> is used to determine if a corresponding pair has
reportable changes.

Specifically, I<hashid-func> is called for each row
passing values from C<--id-column> (or if
not specified then all columns).  If undef is returned
then that row is ignored.  If the same string is returned for a pair of
rows from the two files then I<hash-func> is later used to determine if
there are reportable changes.  If a unique string is returned,
i.e. there is no corresponding row in the other file, then that row
will be reported as "deleted" or "inserted" and I<hash-func> is not
used for that row.

When I<hash-func> is called, it is passed I<all> cells in a row (or those
specified with C<--columns>).  If the result is different for
corresponding rows then a single "change" is reported.

Argument order: Cell values are always passed I<in the order they appear
in the first file>.  When called with a row from the first file then this is
simply the order of columns in that file; when called with a row from the
second file, then columns which also exist in the first file are passed
in the order they appear in the first file, followed by any columns which exist
only in second file in their natural order.

If there are no titles then all columns are passed in their natural order.

=head2 --setup-code PERLCODE

Allows arbitrary initialization, possibly editing the data in memory
or declaring global variables (with C<our>) to be later used by
C<--hashid-func> or C<--hash-func> subs.

The setup sub is called with parameters
($sheet1, $sheet2, \@idcxlist1, \@idcxlist2);

All user-defined PERLCODE subs are compiled into the same package.

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

=head1 BUGS

A bug in Libre Office (and Open Office) prevents reading spreadsheets
if the user has any document open, even unrelated.  This problem does
not occur if gnumeric is installed, or when reading CSVs.

=head1 SEE ALSO

L<Spreadsheet::Edit>, L<Sreadsheet::Edit::IO>

=head1 AUTHOR

Jim Avera (jim.avera [at] gmail)

=head1 LICENSE

GPL2

=cut
