#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-pod.t 141 2017-01-21 12:22:25Z minus $
#
#########################################################################
use strict;
use Test::More;

my $ver = 1.22; # Ensure a recent version of Test::Pod
eval "use Test::Pod $ver";
plan skip_all => "Test::Pod $ver required for testing POD" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

all_pod_files_ok();

1;
__END__
