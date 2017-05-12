#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Exception;
use S2;

throws_ok sub { DBICx::Shortcuts->schema },
  qr/Class 'DBICx::Shortcuts' did not call 'setup[(][)]'/,
  'Needs to call setup() first';

throws_ok sub { DBICx::Shortcuts->connect_info },
  qr/Class 'DBICx::Shortcuts' needs to override 'connect_info[(][)]'/,
  'The connect_info() method dies by default';

throws_ok sub { DBICx::Shortcuts->setup('NoSuchClass') },
  qr/Can't locate NoSuchClass.pm in [@]INC/,
  'Failure to load Schema class detected';

throws_ok sub { S2->setup('Schema') },
  qr/Shortcut failed, 'my_books' already defined in 'S2', /,
  'Shortcut conflict with method detected';

done_testing();
