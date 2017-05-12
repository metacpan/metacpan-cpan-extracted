package t::TestApp::Simple;
use strictures 1;
# ABSTRACT: Test application for unit tests.
#
# This file is part of Dancer2-Session-Redis
#
# This software is Copyright (c) 2016 by BURNERSK <burnersk@cpan.org>.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#

BEGIN {
  our $VERSION = '0.001';  # fixed version - NOT handled via DZP::OurPkgVersion.
}

use Dancer2;
use Plack::Builder;
use Dancer2::Plugin::Redis;

############################################################################

get q{/} => sub { 'Hello World' };

get q{/set} => sub {
  no warnings 'all';
  session param('key') => param('value');
  sprintf 'set %s: %s', param('key'), session param('key');
};

get q{/get} => sub {
  no warnings 'all';
  sprintf 'get %s: %s', param('key'), session param('key');
};

get '/change_session_id' => sub {
  if ( app->can('change_session_id') ) {
    app->change_session_id;
    return "supported";
  }
  else {
    return "unsupported";
  }
};

############################################################################
builder { psgi_app };
