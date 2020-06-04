package Data::Sah::Filter::perl::Float::floor;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Round number to the nearest integer (or "nearest" argument) that is less than the number',
        args => {
            nearest => {
                schema => 'ufloat*',
            },
        },
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};
    my $nearest = $gen_args->{nearest};
    $nearest += 0 if defined $nearest;

    my $res = {};
    $res->{modules}{POSIX} //= 0;
    $res->{expr_filter} = join(
        "",
        defined($nearest) ? "POSIX::floor($dt/$nearest)*$nearest" : "POSIX::floor($dt)",
    );

    $res;
}

1;
# ABSTRACT: Round number to the nearest integer (or "nearest" argument) that is less than the number

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Float::floor - Round number to the nearest integer (or "nearest" argument) that is less than the number

=head1 VERSION

This document describes version 0.008 of Data::Sah::Filter::perl::Float::floor (from Perl distribution Data-Sah-Filter), released on 2020-06-04.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Float::floor"]]

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Related filters: L<Float::ceil|Data::Sah::Filter::perl::Float::ceil>,
L<Float::round|Data::Sah::Filter::perl::Float::round>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
