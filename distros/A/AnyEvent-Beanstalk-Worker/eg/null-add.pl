#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent::Beanstalk;

my $b = AnyEvent::Beanstalk->new
  ( server => 'localhost' );

$b->use('test')->recv;

for my $i (1..10000) {
    my $job = $b->put({ priority => 100,
                        ttr      => 10,
                        delay    => 1,
                        data     => "this is job $i" })->recv;
    print STDERR "added job $i to queue\r";
}
print STDERR "\n";

exit;
