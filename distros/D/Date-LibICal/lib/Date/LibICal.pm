package Date::LibICal;

use 5.012004;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( all => [ qw(expand_recurrence) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{all} } );
our @EXPORT      = qw();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Date::LibICal', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Date::LibICal - Perl wrapper for libical

=head1 SYNOPSIS

  use Date::LibICal;

  my @all_timeslots_in_epoch = Date::LibICal::expand_recurrence(
      'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
  );

alternatively with a fixed start Date

  use Date::LibICal;
  use Date::Time;

  my @timeslots_in_epoch = Date::LibICal::expand_recurrence(
      'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
      DateTime->new( year => 2012, month => 1, day => 1)->epoch,
  );

or with a fixed start Date and a max count of results:

  use Date::LibICal;
  use Date::Time;

  my @timeslots_in_epoch = Date::LibICal::expand_recurrence(
      'FREQ=MONTHLY;UNTIL=20130131T000000Z;INTERVAL=1;BYDAY=MO',
      DateTime->new( year => 2012, month => 1, day => 1)->epoch,
      10,
  );

To convert any of the results into something useful you can

  use DateTime;

  print
      join "\n",
      map {
          DateTime->from_epoch( epoch => $_ );
      } @timeslots_in_epoch;

=head1 DESCRIPTION

Date::LibICal is a non-complete interface for libical. Currently
it is only useful to convert implicit icals into a list of explicit
timeslots.

=head2 EXPORT

None by default.

Exportable methods are: expand_recurrence.

=head1 DEPENDENCIES

This module only works under Perl 5.12 or later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-date-libical@rt.cpan.org>, or through the web interface at
L<"http://rt.cpan.org"/"http://rt.cpan.org/">.

=head1 SEE ALSO

This package helps in doing implicit to explicit conversion like L<Date::ICal>
provides in a fast way, but with less features.

=head1 AUTHOR

Andreas 'ac0v' Specht  C<< <ac0v@sys-network.de> >>
Lukas Mai, C<< <l.mai at web.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Andreas 'ac0v' Specht C<< <ac0v@sys-network.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/"perlartistic">.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
