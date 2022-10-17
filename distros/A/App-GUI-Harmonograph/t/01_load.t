#!/usr/bin/perl -w
use v5.12;
use lib 'lib';
use Test::More tests => 16;

use_ok( 'App::GUI::Harmonograph::Dialog::About' );
use_ok( 'App::GUI::Harmonograph::Dialog::Interface' );
use_ok( 'App::GUI::Harmonograph::Dialog::Function' );
use_ok( 'App::GUI::Harmonograph::Widget::ProgressBar' );
use_ok( 'App::GUI::Harmonograph::Widget::ColorDisplay' );
use_ok( 'App::GUI::Harmonograph::Widget::SliderCombo' );
use_ok( 'App::GUI::Harmonograph::Settings' );
use_ok( 'App::GUI::Harmonograph::Config' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::Board' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorBrowser' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorFlow' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::ColorPicker' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::Pendulum' );
use_ok( 'App::GUI::Harmonograph::Frame::Part::PenLine' );
use_ok( 'App::GUI::Harmonograph::Frame' );
use_ok( 'App::GUI::Harmonograph' );
