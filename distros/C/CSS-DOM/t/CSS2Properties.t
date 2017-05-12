#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
sub tests'import { $tests += pop if @_ > 1 };
use Test::More;
plan tests => $tests;

BEGIN {
our @props = qw /azimuth background background-attachment background-color background-image background-position background-repeat border border-bottom border-bottom-color border-bottom-style border-bottom-width border-collapse border-color border-left border-left-color border-left-style border-left-width border-right border-right-color border-right-style border-right-width border-spacing border-style border-top border-top-color border-top-style border-top-width border-width bottom caption-side clear clip color content counter-increment counter-reset cue cue-after cue-before cursor direction display elevation empty-cells float font font-family font-size font-size-adjust font-stretch font-style font-variant font-weight height left letter-spacing line-height list-style list-style-image list-style-position list-style-type margin margin-bottom margin-left margin-right margin-top marker-offset marks max-height max-width min-height min-width orphans outline outline-color outline-style outline-width overflow padding padding-bottom padding-left padding-right padding-top page page-break-after page-break-before page-break-inside pause pause-after pause-before pitch pitch-range play-during position quotes richness right size speak speak-header speak-numeral speak-punctuation speech-rate stress table-layout text-align text-decoration text-indent text-shadow text-transform top unicode-bidi vertical-align visibility voice-family volume white-space widows width word-spacing z-index/;
}

require CSS::DOM::Style;
my $decl = CSS::DOM::Style::parse
 ( join('', map"$_: 65;", our @props) );

use tests +4 * our @props; # normal CSS property methods
for (@props) {
	(my $meth = $_) =~ s/-(.)/\u$1/g;
	is $decl->$meth, '65', "get $meth";
	is $decl->$meth('right'), '65', "get/set $meth";
	is $decl->getPropertyValue($_), 'right',
		"result of setting $meth";
	is $decl->$meth, 'right', "get $meth again";
}

use tests 4; # cssFloat: the weird case
is $decl->cssFloat, 'right', "get cssFloat"; # it was set by the float meth
is $decl->cssFloat('left'), 'right', "get/set cssFloat";
is $decl->getPropertyValue('float'), 'left',
	"result of setting cssFloat";
is $decl->cssFloat, 'left', "get cssFloat again";

use tests 8; # assigning '', ' ', ' foo' (bug in 0.06)
is eval {$decl->cssFloat(''); 1}, 1,'empty string assignment doesn\'t die';
is $decl->cssFloat, '', 'empty string assignment works';
$decl->cssFloat('foo');
is eval {$decl->cssFloat(' '); 1},1,'whitespace assignment doesn\'t die';
is $decl->cssFloat, '', 'whitespace assignment works';
$decl->cssFloat('foo');
is eval{$decl->cssFloat('/*foo*/'); 1},1,'comment assignment doesn\'t die';
is $decl->cssFloat, '', 'comment assignment works';
is eval{$decl->cssFloat(' foo'); 1},1,'" foo" assignment doesn\'t die';
is $decl->cssFloat, ' foo', 'assignment with initial whitespace works';
