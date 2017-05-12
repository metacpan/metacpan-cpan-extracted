use BrLock::SomePerlFunc; 
use BrLock; 

use warnings; 
use diagnostics; 


# if we are not informed what are our ip number: 
use constant OUR_IP => "127.0.0.1";
# # if we are not informed what are our ip port: 
use constant OUR_PORT => 3002;

use constant RESOURCE_IP => "127.0.0.1"; 
use constant RESOURCE_PORT => 3000; 

#the application works with these values: 
our $t = 2;  # a br_lock() will be kept for, at most, $t sec. 
our $s = 10; # application won't ask again for the lock for, 
             # at most $s sec. 

# sub  resource_usenabuse():
#  Sends immediately a message "begin" to the resource, hangs for 
#  a random number of seconds (between 0..$t), and then sends a 
#  message "end" to the resource. Just a testing function. The idea
#  behind it is that the resource should never print two "begin"s
#  before an end (ie, it should always print beginendbeginend and so
#  on). 
#
#  No parameters. No return codes. 
#

sub resource_usenabuse {
	send_udp_string ("begin($our_ip:$our_port,$BrLock::osn)\n",
		                              $resource_info{Site}, 
		                              $resource_info{Port}); 
	# do nothing for $int_j seconds (hold resource and hang!). 
	# $int_j is a random number between 0 and $t. 
	sleep(choose_integer($t));
	send_udp_string ("end($our_ip:$our_port,$BrLock::osn)\n ", 
		                               $resource_info{Site}, 
		                               $resource_info{Port}); 
}


# sub  hunger_for_resource(): 
#  an infinite loop function  which waits for a
#  random number of seconds (between 0..$s) before asking for the
#  resource; it repeats this forever. 

sub hunger_for_resource {
	$| = 1;  # for flusing output. 
	print "Starting in 5 seconds...\n" if $debug;
	sleep(1);  # TODO: first time wait (waiting for everyone). 
	print "Starting in 4 seconds...\n" if $debug;
	sleep(1); 
	print "Starting in 3 seconds...\n" if $debug;
	sleep(1); 
	print "Starting in 2 seconds...\n" if $debug;
	sleep(1); 
	print "Starting in 1 seconds...\n" if $debug;
	sleep(1); 
	print "Starting.\n" if $debug;
	while(1){
		sleep(BrLock::SomePerlFunc::choose_integer($s));
			BrLock->br_lock(); 
			##### hold the resource and hang!!!  
			print "hunger():resource is OURS!!!!!!!!!"
					. "\n" if $debug; 
			resource_usenabuse(); 
			# it was very exciting to hold the resource, 
			# but we need to release it someday...   =( 
			print "hunger():freeing resource.\n" 
				if $debug; 
			BrLock->br_unlock(); 
	}
}




# main. 

our $our_port = ($ARGV[0] ? $ARGV[0] : OUR_PORT);
our $our_ip   = ($ARGV[1] ? $ARGV[1] : OUR_IP);
our $debug = 1; 
our %resource_info; 
$resource_info{Site} =  RESOURCE_IP; 
$resource_info{Port} =  RESOURCE_PORT; 


BrLock->new("mutex.conf", $our_port, $our_ip); 
$BrLock::debug = 1; 
hunger_for_resource(); 


