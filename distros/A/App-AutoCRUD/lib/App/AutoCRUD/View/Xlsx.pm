package App::AutoCRUD::View::Xlsx;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';

use Excel::Writer::XLSX;
use namespace::clean -except => 'meta';

sub render {
  my ($self, $data, $context) = @_;

  # pseudo-filehandle to memory buffer
  open my $fh, '>', \my $str 
    or die "Failed to open filehandle: $!";

  # open excel file in memory
  my $workbook  = Excel::Writer::XLSX->new($fh);
  my $worksheet = $workbook->add_worksheet();

  # global Excel settings
  my $title_fmt    = $workbook->add_format(bold => 1, size => 13);
  my $sql_fmt      = $workbook->add_format(size => 9);
  my $colgroup_fmt = $workbook->add_format(bold => 1, align => 'center',
                                           border => 1, border_color => 'blue',
                                          );
  $worksheet->outline_settings(1, # visible
                               0, # symbols_below,
                               0, # symbols_right,
                               1, # auto_style
                               );

  # initial Excel rows (title and SQL request)
  my $table   = $data->{table};
  $worksheet->write(0, 0, "Selection from $table", $title_fmt);
  $worksheet->write(1, 0, $data->{criteria}, $sql_fmt);

  # handling column groups (header row and Excel outlines)
  my @headers;
  my $colgroup_row = 2;
  my $first_col = 0;
  my $last_col;
  foreach my $colgroup (@{$data->{colgroups}}) {
    my $cols = $colgroup->{columns};
    push @headers, map {$_->{COLUMN_NAME}} @$cols;
    $last_col = $first_col + @$cols - 1;
    if (@$cols > 1) { # this group contains several columns
      # create a merged cell containing the colgroup name
      $worksheet->merge_range($colgroup_row, $first_col,
                              $colgroup_row, $last_col,
                              $colgroup->{name}, $colgroup_fmt);
      # create an outline group
      $worksheet->set_column($first_col+1, $last_col, undef, undef, undef,
                             1, # outline level 1
                            );
    }
    else {            # this group contains just one column
      # just write the colgroup name into a single cell
      $worksheet->write($colgroup_row, $first_col,
                        $colgroup->{name}, $colgroup_fmt);
    }
    # prepare $first_col for next colgroup iteration
    $first_col = $last_col + 1;
  }

  # generate data table
  my $rows    = $data->{rows};
  my $n_rows  = @$rows;
  my $n_cols  = @headers;
  $worksheet->add_table(3, 0, $n_rows + 3, $n_cols-1, {
    data       => [ map {[@{$_}{@headers}]} @$rows ],
    columns    => [ map { {header => $_}} @headers ],
    autofilter => 1,
   });
  $worksheet->freeze_panes(4, 0);

  # finalize the workbook
  $workbook->close();

  # return Plack response
  my @http_headers = (
    'Content-type'        => 'application/xlsx',
    'Content-disposition' => qq{attachment; filename="$table.xlsx"},
   );
  return [200, \@http_headers, [$str] ];
}


1;


__END__



