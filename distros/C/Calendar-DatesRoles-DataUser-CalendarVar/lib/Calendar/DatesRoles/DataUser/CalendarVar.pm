package Calendar::DatesRoles::DataUser::CalendarVar;

our $DATE = '2019-07-08'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;
use Role::Tiny::With;
no strict 'refs'; # Role::Tiny imports strict for us

with 'Calendar::DatesRoles::PublicInterface::Basic';
requires 'prepare_data';

sub _calc_min_max_year {
    my $mod = shift;

    return if defined ${"$mod\::_CD_DATAUSER_CALENDARVAR_CACHE_MIN_YEAR"};
    $mod->prepare_data;

    my $cal = ${"$mod\::CALENDAR"};
    my ($min, $max);
    my ($min_anniv, $max_anniv);
    for my $e (@{ $cal->{entries} }) {
        my $year;
        if ($e->{date} =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})(?:T|\z)/) {
            $e->{year}  //= $1;
            $e->{month} //= $2 + 0;
            $e->{day}   //= $3 + 0;
            # XXX hour, minute, second?
            if ($e->{tags} && (grep {$_ eq 'anniversary'} @{$e->{tags}})) {
                $min_anniv = $e->{year} if !defined($min_anniv) || $min_anniv > $e->{year};
                $max_anniv = 9999 if !defined($max_anniv) || $max_anniv < 9999;
            } else {
                $min = $e->{year} if !defined($min) || $min > $e->{year};
                $max = $e->{year} if !defined($max) || $max < $e->{year};
            }
        } elsif ($e->{date} =~ /\A(?:--)([0-9]{2})-([0-9]{2})\z/) {
            # anniversary without starting year
            $min_anniv = 1582 if !defined($min_anniv) || $min_anniv > 1582; # start of gregorian calendar :-)
            $max_anniv = 9999 if !defined($max_anniv) || $max_anniv < 9999;
            $e->{month} //= $1 + 0;
            $e->{day}   //= $2 + 0;
        } elsif ($e->{date} =~ m!\AR/([0-9]{4})-([0-9]{2})-([0-9]{2})/P1Y\z!) {
            # anniversary with starting year
            $min_anniv = $1   if !defined($min_anniv) || $min_anniv > $1;
            $max_anniv = 9999 if !defined($max_anniv) || $max_anniv < 9999;
            $e->{month} //= $2 + 0;
            $e->{day}   //= $3 + 0;
        } else {
            die "BUG: $mod has an entry that doesn't have valid date: ".
                ($e->{date} // 'undef');
        }
    }

    #use DD; dd {min=>$min, max=>$max, min_anniv=>$min_anniv, max_anniv=>$max_anniv};

    $min //= $min_anniv;
    $max //= $max_anniv;

    ${"$mod\::_CD_DATAUSER_CALENDARVAR_CACHE_MIN_YEAR"} = $min;
    ${"$mod\::_CD_DATAUSER_CALENDARVAR_CACHE_MAX_YEAR"} = $max;
}

sub get_min_year {
    my $mod = shift;

    $mod->_calc_min_max_year();
    return ${"$mod\::_CD_DATAUSER_CALENDARVAR_CACHE_MIN_YEAR"};
}

sub get_max_year {
    my $mod = shift;

    $mod->_calc_min_max_year();
    return ${"$mod\::_CD_DATAUSER_CALENDARVAR_CACHE_MAX_YEAR"};
}

sub get_entries {
    my $mod = shift;
    my $params = ref $_[0] eq 'HASH' ? shift : {};
    my ($year, $month, $day) = @_;

    die "Please specify year" unless defined $year;
    my $min = $mod->get_min_year;
    die "Year is less than earliest supported year $min" if $year < $min;
    my $max = $mod->get_max_year;
    die "Year is greater than latest supported year $max" if $year > $max;

    my $cal = ${"$mod\::CALENDAR"};
    my @res;

  ENTRY:
    for my $e0 (@{ $cal->{entries} }) {
        my $e = {%$e0}; # shallow copy

        # filter by year
        if ($e->{date} =~ /\A(?:--)([0-9]{2})-([0-9]{2})/a) {
            # anniversary without starting year
            $e->{date} = sprintf "%04d-%02d-%02d", $year, $1, $2;
            $e->{year} = $year;
        } elsif ($e->{date} =~ m!\AR/([0-9]{4})-([0-9]{2})-([0-9]{2})/P1Y\z!a) {
            # anniversary with starting year
            next unless $year >= $1;
            $e->{date} = sprintf "%04d-%02d-%02d", $year, $2, $3;
            # XXX don't do this if language is not english
            $e->{summary} .= sprintf(
                " (%s anniversary)",
                Lingua::EN::Numbers::Ordinate::ordinate($year - $e->{year}))
                if defined $e->{summary};
            $e->{orig_year} = $e->{year};
            $e->{year} = $year;
        } elsif ($e->{tags} && (grep {$_ eq 'anniversary'} @{$e->{tags}})) {
            # anniversary with starting year
            next unless $year >= $e->{year};
            $e->{date} = sprintf "%04d-%02d-%02d",
                $year, $e->{month}, $e->{day};
            # XXX don't do this if language is not english
            require Lingua::EN::Numbers::Ordinate;
            $e->{summary} .= sprintf(
                " (%s anniversary)",
                Lingua::EN::Numbers::Ordinate::ordinate($year - $e->{year}))
                if defined $e->{summary};
            $e->{orig_year} = $e->{year};
            $e->{year} = $year;
        } else {
            # regular date
            next unless $e->{year} == $year;
        }

        # filter by month & day
        next if defined $month && $e->{month} != $month;
        next if defined $day   && $e->{day}   != $day;

        # filter by tags
        if ($params->{include_tags}) {
            my $included;
            for my $tag (@{ $params->{include_tags} }) {
                if ($e->{tags} && (grep {$_ eq $tag} @{$e->{tags}})) {
                    $included++; last;
                }
            }
            next unless $included;
        }
        if ($params->{exclude_tags}) {
            for my $tag (@{ $params->{exclude_tags} }) {
                if ($e->{tags} && (grep {$_ eq $tag} @{$e->{tags}})) {
                    next ENTRY;
                }
            }
        }

        # filter low-priority items by default
        next if !$params->{all} && $e->{tags} &&
            (grep {$_ eq 'low-priority'} @{$e->{tags}});

        # filter by consumer's filter_entry()
        next if $mod->can("filter_entry") && !$mod->filter_entry($e, $params);

        push @res, $e;
    }

    \@res;
}

1;
# ABSTRACT: Provide Calendar::Dates interface from consumer's $CALENDAR

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::DatesRoles::DataUser::CalendarVar - Provide Calendar::Dates interface from consumer's $CALENDAR

=head1 VERSION

This document describes version 0.005 of Calendar::DatesRoles::DataUser::CalendarVar (from Perl distribution Calendar-DatesRoles-DataUser-CalendarVar), released on 2019-07-08.

=head1 DESCRIPTION

This role provides L<Calendar::Dates> interface to consumer that has
C<$CALENDAR> package variable. The variable should contain a L<DefHash>.
Relevant keys include: C<default_lang>, C<entries>.

C<entries> is an array of entries, where each entry is a DefHash. Required keys
include: C<date>. C<year>, C<month>, C<day> keys required by Calendar::Dates
will be taken from C<date> to let you be DRY.

Aside from ISO8601 date in the form of C<< YYYY-MM-DD >> or C<<
YYYY-MM-DD"T"HH:MM >>, or date interval in the form of C<<
YYYY-MM-DD"T"HH:MM/HH:MM >>, the C<date> can also be a date-without-year in the
form of C<< --MM-DD >> or C<< MM-DD >>, or repeating date interval in the form
of C<<R/YYYY-MM-DD/P1Y>>. These are to let you specify anniversaries

Example anniversary without starting year:

 {
     summary => "Christmas day",
     date => "12-25", # or "--12-25"
 }

(When returned from C<get_entries>, the date will be converted to C<YYYY-MM-DD>
format.)

Example anniversary with starting year:

 {
     summary => "Larry Wall's birthday",
     date => "R/1954-09-27/P1Y",
 }

(When returned from C<get_entries>, the date will be converted to C<YYYY-MM-DD>
format. Summary will become e.g. for 2019 "Larry Wall's birthday (65th
anniversary)".)

=head2 Anniversaries

To mark an entry as an anniversary without starting year, you can set date to
C<MM-DD> or C<--MM-DD> as previously explained.

To mark an entry as an anniversary with starting year, you can either: 1) set
date to C<R/YYYY-MM-DD/P1Y>; or 2) include "anniversary" tag.

=head1 METHODS

=head2 get_min_year

Only years from non-anniversary dates are accounted for when determining
min_year and max_year. But if there are no non-anniversary dates in the
calendar, then the years from anniversaries will also be used.

=head2 get_max_year

Only years from non-anniversary dates are accounted for when determining
min_year and max_year. But if there are no non-anniversary dates in the
calendar, then the years from anniversaries will also be used.

=head2 get_entries

Usage:

 $entries = $caldate->get_entries([ \%params , ] $year [ , $month [ , $day ] ]);

Only entries from matching year will be used, unless for anniversary entries.

By default, low-priority entries will not be included unless the parameter
C<all> is set to true.

B<Recognized parameters>.

=over

=item * all

Boolean. Specified in Calendar::Dates.

=item * include_tags

Array. Specified in Calendar::Dates.

=item * exclude_tags

Array. Specified in Calendar::Dates.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-DatesRoles-DataUser-CalendarVar>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-DatesRoles-DataUser-CalendarVar>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-DatesRoles-DataUser-CalendarVar>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Calendar::DatesRoles::DataProvider::CalendarVar::FromDATA::Simple>

L<Calendar::DatesRoles::DataProvider::CalendarVar::FromDATA::CSVJF>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
