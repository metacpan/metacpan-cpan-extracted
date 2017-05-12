package CSS::Adaptor::Whitelist;

use strict;
use CSS::Adaptor;
use parent 'CSS::Adaptor';

our $VERSION = '0.006';

sub log {
    my ($self, $msg) = @_;
    no strict 'refs';
    push @CSS::Adaptor::Whitelist::message_log, {
        timestamp => time,
        message => $msg,
    };
}

sub list2hash {
    return { map { $_ => 1 } @_ }
}

# this evaulates a string against a list of regular expressions
# like for the font or background properties
sub space_sep_res {
    my ($str, @res) = @_;
    while (@res) {
        my $re1 = shift @res;
        if ($str =~ /^$re1(.*)/) {
            my $rest = $1;
            if (length($rest) == 0) {
                return 1
            }
            elsif ($rest =~ s/^\s+//) {
                return space_sep_res($rest, @res)
            }
        }
    }
    return 0
}

# general
my $re_zero_to_one = qr/[01]\.?|0?\.\d+/;
my $re_percent = qr/(?: \d{1,2} \.? | \d{0,2} \. \d+ ) \%/x;
my $re_frac = qr/ \d* \. \d+ | \d+ \.? /x;
my $re_dim = qr/ $re_percent | (?:$re_frac) (?:p[ctx]|in|[cem]m|ex) \b | 0 \b /x;
my $re_ndim = qr/(?:-?$re_dim)/;
my $re_color_name = qr/(?i-xsm:\b(?:A(?:qua(?:marine)?|(?:liceBlu|ntiqueWhit|zur)e)|B(?:l(?:a(?:ck|nchedAlmond)|ue(?:Violet)?)|(?:eig|isqu)e|rown|urlyWood)|C(?:h(?:artreus|ocolat)e|or(?:n(?:flowerBlue|silk)|al)|adetBlue|(?:rimso|ya)n)|D(?:ark(?:G(?:r(?:ay|een)|oldenRod)|O(?:liveGreen|rchid)|S(?:late(?:Blue|Gray)|(?:almo|eaGree)n)|(?:Blu|orang|Turquois)e|Cyan|Khaki|Magenta|Red|Violet)|eep(?:Pink|SkyBlue)|imGray|odgerBlue)|F(?:ireBrick|loralWhite|orestGreen|uchsia)|G(?:old(?:enRod)?|r(?:een(?:Yellow)?|ay)|ainsboro|hostWhite)|Ho(?:neyDew|tPink)|I(?:ndi(?:anRed|go)|vory)|L(?:a(?:vender(?:Blush)?|wnGreen)|i(?:ght(?:C(?:oral|yan)|G(?:re(?:y|en)|oldenRodYellow)|S(?:(?:almo|eaGree)n|(?:ky|teel)Blue|lateGray)|Blue|Pink|Yellow)|me(?:Green)?|nen)|emonChiffon)|M(?:a(?:genta|roon)|edium(?:S(?:(?:ea|pring)Green|lateBlue)|(?:AquaMarin|Blu|Purpl|Turquois)e|(?:Orchi|VioletRe)d)|i(?:(?:dnightBlu|styRos)e|ntCream)|occasin)|Nav(?:ajoWhite|y)|O(?:l(?:ive(?:Drab)?|dLace)|r(?:ange(?:Red)?|chid))|P(?:a(?:le(?:G(?:oldenRod|reen)|Turquoise|VioletRed)|payaWhip)|e(?:achPuff|ru)|ink|lum|(?:owderBlu|urpl)e)|R(?:o(?:syBrown|yalBlue)|ed)|S(?:a(?:(?:ddle|ndy)Brow|lmo)n|ea(?:Green|Shell)|i(?:enna|lver)|late(?:Blue|Gray)|(?:ky|teel)Blue|now|pringGreen)|T(?:an|eal|(?:histl|urquois)e|omato)|Wh(?:ite(?:Smoke)?|eat)|Yellow(?:Green)?|Khaki|Violet)\b)/;
my $re_color = qr/(?:
      transparent \b
    | $re_color_name        # Blue
    | \#[\da-fA-F]{6} \b    # #FF00FF
    | \#[\da-fA-F]{3} \b    # #F0F
    | rgb\(  # rgb(255,0,255), rgb(255,0,255,0.3)
        (?: \d{1,3} | $re_percent ),
        (?: \d{1,3} | $re_percent ),
        (?: \d{1,3} | $re_percent )
        (?: , (?:$re_zero_to_one | $re_percent) )?
      \)
)/x;
my $re_url = qr{url\((?:http://[-\w+.]+/[-/\w.?%#]+)\)};
sub set_url_re {
    my ($new_re) = @_;
    if (ref($new_re) ne 'Regexp') {
        die 'set_url_re requires a compiled regular expression, e.g. qr/url(http:.*?)/'
    }
    else {
        $re_url = $new_re;
    }
}

# background
my $re_image = qr/(?:
      none \b
    | $re_url
)/x;
my $re_xy_pos = qr/(?:
    (?: left | center | right | $re_ndim ) \b
    (?: \s+
        (?: top | center | bottom | $re_ndim ) \b
    )?
)/x;
my $re_bg_attach = qr/(?:scroll\b|fixed\b)/;
my $re_bg_repeat = qr/(?:repeat(?:-[xy])?\b|no-repeat\b)/;

# border
my $re_border_width = qr/(?: thin\b | medium\b | thick\b | $re_dim )/x;
my $re_border_style = qr/(?: (?:none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset) \b )/x;
sub ck_border {
    space_sep_res(shift, $re_border_width, $re_border_style, $re_color)
}
my $re_border_radius = qr/(?: $re_dim ( \s+ $re_dim )? )/x;

# margin, padding
my $re_margin = qr/(?: auto \b | $re_ndim )/x;
my $re_margin_all = qr/(?: $re_margin ( \s+ $re_margin ){0,3} )/x;
my $re_padding_all = qr/(?: $re_ndim ( \s+ $re_ndim ){0,3} )/x;

# font
my $re_font_family = qr/(?: [-a-zA-Z0-9 ,"']+ \b )/x;  # maybe too generous, should we list possible families?
my $re_font_size = qr/(?: (?:x?x-)?(?:small|large)\b | small(?:er)? \b | larger? \b | medium \b | $re_dim )/x;
my $re_font_style = qr/(?: normal \b | oblique \b | italic \b )/x;
my $re_font_variant = qr/(?: normal \b | small-caps \b )/x;
my $re_font_weight = qr/(?: (?: normal | lighter | bold(?:er)? | \d{3} ) \b )/x;

# list style
my $re_list_style_position = qr/(?: (?:in|out)side \b )/x;
my $re_list_style_type = qr/(?: (?:
      none | circle | disc | square | armenian
    | decimal(?:-leading-zero)? | georgian | lower-greek | (?:lower|upper)-(?:alpha|latin|roman)
) \b )/x;

# various
my $re_cursor = qr/(?:
    (?: $re_url (?: \s*,\s* $re_url )* \s* , )?
    (?: auto | crosshair | default | help | move | pointer | progress | text | wait
        | (?:[news]|[ns][ew])-resize
    ) \b
)/x;

our %whitelist = (
    background => sub {
        space_sep_res(shift, $re_color, $re_image, $re_bg_repeat, $re_bg_attach, $re_xy_pos)
    },
    'background-color' => qr/^$re_color$/,
    'background-image' => qr/^$re_image$/,
    'background-position' => qr/^$re_xy_pos$/,
    'background-attachment' => qr/^$re_bg_attach$/,
    'background-repeat' => qr/^$re_bg_repeat$/,
    
    border => \&ck_border,
    'border-color'    => qr/^$re_color$/,
    'border-style'    => qr/^$re_border_style$/,
    'border-width'    => qr/^$re_border_width$/,
    'border-collapse' => list2hash(qw(collapse separate)),
    'border-spacing'  => qr/^ $re_dim (?: \s+ $re_dim )? $/x,
    'border-top' => \&ck_border,
    'border-top-color' => qr/^$re_color$/,
    'border-top-style' => qr/^$re_border_style$/,
    'border-top-width' => qr/^$re_border_width$/,
    'border-bottom' => \&ck_border,
    'border-bottom-color' => qr/^$re_color$/,
    'border-bottom-style' => qr/^$re_border_style$/,
    'border-bottom-width' => qr/^$re_border_width$/,
    'border-left' => \&ck_border,
    'border-left-color' => qr/^$re_color$/,
    'border-left-style' => qr/^$re_border_style$/,
    'border-left-width' => qr/^$re_border_width$/,
    'border-right' => \&ck_border,
    'border-right-color' => qr/^$re_color$/,
    'border-right-style' => qr/^$re_border_style$/,
    'border-right-width' => qr/^$re_border_width$/,
    '-webkit-border-radius' => qr/^$re_border_radius$/,
       '-moz-border-radius' => qr/^$re_border_radius$/,
         '-o-border-radius' => qr/^$re_border_radius$/,
            'border-radius' => qr/^$re_border_radius$/,
    
    outline => \&ck_border,
    'outline-color' => qr/^$re_color$/,
    'outline-style' => qr/^$re_border_style$/,
    'outline-width' => qr/^$re_border_width$/,
    
    margin => qr/^$re_margin_all$/x,
    'margin-top'    => qr/$re_margin$/,
    'margin-bottom' => qr/$re_margin$/,
    'margin-left'   => qr/$re_margin$/,
    'margin-right'  => qr/$re_margin$/,
    
    padding => qr/^$re_padding_all$/,
    'padding-top'    => qr/^$re_ndim$/,
    'padding-bottom' => qr/^$re_ndim$/,
    'padding-left'   => qr/^$re_ndim$/,
    'padding-right'  => qr/^$re_ndim$/,
    
    color => qr/^$re_color$/,
    font => sub {
        my $str = shift;
        return (
            list2hash(
                qw/caption icon menu message-box small-caption status-bar/
            )->{$str}
            ||
            space_sep_res(
                $str, $re_font_style, $re_font_variant, $re_font_weight, $re_font_size
            )
        )
    },
    'font-family'  => qr/^$re_font_family$/,
    'font-size'    => qr/^$re_font_size$/,
    'font-style'   => qr/^$re_font_style$/,
    'font-variant' => qr/^$re_font_variant$/,
    'font-weight'  => qr/^$re_font_weight$/,
    
    'list-style' => sub {
        space_sep_res(shift, $re_list_style_type, $re_list_style_position, $re_image)
    },
    'list-style-image' => qr/^$re_image$/,
    'list-style-type' => qr/^$re_list_style_type$/,
    'list-style-position' => qr/^$re_list_style_position$/,

    position => list2hash(qw/absolute fixed relative static/),
    top      => qr/^$re_ndim$/,
    bottom   => qr/^$re_ndim$/,
    left     => qr/^$re_ndim$/,
    right    => qr/^$re_ndim$/,
    
    display    => qr/^(?: (?:
          none | block | inline(?:-block|-table)? | list-item | run-in
        | table(?:- (:? caption | cell | (?:footer|header)-group | (?:column|row)(?:-group)? ) )?
    ) \b )$/x,
    visibility => list2hash(qw(visible hidden collapse)),
    overflow   => list2hash(qw(visible hidden scroll auto)),
    float      => list2hash(qw(left right none)),
    clear      => list2hash(qw(left right none both)),
    
    clip      => qr/^(?:auto\b|rect\(\s*$re_dim(?:\s*,\s*$re_dim){3}\s*\))$/,
    cursor    => qr/^$re_cursor$/,
    direction => list2hash(qw(ltr trl)),
    
    height => qr/^(?:auto\b|$re_ndim)$/,
    width  => qr/^(?:auto\b|$re_ndim)$/,
    'min-width'  => qr/^$re_ndim$/,
    'min-height' => qr/^$re_ndim$/,
    'max-width'  => qr/^$re_ndim$/,
    'max-height' => qr/^$re_ndim$/,
    'line-height' => qr/^(?:normal\b|$re_frac|$re_dim)$/,
    
    'text-align'      => list2hash(qw(left right center justify)),
    'text-decoration' => sub {
        my $str = shift;
        if ($str !~ /\S/) { return 0 }
        if ($str eq 'none') { return 1 }
        my %vals = %{ list2hash(qw(underline overline line-through blink)) };
        for (split /\s+/, $str) {
            if (not $vals{$_}) { return 0 }
        }
        return 1
    },
    'text-indent'     => qr/^$re_ndim$/,
    'text-shadow'     => qr/^ $re_ndim \s+ $re_ndim (?: \s+ $re_dim )? (?: \s+ $re_color )? $/x,
    'text-transform'  => list2hash(qw(none capitalize uppercase lowercase)),
    
    'letter-spacing' => qr/^(?:normal\b|$re_ndim)$/,
    'word-spacing'   => qr/^(?:normal\b|$re_ndim)$/,
    'caption-side'   => list2hash(qw(top bottom)),
    'empty-cells'    => list2hash(qw(hide show)),
    'table-layout'   => list2hash(qw(auto fixed)),
    'unicode-bidi'   => list2hash(qw(normal embed bidi-override)),
    'vertical-align' => qr/^(?: $re_ndim | baseline \b | middle \b | su(?:b|per) \b | (?:text-)?(?:top|bottom) \b )$/x,
    'white-space'    => list2hash(qw(normal nowrap pre pre-line pre-wrap)),
    'z-index'        => qr/^(?: auto \b | -?\d+ \b )$/x,
    
    orphans => qr/^\d+\b$/,
    widows  => qr/^\d+\b$/,
    'page-break-after'  => list2hash(qw(auto always avoid left right)),
    'page-break-before' => list2hash(qw(auto always avoid left right)),
    'page-break-inside' => list2hash(qw(auto avoid)),
);
sub value_ok {
    my ($value, $property) = @_;
    $value =~ s/\s+!important$//;
    if ($value eq 'inherit') { return 1 }
    my $w = $whitelist{ $property };
    if (ref $w eq 'Regexp') {
        return $value =~ $w
    }
    elsif (ref $w eq 'HASH') {
        return exists($w->{$value}) && $w->{$value}
    }
    elsif (ref $w eq 'CODE') {
        return $w->($value)
    }
    else {
        return 0
    }
}

sub output_rule {
    my ($self, $rule) = @_;
    my $s = $rule->selectors;
    return "$s {\n".$rule->properties."}\n";
}
sub output_properties {
    my ($self, $assignments) = @_;
    my @out;
    for my $assignment (@$assignments) {
        my $property = $assignment->{property};
        if ( $whitelist{$property} ) {
            my $values = $assignment->values;
            if (value_ok($values, $property)) {
                push @out, "    $property: $values;\n";
            }
            else {
                $self->log("filtered out value: $property: $values;");
            }
        }
        else {
            $self->log("filtered out property: $property;");
        }
    }
    return join '', @out;
}
sub output_values {
    my ($self, $values) = @_;
    my @out;
    for my $value (map $_->{value}, @$values) {
        push @out, $value
    }
    return join('', @out);
}

1

__END__

=head1 NAME

CSS::Adaptor::Whitelist -- filter out potentially dangerous CSS

=head1 SYNOPSIS

 use CSS
 use CSS::Adaptor::Whitelist;
 
 my $css = CSS->new({ adaptor => 'CSS::Adaptor::Whitelist' });
 $css->parse_string( <<EOCSS );
    body {
        margin: 0;
        background-image: url(javascript:alert("I am an evil hacker"));
    }
    #main {
        background-color: yellow;
        content-after: '<img src="http://example.com/xxx-rated-picture.jpg">';
    }
EOCSS
 
 print $css->output;
 # prints:
 # body {
 #     margin: 0;
 # }
 # #main {
 #     background-color: yellow;
 # }
 
 # allow the foo selector, but only with value "bar" or "baz"
 # 1) regex way
 $CSS::Adaptor::Whitelist::whitelist{foo} = qr/^ba[rz]$/;
 # 2) hash way
 $CSS::Adaptor::Whitelist::whitelist{foo} = {bar => 1, baz => 1};
 # 3) sub way
 $CSS::Adaptor::Whitelist::whitelist{foo} = sub {
    return ($_[0] eq 'bar' or $_[0] eq 'baz')
 }

=head1 DESCRIPTION

This is a subclass of CSS::Adaptor that paranoidly prunes anything from
the input CSS code that it doesn't recognize as standard.

It is intended as user-input CSS validation before letting it on your site.
The allowed CSS properties and corresponding values were mostly taken from
w3schools.com/css .

=head2 Whitelist

The allowed constructs are given in the C<%CSS::Adaptor::Whitelist::whitelist>
hash. The keys are the allowed selectors and the values can be 1) regular
expressions, 2) code refs and 3) hash refs.

Each CSS property is looked up in the whitelist. If it is not found, it is
discarded.

Each CSS value found is checked. If it passes the test,
then it is output in standard indentation, otherwise a message is passed to
the C<log> method.

In case of regexp, it is checked against the regexp. If it matches, the value
passes.

In case of subroutine, the value is passed as the only argument to it. If the
sub returns a true value, the CSS value passes.

In case of hash, if the CSS value is a key in the hash, that is associated with
a true value, then it passes.

=head2 Overriding defaults

You are invited to modify the rules, particularly the ones that allow URL's.
See C<set_url_re> for a convenient way.

Also the C<font-family> (and thus also C<font>) properties are quite generous.
Feel free to allow just a list of expected font families:

 $CSS::Adaptor::Whitelist::whitelist{'font-family'} = qr/^arial|verdana|...$/;

=head2 Functions

=over 4

=item list2hash

Simplifies giving values in the hash way. Returns hasref.

 list2hash('foo', 'bar', 'baz') # returns {foo => 1, bar => 1, baz => 1}

=item space_sep_res

 space_sep_res($string, $regex, $regex, ...) # returns 1 or 0

SPACE-SEParated Regular ExpresssionS. Given a string like C<1px solid #CCFF55>
and regular expressions for CSS dimension, border type and CSS color,
checks if the string matches piece by piece to these regexps.

Will fail if some of the regexp matches too small a chunk, for example:

 space_sep_res('solid #CCFF55', qr/solid|dotted/, qr/#[A-F\d]{3}|#[A-F\d]{6}/)

will return 0 because the latter regexp stops after matching <#CCF>.

Also beware that the regular expressions provided MUST NOT contain capturing
parentheses, otherwise the function will not work. Use C<(?: ... )> for
non-capturing parenthesising.

=item set_url_re

Sets the regular expression that URL's are checked against. Including the
C<url( )> wrapper. You are encouraged to use this method to provide a regexp
that will only allow URL's to domains you control:

 CSS::Adaptor::Whitelist::set_url_re(qr{url(https?://example\.com/[\w/]+)});

Notice that the regexp should not be anchored (no C<^> and C<$> at the edges).
It is being used in these properties:

 cursor
 background
 background-image
 list-style
 list-style-image

=item log

This is a method that stores messages of things being filtered out in
the C<@CSS::Adaptor::Whitelist::message_log> array.

You are encouraged to override or redefine this method to treat the log
messages in accordance with your logging habits.

=back

=head1 AUTHOR

Oldrich Kruza E<lt>sixtease@cpan.orgE<gt>

http://www.sixtease.net/

=head1 COPYRIGHT

Copyright (c) 2009 Oldrich Kruza. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
