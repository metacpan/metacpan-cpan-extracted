package DNS::WorldWideDns;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.0102';
}


use strict;
use Class::InsideOut qw(readonly private id register);
use Exception::Class (
        'Exception' => {
            description => 'A general error.',
        },

        'MissingParam' => {
            isa         => 'Exception',
            description => 'Expected a parameter that was not specified.',
        },

        'InvalidParam' => {
            isa         => 'Exception',
            description => 'A parameter passed in did not match what it was supposed to be.',
            fields      => [qw(got)],
        },

        'InvalidAccount' => {
            isa         => 'RequestError',
            description => 'Authentication failed.',
        },

        'RequestError' => {
            isa         => 'Exception',
            description => 'Something bad happened during the request.',
            fields      => [qw(url response code)],
        },

    );
use HTTP::Request;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

readonly username => my %username;
readonly password => my %password;



=head1 NAME

DNS::WorldWideDns - An interface to the worldwidedns.net service.

=head1 SYNOPSIS

 use DNS::WorldWideDns;
 
 $dns = DNS::WorldWideDns->new($user, $pass);
 
 $hashRef = $dns->getDomains;
 $hashRef = $dns->getDomain($domain);
 
 $dns->addDomain($domain);
 $dns->updateDomain($domain, $properties);
 $dns->deleteDomain($domain);

=head1 DESCRIPTION

This module allows you to dynamically create, remove, update, delete, and report on domains hosted at L<http://www.worldwidedns.net>. It makes working with their sometimes obtuse, but very useful, DNS API protocol (L<http://www.worldwidedns.net/dns_api_protocol.asp>) a breeze.

=head1 USAGE

The following methods are available from this class:

=cut


###############################################################

=head2 addDomain ( domain, [ isPrimary, isDynamic ] )

Adds a domain to your account. Throws MissingParam, InvalidParam, InvalidAccount and RequestError.

B<NOTE:> You should use updateDomain() directly after adding a domain to give it some properties and records.

Returns a 1 on success.

=head3 domain

A domain to add.

=head3 isPrimary

A boolean indicating if this is a primary domain, or a secondary. Defaults to 1.

B<NOTE:> This module currently only supports primary domains.

=head3 isDynamic

A boolean indicating whether this domain is to allow Dynamic DNS ip updating. Defaults to 0.

=cut

sub addDomain {
    my ($self, $domain, $isPrimary, $isDynamic) = @_;
	unless (defined $domain) {
        MissingParam->throw(error=>'Need a domain.');
    }
	unless ($domain =~ m{^[\w\-\.]+$}xms) {
        InvalidParam->throw(error=>'Domain is improperly formatted.', got=>$domain);
    }
    my $primary = ($isPrimary eq "" || $isPrimary == 1) ? 0 : 1;
    my $dynamic = ($isDynamic eq "" || $isDynamic == 0) ? 1 : 2;
    my $url = 'https://www.worldwidedns.net/api_dns_new_domain.asp?NAME='.$self->username.'&PASSWORD='.$self->password.'&DOMAIN='.$domain.'&DYN='.$dynamic.'&TYPE='.$primary;
    my $response =  $self->makeRequest($url);
    my $content = $response->content;
    chomp $content;
    if ($content eq "200") {
        return 1;
    }
    elsif ($content eq "407") {
        RequestError->throw(
            error       => 'Account domain limit exceeded.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    elsif ($content eq "408") {
        RequestError->throw(
            error       => 'Domain already exists.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    elsif ($content eq "409") {
        RequestError->throw(
            error       => 'Domain banned by DNSBL.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    elsif ($content eq "410") {
        RequestError->throw(
            error       => 'Invalid domain name.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    RequestError->throw(
        error       => 'Got back an invalid response.',
        url         => $url,
        response    => $response,
    );     
}


###############################################################

=head2 deleteDomain ( domain )

Removes a domain from your account. Throws MissingParam, InvalidParam, InvalidAccount and RequestError.

Returns a 1 on success.

=head3 domain

A domain to delete.

=cut

sub deleteDomain {
    my ($self, $domain) = @_;
	unless (defined $domain) {
        MissingParam->throw(error=>'Need a domain.');
    }
	unless ($domain =~ m{^[\w\-\.]+$}xms) {
        InvalidParam->throw(error=>'Domain is improperly formatted.', got=>$domain);
    }
    my $url = 'https://www.worldwidedns.net/api_dns_delete_domain.asp?NAME='.$self->username.'&PASSWORD='.$self->password.'&DOMAIN='.$domain;
    my $response =  $self->makeRequest($url);
    my $content = $response->content;
    chomp $content;
    if ($content eq "200") {
        return 1;
    }
    elsif ($content eq "405") {
        RequestError->throw(
            error       => 'Domain not in account.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    elsif ($content eq "406") {
        RequestError->throw(
            error       => 'Could not remove domain. Try again.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    RequestError->throw(
        error       => 'Got back an invalid response.',
        url         => $url,
        response    => $response,
    );     
}


###############################################################

=head2 getDomain ( domain, [ nameServer ] )

Retrieves the zone information about the domain. Throws MissingParam, InvalidParam, InvalidAccount and RequestError.

Returns a hash reference structure that looks like this:

 {
    hostmaster      => "you.example.com",
    refresh         => "86400",
    retry           => "1200",
    expire          => "186400",
    ttl             => "3600",
    secureTransfer  => "*",
    records         => []
 }

The hostmaster field is the email address of the person in charge of this domain. Note that it should use dot notation, so don't use an at (@) sign.

The refresh field tells a cache name server how often (in seconds) to request fresh data from the authoratative name server. Minimum 3600.

The retry field tells a cache name server how long to wait (in seconds) before attempting to retry a failed refresh. Minimum 3600.

The expire field tells a cache name server how old (in seconds) to let data become before discarding it. Minimum 3600.

The ttl (Time To Live) is the default value for records that don't have a TTL specified.

The secureTransfer parameter is an access control list for zone transfers. Asterisk (*) implies that anyone can do zone transfers. Otherwise it could be a list of IP addresses separated by spaces. Setting it to an empty string means no servers may do zone transfers on the domain.

The records field is an array reference of records attached to this domain. It looks something like this:

 [
    {
        name    => "smtp",
        ttl     => 3600,
        type    => "A",
        data    => "1.1.1.1"
    },
    {
        name    => "@",
        ttl     => 3600,
        type    => "MX",
        data    => "10 smtp.example.com"
    },
 ]

The name field is the subdomain or host name that will be prepended on to the domain. For example the "www" in "www.example.com". The at (@) symbol means the domain itself, which is why you can type google.com not just www.google.com. The asterisk (*) is a wildcard, which means if no matching records are found, use this record to service the request.

The ttl field tells a caching name server how long (in seconds) it may use this record before it has to fetch new information about it. Minimum 3600.

The type field is the domain record type defined in RFC1035. Common record types are A, CNAME, an MX.

The data field holds the data of the record. It's usually an ip address or a fully qualified host name.


=head3 domain

A domain to request information about.

=head3 nameServer

Defaults to 1. Choose from 1, 2, or 3. The number of the primary, secondary or tertiary name server.

=cut

sub getDomain {
    my ($self, $domain, $nameServer) = @_;
	unless (defined $domain) {
        MissingParam->throw(error=>'Need a domain.');
    }
	unless ($domain =~ m{^[\w\-\.]+$}xms) {
        InvalidParam->throw(error=>'Domain is improperly formatted.', got=>$domain);
    }
    $nameServer ||= 1;
    if ($nameServer =~ m/^\D+$/ || $nameServer > 3 || $nameServer < 0) {
        InvalidParam->throw(error=>'Name server must be a number between 1 and 3.', got=>$nameServer);
    }
    my $url = 'https://www.worldwidedns.net/api_dns_viewzone.asp?NAME='.$self->username.'&PASSWORD='.$self->password.'&DOMAIN='.$domain.'&NS='.$nameServer;
    my $response =  $self->makeRequest($url);
    my $content = $response->content;
    chomp $content;
    if ($content eq "405") {
        RequestError->throw(
            error       => 'Domain name could not be found.',
            url         => $url,
            code        => 405,
            response    => $response,
        );     
    }
    elsif ($content eq "450") {
        RequestError->throw(
            error       => 'Could not reach the name server.',
            url         => $url,
            code        => 450,
            response    => $response,
        );     
    }
    elsif ($content eq "451") {
        RequestError->throw(
            error       => 'No zone file for this domain on this name server.',
            url         => $url,
            code        => 451,
            response    => $response,
        );     
    }
    my %domain;
    
    # secure zone transfer
    if ($content =~ m{^;\s+SecureZT((?:\s?\d+\.\d+\.\d+\.\d+){0,})$}xmsi) {
        $domain{secureTransfer} = $1;
    }
    else {
        $domain{secureTransfer} = '*';
    }

    # hostmaster, refresh, retry, expires, ttl
    if ($content =~ m{^\@\s+IN\s+SOA\s+[\w\.\-]+\.\s+([\w\.\-]+)\.\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*$}xmsi) {
        $domain{hostmaster}     = $1;
        $domain{refresh}        = $2;
        $domain{retry}          = $3;
        $domain{expire}         = $4;
        $domain{ttl}            = $5;
    }
    
    # records
    while ($content =~ m{^(\@|\*|[\w\.\-]+)?\s+(\d+)?\s*(?:IN)?\s+(A|A6|AAAA|AFSDB|CNAME|DNAME|HINFO|ISDN|MB|MG|MINFO|MR|MX|NS|NSAP|PTR|RP|RT|SRV|TXT|X25)\s+(.*?)\s*$}xmsig) {
        push @{$domain{records}}, {
            name   => $1,
            ttl    => $2,
            type   => $3,
            data   => $4,
        };
    }
    
    return \%domain;
}


###############################################################

=head2 getDomains ( )

Returns a hash reference where the key is the domain and the value is either a 'Primary' or an 'Secondary'. Throws InvalidAccount and RequestError.

B<NOTE:> This module does not currently handle creating, reading, or updating secondary domains, but it may in the future, so this indicator is left in.

=cut

sub getDomains {
    my $self = shift;
    my $url = 'https://www.worldwidedns.net/api_dns_list.asp?NAME='.$self->username.'&PASSWORD='.$self->password;
    my $content = $self->makeRequest($url)->content; 
    my %domains;
    while ($content =~ m{([\w+\.\-]+)\x1F(P|S)}xmsig) {
        my $type = ($2 eq 'P') ? 'Primary' : 'Secondary';
        $domains{$1} = $type;
    }
    return \%domains;
}


###############################################################

=head2 makeRequest ( url, [ request ] )

Makes a GET request. Returns the HTTP::Response from the request. Throws MissingParam, InvalidParam, InvalidAccount and RequestError.

B<NOTE:> Normally you never need to use this method, it's used by the other methods in this class. However, it may be useful in subclassing this module.

=head3 url

The URL to request.

=head3 request

Normally an HTTP::Request object is created for you on the fly. But if you want to make your own and pass it in you are welcome to do so.

=cut

sub makeRequest {
    my ($self, $url, $request) = @_;
	unless (defined $url) {
        MissingParam->throw(error=>'Need a url.');
    }
	unless ($url =~ m{^https://www.worldwidedns.net/.*$}xms) {
        InvalidParam->throw(error=>'URL is improperly formatted.', got=>$url);
    }
    $request ||= HTTP::Request->new(GET => $url);
    my $ua = LWP::UserAgent->new;
    my $response = $ua->request($request);
    
    # request is good
    if ($response->is_success) {
        my $content = $response->content;
        chomp $content;
        
        # is our account still active
        if ($content eq "401") {
            InvalidAccount->throw(
                error       => 'Login suspended.',
                url         => $url,
                code        => 401,
                response    => $response,
            );
        }
        
        # is our user/pass good
        elsif ($content eq "403") {
            InvalidAccount->throw(
                error       => 'Invalid user/pass combination.',
                url         => $url,
                code        => 403,
                response    => $response,
            );
        }
        
        # we're good, let's get back to work
        return $response;
    }
    
    # the request went totally off the reservation
    RequestError->throw(
        error       => $response->message,
        url         => $url,
        response    => $response,
    );

}

###############################################################

=head2 new ( username, password )

Constructor. Throws MissingParam.

=head3 username

Your worldwidedns.net username.

=head3 password

The password to go with username.

=cut

sub new {
    my ($class, $username, $password) = @_;

	# validate
	unless (defined $username) {
        MissingParam->throw(error=>'Need a username.');
    }
    unless (defined $password) {
        MissingParam->throw(error=>'Need a password.');
    }

	# set up object
	my $self = register($class);
	my $refId = id $self;
	$username{$refId} = $username;
	$password{$refId} = $password;
	return $self;
}

###############################################################

=head2 password ()

Returns the password set in the constructor.

=cut

###############################################################

=head2 updateDomain ( domain, params )

Updates a domain in your account. Throws MissingParam, InvalidParam, InvalidAccount and RequestError.

Returns a 1 on success.

=head3 domain

A domain to update.

=head3 params

A hash reference identical to the one returned by getDomain().

=cut

sub updateDomain {
    my ($self, $domain, $params) = @_;
    
    # validate inputs
	unless (defined $domain) {
        MissingParam->throw(error=>'Need a domain.');
    }
	unless ($domain =~ m{^[\w\-\.]+$}xms) {
        InvalidParam->throw(error=>'Domain is improperly formatted.', got=>$domain);
    }
	unless (defined $params) {
        MissingParam->throw(error=>'Need parameters hash ref to set on the domain.');
    }
	unless (ref $params eq 'HASH') {
        InvalidParam->throw(error=>'Expected a params hash reference.', got=>$params);
    }

    # zone data
    my $zoneData;
    foreach my $record (@{$params->{records}}) {
        $zoneData .= join(" ", $record->{name}, $record->{ttl}, 'IN', $record->{type}, $record->{data})."\r\n";
    }

    # make request
    my $url = 'https://www.worldwidedns.net/api_dns_modify_raw.asp';
    my $request = POST $url, [
        NAME        => $self->username,
        PASSWORD    => $self->password,
        DOMAIN      => $domain,
        HOSTMASTER  => $params->{hostmaster},
        REFRESH     => $params->{refresh},
        RETRY       => $params->{retry},
        SECURE      => $params->{secureTransfer},
        EXPIRE      => $params->{expire},
        TTL         => $params->{ttl},
        FOLDER      => '',
        ZONENS      => 'ns1.worldwidedns.net',
        ZONEDATA    => $zoneData,
        ];
    
    my $response =  $self->makeRequest($url, $request);
    my $content = $response->content;
    chomp $content;
    
    # interpret results
    if ($content =~ m{211\s*212\s*213}xmsi) {
        return 1;
    }
    elsif ($content eq "405") {
        RequestError->throw(
            error       => 'Domain not in account.',
            url         => $url,
            code        => $content,
            response    => $response,
        );     
    }
    RequestError->throw(
        error       => 'Updating one of the name servers failed.',
        url         => $url,
        code        => $content,
        response    => $response,
    );     
}

###############################################################

=head2 username ()

Returns the username set in the constructor.

=cut


=head1 EXCEPTIONS

This module uses L<Exception::Class> for exception handling. Each method is capable of throwing one or more of the following exceptions:

=head2 Exception
        
A general undefined error.

=head2 MissingParam

An expected parameter to a method was not passed.

=head2 InvalidParam

A parameter passed in doesn't match what was expected. This add a "got" field to the exception which contains what was received.

=head2 InvalidAccount

Authentication to worldwidedns.net failed.

=head2 RequestError

Some part of the request/response to worldwidedns.net did not go as expected. This adds url, response, and code fields to the exception.

The url field is the URL that was requested. This can be very helpful when debugging a problem.

The response field is the L<HTTP::Response> object that was returned from the request.

The code field is the error code number or numbers that were returned by the worldwidedns.net API. More informationa about them can be found in the DNS API protocol documentation pages (L<http://www.worldwidedns.net/dns_api_protocol.asp>).

=head1 BUGS

None known.

=head1 CAVEATS

This module is not feature complete with the API worldwidedns.net provides. It does your basic CRUD and that's it. They have other methods this doesn't use, and they have a whole reseller API which this doesn't support. If you need those features, patches are welcome.

=head1 AUTHOR

    JT Smith
    CPAN ID: RIZEN
    Plain Black Corporation
    jt_at_plainblack_com
    http://www.plainblack.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
# The preceding line will help the module return a true value

