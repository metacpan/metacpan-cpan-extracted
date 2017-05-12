package DateTime::Format::Epoch::NTP;

use strict;
use warnings;

use vars qw($VERSION @ISA);

$VERSION = '0.14';

use DateTime;
use DateTime::Format::Epoch;

@ISA = qw/DateTime::Format::Epoch/;

my $epoch = DateTime->new( year => 1900, month => 1, day => 1,
                           time_zone => 'UTC' );

sub new {
	my $class = shift;

    return $class->SUPER::new( epoch => $epoch,
                               unit  => 'seconds',
                               type  => 'int',
                               skip_leap_seconds => 1 );
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch::NTP - Convert DateTimes to/from NTP epoch seconds

=head1 SYNOPSIS

  use DateTime::Format::Epoch::NTP;

  my $dt = DateTime::Format::Epoch::NTP->parse_datetime( 3629861151 );
  print $dt->datetime; # '2015-01-10T06:45:51'

  my $formatter = DateTime::Format::Epoch::NTP->new();
  my $dt = DateTime->new( year => 2015, month => 1, day => 10,
    time_zone => 'Europe/Amsterdam' );
  print $formatter->format_datetime($dt); # '3629833200'

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the number of seconds since the NTP
epoch.

The NTP epoch uses UTC; if you parse an NTP date your DateTime object
will be using the UTC timezone.

=head1 METHODS

Most of the methods are the same as those in L<DateTime::Format::Epoch>.
The only difference is the constructor.

=over 4

=item * new()

Constructor of the formatter/parser object. It has no parameters.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 COPYRIGHT

Copyright (c) 2015 Michiel Beijen. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
