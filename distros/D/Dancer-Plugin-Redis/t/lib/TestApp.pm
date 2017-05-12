#
# This file is part of Dancer-Plugin-Redis
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TestApp;

use Dancer;
use FakeRedis;
use Dancer::Plugin::Redis;

set serializer => 'JSON';

get '/' => sub {
    [ redis->get('foo') ];
};

true;
