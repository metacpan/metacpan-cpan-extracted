package Data::Sah::CoerceRule::array::str_int_range;

our $DATE = '2018-04-17'; # DATE
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Coerce array of ints from string in the form of "INT1-INT2"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::CoerceRule::array::str_int_range - Coerce array of ints from string in the form of "INT1-INT2"

=head1 VERSION

This document describes version 0.001 of Data::Sah::CoerceRule::array::str_int_range (from Perl distribution Data-Sah-CoerceRule-array-str_int_range), released on 2018-04-17.

=head1 DESCRIPTION

This distribution contains Data::Sah coercion rule to coerce array of ints from
string in the form of "INT1-INT2" string. The rule is not enabled by default.
You can enable it in a schema using e.g.:

 ["array*", of=>"int", "x.coerce_rules"=>["str_int_range"]]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceRule-array-str_int_range>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceRule-array-str_int_range>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceRule-array-str_int_range>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::CoerceRule::array::str_comma_sep>

L<Data::Sah::CoerceRule::array::str_int_range_and_comma_sep>

L<Data::Sah::Coerce>

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
