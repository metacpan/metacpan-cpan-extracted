use 5.010;
use strict;
use warnings;
use Test::More 0.96;
use Test::File::ShareDir -share =>
  { -dist => { 'Data-Password-Common' => 'share' } };

use Data::Password::Common 'found',
  found => { -as => "myfound", list => 't/data/500worst.txt' };

ok( found("password"),   "'password' is in built-in list" );
ok( myfound("password"), "'password' is in custom list" );
ok( found("stupid1"),    "'stupid1' is in built-in list" );
ok( !myfound("stupid1"), "'stupid1' is not in custom list" );

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
