package Data::Sah::Coerce::perl::To_timeofday::From_obj::date_timeofday;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.039'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 4,
        summary => 'Coerce timeofday from Date::TimeOfDay object',
        prio => 50,
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'str_hms';

    my $res = {};

    $res->{modules}{'Scalar::Util'} //= 0;

    $res->{expr_match} = join(
        " && ",
        "Scalar::Util::blessed($dt)",
        "$dt\->isa('Date::TimeOfDay')",
    );

    if ($coerce_to eq 'float') {
        $res->{expr_coerce} = "$dt\->float";
    } elsif ($coerce_to eq 'str_hms') {
        $res->{expr_coerce} = "$dt\->hms";
    } elsif ($coerce_to eq 'Date::TimeOfDay') {
        $res->{expr_coerce} = $dt;
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use float, str_hms, or Date::TimeOfDay";
    }

    $res;
}

1;
# ABSTRACT: Coerce timeofday from Date::TimeOfDay object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_timeofday::From_obj::date_timeofday - Coerce timeofday from Date::TimeOfDay object

=head1 VERSION

This document describes version 0.039 of Data::Sah::Coerce::perl::To_timeofday::From_obj::date_timeofday (from Perl distribution Data-Sah-Coerce), released on 2019-11-28.

=head1 DESCRIPTION

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
