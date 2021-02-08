#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use CSS::Minifier::XS qw(minify);

###############################################################################
# Removal of leading whitespace, regardless of "space", "tab", "CR", "LF".
subtest 'leading whitespace can be removed' => sub {
  my $given  = "\n\n\r\t\n    \n    h1 { }";
  my $expect = 'h1{}';
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# Removal of trailing whitespace, regardless of "space", "tab", "CR", "LF".
subtest 'trailing whitespace can be removed' => sub {
  my $given  = "h1 { }  \t\n\r\n";
  my $expect = 'h1{}';
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# Whitespace that trails a ")" may be preserved.
subtest 'whitespace trailing a ")"' => sub {
  subtest 'end of statement; removed' => sub {
    my $given  = 'div { background: url(foo.gif) ; }';
    my $expect = 'div{background:url(foo.gif)}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'inside of statement; preserved' => sub {
    my $given  = 'div { background: url(foo.gif) no-repeat; }';
    my $expect = 'div{background:url(foo.gif) no-repeat}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# Removal of trailing semi-colons, at end of a group.
subtest 'trailing semi-colons' => sub {
  subtest 'at end of group; removed' => sub {
    my $given  = 'h1 { font-weight: bold; }';
    my $expect = 'h1{font-weight:bold}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'inside of group; preserved' => sub {
    my $given  = 'h1 { font-weight: bold; color: red;}';
    my $expect = 'h1{font-weight:bold;color:red}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# Comments get minified and removed, UNLESS they contain the word
# "copyright" in them.
subtest 'comments' => sub {
  subtest 'block comment removed' => sub {
    my $given  = '/* comment */ h1 { background: green }';
    my $expect = 'h1{background:green}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'copyright comment remains' => sub {
    my $given  = '/* comment with copyright */ h1 { color: red }';
    my $expect = '/* comment with copyright */h1{color:red}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'copyright is case in-sensitive' => sub {
    my $given  = '/* comment with CoPyRiGhT */ h1 { color: red }';
    my $expect = '/* comment with CoPyRiGhT */h1{color:red}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# Comments with the "Mac/IE Comment Hack" are preserved, but minified.
subtest 'mac/ie comment hack' => sub {
  subtest 'comment hack is minified' => sub {
    my $given  = '/* start \*/ ul { color: red } /* end */';
    my $expect = '/*\*/ul{color:red}/**/';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'inner hacks are removed' => sub {
    my $given  = '/* start \*/ ul { /* inner \*/ color: red } /* end */';
    my $expect = '/*\*/ul{color:red}/**/';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "!important" declarations can have preceeding whitespace removed.
subtest '!important' => sub {
  my $given  = 'a { box-shadow: none !important; }';
  my $expect = 'a{box-shadow:none!important}';
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# CSS Selector Combinators get whitespace removed
subtest 'css selector combinators' => sub {
  subtest 'child-of' => sub {
    my $given  = 'h1 > p { background: green }';
    my $expect = 'h1>p{background:green}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'adjacent-sibling' => sub {
    # adjacent siblings don't get whitespace removed, as the "+" could also
    # be seen as a mathematical operator
    my $given  = 'h1 + p { background: green }';
    my $expect = 'h1 + p{background:green}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'general-sibling' => sub {
    my $given  = 'h1 ~ p { background: green }';
    my $expect = 'h1~p{background:green}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# CSS pseudo-selectors get leading whitespace preserved
# - which (unfortunately) means that "whitespace before a ':' is significant",
#   as otherwise we need to truly understand the context that we are in when
#   we see a ":" to determine if we can eliminate the whitespace or not
subtest 'pseudo-selectors' => sub {
  my $given  = '#test :link { color: red; }';
  my $expect = '#test :link{color:red}';
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# Media selectors require "(" to retain leading whitespace, which is
# minified.
subtest 'media selectors' => sub {
  subtest 'whitespace is preserved' => sub {
    my $given  = '@media all and (max-width: 100px) { }';
    my $expect = '@media all and (max-width:100px){}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'whitespace is minified' => sub {
    my $given  = '@media all and       (max-width: 100px) { }';
    my $expect = '@media all and (max-width:100px){}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "zero" can be expressed without a unit, in *MOST* cases.
subtest 'zero without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 0px }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: 0 }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations
  subtest 'percent' => sub {
    my $given  = 'p { width: 0% }';
    my $expect = 'p{width:0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 0px) }';
    my $expect = 'p{width:calc(300px - 0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "point zero" can be expressed without a unit, in *MOST* cases.
subtest 'point-zero without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: .0px }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: .0 }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations,
  # but will be minified from "point-zero" to just "zero".
  subtest 'percent' => sub {
    my $given  = 'p { width: .0% }';
    my $expect = 'p{width:0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - .0px) }';
    my $expect = 'p{width:calc(300px - 0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "point zero something" requires preservation
subtest 'point-zero without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: .001px }';
    my $expect = 'p{width:.001px}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: .001 }';
    my $expect = 'p{width:.001}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations
  subtest 'percent' => sub {
    my $given  = 'p { width: .001% }';
    my $expect = 'p{width:.001%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - .001px) }';
    my $expect = 'p{width:calc(300px - .001px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "something point zero" requires preservation of the unit
subtest 'something-point-zero preserves units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 1.0px }';
    my $expect = 'p{width:1.0px}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations
  subtest 'percent' => sub {
    my $given  = 'p { width: 1.0% }';
    my $expect = 'p{width:1.0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 1.0px) }';
    my $expect = 'p{width:calc(300px - 1.0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "zero point zero" can be expressed without a unit, in *MOST* cases.
subtest 'zero-point-zero without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 0.0px }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: 0.0 }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations,
  # but will be minified from "zero-point-zero" to just "zero".
  subtest 'percent' => sub {
    my $given  = 'p { width: 0.0% }';
    my $expect = 'p{width:0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 0.0px) }';
    my $expect = 'p{width:calc(300px - 0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "zero point zero somethihg" requires preservation
subtest 'zero-point-zero without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 0.001px }';
    my $expect = 'p{width:.001px}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: 0.001 }';
    my $expect = 'p{width:.001}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations,
  # but will be minified from "zero-point-zero-something" to just
  # "point-zero-something"
  subtest 'percent' => sub {
    my $given  = 'p { width: 0.001% }';
    my $expect = 'p{width:.001%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 0.001px) }';
    my $expect = 'p{width:calc(300px - .001px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "zerooooooo" can be expressed without a unit, in *MOST* cases.
subtest 'zerooooooo without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 0000px }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'no units' => sub {
    my $given  = 'p { width: 0000 }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations,
  # but will be minified from "zerooooo" to just "zero".
  subtest 'percent' => sub {
    my $given  = 'p { width: 000% }';
    my $expect = 'p{width:0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 0000px) }';
    my $expect = 'p{width:calc(300px - 0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# "zerooooo-point-zeroooo" can be expressed without a unit, in *MOST* cases.
subtest 'zerooooo-point-zeroooo without units' => sub {
  subtest 'px' => sub {
    my $given  = 'p { width: 000.0000px }';
    my $expect = 'p{width:0}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Percent is special, and may need to be preserved for CSS animations,
  # but will be minified from "zerooo-point-zerooo" to just "zero".
  subtest 'percent' => sub {
    my $given  = 'p { width: 000.000% }';
    my $expect = 'p{width:0%}';
    my $got    = minify($given);
    is $got, $expect;
  };

  # Inside of a function, units/zeros are preserved.
  subtest 'inside a function' => sub {
    my $given  = 'p { width: calc(300px - 000.0000px) }';
    my $expect = 'p{width:calc(300px - 0px)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# Inside of "calc()", whitespace surrounding operators needs to be preserved.
subtest 'calc() method' => sub {
  subtest 'plus' => sub {
    my $given  = 'h1   { width: calc( 100px + 10% ) }';
    my $expect = 'h1{width:calc(100px + 10%)}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'minus' => sub {
    my $given  = 'h2 { width: calc(100% - 30px ) }';
    my $expect = 'h2{width:calc(100% - 30px)}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'times' => sub {
    my $given  = 'h3 { width: calc( 60px * 2 ) }';
    my $expect = 'h3{width:calc(60px * 2)}';
    my $got    = minify($given);
    is $got, $expect;
  };

  subtest 'divide' => sub {
    my $given  = 'h4 { width: calc( 100% / 2 ) }';
    my $expect = 'h4{width:calc(100% / 2)}';
    my $got    = minify($given);
    is $got, $expect;
  };
};

###############################################################################
# RT #36557: Nasty segfault on minifying comment-only css input
#
# Actually turns out to be that *anything* that minifies to "nothing" causes
# a segfault in Perl-5.8.  Perl-5.10 seems immune.
subtest 'minifies to nothing' => sub {
  my $given  = '/* */';
  my $expect = undef;
  my $got    = minify($given);
  is $got, $expect;
};

###############################################################################
# General/broad test
subtest 'general/broad test' => sub {
  my $given
    = "/* comment to be removed */\n"
    . "\@import    url(more.css   );\n\n"
    . "\tbody, td, th {\nfont-family: Verdana, 'Bitstream Vera Sans';}\n"
    . ".nav {\n\tmargin-left:20%\n}"
    . "#main-nav { background-color: red; border: 1px solid yellow; }\n"
    . "div#content h1    + p\t{padding-top: 000;}";
  my $expect
    = ""
    . "\@import url(more.css);"
    . "body,td,th{font-family:Verdana,'Bitstream Vera Sans'}"
    . ".nav{margin-left:20%}"
    . "#main-nav{background-color:red;border:1px solid yellow}"
    . "div#content h1 + p{padding-top:0}";
  my $got = minify($given);
  is $got, $expect;
};

###############################################################################
done_testing();
