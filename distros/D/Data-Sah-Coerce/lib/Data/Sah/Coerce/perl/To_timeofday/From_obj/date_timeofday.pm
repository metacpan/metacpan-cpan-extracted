package Data::Sah::Coerce::perl::To_timeofday::From_obj::date_timeofday;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-24'; # DATE
our $DIST = 'Data-Sah-Coerce'; # DIST
our $VERSION = '0.054'; # VERSION

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

This document describes version 0.054 of Data::Sah::Coerce::perl::To_timeofday::From_obj::date_timeofday (from Perl distribution Data-Sah-Coerce), released on 2023-10-24.

=head1 SYNOPSIS

To use in a Sah schema:

 ["timeofday",{"x.perl.coerce_rules"=>["From_obj::date_timeofday"]}]

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Coerce>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
