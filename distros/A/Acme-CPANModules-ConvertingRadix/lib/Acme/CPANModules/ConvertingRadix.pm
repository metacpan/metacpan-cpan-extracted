package Acme::CPANModules::ConvertingRadix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-09'; # DATE
our $DIST = 'Acme-CPANModules-ConvertingRadix'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Convert the radix (base) of a number from one to another',
    entries => [

        {
            module=>'Math::Numseq::RadixConversion',
            description=><<'_',

The list of dependencies seem too much for a simple task: from
<pm:Module::Pluggable> to <pm:File::HomeDir>, <pm:Module::Util>, and so on.
This is because the module is part of the distribution of a large family of
Math::Numseq::* modules.

_
        },

        {
            module=>'Number::AnyBase',
            description=><<'_',

Has one non-core dependency: <pm:Class::Accessor::Faster>.

_
        },

        {
            module=>'Math::NumberBase',
            description=><<'_',

No non-core dependency. The OO interface annoys me slightly.

_
        },

    ],
};

1;
# ABSTRACT: Convert the radix (base) of a number from one to another

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ConvertingRadix - Convert the radix (base) of a number from one to another

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ConvertingRadix (from Perl distribution Acme-CPANModules-ConvertingRadix), released on 2020-04-09.

=head1 DESCRIPTION

Convert the radix (base) of a number from one to another.

=head1 INCLUDED MODULES

=over

=item * L<Math::Numseq::RadixConversion>

The list of dependencies seem too much for a simple task: from
L<Module::Pluggable> to L<File::HomeDir>, L<Module::Util>, and so on.
This is because the module is part of the distribution of a large family of
Math::Numseq::* modules.


=item * L<Number::AnyBase>

Has one non-core dependency: L<Class::Accessor::Faster>.


=item * L<Math::NumberBase>

No non-core dependency. The OO interface annoys me slightly.


=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ConvertingRadix | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ConvertingRadix -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ConvertingRadix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ConvertingRadix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ConvertingRadix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
