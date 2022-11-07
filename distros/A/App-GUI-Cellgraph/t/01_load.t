#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 14;

use_ok( 'App::GUI::Cellgraph::Settings' );
use_ok( 'App::GUI::Cellgraph::Grid' );
use_ok( 'App::GUI::Cellgraph::RuleGenerator' );
use_ok( 'App::GUI::Cellgraph::Dialog::About' );
#use_ok( 'App::GUI::Cellgraph::Dialog::Interface' );
#use_ok( 'App::GUI::Cellgraph::Dialog::Function' );
use_ok( 'App::GUI::Cellgraph::Widget::ColorDisplay' );
use_ok( 'App::GUI::Cellgraph::Widget::ColorToggle' );
use_ok( 'App::GUI::Cellgraph::Widget::SliderCombo' );
use_ok( 'App::GUI::Cellgraph::Widget::Rule' );
use_ok( 'App::GUI::Cellgraph::Widget::Action' );
use_ok( 'App::GUI::Cellgraph::Frame::Part::Board' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Rules' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Start' );
use_ok( 'App::GUI::Cellgraph::Frame' );
use_ok( 'App::GUI::Cellgraph' );
