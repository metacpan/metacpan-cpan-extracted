#!/usr/bin/perl

use strict;
use warnings;

use App::Office::Contacts::Import::vCards::View;

# -----------------------------------------------

my($v) = App::Office::Contacts::Import::vCards::View -> new
(
	config    => 'config',
	db        => 'db',
	logger    => 'logger',
	session   => 'session',
	tmpl_path => '',
);
