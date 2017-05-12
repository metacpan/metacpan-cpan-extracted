#!/usr/local/perl/bin/perl -w

use strict;
use warnings;

use parent 'Class::Scaffold::App::Test::Classes';

$ENV{CF_CONF} = 'local';
main->new->run_app;
