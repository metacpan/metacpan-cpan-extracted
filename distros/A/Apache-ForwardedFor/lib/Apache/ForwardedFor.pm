
package Apache::ForwardedFor;
use strict;

BEGIN {
	use vars qw ($VERSION);
    $VERSION     = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/;
	# use vars qw ($TRACE);
    # $TRACE       = 1;
}

use Apache::Constants qw(DECLINED);


sub handler {

    my $r = shift;

    my $fwd_ips = $r->header_in('X-Forwarded-For');
    # $TRACE && warn(__PACKAGE__." bypassed - no X-Forward-For header") and
    return DECLINED unless $fwd_ips;

    # warn(__PACKAGE__." X-Forwarded-For header: $fwd_ips") if $TRACE;

    # Block based on Remove / Add AcceptForwarder values
    my %deny =map { $_ => 1 } $r->dir_config->get('ForwardedForDeny');
    if (exists $deny{$r->connection->remote_ip}) {
        # warn(__PACKAGE__." handling for IP ".$r->connection->remote_ip." refused by RemoveAcceptForwarder directive") if $TRACE;
        return DECLINED;
    }

    my %accept=map { $_ => 1 } $r->dir_config->get('ForwardedForAccept');
    if (!exists $accept{$r->connection->remote_ip} && keys %accept) {
        # warn(__PACKAGE__." handling for IP ".$r->connection->remote_ip." refused by AddAcceptForwarder directive") if $TRACE;
        return DECLINED;
    }

    # Extract the desired IP address
    if (my($ip) = $fwd_ips =~ /^([\d\.]+)/) {
        # warn(__PACKAGE__." original remote_ip: ".$r->connection->remote_ip) if $TRACE;
        Apache->connection->remote_ip($ip);
        # warn(__PACKAGE__." new remote_ip: ".$r->connection->remote_ip) if $TRACE;
    } else {
        # do nothing if no ip is in forwarded-for header
        # warn(__PACKAGE__." remote_ip: $ip unchanged") if $TRACE;
    }

    # Return declined to continue handling at this phase...
    DECLINED;

}


=head1 NAME

Apache::ForwardedFor - Re-set remote_ip to incoming client's ip when running mod_perl behind a reverse proxy server. 
In other words, copy the first IP from B<X-Forwarded-For> header, which was set by your reverse proxy server, 
to the B<remote_ip> connection property.

=head1 SYNOPSIS

  in httpd.conf

  PerlModule                 Apache::ForwardedFor
  PerlPostReadRequestHandler Apache::ForwardedFor

  PerlSetVar  ForwardedForAccept 192.168.1.1
  PerlAddVar  ForwardedForAccept 192.168.1.2

=head1 DESCRIPTION

We often want to run Apache behind a reverse proxy so that we
can delegate light-weight (static content) requests to a small
httpd and proxy heavy-weight requests (dynamic mod_perl generated
content) to a big httpd. This is a well known technique to overcome
the memory contraints of running a busy mod_perl site.

A small problem when doing this is that our "remote_ip" for the
backend (mod_perl) httpd is that of the front-end proxy'ing httpd.
This is not a good representation of the end client's real IP
address - making it difficult to implement IP-based access control
and tracking usage through your logs.

Before: 

 +--------+     +-------------+     +----------------+
 | Client | <-> | httpd/proxy | <-> | httpd/mod_perl |
 +--------+     +-------------+     +----------------+
  My IP           My IP               My IP
   2.3.4.5         2.9.1.2             192.168.1.2
                  remote_ip           remote_ip
                   2.3.4.5             2.9.1.2

After:

 +--------+     +-------------+     +----------------+
 | Client | <-> | httpd/proxy | <-> | httpd/mod_perl |
 +--------+     +-------------+     +----------------+
  My IP           My IP               My IP
   2.3.4.5         2.9.1.2             192.168.1.2
                  remote_ip           remote_ip
                   2.3.4.5             2.3.4.5

This program takes advantage of the existance of the X-Forwarded-For
or header which is automatically added by software such as mod_proxy and Squid.
Obviously you can imagine that if a savvy user sets their own X-Forwarded-For
header that they could potentially be considered coming from a trusted
IP.

To ensure some measure of security: 1 - make sure you can trust the 
httpd/proxy machine (ie/ its in your organization); 2 - set this module to 
accept X-Forwarded-For headers only from this machine.

From my understanding of the X-Forwarded-For header - each proxy server
will prepend the remote_ip to this header. That means that if the request passes
through several proxies we want to pick up only the last proxy's change - which
is the first IP found in this header.

=head1 USAGE

At this time you simply need to load the module and add it to the
PerlPostReadRequestHandler phase of your mod_perl-enabled httpd.

=head1 APACHE CONFIGURATION

The following can be set using either the B<PerlSetVar> or B<PerlAddVar> directives.

i.e.
  PerlSetVar ForwardedForDeny      127.0.0.1
  PerlAddVar ForwardedForAccept    192.168.1.1
  PerlAddVar ForwardedForAccept    192.168.1.2
  PerlAddVar ForwardedForAccept    192.168.1.3

=head2 ForwardedForAccept IPaddress

By using either the B<PerlSetVar> or B<PerlAddVar> directive you can
list hosts for which we will only be allowing handling of Forwarded headers from.

That means if you put one host in this list then all non-listed hosts
will be blocked.

B<Netblocks> are not supported at this time - you must supply the
full IP address.

=head2 ForwardedForDeny

By using either the B<PerlSetVar> or B<PerlAddVar> directive you can
list hosts for which we will be blocking handling of Forwarded headers from.

This means that all hosts except the ones listed here will be accepted
for processing.

B<Netblocks> are not supported at this time - you must supply the
full IP address.

B<N.B.> - if you specify both Accept and Deny items then you effectively
follow the logic of Deny first, then Accept afterwards. This is virtually
pointless but will be more useful when/if netblock support is added.

=head1 BUGS

Please report your bugs and suggestions for improvement to 
info@infonium.com ... For faster service please in
clude "Apache::ForwardedFor" and "bug" in your subject line.

I have not yet found written documentation on the usage of the X-Forwarded-For
header. My implementation assumes that the first IP in the incoming header
is for your (the most recent) proxy server.

=head1 SUPPORT

For technical support please email to
info@infonium.com ... for faster service please in
clude "Apache::ForwardedFrom" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.com/perl

=head1 COPYRIGHT

Copyright (c) 2002 Jay J. Lawrence. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

 ahosey@systhug.com - mod_extract_forwarded
 Vivek Khera        - Apache::HeavyCGI::SquidRemoteAddr

=head1 SEE ALSO

perl, mod_perl, mod_extract_forwarded.

=cut

1; 


