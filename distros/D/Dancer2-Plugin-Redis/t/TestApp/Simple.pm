package t::TestApp::Simple;
use strictures 1;
# ABSTRACT: Test application for unit tests.
#
# This file is part of Dancer2-Plugin-Redis
#
# This software is Copyright (c) 2018 by BURNERSK <burnersk@cpan.org>.
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
use Safe::Isa;

############################################################################

get q{/} => sub {
    redis_plugin->_redis->$_can('get') && return 'Hello World';
};

get q{/set} => sub {
  no warnings 'uninitialized';
  redis_set param('key'), param('value');
  sprintf 'set %s: %s', param('key'), param('value');
};

get q{/get} => sub {
  no warnings 'uninitialized';
  sprintf 'get %s: %s', param('key'), redis_get param('key');
};

get q{/expire} => sub {
  no warnings 'uninitialized';
  redis_expire param('key'), param('expire');
  sprintf 'expire %s: %s', param('key'), param('expire');
};

get q{/del} => sub {
  no warnings 'uninitialized';
  redis_del param('key');
  sprintf 'del %s', param('key');
};

############################################################################
builder { psgi_app };
