package App::MonM::Util; # $Id: Util.pm 23 2014-11-12 15:48:14Z abalama $
use strict;

=head1 NAME

App::MonM::Util - Exported util functions

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

use App::MonM::Util;

=head1 DESCRIPTION

Exported util functions

=head1 FUNCTIONS

=over

=item B<expire_calc>

Original this function is the part of CGI::Util::expire_calc!

This internal routine creates an expires time exactly some number of hours from the current time.
It incorporates modifications from  Mark Fisher.

format for time can be in any of the forms:

    now   -- expire immediately
    +180s -- in 180 seconds
    +2m   -- in 2 minutes
    +12h  -- in 12 hours
    +1d   -- in 1 day
    +3M   -- in 3 months
    +2y   -- in 2 years
    -3m   -- 3 minutes ago(!)

If you don't supply one of these forms, we assume you are specifying the date yourself

=back

=cut

use vars qw($VERSION);
$VERSION = 1.00;

use base qw/Exporter/;
our @EXPORT = qw(
        expire_calc
    );

sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
      $offset = 0;
    } elsif ($time=~/^\d+/) {
      return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
      $offset = ($mult{$2} || 1)*$1;
    } else {
      return $time;
    }
    my $cur_time = time;
    return ($cur_time+$offset);
}

1;
