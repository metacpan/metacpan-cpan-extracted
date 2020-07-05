package ColorTheme;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorTheme'; # DIST
our $VERSION = '2.1.2'; # VERSION

1;
# ABSTRACT: Color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme - Color themes

=head1 SPECIFICATION VERSION

2

=head1 VERSION

This document describes version 2.1.2 of ColorTheme (from Perl distribution ColorTheme), released on 2020-06-19.

=head1 DESCRIPTION

This document specifies a way to create and use color themes.

=head1 SPECIFICATION STATUS

The series 2.x version is still unstable. API might still change between
releases.

=head1 GLOSSARY

=head2 color theme

Essentially, a mapping of item names and item colors. For example, a color theme
for syntax-coloring JSON might be something like:

 {
   string  => "ffff00",
   number  => "00ffff",
   comma   => "",
   brace   => "",
   bracket => "",
   null    => "ff0000",
   true    => "00ff00",
   false   => "008000",
 }

An application (in this case, a JSON pretty-printer) will consult the color
theme to get the color codes for various items. By using a different color theme
which contains the same item names, a user can change the appearance of an
application or its output (in terms of color) simply by using another compatible
color theme, i.e. color theme which provides color codes for the same items.

=head2 color theme structure

A L<DefHash> which contains the L</color theme> and additional data.

A simple (L<static|/static color theme>) theme has all its information
accessible from the color theme structure.

=head2 color theme class

A Perl module in the C<ColorTheme::*> namespace following this specification. A
color theme class contains L</color theme structure> in its C<%THEME> package
variable, as well as some required methods to access the information in the
structure.

A simple (L<static|/static color theme>) theme has all its information
accessible from the color theme structure, so client can actually bypass the
methods and access the color theme structure directly. Although it is
recommended to always use the methods to access information in the color theme.

=head2 static color theme

A color theme where all the items are specified in the color theme structure. A
client can by-pass the method and access C<%THEME> directly.

See also: L</dynamic color theme>.

=head2 dynamic color theme

A color theme where one must call C</list_items> to get all the items, because
not all (or any) of the items are specified in the color theme structure.

A dynamic color theme can produce items on-demand or transform other color
themes, e.g. provide a tint or duotone color effect on an existing theme.

When a color theme is dynamic, it must set the property C<dynamic> in the color
theme structure to true.

See also: L</static color theme>.

=head1 SPECIFICATION

=head2 Color theme class

A color theme class must be put in C<ColorTheme::> namespace.
Application-specific color themes should be put under
C<ColorTheme::MODULE::NAME::*> or C<ColorTheme::APP::NAME::*>.

The color theme class must declare a package hash variable named C<%THEME>
containing the L<color theme structure|/Color theme structure>. It also must
provide these methods:

=over

=item * new

Usage:

 my $ctheme_obj = ColorTheme::NAME->new([ %args ]);

Constructor. Known arguments will depend on the particular theme class and must
be specified in the color theme structure under the C<args> key.

=item * get_struct

Usage:

 my $ctheme_struct = ColorTheme::NAME->get_struct;
 my $ctheme_struct = $ctheme_obj->get_struct;

Provide a method way of getting the L</color theme structure>. Must also work as
a static method. A client can also access the C<%THEME> package variable
directly.

=item * get_args

Usage:

 my $args = $ctheme_obj->get_args;

Provide a method way of getting the arguments to the constructor. The official
implementation L<ColorThemeBase::Constructor> stores this in the 'args' key of
the hash object, but the proper way to access the arguments should be via this
method.

=item * list_items

Usage:

 my @item_names = $theme_class->list_items;
 my $item_names = $theme_class->list_items;

Must return list of item names provided by theq theme. Each item has a color
associated with it and the color can be retrieved using L</get_color>.

=item * get_item_color

Usage:

 my $color = $theme_class->get_item_color($item_name [ , \%args ]);

Get color for an item. See L<Item color>.

=back

=head2 Color theme structure

Color theme structure is a L<DefHash> containing these keys:

=over

=item * v

Required. Float. From DefHash. Must be set to 2 (this specification version).

=item * summary

String. Optional. From DefHash.

=item * description

String. Optional. From DefHash.

=item * args

Hash of argument names as keys, and argument specification DefHash as values.
The argument specification resembles that specified in L<Rinci::function>. Some
of the important or relevant properties: C<req>, C<schema>, C<default>.

=item * dynamic

Boolean, optional. Must be set to true if the theme class is dynamic, i.e. the
L</items> property does not contain all (or even any) of the items of the theme.
Client must call L</list_items> to list all the items in the theme.

=item * items

Required. Hash of item names as keys and item colors as values. See L</Item
color>.

=back

=head2 Item color

The color of an item can be one of three things.

First, the simplest, a single RGB value in the form of 6-hexdigit string, e.g.
C<ffcc00>.

Second, a DefHash called "item colors hash" containing one or more of these
properties: C<fg> (foreground RGB color), C<bg> (background RGB color),
C<ansi_fg> (foreground ANSI escape sequence string), C<ansi_bg> (background ANSI
escape sequence string). It can also contain additional information like
C<summary> (a summary describing the item), C<description>, C<tags>, and so on.
Properties like C<ansi_fg> and C<ansi_bg> are used to support specifying things
that are not representable by RGB, e.g. reverse or bold.

Third, a coderef which if called is expected to return one of the two formerly
mentioned value (RGB string or the "item colors hash"). A coderef cannot return
another coderef. Coderef will be called with arguments C<< ($self, $name,
\%args) >> where C<$self> is the color theme class (from which you can access
the color theme structure as well as arguments to the constructor), C<$name> is
the item name requested, and C<\%args> is hashref to additional, per-item
arguments.

Allowing coderef as color allows for flexibility, e.g. for doing gradation
border color, random color, context-sensitive color, etc.

=head1 HISTORY

L<Color::Theme> is an older specification, superseded by this document.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorTheme>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorTheme>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorTheme>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DefHash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
