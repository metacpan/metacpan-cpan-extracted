package App::diffwc::ColorScheme::Firenze;

our $DATE = '2017-08-13'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Color::ANSI::Util qw(ansifg);
use App::diffwc ();

our %colors = (
    delete_line => "8E2800",
    path_line   => "B64926",
    linum_line  => "FFB03B",
    insert_line => "468966",
);

for (keys %colors) {
    $App::diffwc::Colors{$_} =
        $colors{$_} ? ansifg($colors{$_}) : "";
}

1;
# ABSTRACT: Firenze color scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

App::diffwc::ColorScheme::Firenze - Firenze color scheme

=head1 VERSION

This document describes version 0.001 of App::diffwc::ColorScheme::Firenze (from Perl distribution App-diffwc-ColorSchemes-Kuler), released on 2017-08-13.

=head1 SYNOPSIS

On the command-line:

 % diffwc --color-scheme Firenze ...

or:

 % PERL5OPT=-MApp::diffwc::ColorScheme::Firenze diffwc ...

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
