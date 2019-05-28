package Calendar::DatesRoles::DataUser::CalendarVar;

our $DATE = '2019-05-25'; # DATE
our $VERSION = '0.002'; # VERSION

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
    for my $e (@{ $cal->{entries} }) {
        my $year;
        $e->{date} =~ /\A(\d{4})-(\d{2})-(\d{2})(?:T|\z)/a
            or die "BUG: $mod has an entry that doesn't have valid date: ".
            ($e->{date} // 'undef');
        $e->{year}  //= $1;
        $e->{month} //= $2 + 0;
        $e->{day}   //= $3 + 0;
        $min = $e->{year} if !defined($min) || $min > $e->{year};
        $max = $e->{year} if !defined($max) || $max < $e->{year};
    }
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
    for my $e (@{ $cal->{entries} }) {
        next unless $e->{year} == $year;
        next if defined $month && $e->{month} != $month;
        next if defined $day   && $e->{day}   != $day;
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

This document describes version 0.002 of Calendar::DatesRoles::DataUser::CalendarVar (from Perl distribution Calendar-DatesRoles-DataUser-CalendarVar), released on 2019-05-25.

=head1 DESCRIPTION

This role provides L<Calendar::Dates> interface to consumer that has
C<$CALENDAR> package variable. The variable should contain a L<DefHash>.
Relevant keys include: C<default_lang>, C<entries>.

C<entries> is an array of entries, where each entry is a DefHash. Required keys
include: C<date>. C<year>, C<month>, C<day> keys required by Calendar::Dates
will be taken from C<date> to let you be DRY.

=head1 METHODS

=head2 get_min_year

=head2 get_max_year

=head2 get_entries

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

L<Calendar::DatesRoles::FromData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
