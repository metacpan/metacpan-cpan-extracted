package ColorThemeBase::Static::FromStructColors;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.008'; # VERSION

use strict 'subs', 'vars';
#use warnings;

use parent 'ColorThemeBase::Base';

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

This document describes version 0.008 of ColorThemeBase::Static::FromStructColors (from Perl distribution ColorThemeBase-Static), released on 2020-06-19.

=head1 DESCRIPTION

This base class is for color theme modules that only have static list of items,
i.e. all from the %THEME package variable, under the key C<items>.

Note that the item color itself can be dynamic, e.g. return a coderef.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ColorThemeBase::Static::FromObjectColors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
