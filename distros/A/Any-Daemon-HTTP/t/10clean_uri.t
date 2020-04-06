#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
use Any::Daemon::HTTP ();

my @tests = qw!
   http://host.com/d/aaa/../bb             http://host.com/d/bb
   http://host.com/../c                    http://host.com/c
   http://host.com/../cc/.                 http://host.com/cc/
   http://host.com/../cc/../b              http://host.com/b
   http://host.com/aa/bb/../../../c        http://host.com/c
   http://host.com/aa/././../c             http://host.com/c
!;

my $daemon = bless {}, 'Any::Daemon::HTTP';

while(@tests)
{   my ($raw, $clean) = splice @tests, 0, 2;
	my $uri = URI->new($raw);
    $daemon->_clean_uri($uri);
	is $uri, $clean;
}

done_testing;
