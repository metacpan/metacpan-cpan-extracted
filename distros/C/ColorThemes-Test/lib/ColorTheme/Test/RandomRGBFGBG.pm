package ColorTheme::Test::RandomRGBFGBG;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-01'; # DATE
our $DIST = 'ColorThemes-Test'; # DIST
our $VERSION = '0.007'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Base';

use Color::RGB::Util qw(rand_rgb_color);

our %THEME = (
    v => 2,
    summary => 'A color theme which gives random RGB foreground+background colors',
    dynamic => 1,
    args => {
        cache => {
            schema => 'bool*',
            default => 1,
        },
        num => {
            schema => 'posint*',
            default => 5,
        },
    },
);

sub list_items {
    my $self = shift;

    my @list = 0 .. ($self->{args}{num}//5)-1;
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;
    if ($self->{args}{cache}) {
        return $self->{_cache}{$name} if defined $self->{_cache}{$name};
        $self->{_cache}{$name} = {fg=>rand_rgb_color(), bg=>rand_rgb_color()};
    } else {
        return {fg=>rand_rgb_color(), bg=>rand_rgb_color()};
    }
}

1;
# ABSTRACT: A color theme which gives random RGB foreground+background colors

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Test::RandomRGBFGBG - A color theme which gives random RGB foreground+background colors

=head1 VERSION

This document describes version 0.007 of ColorTheme::Test::RandomRGBFGBG (from Perl distribution ColorThemes-Test), released on 2021-08-01.

=head1 SYNOPSIS

Show a color swatch of this theme:

 % show-color-theme-swatch Test/RandomRGBFGBG

Specify number of colors:

 % show-color-theme-swatch Test/RandomRGBFGBG=num,10

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemes-Test>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemes-Test>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemes-Test>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
