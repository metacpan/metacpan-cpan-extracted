package Date::Extract::DE;

use Moose;

use version; our $VERSION = qv('0.0.6');

use Date::Range;
use Date::Simple ( 'date', 'today' );
use DateTime;
use DateTime::Incomplete;
use Regexp::Assemble;

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
        'Jaenner'   => 1,
        'Januar'    => 1,
        'Feber'     => 2,
        'Februar'   => 2,
        'März'     => 3,
        'Maerz'     => 3,
        'April'     => 4,
        'Mai'       => 5,
        'Juni'      => 6,
        'Juno'      => 6,
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

class_has '_days',
    is      => 'ro',
    isa     => 'HashRef[Int]',
    traits  => [qw/Hash/],
    handles => { all_days => 'keys', day_nr => 'get' },
    default => sub {

    my %days = (
        'ers'    => 1,
        'zwei'   => 2,
        'drit'   => 3,
        'vier'   => 4,
        'fünf'  => 5,
        'fuenf'  => 5,
        'sechs'  => 6,
        'sieb'   => 7,
        'sieben' => 7,
        'ach'    => 8,
        'neun'   => 9,
        'zehn'   => 10,
        'elf'    => 11,
        'zwölf' => 12,
        'zwoelf' => 12,
    );
    my %prefixes_10 = (
        'drei'  => 3,
        'vier'  => 4,
        'fünf' => 5,
        'fuenf' => 5,
        'sech'  => 6,
        'sieb'  => 7,
        'acht'  => 8,
        'neun'  => 9
    );
    my %prefixes_20 = (
        'ein'    => 1,
        'zwei'   => 2,
        'drei'   => 3,
        'vier'   => 4,
        'fünf'  => 5,
        'fuenf'  => 5,
        'sechs'  => 6,
        'sieben' => 7,
        'acht'   => 8,
        'neun'   => 9
    );

    for my $p ( keys %prefixes_10 ) {
        $days{ $p . 'zehn' } = $prefixes_10{$p} + 10;
    }
    $days{zwanzigs} = 20;
    for my $p ( keys %prefixes_20 ) {
        $days{ $p . 'undzwanzigs' } = $prefixes_20{$p} + 20;
    }

    $days{'dreißigs'}       = $days{dreissigs}       = 30;
    $days{'einunddreißigs'} = $days{einunddreissigs} = 31;

    my %result;

    for my $d ( keys %days ) {
        $result{ $d . 'te' }      = $result{ $d . 'ten' } =
            $result{ $d . 'ter' } = $days{$d};
    }
    return \%result;

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
    return int $month;
}

sub _translate_day {
    my ( $self, $day ) = @_;
    $day =~ s/\W//g;
    return $self->day_nr( lc $day ) if $self->day_nr( lc $day );
    return int $day;
}

sub _translate_year {
    my ( $self, $year ) = @_;
    $year =~ s/\W//g;
    $year = int $year;
    if ( $year < 30 ) {
        $year += 2000;
    }
    elsif ( $year < 100 ) {
        $year += 1900;
    }
    return $year;
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
            push @dates,
                map { { date => $_, context => $date->{date} } }
                $range->dates;
        }
        elsif ( $date->{conjugator} eq 'enum' ) {
            push @dates,
                {
                date => Date::Simple::ymd(
                    $date->{year1}, $date->{month1}, $date->{day1}
                ),
                context => $date->{date}
                },
                {
                date => Date::Simple::ymd(
                    $date->{year2}, $date->{month2}, $date->{day2}
                ),
                context => $date->{date}
                };
        }
        if ( ( $date->{conjugator} ne 'range' ) && ( $date->{days0} ) ) {
            for my $d ( reverse split /[^\d]+/, $date->{days0} ) {
                unshift @dates,
                    {
                    date => Date::Simple::ymd(
                        $date->{year2}, $date->{month2},
                        $self->_translate_day($d)
                    ),
                    context => $date->{date}
                    };
            }
        }
    }
    else {
        if ( !$date->{year1} ) {

            # guesswork
            my $dti = DateTime::Incomplete->new(
                month => $date->{month1},
                day   => $date->{day1}
            );
            push @dates,
                {
                date    => $self->_guess_full_date($dti),
                context => $date->{date}
                };
        }
        else {
            push @dates,
                {
                date => Date::Simple::ymd(
                    $date->{year1}, $date->{month1}, $date->{day1}
                ),
                context => $date->{date}
                };
        }
    }
    return @dates;
}

sub extract_with_context {
    my ( $self, $text ) = @_;
    my @found_dates;

    my @enum  = ( '\+',  ',', 'oder', 'o\.' );
    my @and   = ( 'und', 'u\.' );
    my @range = ( '-',   'bis(?:\s*zum)?', );
    my @months    = $self->all_months;
    my @days      = $self->all_days;
    my $monthlist = Regexp::Assemble->new();
    $monthlist->add(@months);
    $monthlist->add('(?:(?:0?[1-9])|(?:1[0-2]))\.');
    my $month_regex = qr/$monthlist/i;

    my $daylist = Regexp::Assemble->new();
    $daylist->add(@days);

    # once turned into a regex it no longer honors the i switch set on a
    # containing regex.
    my $between_regex = qr/[Zz]wischen/;
    my $day_regex =
        qr/(?:$daylist)|(?:(?:(?:0?[1-9])|(?:[1-2][0-9])|(?:3[0-1]))\.)/i;
    my $year_regex       = qr/(?:\d\d?|\')?\d{2}/;
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
            (?<day1>$day_regex)\s*
            (?<month1>$month_regex)\s*
            (?<year1>$year_regex)?\s*
        $conjugator_regex\s*
            (?<day2>$day_regex)\s*
            (?<month2>$month_regex)\s*
            (?<year2>$year_regex)?\s*
    |
        (?<between>$between_regex)?\s*
        (?<days0>($day_regex(?:\s*\,\s*))*)
        (?<day1>$day_regex)\s*
        (?:
            $conjugator_regex\s*
            (?<day2>$day_regex)\s*
        )?
        (?<month1>$month_regex)\s*
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
            $date->{day1} = $self->_translate_day( $date->{day1} )
                if $date->{day1};
            $date->{day2} = $self->_translate_day( $date->{day2} )
                if $date->{day2};
            $date->{month1} = $self->_translate_month( $date->{month1} )
                if $date->{month1};
            $date->{month2} = $self->_translate_month( $date->{month2} )
                if $date->{month2};
            $date->{year1} = $self->_translate_year( $date->{year1} )
                if $date->{year1};
            $date->{year2} = $self->_translate_year( $date->{year2} )
                if $date->{year2};
            push @found_dates, $date;
            1;
        } or do {
            warn "$text\n\n$@" if $@;
        };

    }

    my @adjusted_dates;
    foreach (@found_dates) {
        $_->{date} =~ s/(?:^\s+)|(?:\s+$)//g;
        push @adjusted_dates, $self->_process_date($_);
    }
    return \@adjusted_dates;
}

sub extract {
    my ( $self, $text ) = @_;

    my $extract_info = $self->extract_with_context($text);
    return [ map { $_->{date} } grep { $_->{date} } @$extract_info ];
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Date::Extract::DE -  Extract dates from german text

=head1 VERSION

0.0.6

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
    my $infos = $parser->extract_with_context($text);
    printf("%s => %s\n", $_->{context}, $_->{date}) foreach @$infos;

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

Tries to extract dates from the text and returns an arrayref of L<Date::Simple>
instances

=item extract_with_context($text)

Tries to extract dates from the text and returns an arrayref of HashRef
instances. Each HashRef contains a key 'date' which maps to a L<Date::Simple>
instance, and a key 'context' mapping to the date string found in the original
text

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
