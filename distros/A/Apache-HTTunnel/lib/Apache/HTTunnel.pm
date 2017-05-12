package Apache::HTTunnel ;

use strict ;
use Carp ;


$Apache::HTTunnel::VERSION = '0.08' ;


sub import {
	my $class = shift ;

	foreach my $a (@_){
		if ($a eq 'sample_config'){
			while (<DATA>){
				print $_ ;
			}
			exit() ;
		}
		else {
			croak("Invalid 'use' parameter '$a'") ;
		}
	}
}


sub handler {
	return Apache::HTTunnel::Handler::handler(@_) ;
}


if ($ENV{MOD_PERL}){
	require Apache::HTTunnel::Keeper ;
	require Apache::HTTunnel::Handler ;
}



1 ;

__DATA__
# Sample Apache::HTTunnel configuration file

# Specifiy the location of the fifo (UNIX domain socket or named pipe)
# that will be used byb the Apache children to communicate with the "keeper"
# process.
PerlSetVar		HTTunnelFifo				/var/lib/httunnel/httunnel.sock

# The maximum connect timeout that may be specified by the client. This value
# should be kept low (< 60) since that Apache children maybe be blocked up 
# to that ammount of time.
# In seconds.
PerlSetVar		HTTunnelMaxConnectTimeout	15

# The maximum read length that may be specified by the client.
# In bytes.
PerlSetVar		HTTunnelMaxReadLength		131072

# The maximum read timeout that may be specified by the client. This value
# should be kept low (< 60) since that Apache children maybe be blocked up 
# to that ammount of time.
# In seconds.
PerlSetVar		HTTunnelMaxReadTimeout		15

# Connections that remain inactive after this amount of time will be closed.
# In seconds.
PerlSetVar		HTTunnelConnectionTimeout	900


# Load up the module
PerlPostConfigRequire	Apache/HTTunnel.pm


# Setup the location that will be used.
<Location "/httunnel">
  SetHandler		perl-script
  PerlResponseHandler	Apache::HTTunnel
  PerlSetVar            HTTunnelAllowedTunnels "\
    localhost => 22|80, \
    dns => 53 "
</Location>
