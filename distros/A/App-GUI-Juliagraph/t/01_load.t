#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 22;

use_ok( 'App::GUI::Juliagraph::Settings' );
use_ok( 'App::GUI::Juliagraph::Config' );
use_ok( 'App::GUI::Juliagraph::Config::Default' );
use_ok( 'App::GUI::Juliagraph::Compute::Mapping' );
use_ok( 'App::GUI::Juliagraph::Compute::Image' );
use_ok( 'App::GUI::Juliagraph::Dialog::About' );
use_ok( 'App::GUI::Juliagraph::Widget::ProgressBar' );
use_ok( 'App::GUI::Juliagraph::Widget::ColorDisplay' );
use_ok( 'App::GUI::Juliagraph::Widget::PositionMarker' );
use_ok( 'App::GUI::Juliagraph::Widget::SliderCombo' );
use_ok( 'App::GUI::Juliagraph::Widget::SliderStep' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Board' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::ColorBrowser' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::ColorPicker' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::ColorSetPicker' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Monomial' );
use_ok( 'App::GUI::Juliagraph::Frame::Tab::Constraints' );
use_ok( 'App::GUI::Juliagraph::Frame::Tab::Polynomial' );
use_ok( 'App::GUI::Juliagraph::Frame::Tab::Mapping' );
use_ok( 'App::GUI::Juliagraph::Frame::Tab::Color' );
use_ok( 'App::GUI::Juliagraph::Frame' );
use_ok( 'App::GUI::Juliagraph' );

exit 0;
