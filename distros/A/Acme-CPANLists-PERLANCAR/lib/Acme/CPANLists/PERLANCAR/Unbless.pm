package Acme::CPANLists::PERLANCAR::Unbless;

our $DATE = '2017-07-28'; # DATE
our $VERSION = '0.25'; # VERSION

our @Module_Lists = (
    {
        summary => 'Unblessing a reference',
        description => <<'_',

Blessing a reference is easy with `bless()` but surprisingly (or
unsurprisingly?) unblessing a blessed reference is not as simple. Currently you
can use the `unbless()` function from <pm:Data::Structure::Util> or `damn()`
from <pm:Acme::Damn> (which is a slimmer module if you just need unblessing
feature). Both are XS modules. If you need a pure-Perl solution, currently
you're out of luck. <pm:Function::Fallback::CoreOrPP> provides `unbless()` where
the fallback option is shallow copying.

_
        entries => [
            {
                module => 'Data::Structure::Util',
            },
            {
                module => 'Acme::Damn',
            },
            {
                module => 'Function::Fallback::CoreOrPP',
            },
        ],
    },
);

1;
# ABSTRACT: Unblessing a reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Unbless - Unblessing a reference

=head1 VERSION

This document describes version 0.25 of Acme::CPANLists::PERLANCAR::Unbless (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-07-28.

=head1 MODULE LISTS

=head2 Unblessing a reference

Blessing a reference is easy with C<bless()> but surprisingly (or
unsurprisingly?) unblessing a blessed reference is not as simple. Currently you
can use the C<unbless()> function from L<Data::Structure::Util> or C<damn()>
from L<Acme::Damn> (which is a slimmer module if you just need unblessing
feature). Both are XS modules. If you need a pure-Perl solution, currently
you're out of luck. L<Function::Fallback::CoreOrPP> provides C<unbless()> where
the fallback option is shallow copying.


=over

=item * L<Data::Structure::Util>

=item * L<Acme::Damn>

=item * L<Function::Fallback::CoreOrPP>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
