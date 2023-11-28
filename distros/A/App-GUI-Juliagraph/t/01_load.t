#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 18;

use_ok( 'App::GUI::Juliagraph::Settings' );
use_ok( 'App::GUI::Juliagraph::Config' );
use_ok( 'App::GUI::Juliagraph::Dialog::About' );
use_ok( 'App::GUI::Juliagraph::Widget::ProgressBar' );
use_ok( 'App::GUI::Juliagraph::Widget::ColorDisplay' );
use_ok( 'App::GUI::Juliagraph::Widget::PositionMarker' );
use_ok( 'App::GUI::Juliagraph::Widget::SliderCombo' );
use_ok( 'App::GUI::Juliagraph::Widget::SliderStep' );
use_ok( 'App::GUI::Juliagraph::Frame::Part::Board' );
use_ok( 'App::GUI::Juliagraph::Frame::Part::ColorBrowser' );
use_ok( 'App::GUI::Juliagraph::Frame::Part::ColorPicker' );
use_ok( 'App::GUI::Juliagraph::Frame::Part::Monomial' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Constraints' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Polynomial' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Mapping' );
use_ok( 'App::GUI::Juliagraph::Frame::Panel::Color' );
use_ok( 'App::GUI::Juliagraph::Frame' );
use_ok( 'App::GUI::Juliagraph' );
