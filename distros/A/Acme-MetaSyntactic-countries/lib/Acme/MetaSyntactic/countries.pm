package Acme::MetaSyntactic::countries;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.002'; # VERSION

use parent qw(Acme::MetaSyntactic::WordList);
my $data = __PACKAGE__->init_data('WordList::EN::CountryNames::SingleWord');
__PACKAGE__->init($data);

1;
# ABSTRACT: Country names

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::countries - Country names

=head1 VERSION

This document describes version 0.002 of Acme::MetaSyntactic::countries (from Perl distribution Acme-MetaSyntactic-countries), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=countries -le 'print metaname'
 indonesia

 % meta countries 2
 ghana
 china

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-countries>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-countries>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-countries>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
