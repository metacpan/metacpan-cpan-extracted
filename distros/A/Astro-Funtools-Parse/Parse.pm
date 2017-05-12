package Astro::Funtools::Parse;

use strict;
use warnings;

use Carp;
use IO::File;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Astro::Parse::Funtools ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parse_funcnts
        parse_funcnts_file				
	parse_funhist
	parse_funhist_file
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.08';

use Data::LineBuffer;


# Preloaded methods go here.

sub parse_funhist_file
{
  my $file = shift;
  my $fh = new IO::File $file 
    or croak( __PACKAGE__, "::parse_funhist_file: unable to open $file\n" );

  parse_funhist( $fh );
}

sub parse_funhist
{
  my $what = shift;

  my %results;

  my $src = new Data::LineBuffer $what
    or croak( __PACKAGE__, "parse_funcnts: something wrong with argument\n");

  my $header = _parse_header( $src );

  if ( exists $header->{_TOP}{'min,max,bins'} )
  {
    my ( $min, $max, $bins ) = split( ' ', $header->{_TOP}{'min,max,bins'} );
    delete $header->{_TOP}{'min,max,bins'};
    @{$header->{_TOP}}{qw( min max bins) } = ( $min, $max, $bins );
  }

  # grab the first thing; it's a table
  my $table = _parse_table( $src );

  ( $header->{_TOP}, $table );
}

sub parse_funcnts_file
{
  my $file = shift;
  my $fh = new IO::File $file 
    or croak( __PACKAGE__, "::parse_funcnts_file: unable to open $file\n" );

  parse_funcnts( $fh );
}


sub parse_funcnts
{
  my $what = shift;

  my @results;

  my $src = new Data::LineBuffer $what
    or croak( __PACKAGE__, "parse_funcnts: something wrong with argument\n");

  LINE: while ( 1 )
  {
    my %results;

    $results{hdr} = _parse_header( $src );

    last unless %{$results{hdr}};
  
    # grab the first thing; it's a table
    my $ln = $src->pos;
    my $table = _parse_table( $src );
  
    # is it a summed background-subtracted table?
    if ( grep { 'upto' eq $_ } @{$table->{names}} )
    {
      $results{sum_bkgd_sub}{table} = $table;
      # next thing is the real background subtracted table, then
      $ln = $src->pos;
      $results{bkgd_sub}{table} = _parse_table( $src );
  
      # but we'll check on that!
      croak( __PACKAGE__,
  	   "::parse_funcnts: line $ln: expected a background-subtracted ",
  	   "table but didn't find one!\n" )
        unless grep { 'reg' eq $_ }
                     @{$results{bkgd_sub}{table}->{names}};
    }
  
    # nope, must be a background-subtracted table
    else
    {
      $results{bkgd_sub}{table} = $table;
      croak( __PACKAGE__,
  	   "::parse_funcnts: line $ln: expected a background-subtracted ",
  	   "table but didn't find one!\n" )
        unless grep { 'reg' eq $_ }
                     @{$table->{names}};
    }
  
    # ok, now we're looking for regions, source and possibly background
    # each region has a table after it.
  
    $results{source}{regions}  = _parse_funcnts_regions( $src );

    $results{source}{table} = _parse_table( $src );
  
    # if there's a region left, it'll be the background
  
    my $regions = _parse_funcnts_regions( $src );
    if ( %$regions )
    {
      if ( @{$regions->{regions}} )
      {
        $results{bkgd}{regions} = $regions;
        $results{bkgd}{table}   = _parse_table( $src );
      }
      _skip_past_formfeed( $src );
    }
    push @results, \%results;
  }
  return wantarray
       ? @results
       : $results[0];
}

sub _skip_past_formfeed
{
  my $src = shift;

  local $_;

  for( my $ln = $src->pos; defined ($_ = $src->get) ; $ln = $src->pos )
  {
    last if /^\f$/;
  }
}


sub _parse_funcnts_regions
{
  my $src = shift;

  local $_;

  my $title;
  my @regions;

  while( defined ($_ = $src->get) )
  {
    return {} if /^\f$/;
    next unless /^#\s+(.*)$/;
    /^#\s+((source|background)_region\(s\))/;
    return unless $_;
    $title = $1;
    last;
  }

  while( defined ($_ = $src->get) )
  {
    last unless /^#\s+(.*)$/;
    push @regions, $1;
  }

  { title => $title, regions => \@regions };
}



sub _parse_header
{
  my $src = shift;

  my %hdr;
  
  local $_;

  my $key = '_TOP';
  for( my $ln = $src->pos; defined ($_ = $src->get) ; $ln = $src->pos )
  {
    last unless /^\#/;
    if ( /:/ )
    {
      croak( __PACKAGE__, 
	     "::_parse_header: line $ln: missing key in header\n" )
	unless defined $key;
      
      my ( $subkey, $val ) = /^\#\s+(.*):\s+(.*)/;
      $subkey =~ s/\s+$//;
      $subkey =~ s/\s/_/g;
      $val =~ s/\s+$//;
      $hdr{$key}{$subkey} = $val;
    }
    
    else
    {
      ( $key ) = /^\#\s+(.*)/;
      $key =~ s/\s+$//;
    }
  }
  
  \%hdr;
}

sub _parse_table
{
  my $src = shift;

  my @records;
  my @comments;
  my @names;

  local $_;

  my $ln;

  # search for start of table.  look for a leading `-'
  # ignore empty lines. anything with a leading `#' is a comment.
  # anything else is the list of column names.
  for( $ln = $src->pos ; defined ( $_ = $src->get ) ; $ln = $src->pos )
  {
    next if /^\s*$/;

    last if /^-+/;

    if ( /^\#(.*)$/ )
    {
      push @comments, $1;
    }

    else
    {
      croak( __PACKAGE__, 
	     "::_parse_table: line $ln: more than one set of column headers?\n" )
	     if @names;

      chomp;
      @names = split;
    }
  }

  croak( __PACKAGE__, "::_parse_table: line $ln: no table here!\n" )
    unless defined $_;

  my @widths = map { length($_) } split(' ', $_ );
  croak( __PACKAGE__, 
	 "::_parse_table: line $ln: inconsistent number of column names and separators" )
    if @names != @widths;


  # work around extra blank line between header and data
  $_ = $src->get;
  $src->unget( $_ )
    unless /^\s*$/;

  for ( my $ln = $src->pos; defined ($_ = $src->get) ;$ln = $src->pos )
  {
    last if /^\s*$/;

    chomp;
    my @data = split;
    unless ( @data == @names )
    {
      croak( __PACKAGE__, 
	   "::_parse_table: line $ln: number of columns and number of data elements differ" )
    }
    my %data;
    @data{@names} = @data;
    push @records, \%data;
  }

  return { comments => \@comments, 
	   names => \@names,
	   widths => \@widths,
	   records => \@records };
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Astro::Funtools::Parse - routines to parse the output of Funtools programs

=head1 SYNOPSIS

  use Astro::Funtools::Parse qw( :all );
  use Astro::Funtools::Parse qw( parse_funcnts 
				 parse_funcnts_file 
				 parse_funhist
				 parse_funhist_file
			       );

  $funcnts = parse_funcnts_file( $filename );
  $funcnts = parse_funcnts( $filehandle );
  $funcnts = parse_funcnts( $string );
  $funcnts = parse_funcnts( \@array );

  ($header, $table ) = parse_funhist_file( $filename );
  ($header, $table ) = parse_funhist( $filehandle );
  ($header, $table ) = parse_funhist( $string );
  ($header, $table ) = parse_funhist( \@array );

=head1 DESCRIPTION

This module provides subroutines which parse the output of two
Funtools programs, B<funcnts> and B<funhist>.  For more information on
Funtools, see

	http://hea-www.harvard.edu/RD/funtools/



=head2 Subroutines

=over 8

=item parse_funcnts_file, parse_funcnts

  $funcnts = parse_funcnts_file( $filename );
  $funcnts = parse_funcnts( $filehandle );
  $funcnts = parse_funcnts( $string );
  $funcnts = parse_funcnts( \@array );

These parse the B<funcnts> output stored in the argument, and return a
reference to a hash containing the results.  If funcnts was run with
the -i switch and more than one "interval" was used, a reference
to an array consisting of references to anonymous hashes is returned,
each hash corresponding to one of the intervals.
The hashes will have the following keys (unless otherwise specified):

=over 8

=item hdr

This element is a reference to a hash containing the header of the
B<funcnts> file.  B<funcnts> headers have a two level hierarchy of
fields in them.  The hash keys are the names of the top level; their
values are references to hashes containing the names and values of
the second level fields.  For example, if the B<funcnts> header is

  # source
  #   data file:          002_02_180_10000_new_evt.fits
  #   degrees/pix:        0.000136639
  # background
  #   data file:          002_02_180_10000_new_evt.fits
  # column units
  #   area:               arcsec**2
  #   surf_bri:           cnts/arcsec**2
  #   err_rate:           cnts/arcsec**2

The resultant entry in the hash returned by this function is

  'hdr' => {
      'background' => { 
         'data file' => '002_02_180_10000_new_evt.fits' 
        },
      'column units' => {
         'area' => 'arcsec**2',
         'surf_bri' => 'cnts/arcsec**2',
         'err_rate' => 'cnts/arcsec**2'
        },
      'source' => {
         'data file' => '002_02_180_10000_new_evt.fits',
         'degrees/pix' => '0.000136639'
        }
    },

=item source

This element is a reference to a hash containing information about the
source regions.  It has two elements, keyed off of C<table> and
C<regions>.  The first element is a hash reference to a table (see
L</Tables> ) and the second is a hash reference to a region (see
L</Regions>)).  For example (note that the contents of the hashes are
not shown):

    'source' => {
                 'table'   => { ... },
                 'regions' => { ... }
                },

=item bkgd

This element may not always be there, depending upon how B<funcnts> was
run.  It has the same format as the C<source> element:

    'bkgd' => {
               'table'   => { ... },
               'regions' => { ... }
              },

=item bkgd_sub

This element is a reference to a hash containing the background subtracted
results table.  The format for tables is given below.

=item sum_bkgd_sub

This element is a reference to a hash containing the summed, background
subtracted results table.  It is not always present, depending upon
how B<funcnts> was run.  The format for tables is given below.

=back



=item parse_funhist_file, parse_funhist

  ($header, $table ) = parse_funhist_file( $filename );
  ($header, $table ) = parse_funhist( $filehandle );
  ($header, $table ) = parse_funhist( $string );
  ($header, $table ) = parse_funhist( \@array );

These parse the B<funhist> output stored in the argument, and return
reference to hashes containing the file header and data.  The header
keywords are used as keys into the header hash.  The data are stored
in the format documented in L</Tables>.

=back


=head2 Tables

Tables are stored as hashes with the keys C<comments>, C<names>, and
C<records>.  The C<comments> element is a reference to an array
containing any comments preceding the table.  The C<names> element is
a reference to an array containing the column names, in the order in
which they appear.  The C<widths> element is an arrayref containing the
width of the column (actually the width of the separators).
Finally, the C<records> element is a reference to
an array, containing references to hashes, one per record in the table.
These latter hashes have as keys the names of the columns, and as
values the related values for that record.

For example:

  {
    'comments' => [
                    ' background-subtracted results'
                  ],
    'widths' => [ 3, 6, 5, 10, 6, 4, 8, 8 ],
    'names' => [
                 'reg',
                 'counts',
                 'error',
                 'background',
                 'berror',
                 'area',
                 'surf_bri',
                 'err_rate'
               ],
    'records' => [
                   {
                     'error' => '95.979',
                     'reg' => '1',
                     'area' => '90.25',
                     'background' => '0.532',
                     'counts' => '9211.468',
                     'surf_bri' => '102.063',
                     'err_rate' => '1.063',
                     'berror' => '0.142'
                   },
                   {
                     'error' => '9.545',
                     'reg' => '2',
                     'area' => '275.84',
                     'background' => '1.326',
                     'counts' => '89.674',
                     'surf_bri' => '0.325',
                     'err_rate' => '0.035',
                     'berror' => '0.332'
                   }
                 ]
  }


=head2 Regions

Regions are stored as hashes with the keys C<title> and C<regions>.
The former is a scalar containing the region's identifying string,
the latter is a reference to an array, containing the region description
(one element per line). For example:

   {
    'title' => 'source region(s)',
    'regions' => [
                   'annulus(4341,4096,0,22,n=2)'
                 ]
   }

=head2 EXPORT

None by default.  The following symbols are available for export:

  parse_funcnts
  parse_funcnts_file				
  parse_funhist
  parse_funhist_file

The tag C<:all> is available to export all symbols.

=head1 LICENSE

Copyright (C) 2006 Smithsonian Astrophysical Observatory

This file is part of Astro::Funtools::Parse

Astro::Funtools::Parse is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

Astro::Funtools::Parse is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
ong with this program; if not, write to the 
      Free Software Foundation, Inc. 
      51 Franklin Street, Fifth Floor
      Boston, MA  02110-1301, USA

=head1 AUTHOR

Diab Jerius ( djerius@cfa.harvard.edu )

=cut
