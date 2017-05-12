package App::ZodiacUtils;

our $DATE = '2016-06-02'; # DATE
our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

my $sch_array_of_dates = ['array*', {
    of=>['date*', {
        'x.perl.coerce_to' => 'DateTime',
        'x.perl.coerce_rules'=>['str_alami_en'],
    }],
    min_len=>1,
}];

$SPEC{zodiac_of} = {
    v => 1.1,
    summary => 'Show zodiac for a date',
    args => {
        dates => {
            summary => 'Dates',
            'x.name.is_plural' => 1,
            schema => $sch_array_of_dates,
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {dates=>['2015-06-15']},
            result => 'gemini',
        },
        {
            summary => 'Multiple dates',
            description => <<'_',

If multiple dates are specified, the result will include the date to
differentiate which zodiac belongs to which date.

_
            args => {dates=>['2015-12-17','2015-12-29']},
            result => [["2015-12-17","sagittarius"], ["2015-12-29","capricornus"]],
        }
    ],
};
sub zodiac_of {
    require Zodiac::Tiny;
    my %args = @_;

    my $dates = $args{dates};

    my $res = [];
    for my $date (@$dates) {

        # when coerced to float(epoch)
        #my @lt = localtime($date);
        #my $ymd = sprintf("%04d-%02d-%02d", $lt[5]+1900, $lt[4]+1, $lt[3]);

        # when coerced to DateTime
        my $ymd = $date->ymd;

        my $z = Zodiac::Tiny::zodiac_of($ymd);
        push @$res, @$dates > 1 ? [$ymd, $z] : $z;
    }
    $res = $res->[0] if @$res == 1;
    $res;
}

$SPEC{chinese_zodiac_of} = {
    v => 1.1,
    summary => 'Show Chinese zodiac for a date',
    args => {
        dates => {
            summary => 'Dates',
            'x.name.is_plural' => 1,
            schema => $sch_array_of_dates,
            req => 1,
            pos => 0,
            greedy => 1,
        },
    },
    result_naked => 1,
    examples => [
        {
            args => {dates=>['1980-02-17']},
            result => 'monkey (metal)',
        },
        {
            summary => 'Multiple dates',
            args => {dates=>['2015-12-17','2016-12-17']},
            result => [["2015-12-17","goat (wood)"], ["2016-12-17","monkey (fire)"]],
            test => 0,
        }
    ],

};
sub chinese_zodiac_of {
    require Zodiac::Chinese::Table;
    my %args = @_;

    my $dates = $args{dates};

    my $res = [];
    for my $date (@$dates) {

        # when coerced to float(epoch)
        #my @lt = localtime($date);
        #my $ymd = sprintf("%04d-%02d-%02d", $lt[5]+1900, $lt[4]+1, $lt[3]);

        # when coerced to DateTime
        my $ymd = $date->ymd;

        my $czres = Zodiac::Chinese::Table::chinese_zodiac($ymd);
        my $z = $czres ? "$czres->[7] ($czres->[3])" : undef;
        push @$res, @$dates > 1 ? [$ymd, $z] : $z;
    }
    $res = $res->[0] if @$res == 1;
    $res;
}

1;
# ABSTRACT: CLI utilities related to zodiac

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ZodiacUtils - CLI utilities related to zodiac

=head1 VERSION

This document describes version 0.10 of App::ZodiacUtils (from Perl distribution App-ZodiacUtils), released on 2016-06-02.

=head1 DESCRIPTION

This distribution includes the following CLI utilities:

=over

=item * L<chinese-zodiac-of>

=item * L<zodiac-of>

=back

=head1 FUNCTIONS


=head2 chinese_zodiac_of(%args) -> any

Show Chinese zodiac for a date.

Examples:

=over

=item * Example #1:

 chinese_zodiac_of(dates => ["1980-02-17"]); # -> "monkey (metal)"

=item * Multiple dates:

 chinese_zodiac_of(dates => ["2015-12-17", "2016-12-17"]);

Result:

 [
   ["2015-12-17", "goat (wood)"],
   ["2016-12-17", "monkey (fire)"],
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[date]>

Dates.

=back

Return value:  (any)


=head2 zodiac_of(%args) -> any

Show zodiac for a date.

Examples:

=over

=item * Example #1:

 zodiac_of(dates => ["2015-06-15"]); # -> "gemini"

=item * Multiple dates:

 zodiac_of(dates => ["2015-12-17", "2015-12-29"]);

Result:

 [["2015-12-17", "sagittarius"], ["2015-12-29", "capricornus"]]

If multiple dates are specified, the result will include the date to
differentiate which zodiac belongs to which date.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dates>* => I<array[date]>

Dates.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ZodiacUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ZodiacUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ZodiacUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
