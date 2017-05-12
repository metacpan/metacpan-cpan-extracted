
package App::FQStat::Debug;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;
use Time::HiRes qw/time/;
use App::FQStat::Debug;

use base 'Exporter';
our %EXPORT_TAGS = (
  'all' => [qw(
   warnline 
   warnenter
  )],
);
our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};
our @EXPORT = @{$EXPORT_TAGS{'all'}};

sub warnline ($) {
  my $msg = shift;
  chomp($msg);
  my $time = time();
  my ($pkg, $file, $line) = caller();
  ::debug( sprintf("[% 6.2f]", $time - &::STARTTIME()) . " $msg at $file line $line\n" );
}

sub warnenter () {
  my $time = time();
  my ($fpkg, $ffile, $fline, $sub) = caller(1);
  ::debug( sprintf("[% 6.2f]", $time - &::STARTTIME()) . " Entering $sub from $ffile line $fline\n" );
}

1;

