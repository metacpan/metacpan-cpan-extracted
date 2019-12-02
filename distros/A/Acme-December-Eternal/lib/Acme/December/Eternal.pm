package Acme::December::Eternal;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(eternaldecemberize);
our $VERSION = '1.0';

use Date::Manip;
use Lingua::EN::Numbers::Ordinate;

sub eternaldecemberize {
    # Change date&time string to "Eternal december" date string
    my ($indateraw) = @_;

    my ($indate, $intime);
    if($indateraw =~ /\ /) {
        ($indate, $intime) = split/\ /, $indateraw;
        $intime = ' ' . $intime;
    } else {
        $indate = $indateraw;
        $intime = '';
    }

    my $result = '';

    my $date = Date::Manip::Date->new();
    $date->parse($indate);

    my $month = $date->printf('%m');
    $month =~ s/^0+//g;
    my $dayofyear = $date->printf('%j');
    $dayofyear =~ s/^0+//g;
    my $dayofmonth = $date->printf('%d');
    $dayofmonth =~ s/^0+//g;
    my $year = $date->printf('%Y');

    my $weekday = $date->printf('%a');
    $weekday .= ', ';

    # December starts on 1st of September...
    my $septstart = Date::Manip::Date->new();
    $septstart->parse($year . '-09-01');
    my $septday = $septstart->printf('%j');
    $septday =~ s/^0+//g;

    if($month == 8) {
        # August
        $result = $weekday . ordinate($dayofmonth) . ' August ' . $year;
    } else {
        # December
        if($month > 8) {
            my $daycount = $dayofyear - $septday + 1;
            $result = $weekday . ordinate($daycount) . ' December ' . $year
        } else {
            # Uh-oh, this is the continuation of last years december...
            my $decend = Date::Manip::Date->new();
            $decend->parse($year . '-12-31');
            my $decday = $decend->printf('%j');
            $decday =~ s/^0+//g;
            my $prevyeardays = $decday - $septday + 1;
            my $daycount = $dayofyear + $prevyeardays;
            $year--; # previous years december
            $result = $weekday . ordinate($daycount) . ' December ' . $year
        }
    }

    return $result;
}

1;
__END__

=head1 NAME

Acme::December::Eternal - Calculate the "canadian eternal december" date string accoring to stevieb

=head1 SYNOPSIS

  use Acme::December::Eternal;

  print eternaldecemberize('2019-10-18 10:28:00'), "\n";

=head1 DESCRIPTION

This module calculates a nicely formatted string for the "canadian eternal december" for any given date string.

According to stevieb on perlmonks, Canada has only two months per year. August (when it is warm), and the rest is
December (year starts with 1st of August). This module turns normal western dates into something more
useful to my Canadian friend.

=head2 eternalDecemberize()

This function takes a date string (anything that L<Date::Manip> can parse should be OK) and returns it formatted
as something like "Fri, 293th December 2019 10:28:23"

=head1 SEE ALSO

L<https://www.perlmonks.org/?node_id=11107642>

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
