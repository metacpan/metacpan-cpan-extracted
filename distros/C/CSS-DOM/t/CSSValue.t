#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'qw regexp once utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::Value', ':all';

require CSS::DOM::Value::List;
require CSS::DOM::Value::Primitive;

use tests 4; # constants
{
	my $x;

	for (qw/ CSS_INHERIT CSS_PRIMITIVE_VALUE CSS_VALUE_LIST
	         CSS_CUSTOM /) {
		eval "is $_, " . $x++ . ", '$_'";
	}
}

use tests 2; # constructor & isa
isa_ok +CSS::DOM::Value->new(type => &CSS_INHERIT), 'CSS::DOM::Value';
isa_ok +CSS::DOM::Value->new(type => &CSS_CUSTOM, value => "top left"),
 'CSS::DOM::Value';


# --- cssText and cssValueType --- #

# Each subclass implements them itself, so I have to test each case. And I
# also have to make sure that getPropertyCSSValue produces the right
# thing, too.


require CSS::DOM::Style;
require CSS::DOM::PropertyParser;
my $s = new CSS'DOM'Style
 property_parser => my $spec = $CSS::DOM::PropertyParser::Default;

# The default parser has no properties with a simple string, attr or
# counter value. They all take a list. So we add a few just to make test-
# ing easier:
$spec->add_property(s => {
 format => '<string>',
});
$spec->add_property(a => {
 format => '<attr>',
});
$spec->add_property(c => {
 format => '<counter>',
});

# This runs 4 tests if the $property is specified and accepts $valstr.
# It runs 2 otherwise.
sub test_value {
	my($s,$property,$class,$args,$valstr,$type,$name) = @_;
	my $donefirst;
	$s->setProperty($property, $valstr) if $property;
	for my $val (
		"CSS::DOM::Value$class"->new( @$args ),
		$property ? $s->getPropertyCSSValue($property) : ()
	) {
		$name .= " (from getPCV)" x $donefirst++;
		is $val->cssText, $valstr, "$name ->cssText";
		is $val->cssValueType, $type,
			"$name ->cssValueType";
	}
}

use tests 8;
test_value $s,"top","", [type => &CSS_INHERIT], 'inherit', &CSS_INHERIT,
 'inherit';
test_value $s,"background-position", "",
 [type=>&CSS_CUSTOM,value=>"top left"],
 'top left', &CSS_CUSTOM, 'custom value';

use tests 130;
my $css_num = &CSS::DOM::Value::Primitive::CSS_NUMBER;
for( #constant   constructor val arg   prop       css str      test name
 [ number     =>  '73'              , 'z-index', '73'       , 'number'   ],
 [ percentage =>  '73'              , 'top'    , '73%'      , '%'        ],
 [ ems        =>  '73'              , 'top'    , '73em'     , 'em'       ],
 [ exs        =>  '73'              , 'top'    , '73ex'     , 'ex'       ],
 [ px         =>  '73'              , 'top'    , '73px'     , 'px'       ],
 [ cm         =>  '73'              , 'top'    , '73cm'     , 'cm'       ],
 [ mm         =>  '73'              , 'top'    , '73mm'     , 'mm'       ],
 [ in         =>  '73'              , 'top'    , '73in'     , 'inch'     ],
 [ pt         =>  '73'              , 'top'    , '73pt'     , 'point'    ],
 [ pc         =>  '73'              , 'top'    , '73pc'     , 'pica'     ],
 [ deg        =>  '73'              , 'azimuth', '73deg'    , 'degree'   ],
 [ rad        =>  '73'              , 'azimuth', '73rad'    , 'radian'   ],
 [ grad       =>  '73'              , 'azimuth', '73grad'   , 'grad'     ],
 [ s          =>  '73'              , 'pause-after', '73s'  , 'second'   ],
 [ ms         =>  '73'              , 'pause-after', '73ms' , 'ms'       ],
 [ Hz         =>  '73'              , 'pitch'  , '73Hz'     , 'hertz'    ],
 [ kHz        =>  '73'              , 'pitch'  , '73kHz'    , 'kHertz'   ],
 [ dimension  => ['73', 'wob'      ], ''       , '73wob'    , 'misc dim' ],
 [ string     =>  '73'              , 's'      , "'73'"     , 'string'   ],
 [ uri        =>  '73'              , 'cue-after', "url(73)", 'URI'      ],
 [ ident      =>  'red'             , 'color'  , "red"      , 'ident'    ],
 [ attr       =>  'red'             , 'a'      , "attr(red)", 'attr'     ],
 [ counter    => ['red'            ], 'c'    , 'counter(red)', 'counter' ],
 [ counter    => ['red',undef,'lower-roman'], 'c',
  'counter(red, lower-roman)',        'counter with style'],
 [ counter    => ['red','. '], 'c',
  "counters(red, '. ')",              'counters'],
 [ counter    => ['red','. ','upper-latin'], 'c',
  "counters(red, '. ', upper-latin)", 'counters with style'],
 [ rect      => [
              [type=>&CSS::DOM::Value::Primitive::CSS_PX,value=>1],
              [type=>&CSS::DOM::Value::Primitive::CSS_EMS,value=>2],
              [type=>&CSS::DOM::Value::Primitive::CSS_IDENT,value=>'auto'],
              [type=>&CSS::DOM::Value::Primitive::CSS_CM,value=>4],
   ],                         'clip', "rect(1px, 2em, auto, 4cm)", 'rect'],
 [ rgbcolor   =>  'red'             , 'color'  , 'red' , 'colour (ident)'],
 [ rgbcolor   =>  '#fff'            , 'color'  , '#fff', 'colour (#hhh)' ],
 [ rgbcolor   =>  '#abcdef'      , 'color', '#abcdef', 'colour (#hhhhhh)'],
 [ rgbcolor   => [
                  [type=>$css_num,value=>255],
                  [type=>$css_num,value=>0],
                  [type=>$css_num,value=>0]
                 ],             'color', 'rgb(255, 0, 0)', 'colour (rgb)'],
 [ rgbcolor  => [
                 [type=>$css_num,value=>255],
                 [type=>$css_num,value=>0],
                 [type=>$css_num,value=>0],
                 [type=>$css_num,value=>.5]
                ],       'color', 'rgba(255, 0, 0, 0.5)', 'colour (rgba)'],
 [ ident     => 'activeborder' , 'color', 'activeborder', 'system colour'],
) {
	test_value $s, $$_[2], "::Primitive",
		[
			type =>
			 &{\&{"CSS::DOM::Value::Primitive::CSS_\U$$_[0]"}},
			value => $$_[1],
		],
		$$_[3], &CSS_PRIMITIVE_VALUE, $$_[4]
}

use tests 20;
test_value $s,"counter-increment","::List", [
 separator => ' ', values => [
  [type => &CSS::DOM::Value::Primitive::CSS_IDENT, value => 'open-quote'],
  [type => &CSS::DOM::Value::Primitive::CSS_NUMBER, value => '8'],
 ]
], "open-quote 8", &CSS_VALUE_LIST, 'space-separated list';
test_value $s,"cursor","::List", [
 separator => ', ', values => [
  [type => &CSS::DOM::Value::Primitive::CSS_URI, value => 'frew'],
  [type => &CSS::DOM::Value::Primitive::CSS_IDENT, value => 'crosshair'],
 ]
], "url(frew), crosshair", &CSS_VALUE_LIST, 'comma-separated list';
test_value $s,"content","::List", [
 separator => ', ', values => [
  [type => &CSS::DOM::Value::Primitive::CSS_URI, value => 'cror'],
 ]
], "url(cror)", &CSS_VALUE_LIST, 'single-valued list';
test_value $s,"font-family","::List", [
 separator => ', ', values => [
  [type => &CSS::DOM::Value::Primitive::CSS_STRING, value => 'dat drin',
   css => 'dat drin'],
 ]
], "dat drin", &CSS_VALUE_LIST,
  'single-valued nominally comma-separated list';
test_value $s,"counter-reset","::List", [
 separator => ' ', values => []
], 'none', &CSS_VALUE_LIST,
  'empty list';

use tests 14; # writing cssText on inherit/custom values
{
 my $v = new CSS::DOM::Value type => &CSS_INHERIT;
 ok !eval{ $v->cssText('aaa'); 1 },
  'setting cssText on an unowned css value object dies';
 isa_ok $@, 'CSS::DOM::Exception', 'class of error after cssText dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  'and the right type of error, too (after cssText dies)';

 $v = new CSS::DOM::Value type => &CSS_INHERIT, owner => $s;
 ok !eval{ $v->cssText('aaa'); 1 },
  'setting cssText on a css value object with no property dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after cssText dies (val with no prop)';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  'and the right type of error, too (after cssText dies [val w/no prop])';

 $s->backgroundPosition('inherit');
 $v = $s->getPropertyCSSValue('background-position');
 $v->cssText('top left'); # We write it twice on purpose, to make sure the
 $v->cssText('top left');        # change in type did not discard  the
 is $s->backgroundPosition, 'top left',  # internal owner attribute.
  'value->cssText("top left") sets the owner CSS property';
 is $v->cssValueType, &CSS_CUSTOM, ' and the value type';
 is $v->cssText, 'top left', ' and the value object\'s own cssText';

 $s->backgroundColor('inherit');
 $v = $s->getPropertyCSSValue('background-color');
 $v->cssText('red');
 is $s->backgroundColor, 'red',
  'setting the cssText of an inherit value to a colour changes the prop';
 is $v->cssText, 'red',
  'setting the cssText of an inherit value changes the cssText thereof';
 is $v->cssValueType, &CSS_PRIMITIVE_VALUE,
  'value type after setting an inherit value to a colour';
 isa_ok $v, "CSS::DOM::Value::Primitive",
  'object class after setting an inherit value to a colour';

 $s->backgroundColor('inherit');
 my $called;
 $s->modification_handler(sub { ++$called });
 $s->getPropertyCSSValue('background-color')->cssText('red');
 is $called, 1,
  'modification_handler is called when a CSS::DOM::Value changes';
}
 
use tests 30; # writing cssText on ‘primitive’ values
{
 my $v = new CSS::DOM::Value::Primitive
  type => &CSS::DOM::Value::Primitive::CSS_NUMBER, value => 43;
 ok !eval{ $v->cssText('aaa'); 1 },
  'setting cssText on an unowned primitive value object dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after primitive->cssText dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  'and the right type of error, too (after primitive->cssText dies)';

 $s->backgroundImage('url(dwow)');
 $v = $s->getPropertyCSSValue('background-image');
 is $v->cssText('none'), 'url(dwow)',
  'setting cssText returns the old value';
 is $s->backgroundImage, 'none',
  'prim_value->cssText("...") sets the owner CSS property';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_IDENT,
  ' prim->cssText sets the “primitive” type';
 is $v->cssText, 'none',
  ' prim->cssText sets the value object\'s own cssText';

 # We re-use the same value on purpose, to make sure the change in type did
 # not discard the internal owner attribute.
 $v->cssText('inherit');
 is $s->backgroundImage, 'inherit',
  'setting the cssText of a primitive value to inherit changes the prop';
 is $v->cssText, 'inherit',
  'setting the cssText of a prim val to inherit changes its cssText';
 is $v->cssValueType, &CSS_INHERIT,
  'value type after setting a primitive value to inherit';
 isa_ok $v, "CSS::DOM::Value",
  'object class after setting a primitive value to inherit';

 $s->clip('rect(0,0,0,0)');
 $v = $s->getPropertyCSSValue('clip')->top;
 $v->cssText('red');
 is $v->cssText, 0,
  'setting cssText on a sub-value of a rect to a colour does nothing';
 $v->cssText(50);
 is $v->cssText, 0,
  'setting cssText on a rect’s sub-value to a non-zero num does nothing';
 $v->cssText('5px');
 is $v->cssText, '5px',
  'setting cssText on a sub-value of a rect to 5px works';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_PX,
  'setting cssText on a sub-value of a rect to 5px changes the prim type';
 like $s->clip, qr/^rect\(5px,\s*0,\s*0,\s*0\)\z/,
  'setting cssText on a sub-value of a rect changes the prop that owns it';
 $v->cssText('auto');
 is $v->cssText, 'auto', 'rect sub-values can be set to auto';
 $v->cssText('bdelp');
 is $v->cssText, 'auto', 'but not to any other identifier';

 $s->color('#c0ffee');
 $v = (my $clr = $s->getPropertyCSSValue('color'))->red;
 $v->cssText('red');
 is $v->cssText, 192,
  'setting cssText on a sub-value of a colour to a colour does nothing';
 $v->cssText('255');
 is $v->cssText, '255',
  'setting cssText on a sub-value of a colour to 255 works';
 is $clr->cssText, '#ffffee',
  'changing a colour’s sub-value sets the colour’s cssText';
 $v->cssText('50%');
 is $v->cssText, '50%',
  'setting cssText on a sub-value of a colour to 50% works';
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_PERCENTAGE,
  'changing the cssText of a colour’s sub-value changes the prim type';
 like $clr->cssText, qr/^rgb\(127.5,\s*255,\s*238\)\z/,
  'the colour’s cssText after making the subvalues mixed numbers & %’s';
 $v = $clr->alpha;
 $v->cssText('50%');
 is $v->cssText, 1,
  'alpha values ignore assignments of percentage values to cssText';
 $v->cssText(.5);
 is $v->cssText, .5,
  'but number assignments (to alpha values’ cssText) work';
 like $clr->cssText, qr/^rgba\(127.5,\s*255,\s*238,\s*0.5\)\z/,
  'the colour’s cssText after making the subvalues mixed numbers & %’s';

 $v = $s->getPropertyCSSValue('color');
 $v->cssText('activeborder');;
 is $v->primitiveType, &CSS::DOM::Value::Primitive::CSS_IDENT,
  'setting a colour property’s cssText to a sys. colour makes it an ident';

 $s->backgroundColor('red');
 my $called;
 $s->modification_handler(sub { ++$called });
 $s->getPropertyCSSValue('background-color')->cssText('white');
 is $called, 1,
  "modification_handler is called when a ‘primitive’ value changes";

 # Bug in 0.08 and 0.09:  non-void context causes cssText not to write
 # anything if the existing value is a string and there is no existing
 # serialisation recorded.
 $v = new CSS::DOM::Value::Primitive::
  type => &CSS::DOM::Value::Primitive::CSS_STRING,
  value => 'nin',
  owner => $s,
  property => 's',
 ;
 scalar $v->cssText("'squow'");
 is $v->cssText, "'squow'",
  'prim->cssText(...) in non-void cx sets the val if existing val is str'

 # ~~~ We also need a test for list sub-values retaining their owner attri-
 #     bute when they change type
}

use tests 10; # writing cssText on list values
{
 my $v = new CSS::DOM::Value::List values => [];
 ok !eval{ $v->cssText('aaa'); 1 },
  'setting cssText on an unowned css list value object dies';
 isa_ok $@,'CSS::DOM::Exception', 'class of error when list->cssText dies';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  'and the right type of error, too (after list->cssText dies)';

 $v = new CSS::DOM::Value::List values => [], owner => $s;
 ok !eval{ $v->cssText('aaa'); 1 },
  'setting cssText on a css value list object with no property dies';
 isa_ok $@, 'CSS::DOM::Exception',
  'class of error after cssText dies (val list with no prop)';
 cmp_ok $@, '==', &CSS::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR,
  'error code when cssText dies (val list w/no prop)';

 $s->fontFamily('ching');
 $v = $s->getPropertyCSSValue('font-family');
 $v->cssText('breck, chon');
 is $s->fontFamily, 'breck, chon',
  'setting the cssText of a value list changes the prop';
 is $v->cssText, 'breck, chon',
  'setting the cssText of a value list changes the cssText thereof';

 $v->[0]->cssText('phrext');
 is $v->cssText, 'phrext, chon',
  'setting the cssText of a list’s sub-value sets the cssText of the list';

 my $called;
 $s->modification_handler(sub { ++$called });
 $s->getPropertyCSSValue('font-family')->cssText('red');
 is $called, 1,
  'modification_handler is called when a CSS::DOM::Value::List changes';
}
