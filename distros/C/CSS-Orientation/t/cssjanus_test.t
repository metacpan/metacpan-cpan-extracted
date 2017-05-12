
use strict;
use warnings;

use CSS::Orientation qw( ChangeLeftToRightToLeft );

use Test::More
    tests => 102
;

# testBGPosition
is( ChangeLeftToRightToLeft( "background: url(/foo/bar.png) top left" ), "background: url(/foo/bar.png) top right" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar.png) top right" ), "background: url(/foo/bar.png) top left" );
is( ChangeLeftToRightToLeft( "background-position: top left" ), "background-position: top right" );
is( ChangeLeftToRightToLeft( "background-position: top right" ), "background-position: top left" );

# testBGPositionPercentage
is( ChangeLeftToRightToLeft( "background-position: 100% 40%" ), "background-position: 0% 40%" );
is( ChangeLeftToRightToLeft( "background-position: 0% 40%" ), "background-position: 100% 40%" );
is( ChangeLeftToRightToLeft( "background-position: 23% 0" ), "background-position: 77% 0" );
is( ChangeLeftToRightToLeft( "background-position: 23% auto" ), "background-position: 77% auto" );
is( ChangeLeftToRightToLeft( "background-position-x: 23%" ), "background-position-x: 77%" );
is( ChangeLeftToRightToLeft( "background-position-y: 23%" ), "background-position-y: 23%" );
is( ChangeLeftToRightToLeft( "background:url(../foo-bar_baz.2008.gif) no-repeat 75% 50%" ), "background:url(../foo-bar_baz.2008.gif) no-repeat 25% 50%" );
is( ChangeLeftToRightToLeft( ".test { background: 10% 20% } .test2 { background: 40% 30% }" ), ".test { background: 90% 20% } .test2 { background: 60% 30% }" );
is( ChangeLeftToRightToLeft( ".test { background: 0% 20% } .test2 { background: 40% 30% }" ), ".test { background: 100% 20% } .test2 { background: 60% 30% }" );

# testBorder
is( ChangeLeftToRightToLeft( "border-left: bar" ), "border-right: bar" );
is( ChangeLeftToRightToLeft( "border-right: bar" ), "border-left: bar" );

# testBorderRadiusNotation
is( ChangeLeftToRightToLeft( "border-radius: .25em 15px 0pt 0ex" ), "border-radius: 15px .25em 0ex 0pt" );
is( ChangeLeftToRightToLeft( "border-radius: 10px 15px 0px" ), "border-radius: 15px 10px 15px 0px" );
is( ChangeLeftToRightToLeft( "border-radius: 7px 8px" ), "border-radius: 8px 7px" );
is( ChangeLeftToRightToLeft( "border-radius: 5px" ), "border-radius: 5px" );

# testCSSProperty
is( ChangeLeftToRightToLeft( "alright: 10px" ), "alright: 10px" );
is( ChangeLeftToRightToLeft( "alleft: 10px" ), "alleft: 10px" );

# testCursor
is( ChangeLeftToRightToLeft( "cursor: e-resize" ), "cursor: w-resize" );
is( ChangeLeftToRightToLeft( "cursor: w-resize" ), "cursor: e-resize" );
is( ChangeLeftToRightToLeft( "cursor: se-resize" ), "cursor: sw-resize" );
is( ChangeLeftToRightToLeft( "cursor: sw-resize" ), "cursor: se-resize" );
is( ChangeLeftToRightToLeft( "cursor: ne-resize" ), "cursor: nw-resize" );
is( ChangeLeftToRightToLeft( "cursor: nw-resize" ), "cursor: ne-resize" );

# testDirection
is( ChangeLeftToRightToLeft( "direction: ltr" ), "direction: ltr" );
is( ChangeLeftToRightToLeft( "direction: rtl" ), "direction: rtl" );
is( ChangeLeftToRightToLeft( "input { direction: ltr }" ), "input { direction: ltr }" );
is( ChangeLeftToRightToLeft( "body { direction: ltr }" ), "body { direction: rtl }" );
is( ChangeLeftToRightToLeft( "body { padding: 10px; direction: ltr; }" ), "body { padding: 10px; direction: rtl; }" );
is( ChangeLeftToRightToLeft( "body { direction: ltr } .myClass { direction: ltr }" ), "body { direction: rtl } .myClass { direction: ltr }" );
is( ChangeLeftToRightToLeft( "body{\n direction: ltr\n}" ), "body{\n direction: rtl\n}" );

# testDirectionalClassnames
is( ChangeLeftToRightToLeft( ".column-left { float: left }" ), ".column-left { float: right }" );
is( ChangeLeftToRightToLeft( "#bright-light { float: left }" ), "#bright-light { float: right }" );
is( ChangeLeftToRightToLeft( "a.left:hover { float: left }" ), "a.left:hover { float: right }" );
is( ChangeLeftToRightToLeft( "#bright-left,\n.test-me { float: left }" ), "#bright-left,\n.test-me { float: right }" );
is( ChangeLeftToRightToLeft( "#bright-left,.test-me { float: left }" ), "#bright-left,.test-me { float: right }" );
is( ChangeLeftToRightToLeft( "div.leftpill, div.leftpillon {margin-right: 0 !important}" ), "div.leftpill, div.leftpillon {margin-left: 0 !important}" );
is( ChangeLeftToRightToLeft( "div.left > span.right+span.left { float: left }" ), "div.left > span.right+span.left { float: right }" );
is( ChangeLeftToRightToLeft( ".thisclass .left .myclass {background:#fff;}" ), ".thisclass .left .myclass {background:#fff;}" );
is( ChangeLeftToRightToLeft( ".thisclass .left .myclass #myid {background:#fff;}" ), ".thisclass .left .myclass #myid {background:#fff;}" );

# testDoubleDash
is( ChangeLeftToRightToLeft( "border-left-color: red" ), "border-right-color: red" );
is( ChangeLeftToRightToLeft( "border-right-color: red" ), "border-left-color: red" );

# testFloat
is( ChangeLeftToRightToLeft( "float: right" ), "float: left" );
is( ChangeLeftToRightToLeft( "float: left" ), "float: right" );

# testFourNotation
is( ChangeLeftToRightToLeft( "padding: .25em 15px 0pt 0ex" ), "padding: .25em 0ex 0pt 15px" );
is( ChangeLeftToRightToLeft( "margin: 1px -4px 3px 2px" ), "margin: 1px 2px 3px -4px" );
is( ChangeLeftToRightToLeft( "padding:0 15px .25em 0" ), "padding:0 0 .25em 15px" );
is( ChangeLeftToRightToLeft( "padding: 1px 4.1grad 3px 2%" ), "padding: 1px 2% 3px 4.1grad" );
is( ChangeLeftToRightToLeft( "padding: 1px 2px 3px auto" ), "padding: 1px auto 3px 2px" );
is( ChangeLeftToRightToLeft( "padding: 1px inherit 3px auto" ), "padding: 1px auto 3px inherit" );
is( ChangeLeftToRightToLeft( "#settings td p strong" ), "#settings td p strong" );

# testGradientNotation
is( ChangeLeftToRightToLeft( "background-image: -moz-linear-gradient(#326cc1, #234e8c)" ), "background-image: -moz-linear-gradient(#326cc1, #234e8c)" );
is( ChangeLeftToRightToLeft( "background-image: -webkit-gradient(linear, 100% 0%, 0% 0%, from(#666666), to(#ffffff))" ), "background-image: -webkit-gradient(linear, 100% 0%, 0% 0%, from(#666666), to(#ffffff))" );

# testLongLineWithMultipleDefs
is( ChangeLeftToRightToLeft( "body{direction:rtl;float:right}.b2{direction:ltr;float:right}" ), "body{direction:ltr;float:left}.b2{direction:ltr;float:left}" );

# testMargin
is( ChangeLeftToRightToLeft( "margin-left: bar" ), "margin-right: bar" );
is( ChangeLeftToRightToLeft( "margin-right: bar" ), "margin-left: bar" );

# testNoFlip
is( ChangeLeftToRightToLeft( "/* \@noflip */ div { float: left; }" ), "/* \@noflip */ div { float: left; }" );
is( ChangeLeftToRightToLeft( "/* \@noflip */ div, .notme { float: left; }" ), "/* \@noflip */ div, .notme { float: left; }" );
is( ChangeLeftToRightToLeft( "/* \@noflip */ div { float: left; } div { float: left; }" ), "/* \@noflip */ div { float: left; } div { float: right; }" );
is( ChangeLeftToRightToLeft( "/* \@noflip */\ndiv { float: left; }\ndiv { float: left; }" ), "/* \@noflip */\ndiv { float: left; }\ndiv { float: right; }" );
is( ChangeLeftToRightToLeft( "div { float: left; /* \@noflip */ float: left; }" ), "div { float: right; /* \@noflip */ float: left; }" );
is( ChangeLeftToRightToLeft( "div\n{ float: left;\n/* \@noflip */\n float: left;\n }" ), "div\n{ float: right;\n/* \@noflip */\n float: left;\n }" );
is( ChangeLeftToRightToLeft( "div\n{ float: left;\n/* \@noflip */\n text-align: left\n }" ), "div\n{ float: right;\n/* \@noflip */\n text-align: left\n }" );
is( ChangeLeftToRightToLeft( "div\n{ /* \@noflip */\ntext-align: left;\nfloat: left\n  }" ), "div\n{ /* \@noflip */\ntext-align: left;\nfloat: right\n  }" );
is( ChangeLeftToRightToLeft( "/* \@noflip */div{float:left;text-align:left;}div{float:left}" ), "/* \@noflip */div{float:left;text-align:left;}div{float:right}" );
is( ChangeLeftToRightToLeft( "/* \@noflip */div{float:left;text-align:left;}a{foo:left}" ), "/* \@noflip */div{float:left;text-align:left;}a{foo:right}" );

# testOneNotation
is( ChangeLeftToRightToLeft( "padding: 1px" ), "padding: 1px" );

# testPadding
is( ChangeLeftToRightToLeft( "padding-right: bar" ), "padding-left: bar" );
is( ChangeLeftToRightToLeft( "padding-left: bar" ), "padding-right: bar" );

# testPositionAbsoluteOrRelativeValues
is( ChangeLeftToRightToLeft( "left: 10px" ), "right: 10px" );

# testPreserveComments
is( ChangeLeftToRightToLeft( "/* left /* right */left: 10px" ), "/* left /* right */right: 10px" );
is( ChangeLeftToRightToLeft( "/*left*//*left*/left: 10px" ), "/*left*//*left*/right: 10px" );
is( ChangeLeftToRightToLeft( "/* Going right is cool */\n#test {left: 10px}" ), "/* Going right is cool */\n#test {right: 10px}" );
is( ChangeLeftToRightToLeft( "/* padding-right 1 2 3 4 */\n#test {left: 10px}\n/*right*/" ), "/* padding-right 1 2 3 4 */\n#test {right: 10px}\n/*right*/" );
is( ChangeLeftToRightToLeft( "/** Two line comment\n * left\n \*/\n#test {left: 10px}" ), "/** Two line comment\n * left\n \*/\n#test {right: 10px}" );

# testThreeNotation
is( ChangeLeftToRightToLeft( "margin: 1em 0 .25em" ), "margin: 1em 0 .25em" );
is( ChangeLeftToRightToLeft( "margin:-1.5em 0 -.75em" ), "margin:-1.5em 0 -.75em" );

# testTwoNotation
is( ChangeLeftToRightToLeft( "padding: 1px 2px" ), "padding: 1px 2px" );

# testUrlWithFlagOff
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-left.png)" ), "background: url(/foo/bar-left.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/left-bar.png)" ), "background: url(/foo/left-bar.png)" );
is( ChangeLeftToRightToLeft( "url(\"http://www.blogger.com/img/triangle_ltr.gif\")" ), "url(\"http://www.blogger.com/img/triangle_ltr.gif\")" );
is( ChangeLeftToRightToLeft( "url('http://www.blogger.com/img/triangle_ltr.gif')" ), "url('http://www.blogger.com/img/triangle_ltr.gif')" );
is( ChangeLeftToRightToLeft( "url('http://www.blogger.com/img/triangle_ltr.gif'  )" ), "url('http://www.blogger.com/img/triangle_ltr.gif'  )" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar.left.png)" ), "background: url(/foo/bar.left.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl.png)" ), "background: url(/foo/bar-rtl.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl.png); left: 10px" ), "background: url(/foo/bar-rtl.png); right: 10px" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-right.png); direction: ltr" ), "background: url(/foo/bar-right.png); direction: ltr" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl_right.png);left:10px; direction: ltr" ), "background: url(/foo/bar-rtl_right.png);right:10px; direction: ltr" );

# testUrlWithFlagOn
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-left.png)", 1, 1 ), "background: url(/foo/bar-right.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/left-bar.png)", 1, 1 ), "background: url(/foo/right-bar.png)" );
is( ChangeLeftToRightToLeft( "url(\"http://www.blogger.com/img/triangle_ltr.gif\")", 1, 1 ), "url(\"http://www.blogger.com/img/triangle_rtl.gif\")" );
is( ChangeLeftToRightToLeft( "url('http://www.blogger.com/img/triangle_ltr.gif')", 1, 1 ), "url('http://www.blogger.com/img/triangle_rtl.gif')" );
is( ChangeLeftToRightToLeft( "url('http://www.blogger.com/img/triangle_ltr.gif'  )", 1, 1 ), "url('http://www.blogger.com/img/triangle_rtl.gif'  )" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar.left.png)", 1, 1 ), "background: url(/foo/bar.right.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bright.png)", 1, 1 ), "background: url(/foo/bright.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl.png)", 1, 1 ), "background: url(/foo/bar-ltr.png)" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl.png); left: 10px", 1, 1 ), "background: url(/foo/bar-ltr.png); right: 10px" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-right.png); direction: ltr", 1, 1 ), "background: url(/foo/bar-left.png); direction: ltr" );
is( ChangeLeftToRightToLeft( "background: url(/foo/bar-rtl_right.png);left:10px; direction: ltr", 1, 1 ), "background: url(/foo/bar-ltr_left.png);right:10px; direction: ltr" );

