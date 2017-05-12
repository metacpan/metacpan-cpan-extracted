package Color::Theme::Role;

our $DATE = '2014-12-11'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use Moo::Role;

has color_theme_args  => (is => 'rw', default => sub { {} });
has _all_color_themes => (is => 'rw');

sub color_theme_module_prefix {
    my $self = shift;

    (ref($self) ? ref($self) : $self ) . '::ColorTheme';
}

sub color_theme {
    my $self = shift;

    if (!@_) { return $self->{color_theme} }
    my $ct = shift;

    my $p2 = "";
    if (!ref($ct)) {
        $p2 = " named $ct";
        $ct = $self->get_color_theme($ct);
    }

    my $err;
    if (!$ct->{no_color} && !$self->use_color) {
        $err = "color theme uses color but use_color is set to false";
    }
    die "Can't select color theme$p2: $err" if $err;

    $self->{color_theme} = $ct;
}

sub get_color_theme {
    my ($self, $ct) = @_;

    my $prefix = $self->color_theme_module_prefix;
    my $cts;
    my $pkg;
    if ($ct =~ s/(.+):://) {
        $pkg = "$prefix\::$1";
        my $pkgp = $pkg; $pkgp =~ s!::!/!g;
        require "$pkgp.pm";
        no strict 'refs';
        $cts = \%{"$pkg\::color_themes"};
    } else {
        #$cts = $self->list_color_themes(1);
        die "Please use SubPackage::name to choose color theme, ".
            "use list_color_themes() to list available themes";
    }
    $cts->{$ct} or die "Unknown color theme name '$ct'".
        ($pkg ? " in package $pkg" : "");
    ($cts->{$ct}{v} // 1.0) == 1.1 or die "Color theme '$ct' is too old ".
        "(v < 1.1)". ($pkg ? ", please upgrade $pkg" : "");
    $cts->{$ct};
}

sub get_theme_color {
    my ($self, $item_name) = @_;

    return undef if $self->{color_theme}{no_color};
    $self->{color_theme}{colors}{$item_name};
}

sub get_theme_color_as_rgb {
    my ($self, $item_name, $args) = @_;
    my $c = $self->get_theme_color($item_name);
    return undef unless defined($c);

    # resolve coderef color
    if (ref($c) eq 'CODE') {
        $args //= {};
        $c = $c->($self, %$args);
    }

    $c;
}

sub list_color_themes {
    require Module::List;
    require Module::Load;

    my ($self, $detail) = @_;

    my $prefix = $self->color_theme_module_prefix;
    my $all_ct = $self->_all_color_themes;

    if (!$all_ct) {
        my $mods = Module::List::list_modules("$prefix\::",
                                              {list_modules=>1, recurse=>1});
        no strict 'refs';
        $all_ct = {};
        for my $mod (sort keys %$mods) {
            #$log->tracef("Loading color theme module '%s' ...", $mod);
            Module::Load::load($mod);
            my $ct = \%{"$mod\::color_themes"};
            for (keys %$ct) {
                my $cutmod = $mod;
                $cutmod =~ s/^\Q$prefix\E:://;
                my $name = "$cutmod\::$_";
                $ct->{$_}{name} = $name;
                $all_ct->{$name} = $ct->{$_};
            }
        }
        $self->_all_color_themes($all_ct);
    }

    if ($detail) {
        return $all_ct;
    } else {
        return sort keys %$all_ct;
    }
}

1;
# ABSTRACT: Role for class wanting to support color themes

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Theme::Role - Role for class wanting to support color themes

=head1 VERSION

This document describes version 0.01 of Color::Theme::Role (from Perl distribution Color-Theme), released on 2014-12-11.

=head1 DESCRIPTION

This role is for class that wants to support color themes. Color theme is
represented as a structure according to the specification described in
L<Color::Theme>.

B<Color theme module.> Color themes are put in modules under
C<Color::Theme::Themes::> (configurable using C<color_theme_module_prefix>
attribute). Each color theme modules can contain one or more color themes. The
module must define a package global variable named C<%color_themes> that contain
color themes keyed by their names. Example:

 package MyProject::ColorThemes::Default;

 our %color_themes = (
     no_color => {
         v => 1.1,
         summary => 'Special theme that means no color',
         colors => {
         },
         no_color => 1,
     },

     default => {
         v => 1.1,
         summary => 'Default color theme',
         colors => {
         },
     },
 );

=head1 ATTRIBUTES

=head2 color_theme => HASH

Get/set color theme.

=head2 color_theme_args => HASH

Get/set arguments for color theme. This can be

=head2 color_theme_module_prefix => STR (default: CLASS + C<::ColorTheme::>)

Each project should have its own class prefix. For example, L<Text::ANSITable>
has its color themes in C<Text::ANSITable::ColorTheme::> namespace,
L<Data::Dump::Color> has them in C<Data::Dump::Color::ColorTheme::> and so on.

=head1 METHODS

=head2 $cl->list_color_themes($detail) => array

Will search packages under C<color_theme_module_prefix> for color theme modules,
then list all color themes for each module. If, for example, the color theme
modules found are C<MyProject::ColorTheme::Default> and
C<MyProject::ColorTheme::Extras>, will return something like:

 ['Default::theme1', 'Default::theme2', 'Extras::extra3', 'Extras::extra4']

=head2 $cl->get_color_theme($name) => hash

Get color theme hash data structure by name. Note that name must be prefixed by
color theme module name (minus the C<color_theme_module_prefix>).

=head2 $cl->get_theme_color($item_name) => str

Get an item's color value from the current color theme (will get from the color
theme's C<colors> hash, then the C<$item_name> key from that hash). If color
value is a coderef, it will be

=head2 $cl->get_theme_color_as_rgb($item_name, \%args) => str|hash

Like C<get_theme_color>, but if the resulting color value is a coderef, will
call that coderef, passing C<%args> to it and returning the value.

=head1 SEE ALSO

L<Color::Theme>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Color-Theme>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Color-Theme>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Color-Theme>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
