package DateTime::Format::Epoch::Unix;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

use DateTime;
use DateTime::Format::Epoch;

@ISA = qw/DateTime::Format::Epoch/;

my $epoch = DateTime->new( year => 1970, month => 1, day => 1 );

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

DateTime::Format::Epoch::Unix - Convert DateTimes to/from Unix epoch seconds

=head1 SYNOPSIS

  use DateTime::Format::Epoch::Unix;

  my $dt = DateTime::Format::Epoch::Unix->parse_datetime( 1051488000 );
   # 2003-04-28T00:00:00

  DateTime::Format::Epoch::Unix->format_datetime($dt);
   # 1051488000

  my $formatter = DateTime::Format::Epoch::Unix->new();
  my $dt2 = $formatter->parse_datetime( 1051488000 );
  $formatter->format_datetime($dt2);

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the number of seconds since the Unix
epoch.

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
