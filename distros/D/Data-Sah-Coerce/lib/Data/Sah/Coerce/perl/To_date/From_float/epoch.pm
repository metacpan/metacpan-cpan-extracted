package Data::Sah::Coerce::perl::To_date::From_float::epoch;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-02'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.043'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce date from number (assumed to be epoch)',
        prio => 50,
        precludes => ['From_float::EpochAlways'],
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(epoch)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "!ref($dt)",
        "$dt =~ /\\A[0-9]{8,10}(?:\.[0-9]+)?\\z/",
        "$dt >= 10**8",
        "$dt <= 2**31",
    );

    if ($coerce_to eq 'float(epoch)') {
        $res->{expr_coerce} = $dt;
    } elsif ($coerce_to eq 'DateTime') {
        $res->{modules}{DateTime} //= 0;
        $res->{expr_coerce} = "DateTime->from_epoch(epoch => $dt)";
    } elsif ($coerce_to eq 'Time::Moment') {
        $res->{modules}{'Time::Moment'} //= 0;
        $res->{expr_coerce} = "Time::Moment->from_epoch($dt)";
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float(epoch), DateTime, or Time::Moment";
    }

    $res;
}

1;
# ABSTRACT: Coerce date from number (assumed to be epoch)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_date::From_float::epoch - Coerce date from number (assumed to be epoch)

=head1 VERSION

This document describes version 0.043 of Data::Sah::Coerce::perl::To_date::From_float::epoch (from Perl distribution Data-Sah-Coerce), released on 2020-01-02.

=head1 DESCRIPTION

This rule coerces date from a number that is assumed to be a Unix epoch. To
avoid confusion with number that contains "YYYY", "YYYYMM", or "YYYYMMDD", we
only do this coercion if data is a number between 10^8 and 2^31.

Hence, this rule has a Y2038 problem :-).

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Coerce::perl::To_date::From_float::epoch_always>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
