package Data::Sah::Coerce::perl::To_duration::From_str::hms;

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
        summary => 'Coerce duration from string in the form of hh:mm:ss (or hh:mm)',
        might_fail => 1, # we match any (hh:mm:ss string, so the conversion might fail on invalid value)
        prio => 40, # higher than From_str::human
    };
}

sub coerce {
    my %args = @_;

    my $dt = $args{data_term};
    my $coerce_to = $args{coerce_to} // 'float(secs)';

    my $res = {};

    $res->{expr_match} = join(
        " && ",
        "$dt =~ /\\A([0-9]{1,2}):([0-9]{1,2})(?::([0-9]{1,2})(\\.[0-9]{1,9})?)?\\z/",
    );

    my $code_check = qq(if (\$1 > 23) { ["Invalid hour '\$1', must be between 0-23"] } elsif (\$2 > 59) { ["Invalid minute '\$2', must be between 0-59"] } elsif (defined \$3 && \$3 > 59) { ["Invalid second '\$3', must be between 0-59"] });

    if ($coerce_to eq 'float(secs)') {
        $res->{expr_coerce} = qq(do { $code_check else { [undef, \$1*3600 + \$2*60 + (defined \$3 ? \$3 : 0) + (defined \$4 ? \$4 : 0)] } });
    } elsif ($coerce_to eq 'DateTime::Duration') {
        $res->{modules}{"DateTime::Duration"} //= 0;
        $res->{expr_coerce} = qq(do { $code_check else { [undef, DateTime::Duration->new(hours => \$1, minutes => \$2, seconds => (defined \$3 ? \$3 : 0), nanoseconds => (defined \$4 ? \$4 * 1e9 : 0))] } });
    } else {
        die "BUG: Unknown coerce_to value '$coerce_to', ".
            "please use 'float(secs)' or 'DateTime::Duration'";
    }

    $res;
}

1;
# ABSTRACT: Coerce duration from string in the form of hh:mm:ss (or hh:mm)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_duration::From_str::hms - Coerce duration from string in the form of hh:mm:ss (or hh:mm)

=head1 VERSION

This document describes version 0.054 of Data::Sah::Coerce::perl::To_duration::From_str::hms (from Perl distribution Data-Sah-Coerce), released on 2023-10-24.

=head1 SYNOPSIS

To use in a Sah schema:

 ["duration",{"x.perl.coerce_rules"=>["From_str::hms"]}]

=head1 DESCRIPTION

Duration can be coerced into one of: C<float(secs)> (number of seconds) or
C<DateTime::Duration> (L<DateTime::Duration> object).

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
