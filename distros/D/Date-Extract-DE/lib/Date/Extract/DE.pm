package Date::Extract::DE;

use Moose;

use version; our $VERSION = qv('0.0.3');

use Date::Range;
use Date::Simple ( 'date', 'today' );
use DateTime;
use DateTime::Incomplete;

use MooseX::ClassAttribute;

use utf8;

use namespace::autoclean;

has 'reference_date',
    is      => 'ro',
    isa     => 'Date::Simple',
    default => sub { today() };
has 'lookback_days',
    is  => 'ro',
    isa => 'Int';

has '_reference_dt',
    is      => 'ro',
    isa     => 'DateTime',
    lazy    => 1,
    builder => '_build__reference_dt';

class_has '_months',
    is      => 'ro',
    isa     => 'HashRef[Int]',
    traits  => [qw/Hash/],
    handles => { all_months => 'keys', month_nr => 'get' },
    default => sub {
    my %months = (
        'Jänner'   => 1,
        'Jannuar'   => 1,
        'Feber'     => 2,
        'Februar'   => 2,
        'März'     => 3,
        'April'     => 4,
        'Mai'       => 5,
        'Juni'      => 6,
        'Juli'      => 7,
        'August'    => 8,
        'September' => 9,
        'Oktober'   => 10,
        'November'  => 11,
        'Dezember'  => 12,
    );

    for my $m ( keys %months ) {
        $months{ substr( $m, 0, 3 ) } = $months{$m};
    }
    return \%months;
    };

sub _build__reference_dt {
    my ($self) = @_;

    return DateTime->new(
        year       => $self->reference_date->year,
        month      => $self->reference_date->month,
        day        => $self->reference_date->day,
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
        time_zone  => 'Europe/Vienna',
    );
}

sub _translate_month {
    my ( $self, $month ) = @_;
    $month =~ s/\W//g;
    $month = ucfirst( lc $month );    # TODO: explore casefold here
    return $self->month_nr($month) if $self->month_nr($month);
    $month = int $month;
    return $month if $month && $month >= 1 && $month <= 12;
    return;
}

sub _guess_full_date {
    my ( $self, $dt ) = @_;

    my $cand = $dt->closest( $self->_reference_dt );
    my $result = Date::Simple::ymd( $cand->year, $cand->month, $cand->day );
    if (   ( defined $self->lookback_days )
        && ( $result < $self->reference_date )
        && ( ( $self->reference_date - $result ) > $self->lookback_days ) ) {
        $cand = $dt->next( $self->_reference_dt );
        $result = Date::Simple::ymd( $cand->year, $cand->month, $cand->day );
    }
    return $result;
}

sub _process_date {
    my ( $self, $date ) = @_;
    my @dates;

    if ( exists $date->{conjugator} ) {
        $date->{month2} = $date->{month1} unless $date->{month2};
        if ( !$date->{year1} && !$date->{year2} ) {
            my $dti1 = DateTime::Incomplete->new(
                month => $date->{month1},
                day   => $date->{day1},
            );
            $date->{year1} = $self->_guess_full_date($dti1)->year();
            $dti1->set( year => $date->{year1} );
            my $dti2 = DateTime::Incomplete->new(
                year  => $date->{year1},
                month => $date->{month2},
                day   => $date->{day2},
            );
            if ( 1 == DateTime->compare_ignore_floating( $dti1, $dti2 ) ) {
                $date->{year2} = 1 + $date->{year1};
            }
            else {
                $date->{year2} = $date->{year1};
            }
        }
        elsif ( $date->{year1} && !$date->{year2} ) {
            my $dti1 = DateTime::Incomplete->new(
                year  => $date->{year1},
                month => $date->{month1},
                day   => $date->{day1},
            );
            my $dti2 = DateTime::Incomplete->new(
                year  => $date->{year1},
                month => $date->{month2},
                day   => $date->{day2},
            );
            if ( 1 == DateTime->compare_ignore_floating( $dti1, $dti2 ) ) {
                $date->{year2} = 1 + $date->{year1};
            }
            else {
                $date->{year2} = $date->{year1};
            }
        }
        elsif ( !$date->{year1} && $date->{year2} ) {
            my $dti1 = DateTime::Incomplete->new(
                year  => $date->{year2},
                month => $date->{month1},
                day   => $date->{day1},
            );
            my $dti2 = DateTime::Incomplete->new(
                year  => $date->{year2},
                month => $date->{month2},
                day   => $date->{day2},
            );
            if ( 1 == DateTime->compare_ignore_floating( $dti1, $dti2 ) ) {
                $date->{year1} = $date->{year2} - 1;
            }
            else {
                $date->{year1} = $date->{year2};
            }
        }
        else {
        }
        if ( $date->{conjugator} eq 'range' ) {
            my $range = Date::Range->new(
                Date::Simple::ymd(
                    $date->{year1}, $date->{month1}, $date->{day1}
                ),
                Date::Simple::ymd(
                    $date->{year2}, $date->{month2}, $date->{day2}
                )
            );
            push @dates, $range->dates();
        }
        elsif ( $date->{conjugator} eq 'enum' ) {
            push @dates,
                Date::Simple::ymd(
                $date->{year1}, $date->{month1}, $date->{day1}
                ),
                Date::Simple::ymd( $date->{year2}, $date->{month2},
                $date->{day2} );
        }
    }
    else {
        if ( !$date->{year1} ) {

            # guesswork
            my $dti = DateTime::Incomplete->new(
                month => $date->{month1},
                day   => $date->{day1}
            );
            push @dates, $self->_guess_full_date($dti);
        }
        else {
            push @dates,
                Date::Simple::ymd( $date->{year1}, $date->{month1},
                $date->{day1} );
        }
    }
    return @dates;
}

sub extract {
    my ( $self, $text ) = @_;
    my @found_dates;

    my @enum  = ( '\+',  ',', 'oder', 'o\.' );
    my @and   = ( 'und', 'u\.' );
    my @range = ( '-',   'bis(?:\s*zum)?', );
    my @months    = $self->all_months;
    my $monthlist = join '|',
        (
        map  {"$_\\b"}
        sort { length($b) <=> length($a) } @months
        ),
        '[1-9]\d?\.';
    my $month_regex = qr/$monthlist/i;

    # once turned into a regex it no longer honors the i switch set on a
    # containing regex.
    my $between_regex    = qr/[Zz]wischen/;
    my $day_regex        = qr'[1-9]\d?\.';
    my $year_regex       = qr'\d{4}';
    my $conjugator_enum  = join '|', @enum;
    my $conjugator_and   = join '|', @and;
    my $conjugator_range = join '|', @range;
    my $conjugator_regex = qr/(?:
                (?<enum>$conjugator_enum)
            |
                (?<and>$conjugator_and)
            |
                (?<range>$conjugator_range)
            )/ix;

    my $date_regex = qr/\b(?:
            (?<between>$between_regex)?\s*
            0?(?<day1>$day_regex)\s*
            0?(?<month1>$month_regex)\s*
            (?<year1>$year_regex)?\s*
        $conjugator_regex\s*
            0?(?<day2>$day_regex)\s*
            0?(?<month2>$month_regex)\s*
            (?<year2>$year_regex)?\s*
    |
        (?<between>$between_regex)?\s*
        0?(?<day1>$day_regex)\s*
        (?:
            $conjugator_regex\s*
            0?(?<day2>$day_regex)\s*
        )?
        0?(?<month1>$month_regex)\s*
        (?<year1>$year_regex)?
    )/x;

    while ( $text =~ m/(?<date>$date_regex)/g ) {
        my $date = {%+};
        eval {
            for my $c (qw(enum range and)) {
                if ( exists $date->{$c} ) {
                    if ( $c eq 'and' ) {
                        if ( exists $date->{between} ) {
                            $date->{conjugator} = 'range';
                        }
                        else {
                            $date->{conjugator} = 'enum';
                        }
                    }
                    else {
                        $date->{conjugator} = $c;
                    }
                }
            }
            $date->{day1} = int $date->{day1} if $date->{day1};
            $date->{day2} = int $date->{day2} if $date->{day2};
            $date->{month1} = $self->_translate_month( $date->{month1} )
                if $date->{month1};
            $date->{month2} = $self->_translate_month( $date->{month2} )
                if $date->{month2};
            push @found_dates, $date;
            1;
        } or do {
            warn "$text\n\n$@" if $@;
        };

    }
    my @adjusted_dates;
    foreach (@found_dates) {
        push @adjusted_dates, $self->_process_date($_);
    }
    return \@adjusted_dates;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Date::Extract::DE -  Extract dates from german text

=head1 VERSION

0.0.3

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=end readme

=for test_synopsis
    my $reference_date;
    my $lookback_days;
    my $text;

=head1 SYNOPSIS

    use Date::Extract::DE;
    my $parser = Date::Extract::DE->new( reference_date => $reference_date );
    my $dates = $parser->extract($text);

=head1 DESCRIPTION

This is a module to extract dates from german text (similar to L<Date::Extract>).

=head1 METHODS

=over 4

=item new(reference_date => $reference_date, lookback_days => $lookback_days)

Creates a new instance. Optionally, you can specify a reference Date::Simple
which is used to determine the year when a date is given incompletely in the
text (default is today). You can also specify a maximum numer of days to look
back when an incomplete date is guessed (otherwise the closest date is used)

=item extract($text)

Tries to extract dates from the text and returns an arrayref of L<Date::Simple> instances

=back

=head1 AUTHORS

=over 4

=item Andreas Mager  C<< <quattro at cpan org> >>

=item Christian Eder  C<< <christian.eder@apa.at> >>

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2020, APA-IT. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this module.  If not, see L<http://www.gnu.org/licenses/>.
