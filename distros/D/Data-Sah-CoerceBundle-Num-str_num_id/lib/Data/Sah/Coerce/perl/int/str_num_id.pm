package Data::Sah::Coerce::perl::int::str_num_id;
use alias::module 'Data::Sah::Coerce::perl::num::str_num_id';

1;
# ABSTRACT: Parse number using Parse::Number::ID

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::int::str_num_id - Parse number using Parse::Number::ID

=head1 VERSION

This document describes version 0.001 of Data::Sah::Coerce::perl::int::str_num_id (from Perl distribution Data-Sah-CoerceBundle-Num-str_num_id), released on 2018-06-11.

=head1 DESCRIPTION

The rule is not enabled by default. You can enable it in a schema using e.g.:

 ["int", "x.perl.coerce_rules"=>["str_num_id"]]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceBundle-Num-str_num_id>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-Num-str_num_id>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceBundle-Num-str_num_id>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
