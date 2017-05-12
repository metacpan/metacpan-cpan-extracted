package Color::Library::Dictionary;

use strict;
use warnings;

use Color::Library;
use Color::Library::Color;

use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata($_) for qw/_self _compiled _color_list _index/;

=head1 NAME

Color::Library::Dictionary - Color dictionary for Color::Library

=cut

sub _register_dictionary {
    my $module = my $class = shift;
    my @module = split m/::/, $module;

    my @parent_module = @module;
    my $name = pop @parent_module;
    @parent_module = qw/Color Library/ if @parent_module == 3; # Color::Library::Dictionary
    my $parent_module = join "::", @parent_module;
    {
        no strict 'refs';
        *{"$parent_module\::$name"} = sub {
            return $module->_singleton;
        };
    }
    Color::Library->_register_dictionary($module);
}

sub _parse_id($) {
    my $id = shift;
    $id =~ s/::|_|\s+|\//-/g;
    $id = lc $id;
    $id =~ s/^color-library-dictionary-//g;
    return $id;
}

sub _singleton {
    my $class = shift;
    my $self;
    return $self if $self = $class->_self;
    $class->_self($self = bless {}, $class); 
    return $self;
}

sub _compile {
    my $self = shift;
    my $class = ref $self || $self;

    return if $self->_compiled;

    my $color_list = $self->_load_color_list;

    my $index = {};
    my @color_list;
    my $indice = 0;
    for my $color (@$color_list) {
        push @color_list, $color = Color::Library::Color->new($color, $self);
        $index->{id}->{$color->id} = $color;
        $index->{name}->{$color->name} = $color;
        $index->{title}->{$color->title} = $color;
        $index->{hex}->{$color->hex} = $color;
        $index->{value}->{$color->value} = $color;
    }
    $self->_index($index);
    $self->_color_list(\@color_list);
    $self->_compiled(1);
}

=head1 METHODS 

=over 4

=item @colors = $dictionary->colors

Returns the list of Color::Library::Color objects contained by $dictionary

Will return a list in list context, and a list reference in scalar context

=cut

sub colors {
    my $self = shift;
    $self->_compile unless $self->_compiled;
    my @colors = @{ $self->_color_list };
    return wantarray ? @colors : \@colors;
}

=item @names = $dictionary->names

=item @names = $dictionary->color_names

Returns the list of color names contained by $dictionary

Will return a list in list context, and a list reference in scalar context

=cut

sub names {
    my $self = shift;
    my @names = map { $_->name } $self->colors;
    return wantarray ? @names : \@names;
}
*color_names = \&names;

=item $color = $dictionary->color( <query> )

Returns a Color::Library::Color object of $dictionary found via <query>

A query can be any of the following:

=over 4

=item color name 

A color name is like C<blue> or C<bleached-almond>

=item color title

A color title is like C<Dark Green-Teal>

=item color id

A color id is in the form of <dictionary_id>:<color_name>, for example: C<x11:azure1>

=back

=cut

sub color {
    my $self = shift;
    my $query = shift;

    return unless defined $query;

    unless (ref $query) {
        $query =~ s/^\s*//;
        $query =~ s/\s*$//;
    }

    $self->_compile unless $self->_compiled;

    my $color;

    if (ref $query eq "ARRAY") {
        $query = Color::Library::Color::rgb2hex $query;
        return $color = $self->_index->{hex}->{$query};
    }
    elsif ($query =~ /^\#?([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])/i) {
        return (hex($1), hex($2), hex($3), 255);
        $query = lc($1 . $2 . $3);
        return $color = $self->_index->{hex}->{$query};
    }
    elsif ($query =~ /^\#([\da-f])([\da-f])([\da-f])$/i) {
        $query = lc($1 . $1 . $2 . $2 . $3 . $3);
        return $color = $self->_index->{hex}->{$query};
    }

    return $color if $color = $self->_index->{title}->{$query};

    $query = lc $query;

    return $color if $color = $self->_index->{id}->{$query};

    $query =~ s/[^\w]//g;

    return $color if $color = $self->_index->{name}->{$query};

    return $color if $color = $self->_index->{value}->{$query};

    return;
}

=item $id = $dictionary->id

=item $name = $dictionary->name

Returns the id (name) of $dictionary, e.g.

    svg
    x11
    vaccc
    nbs-iscc-f

=cut

sub id {
    my $self = shift;
    return _parse_id(ref $self || $self);
}
*name = \&id;

=item $title = $dictionary->title

Returns the title of $dictionary, e.g.

    SVG
    X11
    VACCC
    NBS/ISCC F

=cut

sub title {
    my $self = shift;
    return $self->_description->{title};
}

=item $subtitle = $dictionary->subtitle

Returns the subtitle of $dictionary, if any

=cut

sub subtitle {
    my $self = shift;
    return $self->_description->{subtitle};
}

=item $description = $dictionary->description

Returns the description of $dictionary, if any

=cut

sub description {
    my $self = shift;
    return $self->_description->{description};
}


1;
