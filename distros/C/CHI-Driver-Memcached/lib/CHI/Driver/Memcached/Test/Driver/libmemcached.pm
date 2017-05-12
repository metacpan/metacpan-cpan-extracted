package CHI::Driver::Memcached::Test::Driver::libmemcached;
$CHI::Driver::Memcached::Test::Driver::libmemcached::VERSION = '0.16';
use Moose;
use strict;
use warnings;

extends 'CHI::Driver::Memcached::libmemcached';
with 'CHI::Driver::Memcached::Test::Driver::Base';

__PACKAGE__->meta->make_immutable();

1;
