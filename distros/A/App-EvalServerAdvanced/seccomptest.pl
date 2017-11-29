#!/usr/bin/env perl

use strict;
use warnings;
use lib './lib';
use App::EvalServerAdvanced::Seccomp;
$App::EvalServerAdvanced::Config::config_dir = '/home/ryan//workspace/evalserver-async/serverapp/testsandbox/sandbox/etc';

my $seccomp = App::EvalServerAdvanced::Seccomp->new();
$seccomp->load_yaml('/home/ryan//workspace/evalserver-async/serverapp/skel-sandbox/etc/seccomp.yaml');

use Data::Dumper;
$seccomp->build_seccomp;
$seccomp->apply_seccomp("lang_perl");
#print Dumper($seccomp);
