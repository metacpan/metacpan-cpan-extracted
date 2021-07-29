package Acme::PERLANCAR::Dummy::ModuleFeatures::Declarer_PythonTrove;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-26'; # DATE
our $DIST = 'Acme-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.011'; # VERSION

use strict;
use warnings;

our %FEATURES = (
    set_v => {
        Dummy => 1,
    },
    features => {
        PythonTrove => {
            "Development Status" => "3 - Alpha",
            "Intended Audience" => "Developers",
            "License" => [
                "OSI Approved :: Artistic License",
                "OSI Approved :: GNU General Public License v2 or later (GPLv2+)",
            ],
            "Natural Language" => "Indonesian",
            "Programming Language" => "Perl",
            "Environment" => "Console",
            "Topic" => [
                "Software Development :: Libraries :: Perl Modules",
                "Text Processing :: Linguistic",
                "Utilities",
            ],
        },

    },
);

1;
# ABSTRACT: A test module that declares features from Module::Features::PythonTrove

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::PERLANCAR::Dummy::ModuleFeatures::Declarer_PythonTrove - A test module that declares features from Module::Features::PythonTrove

=head1 VERSION

This document describes version 0.011 of Acme::PERLANCAR::Dummy::ModuleFeatures::Declarer_PythonTrove (from Perl distribution Acme-PERLANCAR-Dummy), released on 2021-07-26.

=head1 DESCRIPTION

This is a dummy module for testing. It declares features from the
L<PythonTrove|Module::Features::PythonTrove> feature set.

=head1 DECLARED FEATURES

Features declared by this module:

=head2 From feature set PythonTrove

Features from feature set L<PythonTrove|Module::Features::PythonTrove> declared by this module:

=over

=item * Development Status

Value: yes.

=item * Environment

Value: yes.

=item * Intended Audience

Value: yes.

=item * License

Value: yes.

=item * Natural Language

Value: yes.

=item * Programming Language

Value: yes.

=item * Topic

Value: yes.

=back

For more details on module features, see L<Module::Features>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-PERLANCAR-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PERLANCAR-Dummy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
