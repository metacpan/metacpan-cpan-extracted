package Class::Usul::Time;

use strict;
use warnings;

use Class::Usul::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use Class::Usul::Functions qw( ensure_class_loaded throw );
use Date::Format             ( );
use Exporter 5.57          qw( import );
use Time::HiRes            qw( usleep );
use Time::Local;
use Time::Zone;
use Unexpected::Functions  qw( DateTimeCoercion );

our @EXPORT    = qw( str2time time2str );
our @EXPORT_OK = qw( nap str2date_time str2time str2time_piece time2str );

# Private package variables
my $_datetime_loaded   = FALSE;
my $_time_piece_loaded = FALSE;

# Public functions
sub nap ($) {
   my $period = shift;

   $period = $period && $period =~ m{ \A [\d._]+ \z }msx && $period > 0
           ? $period : 1;

   return usleep( 1_000_000 * $period );
}

sub str2date_time ($;$) {
   my ($dstr, $zone) = @_; my $time = str2time( $dstr, $zone );

   defined $time or throw DateTimeCoercion, [ $dstr ];

   $_datetime_loaded or (ensure_class_loaded 'DateTime::Format::Epoch'
                         and $_datetime_loaded = TRUE);

   my $dt        = DateTime->new( year => 1970, month => 1, day => 1, );
   my $formatter = DateTime::Format::Epoch->new
      ( epoch             => $dt,
        unit              => 'seconds',
        type              => 'int',
        skip_leap_seconds => TRUE,
        start_at          => 0,
        local_epoch       => undef, );

   return $formatter->parse_datetime( $time );
}

sub str2time ($;$) {
   # This subroutine: Copyright (c) 1995 Graham Barr. All rights reserved.
   # British version dd/mm/yyyy
   my ($dtstr, $zone) = @_;

   (defined $dtstr and length $dtstr) or return;

   my ($year, $month, $day, $hh, $mm, $ss, $dst, $frac, $m, $h, $result);
   my %day =
      ( sunday    => 0, monday => 1, tuesday  => 2, tues => 2,
        wednesday => 3, wednes => 3, thursday => 4, thur => 4,
        thurs     => 4, friday => 5, saturday => 6, );
   my %month =
      ( january   => 0, february => 1, march   => 2, april    => 3,
        may       => 4, june     => 5, july    => 6, august   => 7,
        september => 8, sept     => 8, october => 9, november =>10,
        december  => 11, );
   my @suf = (qw( th st nd rd th th th th th th )) x 3;
      @suf[11, 12, 13] = qw( th th th );

     $day{ substr $_, 0, 3 } =   $day{ $_ } for (keys %day);
   $month{ substr $_, 0, 3 } = $month{ $_ } for (keys %month);

   my $daypat = join '|', reverse sort keys %day;
   my $monpat = join '|', reverse sort keys %month;
   my $sufpat = join '|', reverse sort @suf;
   my $dstpat = 'bst|dst';

   my %ampm = ( a => 0, p => 12 ); my ($AM, $PM) = ( 0, 12 );

   my $merid = 24; my @lt = localtime time;

   $dtstr = lc $dtstr;
   $zone  = tz_offset( $zone ) if ($zone);

   1 while ($dtstr =~ s{\([^\(\)]*\)}{ }mox);

   $dtstr =~ s{ (\A|\n|\z) }{ }gmox;
   $dtstr =~ s{ ([\d\w\s]) [\.\,] \s }{$1 }gmox;
   $dtstr =~ s{ , }{ }gmx;
   $dtstr =~ s{ ($daypat) \s* (den\s)? }{ }mox;

   return unless ($dtstr =~ m{ \S }mx);

   if ($dtstr =~ s{ \s (\d{4}) ([-:]?) # ccyy + optional separator - or : (1)
                       (\d\d?) \2      # mm(1 - 12) + same separator (1)
                       (\d\d?)         # dd(1 - 31)
                       (?:[Tt ]
                        (\d\d?)        # H or HH
                        (?:([-:]?)     # Optionally separator - or : (2)
                         (\d\d?)       # and M or MM
                         (?:\6         # Optionally same separator (2)
                          (\d\d?)      # and S or SS
                          (?:[.,]      # Optionally separator . or ,
                           (\d+) )?    # and fractions of a second
                          )? )? )?
                        (?=\D)
                     }{ }mx) {
      ($year, $month, $day, $hh, $mm, $ss, $frac)
         = ($1, $3-1, $4, $5, $7, $8, $9);
   }

   unless (defined $hh) {
      if ($dtstr =~ s{ [:\s] (\d\d?) : (\d\d?) ( : (\d\d?) (?:\.\d+)? )? \s*
                          (?:([ap]) \.?m?\.? )? \s }{ }mox) {
         ($hh, $mm, $ss) = ($1, $2, $4 || 0);
         $merid          = $ampm{ $5 } if ($5);
      }
      elsif ($dtstr =~ s{ \s (\d\d?) \s* ([ap]) \.?m?\.? \s }{ }mox) {
         ($hh, $mm, $ss) = ($1, 0, 0);
         $merid          = $ampm{ $2 };
      }
   }

   if (defined $hh && $hh <= 12 && $dtstr =~ s{ ([ap]) \.?m?\.? \s }{ }mox) {
      $merid = $ampm{ $1 };
   }

   unless (defined $year) {
   TRY: {
      if ($dtstr =~ s{ \s (\d\d?) ([^\d_]) ($monpat) (\2(\d\d+))? \s}{ }mox) {
         ($year, $month, $day) = ($5, $month{ $3 }, $1);
         last TRY;
      }

      if ($dtstr =~ s{ \s (\d+) ([\-\./]) (\d\d?) (\2(\d+))? \s }{ }mox) {
         ($year, $month, $day) = ($5, $3 - 1, $1);
         ($year, $day)         = ($1, $5) if ($day > 31);

         return if (length $year > 2 and $year < 1901);
         last TRY;
      }

      if ($dtstr =~ s{ \s (\d+) \s* ($sufpat)? \s* ($monpat) }{ }mox) {
         ($month, $day) = ($month{ $3 }, $1);
         last TRY;
      }

      if ($dtstr =~ s{ ($monpat) \s* (\d+) \s* ($sufpat)? \s }{ }mox) {
         ($month, $day) = ($month{ $1 }, $2);
         last TRY;
      }

      if ($dtstr =~ s{ \s (\d\d) (\d\d) (\d\d) \s }{ }mox) {
         ($year, $month, $day) = ($3, $2 - 1, $1);
      }
      } # TRY

      if (! defined $year && $dtstr =~ s{ \s (\d{2} (\d{2})?)[\s\.,] }{ }mox) {
         $year = $1;
      }
   }

   $dst = 1 if ($dtstr =~ s{ \b ($dstpat) \b }{}mox);

   if ($dtstr =~ s{ \s \"? ([a-z]{3,4})
                       ($dstpat|\d+[a-z]*|_[a-z]+)? \"? \s }{ }mox) {
      $zone  = tz_offset( $1 || 0 );
      $dst   = 1 if ($2 && $2 =~ m{ $dstpat }msx);

      return unless (defined $zone);
   }
   elsif ($dtstr =~ s{ \s ([a-z]{3,4})? ([\-\+]?) -?
                          (\d\d?) :? (\d\d)? (00)? \s }{ }mox) {
      $zone  = tz_offset( $1 || 0 );

      return unless (defined $zone);

      $h     = "$2$3";
      $m     = defined $4 ? "$2$4" : 0;
      $zone += 60 * ($m + (60 * $h));
   }

   if ($dtstr =~ m{ \S }msx) {
      if ($dtstr =~ s{ \A \s*(ut?|z)\s* \z }{}msx) {
         $zone  = 0;
      }
      elsif ($dtstr =~ s{ \s ([a-z]{3,4})? ([\-\+]?) -?
                             (\d\d?) (\d\d)? (00)? \s }{ }mox) {
         $zone  = tz_offset( $1 || 0 );

         return unless (defined $zone);

         $h     = "$2$3";
         $m     = defined $4 ? "$2$4" : 0;
         $zone += 60 * ($m + (60 * $h));
      }

      return if ($dtstr =~ m{ \S }mox);
   }

   if (defined $hh) {
      if ($hh == 12) { $hh = 0 if ($merid == $AM) }
      elsif ($merid == $PM) { $hh += 12 }
   }

# This is a feature in the original code RT#53413 and RT#105031
#   $year -= 1900   if     (defined $year && $year > 1900);
   $zone += 3600   if     (defined $zone && $dst);
   $month = $lt[4] unless (defined $month);
   $day   = $lt[3] unless (defined $day);

   unless (defined $year) {
      $year = $month > $lt[4] ? $lt[5] - 1 : $lt[5];
   }

   $hh    = 0 unless (defined $hh);
   $mm    = 0 unless (defined $mm);
   $ss    = 0 unless (defined $ss);
   $frac  = 0 unless (defined $frac);

   return unless ($month <= 11 && $day >= 1 && $day <= 31
                  && $hh <= 23 && $mm <= 59 && $ss <= 59);

   if (defined $zone) {
      $result = eval {
         local $SIG{__DIE__} = sub {}; # Ick!
         timegm( $ss, $mm, $hh, $day, $month, $year );
      };

      return if (! defined $result ||
                 ($result == -1
                  && (join q(), $ss, $mm, $hh, $day, $month, $year)
                  ne '595923311169'));

      $result -= $zone;
   }
   else {
      $result = eval {
         local $SIG{__DIE__} = sub {}; # Ick!
         timelocal( $ss, $mm, $hh, $day, $month, $year );
      };

      return if (! defined $result ||
                 ($result == -1
                  && (join q(), $ss, $mm, $hh, $day, $month, $year)
                  ne  join q(), (localtime -1)[0 .. 5]));
   }

   return $result + $frac;
}

sub str2time_piece ($;$) {
   my ($dstr, $zone) = @_; my $time = str2time( $dstr, $zone );

   defined $time or throw DateTimeCoercion, [ $dstr ];

   $_time_piece_loaded
      or (ensure_class_loaded 'Time::Piece' and $_time_piece_loaded = TRUE);

   return $zone ? Time::Piece->gmtime( $time ) : Time::Piece->localtime( $time);
}

sub time2str (;$$$) {
   my ($format, $time, $zone) = @_;

   $format //= '%Y-%m-%d %H:%M:%S'; $time //= time;

   return Date::Format::Generic->time2str( $format, $time, $zone );
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Class::Usul::Time - Functions for date and time manipulation

=head1 Synopsis

   use Class::Usul::Time qw( time2str );

=head1 Description

This module implements a few simple time related functions

=head1 Subroutines/Methods

=head2 nap

   nap( $period );

Sleep for a given number of seconds. The sleep time can be a fraction
of a second

=head2 str2date_time

   $date_time = str2date_time( $dstr, [$zone] );

Parse a date time string and return a L<DateTime> object. The time zone is
optional

=head2 str2time

   $time = str2time( $dstr, [$zone] );

Parse a date time string and return the number of seconds elapsed
since the epoch. This subroutine is copyright (c) 1995 Graham
Barr. All rights reserved. It has been modified to treat 9/11 as the
ninth day in November. The time zone is optional

=head2 str2time_piece

   $time_piece = str2time_piece( $dstr, [$zone] );

Parse a date time string and return a L<Time::Piece> object. The time
zone is optional

=head2 time2str

   $time_string = time2str( [$format], [$time], [$zone] );

Returns a formatted string representation of the given time (supplied
in seconds elapsed since the epoch). Defaults to ISO format (%Y-%m-%d
%H:%M:%S) and current time if non supplied. The timezone defaults to
local time

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<DateTime::Format::Epoch>

=item L<Time::HiRes>

=item L<Time::Local>

=item L<Time::Zone>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module.

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
