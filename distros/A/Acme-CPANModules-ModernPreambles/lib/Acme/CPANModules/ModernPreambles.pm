package Acme::CPANModules::ModernPreambles;

our $DATE = '2019-03-03'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that offer modern preambles',
    description => <<'_',

The overwhelming convention for coding Perl properly code is to at least add the
following preamble:

    use strict;
    use warnings;

to the beginning of your code. But some people say that's not enough, and they
develop modules/pragmas that bundle the above incantation plus some additional
stuffs. For example:

    use Modern::Perl '2018';

is equivalent to:

    use strict;
    use warnings;
    use feature ':5.26';
    mro::set_mro( scalar caller(), 'c3' );

I think <pm:Modern::Perl> is one of the first to popularize this modern preamble
concept and a bunch of similar preambles emerged. This list catalogs them.

Meanwhile, you can also use:

    use v5.12; # enables strict and warnings, as well as all 5.12 features (see <pm:feature> for more details on new features of each perl release)

and so on, but this also means you set a minimum Perl version.

_
    entries => [
        {module=>'Alt::common::sense::TOBYINK'},
        {module=>'common::sense'},
        {module=>'latest'},
        {module=>'Modern::Perl'},
        {module=>'nonsense'},
        {module=>'perl5'},
        {module=>'perl5i'},
    ],
};

1;
# ABSTRACT: Modules that offer modern preambles

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModernPreambles - Modules that offer modern preambles

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ModernPreambles (from Perl distribution Acme-CPANModules-ModernPreambles), released on 2019-03-03.

=head1 DESCRIPTION

Modules that offer modern preambles.

The overwhelming convention for coding Perl properly code is to at least add the
following preamble:

 use strict;
 use warnings;

to the beginning of your code. But some people say that's not enough, and they
develop modules/pragmas that bundle the above incantation plus some additional
stuffs. For example:

 use Modern::Perl '2018';

is equivalent to:

 use strict;
 use warnings;
 use feature ':5.26';
 mro::set_mro( scalar caller(), 'c3' );

I think L<Modern::Perl> is one of the first to popularize this modern preamble
concept and a bunch of similar preambles emerged. This list catalogs them.

Meanwhile, you can also use:

 use v5.12; # enables strict and warnings, as well as all 5.12 features (see L<feature> for more details on new features of each perl release)

and so on, but this also means you set a minimum Perl version.

=head1 INCLUDED MODULES

=over

=item * L<Alt::common::sense::TOBYINK>

=item * L<common::sense>

=item * L<latest>

=item * L<Modern::Perl>

=item * L<nonsense>

=item * L<perl5>

=item * L<perl5i>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModernPreambles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModernPreambles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModernPreambles>

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
