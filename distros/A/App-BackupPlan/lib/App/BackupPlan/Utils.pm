package App::BackupPlan::Utils;

use strict;
use warnings;
use Archive::Tar;
use File::Find;
use Time::Local;
use DateTime;

our @ISA = qw(Exporter);
our $VERSION = '0.0.9';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use App::BackupPlan ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(fromTS2ISO fromISO2TS addSpan subSpan);

sub fromTS2ISO {
  my $ts = $_[0];
  my @ts = localtime $ts;
  my $year = $ts[5]+1900;
  my $month = $ts[4]+1;
  my $day = $ts[3];
  return sprintf("%4d%02d%02d",$year,$month,$day); 
}


sub fromISO2TS {
  my $iso = $_[0];
  if ($iso =~ m/(\d{4})(\d{2})(\d{2})/) {
	my $year = $1-1900;
	my $month = $2-1;
	my $day = $3;
	return timelocal(0,0,0,$day,$month,$year);
  }
}


sub addSpan{
  my ($timestamp,$span) = @_;
  my @ts = localtime $timestamp;
  my $year = $ts[5]+1900;
  my $month = $ts[4]+1;
  my $day = $ts[3];
  my $dt = DateTime->new(year	=> $year,
	                 month	=> $month, 
			 day	=> $day);
  if ($span=~/(\d+)d/) {
    $dt->add_duration(DateTime::Duration->new(days => $1));
      return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
  if ($span=~/(\d+)m/) {
      $dt->add_duration(DateTime::Duration->new(months => $1));
        return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
  if ($span=~/(\d+)y/) {
       $dt->add_duration(DateTime::Duration->new(years => $1));
        return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
}

sub subSpan{
  my ($timestamp,$span) = @_;
  my @ts = localtime $timestamp;
  my $year = $ts[5]+1900;
  my $month = $ts[4]+1;
  my $day = $ts[3];
  my $dt = DateTime->new(year	=> $year,
	                 month	=> $month, 
			 day	=> $day);
  if ($span=~/(\d+)d/) {
    $dt->subtract_duration(DateTime::Duration->new(days => $1));
      return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
  if ($span=~/(\d+)m/) {
      $dt->subtract_duration(DateTime::Duration->new(months => $1));
        return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
  if ($span=~/(\d+)y/) {
       $dt->subtract_duration(DateTime::Duration->new(years => $1));
        return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
  }
}


1;
