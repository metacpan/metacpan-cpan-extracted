package Acme::MetaSyntactic::display_resolution;

our $DATE = '2017-02-04'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent 'Acme::MetaSyntactic::List';
use Display::Resolution qw(list_display_resolution_names);

__PACKAGE__->init(do {
    my $names0 = list_display_resolution_names();
    my $names = {};
    for (keys %$names0) {
        next unless /\A[A-Za-z][A-Za-z0-9_]*\z/;
        $names->{lc $_} = 1;
    }
    { names => join(" ", sort keys %$names) };
});

1;
# ABSTRACT: Display resolution names

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::MetaSyntactic::display_resolution - Display resolution names

=head1 VERSION

This document describes version 0.003 of Acme::MetaSyntactic::display_resolution (from Perl distribution Acme-MetaSyntactic-display_resolution), released on 2017-02-04.

=head1 SYNOPSIS

 % perl -MAcme::MetaSyntactic=display_resolution -le 'print metaname'
 qhd

 % meta display_resolution 2
 fhd
 wxga

=head1 DESCRIPTION

This theme includes display resolution names retrieved from
L<Display::Resolution>. Only names that start with letters and contain solely
letters/numbers are included. The names are lowercased.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-MetaSyntactic-display_resolution>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-MetaSyntactic-display_resolution>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-MetaSyntactic-display_resolution>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::MetaSyntactic>

L<Display::Resolution>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
