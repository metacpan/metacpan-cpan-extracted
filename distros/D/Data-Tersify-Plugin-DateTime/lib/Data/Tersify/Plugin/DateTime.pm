package Data::Tersify::Plugin::DateTime;

use strict;
use warnings;

use DateTime;

our $VERSION = '1.000';
$VERSION = eval $VERSION;

=head1 NAME

Data::Tersify::Plugin::DateTime - tersify DateTime objects

=head1 SYNOPSIS

 use Data::Tersify;
 print dumper(tersify({ now => DateTime->now }));
 # Prints just today's date and time in yyyy-mm-ss hh:mm:ss format,
 # rather than a full screen of DateTime internals

=head1 DESCRIPTION

This class provides terse description for DateTime objects.

=head2 handles

It handles DateTime objects only.

=cut

sub handles { 'DateTime' }

=head2 tersify

It summarises DateTime objects into human-readable representations, using
variants of the One True Date format.

If the time is 00:00:00, it returns I<yyyy-mm-dd>; if there's a more interesing
time, it returns I<yyyy-mm-dd hh:mm:ss>. If there's also a non-floating
timezone, it returns details of that timezone as well, so
I<yyyy-mm-dd hh:mm:ss Time/Zone>.

=cut

sub tersify {
    my ($self, $datetime) = @_;

    my $terse = $datetime->ymd;
    if ($datetime->hms ne '00:00:00') {
        $terse .= ' ' . $datetime->hms;
        if ($datetime->time_zone->name ne 'floating') {
            $terse .= ' ' . $datetime->time_zone->name;
        }
    }
    return $terse;
}

1;

