#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 19;

use_ok( 'App::GUI::Harmonograph::Settings' );
use_ok( 'App::GUI::Harmonograph::Config::Default' );
use_ok( 'App::GUI::Harmonograph::Config' );
use_ok( 'App::GUI::Harmonograph::Dialog::About' );
use_ok( 'App::GUI::Wx::Widget::Custom::SliderCombo' );
use_ok( 'App::GUI::Wx::Widget::Custom::ColorDisplay' );
use_ok( 'App::GUI::Wx::Widget::Custom::Canvas' );
use_ok( 'App::GUI::Wx::Widget::Custom::PositionMarker' );
use_ok( 'App::GUI::Wx::Widget::Custom::ProgressBar' );
use_ok( 'App::GUI::Harmonograph::Frame::Panel::ColorBrowser' );
use_ok( 'App::GUI::Harmonograph::Frame::Panel::ColorPicker' );
use_ok( 'App::GUI::Harmonograph::Frame::Panel::ColorSetPicker' );
use_ok( 'App::GUI::Harmonograph::Frame::Panel::Pendulum' );
use_ok( 'App::GUI::Harmonograph::Frame::Tab::Color' );
use_ok( 'App::GUI::Harmonograph::Frame::Tab::Function' );
use_ok( 'App::GUI::Harmonograph::Frame::Tab::Visual' );
use_ok( 'App::GUI::Harmonograph::Frame' );
use_ok( 'App::GUI::Harmonograph::Compute::Drawing' );
use_ok( 'App::GUI::Harmonograph' );
