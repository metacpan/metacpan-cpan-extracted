#!/usr/bin/perl
use Apache::Session::MemcachedReplicator;
my $rep = Apache::Session::MemcachedReplicator->new(in_file =>"/tmp/logmem1",
                                   out_file =>"/tmp/mem1",
                                   naptime => 2 ,);

$rep->run ;
exit;

