package App::cryp::arbit::Strategy::null;

our $DATE = '2021-05-26'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub calculate_order_pairs {
    my ($pkg, %args) = @_;

    return [200, "OK", []];
}

1;
# ABSTRACT: Do nothing (for testing)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::arbit::Strategy::null - Do nothing (for testing)

=head1 VERSION

This document describes version 0.010 of App::cryp::arbit::Strategy::null (from Perl distribution App-cryp-arbit), released on 2021-05-26.

=head1 SYNOPSIS

=head1 DESCRIPTION

This strategy does nothing and will always return empty order pairs. For testing
only.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-arbit>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-arbit>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-cryp-arbit/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
