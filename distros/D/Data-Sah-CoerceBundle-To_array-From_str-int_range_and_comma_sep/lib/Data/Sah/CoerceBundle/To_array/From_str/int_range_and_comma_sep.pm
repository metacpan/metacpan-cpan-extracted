package Data::Sah::CoerceBundle::To_array::From_str::int_range_and_comma_sep;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Data-Sah-CoerceBundle-To_array-From_str-int_range_and_comma_sep'; # DIST
our $VERSION = '0.006'; # VERSION

1;
# ABSTRACT: Coerce array of ints from comma-separated ints/int ranges

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::CoerceBundle::To_array::From_str::int_range_and_comma_sep - Coerce array of ints from comma-separated ints/int ranges

=head1 VERSION

This document describes version 0.006 of Data::Sah::CoerceBundle::To_array::From_str::int_range_and_comma_sep (from Perl distribution Data-Sah-CoerceBundle-To_array-From_str-int_range_and_comma_sep), released on 2019-11-28.

=head1 DESCRIPTION

This distribution contains the following L<Sah> coerce rule modules:

=over

=item * L<Data::Sah::Coerce::perl::To_array::From_str::int_range_and_comma_sep>

=back

This distribution contains Data::Sah coercion rule to coerce array of ints from
string in the form of comma-separated integers/integer ranges, for example:

 1
 1,2,4
 5-10
 5..10
 1, 5-10, 15, 20-23

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceBundle-To_array-From_str-int_range_and_comma_sep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-To_array-From_str-int_range_and_comma_sep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceBundle-To_array-From_str-int_range_and_comma_sep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::CoerceBundle::To_array::From_str::comma_sep>

L<Data::Sah::CoerceBundle::To_array::From_str::int_range>

L<Data::Sah::Coerce>

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
