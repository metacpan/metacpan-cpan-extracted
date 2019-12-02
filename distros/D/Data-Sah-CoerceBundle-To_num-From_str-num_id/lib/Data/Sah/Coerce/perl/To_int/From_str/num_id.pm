package Data::Sah::Coerce::perl::To_int::From_str::num_id;
use alias::module 'Data::Sah::Coerce::perl::To_num::From_str::num_id';

1;
# ABSTRACT: Parse number using Parse::Number::ID

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Coerce::perl::To_int::From_str::num_id - Parse number using Parse::Number::ID

=head1 VERSION

This document describes version 0.005 of Data::Sah::Coerce::perl::To_int::From_str::num_id (from Perl distribution Data-Sah-CoerceBundle-To_num-From_str-num_id), released on 2019-11-28.

=head1 SYNOPSIS

To use in a Sah schema:

 ["int",{"x.perl.coerce_rules"=>["From_str::num_id"]}]

=for Pod::Coverage ^(meta|coerce)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-CoerceBundle-To_num-From_str-num_id>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-CoerceBundle-To_num-From_str-num_id>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-CoerceBundle-To_num-From_str-num_id>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
