package Acme::CPANModules::OneLetter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-21'; # DATE
our $DIST = 'Acme-CPANModules-OneLetter'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'One-letter CPAN modules',
    description => <<'_',

Just a list of one-letter modules on CPAN.

To produce this list, you can also use <prog:lcpan>:

    % lcpan mods -l -x --or `perl -E'say for "A".."Z","a".."z","_"'`

For CPAN author, What one-letter name can I use that's available? (Requires
<prog:setop> and <prog:cpanmodules> CLIs.)

    % setop --diff <(perl -E'say for "A".."Z","a".."z","_"') <(cpanmodules ls-entries OneLetter)

_
    entries => [
        {module=>'B'},
        {module=>'D'},
        {module=>'H'},
        {module=>'K'},
        {module=>'L'},
        {module=>'M'},
        {module=>'O'},
        {module=>'P'},
        {module=>'T'},
        {module=>'U'},
        {module=>'V'},
        {module=>'Z'},
        {module=>'c'},
    ],
};

1;
# ABSTRACT: One-letter CPAN modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OneLetter - One-letter CPAN modules

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::OneLetter (from Perl distribution Acme-CPANModules-OneLetter), released on 2020-09-21.

=head1 DESCRIPTION

Just a list of one-letter modules on CPAN.

To produce this list, you can also use L<lcpan>:

 % lcpan mods -l -x --or C<perl -E'say for "A".."Z","a".."z","_"'>

For CPAN author, What one-letter name can I use that's available? (Requires
L<setop> and L<cpanmodules> CLIs.)

 % setop --diff <(perl -E'say for "A".."Z","a".."z","_"') <(cpanmodules ls-entries OneLetter)

=head1 INCLUDED MODULES

=over

=item * L<B>

=item * L<D>

=item * L<H>

=item * L<K>

=item * L<L>

=item * L<M>

=item * L<O>

=item * L<P>

=item * L<T>

=item * L<U>

=item * L<V>

=item * L<Z>

=item * L<c>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries OneLetter | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OneLetter -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OneLetter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OneLetter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OneLetter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
