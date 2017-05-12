package Date::Jalali2;

use strict;
use warnings;
use Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

my @g_days_in_month = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
my @j_days_in_month = (31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29);
my @j_month_name = ("", "Farvardin", "Ordibehesht", "Khordad", "Tir",
                      "Mordad", "Shahrivar", "Mehr", "Aban", "Azar",
                      "Dey", "Bahman", "Esfand");

# Preloaded methods go here.

sub new { 
  my $class = shift; 
  my ($y,$m,$d,$o)=($_[0],$_[1],$_[2],$_[3]);
  if(!defined $o)
  {
  	$o=0;
  }
  if ($o==0) {
  	  my ($gy,$gm,$gd)=($y-1600,$m-1,$d-1);
	  my $self={};
	  my $i=0;
	
	  my $g_day_no = 365*$gy+int(($gy+3)/4)-int(($gy+99)/100)+int(($gy+399)/400);
	
	   for ($i=0; $i < $gm; ++$i) {
	      $g_day_no += $g_days_in_month[$i]; }
	   if ($gm>1 && (($gy%4==0 && $gy%100!=0) || ($gy%400==0))) {
	      #leap and after Feb
	      ++$g_day_no; }
	   $g_day_no += $gd;

	   my $j_day_no = $g_day_no-79;

	   my $j_np = int($j_day_no/12053);
	   $j_day_no %= 12053;
	
	   my $jy = 979+33*$j_np+4*int($j_day_no/1461);
	
	   $j_day_no %= 1461;

	   if ($j_day_no >= 366) {
	      $jy += int(($j_day_no-1)/365);
	      $j_day_no = ($j_day_no-1)%365;
	   }

	   for ($i = 0; $i < 11 && $j_day_no >= $j_days_in_month[$i]; ++$i) {
	      $j_day_no -= $j_days_in_month[$i];
	   }
	   my $jm = $i+1;
	   my $jd = $j_day_no+1;

	   $self->{jal_day}=$jd;
	   $self->{jal_month}=$jm;
	   $self->{jal_year}=$jy;

	   bless $self;
   	return $self;
   } else {
  	  my ($jy,$jm,$jd)=($y-979,$m-1,$d-1);
	  my $self={};
	  my $i=0;
  	  my $j_day_no = 365*$jy + int(($jy/33))*8 + int(($jy%33+3)/4);
	  for ($i=0; $i < $jm; ++$i) {
	  	$j_day_no += $j_days_in_month[$i];
	  }	
	  $j_day_no += $jd;
	  my $g_day_no = $j_day_no+79;
	  my $gy = 1600 + 400*int(($g_day_no/146097)); #/* 146097 = 365*400 + 400/4 - 400/100 + 400/400 */
	  $g_day_no = $g_day_no % 146097;
	  my $leap = 1;
	  if ($g_day_no >= 36525) #/* 36525 = 365*100 + 100/4 */
	  {
	  	$g_day_no--;
	  	$gy += 100*int(($g_day_no/36524)); #/* 36524 = 365*100 + 100/4 - 100/100 */
	  	$g_day_no = $g_day_no % 36524;
	   	if ($g_day_no >= 365) {
	  		$g_day_no++;
		} else {
		  	$leap = 0;
		}
	  }
	  $gy += 4*int(($g_day_no/1461)); #/* 1461 = 365*4 + 4/4 */
	  $g_day_no %= 1461;
	  if ($g_day_no >= 366) {
	  	$leap = 0;
	  	$g_day_no--;
	  	$gy += int($g_day_no/365);
	 	$g_day_no = $g_day_no % 365;
	  }
	 for ($i = 0; $g_day_no >= $g_days_in_month[$i] + ($i == 1 && $leap); $i++) {
	 	$g_day_no -= $g_days_in_month[$i] + ($i == 1 && $leap);
	 }
	 my $gm = $i+1;
	 my $gd = $g_day_no+1;

	 $self->{jal_day}=$gd;
	 $self->{jal_month}=$gm;
	 $self->{jal_year}=$gy;
  	 bless $self;
   	 return $self;


   }
}

sub jal_day {
    my $self = shift;
    return ( $self->{jal_day} );
}

sub jal_month {
    my $self = shift;
    return ( $self->{jal_month} );
}

sub jal_year {
    my $self = shift;
    return ( $self->{jal_year} );
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Date::Jalali2 - Perl extension for converting Gregorian Dates to Jalali

=head1 SYNOPSIS
  
  use Date::Jalali2;
  my $t1 = new Date::Jalali2 (2003,6,9[,options]);
  
  # Option ; 
  # 0 = Gregorian Dates to Jalali
  # 1 = Jalali to Gregorian Dates

  print $t1->jal_day;
  print $t1->jal_month;
  print $t1->jal_year;

=head1 ABSTRACT

  This module converts Gregorian date to Jalali and Jalali date to Gregorian.

=head1 DESCRIPTION

  Gregorian date -> Jalali (used in Iran, ...?)
 
=head2 EXPORT

None by default.

=head1 SEE ALSO

http://www.cpan.org/

=head1 CHANGE LOG :

 #Added Jalali to Gregorian Convertion.

=head1 AUTHOR

Ahmad Anvari <http://www.anvari.org/bio/>

Redistributed by : Ehsan Golpayegani <http://www.golpayegani.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Ehsan Golpayegani

The original algorithm was written with regards to Gregorian<->Jalali
convertor developed by Roozbeh Pournader and Mohammad Toossi
available at:

http://www.farsiweb.info/jalali/jalali.c

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
