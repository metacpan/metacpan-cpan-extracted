package AppBase::Grep::ColorScheme::Firenze;

our $DATE = '2018-02-11'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Color::ANSI::Util qw(ansifg);
use AppBase::Grep ();

our %colors = (
    match     => "8E2800",
    label     => "B64926",
    linum     => "FFB03B",
    separator => "468966",
);

for (keys %colors) {
    $AppBase::Grep::Colors{$_} =
        $colors{$_} ? ansifg($colors{$_}) : "";
}

1;
# ABSTRACT: Firenze color scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

AppBase::Grep::ColorScheme::Firenze - Firenze color scheme

=head1 VERSION

This document describes version 0.001 of AppBase::Grep::ColorScheme::Firenze (from Perl distribution AppBase-Grep-ColorSchemes-Kuler), released on 2018-02-11.

=head1 SYNOPSIS

On the command-line:

 % abgrep --color-scheme Firenze ...

or:

 % PERL5OPT=-MAppBase::Grep::ColorScheme::Firenze abgrep ...

Screenshot (TODO):

=head1 DESCRIPTION

Note that all scripts that use L<AppBase::Grep> can use this color scheme.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Grep-ColorSchemes-Kuler>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Grep-ColorSchemes-Kuler>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Grep-ColorSchemes-Kuler>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
