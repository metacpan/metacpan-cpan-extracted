#!/usr/bin/perl
use warnings;
use strict;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use Data::Dumper;
use Carp;
my $address = "127.0.0.1";
my $webRoot = "example_cgi_apps";
my $d;
print "Waiting for port to become ready\n";
while(!$d){
	$d = HTTP::Daemon->new(
		LocalAddr => $address
	);
	print ".";
	sleep 1;
}
print "\n";
if($d){
	$ENV{'SERVER_NAME'} = $address;
	my $baseUrl = $d->url();
	print "Point your browser to: " . $baseUrl . "mungo_hello.cgi\n";
	while(my $c = $d->accept) {
    	while(my $r = $c->get_request) {
        	if($r->method eq 'GET' || $r->method() eq "POST") {
                my $request = $r->uri();
				$ENV{'SCRIPT_NAME'} = $request;
				if($request ne "/favicon.ico"){	#ignore these files
					print STDERR "Serving request: $request\n";
	                my $cmd = $webRoot . $request;
	                if(open(CGI, $cmd. "|")){
		                my $output = "200 OK\n";	#always give a 200 if the script finishes
	                	while(my $line = <CGI>){	#get all the output from the cgi app
	                		$output .= $line;
	                	}
	                	close(CGI);
	                	my $response = HTTP::Response->parse($output);
	                	$c->send_response($response);
	                }
	                else{	#problem with cgi script
	                	$c->send_error(RC_INTERNAL_SERVER_ERROR);
	                }					
				}
				else{	#we dont have these files
	                $c->send_error(RC_NOT_FOUND);					
				}
           	}
            else{	#no other methods are implemented
            	$c->send_error(RC_NOT_IMPLEMENTED)
            }
		}
		$c->close;
        undef($c);
	}
}
else {
	confess("Could not start server: $!");
}
