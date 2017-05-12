#!perl 

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;


my $OS = $^O;

if($OS =~ /linux/i){

    if(-e '/usr/bin/memcached' || -e '/usr/bin/memcachedb'){
        pass 'memcached/memcachedb binary was found!'; 
    }
    else {
        fail 'memcached/memcachedb service is required. Install some Memcached service';
    }
}
elsif($OS =~ /win/i){
    #trying find memcached on windows like a service...
    my @dump = readpipe 'sc memcached';
    if(!@dump){
        #trying with dir /s command
        @dump = ();
        @dump = readpipe 'dir /s memcached*.exe';
        my $found =0;
        map{if($_ =~ /memcached/i){$found =1; last;}}@dump;
        if(!$found){
            fail 'memcached executable was not found!'
        }
        else {
            pass 'memcached was found!';
        }
    }
    else {
        my $found = 0;
        map{if($_ =~ /memcached/i){$found =1; last;}}@dump;
        if($found){
            pass 'memcached was found!';
        }
        else {
            fail 'memcached was not found! Need to install!';
        }
    }
}
else {
    #trying a generic Unix like test...
    my @dump = readpipe 'memcached -i';
    if(!@dump){
        fail 'memcached was not found';
    }
    foreach my $d(@dump){
        if($d =~ /memcached/i){
            pass 'memcached was found!';
        }
    }
    
}

