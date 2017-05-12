use strict;
use warnings;
use Test::More;
use lib qw(lib ../lib);
plan(tests => 9);
#1
use_ok("CGI::Mungo");
#2
use_ok("CGI::Mungo::Base");
#3
use_ok("CGI::Mungo::Log");
#4
use_ok("CGI::Mungo::Request");
#5
use_ok("CGI::Mungo::Response");
#6
use_ok("CGI::Mungo::Session");
#7
use_ok("CGI::Mungo::Utils");
#8
use_ok("CGI::Mungo::Response::Raw");
#9
use_ok("CGI::Mungo::Response::TemplateToolkit");
