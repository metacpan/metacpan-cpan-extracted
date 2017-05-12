#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use File::Spec;

BEGIN {
    use_ok('Config::Constants::XML');
};

can_ok('Config::Constants::XML', 'new');

{
    my $config = Config::Constants::XML->new(File::Spec->catdir('t', 'confs', 'conf.xml'));
    isa_ok($config, 'Config::Constants::XML');
    
    can_ok($config, 'modules');
    can_ok($config, 'constants');    
    
    is_deeply(
        [ $config->modules ],
        [ 'Foo::Bar', 'Bar::Baz' ],
        '... got the right modules');
        
    is_deeply(
        [ $config->constants('Foo::Bar') ],
        [ { 'BAZ' => 'the coolest module ever' } ],
        '... got the right constants for Foo::Bar');

    is_deeply(
        [ sort { (keys(%$a))[0] cmp (keys(%$b))[0] } $config->constants('Bar::Baz') ],
        [ { 'BAR' => 'Foo and Baz' },
          { 'FOO' => 42 } ],
        '... got the right constants for Bar::Baz');
}
