#!/usr/bin/perl
# 02-pod.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();

