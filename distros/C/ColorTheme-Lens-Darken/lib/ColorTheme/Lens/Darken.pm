package ColorTheme::Lens::Darken;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'ColorTheme-Lens-Darken'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Base';

our %THEME = (
    v => 2,
    summary => 'Darken other theme',
    dynamic => 1,
    args => {
        theme => {
            schema => 'perl::modname_with_args',
            req => 1,
            pos => 0,
        },
        percent => {
            schema => ['num*', between=>[0, 100]],
            default => 50,
        },
    },
);

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    require Module::Load::Util;
    $self->{orig_theme_class} = Module::Load::Util::instantiate_class_with_optional_args(
        $self->{args}{theme});

    $self;
}

sub list_items {
    my $self = shift;

    # return the same list of items as the original theme
    $self->{orig_theme_class}->list_items;
}

sub get_item_color {
    require Color::RGB::Util;

    my $self = shift;

    my $color = $self->{orig_theme_class}->get_item_color(@_);
    $color = {%{$color}} if ref $color eq 'HASH'; # shallow copy

    if (!ref $color) {
        $color = Color::RGB::Util::mix_2_rgb_colors($color, '000000', $self->{args}{percent}/100);
    } else { # assume hash
        $color->{fg} = Color::RGB::Util::mix_2_rgb_colors($color->{fg}, '000000', $self->{args}{percent}/100) if defined $color->{fg} && length $color->{fg};
        $color->{bg} = Color::RGB::Util::mix_2_rgb_colors($color->{bg}, '000000', $self->{args}{percent}/100) if defined $color->{bg} && length $color->{bg};
        # can't mix ansi_fg, ansi_bg
    }
    $color;
}

1;
# ABSTRACT: Darken other theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Lens::Darken - Darken other theme

=head1 VERSION

This document describes version 0.001 of ColorTheme::Lens::Darken (from Perl distribution ColorTheme-Lens-Darken), released on 2020-06-09.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-Lens-Darken>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-Lens-Darken>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme-Lens-Darken>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorTheme::Lens::Brighten>

Other C<ColorTheme::Lens::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
