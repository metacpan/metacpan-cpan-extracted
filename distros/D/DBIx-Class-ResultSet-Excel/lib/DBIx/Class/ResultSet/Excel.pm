package DBIx::Class::ResultSet::Excel;

use strict;
use 5.008_005;
our $VERSION = '0.01';

BEGIN {
   use base 'DBIx::Class::ResultSet';
   use File::Temp qw/tempfile/;
   use Spreadsheet::WriteExcel;
};


sub export_excel {
   my $self = shift;
   my %options = @_;

   my $filename = ($options{'filename'}) ? $options{'filename'} : '';

   my $fh; # Filehandle for the resulting excel file

   # load up temp file
   if ($filename) {
      # if filename give, load that file
      open($fh, ">", $filename) or die "cannot open $filename: $!";
   } else {
      # if no file give, create temple file.
      ( $fh, $filename ) = tempfile(); 
   }

   my $source = $self->result_source;

   my $columns = $source->columns_info;

   # Create our new workbook
   my $workbook = Spreadsheet::WriteExcel->new($fh) or die "Problems creating new Excel file: $! : $filename";

   # Create a worksheet
   my $worksheet = $workbook->add_worksheet();

   # Create Bold formating
   my $bold = $workbook->add_format();
   $bold->set_bold();

   # Construct the header of the excel file
   my $column_cnt = 0;
   foreach my $column ( keys %$columns ) {
      $worksheet->write(0, $column_cnt, $column, $bold);
      # Increment counter
      $column_cnt++;
   }

   # Add Data for each row
   my $row_cnt = 1; # Starts at 1 because 0 is taken by headers
   while (my $row = $self->next) {
      # Loop through each column
      $column_cnt = 0;
      foreach my $column ( keys %$columns ) {
         $worksheet->write($row_cnt, $column_cnt, $row->$column);
         # Increment counter
         $column_cnt++;
      }

      # Increment counter
      $row_cnt ++;
   } 

   return ( $fh, $filename );
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::ResultSet::Excel - Excel export for DBIx::Class using Spreedsheet::WriteExcel

=head1 SYNOPSIS

  package MyApp::Schema::ResultSet::Artist;
  use base 'DBIx::Class::ResultSet::Excel';

  1;

  use MyApp::Schema;
  my $schema = MyApp::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

  # Query for all artists and put them in an array,
  # or retrieve them as a result set object.
  # $schema->resultset returns a DBIx::Class::ResultSet
  my ($fh, $filename) = $schema->resultset('Artist')->export_excel;

=head1 DESCRIPTION

DBIx::Class::ResultSet::Excel is an extension of the Basic DBIx::Class::ResultSet with an extra function to export the ResultSet as an excel file.

=head1 AUTHOR

Sean Zellmer E<lt>sean@lejeunerenard.comE<gt>
L<http://www.lejeunenrenard.com>

=head1 COPYRIGHT

Copyright 2013- Sean Zellmer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DEPENDENCIES

The following modules are mandatory:

=over 8

=item L<DBIx::Class>

=item L<Spreadsheet::WriteExcel>

=item L<File::Temp>

=back

=cut
