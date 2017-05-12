
=head1 NAME

DateTime::Calendar::Discordian - Perl extension for the Discordian Calendar

=head1 SYNOPSIS

  use DateTime::Calendar::Discordian;

=head1 ABSTRACT

A module that implements the Discordian calendar made popular(?) in the
"Illuminatus!" trilogy by Robert Shea and Robert Anton Wilson and by the
Church of the SubGenius.

=cut

package DateTime::Calendar::Discordian;

use strict;
use warnings;
use 5.010;
use Carp;
use DateTime::Locale;
use Params::Validate qw( validate SCALAR OBJECT UNDEF);

=head1 VERSION

This document describes DateTime::Calendar::Discordian version 1.0

=cut

our $VERSION = '1.0';

=head1 DESCRIPTION

=head2 The Discordian Calendar

=head3 Seasons 

	Name            Patron apostle
	----            --------------
	Chaos           Hung Mung
	Discord         Dr. Van Van Mojo
	Confusion       Sri Syadasti
	Bureaucracy	    Zarathud
	The Aftermath   The Elder Malaclypse

Each season contains 73 consecutively numbered days.

=head3 Holydays

	Apostle Holydays    Season Holydays
	----------------    ---------------
	1) Mungday          1) Chaoflux
	2) Mojoday          2) Discoflux
	3) Syaday           3) Confuflux
	4) Zaraday          4) Bureflux
	5) Maladay          5) Afflux

Apostle Holydays occur on the 5th day of the season.

Season Holydays occur on the 50th day of the deason.

St. Tib's Day occurs once every 4 years (1+4=5) and is inserted between
the 59th and 60th days of the Season of Chaos. 

The era of the Discordian Calendar is called Year Of Lady Discord
(YOLD.) Its' epoch (Confusion 1 of year 0) is equivalent to January 1,
-1167 B.C.

X Day is when the Church of the SubGenius believes the alien X-ists will
destroy the world.  The revised date is equivalent to Confusion 40, 9827
YOLD.

=cut

my %seasons = (
    'Chaos' => {
        abbrev          => 'Chs',
        offset          => 0,
        apostle_holyday => 'Mungday',
        season_holyday  => 'Chaoflux',
    },
    'Discord' => {
        abbrev          => 'Dsc',
        offset          => 73,
        apostle_holyday => 'Mojoday',
        season_holyday  => 'Discoflux',
    },
    'Confusion' => {
        abbrev          => 'Cfn',
        offset          => 146,
        apostle_holyday => 'Syaday',
        season_holyday  => 'Confuflux',
    },
    'Bureaucracy' => {
        abbrev          => 'Bcy',
        offset          => 219,
        apostle_holyday => 'Zaraday',
        season_holyday  => 'Bureflux',
    },
    'The Aftermath' => {
        abbrev          => 'Afm',
        offset          => 292,
        apostle_holyday => 'Maladay',
        season_holyday  => 'Afflux',
    },
);

my $tibsday = qr/s(?:ain)?t[.]?\s*tib'?s?\s*(?:day)?/imsx;

=head3 Days Of The Week

	1. Sweetmorn 
	2. Boomtime 
	3. Pungenday 
	4. Prickle-Prickle 
	5. Setting Orange 

The days of the week are named from the five Basic Elements: sweet,
boom, pungent, prickle and orange.

=cut

my @days = (
    { name => 'Sweetmorn',       abbrev => 'SM', },
    { name => 'Boomtime',        abbrev => 'BT', },
    { name => 'Pungenday',       abbrev => 'PD', },
    { name => 'Prickle-Prickle', abbrev => 'PP', },
    { name => 'Setting Orange',  abbrev => 'SO', },
);

my @excl = (
    'Hail Eris!',
    'All Hail Discordia!',
    'Kallisti!',
    'Fnord.',
    'Or not.',
    'Wibble.',
    'Pzat!',
    q{P'tang!},
    'Frink!',
    'Slack!',
    'Praise "Bob"!',
    'Or kill me.',
    'Grudnuk demand sustenance!',
    'Keep the Lasagna flying!',
    'Umlaut Zebra über alles!',
    'You are what you see.',
    'Or is it?',
    'This statement is false.',
    'Hail Eris, Hack Perl!',
);

=head1 METHODS

=head2 new

Constructs a new I<DateTime::Calendar::Discordian> object.  This class
method requires the parameters I<day>, I<season>, and I<year>.  If
I<day> is given as "St. Tib's Day" (or reasonable facsimile thereof,)
then I<season> is omitted. This function will C<die> if invalid
parameters are given.  For example:

my $dtcd = DateTime::Calendar::Discordian->new(
  day => 8, season => 'Discord', year => 3137, );

The I<second>, I<nanosecond>, and I<locale> parameters are also accepted for
compatability with L<DateTime|DateTime> but nothing is done with them.

=cut

sub new {
    my ( $class, @arguments ) = @_;

    my %args = validate(
        @arguments,
        {
            day => {
                callbacks => {
                    q{between 1 and 73 or St. Tib's Day} => sub {
                        my ( $day, $opts ) = @_;
                        if ( $day =~ $tibsday ) {
                            if ( !defined $opts->{season} ) {
                                return 1;
                            }
                        }
                        elsif ( $day > 0 && $day < 74 ) {
                            return 1;
                        }
                        return;
                    },
                },
            },
            season => {
                default   => undef,
                callbacks => {
                    'valid season name' => sub {
                        my ( $season, $opts ) = @_;
                        if ( defined $season ) {
                            return scalar grep { /((?-x)$season)/imsx }
                              keys %seasons;
                        }
                        return 1;
                    },
                },
            },
            year       => { type    => SCALAR, },
            second     => { default => 0, },
            nanosecond => { default => 0, },
            locale     => {
                type     => SCALAR | OBJECT | UNDEF,
                optional => 1,
            },

        }
    );

    if ( defined $args{season} ) {
        $args{season} = join q{ }, map { ucfirst lc $_ } split q{ },
          $args{season};
    }
    else {
        if ( $args{day} !~ $tibsday ) {
            confess 'missing season';
        }
    }
    if ( $args{day} =~ $tibsday ) {
        $args{day} = q{St. Tib's Day};
    }
    croak q{Not a leap year}
      if $args{day} eq q{St. Tib's Day}
          && !_is_leap_year( $args{year} - 1166 );
    my $self = bless \%args, $class;
    $self->{epoch} = -426_237;
    $self->{fnord} = 5;
    if ( defined $self->{locale} ) {
        if ( !ref $self->{locale} ) {
            $self->{locale} = DateTime::Locale->load( $args{locale} );
        }
    }
    $self->{rd} = $self->_discordian2rd;

    return bless $self, $class;
}

=head2 clone

Returns a copy of the object.

=cut

sub clone {
    my ($object) = @_;
    return bless { %{$object} }, ref $object;
}

=head2 day

Returns the day of the season as a number between 1 and 73 or the string
"St. Tib's Day".

=cut

sub day {
    my ($self) = @_;

    return $self->{day};
}

=head2 day_abbr

Returns the name of the day of the week in abbreviated form or false if
it is "St. Tib's Day".

=cut

sub day_abbr {
    my ($self) = @_;

    if ( $self->{day} eq q{St. Tib's Day} ) {
        return;
    }

    my $day_of_year = $seasons{ $self->{season} }->{offset} + $self->{day};
    return $days[ ( $day_of_year - 1 ) % 5 ]->{abbrev};
}

=head2 day_name

Returns the full name of the day of the week or "St. Tib's Day" if it is
that day.

=cut

sub day_name {
    my ($self) = @_;

    return $self->{day} if ( $self->{day} eq q{St. Tib's Day} );

    my $day_of_year = $seasons{ $self->{season} }->{offset} + $self->{day};
    return $days[ ( $day_of_year - 1 ) % 5 ]->{name};
}

=head2 days_till_x

Returns the number of days until X Day.

=cut

sub days_till_x {
    my ($self) = @_;
    return 3_163_186 - $self->{rd};
}

=head2 from_object

Builds a I<DateTime::Calendar::Discordian> object from another
I<DateTime> object.  This function takes an I<object> parameter and
optionally I<locale>. For example:

my $dtcd = DateTime::Calendar::Discordian->from_object(
  object => DateTime->new(day => 22, month => 3, year => 1971,));

=cut

sub from_object {
    my ( $class, @arguments ) = @_;
    my %args = validate(
        @arguments,
        {
            object => {
                type => OBJECT,
                can  => 'utc_rd_values',
            },
            locale => {
                type    => SCALAR | OBJECT | UNDEF,
                default => undef,
            },
        },
    );

    if ( $args{object}->can('set_time_zone') ) {
        $args{object} = $args{object}->clone->set_time_zone('floating');
    }
    my ( $rd_days, $rd_secs, $rd_nanosecs ) = $args{object}->utc_rd_values;

    my ( $day, $season, $year ) = $class->_rd2discordian($rd_days);

    my $newobj = $class->new(
        day        => $day,
        season     => $season,
        year       => $year,
        second     => $rd_secs,
        nanosecond => $rd_nanosecs,
        locale     => $args{locale},
    );

    return $newobj;
}

=head2 holyday

If the current day is a holy day, returns the name of that day otherwise
returns an empty string.

=cut 

sub holyday {
    my ($self) = @_;

    return $seasons{ $self->{season} }->{apostle_holyday}
      if ( $self->{day} == 5 );
    return $seasons{ $self->{season} }->{season_holyday}
      if ( $self->{day} == 50 );
    return q{};
}

=head2 season_abbr

Returns the abbreviated name of the current season.

=cut

sub season_abbr {
    my ($self) = @_;

    return $seasons{ $self->{season} }->{abbrev};
}

=head2 season_name

Returns the full name of the current season.

=cut

sub season_name {
    my ($self) = @_;

    return $self->{season};
}

=head2 strftime

This function takes one or more parameters consisting of strings
containing special specifiers.  For each such string it will return a
string formatted according to the specifiers, er, specified.  See the
L<strftime Specifiers|/"strftime Specifiers"> section for a list of the
available format specifiers.  They have been chosen to be compatible
with the L<ddate(1)|ddate/1> program not necessarily the L<strftime(3)|strftime/3> C
function.  If you give a format specifier that doesn't exist, then it is
simply treated as text.

=head3 strftime Specifiers

The following specifiers are allowed in the format string given to the
B<strftime> method:

=over 4

=item * %a

Abbreviated name of the day of the week (i.e., SM.)  Internally uses the
I<day_abbr> function.

=item * %A

Full name of the day of the week (i.e., Sweetmorn.)  Internally uses the
I<day_name> function.

=item * %b

Abbreviated name of the season (i.e., Chs.)  Internally uses the
I<season_abbr> function.

=item * %B

Full name of the season (i.e., Chaos.)  Internally uses the
I<season_name> function.

=item * %d

Ordinal number of day in season (i.e., 23.)  Internally uses the I<day>
function.

=item * %e

Cardinal number of day in season (i.e., 23rd.)

=item * %H

Name of current Holyday, if any.  Internally uses the I<holyday>
function.

=item * %n

A newline character.

=item * %N

Magic code to prevent rest of format from being printed unless today is
a Holyday.

=item * %t

A tab character.

=item * %X

Number of days remaining until X-Day.  Internally uses the
I<days_till_x> function.

=item * %Y

Number of Year Of Lady Discord (YOLD.)  Internally uses the I<year>
function.

=item * %{

=item * %}

Used to enclose the part of the string which is to be replaced with the
words "St. Tib's Day" if the current day is St. Tib's Day.

=item * %%

A literal `%' character.

=item * %.

Try it and see.

=back

=cut

my %formats = (
    'a'  => sub { $_[0]->day_abbr },
    'A'  => sub { $_[0]->day_name },
    'b'  => sub { $_[0]->season_abbr },
    'B'  => sub { $_[0]->season_name },
    'd'  => sub { $_[0]->day },
    'e'  => sub { _cardinal( $_[0]->{day} ) },
    'H'  => sub { $_[0]->holyday },
    'n'  => sub { "\n" },
    't'  => sub { "\t" },
    'X'  => sub { $_[0]->days_till_x },
    'Y'  => sub { $_[0]->year },
    q{%} => sub { q{%} },
    q{.} => sub { $_[0]->_randexcl },
);

sub strftime {
    my ( $self, @r ) = @_;

    foreach (@r) {
        ( $self->{day} eq q{St. Tib's Day}
              || ( $self->{day} != 5 && $self->{day} != 50 ) )
          ? s/%N.+$//msx
          : s/%N//gmsx;
        ( $self->{day} eq q{St. Tib's Day} )
          ? s/%[{].+?%[}]/%d/gmsx
          : s/%[{}]//gmsx;

        s/%([%*[:alpha:]])/ $formats{$1} ? $formats{$1}->($self) : $1 /egmsx;
        if ( !wantarray ) {
            return $_;
        }
    }
    return @r;
}

=head2 utc_rd_values

Returns a three-element array containing the current UTC RD days,
seconds, and nanoseconds.  See L<DateTime|DateTime> for more details.

=cut

sub utc_rd_values {
    my ($self) = @_;

    return ( $self->{rd}, $self->{rd_secs}, $self->{rd_nanosecs} );
}

=head2 year

Returns the current year according to the YOLD (Year Of Lady Discord)
era.

=cut

sub year {
    my ($self) = @_;

    return $self->{year};
}

sub _cardinal {
    my ($day) = @_;

    my $cardinal = $day;
    return $cardinal . 'st' if ( $day % 10 == 1 && $day != 11 );
    return $cardinal . 'nd' if ( $day % 10 == 2 && $day != 12 );
    return $cardinal . 'rd' if ( $day % 10 == 3 && $day != 13 );
    return $cardinal . 'th';
}

#
# calculate RD (Rata Dia) date
#
sub _discordian2rd {
    my ($self) = @_;

    # Convert Discordian year to Gregorian - 1
    my $yr = $self->{year} - 1167;

    # Start with the epoch + number of elapsed days in intervening years.
    # Add number of intervening leap days.
    my $rd = 0    #
      + 365 * ($yr)    #
      + _floor( $yr / 4 )    #
      - _floor( $yr / 100 ) + _floor( $yr / 400 );

    # add number of days elapsed this year.
    my $day_of_year =
      $self->{day} eq q{St. Tib's Day}
      ? 60
      : $seasons{ $self->{season} }->{offset} + $self->{day};
    $rd += $day_of_year;

    # add 1 if this is a leap year and it is past St. Tibs' Day.
    $rd += $day_of_year <= 60 ? 0 : _is_leap_year( $yr + 1 ) ? 1 : 0;

    return $rd;
}

sub _floor {
    my ($x) = @_;
    my $ix = int $x;
    return ( $ix <= $x ) ? $ix : $ix - 1;
}

sub _is_leap_year {
    my ($yr) = @_;
    my $c = ($yr) % 400;

    return ( $yr % 4 == 0 ) && $c != 100 && $c != 200 && $c != 300;
}

sub _randexcl {
    my ($self) = @_;

    return $excl[ int rand $#excl ];
}

sub _rd2discordian {
    my ( $self, $rd ) = @_;

    my $n400 = _floor( $rd / 146_097 );
    my $d1   = $rd % 146_097;
    my $n100 = _floor( $d1 / 36_524 );
    my $d2   = $d1 % 36_524;
    my $n4   = _floor( $d2 / 1461 );
    my $d3   = $d2 % 1461;
    my $n1   = _floor( $d3 / 365 );
    my $d4   = $d3 % 365;

    # $d4 == 0 is the last day of the year so has to be special cased.
    my $year =
      ( 400 * $n400 ) +
      ( 100 * $n100 ) +
      ( 4 * $n4 ) +
      $n1 + 1166 +
      ( ( $d4 == 0 ) ? 0 : 1 );

    my ( $season, $day );
    if ( $d4 == 60 && _is_leap_year( $year - 1166 ) ) {
        $season = undef;
        $day    = q{St. Tib's Day};
    }
    else {
        my @seas =
          ( 'Chaos', 'Discord', 'Confusion', 'Bureaucracy', 'The Aftermath', );
        $season = ( $d4 == 0 ) ? $seas[4] : $seas[ _floor( $d4 / 73 ) ];

        $day = ( $d4 == 0 ) ? 73 : $d4 - $seasons{$season}->{offset};

        if ( $d4 > 60 && _is_leap_year( $year - 1166 ) ) {
            $day--;
        }

        if ( $day < 1 ) {
            $day += 73;
        }
    }

    return ( $day, $season, $year );
}

1;
__END__

=head1 SUPPORT

After installing, you can find documentation for this module with the perldoc
command.

    perldoc DateTime::Calendar::Discordian

Support for this module is provided via the datetime@perl.org email list. See
L<lists.perl.org|http://lists.perl.org/> for more details.

Please submit bugs to the L<CPAN RT system|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=datetime-Calendar-Discordian>
or via email at bug-datetime-calendar-discordian@rt.cpan.org.

You can also look for information at:

=over 4

=item * L<Search CPAN.|http://search.cpan.org/dist/DateTime-Calendar-Discordian>

=item * L<AnnoCPAN, annotated CPAN documentation.|http://annocpan.org/dist/DateTime-Calendar-Discordian>

=item * L<CPAN Ratings.|http://cpanratings.perl.org/d/DateTime-Calendar-Discordian>

=back

=head1 AUTHOR

Jaldhar H. Vyas, E<lt>jaldhar@braincells.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Consolidated Braincells Inc.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

The full text of the license can be found in the LICENSE file included
with this distribution.

=head1 SEE ALSO

=over 4

=item * L<The DateTime project web site.|http://datetime.perl.org/>

=item * L<The Principia Discordia.|http://www.ology.org/principia/>

=item * L<The Church of the SubGenius.|http://www.subgenius.com/>

=back

=cut
