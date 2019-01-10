package Acme::CPANModules::Assert;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Assertion',
    description => <<'_',

Assertion is a check statement that must evaluate to true or it will abort
program's execution. It is useful during development/debugging:

    assert("there must be >3 arguments", sub { @args > 3 });

In production code, compilers ideally do not generate code for assertion
statements so they do not have any impact on runtime performance.

In the old days, you only have this alternative to do it in Perl:

    assert(...) if DEBUG;

where `DEBUG` is a constant subroutine, declared using:

    use constant DEBUG => 0;

or:

    sub DEBUG() { 0 }

The perl compiler will optimize away and remove the code entirely when `DEBUG`
is false. But having to add `if DEBUG` to each assertion is annoying and
error-prone.

Nowadays, you have several alternatives to have a true, C-like assertions. One
technique is using <pm:Devel::Declare> (e.g. <pm:PerlX::Assert>). Another technique is
using <pm:B::CallChecker> (e.g. <pm:Assert::Conditional>).

_

        entries => [
            {module=>'Assert::Conditional'},
            {module=>'PerlX::Assert'},
            {module=>'Devel::Assert'},
            #{module=>'assertions'}, # this module doesn't work now, it uses an experimental feature available on 5.9.x which finally removed before 5.10.
        ],
    };

1;
# ABSTRACT: Assertion

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Assert - Assertion

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Assert (from Perl distribution Acme-CPANModules-Assert), released on 2019-01-09.

=head1 DESCRIPTION

Assertion.

Assertion is a check statement that must evaluate to true or it will abort
program's execution. It is useful during development/debugging:

 assert("there must be >3 arguments", sub { @args > 3 });

In production code, compilers ideally do not generate code for assertion
statements so they do not have any impact on runtime performance.

In the old days, you only have this alternative to do it in Perl:

 assert(...) if DEBUG;

where C<DEBUG> is a constant subroutine, declared using:

 use constant DEBUG => 0;

or:

 sub DEBUG() { 0 }

The perl compiler will optimize away and remove the code entirely when C<DEBUG>
is false. But having to add C<if DEBUG> to each assertion is annoying and
error-prone.

Nowadays, you have several alternatives to have a true, C-like assertions. One
technique is using L<Devel::Declare> (e.g. L<PerlX::Assert>). Another technique is
using L<B::CallChecker> (e.g. L<Assert::Conditional>).

=head1 INCLUDED MODULES

=over

=item * L<Assert::Conditional>

=item * L<PerlX::Assert>

=item * L<Devel::Assert>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Assert>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Assert>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Assert>

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
