package DateTime::Format::Epoch::RJD;

use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.13';

use DateTime;
use DateTime::Format::Epoch;

@ISA = qw/DateTime::Format::Epoch/;

my $epoch = DateTime->new( year => 1858, month => 11, day => 16,
                           hour => 12 );

sub new {
	my $class = shift;

    return $class->SUPER::new( epoch => $epoch,
                               unit  => 1/86400,
                               type  => 'float',
                               skip_leap_seconds => 1 );
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch::RJD - Convert DateTimes to/from Reduced Julian Days

=head1 SYNOPSIS

  use DateTime::Format::Epoch::RJD;

  my $dt = DateTime::Format::Epoch::RJD->parse_datetime( 53244.5 );
   # 2004-08-27T00:00:00
  DateTime::Format::Epoch::RJD->format_datetime($dt);
   # 53244.5

  my $formatter = DateTime::Format::Epoch::RJD->new();

  my $dt2 = $formatter->parse_datetime( 53244.5 );
   # 2004-08-27T00:00:00

  $formatter->format_datetime($dt2);
   # 53244.5

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the Reduced Julian Day number. See
L<DateTime::Format::Epoch::JD> for a description.

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

Copyright (c) 2004 Eugene van der Pijll.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
