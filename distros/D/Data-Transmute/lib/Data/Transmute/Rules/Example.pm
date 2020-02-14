package Data::Transmute::Rules::Example;

use strict;
use warnings;

our @RULES = (
    [create_hash_key => {name=>'a', value=>1}],
    [create_hash_key => {name=>'b', value=>2}],
    [rename_hash_key => {from=>'c', to=>'d'}],
);

1;
# ABSTRACT: Example rules module

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Transmute::Rules::Example - Example rules module

=head1 VERSION

This document describes version 0.039 of Data::Transmute::Rules::Example (from Perl distribution Data-Transmute), released on 2020-02-13.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Transmute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Transmute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Transmute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
