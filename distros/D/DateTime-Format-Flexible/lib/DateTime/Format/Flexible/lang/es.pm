package DateTime::Format::Flexible::lang::es;

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
    # http://llts.stanford.edu/months.html
    # http://www.tarver-genealogy.net/aids/spanish/sp_dates_num.html#days
    return (
        qr{enero|enro|eno}i    => 1,
        qr{febr(?:ero)?|febo}i => 2,
        qr{marzo|mzo}i         => 3,
        qr{abr(?:il)?|abl}i    => 4,
        qr{\bmayo\b}i          => 5,
        qr{jun(?:io)?}i        => 6,
        qr{jul(?:io)?}i        => 7,
        qr{agosto|agto}i       => 8,
        qr{sept(?:iembre)}i    => 9,
        qr{septe|set}i         => 9,
        qr{oct(?:ubre)?}i      => 10,
        qr{nov(?:iembre)?}i    => 11,
        qr{novbre}i            => 11,
        qr{dic(?:iembre)?}i    => 12,
        qr{dice}i              => 12,
    );
}

sub days
{
    # http://www.tarver-genealogy.net/aids/spanish/sp_dates_num.html#days
    return [
        {q{lunes}     => 1}, # Monday
        {q{martes}    => 2}, # Tuesday
        {q{miércoles} => 3}, # Wednesday
        {q{jueves}    => 4}, # Thursday
        {q{viernes}   => 5}, # Friday
        {q{sábado}    => 6}, # Saturday
        {q{domingo}   => 7}, # Sunday
    ];
}

sub day_numbers
{
    # http://www.tarver-genealogy.net/aids/spanish/sp_dates_num.html#days
    return (
        q{primero}           => 1, # first
        q{segundo}           => 2, # second
        q{tercero}           => 3, # third
        q{cuarto}            => 4, # fourth
        q{quinto}            => 5, # fifth
        q{sexto}             => 6, # sixth
        q{septimo}           => 7, # seventh
        q{octavo}            => 8, # eighth
        q{nono|noveno}       => 9, # ninth
        q{decimo}            => 10, # tenth
        q{undecimo}          => 11, # eleventh
        q{decimoprimero}     => 11, # eleventh
        q{duodecimo}         => 12, # twelfth
        q{decimosegundo}     => 12, # twelfth
        q{decimotercero}     => 13, # thirteenth
        q{decimocuarto}      => 14, # fourteenth
        q{decimoquinto}      => 15, # fifteenth
        q{decimosexto}       => 16, # sixteenth
        q{decimo septimo}    => 17, # seventeenth
        q{decimoctavo}       => 18, # eithteenth
        q{decimonono}        => 19, # ninteenth
        q{vigesimo}          => 20, # twentieth
        q{vigesimo primero}  => 21, # twenty first
        q{vigesimo segundo}  => 22, # twenty second
        q{vigesimo tercero}  => 23, # twenty third
        q{vigesimo cuarto}   => 24, # twenty fourth
        q{veinticuatro}      => 24, # twenty four
        q{vigesimo quinto}   => 25, # twenty fifth
        q{vigesimo sexto}    => 26, # twenty sixth
        q{vigesimo septimo}  => 27, # twenty seventh
        q{vigesimo octavo}   => 28, # twenty eighth
        q{vigesimo nono}     => 29, # twenty ninth
        q{trigesimo}         => 30, # thirtieth
        q{trigesimo primero} => 31, # thirty first
    );
}

sub hours
{
    return (
        mediodia   => '12:00:00', # noon
        medianoche => '00:00:00', # midnight
    );
}

sub remove_strings
{
    return (
        qr{\bde\b}i, # remove ' de ' as in '29 de febrero de 1996'
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
        ahora  => sub { return $base_dt->datetime },                                                   # now
        hoy    => sub { return $base_dt->clone->truncate( to => 'day' )->ymd } ,                       # today
        manana => sub { return $base_dt->clone->truncate( to => 'day' )->add( days => 1 )->ymd },      # tomorrow
        ayer   => sub { return $base_dt->clone->truncate( to => 'day' )->subtract( days => 1 )->ymd }, # yesterday
        'pasado manana' => sub { return DateTime->today->add( days => 2 )->ymd },                      # overmorrow (the day after tomorrow)
        epoca       => sub { return DateTime->from_epoch( epoch => 0 ) },
        '-infinito' => sub { return '-infinity' },
        infinito    => sub { return 'infinity'  },
    );
}

sub relative
{
    return (
        # as in 3 years ago, -3 years
        ago  => qr{\bhace\b|\A\-}i,
        # as in 3 years from now, +3 years
        from => qr{\ba\b\s\bpartir\b\s\bde\b\s\bahora\b|\A\+}i,
        # as in next Monday
        next => qr{\bsiguiente\b}i,
        # as in last Monday
        last => qr{\bpasado\b}i,
    );
}

sub math_strings
{
    return (
        ano     => 'years' ,
        anos    => 'years' ,
        'años'  => 'years' ,
        mes     => 'months' ,
        meses   => 'months' ,
        dia     => 'days' ,
        dias    => 'days' ,
        hora    => 'hours' ,
        horas   => 'hours' ,
        minuto  => 'minutes' ,
        minutos => 'minutes' ,
        semana  => 'weeks',
        semanas => 'weeks',
    );
}

sub timezone_map
{
    # http://home.tiscali.nl/~t876506/TZworld.html
    return (
        CET  => 'Europe/Madrid',
        CEST => 'Europe/Madrid',
        CST  => 'America/Cancun',
        CDT  => 'America/Cancun',
        MST  => 'America/Chihuahua',
        MDT  => 'America/Chihuahua',
        PST  => 'America/Tijuana',
        PDT  => 'America/Tijuana',
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Flexible::lang::es - spanish language plugin

=head1 DESCRIPTION

You should not need to use this module directly.

If you only want to use one language, specify the lang property when parsing a date.

example:

 my $dt = DateTime::Format::Flexible->parse_datetime(
     '29 de febrero de 1996' ,
     lang => ['es']
 );
 # $dt is now 1996-02-29T00:00:00

Note that this is not required, by default ALL languages are scanned when trying to parse a date.

=head2 new

Instantiate a new instance of this module.

=head2 months

month name regular expressions along with the month numbers (enero|enro|eno => 1)

=head2 days

day name regular expressions along the the day numbers (lunes => 1)

=head2 day_numbers

maps day of month names to the corresponding numbers (primero => 01)

=head2 hours

maps hour names to numbers (ediodia => 12:00:00)

=head2 remove_strings

strings to remove from the date (de as in cinco de mayo)

=head2 parse_time

currently does nothing

=head2 string_dates

maps string names to real dates (ahora => DateTime->now)

=head2 relative

parse relative dates (ago => hace, from => a partir de ahora, next => siguiente, last => pasado)

=head2 math_strings

useful strings when doing datetime math

=head2 timezone_map

maps unofficial timezones to official timezones for this language (PDT  => America/Tijuana)

=head1 AUTHOR

    Tom Heady
    CPAN ID: thinc
    Punch, Inc.
    cpan@punch.net
    http://www.punch.net/

=head1 COPYRIGHT & LICENSE

Copyright 2011 Tom Heady.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
    Software Foundation; either version 1, or (at your option) any
    later version, or

=item * the Artistic License.

=back

=head1 SEE ALSO

F<DateTime::Format::Flexible>

=cut
