package Data::Sah::CoerceRule::array::str_comma_sep;

our $DATE = '2016-05-23'; # DATE
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Coerce array from a comma-separated items in a string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::CoerceRule::array::str_comma_sep - Coerce array from a comma-separated items in a string

=head1 VERSION

This document describes version 0.005 of Data::Sah::CoerceRule::array::str_comma_sep (from Perl distribution Data-Sah-CoerceRule-array-str_comma_sep), released on 2016-05-23.

=head1 DESCRIPTION

This distribution contains Data::Sah coercion rule to coerce array from a
comma-separated items in a string. The rule is not enabled by default. You can
enable it in a schema using e.g.:

 ["array*", of=>"int", "x.coerce_rules"=>["str_comma_sep"]]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceRule-array-str_comma_sep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceRule-array-str_comma_sep>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceRule-array-str_comma_sep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Coerce>

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
