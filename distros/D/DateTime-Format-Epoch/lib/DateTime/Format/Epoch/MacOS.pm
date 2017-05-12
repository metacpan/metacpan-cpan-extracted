package DateTime::Format::Epoch::MacOS;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

use DateTime;
use DateTime::Format::Epoch;

@ISA = qw/DateTime::Format::Epoch/;

my $epoch = DateTime->new( year => 1904, month => 1, day => 1,
                           time_zone => 'floating' );

sub new {
	my $class = shift;

    return $class->SUPER::new( epoch => $epoch,
                               unit  => 'seconds',
                               type  => 'int',
                               local_epoch => 1,
                               skip_leap_seconds => 1 );
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch::MacOS - Convert DateTimes to/from Mac OS epoch seconds

=head1 SYNOPSIS

  use DateTime::Format::Epoch::MacOS;

  my $dt = DateTime::Format::Epoch::MacOS->parse_datetime( 1051488000 );
  DateTime::Format::Epoch::MacOS->format_datetime($dt);
   # 1051488000

  my $formatter = DateTime::Format::Epoch::MacOS->new();

  my $dt2 = $formatter->parse_datetime( 1051488000 );

  $formatter->format_datetime($dt2);
   # 1051488000

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the number of seconds since the Mac OS
epoch.

Note that the Mac OS epoch is defined in the I<local> time zone. This
means that these two pieces of code will print the same number of
seconds, even though they represent two datetimes 6 hours apart:

    $dt = DateTime->new( year => 2003, month => 5, day => 2,
                         time_zone => 'Europe/Amsterdam' );
    print $formatter->format_datetime($dt);

    $dt = DateTime->new( year => 2003, month => 5, day => 2,
                         time_zone => 'America/Chicago' );
    print $formatter->format_datetime($dt);

Mac OS X is a Unix system, and uses the Unix epoch
(1970-01-01T00:00:00). Use DateTime::Format::Epoch::Unix instead.

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

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
