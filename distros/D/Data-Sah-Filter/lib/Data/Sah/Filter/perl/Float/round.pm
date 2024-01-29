package Data::Sah::Filter::perl::Float::round;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-17'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.024'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Round number to the nearest integer (or "nearest" argument)',
        args => {
            nearest => {
                schema => 'ufloat*',
            },
        },
        examples => [
            {value=>1, filtered_value=>1},
            {value=>-1.1, filtered_value=>-1},
            {value=>1.1, filtered_value=>1},
            {value=>1.1, filter_args=>{nearest=>0.5}, filtered_value=>1},
            {value=>1.3, filter_args=>{nearest=>0.5}, filtered_value=>1.5},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};
    my $nearest = $gen_args->{nearest};
    $nearest += 0 if defined $nearest;

    my $res = {};
    $res->{expr_filter} = join(
        "",
        defined($nearest) ? "sprintf('%.0f', $dt/$nearest) * $nearest" : "sprintf('%.0f', $dt)",
    );

    $res;
}

1;
# ABSTRACT: Round number to the nearest integer (or "nearest" argument)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Float::round - Round number to the nearest integer (or "nearest" argument)

=head1 VERSION

This document describes version 0.024 of Data::Sah::Filter::perl::Float::round (from Perl distribution Data-Sah-Filter), released on 2024-01-17.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Float::round"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Float::round"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Float::round"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 1 # valid, unchanged
 -1.1 # valid, becomes -1
 1.1 # valid, becomes 1
 1.1 # filtered with args {nearest=>0.5}, valid, becomes 1
 1.3 # filtered with args {nearest=>0.5}, valid, becomes 1.5

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

Related filters: L<Float::ceil|Data::Sah::Filter::perl::Float::ceil>,
L<Float::floor|Data::Sah::Filter::perl::Float::floor>.

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

This software is copyright (c) 2024, 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
