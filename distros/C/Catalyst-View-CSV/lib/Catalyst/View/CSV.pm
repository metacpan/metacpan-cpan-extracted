package Catalyst::View::CSV;

# Copyright (C) 2011 Michael Brown <mbrown@fensystems.co.uk>.
#
# This program is free software. You can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 NAME

Catalyst::View::CSV - CSV view class

=head1 SYNOPSIS

    # Create MyApp::View::CSV using the helper:
    script/create.pl view CSV CSV

    # Create MyApp::View::CSV manually:
    package MyApp::View::CSV;
    use base qw ( Catalyst::View::CSV );
    __PACKAGE__->config ( sep_char => ",", suffix => "csv" );
    1;

    # Return a CSV view from a controller:
    $c->stash ( columns => [ qw ( Title Date ) ],
		cursor => $c->model ( "FilmDB::Film" )->cursor,
		current_view => "CSV" );
    # or
    $c->stash ( columns => [ qw ( Title Date ) ],
		data => [
		  [ "Dead Poets Society", "1989" ],
		  [ "Stage Beauty", "2004" ],
		  ...
		],
		current_view => "CSV" );

=head1 DESCRIPTION

L<Catalyst::View::CSV> provides a L<Catalyst> view that generates CSV
files.

You can use either a Perl array of arrays, an array of hashes, an
array of objects, or a database cursor as the source of the CSV data.
For example:

    my $data = [
      [ "Dead Poets Society", "1989" ],
      [ "Stage Beauty", "2004" ],
      ...
    ];
    $c->stash ( data => $data );

or

    my $resultset = $c->model ( "FilmDB::Film" )->search ( ... );
    $c->stash ( cursor => $resultset->cursor );

The CSV file is generated using L<Text::CSV>.

=head1 FILENAME

The filename for the generated CSV file defaults to the last segment
of the request URI plus a C<.csv> suffix.  For example, if the request
URI is C<http://localhost:3000/report> then the generated CSV file
will be named C<report.csv>.

You can use the C<suffix> configuration parameter to specify the
suffix of the generated CSV file.  You can also use the C<filename>
stash parameter to specify the filename on a per-request basis.

=head1 CONFIGURATION PARAMETERS

=head2 suffix

The filename suffix that will be applied to the generated CSV file.
Defaults to C<csv>.  For example, if the request URI is
C<http://localhost:3000/report> then the generated CSV file will be
named C<report.csv>.

Set to C<undef> to prevent any manipulation of the filename suffix.

=head2 charset

The character set stated in the MIME type of the downloaded CSV file.
Defaults to C<utf-8>.

=head2 content_type

The Content-Type header to be set for the downloaded file.
Defaults to C<text/csv>.

=head2 eol, quote_char, sep_char, etc.

Any remaining configuration parameters are passed directly to
L<Text::CSV>.

=head1 STASH PARAMETERS

=head2 data

An array containing the literal data to be included in the generated
CSV file.  For example:

    # Array of arrays
    my $data = [
      [ "Dead Poets Society", "1989" ],
      [ "Stage Beauty", "2004" ],
    ];
    $c->stash ( data => $data );

or

    # Array of hashes
    my $columns = [ qw ( Title Date ) ];
    my $data = [
      { Title => "Dead Poets Society", Date => 1989 },
      { Title => "Stage Beauty", Date => 2004 },
    ];
    $c->stash ( data => $data, columns => $columns );

or

    # Array of objects
    my $columns = [ qw ( Title Date ) ];
    my $data = [
      Film->new ( Title => "Dead Poets Society", Date => 1989 ),
      Film->new ( Title => "Stage Beauty", Date => 2004 ),
    ];
    $c->stash ( data => $data, columns => $columns );

will all (assuming the default configuration parameters) generate the
CSV file body:

    "Dead Poets Society",1989
    "Stage Beauty",2004

You must specify either C<data> or C<cursor>.

=head2 cursor

A database cursor providing access to the data to be included in the
generated CSV file.  If you are using L<DBIx::Class>, then you can
obtain a cursor from any result set using the C<cursor()> method.  For
example:

    my $resultset = $c->model ( "FilmDB::Film" )->search ( ... );
    $c->stash ( cursor => $resultset->cursor );

You must specify either C<data> or C<cursor>.  For large data sets,
using a cursor may be more efficient since it avoids copying the whole
data set into memory.

=head2 columns

An optional list of column headings.  For example:

    $c->stash ( columns => [ qw ( Title Date ) ] );

will produce the column heading row:

    Title,Date

If no column headings are provided, the CSV file will be generated
without a header row (and the MIME type attributes will indicate that
no header row is present).

If you are using literal data in the form of an B<array of hashes> or
an B<array of objects>, then you must specify C<columns>.  You do not
need to specify C<columns> when using literal data in the form of an
B<array of arrays>, or when using a database cursor.

Extracting the column names from a L<DBIx::Class> result set is
surprisingly non-trivial.  The closest approximation is

    $c->stash ( columns => $resultset->result_source->columns );

This will use the column names from the primary result source
associated with the result set.  If you are doing anything even
remotely sophisticated, then this will not be what you want.  There
does not seem to be any supported way to properly extract a list of
column names from the result set itself.

=head2 filename

An optional filename for the generated CSV file.  For example:

    $c->stash ( data => $data, filename => "films.csv" );

If this is not specified, then the filename will be generated from the
request URI and the C<suffix> configuration parameter as described
above.

=cut

use Text::CSV;
use URI;
use base qw ( Catalyst::View );
use mro "c3";
use strict;
use warnings;

use 5.009_005;
our $VERSION = "1.8";

__PACKAGE__->mk_accessors ( qw ( csv charset suffix content_type ) );

sub new {
  ( my $self, my $app, my $arguments ) = @_;

  # Resolve configuration
  my $config = {
    eol => "\r\n",
    charset => "utf-8",
    suffix => "csv",
    content_type => "text/csv",
    %{ $self->config },
    %$arguments,
  };
  $self = $self->next::method ( $app, $config );

  # Record character set
  $self->charset ( $config->{charset} );
  delete $config->{charset};

  # Record suffix
  $self->suffix ( $config->{suffix} );
  delete $config->{suffix};

  # Record content-type
  $self->content_type( $config->{content_type} );
  delete $config->{content_type};

  # Create underlying Text::CSV object
  delete $config->{catalyst_component_name};
  my $csv = Text::CSV->new ( $config )
      or die "Cannot use CSV view: ".Text::CSV->error_diag();
  $self->csv ( $csv );

  return $self;
}

sub process {
  ( my $self, my $c ) = @_;

  # Extract instance parameters
  my $charset = $self->charset;
  my $suffix = $self->suffix;
  my $csv = $self->csv;
  my $content_type = $self->content_type;

  # Extract stash parameters
  my $columns = $c->stash->{columns};
  die "No cursor or inline data provided\n"
      unless exists $c->stash->{data} || exists $c->stash->{cursor};
  my $data = $c->stash->{data};
  my $cursor = $c->stash->{cursor};
  my $filename = $c->stash->{filename};

  # Determine resulting CSV filename
  if ( ! defined $filename ) {
    $filename = ( [ $c->req->uri->path_segments ]->[-1] ||
		  [ $c->req->uri->path_segments ]->[-2] );
    if ( $suffix ) {
      $filename =~ s/\.[^.]*$//;
      $filename .= ".".$suffix;
    }
  }

  # Set HTTP headers
  my $response = $c->response;
  my $headers = $response->headers;
  my @content_type = ( $content_type,
		       "header=".( $columns ? "present" : "absent" ),
		       "charset=".$charset );
  $headers->content_type ( join ( "; ", @content_type ) );
  $headers->header ( "Content-disposition",
		     "attachment; filename=".$filename );

  # Generate CSV file
  if ( $columns ) {
    $csv->print ( $response, $columns )
	or die "Could not print column headings: ".$csv->error_diag."\n";
  }
  if ( $data ) {
    foreach my $row ( @$data ) {
      if ( ref $row eq "ARRAY" ) {
	# No futher processing required
      } elsif ( ref $row eq "HASH" ) {
	$row = [ @$row{@$columns} ];
      } else {
	$row = [ map { $row->$_ } @$columns ];
      }
      $csv->print ( $response, $row )
	  or die "Could not generate row data: ".$csv->error_diag."\n";
    }
  } else {
    while ( ( my @row = $cursor->next ) ) {
      $csv->print ( $response, \@row )
	  or die "Could not generate row data: ".$csv->error_diag."\n";
    }
  }

  return 1;
}

=head1 AUTHOR

Michael Brown <mbrown@fensystems.co.uk>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
