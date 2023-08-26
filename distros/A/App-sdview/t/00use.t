#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

require App::sdview::Parser;
require App::sdview::Parser::Markdown;
require App::sdview::Parser::Pod;
require App::sdview::Parser::Man;

require App::sdview::Style;

require App::sdview::Output::Terminal;
require App::sdview::Output::Plain;
require App::sdview::Output::Pod;
require App::sdview::Output::Markdown;
require App::sdview::Output::Man;

require App::sdview;

pass( 'Modules loaded' );
done_testing;
