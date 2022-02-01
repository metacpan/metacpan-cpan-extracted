package Acme::Resume;

# ABSTRACT: Write a human-readable resume in Perl
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0109';

use strict;
use warnings;

use base 'MoopsX::UsingMoose';
use Acme::Resume::Moose();
use Time::Moment;
use syntax();

sub import {
    my $class = shift;
    my %opts = @_;

    push @{ $opts{'imports'} ||= [] } => (
        'syntax' => ['qs'],
        'Acme::Resume::Moose' => [],
    );

    push @{ $opts{'traits'} ||= [] } => (
        'Acme::Resume::MoopsParserTrait',
    );

    $class->SUPER::import(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume - Write a human-readable resume in Perl



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.14+-blue.svg" alt="Requires Perl 5.14+" />
<img src="https://img.shields.io/badge/coverage-86.3%25-orange.svg" alt="coverage 86.3%" />
<a href="https://github.com/Csson/p5-Acme-Resume/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-Acme-Resume/makefile-test" alt="Build status at Github" /></a>
</p>

=end html

=head1 VERSION

Version 0.0109, released 2022-01-30.

=head1 SYNOPSIS

    use Acme::Resume;

    resume ExAmple {

        name 'Ex Ample';

        email 'ex@example.com';

        address ['Suburbia lane 1200', 'Townsville', 'USA'];

        phone '+1 (555) 123 4321';

        education { ... }

        education { ... }

        job { ... }

        job { ... }
    }

    1;

=head1 DESCRIPTION

Acme::Resume is a framework for writing human-readable, computer-executable, object-oriented résumés in Perl.

C<Acme::Resume> is a wrapper around L<Moops> that imports L<Acme::Resume::Moose>, which adds all the methods. It also adds
the L<Acme::Resume::MoopsParserTrait> which includes the C<resume> keyword (just an alias for a standard Moops C<class>) and
adds special handling of the package name:

If the package doesn't contain C<::>, as in the synopsis, the package name will have C<Acme::Resume::For::> automatically prepended.

=head1 METHODS

=head2 name

Your full name.

=head2 email

Your email address.

=head2 phone

Your phone number.

=head2 address

An array reference of address parts.

=head2 education

Can be used multiple times. Adds an L<Acme::Resume::Types::Education> to the list of educations.

=head2 job

Can be used multiple times. Adds a L<Acme::Resume::Types::Job> to the list of jobs.

=head1 USAGE

One way to read a résumé (apart from reading the source) is with one-liners:

    $ perl -MAcme::Resume::For::ExAmple -E 'say Acme::Resume::For::ExAmple->new->get_job(-1)->started->year'

The L<Acme::Resume::Output::ToPlain> role (used by default) adds a C<to_plain> method:

    $ perl -MAcme::Resume::For::Tester -E 'say Acme::Resume::For::Tester->new->to_plain'

=head1 TODO

More documentation and a complete example.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
