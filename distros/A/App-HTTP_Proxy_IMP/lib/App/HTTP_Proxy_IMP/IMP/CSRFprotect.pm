# PoC for CSRF protection
# see pod at the end for detailed description of the idea and references

use strict;
use warnings;
package App::HTTP_Proxy_IMP::IMP::CSRFprotect;
use base 'Net::IMP::HTTP::Request';
use fields (
    'target',       # target domain from request header
    'origin',       # domain from origin/referer request header
);

use Net::IMP qw(:DEFAULT :log);
use Net::IMP::Debug;
use Net::IMP::HTTP;

sub RTYPES { return (
    IMP_REPLACE, # remove Cookie/Authorization header
    IMP_LOG,     # log if we removed something
    IMP_DENY,    # bad requests/responses
    IMP_PASS,
)}

sub new_analyzer {
    my ($class,%args) = @_;
    my $self = $class->SUPER::new_analyzer(%args);
    $self->run_callback(
	# we will not modify response, but need to look at the response
	# header to detect redirects. After the response header was seen
	# this will be upgraded to IMP_PASS
	[ IMP_PREPASS,1,IMP_MAXOFFSET]
    );
    return $self;
}

sub request_hdr {
    my ($self,$hdr) = @_;
    # modify if necessary, rest of request can be forwarded w/o inspection
    my $len = length($hdr);
    my @rv;
    if ( defined( my $newhdr = _modify_rqhdr($self,$hdr))) {
	push @rv, [ IMP_REPLACE,0,$len,$newhdr ];
    }
    $self->run_callback(@rv,[ IMP_PASS,0,IMP_MAXOFFSET ]);
}

sub response_hdr {
    my ($self,$hdr) = @_;
    # response header
    _analyze_rphdr($self,$hdr);
    $self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]); # upgrade to IMP_PASS
}


{
    # FIXME - should expire after a short time
    # FIXME - for multi-process environments it needs to be shared 
    #         between processes
    # DELEGATION{FROM}{TO}: e.g. FROM delegated to TO by
    #  - having a POST request to TO with origin/referer FROM
    #  - having a redirect to TO in response from FROM
    my %DELEGATION; 

    sub _delegate {
	my ($origin,$target,$why) = @_;
	if ( $DELEGATION{$origin}{$target} ) {
	    debug("refresh delegation $origin -> $target ($why)");
	    $DELEGATION{$origin}{$target} = 1;
	} else {
	    debug("add delegation $origin -> $target ($why)");
	    $DELEGATION{$origin}{$target} = 1;
	}
    }

    sub _delegation_exists {
	my ($origin,$target) = @_;
	return $DELEGATION{$origin}{$target};
    }
}

# extract target and origin domain
# if they differ remove cookies and authorization infos unless we have
#   an established trust between these domains
my $rx_host = qr{([\w\-.]+|\[[\da-fA-F:.]+\])};
my $rx_host_from_url = qr{^https?://$rx_host};
sub _modify_rqhdr {
    my ($self,$hdr) = @_;
    
    # determine target
    my (@target) = $hdr =~m{\A\w+[ \t]+http://$rx_host};
    @target = _gethdr($hdr,'Host',$rx_host) if ! @target;
    if ( ! @target or @target>1 ) {
	$self->run_callback(
	    [ IMP_LOG,0,0,0,IMP_LOG_WARNING,
		"cannot determine target from request\n".$hdr ],
	    [ IMP_DENY,0, "cannot determine target from request" ]
	);
	return;
    }

    # determine referer/origin domain
    my @origin = _gethdr($hdr,'Origin',$rx_host_from_url);
    @origin = _gethdr($hdr,'Referer',$rx_host_from_url) if ! @origin;
    if ( @origin > 1 ) {
	# invalid: conflicting origins
	$self->run_callback(
	    [ IMP_LOG,0,0,0,IMP_LOG_WARNING,
		"conflicting origins in request\n".$hdr ],
	    [ IMP_DENY,0, "conflicting origins in request" ]
	);
	return;
    }

    if ( ! @origin ) {
	# we have no origin to check trust inside request
	debug("no origin to check trust in request to @target");

    } else {
	# do nothing unless the request is cross-origin
	$self->{origin} = $origin[0];
	$self->{target} = $target[0];
	return if $origin[0] eq $target[0];

	# implicite trust when both have the same root-domain
	my $origin = _rootdom($origin[0]);
	my $target = _rootdom($target[0]);
	if ( $origin eq $target ) {
	    debug("trusted request from $origin[0] to $target[0] (same root-dom)");
	    return 
	}

	# check if this is a delegation (POST)
	if ( $hdr =~m{\APOST } ) {
	    _delegate($origin,$target,'POST');
	}

	# consider the request trused if we got an earlier delegation from 
	# $target to $origin (e.g. in the other direction)
	if ( _delegation_exists($target,$origin)) {
	    debug("trusted request from $origin to $target (earlier delegation)");
	    return 
	}
    }

    # remove cookies, because there is no cross-domain trust
    # we should remove authorization header too, but then access to the
    # protected site will probably not be available at all (see BUGS section)
    my @del;
    push @del,$1 while ( $hdr =~s{^(Cookie|Cookie2):[ \t]*(.*(?:\n[ \t].*)*)\n}{}im );
    if (@del) {
	$self->run_callback([ 
	    IMP_LOG,0,0,0,IMP_LOG_INFO,
	    "removed cross-origin session credentials (@del) for request @origin -> @target" 
	]);
	# return changed header
	return $hdr; 
    }

    # nothing changed
    return undef;
}

# find out if response header contains delegation through a redirect
sub _analyze_rphdr {
    my ($self,$hdr) = @_;
    # we are only interested in temporal redirects
    $hdr =~m{\AHTTP/1\.[01] 30[237]} or return; 

    my @location = _gethdr($hdr,'Location',$rx_host_from_url)
	or return; # no redirect
    if ( @location > 1 ) {
	# invalid: multiple conflicting redirects
	$self->run_callback(
	    [ IMP_LOG,0,0,0,IMP_LOG_WARNING,
		"conflicting redirects in response\n".$hdr ],
	    [ IMP_DENY,0, "conflicting redirects in response" ]
	);
	return;
    }
    my $location = $location[0];
    my $target   = $self->{target} or return;
    return if $target eq $location; # no cross-domain

    $target   = _rootdom($target);
    $location = _rootdom($location);
    return if $target eq $location; # not considered cross-domain too

    _delegate($target,$location,'redirect');
}

sub _gethdr {
    my ($hdr,$key,$rx) = @_;
    my @val;
    for ( $hdr =~m{^\Q$key\E:[ \t]*(.*(?:\n[ \t].*)*)}mgi ) {
	s{\r\n}{}g; 
	s{\s+$}{}; 
	s{^\s+}{};
	push @val, m{$rx};
    }
    my %v;
    return grep { ! $v{$_}++ } @val;
}

BEGIN {
    if ( eval { require WWW::CSP::PublicDNSSuffix } ) {
	*_rootdom = sub {
	    my ($rest,$tld) = WWW::CSP::PublicDNSSuffix::public_suffix( shift );
	    return $rest =~m{([^.]+)$} ? "$1.$tld" : undef;
	}
    } elsif ( eval { require Mozilla::PublicSuffix }) {
	*_rootdom = sub {
	    my $host = shift;
	    my $suffix = Mozilla::PublicSuffix::public_suffix($host);
	    return $host =~m{([^\.]+\.\Q$suffix)} ? $1:undef,
	}
    } elsif ( my $suffix = eval { 
	require Domain::PublicSuffix; 
	Domain::PublicSuffix->new 
    }) {
	*_rootdom = sub { return $suffix->get_root_domain( shift ) }
    } else {
	die "need one of Domain::PublicSuffix, Mozilla::PublicSuffix or WWW::CSP::PublicDNSSuffix"
    }
}

1;
__END__

=head1 NAME

App::HTTP_Proxy_IMP::IMP::CSRFprotect - IMP plugin against CSRF attacks

=head1 DESCRIPTION

This plugin attempts to block malicious cross-site requests (CSRF), by removing
session credentials (Cookie, Cookie2 and Authorization header) from the request,
if the origin of the request is not known or not trusted.
The origin is determined by checking the Origin or the Referer HTTP-header of
the request.

An origin O is considered trusted to issue a cross-site request to target T, if

=over 4

=item * 

O is the same as T

=item *

O and T share the same root domain (which should not be a public suffix)

=item *

there was an earlier delegation from T to O

=back

Delegation from T to O means, that

=over 4

=item *

a POST request to target O with origin T

=item *

or a redirect to O within the HTTP response from T

=back

This module is based on ideas described 2011 in the paper
"Automatic and Precise Client-Side Protection against CSRF Attacks" from
Philippe De Ryck, Lieven Desmet, Wouter Joosen, and Frank Piessens.

=head1 BUGS

This module is a proof of concept.

Contrary to the initial goal, currently no Authorization HTTP header will be
removed. While for session authorization with cookies, there is a fallback page
on failed authorization, no such page exists for HTTP authorization.
Instead the HTTP server will issue again and again "407 authorization required"
because the request would still be Cross-Site or No-Site (e.g. no Origin/Referer
header) and thus CSRF protection would apply.
This would not only stop cross-site accesses to the protected site completly,
but also access from bookmarks et. al. (e.g. No-Site request).

Missing essential functionality is the expiring of information about previous
delegations after a short time, so that they need to be refreshed before the
next cross-site request is allowed.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
