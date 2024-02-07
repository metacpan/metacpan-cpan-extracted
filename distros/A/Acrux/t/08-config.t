#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;

BEGIN { use_ok('Acrux::Config') }

my $c = Acrux::Config->new(
        #root => '/tmp/test',
        #dirs => ['t', 'src', '/home/minus/prj/modules/Acrux/lib'],
        file => 't/test.conf',
    );
#diag explain $c;

# Check errors
ok(!$c->error, 'Check errors') or do { diag $c->error; exit 255 if $c->error };

## Foo     One
## Bar     1
## Baz     On
## Qux     Off
## <Box>
##     Test    123
## </Box>
## <Array>
##     Test    First
##     Test    Second
##     Test    Third
## </Array>
## <Deep>
##     <Foo>
##         <Bar>
##             Test    blah blah blah
##         </Bar>
##     </Foo>
## </Deep>

# Loaded config data
is($c->config('_config_loaded'), 1, 'get config directive directrly');

# Get on/off flags directly
is($c->config('baz'), 1, 'Get on/off flags directly');

# Get by pointer path
is($c->get('/box/test'), 123, 'Get by pointer path /box/test');
is($c->get('box/test'), 123, 'Get by pointer path in short notation box/test');

# Get deeply
is($c->get('/deep/foo/bar/test'), 'blah blah blah', 'Get deeply /deep/foo/bar/test');

# Get on/off flags
is($c->get('/baz'), 1, 'Get on flags');
is($c->get('/qux'), 0, 'Get off flags');

# Get first value
is($c->first('/array/test'), 'First', 'Get first value');

# Get latest value
is($c->latest('/array/test'), 'Third', 'Get latest value');

# Get list of values as array
is(ref($c->array('/array/test')), 'ARRAY', 'Get list of values as array');

# Get hash of values
is(ref($c->hash('/array')), 'HASH', 'Get hash of values');
#diag explain $c->hash('/array');

done_testing;

1;

__END__
