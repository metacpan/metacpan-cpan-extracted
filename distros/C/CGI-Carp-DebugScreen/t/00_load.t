use strict;
use Test::More tests => 5;

BEGIN {
  use_ok('CGI::Carp::DebugScreen');
  use_ok('CGI::Carp::DebugScreen::DefaultView');
  use_ok('CGI::Carp::DebugScreen::Dumper');

SKIP: {
    eval 'require HTML::Template';
    skip('skip; no HTML::Template',1) if $@;

    use_ok('CGI::Carp::DebugScreen::HTML::Template');
  }

SKIP: {
    eval 'require Template';
    skip('skip; no Template Toolkit',1) if $@;

    use_ok('CGI::Carp::DebugScreen::TT');
  }
}

