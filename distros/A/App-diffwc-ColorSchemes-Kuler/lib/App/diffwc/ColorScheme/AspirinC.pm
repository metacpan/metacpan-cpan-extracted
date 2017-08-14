package App::diffwc::ColorScheme::AspirinC;

our $DATE = '2017-08-13'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Color::ANSI::Util qw(ansifg);
use App::diffwc ();

our %colors = (
    delete_line => "EB7F00",
    path_line   => "F3FFE2",
    linum_line  => "1695A3",
    insert_line => "225378",
);

for (keys %colors) {
    $App::diffwc::Colors{$_} =
        $colors{$_} ? ansifg($colors{$_}) : "";
}

1;
# ABSTRACT: AspirinC color scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

App::diffwc::ColorScheme::AspirinC - AspirinC color scheme

=head1 VERSION

This document describes version 0.001 of App::diffwc::ColorScheme::AspirinC (from Perl distribution App-diffwc-ColorSchemes-Kuler), released on 2017-08-13.

=head1 SYNOPSIS

On the command-line:

 % diffwc --color-scheme AspirinC ...

or:

 % PERL5OPT=-MApp::diffwc::ColorScheme::AspirinC diffwc ...

Screenshot (TODO):

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-diffwc-ColorSchemes-Kuler>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-diffwc-ColorSchemes-Kuler>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-diffwc-ColorSchemes-Kuler>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
