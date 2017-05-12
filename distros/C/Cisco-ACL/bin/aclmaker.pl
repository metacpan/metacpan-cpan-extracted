#!/usr/bin/perl
#
# $Id: aclmaker.pl 86 2004-06-18 20:18:01Z james $
#

=head1 NAME

aclmaker.pl - simple CGI frontend to Cisco::ACL

=head1 DESCRIPTION

B<aclmaker.pl> is a simple CGI script that uses the Cisco::ACL module to
generate IOS access control lists.

The script is designed to emulate B<acl.pl>, which is the original script
that Cisco::ACL began life as. It is not meant to be in any way fancy or
suitable for embedding in a large web site. There is no taint checking
enabled, the content type of the output is C<text/plain>, etc, etc, etc.

=cut

use strict;
use warnings;

use Cisco::ACL;
use CGI;

# create a CGI object
my $cgi = CGI->new;

# output a header
print $cgi->header('text/plain');

# make sure we have all our args
for( qw|permit_or_deny protocol src_addr src_port dst_addr dst_port| ) {
    unless( $cgi->param($_) ) {
        print "missing input param $_\n";
        exit(0);
    }
}

# massage our input args a bit
my %params;
if( $cgi->param('permit_or_deny') eq 'permit' ) {
    $params{permit} = 1;
}
else {
    $params{permit} = 0;
}
if( $cgi->param('protocol') eq 'both' ) {
    $params{protocol} = 'ip';
}
else {
    $params{protocol} = $cgi->param('protocol');
}
for my $param( qw|src_addr src_port dst_addr dst_port| ) {
    $params{$param} = [ map { scalar(s/^\s+//, s/\s+$//, $_) }
        split(/,/, $cgi->param($param)) ];
}

# create a Cisco::ACL object
my $acl = Cisco::ACL->new( %params );

# get back the ACLs and print them out
if( my $acls = $acl->acls ) {
    for( @{ $acls } ) {
        print "$_\n";
    }
}
else {
    print "could not parse input parms\n";
}

__END__


=head1 INPUT PARAMETERS

aclmaker.pl takes six input arguments:

=over 4

=item * permit_or_deny

One of C<permit> or C<deny>.

=item * src_addr

Source and destination addresses may be specified in any combination of
three syntaxes: a single IP address, a range of addresses in the format
a.a.a.a-b.b.b.b or a.a.a.a-b, or a CIDR block in the format x.x.x.x/nn. You
may supply a comma-separated list of any or all of these formats. Use the
word "any" to specify all addresses. For example, all of the following are
legal:

  10.10.10.20
  10.10.10.10-200
  20.20.20.20-30.30.30.30
  10.10.10.20
  10.10.10.10-200
  10.10.10.10/8,45.45.45.45 

=item * src_port

Ports may be specified as a singe port, a range of ports in the form
xxxx-yyyy, or a comma separated list of any combination of those. The valid
range is 0-65535.

=item * dst_addr

As with src_addr but for the destination endpoint.

=item * dst_port

As with src_port but tor the destination endpoint.

=item * protocol

The protocol for the ACL. One of C<tcp>, C<udp> or C<ip>. For compatibility
the value C<both> is interpreted as C<ip>.

=back

=head1 OUTPUT

The output of aclmaker.pl is by design rather plain. Given the following
input parms:

=over 4

=item * permit_or_deny = deny

=item * src_addr = 192.168.0.1/24

=item * src_port = any

=item * dst_addr = any

=item * dst_port = 25

=item * protocol = tcp

=back

The output is:

  deny tcp 192.168.0.0 0.0.0.255 any eq 25
  
=head1 SEE ALSO

Cisco::ACL

=head1 AUTHOR

James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>.

Chris De Young (chd AT chud DOT net) wrote acl.pl, the guts of which are in
Cisco::ACL but the interface of which this script emulates.

=head1 COPYRIGHT

This module is free software.  You may use and/or modify it under the
same terms as perl itself.

=cut

#
# EOF
