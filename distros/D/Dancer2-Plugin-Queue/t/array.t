use 5.010;
use Test::Roo;

sub _build_options { return { name => 'foo' } }

with 'Dancer2::Plugin::Queue::Role::Test';

run_me( { backend => 'Array' } );

done_testing;
#
# This file is part of Dancer2-Plugin-Queue
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
