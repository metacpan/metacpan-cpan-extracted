##############################################################################
#
#  Data::Tools::CSV perl module
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::CSV;
use strict;
use Exporter;

our $VERSION = '1.50';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                  parse_csv
                  parse_csv_line
                  
                  parse_csv_to_hash_array

                );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );

##############################################################################


sub parse_csv
{
  my $csv_data = shift();
  my $delim    = shift();
  my $strip = shift;
  
  my @csv_data = grep /\S/, split /[\r\n]+/, $csv_data;
  
  # 123,is,testing,"""The"" book, is now",qwerty
  my @res;
  for my $line ( @csv_data )
    {
    push @res, parse_csv_line( $line, $delim, $strip );
    }

  return \@res;
}

sub parse_csv_line
{
  my @line = split //, shift();
  my $delim = shift() || ',';
  my $strip = shift;
  my @out;
  my $fld;
  my $q;
  for( @line, undef )
    {
    if( ( $_ eq $delim and $q % 2 == 0 ) or ! defined )
      {
      $fld =~ s/^\s*// if $strip;
      $fld =~ s/\s*$// if $strip;
      $fld =~ s/^"(.*?)"$/$1/;
      $fld =~ s/""/"/g;
      push @out, $fld;
      $fld = undef;
      next;
      }
    $q++ if /"/;
    $fld .= $_;
    }
  
  return \@out;
}

#-----------------------------------------------------------------------------

sub parse_csv_to_hash_array
{
  my $csv_data = shift();
  my $delim    = shift();
  my $strip    = shift;
  
  my @csv_data = grep /\S/, split /[\r\n]+/, $csv_data;
  
  my $head = parse_csv_line( shift @csv_data, $delim, $strip );
  
  my @res;
  for my $line ( @csv_data )
    {
    my $line_array = parse_csv_line( $line, $delim, $strip );
    push @res, { map { $_ => shift @$line_array } @$head };
    }

  return \@res;
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::CSV -- compact, pure-perl CSV parsing

=head1 SYNOPSIS

  use Data::Tools::CSV qw( :all );  # import all functions
  use Data::Tools::CSV;             # the same as :all :) 
  use Data::Tools::CSV qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  my $array_of_arrays = parse_csv( $csv_data_string );
  my @single_line     = parse_csv_line( $single_csv_line );
  
  while( <$fh> )
    {
    parse_csv_line( $_ );
    ...  
    }

  # hash keys names are mapped from the first line of $csv_data (head)
  my @array_of_hashes = parse_csv_to_hash_array( $csv_data );

  # --------------------------------------------------------------------------

=head1 FUNCTIONS

In all functions the '$delim' argument is optional and sets the delimiter to
be used. Default one is comma ',' (accordingly to RFC4180, see below).

In all functions the '$strip' argument should be true ("1" or non-zero string)
to strip data from leading and trailing whitespace. If leading or trailing
whitespace is required but stripping is needed to pad visually the data then
actual data must be quoted:

    NAME,   TEL
    jim,    123
    boo,    "  413  "
    
second field will be [TEL] and data will be [123] and [  413  ].

Unfortunately, for keeping API simple, using stripping will require $delim.
However $delim may be undef to use default delimiter.

=head2 parse_csv( $csv_data_string, $delim, $strip )

Parses multi-line CSV text and returnsh hashref to array of arrays.

=head2 parse_csv_line( $single_csv_line, $delim, $strip )

Parses single line CSV data and returns list of parsed fields' data. 
This function will NOT strip trailing CR/LFs. However, parse_csv() and 
parse_csv_to_hash_array() will strip CR/LFs.

=head2 parse_csv_to_hash_array( $csv_data, $delim, $strip )

This function uses first line as hash key names to produce array of hashes
for the rest of the data.

  NOTE: Lines with more data fields than header will discard extra data fields.
  NOTE: Lines with less data fields than header will produce keys with undef values.

=head1 IMPLEMENTATION DETAILS

Data::Tools::CSV is compact, pure-perl implementation of a CSV parser of
RFC4180 style CSV files:

  https://www.ietf.org/rfc/rfc4180.txt
  
RFC4180 says:

  * lines are CRLF delimited, however CR or LF-only are accepted as well.
  * whitespace is data, will not be stripped (2.4).
  * whitespace and delimiters can be quoted with double quotes (").
  * quotes in quoted text should be doubled ("") as escaping.

=head1 KNOWN ISSUES

This implementation does not support multiline fields (lines split),
as described in RFC4180, (2.6).

There is no much error handling. However the code makes reasonable effort
to handle properly all the data provided. This may seem vague but the CSV 
format itself is vague :)

=head1 FEEDBACK

Please, report any bugs or missing features as long as they follow RFC4180.

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  


=cut

##############################################################################
1;
