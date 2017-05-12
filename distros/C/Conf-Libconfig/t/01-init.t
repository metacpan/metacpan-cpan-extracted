#!perl -T
use strict;
use warnings;
#use Test::More;
#eval "use Test::Exception tests => 1";
use Test::Exception tests => 1;
#plan skip_all => "Test::Exception required for testing" if $@;
use Conf::Libconfig;

lives_ok { my $foo = Conf::Libconfig->new; } 'new - status ok';
