package App::WRT::Date;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK = qw(iso_date get_date get_mtime month_name);

use POSIX qw(strftime);

=head1 NAME

App::WRT::Date - a small collection of date utility functions

=head2 FUNCTIONS

=over

=item iso_date($time)

Return an ISO 8601 date string for the given epoch time.

=cut

sub iso_date {
  my ($time) = @_;
  return strftime("%Y-%m-%dT%H:%M:%SZ", localtime($time));
}

=item get_mtime(@filenames)

Return one or more mtimes for a given list of files.

=cut

sub get_mtime {
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

=item month_name($number)

Turn numeric months into English names.

=cut

{
  # "Null" is here so that $month_name[1] corresponds to January, etc.
  my @months = qw(Null January February March April May June
                  July August September October November December);

  sub month_name {
    my ($number) = @_;
    return $months[$number];
  }
}

=item get_date('key', 'other_key', ...)

Return current date values for the given key. Valid keys are sec, min, hour,
mday (day of month), mon, year, wday (day of week), yday (day of year), and
isdst (is daylight savings).

Remember that year is given in years after 1900.

=cut

# Below replaces:
# my ($sec, $min, $hour, $mday, $mon,
#     $year, $wday, $yday, $isdst) = localtime(time);
{
  my %name_map = (
    sec   => 0,  min   => 1, hour => 2, mday => 3,
    mon   => 4,  year  => 5, wday => 6, yday => 5,
    isdst => 6,
  );

  sub get_date {
    my (@names) = @_;
    my (@indices) = @name_map{@names};
    my (@values) = (localtime time)[@indices];

    if (wantarray()) {
        # my ($foo, $bar) = get_date('foo', 'bar');
        return @values;
    } else {
        # this is probably useless unless you're getting just one value
        return join '', @values;
    }
  }
}

=back

=cut

1;
