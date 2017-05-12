use strict;
use warnings;
package Data::OpeningHours;
use strict;
use 5.008_005;
our $VERSION = '0.4.2';

use parent 'Exporter';

our @EXPORT_OK = qw/is_open/;

sub is_open {
    my ($calendar, $now) = @_;
    return $calendar->is_open($now);
}

1;

=head1 NAME

Data::OpeningHours - Is a shop is open or closed at this moment?

=head1 SYNOPSYS

    use DateTime;
    use Data::OpeningHours 'is_open';
    use Data::OpeningHours::Calendar;

    my $cal = Data::OpeningHours::Calendar->new();
    $cal->set_week_day(1, [['13:00','18:00']]); # monday
    $cal->set_week_day(2, [['09:00','18:00']]);
    $cal->set_week_day(3, [['09:00','18:00']]);
    $cal->set_week_day(4, [['09:00','18:00']]);
    $cal->set_week_day(5, [['09:00','21:00']]);
    $cal->set_week_day(6, [['09:00','17:00']]);
    $cal->set_week_day(7, []);
    $cal->set_special_day('2012-01-01', []);
    is_open($cal, DateTime->now());

=head1 DESCRIPTION

Data::OpeningHours helps you create a widget that shows when a shop is open or
closed.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright 2013 - Peter Stuifzand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

