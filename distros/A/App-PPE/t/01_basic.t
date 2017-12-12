use strict;
use warnings;
use utf8;
use Test::More;

use App::PPE;

my $ppe = App::PPE->new({color => 0});

is $ppe->prettify_perl_error('syntax error at /home/kfly8/foo.pl line 52, near "$foo:"'),
  'foo.pl:52: [CRITICAL] (F) syntax error, near $foo', 'prettify';

is $ppe->prettify_perl_error('XXX'), 'XXX';

done_testing;
