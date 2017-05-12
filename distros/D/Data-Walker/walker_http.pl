#!/usr/bin/perl -w
#-------------------------------------------------------
# Format the output of Data::Walker as HTML, and set up
# an HTTP daemon.  In this way we can examine Perl objects 
# using a Web browser. 
#
# This script requires that you have the LWP and the HTTP
# bundles installed.  If you don't have these installed,
# then you should install them anyway, because they are 
# pretty cool. 
#-------------------------------------------------------

use CGI qw(:standard :nodebug);
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Request;
use Data::Walker;

use strict;

#----------------------------------------------
# Setup the HTTP daemon
#
sub walk_via_HTTP_daemon {

	my ($w,$timeout,$port,$host) = @_;

	$timeout   = 180 unless defined $timeout;
	$port      =   0 unless defined $port;

	my $d;

	if ($port) {
		$d = new HTTP::Daemon (LocalAddr => $host);
	} else {
		$d = new HTTP::Daemon (LocalAddr => $port, LocalPort => $port);
	}
	
	unless (defined $d) {
		warn "Could not bind to port.  I'm going to have to exit.  Sorry.\n";
		exit(-1);
	}
	
	my $myurl = $d->url;

	#----------------------------------------------
	# Daemonize:  fork, and then detatch from the local shell.
	#
	defined(my $pid = fork) or die "Cannot fork: $!";
	
	if ($pid) {             # The parent exits
		print redirect($myurl); 
		exit 0;
	}
	
	close(STDOUT);          # The child lives on, but disconnects
                        	# from the local terminal
	
	# We opt not to close STDERR here, because we actually might
	# want to see error messages at the terminal. 


	#----------------------------------------------
	# Now we enter a never-ending listen loop. 
	# The program ends when the timer runs out. 
	# We do not have any alarm handler, we just exit. 
	#
	LISTEN: {

		alarm($timeout);              # (re-)set the clock

		my $c = $d->accept;           # $c is a connection
		redo LISTEN unless defined $c;

		my $r = $c->get_request;      # $r is a request
		redo LISTEN unless defined $r;

		#----------------------------------------------
		# Parse the document path and interpret it as a "path"
		# into the object.  Pass this to the Data::Walker::cd() method. 
		#
		my $target = $r->{_url}->{path};
		$target = "/" unless defined $target and $target ne "";
		$target =~ s#/+#/#g;
		$w->cd($target);

		my $pwd = $w->pwd;
		$pwd =~ s#->#/#g;
		$pwd =~ s/[{}]//g;
		$pwd =~	s#/+#/#g;

		print $c "<h1>Data::Walker->cwd &nbsp;&nbsp; $pwd</h1>\n<pre>\n\n";
		( my $pwd_parent = $pwd ) =~ s#/[^/]+$##;

		#----------------------------------------------
		# Insert hyperlinks into the output of ls()
		#
		my @output = split /\n/, $w->ls("-al");

		foreach (@output) {

			$_ = CGI::escapeHTML($_);

			next unless m#(HASH|ARRAY)#;
			s#^[-\w]+#<a href="/$pwd/$&">$&</a>#;
			s#^\.\.#<a href="/$pwd_parent">$&</a>#;
			s#/+#/#g;
		}

		#----------------------------------------------
		# Print the formatted lines to the client
		#
		local($,) = "\n";
		print $c @output;
		close $c;

		redo LISTEN;
	}
}


1; # END

