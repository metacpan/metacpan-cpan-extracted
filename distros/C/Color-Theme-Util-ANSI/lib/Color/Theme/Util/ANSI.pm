package Color::Theme::Util::ANSI;

our $DATE = '2018-02-25'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       theme_color_to_ansi
               );

sub theme_color_to_ansi {
    require Color::ANSI::Util;

    my ($color_theme, $item, $args, $is_bg) = @_;

    my $c = $color_theme->{colors}{$item};
    return undef unless defined $c && length $c;

    # resolve coderef color
    if (ref($c) eq 'CODE') {
        $args //= {};
        $c = $c->("self", %$args);
    }

    if (ref $c) {
        my $ansifg = $c->{ansi_fg};
        $ansifg //= Color::ANSI::Util::ansifg($c->{fg})
            if defined $c->{fg};
        $ansifg //= "";
        my $ansibg = $c->{ansi_bg};
        $ansibg //= Color::ANSI::Util::ansibg($c->{bg})
            if defined $c->{bg};
        $ansibg //= "";
        $c = $ansifg . $ansibg;
    } else {
        $c = $is_bg ? Color::ANSI::Util::ansibg($c) :
            Color::ANSI::Util::ansifg($c);
    }
}

1;
# ABSTRACT: Utility routines related to color themes and ANSI code

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Theme::Util::ANSI - Utility routines related to color themes and ANSI code

=head1 VERSION

This document describes version 0.001 of Color::Theme::Util::ANSI (from Perl distribution Color-Theme-Util-ANSI), released on 2018-02-25.

=head1 FUNCTIONS

=head2 theme_color_to_ansi

Usage: theme_color_to_ansi($color_theme, $item, $args, $is_bg) => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-Theme-Util-ANSI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-Theme-Util-ANSI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-Theme-Util-ANSI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Color::Theme::Util>

L<Color::Theme::Role::ANSI>

L<Color::Theme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
