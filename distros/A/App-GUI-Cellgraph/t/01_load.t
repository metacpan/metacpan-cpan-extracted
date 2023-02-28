#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 21;

use_ok( 'App::GUI::Cellgraph::Settings' );
use_ok( 'App::GUI::Cellgraph::Compute::Grid' );
use_ok( 'App::GUI::Cellgraph::Compute::Rule' );
use_ok( 'App::GUI::Cellgraph::Dialog::About' );
use_ok( 'App::GUI::Cellgraph::Widget::Action' );
use_ok( 'App::GUI::Cellgraph::Widget::ColorDisplay' );
use_ok( 'App::GUI::Cellgraph::Widget::ColorToggle' );
use_ok( 'App::GUI::Cellgraph::Widget::PositionMarker' );
use_ok( 'App::GUI::Cellgraph::Widget::ProgressBar' );
use_ok( 'App::GUI::Cellgraph::Widget::RuleInput' );
use_ok( 'App::GUI::Cellgraph::Widget::SliderCombo' );
use_ok( 'App::GUI::Cellgraph::Frame::Part::Board' );
use_ok( 'App::GUI::Cellgraph::Frame::Part::ColorBrowser' );
use_ok( 'App::GUI::Cellgraph::Frame::Part::ColorPicker' );
use_ok( 'App::GUI::Cellgraph::Frame::Part::ColorSetPicker' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Rules' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Start' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Mobile' );
use_ok( 'App::GUI::Cellgraph::Frame::Panel::Color' );
use_ok( 'App::GUI::Cellgraph::Frame' );
use_ok( 'App::GUI::Cellgraph' );
