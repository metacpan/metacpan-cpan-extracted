use 5.010;
use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Test::File::ShareDir -share =>
  { -dist => { 'Data-Password-Common' => 'share' } };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use Data::Password::Common qw/found/;

ok( found("password"),   "'password' is a common passwo'rd" );
ok( found("trustno1"),   "'trustno1' is a common password" );
ok( found('!"£$%^'),    q['!"£$%^' is a common password] );
ok( !found("alkdjf1=2"), "'alkdjf1=2' is not a common password" );

done_testing;
#
# This file is part of Data-Password-Common
#
# This software is Copyright (c) 2012 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
