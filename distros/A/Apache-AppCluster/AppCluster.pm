package Apache::AppCluster;
use strict;
use Apache::AppCluster::Server;
use Apache::AppCluster::Client;
use vars qw( $VERSION );

$VERSION = '0.02';

1;

=head1 NAME

Apache::AppCluster

=head1 SYNOPSIS

use Apache::AppCluster::Client; #in your client applications

See Apache::AppCluster::Server and Apache::AppCluster::Client 
documentation for details on usage.

=head1 SUMMARY DESCRIPTION

Apache::AppCluster is a lightweight mod_perl RPC mechanism that allows you to
use your mod_perl web servers as distributed application servers that serve
multiple concurrent RPC requests to remote clients across a network. The client
component has the ability to fire off multiple simultaneous requests to 
multiple remote application servers and collect the responses simultaneously. 

This is similar to SOAP::Lite in that it is a web based RPC mechanism, but it has the advantage of being able to send/receive multiple concurrent requests to the same or different remote application servers and the methods/functions called on the remote servers may receive and return Perl data structures of arbritary complexity - entire objects can be flung back and forth with ease. 

Please see Apache::AppCluster::Client and Apache::AppCluster::Server documentation for full details on server configuration (very easy) and Client usage (OO interface).

=head1 BUGS

None known. Please send to the author.

=head1 SEE ALSO

Apache::AppCluster::Client and Apache::AppCluster::Server contain comprehensive documentation on their respective usages.

=head1 AUTHOR

Mark Maunder <mark@swiftcamel.com> - please email problems, suggestions and bugs.

=cut

