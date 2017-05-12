#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use_ok 'AnyEvent::RabbitMQ::Fork';
use_ok 'AnyEvent::RabbitMQ::Fork::Channel';
use_ok 'AnyEvent::RabbitMQ::Fork::Worker';

done_testing;
