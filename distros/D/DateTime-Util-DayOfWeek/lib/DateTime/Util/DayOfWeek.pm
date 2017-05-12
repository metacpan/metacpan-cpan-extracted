package DateTime::Util::DayOfWeek;
use strict;
use warnings;
our $VERSION = '0.05';
use 5.008001;

{
    package # hide from pause
        DateTime;
    sub is_monday    { shift->day_of_week == 1 }
    sub is_tuesday   { shift->day_of_week == 2 }
    sub is_wednesday { shift->day_of_week == 3 }
    sub is_thursday  { shift->day_of_week == 4 }
    sub is_friday    { shift->day_of_week == 5 }
    sub is_saturday  { shift->day_of_week == 6 }
    sub is_sunday    { shift->day_of_week == 7 }
}

1;
__END__

=head1 NAME

DateTime::Util::DayOfWeek - DateTime Day of Week Utilities

=head1 SYNOPSIS

  use DateTime;
  use DateTime::Util::DayOfWeek;
  my $dt = DateTime->today;
  print "today is sunday\n" if $dt->is_sunday;
  # This is equivalent to:
  print "today is sunday\n" if $dt->is_sunday;

=head1 DESCRIPTION

DateTime::Util::DayOfWeek is day of week utilities for DateTime.This module
extends is_(sunday|mondy|tuesday|wednesday|thursday|friday) methods to DateTime
object.

=head1 METHODS

=head2 is_monday

=head2 is_tuesday

=head2 is_wednesday

=head2 is_thursday

=head2 is_friday

=head2 is_saturday

=head2 is_sunday

judgement the day of week.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhiro at mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 THANKS TO

Tatsuhiko Miyagawa, and #catalyst-ja members.

=head1 DEPENDENCIES

L<DateTime>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
