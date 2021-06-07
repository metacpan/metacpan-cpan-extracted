package DateTime::Format::Flexible::lang::en;

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
        qr{Jan(?:uary)?}i        => 1,
        qr{Feb(?:ruary)?}i       => 2,
        qr{Mar(?:ch)?}i          => 3,
        qr{Apr(?:il)?}i          => 4,
        qr{May}i                 => 5,
        qr{Jun(?:e)?}i           => 6,
        qr{Jul(?:y)?}i           => 7,
        qr{Aug(?:ust)?}i         => 8,
        qr{Sep(?:t)?(?:ember)?}i => 9,
        qr{Oct(?:ober)?}i        => 10,
        qr{Nov(?:ember)?}i       => 11,
        qr{Dec(?:ember)?}i       => 12,
    );
}

sub days
{
    # order is important here, otherwise
    # we end up removing "Mon" and leaving "day"
    return [
        {Monday    => 1},
        {Mon       => 1},
        {Tuesday   => 2},
        {Tue       => 2},
        {Wednesday => 3},
        {Wed       => 3},
        {Thursday  => 4},
        {Thurs     => 4},
        {Thu       => 4},
        {Friday    => 5},
        {Fri       => 5},
        {Saturday  => 6},
        {Sat       => 6},
        {Sunday    => 7},
        {Sun       => 7},
    ];
}

sub day_numbers
{
    return (
        q{first}          => 1,
        q{second}         => 2,
        q{third}          => 3,
        q{fourth}         => 4,
        q{fifth}          => 5,
        q{sixth}          => 6,
        q{seventh}        => 7,
        q{eighth}         => 8,
        q{ninth}          => 9,
        q{tenth}          => 10,
        q{eleventh}       => 11,
        q{twelfth}        => 12,
        q{thirteenth}     => 13,
        q{fourteenth}     => 14,
        q{fifteenth}      => 15,
        q{sixteenth}      => 16,
        q{seventeenth}    => 17,
        q{eithteenth}     => 18,
        q{ninteenth}      => 19,
        q{twentieth}      => 20,
        q{twentyfirst}    => 21,
        q{twenty first}   => 21,
        q{twentysecond}   => 22,
        q{twenty second}  => 22,
        q{twentythird}    => 23,
        q{twenty third}   => 23,
        q{twentyfourth}   => 24,
        q{twenty fourth}  => 24,
        q{twentyfifth}    => 25,
        q{twenty fifth}   => 25,
        q{twentysixth}    => 26,
        q{twenty sixth}   => 26,
        q{twentyseventh}  => 27,
        q{twenty seventh} => 27,
        q{twentyninth}    => 29,
        q{twenty ninth}   => 29,
        q{thirtieth}      => 30,
        q{thirtyfirst}    => 31,
        q{thirty first}   => 31,
    );
}

sub hours
{
    return (
        noon     => '12:00:00',
        midnight => '00:00:00',
        one      => '01:00:00',
        two      => '02:00:00',
        three    => '03:00:00',
        four     => '04:00:00',
        five     => '05:00:00',
        six      => '06:00:00',
        seven    => '07:00:00',
        eight    => '08:00:00',
        nine     => '09:00:00',
        ten      => '10:00:00',
        eleven   => '11:00:00',
        twelve   => '12:00:00',
    );
}

sub remove_strings
{
    return (
        # remove ' of ' as in '16th of November 2003'
        qr{\bof\b}i,
        # remove number extensions. 1st, etc
        # these must be following a digit, which
        # is not captured.
        qr{(?<=\d)(?:st|nd|rd|th)\b,?}i,
        # next sunday
        qr{\bnext\b}i,
    );
}

sub parse_time
{
    my ( $self, $date ) = @_;

    return $date if ( not $date =~ m{\s?at\s?}mx );

    my ( $pre, $time, $post ) = $date =~ m{\A(.+)?\s?at\s?([\d\.:]+)(.+)?\z}mx;

    # this will remove warnings if we don't have values for some of the variables
    # eg: not a date matches on the 'at' in date
    $pre  ||= q{};
    $time ||= q{};
    $post ||= q{};

    # if there is an 'at' string, we want to remove any time that was set on the date by default
    # 20050612T12:13:14 <-- T12:13:14
    $pre =~ s{T[^\s]+}{};

    $date = $pre . 'T' . $time . 'T' . $post;
    return $date;
}

sub string_dates
{
    my $base_dt = DateTime::Format::Flexible->base;

    return (
        now         => sub { return $base_dt->datetime } ,
        today       => sub { return $base_dt->clone->truncate( to => 'day' )->ymd } ,
        tomorrow    => sub { return $base_dt->clone->truncate( to => 'day' )->add( days => 1 )->ymd },
        yesterday   => sub { return $base_dt->clone->truncate( to => 'day' )->subtract( days => 1 )->ymd },
        overmorrow  => sub { return $base_dt->clone->truncate( to => 'day' )->add( days => 2 )->ymd },
        allballs    => sub { return $base_dt->clone->truncate( to => 'day' ) },

        epoch       => sub { return DateTime->from_epoch( epoch => 0 ) },
        '-infinity' => sub { '-infinity' },
        infinity    => sub { 'infinity'  },
    );
}

sub relative
{
    return (
        # as in 3 years ago, -3 years
        ago  => qr{\bago\b|\A\-}i,
        # as in 3 years from now, +3 years
        from => qr{\bfrom\b\s\bnow\b|\A\+}i,
        # as in next Monday
        next => qr{\bnext\b}i,
        # as in last Monday
        last => qr{\blast\b}i,
    );
}

sub math_strings
{
    return (
        year   => 'years' ,
        years  => 'years' ,
        month  => 'months' ,
        months => 'months' ,
        day    => 'days' ,
        days   => 'days' ,
        hour   => 'hours' ,
        hours  => 'hours' ,
        minute => 'minutes' ,
        minutes => 'minutes' ,
        week   => 'weeks',
        weeks  => 'weeks',
    );
}

sub timezone_map
{
    # http://home.tiscali.nl/~t876506/TZworld.html
    return (
        EST => 'America/New_York',
        EDT => 'America/New_York',
        CST => 'America/Chicago',
        CDT => 'America/Chicago',
        MST => 'America/Denver',
        MDT => 'America/Denver',
        PST => 'America/Los_Angeles',
        PDT => 'America/Los_Angeles',
        AKST => 'America/Juneau',
        AKDT => 'America/Juneau',
        HAST => 'America/Adak',
        HADT => 'America/Adak',
        HST => 'Pacific/Honolulu',
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

DateTime::Format::Flexible::lang::en - the english language plugin

=head1 DESCRIPTION

You should not need to use this module directly.

If you only want to use one language, specify the lang property when parsing a date.

example:

 my $dt = DateTime::Format::Flexible->parse_datetime(
     'Wed, Jun 10, 2009' ,
     lang => ['en']
 );
 # $dt is now 2009-06-10T00:00:00

Note that this is not required, by default ALL languages are scanned when trying to parse a date.

=head2 new

Instantiate a new instance of this module.

=head2 months

month name regular expressions along with the month numbers (Jan(?:uary)? => 1)

=head2 days

day name regular expressions along the the day numbers (Mon(?:day)? => 1)

=head2 day_numbers

maps day of month names to the corresponding numbers (first => 01)

=head2 hours

maps hour names to numbers (noon => 12:00:00)

=head2 remove_strings

strings to remove from the date (rd as in 3rd)

=head2 parse_time

searches for the string 'at' to help determine a time substring (sunday at 3:00)

=head2 string_dates

maps string names to real dates (now => DateTime->now)

=head2 relative

parse relative dates (ago => ago, from => from now, next => next, last => last)

=head2 math_strings

useful strings when doing datetime math

=head2 timezone_map

maps unofficial timezones to official timezones for this language (CST => America/Chicago)


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
