package Acme::CPANModules::AliasingModuleName;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Aliasing a (long) module name to another (shorter) name',
    tags => ['task'],
    entries => [
        {
            module=>'Package::Alias',
        },
        {
            module=>'alias::module',
            description => <<'_',

I used to use <pm:Package::Alias> but later I created <pm:alias::module> that is
more lightweight (avoids using <pm:Carp>) and has a simpler interface.

_
        },
        {
            module=>'abbreviation',
        },
    ],
};

1;
# ABSTRACT: Aliasing a (long) module name to another (shorter) name

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::AliasingModuleName - Aliasing a (long) module name to another (shorter) name

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::AliasingModuleName (from Perl distribution Acme-CPANModules-AliasingModuleName), released on 2019-01-09.

=head1 DESCRIPTION

Aliasing a (long) module name to another (shorter) name.

=head1 INCLUDED MODULES

=over

=item * L<Package::Alias>

=item * L<alias::module>

I used to use L<Package::Alias> but later I created L<alias::module> that is
more lightweight (avoids using L<Carp>) and has a simpler interface.


=item * L<abbreviation>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-AliasingModuleName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-AliasingModuleName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-AliasingModuleName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
