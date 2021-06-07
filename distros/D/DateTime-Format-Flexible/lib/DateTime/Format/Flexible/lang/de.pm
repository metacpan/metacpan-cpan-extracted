package DateTime::Format::Flexible::lang::de;

use strict;
use warnings;

sub new
{
    my ( $class , %params ) = @_;
    my $self = bless \%params , $class;
    return $self;
}

sub months
{
    return (
        qr{Jan(?:uar)?}i        => 1,
        qr{Jän(?:er)?}i         => 1, # Austrian?!
        qr{Feb(?:ruar)?}i       => 2,
        qr{Mär(?:z)?|Maerz}i    => 3,
        qr{Apr(?:il)?}i         => 4,
        qr{Mai}i                => 5,
        qr{Jun(?:i)?}i          => 6,
        qr{Jul(?:i)?}i          => 7,
        qr{Aug(?:ust)?}i        => 8,
        qr{Sep(?:tember)?}i     => 9,
        qr{Okt(?:ober)?}i       => 10,
        qr{Nov(?:ember)?}i      => 11,
        qr{Dez(?:ember)?}i      => 12,
    );
}

sub days
{
    return [
        {Montag     => 1}, # Monday
        {Mo         => 1}, # Monday
        {Dienstag   => 2}, # Tuesday
        {Di         => 2}, # Tuesday
        {Mittwoch   => 3}, # Wednesday
        {Mi         => 3}, # Wednesday
        {Donnerstag => 4}, # Thursday
        {Do         => 4}, # Thursday
        {Freitag    => 5}, # Friday
        {Fr         => 5}, # Friday
        {Samstag    => 6}, # Saturday
        {Sa         => 6}, # Saturday
        {Sonnabend  => 6}, # Saturday
        {Sonntag    => 7}, # Sunday
        {So         => 7}, # Sunday
    ];
}

sub day_numbers
{
    return (
        q{erster}               => 1, # first
        q{ersten}               => 1, # first
        q{zweiter}              => 2, # second
        q{dritter}              => 3, # third
        q{vierter}              => 4, # fourth
        q{fünfter}              => 5, # fifth
        q{fuenfter}             => 5, # fifth
        q{sechster}             => 6, # sixth
        q{siebter}              => 7, # seventh
        q{achter}               => 8, # eighth
        q{neunter}              => 9, # ninth
        q{zehnter}              => 10, # tenth
        q{elfter}               => 11, # eleventh
        q{zwölfter}             => 12, # twelfth
        q{zwoelfter}            => 12, # twelfth
        q{dreizehnter}          => 13, # thirteenth
        q{vierzehnter}          => 14, # fourteenth
        q{vierzehnten}          => 14, # fourteenth
        q{fünfzehnter}          => 15, # fifteenth
        q{fuenfzehnter}         => 15, # fifteenth
        q{sechzehnter}          => 16, # sixteenth
        q{siebzehnter}          => 17, # seventeenth
        q{achtzehnter}          => 18, # eithteenth
        q{neunzehnter}          => 19, # ninteenth
        q{zwanzigster}          => 20, # twentieth
        q{einundzwanzigster}    => 21, # twenty first
        q{zweiundzwanzigster}   => 22, # twenty second
        q{dreiundzwanzigster}   => 23, # twenty third
        q{vierundzwanzigster}   => 24, # twenty fourth
        q{fünfundzwanzigster}   => 25, # twenty fifth
        q{fuenfundzwanzigster}  => 25, # twenty fifth
        q{sechsundzwanzigster}  => 26, # twenty sixth
        q{siebenundzwanzigster} => 27, # twenty seventh
        q{achtundzwanzigster}   => 28, # twenty eighth
        q{neunundzwanzigster}   => 29, # twenty ninth
        q{dreißigster}          => 30, # thirtieth
        q{dreissigster}         => 30, # thirtieth
        q{einunddreißigster}    => 31, # thirty first
        q{einunddreissigster}   => 31, # thirty first
    );
}

sub hours
{
    return (
        Mittag       => '12:00:00', # noon
        mittags      => '12:00:00', # noon
        Mitternacht  => '00:00:00', # midnight
        mitternachts => '00:00:00', # midnight
    );
}

sub remove_strings
{
    return (
        # we want to remove ' am ' only when it does not follow a digit
        # we also don't want to remove am when it follows a capital T,
        # we can have a capital T when we have already determined the time
        # part of a string
        # if we just remove ' am ', it removes am/pm designation, losing accuracy
        qr{(?<!\d|T)\sam\b}i, # remove ' am ' as in '20. Feb am Mittag'
        # we can also remove it if it is at the beginning
        qr{\A\bam\b}i,
        qr{\bum\b}i,        # remove ' um ' as in '20. Feb um Mitternacht'
    );
}

sub parse_time
{
    my ( $self, $date ) = @_;
    return $date;
}

sub string_dates
{
    my $base_dt = DateTime::Format::Flexible->base;
    return (
        jetzt   => sub { return $base_dt->datetime },                                                   # now
        heute   => sub { return $base_dt->clone->truncate( to => 'day' )->ymd } ,                       # today
        morgen  => sub { return $base_dt->clone->truncate( to => 'day' )->add( days => 1 )->ymd },      # tomorrow
        gestern => sub { return $base_dt->clone->truncate( to => 'day' )->subtract( days => 1 )->ymd }, # yesterday
        'übermorgen' => sub { return DateTime->today->add( days => 2 )->ymd },  # overmorrow (the day after tomorrow) don't know if the Umlaut works
        uebermorgen  => sub { return DateTime->today->add( days => 2 )->ymd },   # overmorrow (the day after tomorrow)
        Epoche       => sub { return DateTime->from_epoch( epoch => 0 ) },
        '-unendlich' => sub { return '-infinity' },
        unendlich    => sub { return 'infinity'  },
    );
}

sub relative
{
    return (
        # as in 3 years ago, -3 years
        ago  => qr{\bvor\b|\A\-}i,
        # as in 3 years from now, +3 years
        from => qr{\bab\b\s\bjetzt\b|\A\+}i,
        # as in next Monday
        next => qr{\bnächste|nachste\b}i,
        # as in last Monday
        last => qr{\bletzten\b}i,
    );
}

sub math_strings
{
    return (
        Jahr    => 'years' ,
        Jahre   => 'years' ,
        Jahren  => 'years' ,
        Monat   => 'months' ,
        Monate  => 'months' ,
        Tag     => 'days' ,
        Tage    => 'days' ,
        Stunde  => 'hours' ,
        Stunden => 'hours' ,
        Minute  => 'minutes' ,
        Minuten => 'minutes' ,
        Woche   => 'weeks',
        Wochen  => 'weeks',
    );
}

sub timezone_map
{
    # http://home.tiscali.nl/~t876506/TZworld.html
    return (
        CET  => 'Europe/Berlin',
        CEST => 'Europe/Berlin',
        MEZ  => 'Europe/Berlin', # German Version: Mitteleuropäische Zeit
        MESZ => 'Europe/Berlin', # Mitteleuropäische Sommerzeit
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Flexible::lang::de - german language plugin

=head1 DESCRIPTION

You should not need to use this module directly.

If you only want to use one language, specify the lang property when parsing a date.

example:

 my $dt = DateTime::Format::Flexible->parse_datetime(
     'Montag, 6. Dez 2010' ,
     lang => ['de']
 );
 # $dt is now 2010-12-06T00:00:00

Note that this is not required, by default ALL languages are scanned when trying to parse a date.

=head2 new

Instantiate a new instance of this module.

=head2 months

month name regular expressions along with the month numbers (Jan(:?uar)? => 1)

=head2 days

day name regular expressions along the the day numbers (Montag => 1)

=head2 day_numbers

maps day of month names to the corresponding numbers (erster => 01)

=head2 hours

maps hour names to numbers (Mittag => 12:00:00)

=head2 remove_strings

strings to remove from the date (um as in um Mitternacht)

=head2 parse_time

currently does nothing

=head2 string_dates

maps string names to real dates (jetzt => DateTime->now)

=head2 relative

parse relative dates (ago => vor, from => a jetzt, next => nachste, last => letzten)

=head2 math_strings

useful strings when doing datetime math

=head2 timezone_map

maps unofficial timezones to official timezones for this language (MEZ => Europe/Berlin)

=head1 AUTHOR

    Mark Trettin <nulldevice.mark@gmx.de>

    Based on DateTime::Format::Flexible::lang::en by
    Tom Heady
    CPAN ID: thinc
    Punch, Inc.
    cpan@punch.net
    http://www.punch.net/

=head1 COPYRIGHT & LICENSE

Copyright 2011 Mark Trettin.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

=item * the Artistic License version.

=back

=head1 SEE ALSO

F<DateTime::Format::Flexible>

=cut
### Local variables:
### coding: utf-8
### End:
