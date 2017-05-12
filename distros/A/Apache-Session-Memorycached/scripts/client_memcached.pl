#!/usr/bin/perl
use Apache::Session::MemcachedClient;
my $rep = Apache::Session::MemcachedClient->new(in_file =>"/tmp/mem1",
                                                out_file =>"/tmp/log1",
                            naptime => 2 ,
                     localmemcached => {'servers' => ['localhost:11211'],  },  
                     remotememcached =>{'servers' => ['localhost:11311'],  },
                     signature  => 'mastersur11211',
		     safety_mode   =>'actived' , 
);
$rep->run ;
exit;
