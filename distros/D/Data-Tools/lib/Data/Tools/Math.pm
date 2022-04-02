##############################################################################
#
#  Data::Tools perl module
#  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools::Math;
use strict;
use Exporter;
use Carp;
use Data::Tools;
use Math::BigFloat;

our $VERSION = '1.27';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                  num_round
                  num_round_trunc
                  num_pow

                );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );

##############################################################################


sub num_round
{
  my $num = shift; # number
  my $dot = shift; # precision

  return $num unless $dot >= 0;
  my $bf = Math::BigFloat->new($num);
  $num = $bf->ffround(-abs($dot))->bstr();
  return $num;
}

sub num_round_trunc
{
  my $num = shift; # number
  my $dot = shift; # precision

  return $num unless $dot >= 0;
  my $bf = Math::BigFloat->new();
  $bf->round_mode('trunc');
  $bf->badd($num);
  $num = $bf->ffround(-abs($dot))->bstr();
  return $num;
}

sub num_pow
{
  my $num = shift; # number
  my $exp = shift; # exponent

  my $bf = Math::BigFloat->new($num);
  $num = $bf->bpow($exp)->bstr();
  return $num;
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Math provides set of basic functions for mathematics.

=head1 SYNOPSIS

  use Data::Tools::Math qw( :all );  # import all functions
  use Data::Tools::Math;             # the same as :all :) 
  use Data::Tools::Math qw( :none ); # do not import anything

  # --------------------------------------------------------------------------


  # --------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 num_round( $number, $precision )

Rounds $number to $precisioun places after the decimal point.

=head2 num_round_trunc( $number, $precision )

Same as num_trunc() but just truncates after the $precision places.

=head2 num_pow( $number, $exponent )

Returns power of $number by $exponent ( $num ** $exp )

=head1 REQUIRED MODULES

Data::Tools::Time uses:

  * Math::BigFloat

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
