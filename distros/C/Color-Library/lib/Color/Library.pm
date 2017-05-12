package Color::Library;
{
  $Color::Library::VERSION = '0.021';
}
# ABSTRACT: An easy-to-use and comprehensive named-color library

use warnings;
use strict;

use Module::Pluggable search_path => 'Color::Library::Dictionary', sub_name => '_load_dictionaries', require => 1;
use Color::Library::Dictionary;
__PACKAGE__->_load_dictionaries;

my %dictionary;
sub _register_dictionary {
    my $self = shift;
    my $dictionary = shift;
    $dictionary{$dictionary->id} = $dictionary;
}


sub dictionary {
    my $self = shift;
    return ($self->dictionaries(shift))[0];
}


sub dictionaries {
    my $self = shift;
    local @_ = keys %dictionary unless @_;
    @_ = map { Color::Library::Dictionary::_parse_id $_ } @_;
    if (wantarray) {
        return map { $_->_singleton } @dictionary{@_};
    }
    else {
        my %_dictionary;
        @_dictionary{@_} = map { $_->_singleton } @dictionary{@_};
        return \%_dictionary;
    }
}


# FUTURE Make this better
my @dictionary_search_order = (qw/svg x11 html ie mozilla netscape windows vaccc nbs-iscc/,
        map { "nbs-iscc-$_" } qw/a b f h m p r rc s sc tc/);

sub color {
    my $self = shift;

    my @colors;

    # Default dictionaries to search, in order
    my @dictionaries = @dictionary_search_order;

    # Can also pass in a default array of dictionary ids to search
    @dictionaries = @{ shift() } if ref $_[0] eq "ARRAY";

    my $query_;
    for my $query (@_) {
        $query_ = $query;
        my @dictionaries = @dictionaries;

        if ($query =~ m/:/) {
            # Looks like the query contains at least one dictionary id

            my ($dictionaries, $name) = split m/:/, $query, 2;
            unless (defined $name) {
                $name = $dictionaries;
                undef $dictionaries
            }
            @dictionaries = split m/,/, $dictionaries if defined $dictionaries;
            $query_ = $name;
        }

        my $color;
        for my $dictionary_id (@dictionaries) {
            next unless my $dictionary = $self->dictionary($dictionary_id);
            last if $color = $dictionary->color($query_);
        }
        push @colors, $color;
    }

    return wantarray ? @colors : $colors[0];
}
*colors = \&color;
*colour = \&color;
*colours = \&color;


1;

__END__
=pod

=head1 NAME

Color::Library - An easy-to-use and comprehensive named-color library

=head1 VERSION

version 0.021

=head1 SYNOPSIS

    use Color::Library;

    # Search for a sea blue color 
    my $seablue = Color::Library->color("seablue");

    # Search for a grey73 in the 'svg' and 'x11' dictionaries only
    my $grey73 = Color::Library->colour([qw/svg x11/] => "grey73");

    # Find a bunch of colors at the same time
    my ($red, $green, $blue) = Color::Library->colors(qw/red green blue/);

    # Fetch the named color "aliceblue" from the SVG dictionary
    my $color = Color::Library->SVG->color("aliceblue");

    # Prints out "aliceblue is #ff08ff"
    print $color->name, "is ", $color, "\n";

    # Get a list of names in the svg dictionary
    my @names = Color::Library->SVG->names;

    # Get a list of colors in the x11 dictionary
    my @colors = Color::Library->dictionary('x11')->colors;

=head1 DESCRIPTION

Color::Library is an easy-to-use and comprehensive named-color dictionary. Currently provides coverage for www (svg, html, css) colors, x11 colors, and more.

=head1 DICTIONARIES

The following dictionaries are available in this distribution:

    Color::Library::Dictionary::SVG - Colors from the SVG specification
    Color::Library::Dictionary::X11 - Colors for the X11 Window System (rgb.txt)
    Color::Library::Dictionary::HTML - Colors from the HTML 4.0 specification
    Color::Library::Dictionary::IE - Colors recognized by Internet Explorer
    Color::Library::Dictionary::Mozilla - Colors recognized by Mozilla (ColorNames.txt)
    Color::Library::Dictionary::Netscape - Colors recognized by Netscape
    Color::Library::Dictionary::Windows - Colors from the Windows system palette
    Color::Library::Dictionary::VACCC - VisiBone Anglo-Centric Color Code
    Color::Library::Dictionary::NBS_ISCC - Centroids of the NBS/ISCC catalog
    Color::Library::Dictionary::NBS_ISCC::A - Dye Colors
    Color::Library::Dictionary::NBS_ISCC::B - Colour Terminology in Biology
    Color::Library::Dictionary::NBS_ISCC::F - Colors; (for) Ready-Mixed Paints
    Color::Library::Dictionary::NBS_ISCC::H - Horticultural Colour Charts
    Color::Library::Dictionary::NBS_ISCC::M - Dictionary of Color
    Color::Library::Dictionary::NBS_ISCC::P - Plochere Color System
    Color::Library::Dictionary::NBS_ISCC::R - Color Standards and Color Nomenclature
    Color::Library::Dictionary::NBS_ISCC::RC - Rock-Color Chart
    Color::Library::Dictionary::NBS_ISCC::S - Postage-Stamp Color Names
    Color::Library::Dictionary::NBS_ISCC::SC - Soil Color Charts
    Color::Library::Dictionary::NBS_ISCC::TC - Standard Color Card of America

You can see a list of colors in any of these by reading their perldoc. For example:

    perldoc Color::Library::Dictionary::VACCC

If you have any suggestions for more color dictionaries to integrate, contact me.

=head1 METHODS

=over 4

=item $dictionary = Color::Library->dictionary( <dictionary_id> )

Returns a Color::Library::Dictionary object corresponding to <dictionary_id>

=item @dictionaries = Color::Library->dictionaries

=item @dictionaries = Color::Library->dictionaries( <dictionary_id>, <dictionary_id>, ... )

=item $dictionaries = Color::Library->dictionaries( <dictionary_id>, <dictionary_id>, ... )

In list context, returns a list of Color::Library::Dictionary objects (for each <dictionary_id> passed in

In scalar context, returns a hash of Color::Library::Dictionary objects mapping a dictionary id to a dictionary 

When called without arguments, the method will return all dictionaries

=item $color = Color::Library->color( <query> )

Returns a Color::Library::Color object found via <query>

A query can be any of the following:

=over 4

=item color name 

A color name is like C<blue> or C<bleached-almond>

=item color title

A color title is like C<Dark Green-Teal>

=item color id

A color id is in the form of <dictionary_id>:<color_name>, for example: C<x11:azure1>

=back

=item color( <query>, <query>, ... )

In list context, returns a list of Color::Library::Color objects corresponding to each <query>

In scalar context, just returns the first <query>

=item color( <dictionaries>, <query>, ... )

If an array reference is passed as the first argument, then this indicates that the array is a list of dictionary ids to search
through (in order):

    # Search in the svg and x11 dictionaries for a match
    my $blue = Color::Library->color([qw/svg x11/], "blue");
    
    # Will not find "aquamarine1" in the svg dictionary, so it will try the x11 dictionary
    my $aquamarine1 = Color::Library->color([qw/svg x11/], "aquamarine1");

=item $color = Color::Library->colors

=item $color = Color::Library->colour

=item $color = Color::Library->colours

All are aliases for the above color method

=back

=head1 ABOUT

This package was inspired by Graphics::ColorNames, and covers much of the same ground. However, I found the Graphics::ColorNames interface difficult to use. I also wanted to list colors directly in the perldoc, which this package does.

=head1 SEE ALSO

L<Graphics::ColorNames>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

