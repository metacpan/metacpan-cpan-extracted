package DMTF::WSMan;

use warnings;
use strict;

use version; 
our $VERSION = qv('0.05');
use LWP;
use LWP::Authen::Digest;
use Data::UUID;
use Carp;

# Module implementation here
# We make our own specialization of LWP::UserAgent that 
# uses the correct user ID and password
{
    package DMTF::WSMan::PRIVATE::RequestAgent;
    our @ISA = qw(LWP::UserAgent);

    sub new
    {
		my $class=shift;
		my $awo=shift;
		my $self = LWP::UserAgent::new($class, @_);
		$self->{ASSOCIATED_WSMAN_OBJECT}=$awo;
		return($self);
    }

    sub get_basic_credentials
    {
		my $self=shift;
		return($self->{ASSOCIATED_WSMAN_OBJECT}{Context}{user},$self->{ASSOCIATED_WSMAN_OBJECT}{Context}{pass});
    }
}

sub new
{
	my $self={};
	$self->{CLASS} = shift;
	my %args=@_;
	$self->{Context} = {
		user=>'Administrator',
		# password
		# host
		port=>623,
		protocol=>'http',
		xmlns=>{
			soap=>{prefix=>'s', uri=>'http://www.w3.org/2003/05/soap-envelope'},
			addressing=>{prefix=>'a', uri=>'http://schemas.xmlsoap.org/ws/2004/08/addressing'},
			enumeration=>{prefix=>'n', uri=>'http://schemas.xmlsoap.org/ws/2004/09/enumeration'},
			wsman=>{prefix=>'w', uri=>'http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd'},
			cim=>{prefix=>'c', uri=>'http://schemas.dmtf.org/wbem/wsman/1/cimbinding.xsd'}
		}
	};
	$self->{Context}{user} = $args{user} if(defined $args{user});
	$self->{Context}{port} = $args{port} if(defined $args{port});
	$self->{Context}{protocol} = $args{protocol} if(defined $args{protocol});
	$self->{Context}{pass} = $args{pass} if(defined $args{pass});
	$self->{Context}{host} = $args{host} if(defined $args{host});
	$self->{RA} = DMTF::WSMan::PRIVATE::RequestAgent->new($self, keep_alive=>1);
	$self->{challenge_str}=undef;
	$self->{UUID} = Data::UUID->new();
	bless($self, $self->{CLASS});
	return($self);
}

sub invoke
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp "No EPR specified";
		return;
	}
	my $postdata;

	if(defined $args{method}) {
		$postdata=$self->_genheaders($args{epr}{ResourceURI}."/".$args{method},$args{epr});
	}
	else {
		$postdata=$self->_genheaders($args{epr}{ResourceURI},$args{epr});
	}
	$postdata .= "<$self->{Context}{xmlns}{soap}{prefix}:Body>";
	$postdata .= $args{body};
	$postdata .= "</$self->{Context}{xmlns}{soap}{prefix}:Body></$self->{Context}{xmlns}{soap}{prefix}:Envelope>";

	my $res = $self->_request($postdata);
	return $res->content;
}

sub put
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp('No EPR specified');
		return;
	}

	my $postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/transfer/Put',$args{epr});
	$postdata .= "<$self->{Context}{xmlns}{soap}{prefix}:Body>".$args{body}."</$self->{Context}{xmlns}{soap}{prefix}:Body></$self->{Context}{xmlns}{soap}{prefix}:Envelope>";

	my $res = $self->_request($postdata);
	return $res->content;
}

sub create
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp('No EPR specified');
		return;
	}

	my $postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/transfer/Create',$args{epr});
	$postdata .= "<$self->{Context}{xmlns}{soap}{prefix}:Body>".$args{body}."</$self->{Context}{xmlns}{soap}{prefix}:Body></$self->{Context}{xmlns}{soap}{prefix}:Envelope>";

	my $res = $self->_request($postdata);
	return $res->content;
}

sub get
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp('No EPR specified');
		return;
	}
	my $postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/transfer/Get',$args{epr});
	$postdata .= <<ENDOFREQUEST;
  <$self->{Context}{xmlns}{soap}{prefix}:Body/>
</$self->{Context}{xmlns}{soap}{prefix}:Envelope>
ENDOFREQUEST

	my $res = $self->_request($postdata);
	return($res->content);
}

sub delete
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp('No EPR specified');
		return;
	}
	my $postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete',$args{epr});
	$postdata .= <<ENDOFREQUEST;
  <$self->{Context}{xmlns}{soap}{prefix}:Body/>
</$self->{Context}{xmlns}{soap}{prefix}:Envelope>
ENDOFREQUEST

	my $res = $self->_request($postdata);
	return($res->content);
}

sub enumerate
{
	my $self=shift;
	my %args=@_;
	if(!defined $args{epr}) {
		carp('No EPR specified');
		return;
	}

	$args{mode} = 'EnumerateObjectAndEPR' if(!defined $args{mode});
	$args{filter} = '' if(!defined $args{filter});
	my $cnt;
	my $results='';

	my $postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/enumeration/Enumerate',$args{epr});
	$postdata.=<<ENDOFREQUEST;
  <$self->{Context}{xmlns}{soap}{prefix}:Body>
    <$self->{Context}{xmlns}{enumeration}{prefix}:Enumerate>
      <$self->{Context}{xmlns}{wsman}{prefix}:OptimizeEnumeration/>
      <$self->{Context}{xmlns}{wsman}{prefix}:MaxElements>10000</$self->{Context}{xmlns}{wsman}{prefix}:MaxElements>
      <$self->{Context}{xmlns}{wsman}{prefix}:EnumerationMode>$args{mode}</$self->{Context}{xmlns}{wsman}{prefix}:EnumerationMode>$args{filter}
    </$self->{Context}{xmlns}{enumeration}{prefix}:Enumerate>    
  </$self->{Context}{xmlns}{soap}{prefix}:Body>
</$self->{Context}{xmlns}{soap}{prefix}:Envelope>
ENDOFREQUEST

	my $res = $self->_request($postdata);
	if($res->content=~/EnumerationContext(?:\s+[^>]*)?>([^<]*)</s) {
		$cnt=$1;
	}
	$results .= $res->content;
	undef $cnt if($res->content=~/<[^:>]+:EndOfSequence[\s\/>]/s);

	while(defined $cnt) {
		$postdata=$self->_genheaders('http://schemas.xmlsoap.org/ws/2004/09/enumeration/Pull',$args{epr});
		$postdata.=<<ENDOFREQUEST;
  <$self->{Context}{xmlns}{soap}{prefix}:Body>
	<$self->{Context}{xmlns}{enumeration}{prefix}:Pull>
	  <$self->{Context}{xmlns}{enumeration}{prefix}:EnumerationContext>$cnt</$self->{Context}{xmlns}{enumeration}{prefix}:EnumerationContext>
	  <$self->{Context}{xmlns}{enumeration}{prefix}:MaxElements>10000</$self->{Context}{xmlns}{enumeration}{prefix}:MaxElements>
	</$self->{Context}{xmlns}{enumeration}{prefix}:Pull>
  </$self->{Context}{xmlns}{soap}{prefix}:Body>
</$self->{Context}{xmlns}{soap}{prefix}:Envelope>
ENDOFREQUEST

		$res = $self->_request($postdata);
		if($res->content=~/EnumerationContext(?:\s+[^>]*)?>([^<]*)</s) {
			$cnt=$1;
		}
		else {
			undef $cnt;
		}
		undef $cnt if($res->content=~/<[^:>]+:EndOfSequence[\s\/>]/s);
		# TODO: Normalize namespaces
		$results .= $res->content;
	}

	return($results);
}


###################
# Utility methods #
###################

sub get_selectorset_xml
{
	my $self=shift;
	my $epr=shift;
	my $selectorset='';

	if(defined $epr->{SelectorSet}) {
		$selectorset = "    <$self->{Context}{xmlns}{wsman}{prefix}:SelectorSet>\n";
		foreach my $name (keys %{$epr->{SelectorSet}}) {
			$selectorset .= "      <$self->{Context}{xmlns}{wsman}{prefix}:Selector Name=\"$name\">";
			if(ref($epr->{SelectorSet}{$name}) eq 'HASH') {
				$selectorset .= $self->epr_to_xml($epr->{SelectorSet}{$name});
			}
			else {
				$selectorset .= _XML_escape($epr->{SelectorSet}{$name});
			}
			$selectorset .= "</$self->{Context}{xmlns}{wsman}{prefix}:Selector>\n";
		}
		$selectorset .= "    </$self->{Context}{xmlns}{wsman}{prefix}:SelectorSet>\n";
	}
	$selectorset = "\n$selectorset" if($selectorset ne '');

	return $selectorset;
}

sub epr_to_xml
{
	my $self=shift;
	my $epr=shift;
	my $selectorset=$self->get_selectorset_xml($epr);

return <<EOF;
			<$self->{Context}{xmlns}{addressing}{prefix}:EndpointReference>
				<$self->{Context}{xmlns}{addressing}{prefix}:Address>http://$self->{Context}{host}:$self->{Context}{port}/wsman</$self->{Context}{xmlns}{addressing}{prefix}:Address>
				<$self->{Context}{xmlns}{addressing}{prefix}:ReferenceParameters>
					<$self->{Context}{xmlns}{wsman}{prefix}:ResourceURI>$epr->{ResourceURI}</$self->{Context}{xmlns}{wsman}{prefix}:ResourceURI>
$selectorset
				</$self->{Context}{xmlns}{addressing}{prefix}:ReferenceParameters>
			</$self->{Context}{xmlns}{addressing}{prefix}:EndpointReference>
EOF
}

################
# Non-exported #
################
sub _XML_escape
{
	my $val=shift;
	$val=~s/&/&amp;/g;
	$val=~s/</&lt;/g;
	$val=~s/"/&quot;/g;
	$val=~s/'/&apos;/g;
	return $val;
}

sub _request
{
	my $self=shift;
	my $postdata=shift;

	my $req = HTTP::Request->new(POST => $self->{Context}{protocol}."://$self->{Context}{host}:$self->{Context}{port}/wsman");
	$req->header('Content-Type', 'application/soap+xml;charset=UTF-8');
	$req->header('Content-Length', length $postdata);  # Not really needed
	$req->content($postdata);
	return $self->_authenticated_request($req);
}

sub _genheaders
{
	my $self=shift;
	my $action=shift;
	my $epr=shift;
	my $selectorset=$self->get_selectorset_xml($epr);

	my $postdata="<$self->{Context}{xmlns}{soap}{prefix}:Envelope";
	foreach my $ns (keys %{$self->{Context}{xmlns}}) {
		$postdata .= "\n      xmlns:$self->{Context}{xmlns}{$ns}{prefix}=\"$self->{Context}{xmlns}{$ns}{uri}\"";
	}
	$postdata .= ">\n";
	my $uuid=$self->{UUID}->create_str();
	$postdata .= <<ENDOFREQUEST;
  <$self->{Context}{xmlns}{soap}{prefix}:Header>
    <$self->{Context}{xmlns}{addressing}{prefix}:To>$self->{Context}{protocol}://$self->{Context}{host}:$self->{Context}{port}/wsman</$self->{Context}{xmlns}{addressing}{prefix}:To>
    <$self->{Context}{xmlns}{wsman}{prefix}:ResourceURI s:mustUnderstand="true">$epr->{ResourceURI}</$self->{Context}{xmlns}{wsman}{prefix}:ResourceURI>
    <$self->{Context}{xmlns}{addressing}{prefix}:ReplyTo>
      <$self->{Context}{xmlns}{addressing}{prefix}:Address $self->{Context}{xmlns}{soap}{prefix}:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</$self->{Context}{xmlns}{addressing}{prefix}:Address>
    </$self->{Context}{xmlns}{addressing}{prefix}:ReplyTo>
    <$self->{Context}{xmlns}{addressing}{prefix}:Action $self->{Context}{xmlns}{soap}{prefix}:mustUnderstand="true">$action</$self->{Context}{xmlns}{addressing}{prefix}:Action>
    <$self->{Context}{xmlns}{addressing}{prefix}:MessageID>uuid:$uuid</$self->{Context}{xmlns}{addressing}{prefix}:MessageID>$selectorset
  </$self->{Context}{xmlns}{soap}{prefix}:Header>
ENDOFREQUEST
	return($postdata);
}

sub _authenticated_request
{
	my $self=shift;
	my $req=shift;

	if(defined $self->{challenge_str}) {
		my $challenge=$self->{challenge_str};

		$challenge =~ tr/,/;/;  # "," is used to separate auth-params!!
		($challenge) = HTTP::Headers::Util::split_header_words($challenge);
		$challenge = { @$challenge };  # make rest into a hash
		for (keys %$challenge) {       # make sure all keys are lower case
			$challenge->{lc $_} = delete $challenge->{$_};
		}
		my $res;
		if(exists $challenge->{digest}) {
			$res=LWP::Authen::Digest->authenticate($self->{RA}, undef, $challenge, undef, $req, undef, undef);
		}
		elsif(exists $challenge->{basic}) {
			$res=LWP::Authen::Basic->authenticate($self->{RA}, undef, $challenge, undef, $req, undef, undef);
		}
		else {
			$res=$self->{RA}->request($req);
		}
		if($res->code == 401) {
			$self->{challenge_str}=$res->www_authenticate;
			$res=$self->_authenticated_request($req);
			if($res->code == 200) {
				return($res);
			}
			else {
				print "!!!! Unable to authenticate!\n";
			}
		}
		$self->{challenge_str}=$res->previous->www_authenticate if(defined $res->previous && $res->code==200);
		return($res);
	}
	my $res=$self->{RA}->request($req);
	if($res->code == 501) {
		if($res->message =~ /SSLeay/) {
			print "SSL support requires Crypt::SSLeay to be installed.\n";
			print "Use the command \"ppm install http://theoryx5.uwinnipeg.ca/ppms/Crypt-SSLeay.ppd\"\n";
		}
	}
	$self->{challenge_str}=$res->previous->www_authenticate if(defined $res->previous && $res->code==200);
	return($res);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::WSMan - Implements the WS-Management Protocol


=head1 VERSION

This document describes DMTF::WSMan version 0.05


=head1 SYNOPSIS

  use DMTF::WSMan;

  my $wsman = DMTF::WSMan->new(user=>'user', pass=>'pass', port=623, protocol='http', host='example.com');
  my $xml = $wsman->get( epr=>{
      ResourceURI=>'http://example.org/management/instance',
      SelectorSet=>{
          ID=>'Instance21',
      },
  });
  
=head1 DESCRIPTION

This module provides access to the WS-Management protocol, but is not
intended to be used directly.  The returns types are generally XML strings
as are many of the arguments.  Refer to DMTF::CIM for full usage.


=head1 INTERFACE 

Many of the following methods take an EPR argument.  The EPR is simply a hashref
with at least a ResourceURI element and optionally a SelectorSet hashref element.

=head2 METHODS

=over

=item C<< new( [user=>I<user>,] [pass=>I<password>,] [port=>I<port>,] [protocol=I<protocol>,] [host=>I<hostname>,] ); >>

Creates a new WS-Management context optionally specifying various
connection parameters.

=over

=item C<< user=>I<user> >> (default is 'Administrator')

Specifies the user ID to use with autentication.

=item C<< pass=>I<password> >>

Specifies the password to use with autentication.

=item C<< host=>I<hostname> >> (no default)

Specifies the host that will be connected to.

=item C<< port=>I<port> >> (default is 623)

Sets the TCP port that will be connected to.

=item C<< protocol=>I<protocol> >> (default is 'http')

Specifies the HTTP protocol that will be used.  Valid values are:

=over

=item http  - Uses plain-text HTTP protocol

=item https - Uses HTTP over TLS for an encrypted session

=back

=back

=item C<< get( epr=>I<epr> ) >>

Returns the response from a Get operation.

=item C<< put( epr=>I<epr>, body=>I<object> ) >>

Returns the response from a Put operation.  The body argument is the
complete contents of the SOAP body element.

=item C<< delete( epr=>I<epr> ); >>

Returns the response from a Delete operation.

=item C<< create( epr=>I<epr>, body=>I<object> ); >>

Returns the response from a Create operation.  The body argument is the
complete contents of the SOAP body element.

=item C<< invoke( epr=>I<epr>, body=>I<object>, method=>I<method> ); >>

Returns the response from a custom method invocation.  When a method
is provided, the action is constructed by appending "/" and the specified method to the
end of the ResourceURI in the EPR.

=item C<< enumerate( epr=>I<epr>, filter=>I<filterxml>, mode=>I<EnumerateObjects> ); >>

Returns all the responses to both an Emumerate and all the successive
Pull operations to complete an enumeration.

The filter is included directly in the XML so must include the
appropriate filter tags.

Mode specifies the enumeration mode.  Available values are:
'EnumerateObject', 'EnumerateEPR', 'EnumerateObjectAndEPR'

=item C<< get_selectorset_xml( I<epr> ) >>

Returns an XML representation of the SelectorSet tag constructed from the
passed EPR using the same XML namespaces and prefixes that will be used in
the actual message.

=item C<< epr_to_xml( I<epr> ) >>

Returns an XML representation constructed from the passed EPR using the
same XML namespaces and prefixes that will be used in the actual message.

=back

=head1 DIAGNOSTICS

This module will carp() on errors and return undef or an empty list.


=head1 CONFIGURATION AND ENVIRONMENT

DMTF::WSMan requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item L<Data::UUID>          (available from CPAN)

=item L<LWP>                 (part of perl libwww)

=item L<LWP::Authen::Digest> (part of perl libwww)

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dmtf-wsman@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stephen James Hurd  C<< <shurd@broadcom.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Broadcom Corporation C<< <shurd@broadcom.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
