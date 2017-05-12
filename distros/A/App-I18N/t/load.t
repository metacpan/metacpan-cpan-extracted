#!/usr/bin/env perl
use Test::More tests => 10;
use utf8;
use lib 'lib';

use_ok "App::I18N";
use_ok "App::I18N::DB";
use_ok "App::I18N::Web";
use_ok "App::I18N::Command";
use_ok "App::I18N::Command::Server";
use_ok "App::I18N::Command::Parse";
use_ok "App::I18N::Command::Lang";
use_ok "App::I18N::Command::Auto";
use_ok "App::I18N::Command::Initdb";
use_ok "App::I18N::Command::Import";
