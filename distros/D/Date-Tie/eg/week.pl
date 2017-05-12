#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Date::Tie;

sub iso { 
	$self = shift; 
	return $self->{year} . '-' . $self->{month} . '-' . $self->{day} . " $self->{weekyear}-W$self->{week}-$self->{weekday}"; 
}

    tie %date, 'Date::Tie';
print iso(\%date),"\n";
	%date = ( year => 2001, month => 12, day => 31 );
print iso(\%date),"\n";
print "Week day: $date{weekday}\n"; 

$date{weekday}++;
print iso(\%date),"\n";
$date{week}++;
print iso(\%date),"\n";

$date{year} = 1976;
$date{weekday} = 1;
$date{week} = 1;
print iso(\%date),"\n";

$date{weekyear}++;
print iso(\%date),"\n";

$date{weekyear}-=2;
print iso(\%date),"\n";

$date{yearday} = 32;
print iso(\%date),"\n";

$date{yearday}--;
print iso(\%date),"\n";

$date{weekday} = 7;
print iso(\%date),"\n";

$date{weekday} = 0;
print iso(\%date),"\n";

$date{weekday} = -7;
print iso(\%date),"\n";

	$date{year}++;
print iso(\%date),"\n";
	$date{month} += 12;
print iso(\%date),"\n";

1;
