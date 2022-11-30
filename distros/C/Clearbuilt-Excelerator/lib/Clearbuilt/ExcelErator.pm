package Clearbuilt::ExcelErator;
use Modern::Perl;
our $VERSION = '2.0001'; # VERSION
our $AUTHORITY = 'cpan:CLEARBLT'; # AUTHORITY
# ABSTRACT: Write XLSX files in a Clearbuilt-standard way
use Moo;
extends 'Excel::Writer::XLSX';

#
# Attributes
#

has color => (
   is      => 'ro',
   lazy    => 1,
   builder => sub {
      my ($self) = @_;
      return {
         gray30              => $self->set_custom_color( 40, 77,  77,  77 ),
         gray50              => $self->set_custom_color( 40, 127, 127, 127 ),
         gray80              => $self->set_custom_color( 41, 205, 205, 205 ),
         blueaccent1darker50 => $self->set_custom_color( 42, 31,  78,  121 ),
      };
   },
);

has column_lengths => (
   is      => 'ro',
   builder => sub {
      return {};
   },
);

has filename => ( is => 'ro', );

has format_cache => (
   is      => 'rwp',
   lazy    => 1,
   builder => sub {
      my ($self) = @_;
      return {
         richnormal => $self->add_format(),
         richbold   => $self->add_format( bold   => 1 ),
         richitalic => $self->add_format( italic => 1 ),
         settings   => {
            color => {
                    'black' => { color => 'black' },
                    'blue' => { color => 'blue' },
                    'brown' => { color => 'brown' },
                    'cyan' => { color => 'cyan' },
                    'gray' => { color => 'gray' },
                    'green' => { color => 'green' },
                    'lime' => { color => 'lime' },
                    'magenta' => { color => 'magenta' },
                    'navy' => { color => 'navy' },
                    'orange' => { color => 'orange' },
                    'pink' => { color => 'pink' },
                    'purple' => { color => 'purple' },
                    'red' => { color => 'red' },
                    'silver' => { color => 'silver' },
                    'white' => { color => 'white' },
                    'yellow' => { color => 'yellow' },
            },
            type => {
               normal        => {},
               wrap          => { text_wrap  => 1, },
               currency      => { num_format => '$#,##0.00', },
               currencywhole => { num_format => '$#,##0', },
               currencyplain => { num_format => '0.00', },
               currencyacct  => { num_format => '$#,##0.00;($#,##0.00)', },
               percent       => { num_format => '0.00%', },
               multiplier    => { num_format => '0.0000', },
               dec1comma     => { num_format => '#,##0.0' },
            },
            font => {
               normal      => {},
               underline   => { underline => 1 },
               underline20 => { underline => 1, size => 20, },
               bold        => { bold      => 1 },
               bold16      => { bold      => 1, size => 16, },
               bold18      => { bold      => 1, size => 18, },
               bold20      => { bold      => 1, size => 20, },
               bold26      => { bold      => 1, size => 26, },
               italic      => { italic    => 1 },
               italic20    => { italic    => 1, size => 20, },
            },
            bg => {
               none                => {},
               white               => { bg_color => 'white' },
               gray                => { bg_color => 'gray' },
               yellow              => { bg_color => 'yellow' },
               blue                => { bg_color => 'blue',                 color => 'white' },
               gray30              => { bg_color => $self->color->{gray30}, color => 'white' },
               gray50              => { bg_color => $self->color->{gray50} },
               gray80              => { bg_color => $self->color->{gray80} },
               blueaccent1darker50 =>
                   { bg_color => $self->color->{blueaccent1darker50}, color => 'white' },
            },
            border_color => {
               black               => {},
               gray30              => { border_color => $self->color->{gray30} },
               gray80              => { border_color => $self->color->{gray80} },
               blueaccent1darker50 => { border_color => $self->color->{blueaccent1darker50} },
            },
            halign => {
               left    => { align  => 'left' },
               center  => { align  => 'center' },
               right   => { align  => 'right' },
               indent2 => { indent => 2 },
               indent3 => { indent => 3 },
            },
            valign => {
               top      => { valign => 'top' },
               vcenter  => { valign => 'vcenter' },
               bottom   => { valign => 'bottom' },
               vjustify => { valign => 'vjustify' },
            },
            bt => {
               0 => { top => 0 },
               1 => { top => 1 },
               2 => { top => 2 },
            },
            bb => {
               0 => { bottom => 0 },
               1 => { bottom => 1 },
               2 => { bottom => 2 },
            },
            bl => {
               0 => { left => 0 },
               1 => { left => 1 },
               2 => { left => 2 },
            },
            br => {
               0 => { right => 0 },
               1 => { right => 1 },
               2 => { right => 2 },
            },
         },
      };
   },
);

#
# Builder
#

sub FOREIGNBUILDARGS {
   my ( $self, $options ) = @_;
   return $options->{filename};
}

#
# Public methods
#

sub write_the_book {
   my ( $self, $spreadsheet ) = @_;
   foreach my $sheet ( @{$spreadsheet} ) {
      my $worksheet = $self->add_worksheet( $sheet->{title} );
      my $row       = 0;
      if ( defined $sheet->{col_widths} ) {
         $self->_set_default_column_widths( $worksheet, $sheet->{col_widths} );
      }
      foreach my $datarow ( @{ $sheet->{rows} } ) {
         my $col = 0;
         my $cells;
         if ( !defined $datarow ) {
            $row++;
            next;
         }
         if ( ref $datarow eq 'ARRAY' ) {
            $cells = $datarow;
         }
         else {
            $cells = $datarow->{cells};
            my $rowformat = $self->_format_with_defaults();
            if ( $datarow->{format} ) {
               $rowformat = $self->_format_with_defaults( @{ $datarow->{format} } );
            }
            $worksheet->set_row(
               $row, $datarow->{height}, $rowformat,
               ( $datarow->{hidden}        // 0 ),
               ( $datarow->{outline_level} // 0 ),
               ( $datarow->{collapsed}     // 0 )
            );
         }
         foreach my $cell ( @{$cells} ) {
            my $format = $self->_format_with_defaults();
            if ( ref($cell) ne 'HASH' ) {
               if ( defined $cell ) {
                  $self->_update_column_length( $sheet->{title}, $col, $cell );
                  $worksheet->write( $row, $col, $cell, $format );
               }
               $col++;
               next;
            }
            unless ( $cell->{nowidth} ) {
               $self->_update_column_length( $sheet->{title}, $col, $cell->{value} );
            }
            if ( $cell->{format} ) {
               $format = $self->_format_with_defaults( @{ $cell->{format} } );
            }
            if ( $cell->{across} ) {
               $worksheet->merge_range( $cell->{across}, $cell->{value}, $format );
               $col++;
               next;
            }
            my $writer = $cell->{as_text} ? 'write_string' : 'write';
            $worksheet->$writer( $row, $col, $cell->{value}, $format );
            if ($cell->{comment}) {
               if (ref $cell->{comment} ne 'HASH') {
                  $worksheet->write_comment( $row, $col, $cell->{comment} );
               } else {
                  $worksheet->write_comment( $row, $col, $cell->{comment}->{value}, @{$cell->{comment}->{format}});
               }
            }
            $col++;
         }
         $row++;
      }
      $self->_close();
   }
}

#
# Private methods
#

sub _close {
   my $self = shift;
   $self->_set_column_widths;
   $self->SUPER::close();
}

sub _format_with_defaults {
   my $self = shift;
   my %args = (
      type         => 'normal',
      font         => 'normal',
      color        => 'black',
      bg           => 'none',
      border_color => 'black',
      halign       => 'left',
      valign       => 'bottom',
      bt           => 0,
      bb           => 0,
      bl           => 0,
      br           => 0,
   );
   if (@_) {
      %args = (
         type         => 'normal',
         font         => 'normal',
         color        => 'black',
         bg           => 'none',
         border_color => 'black',
         halign       => 'left',
         valign       => 'bottom',
         bt           => 0,
         bb           => 0,
         bl           => 0,
         br           => 0,
         @_,
      );
   }

   my $cache_key = join( '|', map { $args{$_} } qw(type font color bg halign valign bt bb bl br) );
   return $self->format_cache->{$cache_key} if ( exists $self->format_cache->{$cache_key} );

   $self->format_cache->{$cache_key} = $self->add_format(
      %{ $self->format_cache->{settings}{type}{ $args{type} } },
      %{ $self->format_cache->{settings}{font}{ $args{font} } },
      %{ $self->format_cache->{settings}{color}{ $args{color} } },
      %{ $self->format_cache->{settings}{bg}{ $args{bg} } },
      %{ $self->format_cache->{settings}{border_color}{ $args{border_color} } },
      %{ $self->format_cache->{settings}{halign}{ $args{halign} } },
      %{ $self->format_cache->{settings}{valign}{ $args{valign} } },
      %{ $self->format_cache->{settings}{bt}{ $args{bt} } },
      %{ $self->format_cache->{settings}{bb}{ $args{bb} } },
      %{ $self->format_cache->{settings}{bl}{ $args{bl} } },
      %{ $self->format_cache->{settings}{br}{ $args{br} } },
   );
   return $self->format_cache->{$cache_key};
}

sub _no_more_than {
   my ( $self, $max, $val ) = @_;
   return $val if $val < $max;
   return $max;
}

sub _set_column_widths {
   my ( $self, $factor ) = @_;
   $factor = 1.3 unless ( defined $factor );
   foreach my $sheet_name ( keys %{ $self->column_lengths } ) {
      my $sheet = $self->get_worksheet_by_name($sheet_name);
      foreach my $column ( keys %{ $self->column_lengths->{$sheet_name} } ) {
         $sheet->set_column( $column, $column,
            $factor * $self->column_lengths->{$sheet_name}->{$column} );
      }
   }
}

sub _set_default_column_widths {
   my ( $self, $worksheet, $format_info ) = @_;
   foreach my $element ( keys %{$format_info} ) {
      foreach my $range ( split /,/, $element ) {
         my $first_element = $range;
         my $last_element  = $range;
         if ( $range =~ /\-/ ) { ( $first_element, $last_element ) = $range =~ /(\d+)\-(\d+)/; }
         my $curr = $first_element;
         while ( $curr <= $last_element ) {
            $worksheet->set_column( $curr, $curr, $format_info->{$element} );
            $self->column_lengths->{ $worksheet->get_name() }->{$curr} =
                $format_info->{$element};
            $curr++;
         }
      }
   }
}

sub _update_column_length {
   my ( $self, $sheet, $current_column, $value ) = @_;
   if ( defined $self->column_lengths->{$sheet}->{$current_column} ) {
      my $cell_length = length($value) // 0;
      if ( $cell_length > $self->column_lengths->{$sheet}->{$current_column} ) {
         $self->column_lengths->{$sheet}->{$current_column} =
             $self->_no_more_than( 80, $cell_length );
      }
   }
   else {
      $self->column_lengths->{$sheet}->{$current_column} =
          $self->_no_more_than( 80, length($value) );
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clearbuilt::ExcelErator - Write XLSX files in a Clearbuilt-standard way

=head1 VERSION

version 2.0001

=head1 SYNOPSIS

   use Clearbuilt::ExcelErator;

   my %spreadsheet = (
      'title'      => 'Summary',
      'col_widths' => {
         '1-3' => 12
      },
      'rows' => [
         [ { value => 'The Report Title', format => [ font => 'bold' ], nowidth => 1 } ],
         [],
         [
            '',
            { value => 'Qty', format => [ bb => 2, font => 'bold', halign => 'center' ] },
            { value => 'Cost', format => [ bb => 2, font => 'bold', halign => 'center' ] },
            { value => 'Total Cost', format => [ bb => 2, font => 'bold', halign => 'center' ] },
         ],
         [ 'Widget 1',
            { value => $qty_of_widget_1,  format => [ halign => 'right', type => 'dec1comma' ] },
            { value => $cost_of_widget_1, format => [ halign => 'right', type => 'currencyacct' ] },
            { value => $qty_of_widget_1 * $cost_of_widget_1,
                 format => [ halign => 'right', type => 'currencyacct' ] },
         ],
         [ 'Widget 2',
            { value => $qty_of_widget_2,  format => [ halign => 'right', type => 'dec1comma' ] },
            { value => $cost_of_widget_2, format => [ halign => 'right', type => 'currencyacct' ] },
            { value => $qty_of_widget_2 * $cost_of_widget_2,
                 format => [ halign => 'right', type => 'currencyacct' ] },
         ],
         [ 'Totals',
            { value  => "=sum(B3:B4)", format => [ tb => 2, halign => 'right', type => 'dec1comma' ] },
            { value  => "=sum(C3:C4)", format => [ tb => 2, halign => 'right', type => 'currencyacct' ] },
            { value  => "=sum(D3:D4)", format => [ tb => 2, halign => 'right', type => 'currencyacct' ] },
         ],
      ],
   );
   my $workbook = Clearbuilt::ExcelErator->new( { filename => 'my_workbook.xlsx' } );
   $workbook->write_the_book( [\%spreadsheet] );

=head1 DESCRIPTION

Clearbuilt::Excelerator is a wrapper around L<Excel::Writer::XLSX> that
simplifies and standardizes its usage. You create a hash defining your
spradsheet, and it does the rest for you!

More documentation of the hash will be added later, but the L</"SYNOPSIS"> above shows a 
simple and common usage, with frequently-used options. A more-extensive example can be found
in the package, in C<examples/create_test_excel_sheet>.

=head1 THE WORKBOOK ARRAY

The workbook is an array of hashes, each of which is a worksheet.

Note that the hash for this simple example is sent as an arrayref-to-the-hash.
The implication of that it is, of course, that you could create multiple
hashes, push them into an array in the order you want, and send a reference
to that array to C<write_the_book> and get a multi-sheet workbook.

=head1 THE WORKSHEET HASH

There are only three valid elements in this hash:

=over 4

=item *
C<title>: The title of the spreadsheet, which will show up in the tabs at the bottom.

=item *
C<col_widths>: A hashref of column widths. The key is the column number (beginning with 1), and the value is the desired width.

=item *
C<rows>: The array of rows for the sheet.

=back

=head1 THE WORKSHEET ROWS ARRAY

The C<rows> array is an array of arrayrefs; each of B<those> is an arrayref of cells.  The cell can be a 
scalar, in which case it is displayed with default formatting, or a hashref with a C<value> and optionally
a C<format>.  If you do not specify a C<format>, you get the default for that cell.

=head1 EXPORTED METHODS

=head2 new({ filename => <filespec>})>

Opens the desired file for writing.  At this time, C<filename> is the only parameter, which is passed
verbatim into L<Excel::Writer::XLSX>; there may be other options in the future.

=head2 write_the_book(\%spreadsheet);

Writes the file, and closes it.  Easy-peasy!

=head1 REQUIRES

=over 4

=item *
L<Modern::Perl>

=item *
L<Moo>

=item *
L<Excel::Writer::XLSX>

=back

=head1 ROADMAP

=over 4

=item *
Add other formatting functions

=item *
Default column formatting

=item *
More documentation

=item *
A robust unit test for C<write_the_book>

=back

=head1 AUTHOR

D Ruth Holloway <ruthh@clearbuilt.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Clearbuilt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
