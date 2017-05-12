package Color::Library::Color;

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/_id _name _title _dictionary /);
__PACKAGE__->mk_accessors(qw/_rgb _html _value _hex/);

use overload
    '""' => \&html,
    fallback => 1,
;

sub rgb;
sub rgb2hex;
sub rgb2value;
sub value2rgb($);
sub parse_rgb_color;
sub integer2rgb($);

=head1 NAME

Color::Library::Color - Color entry for a Color::Library color dictionary

=head1 METHODS 

=over 4

=item $id = $color->id 

Returns the id of the color

A color id is in the format of <dictionary_id:color_name>, e.g.

    svg:aliceblue
    x11:bisque2
    nbs-iscc-f:chromeyellow.66
    vaccc:darkspringyellow

=item $name = $color->name 

Returns the name of the color, e.g.

    aliceblue
    bisque2
    chromeyellow
    darkspringyellow

=item $title = $color->title 

Returns the title of the color, e.g.

    aliceblue
    bisque2
    chrome yellow
    Dark Spring-Yellow

=item $dictionary = $color->dictionary 

Returns the Color::Library::Dictionary object that the color belongs to

=item $hex = $color->hex 

Returns the hex value of the color, e.g.

    ff08ff
    eed5b7
    eaa221
    669900

Note that $hex does NOT include the leading #, for that use $color->html, $color->css, or $color->svg

=item $html = $color->html 

=item $css = $color->css 

=item $svg = $color->svg 

Returns the hex value of the color with a leading #, suitable for use in HTML, CSS, or SVG documents, e.g.

    #ff08ff
    #eed5b7
    #eaa221
    #669900

=cut

=item $value = $color->value 

Returns the numeric value of the color, e.g.

    15792383
    15652279
    15376929
    6723840

=cut

for my $method (qw/id name title dictionary html value hex/) {
    no strict 'refs';
    my $accessor = "_$method";
    *$method = sub { return $_[0]->$accessor };
}
*css = \&html;
*svg = \&html;

=item ($r, $g, $b) = $color->rgb 

Returns r, g, and b values of the color as a 3 element list (list context), e.g.

    (240, 248, 255)

=item $rgb = $color->rgb 

Returns r, g, and b values of the color in a 3 element array (scalar context), e.g.

    [ 240, 248, 255 ]

=cut

sub rgb {
    return wantarray ? @{ $_[0]->_rgb } : [ @{ $_[0]->_rgb } ]
}

=item $color = Color::Library::Color->new( id => $id, name => $name, title => $title, value => $value )

=item $color = Color::Library::Color->new( { id => $id, name => $name, title => $title, value => $value } )

=item $color = Color::Library::Color->new( [[ $id, $name, $title, $rgb, $hex, $value ]] )

Returns a new Color::Library::Color object representing the specified color

You probably don't want/need to call this yourself

=cut

# FUTURE Note that $value may be a numeric value, a hex value, or a 3 element r-g-b array

sub new {
    my $self = bless {}, shift;
    if (ref $_[0] eq "ARRAY") {
        my ($id, $name, $title, $rgb, $hex, $value) = @{ shift() };
        $self->_id($id);
        $self->_name($name);
        $self->_title($title);
        $self->_rgb($rgb);
        $self->_hex($hex);
        $self->_html("#" . $hex);
        $self->_value($value);
        $self->_dictionary(shift);
    }
    else {
        local %_ = ref $_[0] eq "HASH" ? %{ $_[0] } : @_;
        $self->_id($_{id});
        $self->_name($_{name});
        $self->_title($_{title});
        $self->_dictionary($_{dictionary});

        my ($r, $g, $b) = parse_rgb_color(ref $_{value} eq "ARRAY" ? @{ $_{value} } : $_{value});

        my $rgb = $self->_rgb([ $r, $g, $b ]);
        my $hex = $self->_hex(rgb2hex $rgb);
        $self->_html("#" . $hex);
        $self->_value(rgb2value $rgb);
    }
    return $self;
}

=back

=head2 FUNCTIONS

=over 4

=item $hex = Color::Library::Color::rgb2hex( $rgb )

=item $hex = Color::Library::Color::rgb2hex( $r, $g, $b )

Converts an rgb value to its hex representation

=cut

sub rgb2hex {
    return ref $_[0] eq "ARRAY" ? 
        sprintf("%02lx%02lx%02lx", $_[0][0], $_[0][1], $_[0][2]) :
        sprintf("%02lx%02lx%02lx", $_[0], $_[1], $_[2]);
}

=item $value = Color::Library::Color::rgb2value( $rgb )

=item $value = Color::Library::Color::rgb2value( $r, $g, $b )

Converts an rgb value to its numeric representation

=cut

sub rgb2value {
    my ($r, $g, $b) = ref $_[0] eq "ARRAY" ? @{ $_[0] } : @_;
    return $b + ($g << 8) + ($r << 16);
}

=item $rgb = Color::Library::Color::value2rgb( $value )

=item ($r, $g, $b) = Color::Library::Color::value2rgb( $value )

Converts a numeric color value to its rgb representation

=cut

sub value2rgb($) {
    my $value = shift;
    my ($r, $g, $b);
    $b = ($value & 0x0000ff);
    
    $g = ($value & 0x00ff00) >> 8;
    $r = ($value & 0xff0000) >> 16;
    return wantarray ? ($r, $g, $b) : [ $r, $g, $b ];
}

=item ($r, $g, $b) = Color::Library::Color::parse_rgb_color( $hex )

=item ($r, $g, $b) = Color::Library::Color::parse_rgb_color( $value )

Makes a best effort to convert a hex or numeric color value to its rgb representation

=cut

# Partly taken from Imager/Color.pm
sub parse_rgb_color {
    return (@_) if @_ == 3 && ! grep /[^\d.+eE-]/, @_;
    if ($_[0] =~ /^\#?([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])$/i) {
        return (hex($1), hex($2), hex($3));
    }
    if ($_[0] =~ /^\#?([\da-f])([\da-f])([\da-f])$/i) {
        return (hex($1) * 17, hex($2) * 17, hex($3) * 17);
    }
    return value2rgb $_[0] if 1 == @_ && $_[0] =~ m/^\d+$/;
}

1;

__END__

sub parse_rgbs_color {
    return (@_) if @_ == 3 && ! grep /[^\d.+eE-]/, @_;
    if ($_[0] =~ /^\#?([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])/i) {
        return (hex($1), hex($2), hex($3), hex($4));
    }
    if ($_[0] =~ /^\#?([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])/i) {
        return (hex($1), hex($2), hex($3), 255);
    }
    if ($_[0] =~ /^\#([\da-f])([\da-f])([\da-f])$/i) {
        return (hex($1) * 17, hex($2) * 17, hex($3) * 17, 255);
    }
    return value2rgb $_[0] if 1 == @_;
}
