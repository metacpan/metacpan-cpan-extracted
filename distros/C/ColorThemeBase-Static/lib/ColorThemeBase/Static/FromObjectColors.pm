package ColorThemeBase::Static::FromObjectColors;

use strict 'subs', 'vars';
#use warnings;

use parent 'ColorThemeBase::Base';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.009'; # VERSION

sub list_items {
    my $self = shift;
    my @list = sort keys %{ $self->{items} };
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;

    my $c = $self->{items}{$name};
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
# ABSTRACT: Base class for color theme modules with static list of items (from object's items key)

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeBase::Static::FromObjectColors - Base class for color theme modules with static list of items (from object's items key)

=head1 VERSION

This document describes version 0.009 of ColorThemeBase::Static::FromObjectColors (from Perl distribution ColorThemeBase-Static), released on 2024-07-17.

=head1 DESCRIPTION

Much like L<ColorThemeBase::Static::FromStructColors>, this base class also gets
the list of items from a data structure, in this case the object's C<items> key
which is assumed to be a mapping of item names and item colors, much like the
C<items> property of the color theme structure. It is expected that the subclass
sets the value of this key during initialization.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 SEE ALSO

L<ColorThemeBase::Static::FromStructColors>

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
