#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: pod-coverage.t 59 2016-10-05 10:13:27Z abalama $
#
#########################################################################

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 6;

pod_coverage_ok( "App::MonM", { trustme => [qr/^(debug|start|finish|ctkx|foutput|([A-Z]+))$/] } );

# App::MonM::*
pod_coverage_ok( "App::MonM::AlertGrid", { trustme => [qr/^(LOCALHOSTIP)$/] } );
pod_coverage_ok( "App::MonM::Checkit" );
pod_coverage_ok( "App::MonM::Helper", { trustme => [qr/^(pool|dirs)$/] } );
pod_coverage_ok( "App::MonM::Util" );
pod_coverage_ok( "App::MonM::RRDtool", { trustme => [qr/^(GTYPES|MASK)$/] } );

1;
