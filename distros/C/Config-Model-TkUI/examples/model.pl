#!/usr/bin/perl
#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# (c) 2009 Alexander Becker <asb_ehb at yahoo.de>
# (c) 2009 Dominique Dumont <ddumont at cpan.org>

# example contributed by Alexander Becker
# Adapted to Unix and streamlined by Dominique Dumont

# See https://rt.cpan.org/Ticket/Display.html?id=49999

use strict;
use warnings;
use Config::Model;
use Config::Model::TkUI;
use Log::Log4perl qw(:easy);

# -- init trace
Log::Log4perl->easy_init($WARN);

# -- create configuration instance
my $model = Config::Model->new();

# -- create config model
$model->create_config_class(
	name => "SomeRootClass",
	element => [
		country  => {
			type =>       'leaf',
			value_type => 'enum',
			choice =>     [qw/France US/]
		},
	],
);

my $inst = $model->instance(
	root_class_name => 'SomeRootClass',
);

my $root = $inst->config_root();

# -- Tk part
my $mw = MainWindow->new();

$mw->withdraw();
$mw->ConfigModelUI(-root => $root);

$mw->MainLoop();
