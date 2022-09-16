#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 15;

use_ok( 'App::GUI::Harmonograph::Color::Value' );
use_ok( 'App::GUI::Harmonograph::Color::Constant' );
use_ok( 'App::GUI::Harmonograph::Color' );
use_ok( 'App::GUI::Harmonograph::ColorDisplay' );
use_ok( 'App::GUI::Harmonograph::Settings' );
use_ok( 'App::GUI::Harmonograph::Config' );
use_ok( 'App::GUI::Harmonograph::SliderCombo' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::Board' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorBrowser' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorFlow' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorPicker' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::Pendulum' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::PenLine' );
use_ok( 'App::GUI::Harmonograph::Frame' );
use_ok( 'App::GUI::Harmonograph' );
