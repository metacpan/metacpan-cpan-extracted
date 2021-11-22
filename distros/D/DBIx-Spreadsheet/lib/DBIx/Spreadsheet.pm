#!perl
package DBIx::Spreadsheet;
use strict;
use DBI;
use Getopt::Long;
use Spreadsheet::Read;
use Text::CleanFragment;

use Moo 2;

use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.01';

=head1 NAME

DBIx::Spreadsheet - Query a spreadsheet with SQL

=head1 SYNOPSIS

  my $sheet = DBIx::Spreadsheet->new( file => 'workbook.xlsx' );
  my $dbh = $sheet->dbh;

  my @rows = $dbh->selectall_arrayref(<<'SQL');
      select *
        from sheet_1
       where foo = 'bar'
  SQL

This module reads a workbook and makes the contained spreadsheets available
as tables. It assumes that the first row of a spreadsheet are the column
names. Empty column names will be replaced by C<col_$number>. The sheet and
column names will be sanitized by L<Text::CleanFragment> so they are
conveniently usable.

=head1 WARNING

The parsing and reformatting of cell values is very hacky. Don't expect
too much consistency between C<ods> and C<xlsx> cell formats. I try to
make these consistent, but this is currently a pile of value-specific hacks.

=head1 METHODS

=head2 C<< DBIx::Spreadsheet->new >>

  my $wb = DBIx::Spreadsheet->new(
      file => 'workboook.ods',
  );

=head3 Options

=over 4

=item *

B<file> - name of the workbook file. The file will be read using L<Spreadsheet::Read>
using the options in C<spreadsheet_options>.

=cut

has 'file' => (
    is => 'ro',
);

=item *

B<spreadsheet> - a premade L<Spreadsheet::Read> object

=cut

has 'spreadsheet' => (
    is => 'lazy',
    default => \&_read_file,
);

=item *

B<spreadsheet_options> - options for the L<Spreadsheet::Read> object

=back

=cut

has 'spreadsheet_options' => (
    is => 'lazy',
    default => sub { {
        dtfmt => 'yyyy-mm-dd',
    } },
);

=head2 C<< ->dbh >>

  my $dbh = $wb->dbh;

Returns the database handle to access the sheets.

=cut

has 'dbh' => (
    is => 'lazy',
    default => sub( $self ) { $self->_import_data; $self->{dbh} },
);

=head2 C<< ->tables >>

  my $tables = $wb->tables;

Arrayref containing the names of the tables. These are usually the names
of the sheets.

=cut

has 'tables' => (
    is => 'lazy',
    default => sub( $self ) { $self->_import_data; $self->{tables} },
);

sub _read_file( $self, $filename=$self->file ) {
    return
        Spreadsheet::Read->new(
            $filename,
            attr => 1,
            %{ $self->spreadsheet_options }
        );
};

our $table_000;

our %charmap = (
    '+' => 'plus',
    '%' => 'perc',
);

sub gen_colname( $self, $org_name, $colposition=1, $seen={} ) {
    $org_name = !defined($org_name) ? "" : $org_name;

    my $name = $org_name;

    my $chars = quotemeta join "", sort keys %charmap;
    $name =~ s/([$chars])/_$charmap{ $1 }_/g; # replace + and % with names
    $name =~ s/([-.])/_/g;                # replace . and - to _
    $name = clean_fragment( $name );

    if( $org_name =~ /^\s*$/ or $name =~ /^\s*$/ ) {
        $name = sprintf "col_%d", $colposition;
    };

    # Welcome quadratical complexity. If you look at this line for performance
    # reasons, this, together with the call from ->gen_colnames implies that
    # we have quadratical runtime on the number of colliding column names. This
    # will happen especially if there is a named column inserted before unnamed
    # columns, and that named column collides with the generated name of an
    # unnamed column. So don't do that.
    my $counter = 1;
    if( $seen->{ $name }) {
        my $newname = $name .= "_" . ($counter++);
        while( $seen->{ $newname }) {
            $newname = $name .= "_" . ($counter++);
        };
        $name = $newname;
    };
    return $name
}

sub gen_tablename( $self, $org_name, $seen={}) {
    $self->gen_colname( $org_name, 0, $seen );
}

sub gen_colnames( $self, @colnames ) {
    my %seen;
    my $i = 1;
    my @res;
    for my $name (@colnames) {
        $name = $self->gen_colname( $name, $i++, \%seen );
        $seen{ $name }++;
        push @res, qq("$name");
    };
    return @res
}

# The nasty fixup until I clean up Spreadsheet::ReadSXC to allow for the raw
# values
sub nasty_cell_fixup( $self, $value, $source_type, $attr ) {
    return $value if ! defined $value;
# use Data::Dumper; $Data::Dumper::Useqq = 1;

    # We treat the different spreadsheet sources differently. This should
    # become more feature-oriented, like:
    # if( xlsx ) { +reformat_date_from_excel_date, +reformat_number

    my $t = $attr->{type} // '';
    my $f = $attr->{format} // '';

    if( $source_type eq 'xlsx' ) {
        if( $f =~ m!DD! ) {
            # it's still a date, no matter what the type says
            $t = 'date';
        };

        if( $t eq 'date' ) {
            # Reformat the Excel-date (number of days since 1900-01-01
            require Spreadsheet::ParseExcel::Utility;

            $value = Spreadsheet::ParseExcel::Utility::ExcelFmt( 'yyyy-mm-dd', $value );

        } elsif(    $t eq 'currency') {
            # Hard-format back to random currency format, as that's
            # what I have. This should rather be a string operation
            $value = sprintf '%0.2f', $value;

        } elsif( $t eq 'numeric' and $f =~ m!\.00!) {
            # Hard-format back to random currency format, as that's
            # what I have. This should rather be a string operation
            $value = sprintf '%0.2f', $value;
        }

    } elsif( $source_type eq 'ods' ) {
        # Fix up German locale formatted numbers, as that's what I have
        if(     $t eq 'currency') {
            if( $value =~ /^([+-]?)([0-9\.]+(,\d+))?(\s*\x{20ac}|€)?$/ ) {
                # Fix up formatted number
                $value =~ s![^\d\.\,+-]!!g;
                $value =~ s!\.!!g;
                $value =~ s!,!.!g;
            };

            # Hard-format back to random currency format, as that's
            # what I have. This should rather be a string operation
            $value = sprintf '%0.2f', $value;

        # Fix up  German locale formatted dates, as that's what I have
        } elsif(     $t eq 'date'
                 and $value =~ /^([0123]?\d)\.([01]\d)\.(\d\d)$/ ) {
            $value = "20$3-$2-$1";

        # Fix up  German locale formatted dates, as that's what I have
        } elsif(     $t eq 'date'
                 and $value =~ /^([0123]?\d)\.([01]\d)\.(20\d\d)$/ ) {
            $value = "$3-$2-$1";
        }
    } else {
        # Don't know
        die "Unknown spreadsheet type '$source_type'";
    }


    return $value
}

our $month_num = qr!(?<month>0?[1-9]|1[012])!x;
our $month     = qr!($month_num|[A-Z][a-z]{2})!x;
our $day_num2  = qr!(?<day>0[1-9]|1[0-9]|2[0-9]|3[01])!x;
our $day       = qr!(?<day>[1-9]|$day_num2)!x;
our $year      = qr!(?<year>[1-9]\d|[1-9]\d\d\d)!x;
our $looks_like_date =
    qr!^\s*(
           |(?:$month     \s* /  \s* $day       \s* /  \s* $year)
           |(?:$month     \s* -  \s* $day       \s* -  \s* $year)
           |(?:$day_num2  \s* \. \s* $month     \s* \. \s* $year)
           |(?:$year      \s* -? \s* $month_num \s* -? \s* $day_num2 )
        )\s*$!x;

sub import_data( $self, $book ) {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:',undef,undef,{AutoCommit => 1, RaiseError => 1,PrintError => 0});
    $dbh->sqlite_create_module(perl => "DBD::SQLite::VirtualTable::PerlData");

    my @tables;
    my $i = 0;
    my %seen;
    for my $table_name ($book->sheets) {
        my $sheet = $book->sheet( $table_name );

        # We could try to identify the column types here more closely
        my $source_type = $book->[0]->{type}
            or die "No spreadsheet type found in spreadsheet?!";

        my $data = [map {
                      my $rownum = $_;
                      my @row = map {
                          my $v;
                          if( $rownum == 1 ) {
                              # This is a column heading
                              $v = $sheet->cell($_,$rownum);
                          } else {
                              my $c = $_;
                              # unformatted
                              $v = $sheet->cell($c,$rownum);
                              my $a;
                              if( defined $sheet->{attr}->[$c]->[$rownum]) {
                                  $a = $sheet->attr($c,$rownum);
                              };
                              $v = $self->nasty_cell_fixup( $v, $source_type, $a );

                              # use formatted if things look like a date
                              #my $label = Spreadsheet::Read::cr2cell($_,$rownum);
                              #my $fv = $sheet->cell($label);
                              #
                              #if( defined $v ) {
                              #    if( $v =~ /^\d+$/ and $fv =~ m!$looks_like_date! ) {
                              #        $v = $fv
                              #    };
                              #};
                          }
                          $v
                        } 1..$sheet->maxcol;

                      \@row
                    } 1..$sheet->maxrow ];
        #my $data = [$sheet->rows($_)];
        my $colnames = shift @{$data};

        my $sql_name = $self->gen_tablename( $table_name, \%seen );

        # Fix up duplicate columns, empty column names
        $colnames = join ",", $self->gen_colnames( @$colnames );
        {;
            #no strict 'refs';
            # Later, find the first non-empty row, instead of blindly taking the first row
            #${main::}{$tablevar} = \$data;
        };
        local $table_000 = $data;
        my $tablevar = __PACKAGE__ . '::table_000';
        my $sql = qq(CREATE VIRTUAL TABLE temp."$sql_name" USING perl($colnames, arrayrefs="$tablevar"););
        $dbh->do($sql);
        push @tables, { sheet => $table_name, table => $sql_name };
    };

    return $dbh, \@tables;
}

=head2 C<< ->table_names >>

  print "The sheets are available as\n";
  for my $mapping ($foo->table_names) {
      printf "Sheet: %s Table name: %s\n", $mapping->{sheet}, $mapping->{table};
  };

Returns the mapping of sheet names and generated/cleaned-up table names.
This may be convenient if you want to help your users find the table names that
they can use.

If you want to list all available table names, consider using the L<DBI>
catalog methods instead:

  my $table_names = $dbh->table_info(undef,"TABLE,VIEW",undef,undef)
                        ->fetchall_arrayref(Slice => {});
  print $_->{TABLE_NAME}, "\n"
      for @$table_names;

=cut

sub table_names( $self ) {
    @{ $self->tables }
}

sub _import_data( $self ) {
    my( $dbh, $tables ) = $self->import_data( $self->spreadsheet );
    $self->{dbh} = $dbh;
    $self->{tables} = $tables;
}

1;

=head1 SUPPORTED FILE TYPES

This module supports the same file types as L<Spreadsheet::Read>. The following
modules need to be installed to read the various file types:

=over 4

=item *

L<Text::CSV_XS> - CSV files

=item *

L<Spreadsheet::ParseXLS> - Excel XLS files

=item *

L<Spreadsheet::ParseXLSX> - Excel XLSX files

=item *

L<Spreadsheet::ParseSXC> - Staroffice / Libre Office SXC or ODS files

=back

=head1 TO DO

=over 4

=item *

Create DBD so direct usage with L<DBI> becomes possible

  my $dbh = DBI->connect('dbi:Spreadsheet:filename=workbook.xlsx,start_row=2');

DBIx::Spreadsheet will provide the underlying glue.

=back

=head1 SEE ALSO

L<DBD::CSV>

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/DBIx-Spreadsheet>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Spreadsheet>
or via mail to L<dbix-spreadsheet-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
