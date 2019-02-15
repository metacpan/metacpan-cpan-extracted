package Calendar::DatesRoles::FromData;

our $DATE = '2019-02-14'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Role::Tiny;
no strict 'refs'; # Role::Tiny imports strict for us

sub _parse_data {
    my $mod = shift;

    return if defined ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"};

    my ($min, $max);
    my $fh = \*{"$mod\::DATA"};
    my $i = 0;
    while (my $line = <$fh>) {
        $i++;
        chomp $line;
        next unless $line =~ /\S/;
        next if $line =~ /^#/;
        my @fields = split /;/, $line;
        my $e = {};
        $e->{date} = $fields[0];
        $e->{date} =~ /\A(\d{4})-(\d{2})-(\d{2})(?:T|\z)/a
            or die "BUG: $mod:data #$i: Invalid date syntax '$e->{date}'";
        $e->{year}  = $1;
        $e->{month} = $2 + 0;
        $e->{day}   = $3 + 0;
        $min = $e->{year} if !defined($min) || $min > $e->{year};
        $max = $e->{year} if !defined($max) || $max < $e->{year};
        $e->{summary} = $fields[1];
        $e->{tags} = [split /,/, $fields[2]] if defined $fields[2];
        push @{"$mod\::_CDFROMDATA_CACHE_ENTRIES"}, $e;
    }
    ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"} = $min;
    ${"$mod\::_CDFROMDATA_CACHE_MAX_YEAR"} = $max;
}

sub get_min_year {
    my $mod = shift;

    $mod->_parse_data();
    return ${"$mod\::_CDFROMDATA_CACHE_MIN_YEAR"};
}

sub get_max_year {
    my $mod = shift;

    $mod->_parse_data();
    return ${"$mod\::_CDFROMDATA_CACHE_MAX_YEAR"};
}

sub get_entries {
    my $mod = shift;
    my ($year, $month, $day) = @_;

    die "Please specify year" unless defined $year;
    my $min = $mod->get_min_year;
    die "Year is less than earliest supported year $min" if $year < $min;
    my $max = $mod->get_max_year;
    die "Year is greater than latest supported year $max" if $year > $max;

    my $entries = \@{"$mod\::_CDFROMDATA_CACHE_ENTRIES"};
    my @res;
    for my $e (@$entries) {
        next unless $e->{year} == $year;
        next if defined $month && $e->{month} != $month;
        next if defined $day   && $e->{day}   != $day;
        push @res, $e;
    }

    \@res;
}

1;
# ABSTRACT: Provide Calendar::Dates interface to consumer which has __DATA__ section

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::DatesRoles::FromData - Provide Calendar::Dates interface to consumer which has __DATA__ section

=head1 VERSION

This document describes version 0.002 of Calendar::DatesRoles::FromData (from Perl distribution Calendar-DatesRoles-FromData), released on 2019-02-14.

=head1 DESCRIPTION

This role provides L<Calendar::Dates> interface to modules that puts the entries
in __DATA__ section. Entries should be in the following format:

 YYYY-MM-DD;Summary;tag1,tag2

Blank lines or lines that start with C<#> are ignored.

Examples:

 2019-02-14;Valentine's day
 2019-06-01;Pancasila day

=head1 METHODS

=head2 get_min_year

=head2 get_max_year

=head2 get_entries

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-DatesRoles-FromData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-DatesRoles-FromData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-DatesRoles-FromData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Calendar::DatesRoles::FromEntriesVar>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
