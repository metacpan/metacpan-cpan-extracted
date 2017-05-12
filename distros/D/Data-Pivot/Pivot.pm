package Data::Pivot;

#---------------------------------------------------------------------------------------------------------------------

=head1 NAME

Data::Pivot - Perl module to pivot a table

=head1 SYNOPSIS

  use Data::Pivot;
  @newtable = pivot( table        => \@table,
                     headings     => \@headings,
                     pivot_column => $pivot_col_no,
                     layout       => 'vertical',
                     row_sum      => 'Sum',
                     row_titles   => 1,
                     format       => '%5.2f',
                   )

=head1 DESCRIPTION

With Data::Pivot you can pivot a table like this:

 Some    Fix   Columns      Pivot_Col     Num_Values

 aaa     bbb   ccc          01              12.20
 aaa     bbb   ccc          02             134.50
 aaa     bbb   ccc          03               1.25
 xxx     yyy   zzz          02              22.22
 xxx     yyy   zzz          03             111.11

Will be converted to:

 Some    Fix   Columns       01       02       03       Sum

 aaa     bbb   ccc          12.20   134.50     1.25   147.95
 yyy     xxx   zzz           0.00    22.22   111.11   133.33

The table can contain several columns of Num_Values, which will get into rows, if the layout is 'horizontal', like this:

 Some    Fix   Columns      Pivot_Col     Num_Val_1    Num_Val_2   Num_Val_3

 aaa     bbb   ccc          01              12.20         1.40         5.90
 aaa     bbb   ccc          02             134.50        12.00        12.30
 aaa     bbb   ccc          03               1.25        30.00       123.45
 xxx     yyy   zzz          02              22.22         7.80         8.88
 xxx     yyy   zzz          03             111.11       100.00        42.00

Will be converted to:

 Some    Fix   Columns                    01       02       03       Sum

 aaa     bbb     ccc     Num_Val_1       12.20   134.50     1.25   147.95
                         Num_Val_2        1.40    12.00    30.00    43.40
                         Num_Val_3        5.90    12.30   123.45   141.65
 xxx     yyy     zzz     Num_Val_1        0.00    22.22   111.11   133.33
                         Num_Val_2        0.00     7.80   100.00   107.80
                         Num_Val_3        0.00     8.88    42.00    50.88

Data::Pivot has only one function which does all the work.

=head1 Functions

=head2 pivot()

=head2 Parameters:

pivot receives several named parameters:

=over

=item table => \@table

A reference to an array of arrays containing all the data but no headings.

In the last example above:

 @table = ( [ 'aaa', 'bbb', 'ccc', '01', 12.2, 1.4, 5.9 ],
            [ 'aaa', 'bbb', 'ccc', '02', 134.5, 12, 12.3 ],
            [ 'aaa', 'bbb', 'ccc', '03', 1.25, 30, 123.45 ],
            [ 'xxx', 'yyy', 'zzz', '02', 22.22, 7.8, 8.88 ],
            [ 'xxx', 'yyy', 'zzz', '03', 111.11, 100, 42 ]
          );

=item headings => \@headings

A reference to an array containing the column headings.

In the last example above:

 @headings = ('Some', 'Fix', 'Columns', 'Pivot_Col', 'Num_Val_1', 'Num_Val_2', 'Num_Val_3');

=item pivot_column => $no_of_col

The column number over which the pivoting takes place

In the last example above:

 $no_of_col = 3;

=item layout => 'horizontal'

'layout' determines whether the 'Num_Val' columns are arranged 'horizontal'ly or 'vertical'ly in the new table.

=item row_sum => 'Sum'

The title of the sum column, which sums up the new pivoted columns. If this is undef the column will be omitted.

=item row_title1 => 1

If this is true, a new column will be inserted after the fix columns if the layout is 'horizontal'. This column will have no heading and the contents will be the headings of the value columns.

=item format => '%5.2f'

Format may be a legal sprintf format string or a reference to a subroutine.
The format string will be applied to each pivoted column and the sum column.
The subroutine will be called with each pivoted column and the sum column as parameter.

=back

The full function call for the above example is:

 @newtable = pivot( table => \@table,
                    headings     => \@headings,
                    pivot_column => $pivot_col_no,
                    row_sum      => 'Sum',
                    row_titles   => 1,
                    format       => '%5.2f',
                  );


=cut

use 5.005;
use strict;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT);

require Exporter;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
  pivot
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
  pivot
);
$VERSION = '0.05';

#---------------------------------------------------------------------------------------------------------------------

sub pivot {
  my %parms = @_;

  if (exists $parms{layout} and $parms{layout} eq 'vertical') {
    return pivot_vertical(@_);
  } else {
    return pivot_horizontal(@_);
  }
}

#---------------------------------------------------------------------------------------------------------------------

sub pivot_horizontal {
  my %parms = @_;

  my $table        = $parms{table};
  my $headings     = $parms{headings};
  my $pivot_column = $parms{pivot_column};
  my $row_sum      = $parms{row_sum};
  my $row_titles   = $parms{row_titles};
  my $format       = $parms{format};


  my @sum_columns  = $pivot_column + 1 .. $#$headings;
  my $flatrow;
  my $oldflatrow = '';
  my %pivot_cols;
  my $lastrow;
  my @newtable;

#---- initialise %pivot_cols
#
  foreach my $row (@$table) {
    $pivot_cols{$row->[$pivot_column]} ||= [ (0) x @sum_columns ];
  }

#---- read table line by line
#
  foreach my $row (@$table) {
    $flatrow = join '', @{$row}[0..$pivot_column - 1];

    if ($flatrow ne $oldflatrow && $lastrow) {
      foreach my $pivot_row (0..$#sum_columns) {
        my @newrow;
        if (!$pivot_row) {
          splice @$lastrow, $pivot_column;
          @newrow = @$lastrow;
        } else {
          @newrow = ('') x @$lastrow;
        }
        push @newrow, $headings->[$sum_columns[$pivot_row]] if $row_titles;

  #---- sums for each row
  #
        my $rowsum = 0;
        foreach (keys %pivot_cols) {
          $rowsum += $pivot_cols{$_}->[$pivot_row];
        }

  #---- create new row
  #
        if ($format) {
          if (ref $format eq 'CODE') {
            push @newrow, (map({ $format->($pivot_cols{$_}->[$pivot_row]) } sort keys %pivot_cols), $row_sum ? $format->($rowsum) : ());
          } else {
            push @newrow, (map({ sprintf($format, $pivot_cols{$_}->[$pivot_row]) } sort keys %pivot_cols), $row_sum ? sprintf($format, $rowsum) : ());
          }
        } else {
          push @newrow, (map({ $pivot_cols{$_}->[$pivot_row] } sort keys %pivot_cols), $row_sum ? $rowsum : ());
        }
        push @newtable, \@newrow;
      }

  #---- initialise %pivot_cols
  #
      $pivot_cols{$_} = [ (0) x @sum_columns ] for (keys %pivot_cols);
    }

    foreach (0..$#sum_columns) {
      $pivot_cols{$row->[$pivot_column]}->[$_] = $row->[$sum_columns[$_]];
    }

    $lastrow = $row;
    $oldflatrow = $flatrow;
  }
  if ($lastrow) {
    foreach my $pivot_row (0..$#sum_columns) {
      my @newrow;
      if (!$pivot_row) {
        splice @$lastrow, $pivot_column;
        @newrow = @$lastrow;
      } else {
        @newrow = ('') x @$lastrow;
      }
      push @newrow, $headings->[$sum_columns[$pivot_row]] if $row_titles;

      my $rowsum = 0;
      foreach (keys %pivot_cols) {
        $rowsum += $pivot_cols{$_}->[$pivot_row];
      }
      if ($format) {
        if (ref $format eq 'CODE') {
          push @newrow, (map({ $format->($pivot_cols{$_}->[$pivot_row]) } sort keys %pivot_cols), $row_sum ? $format->($rowsum) : ());
        } else {
          push @newrow, (map({ sprintf($format, $pivot_cols{$_}->[$pivot_row]) } sort keys %pivot_cols), $row_sum ? sprintf($format, $rowsum) : ());
        }
      } else {
        push @newrow, (map({ $pivot_cols{$_}->[$pivot_row] } sort keys %pivot_cols), $row_sum ? $rowsum : ());
      }
      push @newtable, \@newrow;
    }
  }

  splice @$headings, $pivot_column, @sum_columns + 1, ($row_titles ? '' : (), (sort keys %pivot_cols), $row_sum ? $row_sum : ());
  return @newtable;
}

#---------------------------------------------------------------------------------------------------------------------

sub pivot_vertical {
  my %parms = @_;

  my $table        = $parms{table};
  my $headings     = $parms{headings};
  my $pivot_column = $parms{pivot_column};
  my $row_sum      = 0;
  my $row_titles   = $parms{row_titles};
  my $format       = $parms{format};


  my @sum_columns  = $pivot_column + 1 .. $#$headings;
  my $flatrow;
  my $oldflatrow = '';
  my %pivot_cols;
  my $lastrow;
  my @newtable;

#---- initialise %pivot_cols
#
  foreach my $row (@$table) {
    foreach (@sum_columns) {
      $pivot_cols{$row->[$pivot_column] . sprintf('<<<%03d>>>', $_) . $headings->[$_]} ||= 0;
    }
  }

#---- read table line by line
#
  foreach my $row (@$table) {
    $flatrow = join '', @{$row}[0..$pivot_column - 1];

    if ($flatrow ne $oldflatrow && $lastrow) {
      my @newrow;

  #---- create new row
  #
      if ($format) {
        if (ref $format eq 'CODE') {
          push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ $format->($pivot_cols{$_}) } sort keys %pivot_cols));
        } else {
          push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ sprintf($format, $pivot_cols{$_}) } sort keys %pivot_cols));
        }
      } else {
        push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ $pivot_cols{$_} } sort keys %pivot_cols));
      }
      push @newtable, \@newrow;

  #---- initialise %pivot_cols
  #
      $pivot_cols{$_} = 0 for (keys %pivot_cols);
    }

    foreach (@sum_columns) {
      $pivot_cols{$row->[$pivot_column] . sprintf('<<<%03d>>>', $_) . $headings->[$_]} = $row->[$_];
    }

    $lastrow = $row;
    $oldflatrow = $flatrow;
  }
  if ($lastrow) {
    my @newrow;

    if ($format) {
      if (ref $format eq 'CODE') {
        push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ $format->($pivot_cols{$_}) } sort keys %pivot_cols));
      } else {
        push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ sprintf($format, $pivot_cols{$_}) } sort keys %pivot_cols));
      }
    } else {
      push @newrow, (@{$lastrow}[0..$pivot_column - 1], map({ $pivot_cols{$_} } sort keys %pivot_cols));
    }
    push @newtable, \@newrow;
  }

  splice @$headings, $pivot_column, @sum_columns + 1, (map {s/(.*?)<<<\d+>>>(.*)/$2 $1/; $_} sort keys %pivot_cols);
  return @newtable;
}


1;
__END__


=head1 AUTHOR

Bernd Dulfer <bdulfer@cpan.org>

=head2 With Patches from

Graham TerMarsch

=cut
