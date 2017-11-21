package App::WRT::Date;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(iso_date get_mtime);

use POSIX qw(strftime);

# Return an ISO 8601 date string for the given epoch time.
sub iso_date {
  my ($time) = @_;
  return strftime("%Y-%m-%dT%H:%M:%SZ", localtime($time));
}

sub get_mtime
{
  my (@filenames) = @_;

  my @mtimes; 
  for my $filename (@filenames) {
    #my( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
    #    $atime, $mtime, $ctime, $blksize, $blocks )
    #   = stat( $filename );

    push @mtimes, (stat $filename)[9];
  }

  # return a list if we've got more than one, a scalar
  # otherwise.  is this evil? or even necessary?
  if (@mtimes > 1) {
    return @mtimes;
  } else {
    return $mtimes[0];
  }
}


1;
