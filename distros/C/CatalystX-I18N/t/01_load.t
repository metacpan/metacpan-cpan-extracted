#!perl
use strict;
use warnings;

use Test::Most tests => 20;

use_ok( 'CatalystX::I18N' );
use_ok( 'CatalystX::I18N::Maketext' );
use_ok( 'CatalystX::I18N::Role::Base' );
use_ok( 'CatalystX::I18N::Role::DateTime' );
use_ok( 'CatalystX::I18N::Role::GetLocale' );
use_ok( 'CatalystX::I18N::Role::Maketext' );
use_ok( 'CatalystX::I18N::Role::NumberFormat' );
use_ok( 'CatalystX::I18N::Role::Collate' );
use_ok( 'CatalystX::I18N::Role::All' );
use_ok( 'CatalystX::I18N::Role::PosixLocale' );
use_ok( 'CatalystX::I18N::Role::DataLocalize' );
use_ok( 'CatalystX::I18N::TypeConstraints' );
use_ok( 'CatalystX::I18N::Model::L10N' );
use_ok( 'CatalystX::I18N::Model::Maketext' );
use_ok( 'CatalystX::I18N::Model::DataLocalize' );
use_ok( 'CatalystX::I18N::TraitFor::Response' );
use_ok( 'CatalystX::I18N::TraitFor::Request' );
use_ok( 'CatalystX::I18N::TraitFor::ViewTT' );

use_ok( 'Catalyst::Helper::Model::DataLocalize' );
use_ok( 'Catalyst::Helper::Model::Maketext' );
