package ColorThemeUtil::ANSI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-06'; # DATE
our $DIST = 'ColorThemeUtil-ANSI'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       item_color_to_ansi
               );

sub item_color_to_ansi {
    require Color::ANSI::Util;

    my ($color, $is_bg) = @_;

    return unless defined $color && length($color);

    # force color depth detection
    Color::ANSI::Util::_color_depth();

    return "" if !$Color::ANSI::Util::_color_depth;

    my $ansi;
    if (ref $color eq 'HASH') {
        my $ansifg = $color->{ansi_fg};
        $ansifg //= Color::ANSI::Util::ansifg($color->{fg})
            if defined $color->{fg};
        $ansifg //= "";
        my $ansibg = $color->{ansi_bg};
        $ansibg //= Color::ANSI::Util::ansibg($color->{bg})
            if defined $color->{bg};
        $ansibg //= "";
        $ansi = $ansifg . $ansibg;
    } elsif (ref $color) {
        die "Cannot handle color $color";
    } else {
        $ansi = $is_bg ? Color::ANSI::Util::ansibg($color) :
            Color::ANSI::Util::ansifg($color);
    }
    $ansi;
}

1;
# ABSTRACT: Utility routines related to color themes and ANSI code

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeUtil::ANSI - Utility routines related to color themes and ANSI code

=head1 VERSION

This document describes version 0.002 of ColorThemeUtil::ANSI (from Perl distribution ColorThemeUtil-ANSI), released on 2021-02-06.

=head1 FUNCTIONS

=head2 item_color_to_ansi

Usage:

 my $ansi_code = item_color_to_ansi($color [ , $is_bg ]);

This routine expects an item color (string or hash, see L<ColorTheme>) returned
by C<get_item_color()> and converts it to ANSI code. This routine cannot handle
coderef item color directly; so use C<get_item_color()> first.

If the item color has C<ansi_fg> or C<ansi_bg> property, this routine will use
that directly. Otherwise, it will convert RGB to ANSI.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeUtil-ANSI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeUtil-ANSI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ColorThemeUtil-ANSI/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorTheme>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
