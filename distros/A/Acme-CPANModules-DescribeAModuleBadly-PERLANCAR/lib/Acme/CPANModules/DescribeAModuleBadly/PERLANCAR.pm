package Acme::CPANModules::DescribeAModuleBadly::PERLANCAR;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-23'; # DATE
our $DIST = 'Acme-CPANModules-DescribeAModuleBadly-PERLANCAR'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'PERLANCAR describing modules badly',
    description => <<'_',

_
    entries => [

        {
            module => 'Path::Tiny',
            description => <<'_',

When you're bored and want to relearn crawling, standing up, walking and speech
all over again when dealing with files.

_
        },

        {
            module => 'M',
            description => <<'_',

Remember when you want to have more than four ways to do OO, but less than six?
Yeah, me neither.

 (To be honest, I've used all <pm:Moose>, <pm:Mouse>, <pm:Moo>,
and <pm:Mo> for "real-world" purposes, and Mo is so lightweight the only way to
be more lightweight is to do bare OO by yourself.)

_
        },

        {
            module => 'Dist::Zilla',
            description => <<'_',

An ideal distribution builder tool, particularly if you need to develop dzil
plugin distributions.

_
        },

    ],
};

1;
# ABSTRACT: PERLANCAR describing modules badly

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DescribeAModuleBadly::PERLANCAR - PERLANCAR describing modules badly

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::DescribeAModuleBadly::PERLANCAR (from Perl distribution Acme-CPANModules-DescribeAModuleBadly-PERLANCAR), released on 2020-02-23.

=head1 DESCRIPTION

PERLANCAR describing modules badly.

=head1 INCLUDED MODULES

=over

=item * L<Path::Tiny>

When you're bored and want to relearn crawling, standing up, walking and speech
all over again when dealing with files.


=item * L<M>

Remember when you want to have more than four ways to do OO, but less than six?
Yeah, me neither.

 (To be honest, I've used all L<Moose>, L<Mouse>, L<Moo>,
and L<Mo> for "real-world" purposes, and Mo is so lightweight the only way to
be more lightweight is to do bare OO by yourself.)


=item * L<Dist::Zilla>

An ideal distribution builder tool, particularly if you need to develop dzil
plugin distributions.


=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries DescribeAModuleBadly::PERLANCAR | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DescribeAModuleBadly::PERLANCAR -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DescribeAModuleBadly-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DescribeAModuleBadly-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DescribeAModuleBadly-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

The L<Acme::CPANModules::DescribeAModuleBadly> namespace.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
