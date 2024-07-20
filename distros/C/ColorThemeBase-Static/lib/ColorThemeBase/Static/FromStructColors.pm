package ColorThemeBase::Static::FromStructColors;

use strict 'subs', 'vars';
#use warnings;

use parent 'ColorThemeBase::Base';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.009'; # VERSION

sub list_items {
    my $self = shift;

    my $theme_hash = \%{"$self->{orig_class}::THEME"};
    my @list = sort keys %{ $theme_hash->{items} };
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;

    my $theme_hash = \%{"$self->{orig_class}::THEME"};

    my $c = $theme_hash->{items}{$name};
    return unless defined $c;

    if (ref $c eq 'CODE') {
        my $c2 = $c->($self, $name, $args);
        if (ref $c2 eq 'CODE') {
            die "Color '$name' of theme $self->{orig_class} returns coderef, ".
                "which after called still returns a coderef";
        }
        return $c2;
    }
    $c;
}

1;
# ABSTRACT: Base class for color theme modules with static list of items (from %THEME)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeBase::Static::FromStructColors - Base class for color theme modules with static list of items (from %THEME)

=head1 VERSION

This document describes version 0.009 of ColorThemeBase::Static::FromStructColors (from Perl distribution ColorThemeBase-Static), released on 2024-07-17.

=head1 DESCRIPTION

This base class is for color theme modules that only have static list of items,
i.e. all from the %THEME package variable, under the key C<items>.

Note that the item color itself can be dynamic, e.g. return a coderef.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 SEE ALSO

L<ColorThemeBase::Static::FromObjectColors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
