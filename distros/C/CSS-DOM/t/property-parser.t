#!/usr/bin/perl -Tw

use strict; use warnings; no warnings qw 'utf8 parenthesis regexp once qw';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

# --------------- Object API ---------------- #

use tests 1; # use
use_ok 'CSS::DOM::PropertyParser';

use tests 1; # constructor
isa_ok my $parser = CSS::DOM::PropertyParser->new, 
	'CSS::DOM::PropertyParser';

use tests 4; # clone
my $clone = (my $css21 = $CSS::DOM::PropertyParser::CSS21)->clone;
isn't $clone, $css21, 'clone at the first level';
isn't $clone->get_property('background-position'),
      $css21->get_property('background-position'),
 'clone clones individual property specs';
isn't
 $clone->get_property('border-color')->{properties}
  {'border-top-color'},
 $css21->get_property('border-color')->{properties}
  {'border-top-color'},
 'clone clones deeply';
is_deeply
 $clone->get_property('border-color')->{properties}
  {'border-top-color'},
 $css21->get_property('border-color')->{properties}
  {'border-top-color'},
 'the values within the clone are still identical';

use tests 3; # add/get/delete_property
$parser->add_property("foo", my $prop = {});
is $parser->get_property("foo"), $prop, 'add/get_property';
is $parser->delete_property("foo"), $prop, 'delete_property retval';
is $parser->get_property("foo"), undef, 'effect of delete_property';

use tests 1; # property_names
$parser->add_property($_,{}) for reverse "a".."f";
is_deeply [$parser->property_names], ["a".."f"], 'property_names';

# ------------------------- CSS::DOM::Style ------------------------ #

require CSS::DOM::Style;

use tests 2; # invalid properties in parsing
my $s = CSS::DOM::Style::parse(
 'azimuth: 0; azimuth: blue', property_parser => $css21
);
is $s->azimuth, '0',
 'invalid property values are ignored in parsing (CSS::DOM::Style::parse)';

$s->cssText('');
$s->cssText('azimuth: 0; azimuth: blue'),
is $s->azimuth, 0, 'style->cssText ignores invalid values';

# ------------------------- CSS 2.1 tests ------------------------ #

use tests 28; # azimuth
for(qw/ left-side far-left left center-left center center-right right
        far-right right-insidE behInd leftwards rightwards 0 0deg 80deg
        60rad 38grad -0 +0 -80deg +80deg inherit /,
    'left behind', 'behind center') {
 $s->azimuth($_);
 like $s->azimuth, qr/^\Q$_\E\z/i, "azimuth value: \L$_"
}
$s->azimuth('left');
for(qw/ 38 38cm upwards /, "center leftwards") {
 $s->azimuth($_);
 is $s->azimuth, 'left', "invalid azimuth value: $_";
}

use tests 3; # background-attachment
for(qw/ scroll fixed /) {
 $s->backgroundAttachment($_);
 is $s->backgroundAttachment, $_, "background-attachment value: \L$_"
}
$s->backgroundAttachment('38');
is $s->backgroundAttachment, 'fixed', "invalid bg-attachment value: 38";

use tests 197; # background-color
for(qw/ #abc #abcdef rgb(1,2,3) rgb(1%,2%,3%) rgba(1,2,3,4)
        rgba(1%,2%,3%,4) transparent Aliceblue antiquewhitE aqua
        aquamarine azure beige bisque black blanchedalmond blue blueviolet
        brown burlywood cadetblue chartreuse chocolate coral cornflowerblue
        cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray
        darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange
        darkorchid darkred darksalmon darkseagreen darkslateblue
        darkslategray darkslategrey darkturquoise darkviolet deeppink
        deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite
        forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray green
        greenyellow grey honeydew hotpink indianred indigo ivory khaki
        lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral
        lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey
        lightpink lightsalmon lightseagreen lightskyblue lightslategray
        lightslategrey lightsteelblue lightyellow lime limegreen linen
        magenta maroon mediumaquamarine mediumblue mediumorchid
        mediumpurple mediumseagreen mediumslateblue mediumspringgreen
        mediumturquoise mediumvioletred midnightblue mintcream mistyrose
        moccasin navajowhite navy oldlace olive olivedrab orange orangered
        orchid palegoldenrod palegreen paleturquoise palevioletred
        papayawhip peachpuff peru pink plum powderblue purple red rosybrown
        royalblue saddlebrown salmon sandybrown seagreen seashell sienna
        silver skyblue slateblue slategray slategrey snow springgreen
        steelblue tan teal thistle tomato turquoise violet wheat white
        whitesmoke yellow yellowgreen activeborder activecaption
        appworkspace background buttonface buttonhighlight buttonshadow
        buttontext captiontext graytext highlight highlighttext
        inactiveborder inactivecaption incativecaptiontext infobackground
        infotext menu menutext scrollbar threeddarkshadow threedface
        threedhighlight threedlightshadow threedshadow window windowframe
        windowtext rgb(-5%,-6%,-7%) rgb(+5%,+6%,+7%) rgb(-5,-6,-7)
        rgb(+5,+6,+7) rgba(-5%,-6%,-0%,-1) rgba(+5%,+6%,+7%,+5)
        rgba(-5,-6,-0,-1) rgba(+5,+6,+7,+5)/) {
 $s->backgroundColor($_);
 my $__ = $s->backgroundColor;
 for($__) {
  s/ //g if /,/;
 }
 is $__, $_, "background-color value: \L$_"
}
$s->backgroundColor('white');
for(qw/ #1234 #defghi rgb(1%,2,3) rgb(1,2,3,4) rgba(1%,2,3,4)
        rgba(1,2%,3%,4) SaladDressing /) {
 $s->backgroundColor($_);
 my $__ = $s->backgroundColor;
 for($__) {
  s/ //g if /,/;
 }
 is $__, 'white', "invalid bg-color value: $_";
}

use tests 3; # background-image
for(qw/ none url(foo) /) {
 $s->backgroundImage($_);
 is $s->backgroundImage, $_, "background-image value: \L$_"
}
$s->backgroundImage('38');
is $s->backgroundImage, 'url(foo)', "invalid bg-image value: 38";

use tests 57; # background-position
for('5%','-5%','+5%', '5% 5%', '5% 5px', '5% top', '5% bottom','5% center',
    '5% bottom', '5em', '5ex', '5px', '5in', '5cm', '5mm', '5pt', '5pc', 0,
    '-5px','-0','+0','+5px','5px 5%', '5px 5px', '5px top', '5px center',
    '5px bottom','left','left 5%','left 5px','left top','left center',
    'left bottom','center','center 5%','center 5px','center top',
    'center center','center bottom','right','right 5%','right 5px',
    'right top','right center','right bottom','top','top left',
    'top center','top right','center left','center right','bottom',
    'bottom left', 'bottom center', 'bottom right') {
 $s->backgroundPosition($_);
 is $s->backgroundPosition, $_, "background-position value: \L$_"
}
$s->backgroundPosition('left');
for("top bottom", "5% 5") {
 $s->backgroundPosition($_);
 is $s->backgroundPosition, 'left', "invalid bg-position value: $_";
}

use tests 6; # background-repeat
for(qw 'repeat repeat-x repeat-y no-repeat') {
 $s->backgroundRepeat($_);
 is $s-> backgroundRepeat, $_, "background-repeat value: \L$_"
}
$s-> backgroundRepeat('no-repeat');
for(qw "top 5") {
 $s-> backgroundRepeat($_);
 is $s-> backgroundRepeat, 'no-repeat', "invalid bg-repeat value: $_";
}

use tests 23; # background
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("background-$_"),
   qw(color image repeat attachment position)
 };
 $s->background('white');
 is $s->background, 'white', 'background: colour';
 is &$props, 'white,none,repeat,scroll,0% 0%',
  'other sub-properties after setting background to colour';
 is # bug fixed in 0.09, that only occurred in 5.10.0 [RT #54809]
   $s->getPropertyCSSValue('background-color')->cssValueType,
   1, # CSS_PRIMITIVE_VALUE
  'value types of named subprops of shorthand props after sh. assignment';
 $s->background('url(foo)');
 is $s->background, 'url(foo)', 'background: url';
 is &$props, 'transparent,url(foo),repeat,scroll,0% 0%',
  'other sub-properties after setting background to url';
 $s->background('no-repeat');
 is $s->background, 'no-repeat', 'background: repeat';
 is &$props, 'transparent,none,no-repeat,scroll,0% 0%',
  'other sub-properties after setting background to repeat';
 $s->background('fixed');
 is $s->background, 'fixed', 'background: attachment';
 is &$props, 'transparent,none,repeat,fixed,0% 0%',
  'other sub-properties after setting background to attachment';
 $s->background('top');
 is $s->background, 'top', 'background: position (single keyword)';
 is &$props, 'transparent,none,repeat,scroll,top',
  'other sub-properties after setting background to position (single)';
 $s->background('top left');
 is $s->background, 'top left', 'background: position (two words)';
 is &$props, 'transparent,none,repeat,scroll,top left',
  'other sub-properties after setting background to position';
 $s->background('red url("foo") no-repeat center center fixed');
 is $s->background, 'red url("foo") no-repeat fixed center center',
  'background with five values';
 is &$props, 'red,url("foo"),no-repeat,fixed,center center',
  'bg subprops after setting all at once';
 $s->background('bottom scroll repeat-y none #00f');
 is $s->background, '#00f repeat-y bottom',
  'background with five values in reverse order';
 is &$props, '#00f,none,repeat-y,scroll,bottom',
  'bg subprops after setting backwards';
 $s->background('');
 is $s->background, '', 'setting background to nothing ...';
 is &$props, ',,,,', ' ... resets all its sub-properties';
 $s->background('blue');
 $s->backgroundAttachment("");
 is $s->background, '',
  'background is blank if not all sub-properties are specified';
 $s->background('transparent none repeat scroll 0% 0%');
 is $s->background, 'none',
  'background is none when all sub-properties are set to initial values';
}
$s->background('red');
$s->background("top red left");
is $s->background, 'red', "invalid background value: top red left";
$s->background("0");
is $s->background, "0", 'setting background to 0';

use tests 3; # border-collapse
for(qw 'collapse separate') {
 $s->borderCollapse($_);
 is $s->borderCollapse, $_, "border-collapse value: \L$_"
}
$s->borderCollapse('collapse');
$s->borderCollapse('no-repeat');
is $s->borderCollapse, 'collapse', "invalid border-claps val: no-repeat";

use tests 15; # border-color
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("border-$_-color"),
   qw(top right bottom left)
 };

 $s->borderColor('red');
 is $s->borderColor, 'red', 'setting border-color to one value';
 is &$props, 'red,red,red,red',
  'result of setting border-color to one value';
 $s->borderColor('red green');
 is $s->borderColor, 'red green', 'setting border-color to two values';
 is &$props, 'red,green,red,green',
  'result of setting border-color to two values';
 $s->borderColor('red green blue');
 is $s->borderColor, 'red green blue',
  'setting border-color to three values';
 is &$props, 'red,green,blue,green',
  'result of setting border-color to three values';
 $s->borderColor('red green blue #f0f');
 is $s->borderColor, 'red green blue #f0f',
  'setting border-color to fourvalues';
 is &$props, 'red,green,blue,#f0f',
  'result of setting border-color to four values';
 $s->borderColor('red red blue #f0f');
 is $s->borderColor, 'red red blue #f0f',
  'setting border-color to four values, the 1st 2 the same';
 is &$props, 'red,red,blue,#f0f',
  'result of setting border-color to four values, the 1st 2 the same';
 $s->borderColor('rgb(255, 0, 0) rgb(0, 255, 0) rgb(0, 0, 255) rgb(0, 0, 0)');
 is $s->borderColor, 'rgb(255, 0, 0) rgb(0, 255, 0) rgb(0, 0, 255) rgb(0, 0, 0)', # bug in 0.08 (fixed in 0.09)
  'setting border-color to four rgb() values';  # that only affected
                                                     # cygwin perl

 $s->borderColor('');
 is $s->borderColor, '', 'setting border-color to nothing ...';
 is &$props, ',,,', ' ... resets all its sub-properties';
 $s->borderColor('blue');
 $s->borderTopColor("");
 is $s->borderColor, '',
  'borderColor is blank if not all sub-properties are specified';
}
$s->borderColor('red');
$s->borderColor("poiple");
is $s->borderColor, 'red', "invalid border-color value";

use tests 4; # border-spacing
for(0, '0cm', '5cm 4em') {
 $s->borderSpacing($_);
 is $s->borderSpacing, $_, "border-spacing value: \L$_"
}
$s->borderSpacing('0');
$s->borderSpacing('1');
is $s->borderSpacing, '0', "invalid border-spacing val";

use tests 29; # border-style
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("border-$_-style"),
   qw(top right bottom left)
 };

 $s->borderStyle('none');
 is $s->borderStyle, 'none', 'setting border-style to one value';
 is &$props, 'none,none,none,none',
  'result of setting border-style to one value';
 $s->borderStyle('hidden none');
 is $s->borderStyle, 'hidden none', 'setting border-style to two values';
 is &$props, 'hidden,none,hidden,none',
  'result of setting border-style to two values';
 $s->borderStyle('dotted hidden none');
 is $s->borderStyle, 'dotted hidden none',
  'setting border-style to three values';
 is &$props, 'dotted,hidden,none,hidden',
  'result of setting border-style to three values';

 $s->borderStyle('dashed dotted hidden none');
 is $s->borderStyle, 'dashed dotted hidden none',
  'setting border-style to four values: dashed dotted hidden none';
 is &$props, 'dashed,dotted,hidden,none',
  'result of setting border-style to dashed dotted hidden none';
 $s->borderStyle('solid dashed dotted hidden');
 is $s->borderStyle, 'solid dashed dotted hidden',
  'setting border-style to four values: solid dashed dotted hidden';
 is &$props, 'solid,dashed,dotted,hidden',
  'result of setting border-style to solid dashed dotted hidden';
 $s->borderStyle('double solid dashed dotted');
 is $s->borderStyle, 'double solid dashed dotted',
  'setting border-style to four values: double solid dashed dotted';
 is &$props, 'double,solid,dashed,dotted',
  'result of setting border-style to double solid dashed dotted';
 $s->borderStyle('groove double solid dashed');
 is $s->borderStyle, 'groove double solid dashed',
  'setting border-style to four values: groove double solid dashed';
 is &$props, 'groove,double,solid,dashed',
  'result of setting border-style to groove double solid dashed';
 $s->borderStyle('ridge groove double solid');
 is $s->borderStyle, 'ridge groove double solid',
  'setting border-style to four values: ridge groove double solid';
 is &$props, 'ridge,groove,double,solid',
  'result of setting border-style to ridge groove double solid';
 $s->borderStyle('inset ridge groove double');
 is $s->borderStyle, 'inset ridge groove double',
  'setting border-style to four values: inset ridge groove double';
 is &$props, 'inset,ridge,groove,double',
  'result of setting border-style to inset ridge groove double';
 $s->borderStyle('outset inset ridge groove');
 is $s->borderStyle, 'outset inset ridge groove',
  'setting border-style to four values: outset inset ridge groove';
 is &$props, 'outset,inset,ridge,groove',
  'result of setting border-style to outset inset ridge groove';
 $s->borderStyle('none outset inset ridge');
 is $s->borderStyle, 'none outset inset ridge',
  'setting border-style to four values: none outset inset ridge';
 is &$props, 'none,outset,inset,ridge',
  'result of setting border-style to none outset inset ridge';
 $s->borderStyle('none none outset inset');
 is $s->borderStyle, 'none none outset inset',
  'setting border-style to four values: none none outset inset';
 is &$props, 'none,none,outset,inset',
  'result of setting border-style to none none outset inset';
 $s->borderStyle('none none none outset');
 is $s->borderStyle, 'none none none outset',
  'setting border-style to four values: none none none outset';
 is &$props, 'none,none,none,outset',
  'result of setting border-style to none none none outset';

 $s->borderStyle('');
 is $s->borderStyle, '', 'setting border-style to nothing ...';
 is &$props, ',,,', ' ... resets all its sub-properties';
 $s->borderStyle('inset');
 $s->borderTopStyle("");
 is $s->borderStyle, '',
  'border-style is blank if not all sub-properties are specified';
}

use tests 40; # border-top/left/right/bottom
for my $side(qw/ top right left bottom /) {
 my $meth = "border\u$side";
 my $prop = "border-$side";
 my $props = sub {
  return join ",", map $s->getPropertyValue("$prop-$_"),
   qw(width style color)
 };
 $s->$meth('white');
 is $s->$meth, 'white', "$prop: colour";
 is &$props, 'medium,none,white',
  "other sub-properties after setting $prop to colour";
 $s->$meth('inset');
 is $s->$meth, '', "$prop: style";
 is &$props, 'medium,inset,',
  "other sub-properties after setting $prop to style";
 $s->$meth('thick');
 is $s->$meth, '', "$prop: weight";
 is &$props, 'thick,none,',
  "other sub-properties after setting $prop to a style value";
 $s->$meth('solid 1px red');
 is $s->$meth, '1px solid red',
  "$prop with three values";
 is &$props, '1px,solid,red',
  "$prop subprops after setting all at once";

 $s->$meth('');
 is $s->$meth, '', "setting $prop to nothing ...";
 is &$props, ',,', " ... resets all its sub-properties";
}

use tests 8; # border-*-color
for(qw/ top right bottom left /) {
 my $meth = "border\u${_}Color";
 $s->$meth('green');
 is $s->$meth, 'green', "border-$_-color";
 $s->$meth('bloo');
 is $s->$meth, 'green', "border-$_-color with invalid value";
}

use tests 40; # border-*-style
for(qw/ top right bottom left/) {
 my $meth = "border\u${_}Style";
 my $prop = "border-$_-style";
 for(qw/none hidden dotted dashed solid double groove ridge inset outset/){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 16; # border-*-width
for(qw/ top right bottom left/) {
 my $meth = "border\u${_}Width";
 my $prop = "border-$_-width";
 for(qw/5em thin thick medium/){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 19; # border-width
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("border-$_-width"),
   qw(top right bottom left)
 };

 $s->borderWidth('4em');
 is $s->borderWidth, '4em', 'setting border-width to one value';
 is &$props, '4em,4em,4em,4em',
  'result of setting border-width to one value';
 $s->borderWidth('thin 5em');
 is $s->borderWidth, 'thin 5em', 'setting border-width to two values';
 is &$props, 'thin,5em,thin,5em',
  'result of setting border-width to two values';
 $s->borderWidth('thick thin 5em');
 is $s->borderWidth, 'thick thin 5em',
  'setting border-width to three values';
 is &$props, 'thick,thin,5em,thin',
  'result of setting border-width to three values';

 $s->borderWidth('medium thick thin 5em');
 is $s->borderWidth, 'medium thick thin 5em',
  'setting border-width to four values: medium thick thin 5em';
 is &$props, 'medium,thick,thin,5em',
  'result of setting border-width to medium thick thin 5em';
 $s->borderWidth('0 medium thick thin');
 is $s->borderWidth, '0 medium thick thin',
  'setting border-width to four values: 0 medium thick thin';
 is &$props, '0,medium,thick,thin',
  'result of setting border-width to 0 medium thick thin';
 $s->borderWidth('1px 0 medium thick');
 is $s->borderWidth, '1px 0 medium thick',
  'setting border-width to four values: 1px 0 medium thick';
 is &$props, '1px,0,medium,thick',
  'result of setting border-width to 1px 0 medium thick';
 $s->borderWidth('2in 1px 0 medium');
 is $s->borderWidth, '2in 1px 0 medium',
  'setting border-width to four values: 2in 1px 0 medium';
 is &$props, '2in,1px,0,medium',
  'result of setting border-width to 2in 1px 0 medium';
 $s->borderWidth('0 0 0 5px');
 is $s->borderWidth, '0 0 0 5px',
  'setting border-width to four values: 0 0 0 5px';
 is &$props, '0,0,0,5px',
  'result of setting border-width to 0 0 0 5px';

 $s->borderWidth('');
 is $s->borderWidth, '', 'setting border-width to nothing ...';
 is &$props, ',,,', ' ... resets all its sub-properties';
 $s->borderWidth('medium');
 $s->borderTopWidth("");
 is $s->borderWidth, '',
  'border-width is blank if not all sub-properties are specified';
}

use tests 23; # border
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("border-$_"),
   map +("top-$_", "left-$_", "right-$_", "bottom-$_"),
   qw(width style color)
 };
 $s->border('white');
 is $s->border, 'white', "border: colour";
 is &$props, 'medium,'x4 .'none,none,none,none,white,white,white,white',
  "other sub-properties after setting border to a colour";

 for(qw( none hidden dotted dashed solid double groove ridge inset outset))
 {
  $s->border("$_");
  is &$props, 'medium,'x4 ."$_,"x4 .',,,',
   "setting border to $_";
 }

 for(qw( thin thick medium 5px))
 {
  $s->border("$_");
  is &$props, "$_,"x4 ."none,"x4 .',,,',
   "setting border to $_";
 }

 $s->border('solid 1px red');
 is $s->border, '1px solid red',
  "border with three values";
 is &$props, '1px,'x4 .'solid,'x4 .'red,red,red,red',
  "border subprops after setting all at once";

 $s->borderTopColor('green');
 is $s->border, '', 'border is blank when not all colour values are equal';
 $s->border('solid 1px red');
 $s->borderRightStyle('inset');
 is $s->border, '', 'border is blank when not all style values are equal';
 $s->border('solid 1px red');
 $s->borderBottomWidth('2px');
 is $s->border, '', 'border is blank when not all width values are equal';

 $s->border('');
 is $s->border, '', "setting border to nothing ...";
 is &$props, ',,,,,,,,,,,', " ... resets all its sub-properties"; 
}

use tests 3; # bottom
for(qw( 5em 5% auto )) {
 $s->bottom($_);
 is $s->bottom, $_, "bottom value: \L$_"
}

use tests 2; # caption-side
for(qw( top bottom )) {
 $s->captionSide($_);
 is $s->captionSide, $_, "caption-side value: \L$_"
}

use tests 4; # clear
for(qw( none left right both )) {
 $s->clear($_);
 is $s->clear, $_, "clear value: \L$_"
}

use tests 3; # clip
for('rect(0 auto 5px -7em)', 'rect(0, auto, 5px, -7em)', 'auto') {
 $s->clip($_);
 is $s->clip, $_, "clip value: \L$_"
}

use tests 2; # color
for('black', 'rgb(0, 0, 0)') {
 $s->color($_);
 is $s->color, $_, "color value: \L$_"
}

use tests 19; # content
for(qw/ normal none open-quote close-quote no-open-quote no-close-quote
        "foo" 'bar' url(foo) counter(foo)/,
    'counter(foo, disc)',
    'counters(foo, "bar")',
    'counters(foo, "bar", circle)',
    'attr(bexieiehehtett)',
    'normal none',
    'none open-quote close-quote',
    'open-quote close-quote no-open-quote no-close-quote',
    'close-quote no-open-quote no-close-quote "strine" url(url)',
    "no-open-quote no-close-quote 'oetd' url(eeudon\\)) counter(udux)"
      ." attr(x)",
) {
 $s->content($_);
 is $s->content, $_, "content value: \L$_"
}

use tests 10; # counter-increment and -reset
for my $prop('increment','reset') {
 my $meth = "counter\u$prop";
 for('tahi',
    'rua toru',
    'wha 4 rima 5',
    'ono whitu 7',
    'waru 8 iwa 9',
 ) {
  $s->$meth($_);
  is $s->$meth, $_, "counter-$prop value: \L$_"
 }
}

use tests 4; # cue-after and -before
for my $prop('after','before') {
 my $meth = "cue\u$prop";
 for(qw/ none url(foo) /) {
  $s->$meth($_);
  is $s->$meth, $_, "cue-$prop value: \L$_"
 }
}

use tests 9; # cue
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("cue-$_"),
   qw(before after)
 };

 $s->cue('url(po)');
 is $s->cue, 'url(po)', 'setting cue to one value';
 is &$props, 'url(po),url(po)',
  'result of setting cue to one value';
 $s->cue('none url(sto)');
 is $s->cue, 'none url(sto)', 'setting cue to two values';
 is &$props, 'none,url(sto)',
  'result of setting cue to two values';
 $s->cue('none none');
 is $s->cue, 'none', 'setting cue to none none';
 is &$props, 'none,none',
  'result of setting cue to none none';

 $s->cue('');
 is $s->cue, '', 'setting cue to nothing ...';
 is &$props, ',', ' ... resets all its sub-properties';
 $s->cue('none');
 $s->cueAfter("");
 is $s->cue, '',
  'cue is blank if not all sub-properties are specified';
}

use tests 17; # cursor
for('url(lous), auto',
    'url(os), crosshair',
    'url(exe), default',
    'url(eelthe), pointer',
    'url(oit), move',
    'url(ou), e-resize',
    'url(ampe), ne-resize',
    'url(lon), nw-resize',
    'url(ose), n-resize',
    'url(rgat), se-resize',
    'url(aike), sw-resize',
    'url(ryx), s-resize',
    'url(ate), w-resize',
    'url(tonte), text',
    'url(san), wait',
    'url(ast), help',
    'url(264), url(ech), progress',
) {
 $s->cursor($_);
 is $s->cursor, $_, "cursor value: \L$_"
}

use tests 2; # direction
for(qw/ ltr rtl /) {
 $s->direction($_);
 is $s->direction, $_, "direction value: \L$_"
}

use tests 16; # display
for(qw/ inline block list-item run-in inline-block table inline-table
        table-row-group table-header-group table-footer-group table-row
        table-column-group table-column table-cell table-caption none /) {
 $s->display($_);
 is $s->display, $_, "display value: \L$_"
}

use tests 6; # elevation
for(qw/ 70deg below level above higher lower /) {
 $s->elevation($_);
 is $s->elevation, $_, "elevation value: \L$_"
}

use tests 2; # empty-cells
for(qw/ show hide /) {
 $s->emptyCells($_);
 is $s->emptyCells, $_, "empty-cells value: \L$_"
}

use tests 3; # float
for(qw/ left right none /) {
 $s->float($_);
 is $s->float, $_, "float value: \L$_"
}

use tests 10; # font-family
for(qw/ serif sans-serif cursive fantasy monospace "Times" Times /,
    'Lucida Grande',
    'serif, sans-serif, Lucida Grande',
    'Lucida Grande, Times, fantasy',
) {
 $s->fontFamily($_);
 is $s->fontFamily, $_, "font-family value: \L$_"
}

use tests 11; # font-size
for(qw/ xx-small x-small small medium large x-large xx-large larger smaller
        5px 5% /) {
 $s->fontSize($_);
 is $s->fontSize, $_, "font-size value: \L$_"
}

use tests 2; # font-variant
for(qw/ normal small-caps /) {
 $s->fontVariant($_);
 is $s->fontVariant, $_, "font-variant value: \L$_"
}

use tests 13; # font-weight
for(qw/ normal bold bolder lighter 100 200 300 400 500 600 700 800 900 /) {
 $s->fontWeight($_);
 is $s->fontWeight, $_, "font-weight value: \L$_"
}

use tests 25; # font
{
 my $props = sub {
  return join ",", map $s->getPropertyValue($_),
   qw(
    font-style font-variant font-weight font-size line-height font-family
   )
 };
 $s->font('13px my font');
 is $s->font, '13px my font', "font: size typeface";
 is &$props, 'normal,normal,normal,13px,normal,my font',
  "other sub-properties after setting font to size/typeface";
 $s->font('italic medium medium');
 is $s->font, 'italic medium medium', "font: style size typeface";
 is &$props, 'italic,normal,normal,medium,normal,medium',
  "other sub-properties after setting font to style/size/typeface";
 $s->font('small-caps medium "quoted  font"');
 is $s->font, 'small-caps medium "quoted  font"',
  "font: variant size typeface";
 is &$props, 'normal,small-caps,normal,medium,normal,"quoted  font"',
  "other sub-properties after setting font to variant/size/typeface";
 $s->font('100 medium foo');
 is $s->font, '100 medium foo',
  "font: weight size typeface";
 is &$props, 'normal,normal,100,medium,normal,foo',
  "other sub-properties after setting font to weight/size/typeface";
 $s->font('medium/13px foo');
 is $s->font, 'medium/13px foo',
  "font: size/leading typeface";
 is &$props, 'normal,normal,normal,medium,13px,foo',
  "other sub-properties after setting font to size/leading/typeface";
 $s->font('normal bold italic 0 foo');
 is $s->font, 'italic bold 0 foo',
  "font with first three sub-props out of order and normal variant";
 is &$props, 'italic,normal,bold,0,normal,foo',
  "result of setting font with normal variant & props out of order";
 $s->font('small-caps normal 0 foo');
 is $s->font, 'small-caps 0 foo',
  "font with first 2/3 sub-props & explicit variant (normal applies to 2)";
 is &$props, 'normal,small-caps,normal,0,normal,foo',
  "result of setting font with small-caps normal";
 $s->font('bold italic small-caps 0/5px Times, serif');
 is $s->font, 'italic small-caps bold 0/5px Times, serif',
  "font with all sub props and comma in typeface";
 is &$props, 'italic,small-caps,bold,0,5px,Times, serif',
  "result of setting font with all sub-props";

 $s->font('caption');
 is &$props,
  'normal,normal,normal,13px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to caption";
 $s->font('');$s->font('icon');
 is &$props,
  'normal,normal,normal,13px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to icon";
 $s->font('');$s->font('menu');
 is &$props,
  'normal,normal,normal,13px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to menu";
 $s->font('');$s->font('message-box');
 is &$props,
  'normal,normal,normal,13px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to message-box";
 $s->font('');$s->font('small-caption');
 is &$props,
  'normal,normal,normal,11px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to small-caption";
 $s->font('');$s->font('status-bar');
 is &$props,
  'normal,normal,normal,10px,normal,Lucida Grande, sans-serif',
  "sub-props after setting font to status-bar";

 $s->lineHeight('');
 is $s->font, '', 'font is blank when not all sub-props are specified';

 $s->font('');
 is $s->font, '', "setting font to nothing ...";
 is &$props, ',,,,,', " ... resets all its sub-properties";
}

use tests 3; # height
for(qw( 5em 5% auto )) {
 $s->height($_);
 is $s->height, $_, "height value: \L$_"
}

use tests 3; # left
for(qw( 5em 5% auto )) {
 $s->left($_);
 is $s->left, $_, "left value: \L$_"
}

use tests 2; # letter-spacing
for(qw( 5em normal )) {
 $s->letterSpacing($_);
 is $s->letterSpacing, $_, "letter-spacing value: \L$_"
}

use tests 4; # line-height
for(qw( 5em 5% 5 normal )) {
 $s->lineHeight($_);
 is $s->lineHeight, $_, "line-height value: \L$_"
}

use tests 2; # list-style-image
for(qw/ none url(foo) /) {
  $s->listStyleImage($_);
  is $s->listStyleImage, $_, "list-style-image value: \L$_"
}

use tests 2; # list-style-position
for(qw/ inside outside /) {
  $s->listStylePosition($_);
  is $s->listStylePosition, $_, "list-style-position value: \L$_"
}

use tests 14; # list-style-type
for(qw/ disc circle square decimal decimal-leading-zero 
        lower-roman upper-roman lower-greek lower-latin 
        upper-latin armenian georgian lower-alpha 
        upper-alpha /) {
  $s->listStyleType($_);
  is $s->listStyleType, $_, "list-style-type value: \L$_"
}

use tests 11; # list-style
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("list-style-$_"),
   qw(type position image)
 };
 $s->listStyle('circle');
 is $s->listStyle, 'circle', "list-style: type";
 is &$props, 'circle,outside,none',
  "other sub-properties after setting list-style to type";
 $s->listStyle('inside');
 is $s->listStyle, 'inside', "list-style: position";
 is &$props, 'disc,inside,none',
  "other sub-properties after setting list-style to position";
 $s->listStyle('url(foo)');
 is $s->listStyle, 'url(foo)', "list-style: image";
 is &$props, 'disc,outside,url(foo)',
  "other sub-properties after setting list-style to an image url";
 $s->listStyle('inside url(oo) square');
 is $s->listStyle, 'square inside url(oo)',
  "list-style with three values";
 is &$props, 'square,inside,url(oo)',
  "list-style subprops after setting all at once";

 $s->listStyleType('');
 is $s->listStyle, '', 'list-style is blank if not all sub-props are set';

 $s->listStyle('');
 is $s->listStyle, '', "setting list-style to nothing ...";
 is &$props, ',,', " ... resets all its sub-properties";
}

use tests 12; # margin-*
for(qw/ top right bottom left/) {
 my $meth = "margin\u${_}";
 my $prop = "margin-$_";
 for(qw/5em 5% auto/){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 15; # margin
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("margin-$_"),
   qw(top right bottom left)
 };

 $s->margin('4em');
 is $s->margin, '4em', 'setting margin to one value';
 is &$props, '4em,4em,4em,4em',
  'result of setting margin to one value';
 $s->margin('5% 5em');
 is $s->margin, '5% 5em', 'setting margin to two values';
 is &$props, '5%,5em,5%,5em',
  'result of setting margin to two values';
 $s->margin('auto 5% 5em');
 is $s->margin, 'auto 5% 5em',
  'setting margin to three values';
 is &$props, 'auto,5%,5em,5%',
  'result of setting margin to three values';

 $s->margin('6em auto 5% 5em');
 is $s->margin, '6em auto 5% 5em',
  'setting margin to four values: 6em auto 5% 5em';
 is &$props, '6em,auto,5%,5em',
  'result of setting margin to 6em auto 5% 5em';
 $s->margin('6% 6em auto 5%');
 is $s->margin, '6% 6em auto 5%',
  'setting margin to four values: 6% 6em auto 5%';
 is &$props, '6%,6em,auto,5%',
  'result of setting margin to 6% 6em auto 5%';
 $s->margin('auto 6% 6em auto');
 is $s->margin, 'auto 6% 6em auto',
  'setting margin to four values: auto 6% 6em auto';
 is &$props, 'auto,6%,6em,auto',
  'result of setting margin to auto 6% 6em auto';

 $s->margin('');
 is $s->margin, '', 'setting margin to nothing ...';
 is &$props, ',,,', ' ... resets all its sub-properties';
 $s->margin('medium');
 $s->marginTop("");
 is $s->margin, '',
  'margin is blank if not all sub-properties are specified';
}

use tests 12; # min/max-width/height
for my $prop (qw/ max-height max-width min-height min-width /) {
 (my $meth = $prop) =~ s/-(.)/\u$1/g;
 for(qw/5em 5% none/){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 1; # orphans
$s->orphans(5);
is $s->orphans, 5, "orphans";

use tests 2; # outline-color
for(qw/green invert/){
  $s->outlineColor($_);
  is $s->outlineColor, $_, "setting outline-color to $_";
}

use tests 10; # outline-style
for(qw/ none hidden dotted dashed solid double groove ridge inset outset/){
  $s->outlineStyle($_);
  is $s->outlineStyle, $_, "setting outline-style to $_";
}

use tests 4; # outline-width
for(qw/ 3px thin thick medium /){
  $s->outlineWidth($_);
  is $s->outlineWidth, $_, "setting outline-width to $_";
}

use tests 11; # outline
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("outline-$_"),
   qw(color style width)
 };
 $s->outline('thick');
 is $s->outline, 'thick', "outline: weight";
 is &$props, 'invert,none,thick',
  "other sub-properties after setting outline to weight";
 $s->outline('inset');
 is $s->outline, 'inset', "outline: style";
 is &$props, 'invert,inset,medium',
  "other sub-properties after setting outline to style";
 $s->outline('white');
 is $s->outline, 'white', "outline: colour";
 is &$props, 'white,none,medium',
  "other sub-properties after setting outline to a colour";
 $s->outline('solid red 1px');
 is $s->outline, 'red solid 1px',
  "outline with three values";
 is &$props, 'red,solid,1px',
  "outline subprops after setting all at once";

 $s->outlineWidth('');
 is $s->outline,'', 'outline is blank if not all sub-props are set';

 $s->outline('');
 is $s->outline, '', "setting outline to nothing ...";
 is &$props, ',,', " ... resets all its sub-properties";
}

use tests 4; # overflow
for(qw/ visible hidden scroll auto /){
  $s->overflow($_);
  is $s->overflow, $_, "setting overflow to $_";
}

use tests 8; # padding-*
for(qw/ top right bottom left/) {
 my $meth = "padding\u${_}";
 my $prop = "padding-$_";
 for(qw/5em 5%/){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 13; # padding
{
 my $props = sub {
  return join ",", map $s->getPropertyValue("padding-$_"),
   qw(top right bottom left)
 };

 $s->padding('4em');
 is $s->padding, '4em', 'setting padding to one value';
 is &$props, '4em,4em,4em,4em',
  'result of setting padding to one value';
 $s->padding('5% 5em');
 is $s->padding, '5% 5em', 'setting padding to two values';
 is &$props, '5%,5em,5%,5em',
  'result of setting padding to two values';
 $s->padding('6px 5% 5em');
 is $s->padding, '6px 5% 5em',
  'setting padding to three values';
 is &$props, '6px,5%,5em,5%',
  'result of setting padding to three values';

 $s->padding('6% 6px 5% 5em');
 is $s->padding, '6% 6px 5% 5em',
  'setting padding to four values: 6% 6px 5% 5em';
 is &$props, '6%,6px,5%,5em',
  'result of setting padding to 6% 6px 5% 5em';
 $s->padding('6% 6px 5% 7%');
 is $s->padding, '6% 6px 5% 7%',
  'setting padding to four values: 6% 6px 5% 7%';
 is &$props, '6%,6px,5%,7%',
  'result of setting padding to 6% 6px 5% 7%';

 $s->padding('');
 is $s->padding, '', 'setting padding to nothing ...';
 is &$props, ',,,', ' ... resets all its sub-properties';
 $s->padding('medium');
 $s->paddingTop("");
 is $s->padding, '',
  'padding is blank if not all sub-properties are specified';
}

use tests 10; # page-break-before/after
for(qw/ before after/) {
 my $meth = "pageBreak\u${_}";
 my $prop = "page-break-$_";
 for(qw/auto always avoid left right/){
  $s->$meth($_);
  is $s->$meth, $_, "setting page-break-$prop to $_";
 }
}

use tests 2; # page-break-inside
for(qw/ avoid auto /){
  $s->pageBreakInside($_);
  is $s->pageBreakInside, $_, "setting page-break-inside to $_";
}

use tests 4; # pause-*
for(qw/ before after/) {
 my $meth = "pause\u${_}";
 my $prop = "pause-$_";
 for(qw/ 3s 3% /){
  $s->$meth($_);
  is $s->$meth, $_, "setting $prop to $_";
 }
}

use tests 1; # pitch-range
$s->pitchRange(5);
is $s->pitchRange, 5, "pitch-range";

use tests 10; # pitch
for(qw/ -0 +0 70hz 80khz +70hz x-low low medium high x-high /){
  $s->pitch($_);
  is $s->pitch, $_, "setting pitch to $_";
}

use tests 7; # play-during
for(
 'url(foo)',
 'url(bar) mix',
 'url(baz) repeat',
 'url(log) mix repeat',
 'url(ose) repeat mix',
 'auto',
 'none',
){
  $s->playDuring($_);
  is $s->playDuring, $_, "setting play-during to $_";
}

use tests 4; # position
for(qw/ static relative absolute fixed /){
  $s->position($_);
  is $s->position, $_, "setting position to $_";
}

use tests 4; # quotes
for(
 "'foo' 'bar'",
 "'‘' '’' '“' '”'",
 '"‘" "’" "“" "“" "«" "»"',
 'none',
){
  $s->quotes($_);
  is $s->quotes, $_, "setting quotes to $_";
}

use tests 1; # richness
$s->richness(5);
is $s->richness, 5, "richness";

use tests 3; # right
for(qw( 5em 5% auto )) {
 $s->right($_);
 is $s->right, $_, "right value: \L$_"
}

use tests 2; # speak-header
for(qw( once always )) {
 $s->speakHeader($_);
 is $s->speakHeader, $_, "speak-header value: \L$_"
}

use tests 2; # speak-numeral
for(qw( digits continuous )) {
 $s->speakNumeral($_);
 is $s->speakNumeral, $_, "speak-numeral value: \L$_"
}

use tests 2; # speak-punctuation
for(qw( code none )) {
 $s->speakPunctuation($_);
 is $s->speakPunctuation, $_, "speak-punctuation value: \L$_"
}

use tests 3; # speak
for(qw( normal none spell-out )) {
 $s->speak($_);
 is $s->speak, $_, "speak value: \L$_"
}

use tests 8; # speech-rate
for(qw( 3 x-slow slow medium fast x-fast faster slower )) {
 $s->speechRate($_);
 is $s->speechRate, $_, "speech-rate value: \L$_"
}

use tests 1; # stress
$s->stress(5);
is $s->stress, 5, "stress";

use tests 2; # table-layout
for(qw( auto fixed )) {
 $s->tableLayout($_);
 is $s->tableLayout, $_, "table-layout value: \L$_"
}

use tests 5; # text-align
for(qw( left right center justify auto )) {
 $s->textAlign($_);
 is $s->textAlign, $_, "text-align value: \L$_"
}

use tests 7; # text-decoration
for(
 "none",
 "underline",
 'overline',
 'line-through',
 'blink',
 'underline overline line-through blink',
 'overline blink underline line-through',
){
  $s->textDecoration($_);
  is $s->textDecoration, $_, "setting text-decoration to $_";
}

use tests 2; # text-indent
for(qw/5em 5%/){
  $s->textIndent($_);
  is $s->textIndent, $_, "setting text-indent to $_";
}

use tests 4; # text-transform
for(qw( capitalize uppercase lowercase none )) {
 $s->textTransform($_);
 is $s->textTransform, $_, "text-transform value: \L$_"
}

use tests 3; # top
for(qw/5em 5% auto/){
  $s->top($_);
  is $s->top, $_, "setting top to $_";
}

use tests 3; # unicode-bidi
for(qw/normal embed bidi-override/){
  $s->unicodeBidi($_);
  is $s->unicodeBidi, $_, "setting unicode-bidi to $_";
}

use tests 10; # vertical-align
for(qw/ baseline sub super top text-top middle bottom text-bottom 5% 5em/){
  $s->verticalAlign($_);
  is $s->verticalAlign, $_, "setting vertical-align to $_";
}

use tests 3; # visibility
for(qw/ visible hidden collapse /){
  $s->visibility($_);
  is $s->visibility, $_, "setting visibility to $_";
}

use tests 8; # voice-family
for(qw/ male female child "Times" Times /,
    'Lucida Grande',
    'male, female, Lucida Grande',
    'Lucida Grande, Times, child',
) {
 $s->voiceFamily($_);
 is $s->voiceFamily, $_, "voice-family value: \L$_"
}

use tests 10; # volume
for(qw/ soft medium 5% 5 silent x-soft soft medium loud x-loud /){
  $s->volume($_);
  is $s->volume, $_, "setting volume to $_";
}

use tests 1; # widows
$s->widows(5);
is $s->widows, 5, "widows";

use tests 3; # width
for(qw/5em 5% auto/){
  $s->width($_);
  is $s->width, $_, "setting width to $_";
}

use tests 2; # word-spacing
for(qw/ normal 51em /){
  $s->wordSpacing($_);
  is $s->wordSpacing, $_, "setting word-spacing to $_";
}

use tests 2; # z-index
for(qw/ auto 5 /){
  $s->zIndex($_);
  is $s->zIndex, $_, "setting z-index to $_";
}

# ------------- CSS::DOM’s part of the interface ---------- #

require CSS::DOM;

use tests 3;

my $sheet = CSS::DOM::parse(
 '* {azimuth: 0; azimuth: blue}', property_parser => $css21
);
is $sheet->cssRules->[0]->style->azimuth, '0',
 'CSS::DOM::parse ..., property_parser => ...';
is $sheet->property_parser, $css21, 'sheet->property_parser';

$sheet = new CSS::DOM property_parser => $css21;
$sheet -> insertRule('* {azimuth: 0; azimuth: blue}',0);
is $sheet->cssRules->[0]->style->azimuth, '0',
 'new CSS::DOM property_parser => ...';

# ------------- Miscellaneous Bug Fixes ------------- #

use tests 4;
{
 # Note: These fixes rely on border-top-color not having a default value.
 # That may change, in which case we will have to create our own property
 # specs for the tests’ sake.
 $s->cssText('border-top-color: white; border-top: inset');
 is $s->borderTopColor, "",
  'assignment to shorthand properties initiated by the parser deletes a'
   .' subproperty whose default value is blank';
 is +()=$s->getPropertyCSSValue("border-top-color"), 0,
  ' and that assignment causes getPropertyCSSValue to return nothing';
 $s->borderTopColor('white'); $s->borderTop('inset');
 is $s->borderTopColor, "",
  'direct assignment to shorthand properties deletes a'
   .' subproperty whose default value is blank';
 is +()=$s->getPropertyCSSValue("border-top-color"), 0,
  ' and *that* assignment causes getPropertyCSSValue to return nothing';
}

use tests 2; # parsing colours
{ # Tests for problems with colours in cygwin’s perl (broken in 0.08; fixed
  # in 0.09) and for bugs temporarily introduced while those problems were
  # being addressed.
 my $p = new CSS'DOM'PropertyParser;
 $p->add_property(
  'colours' => {
    format => '<colour>+',
   },
 );
 my $s = CSS'DOM'Style'parse(
  "colours: rgb(0,0,0) rgb(1,1,1)", 
   property_parser => $p
 );
 use CSS'DOM'Constants 'CSS_CUSTOM';
 is $s->getPropertyCSSValue('colours')->cssValueType, CSS_CUSTOM,
   'quantified <colour>s';
 $p->add_property(
  "agent" => {
    format => '(<identifier> <colour>)',
    properties => { "agent-name" => [1] }
   }
 );
 $s->agent("honey #bee");
 is $s->agentName, "honey #bee",
  '#colour within paren group and not at the start of the group';
}

use tests 1; # backtracking with list properties
{ # This bug,  fixed in 0.15,  was discovered as a result  of  perl  change
  # 3da9985538. See <http://rt.perl.org/rt3/Ticket/Display.html?id=114628>.
  # When I wrote  PropertyParser.pm,  I thought that  local @{$whatever}
  # would  localise  the  entire  contents  of  the  array,  just  as
  # local ${$whatever}[0]  localises one element.  But it  actually
  # replaces the array temporarily with a new one,  which cannot
  # work with references.
 my $p = new CSS'DOM'PropertyParser;
 $p->add_property(
  'foo' => {
    format => '[(foo)|(foo),]+', # [(foo),?]+ does not trigger the bug
    list   => 1,
   },
 );
 my $s = CSS'DOM'Style'parse(
  "foo: foo, foo", 
   property_parser => $p
 );
 use CSS'DOM'Constants 'CSS_VALUE_LIST';
 is_deeply [map cssText $_, @{$s->getPropertyCSSValue('foo')}],[('foo')x2],
   'backtracking does not preserve existing captures';
}
