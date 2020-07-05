package ColorTheme::Lens::Tint;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorTheme-Lens-Tint'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Base';

our %THEME = (
    v => 2,
    summary => 'Tint other theme',
    description => <<'_',

This color theme tints RGB colors from other color scheme with another color.

_
    dynamic => 1,
    args => {
        theme => {
            schema => 'perl::modname_with_args',
            req => 1,
            pos => 0,
        },
        color => {
            summary => 'Tint color',
            schema => 'color::rgb24*',
            req => 1,
            pos => 1,
        },
        percent => {
            schema => ['num*', between=>[0, 100]],
            default => 50,
        },
    },
    examples => [
        {
            summary => 'Tint another color theme with lots of red',
            args => {theme => 'Test::Static', color=>'ff0000', percent=>90},
        },
    ],
);

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    require Module::Load::Util;
    $self->{orig_theme_class} = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>'ColorTheme'}, $self->{args}{theme});

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
        $color = Color::RGB::Util::tint_rgb_color($color, $self->{args}{color}, $self->{args}{percent}/100);
    } else { # assume hash
        $color->{fg} = Color::RGB::Util::tint_rgb_color($color->{fg}, $self->{args}{color}, $self->{args}{percent}/100) if defined $color->{fg} && length $color->{fg};
        $color->{bg} = Color::RGB::Util::tint_rgb_color($color->{bg}, $self->{args}{color}, $self->{args}{percent}/100) if defined $color->{bg} && length $color->{bg};
        # can't tint ansi_fg, ansi_bg
    }
    $color;
}

1;
# ABSTRACT: Tint other theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Lens::Tint - Tint other theme

=head1 VERSION

This document describes version 0.002 of ColorTheme::Lens::Tint (from Perl distribution ColorTheme-Lens-Tint), released on 2020-06-19.

=head1 DESCRIPTION

This color theme tints RGB colors from other color scheme with another color.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-Lens-Tint>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-Lens-Tint>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme-Lens-Tint>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<ColorTheme::Lens::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
