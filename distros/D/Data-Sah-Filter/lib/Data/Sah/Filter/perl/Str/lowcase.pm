package Data::Sah::Filter::perl::Str::lowcase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-30'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Convert string to lowercase',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "lc($dt)",
    );

    $res;
}

1;
# ABSTRACT: Convert string to lowercase

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::lowcase - Convert string to lowercase

=head1 VERSION

This document describes version 0.005 of Data::Sah::Filter::perl::Str::lowcase (from Perl distribution Data-Sah-Filter), released on 2020-05-30.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Str::lowcase"]]

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
