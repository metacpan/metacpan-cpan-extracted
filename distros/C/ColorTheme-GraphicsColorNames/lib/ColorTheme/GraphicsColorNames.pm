package ColorTheme::GraphicsColorNames;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorTheme-GraphicsColorNames'; # DIST
our $VERSION = '0.003'; # VERSION

use strict 'subs', 'vars';
use warnings;
use parent 'ColorThemeBase::Base';

our %THEME = (
    v => 2,
    summary => 'Display Graphics::ColorNames::* color scheme as color theme',
    dynamic => 1,
    args => {
        scheme => {
            schema => 'perl::modname_with_args*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            summary => 'Show Graphics::ColorNames::WWW',
            args => {scheme => 'WWW'},
        },
    ],
);

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new(%args);

    require Module::Load::Util;

    my $res = Module::Load::Util::load_module_with_optional_args(
        {ns_prefix=>'Graphics::ColorNames'}, $self->{args}{scheme});

    $self->{table} = &{"$res->{module}::NamesRgbTable"}();
    $self;
}

sub list_items {
    my $self = shift;

    my @list = sort keys %{ $self->{table} };
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;
    sprintf "%06x", $self->{table}{$name};
}

1;
# ABSTRACT: Display Graphics::ColorNames::* color scheme as color theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::GraphicsColorNames - Display Graphics::ColorNames::* color scheme as color theme

=head1 VERSION

This document describes version 0.003 of ColorTheme::GraphicsColorNames (from Perl distribution ColorTheme-GraphicsColorNames), released on 2020-06-19.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme-GraphicsColorNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme-GraphicsColorNames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme-GraphicsColorNames>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<ColorTheme::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
