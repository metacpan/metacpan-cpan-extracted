package Catalyst::Action::Serialize::SimpleXLSX;
use Moose;
extends 'Catalyst::Action';
use Data::Dumper;
use Excel::Writer::XLSX;
use Catalyst::Exception;
use namespace::clean;

=head1 NAME

Catalyst::Action::Serialize::SimpleXLSX - Serialize to Microsoft Excel 2007 .xlsx files 

=cut

our $VERSION = "0.007";

=head1 SYNOPSIS

Serializes tabular data to an Excel file, with simple configuration options.

In your REST Controller:

  package MyApp::Controller::REST;

  use parent 'Catalyst::Controller::REST';
  use DBIx::Class::ResultClass::HashRefInflator;
  use POSIX 'strftime';

  __PACKAGE__->config->{map}{'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'} = 'SimpleXLSX';

  sub books : Local ActionClass('REST') {}

  sub books_GET {
    my ($self, $c) = @_;

    # Books (Sheet 1)
    my $books_rs = $c->model('MyDB::Book')->search();
    $books_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @books = map { [ @{$_}{qw/author title/} ] } $books_rs->all;

    # Authors (Sheet 2)
    my $authors_rs = $c->model('MyDB::Author')->search();
    $authors_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @authors = map { [ @{$_}{qw/first_name last_name/} ] } $authors_rs->all;

    my $entity = {
      sheets => [
        {
          name => 'Books',
          header => ['Author', 'Title'],
          rows => \@books,
        },
        {
          name => 'Authors',
          header => ['First Name', 'Last Name'],
          rows => \@authors,
        },
      ],
      # .xlsx suffix automatically appended
      filename => 'myapp-books-'.strftime('%m-%d-%Y', localtime)
    };

    $self->status_ok(
      $c,
      entity => $entity
    );
  }

In your jQuery webpage, to initiate a file download:

  <script>
  $(document).ready(function () {

  function export_to_excel() {
    $('<iframe ' + 'src="/item?content-type=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">').hide().appendTo('body');
  }
  $("#books").on("click", export_to_excel);

  });
  </script>


Note, the content-type query param is required if you're just linking to the
action. It tells L<Catalyst::Controller::REST> what you're serializing the data
as.

=head1 DESCRIPTION

Your entity should be either:

=over 4

=item * an array of arrays

=item * an array of arrays of arrays

=item * a hash with the keys as described below and in the L</SYNOPSIS>

=back

If entity is a hashref, keys should be:

=head2 sheets

An array of worksheets. Either sheets or a worksheet specification at the top
level is required.

=head2 filename

Optional. The name of the file before .xlsx. Defaults to "data".

Each sheet should be an array of arrays, or a hashref with the following fields:

=head2 name

Optional. The name of the worksheet.

=head2 rows

Required. The array of arrays of rows.

=head2 header

Optional, an array for the first line of the sheet, which will be in bold.

=head2 column_widths

Optional, the widths in characters of the columns. Otherwise the widths are
calculated automatically from the data and header.

If you only have one sheet, you can put it in the top level hash.

=cut

has 'content_type' => (
  is       => 'ro',
  required => 1,
  default  => sub { return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' },
);

sub execute {
  my $self = shift;
  my ( $controller, $c ) = @_;

  my $stash_key = (
      $controller->config->{'serialize'}
    ? $controller->config->{'serialize'}->{'stash_key'}
    : $controller->config->{'stash_key'}
    )
    || 'rest';

  my $data = $c->stash->{$stash_key};

  open my $fh, '>', \my $buf;
  my $workbook = Excel::Writer::XLSX->new($fh);
  my ( $filename, $sheets ) = $self->_parse_entity($data);
  for my $sheet (@$sheets) {
    $self->_add_sheet( $workbook, $sheet );
  }
  $workbook->close;

  $self->_write_file( $c, $filename, $buf );
  return 1;
}

sub _write_file {
  my ( $self, $c, $filename, $data ) = @_;

  $c->res->content_type( $self->content_type );
  $c->res->header(
    'Content-Disposition' => "attachment; filename=${filename}.xlsx" );
  $c->res->output($data);
}

sub _parse_entity {
  my ( $self, $data ) = @_;

  my @sheets;
  my $filename = 'data';

  if ( ref $data eq 'ARRAY' ) {
    if ( not ref $data->[0][0] ) {
      $sheets[0] = { rows => $data };
    }
    else {
      @sheets =
          map ref $_ eq 'HASH' ? $_
        : ref $_ eq 'ARRAY' ? { rows => $_ }
        : Catalyst::Exception->throw(
        'Unsupported sheet reference type: ' . ref($_) ), @{$data};
    }
  }
  elsif ( ref $data eq 'HASH' ) {
    $filename = $data->{filename} if $data->{filename};

    my $sheets = $data->{sheets};
    my $rows   = $data->{rows};

    if ( $sheets && $rows ) {
      Catalyst::Exception->throw('Use either sheets or rows, not both.');
    }

    if ($sheets) {
      @sheets =
          map ref $_ eq 'HASH' ? $_
        : ref $_ eq 'ARRAY' ? { rows => $_ }
        : Catalyst::Exception->throw(
        'Unsupported sheet reference type: ' . ref($_) ), @{$sheets};
    }
    elsif ($rows) {
      $sheets[0] = $data;
    }
    else {
      Catalyst::Exception->throw('Must supply either sheets or rows.');
    }
  }
  else {
    Catalyst::Exception->throw(
      'Unsupported workbook reference type: ' . ref($data) );
  }

  return ( $filename, \@sheets );
}

sub _add_sheet {
  my ( $self, $workbook, $sheet ) = @_;

  my $worksheet = $workbook->add_worksheet( $sheet->{name} ? $sheet->{name} : () );
  $worksheet->keep_leading_zeros(1);

  my ( $row, $col ) = ( 0, 0 );

  my @auto_widths;

  # Write Header
  if ( exists $sheet->{header} ) {
    my $header_format = $workbook->add_format;
    $header_format->set_bold;
    for my $header ( @{ $sheet->{header} } ) {
      if (defined $auto_widths[$col] && $auto_widths[$col] < length $header) {
        $auto_widths[$col] = length $header;
      }
      $worksheet->write( $row, $col++, $header, $header_format );
    }
    $row++;
    $col = 0;
  }

  # Write data
  for my $the_row ( @{ $sheet->{rows} } ) {
    for my $the_col (@$the_row) {
      if (defined $auto_widths[$col] && $auto_widths[$col] < length $the_col) {
        $auto_widths[$col] = length $the_col;
      }
      $worksheet->write( $row, $col++, $the_col );
    }
    $row++;
    $col = 0;
  }

  # Set column widths
  $sheet->{column_widths} = \@auto_widths unless exists $sheet->{column_widths};

  for my $width ( @{ $sheet->{column_widths} } ) {
    $worksheet->set_column( $col, $col++, $width );
  }
  $worksheet->set_column( 0, 0, $sheet->{column_widths}[0] );

  return $worksheet;
}

=head1 AUTHOR

Mike Baas <mbaas at cpan.org>

=head1 ORIGINAL AUTHOR 

Rafael Kitover <rkitover at cpan.org>

=head1 ACKNOWLEDGEMENTS  

This module is really nothing more than a tweak to L<Catalyst::Action::Serialize::SimpleExcel> that drops in L<Excel::Writer::XLSX> for compatibility with Excel 2007 and later.  I just needed more rows!

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Controller::REST>, L<Catalyst::Action::REST>, L<Catalyst::Action::Serialize::SimpleExcel>, L<Excel::Writer::XLSX>

=head1 REPOSITORY

L<https://github.com/initself/Catalyst-Action-Serialize-SimpleXLSX>

=head1 COPYRIGHT & LICENSE

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;    # End of Catalyst::Action::Serialize::SimpleXLSX
