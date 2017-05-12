# --8<--8<--8<--8<--
#
# Copyright (C) 2008 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::QDP::Parse
#
# Astro::QDP::Parse is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Astro::QDP::Parse;

use strict;
use warnings;
use 5.008;

use Carp;

our $VERSION = '0.13';

use Text::Abbrev;

use Clone qw( clone );
use IO::File;
use Regexp::Common qw{ number };
use List::Util qw{ first };
use List::MoreUtils qw{ pairwise };
use Params::Validate qw{ :all };

## no critic (ProhibitAccessOfPrivateData)


my $have_PDL = eval 'use PDL::Core qw( pdl ); 1;';	## no critic


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        read_qdpfile
        parse_qdp
        parse_qdpfile
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub _normalize_keys { return lc $_[0] };

my %parse_qdp_spec = (
                      as_pdl => { type => BOOLEAN, default => 0 },
                      normalize => { type => BOOLEAN, default => 0},
                     );

#========================================================================


sub parse_qdpfile
{
    my @pos = ( shift );
    my ( $file ) = validate_pos( @pos, { type => SCALAR } );

    my %opt = validate_with( params => \@_,
                             spec => \%parse_qdp_spec,
                             normalize_keys => \&_normalize_keys
                           );

    croak( "piddle output requested, but PDL is not available\n" )
      if $opt{as_pdl} && ! $have_PDL;

    my $lines = read_qdpfile( $file );

    return parse_qdp( $lines, \%opt );
}

#-------------------------------------------------------------------
sub read_qdpfile
{
    my ( $file ) = @_;
    my $fh = new IO::File $file
      or croak( __PACKAGE__, "::read_qdpfile: unable to open $file\n" );

    my @lines;

    my $line;
    while ( defined( $line = $fh->getline ) ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ( $line =~ /-$/ ) {
            chop $line;
            chomp( my $l1   =  $fh->getline );
            $l1    =~ s/^\s+//;
            $l1    =~ s/\s+$//;
            $line .= " $l1";
            redo unless $fh->eof;
        }

        push @lines,  $line;
    }
    $fh->close;
    return \@lines;
}

#-------------------------------------------------------------------
sub parse_qdp
{
    my @pos = ( shift );
    my ( $lines ) = validate_pos( @pos, { type => ARRAYREF } );

    my %opt = validate_with( params => \@_,
                             spec => \%parse_qdp_spec,
                             normalize_keys => \&_normalize_keys
                           );

  my $hdr = _parse_qdp_hdr( $lines );

  return _parse_qdp_datagroups( $hdr, $lines, \%opt );
}

#-------------------------------------------------------------------
sub _parse_qdp_hdr
{
  my ( $lines ) = @_;

  my %hdr     = ( serr => [],
                  terr => [],
                  skip => 0,
                  plt  => [],
                );     # header info

  # serr and terr must be at the beginning of the qdp file.
  while( $lines->[0] =~ /^\s*read\s+(s|t)(?:err)?\s+(.*)/i )
  {
      chomp( my $line = shift @$lines);

      $hdr{lc $1 . 'err'} = [ split(' ', $2) ];
  }

  {
      # now find first line of data so can figure out vectors
      my $dline = first { /^$RE{num}{real}/ } @$lines;

      croak( "no data in qdp file?\n" )
        if ! defined $dline;

      chomp $dline;
      my @data = split(' ', $dline);
      $hdr{ncols} = @data;
  }

  #------------------
  # determine number of vectors. a vector consists of a data column plus
  # 0, 1, or 2 error columns.
  my $nvec = $hdr{ncols} - @{$hdr{serr}} - 2 * @{$hdr{terr}};

  # initialize list of vectors
  my @vec = map { { errtype => 0 } } 1..$nvec;

  # set non-default error types
  $vec[$_-1]{errtype} = 1 foreach @{$hdr{serr}};
  $vec[$_-1]{errtype} = 2 foreach @{$hdr{terr}};

  # flush out vectors, creating indices to data file columns
  # for each vector component (data and error column(s))
  my $idx = 0;
  my $hdg = 0;
  for my $vec ( @vec )
  {
      $vec->{hdg} = $hdg++;
      $vec->{start} = $idx;
      $idx += $vec->{errtype} + 1;
      $vec->{data} = [];
      if ( $vec->{errtype} == 1 )
      {
          $vec->{err} = [];
      }
      elsif ( $vec->{errtype} == 2 )
      {
          $vec->{elo} = [];
          $vec->{ehi} = [];
      }
  }

  $hdr{vecs} = \@vec;

  return \%hdr;
}

#-------------------------------------------------------------------
sub _parse_qdp_datagroups
{
  my ( $hdr, $lines, $opts ) = @_;

  my @groups;

  my $vdg = 0;
  my $dg  = 1;
  while ( @$lines )
  {
      my ( $x, @y) = _parse_qdp_datagroup( $hdr, $lines, $opts );

      $x->{vdg} = $vdg;
      for my $y ( @y )
      {
          $y->{vdg} = $vdg;
          $y->{dg} = $dg++;
          push @groups, { x => $x, y => $y };
      }
      $vdg++;
  }

  delete $hdr->{vecs};
  delete $hdr->{skip};

  return \@groups, $hdr;
}


#-------------------------------------------------------------------
sub _parse_qdp_datagroup
{
  my ( $hdr, $lines, $opt ) = @_;

  # make copy of vector templates, as the templates
  # are reused for "vertical" data groups.
  my $vecs = clone $hdr->{vecs};

  # create a list of arrayrefs, in the same order as the input data tokens,
  # to speed up processing of data
  my @drefs = map {   $_->{errtype} == 0 ? ( $_->{data} )
                    : $_->{errtype} == 1 ? ( $_->{data}, $_->{err} )
                    :                      ( $_->{data}, $_->{elo}, $_->{ehi} ) 
                }
               @$vecs;

  _parse_horiz_datagroup( $hdr, $lines, @drefs );

  if ( $opt->{as_pdl} )
  {
      for my $vec ( @$vecs )
      {
          $vec->{$_} = pdl( $vec->{$_} ) 
            foreach grep { exists $vec->{$_} }
                           qw ( data err elo ehi );
      }
  }

  if ( $opt->{normalize} )
  {
      $_->{elo} = $_->{ehi} = delete $_->{err}
        foreach grep { exists $_->{err} } @$vecs;
  }

  return @$vecs;
}

#-------------------------------------------------------------------
sub _parse_horiz_datagroup {

    my ( $hdr, $lines, @cols ) = @_;

    my $nskip = 0;
    while( @$lines )
    {
        my $line = shift @$lines;
        chomp $line;

        if ( $hdr->{skip} && $line =~ /^\s*NO\s+/ )
        {
            # $NO is the number of *additional* NO lines
            my $NO = 0;
            $NO++ while $NO < @$lines && $lines->[$NO] =~ /^\s*NO\s+/;

            if ( $hdr->{skip} && $hdr->{skip} <= $NO+1 )
            {
                splice(@$lines, 0, $NO);
                return;
            }
        }


        if ( $line =~ /^\s*$RE{num}{real}/ || $line =~ /^\s*NO\s+/ )
        {
            my @data = map { $_ eq 'NO' ? undef : $_ } split( ' ', $line );
            if ( @data != @cols )
            {
                croak( 'unexpected number of data points: ',
                     'got ', scalar @data,
                     ' expected ', scalar @cols,
                     "\n" );
            }

            push @{$_}, shift @data foreach @cols;
        }

        else
        {
            _parse_plt_command( $hdr, $line );
        }
    }

    return;
}

#-------------------------------------------------------------------

my %PLT = abbrev qw( skip off single double );

sub _parse_plt_command {

    my ( $hdr, $line ) = @_;


    push @{ $hdr->{plt} }, $line;


    # need to process some .pco commands (e.g. skip) while reading
    # in data; if it's an indirection ("@filename") recursively handle that

    if ( $line =~ /^\s*\@(.*)/ )
    {
        my $lines = read_qdpfile($1);

        # don't push the expanded commands in the saved list of plt commands
        my $plts = $hdr->{plt};
        $hdr->{plt} = [];
        _parse_plt_command( $hdr, $_ ) foreach @$lines;
        $hdr->{plt} = $plts;
    }

    else
    {
        my ( $cmd, @opts ) = split( ' ', $line );

        $cmd = $PLT{lc $cmd} || '';

        if ( $cmd eq 'skip' )
        {
            my $opt = $PLT{lc $opts[0]};
            croak( "unrecognized argument to PLT skip command: $opts[0]\n" )
              unless defined $opt;

            $hdr->{skip} = { off    => 0,
                             single => 1,
                             double => 2,
                           }->{$opt};
        }
    }

    return;
}

1;


__END__

=head1 NAME

Astro::QDP::Parse - extract Data from a B<QDP> input file

=head1 SYNOPSIS

    use Astro::QDP::Parse qw/ :all /;

    $rawlines = read_qdpfile( $filename );
    ( $data, $hdr ) = parse_qdp( $rawlines, \%options );
    ( $data, $hdr ) = parse_qdpfile( $filename, \%options );

=head1 DESCRIPTION

Astro::QDP::Parse processes files in QDP format (e.g., the QDP
output written by XSPEC's C<wenv> command).  The QDP file contains QDP
commands specifying how the data are to be read, data records and
optional PLT commands.

The B<QDP> format encodes data as one or more sets of data vectors,
where a set of vectors consists of a single "independent" vector and
one or more "dependent" data vectors of the same length.  Each pairing
of a dependent vector with its matching "independent" vector is
considered a separate data group.

A data vector consists of a data column and zero, one, or two error columns.


=head1 INTERFACE

=head1 Functions

=over 8

=item B<read_qdpfile>

  $lines = read_qdpfile( $filename );

This function reads data the named QDP file, and returns an array
containing logical records. (Lines ending with '-' (the QDP line
continuation character) are concatenated to generate the logical
lines).  It does not interpolate files accessed via the PLT
C<@filename> command.

=item B<parse_qdp>

  ($data, $hdr) = parse_qdp( \@lines, \%options );

The function extracts the data in the passed array (which must contain
data and QDP or PLT command records) and returns the encoded data
groups and other metadata.  The input array of lines is typically that
returned by B<read_qdpfile>.  See also B<parse_qdpfile> for a more
turnkey approach.

The data is returned as an array of hashes, one per data group, in the
order the groups were read from the input file.  Each hash has the
following keys:

=over

=item x - the independent data vector

=item y - the dependent data vector

=back

Data vectors are represented as hashes, with the following keys:

=over

=item C<hdg>

The zero based index of the vector within its containing data set.  The C<x> data
vector always has C<hdg == 0>.

=item C<vdg>

The zero based index of the data set within the set of data sets which contains the
vector.

=item C<dg>

The unary based index of the data group containing the vector.  This corresponds
to B<QDP>'s numbering of data groups.

=item C<errtype>

This indicates the number of errors associated with the data, either
C<0>, C<1> for symmetric sided errors and C<2> for asymmetric errors.

=item C<data>

A array (or piddle, if the C<as_pdl> option was specified) containing the data.

=item C<err>

A array (or piddle, if the C<as_pdl> option was specified) containing
the symmetric error, if available.  If the C<normalize> option was
specified, then the symmetric error is made available via the C<elo> and
C<ehi> elements and this element is not present.

=item C<elo>

A array (or piddle, if the C<as_pdl> option was specified) containing
the lower assymmetric error, if available.

=item C<ehi>

A array (or piddle, if the C<as_pdl> option was specified) containing
the upper assymmetric error, if available.

=back

The meta-data are returned via the C<$hdr> hash, with the following keys:

=over

=item C<plt>

An array containing the list of PLT commands in the QDP file.

=back


The available options are:

=over

=item C<as_pdl>

If true, return the data as PDL objects (piddles) rather than arrays.

=item C<normalize>

If true, symmetric errors masquerade as asymmetric errors.

=back


=item B<parse_qdpfile>


  ($data, $hdr) = parse_qdpfile( $filename, \%options );

B<parse_qdpfile> combines the B<read_qdpfile> and B<parse_qdp>
functions and takes the same optoins as B<parse_qdp>.

=back

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< piddle output requested, but PDL is not available >>

The C<as_pdl> option was specified, but the PDL module is not installed.

=item C<< read_qdpfile: unable to open %s >>

The specified B<QDP> file does not exist or is not readable.

=item C<< no data in qdp file? >>

No data records were found in the B<QDP> file.

=item C<< unexpected number of data points: got %d expected %d >>

A data record contained fewer or more data columns than was expected.

=item C<< unrecognized argument to PLT skip command: %s >>

The argument to the B<PLT> C<skip> command in the B<QDP> file (or in
a file specified via a C<@filename> B<PLT> command was not recognized.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Astro::QDP::Parse requires no configuration files or
environment variables.


=head1 DEPENDENCIES

Required Modules:

    Clone
    IO::File
    Regexp::Common
    List::Util
    List::MoreUtils
    Params::Validate;

Optional Modules:

    PDL::Core


=head1 INCOMPATIBILITIES


None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-astro-qdp-parse@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-QDP-Parse>.

=head1 SEE ALSO

The B<QDP> web page at L<http://wwwastro.msfc.nasa.gov/qdp/>.

=head1 VERSION

Version 0.13

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 The Smithsonian Astrophysical Observatory

Astro::QDP::Parse is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Terry Gaetz  E<lt>tgaetz@cpan.orgE<gt>

Diab Jerius  E<lt>djerius@cpan.orgE<gt>

