package ColorTheme::Distinct::WhiteBG;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'ColorTheme-Distinct-WhiteBG'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;
use parent 'ColorThemeBase::Base';

our @colors = (
    'ff0000', # red
    '0000ff', # blue
    '00ff00', # green
    'ffff00', # yellow
    '000000', # black

    'ff00ff', # magenta
    '00ffff', # cyan
    'ff8000', # orange
    '606060', # darkgray

    'ffa0a0', # pink
    'a0a0ff', # light blue
    'a0ffa0', # light green
    'c0c0c0', # light gray
);

our %THEME = (
    v => 2,
    summary => 'Pick some distinct colors (that are suitable for white background) for you',
    description => <<'_',

This is suitable when you want to have different colors for several (like 5 or
10) items, e.g. in line or bar charts.

_
    dynamic => 1,
    args => {
        n => {
            summary => 'Number of colors',
            schema => ['int*', between=>[1, 0+@colors]],
            pos => 0,
            default => 0+@colors,
        },
    },
    examples => [
        {
            summary => 'Show 5 distinct colors you can use as, say, chart color',
            args => {n=>5},
        },
    ],
);

sub new {
    my $class = shift;
    my %args = @_;

    $args{n} //= 0+@colors;
    if (!$args{n}) { die "Please specify a positive n" }
    if ($args{n} > @colors) { die "There are only ".(0+@colors)." colors in the theme, please specify n not greater than this" }

    my $self = $class->SUPER::new(%args);
    $self;
}

sub list_items {
    my $self = shift;

    my @list = 1 .. $self->{args}{n};
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;
    $colors[$name-1];
}

1;
# ABSTRACT: Pick some distinct colors (that are suitable for white background) for you

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Distinct::WhiteBG - Pick some distinct colors (that are suitable for white background) for you

=head1 VERSION

This document describes version 0.002 of ColorTheme::Distinct::WhiteBG (from Perl distribution ColorTheme-Distinct-WhiteBG), released on 2021-01-20.

=head1 DESCRIPTION

This is suitable when you want to have different colors for several (like 5 or
10) items, e.g. in line or bar charts.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-Distinct-WhiteBG>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-Distinct-WhiteBG>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ColorTheme-Distinct-WhiteBG/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorTheme::Distinct::BlackBG>

L<Acme::CPANModules::CreatingPaletteOfVisuallyDistinctColors>

Other C<ColorTheme::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
