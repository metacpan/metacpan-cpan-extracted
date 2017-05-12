package Akamai::Open::DiagnosticTools;
BEGIN {
  $Akamai::Open::DiagnosticTools::AUTHORITY = 'cpan:PROBST';
}
# ABSTRACT: The Akamai Open DiagnosticTools API Perl client
$Akamai::Open::DiagnosticTools::VERSION = '0.02';
use strict;
use warnings;
use v5.10;

use Moose;
use JSON;

#XXX create a useful scheme for REST methods
use constant {
    TOOLS_URI  => '/diagnostic-tools',
    DIG_URI    => '/v1/dig',
    MTR_URI    => '/v1/mtr',
    LOC_URI    => '/v1/locations'
};

extends 'Akamai::Open::Request::EdgeGridV1';

has 'tools_uri' => (is => 'ro', default => TOOLS_URI);
has 'dig_uri'   => (is => 'ro', default => DIG_URI);
has 'mtr_uri'   => (is => 'ro', default => MTR_URI);
has 'loc_uri'   => (is => 'ro', default => LOC_URI);
has 'baseurl'   => (is => 'rw', trigger => \&Akamai::Open::Debug::debugger);
has 'last_error'=> (is => 'rw');

sub validate_base_url {
    my $self = shift;
    my $base = $self->baseurl();
    $self->debug->logger->debug('validating baseurl');
    $base =~ s{/$}{} && $self->baseurl($base);
    return;
}
 
foreach my $f (qw/dig mtr locations/) {
    before $f => sub {
        my $self = shift;
        my $param = @_;

        $self->validate_base_url();
        my $uri = $self->baseurl() . $self->tools_uri();

        $self->debug->logger->debug("before hook called for $f") if($self->debug->logger->is_debug());

        #XXX create a useful scheme for REST methods
        given($f) {
            when($_ eq 'dig') {
                $uri .= $self->dig_uri();
                $self->request->method('GET');
            }
            when($_ eq 'mtr') {
                $uri .= $self->mtr_uri();
                $self->request->method('GET');
            }
            when($_ eq 'locations') {
                $uri .= $self->loc_uri();
                $self->request->method('GET');
            }
        }

        $self->debug->logger->info('filling request object with data');
        $self->request->uri(URI->new($uri));
    };
}

sub dig {
    my $self = shift;
    my $param = shift;
    my $valid_types_re = qr/^(?i:A|AAAA|PTR|SOA|MX|CNAME)$/;
    my $data;

    $self->debug->logger->debug('dig() was called');

    unless(ref($param)) {
        $self->last_error('parameter of dig() has to be a hashref');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'hostname'}) && defined($param->{'queryType'})) {
        $self->last_error('hostname and queryType are mandatory options for dig()');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless($param->{'queryType'} =~ m/$valid_types_re/) {
        $self->last_error('queryType has to be one of A, AAAA, PTR, SOA, MX or CNAME');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'location'}) || defined($param->{'sourceIp'})) {
        $self->last_error('either location or sourceIp has to be set');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    $self->request->uri->query_form($param);
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));

    $self->debug->logger->info(sprintf('HTTP response code for dig() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'dig'}->{'errorString'})) {
                $self->last_error($data->{'dig'}->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'dig'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

sub mtr {
    my $self = shift;
    my $param = shift;
    my $data;

    $self->debug->logger->debug('mtr() was called');

    unless(ref($param)) {
        $self->last_error('parameter of mtr() has to be a hashref');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'destinationDomain'})) {
        $self->last_error('destinationDomain is a mandatory options for mtr()');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    unless(defined($param->{'location'}) || defined($param->{'sourceIp'})) {
        $self->last_error('either location or sourceIp has to be set');
        $self->debug->logger->error($self->last_error());
        return(undef);
    }

    $self->request->uri->query_form($param);
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));

    $self->debug->logger->info(sprintf('HTTP response code for mtr() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'mtr'}->{'errorString'})) {
                $self->last_error($data->{'mtr'}->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'mtr'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

sub locations {
    my $self = shift;
    my $data;

    $self->debug->logger->debug('locations() was called');
    $self->sign_request();
    $self->response($self->user_agent->request($self->request()));
    $self->debug->logger->info(sprintf('HTTP response code for locations() call is %s', $self->response->code()));
    $data = decode_json($self->response->content());
    given($self->response->code()) {
        when($_ == 200) {
            if(defined($data->{'errorString'})) {
                $self->last_error($data->{'errorString'});
                $self->debug->logger->error($self->last_error());
                return(undef);
            } else {
                return($data->{'locations'});
            }
        }
        when($_ =~m/^5\d\d/) {
            $self->last_error('the server returned a 50x error');
            $self->debug->logger->error($self->last_error());
            return(undef);
        }
    }
    $self->last_error(sprintf('%s %s %s', $data->{'httpStatus'} ,$data->{'title'} ,$data->{'problemInstance'}));
    $self->debug->logger->error($self->last_error());
    return(undef);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Akamai::Open::DiagnosticTools - The Akamai Open DiagnosticTools API Perl client

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Akamai::Open::Client;
 use Akamai::Open::DiagnosticTools;

 my $client = Akamai::Open::Client->new();
 $client->access_token('foobar');
 $client->client_token('barfoo');
 $client->client_secret('Zm9vYmFyYmFyZm9v');

 my $diag = Akamai::Open::DiagnosticTools->new(client => $client);
 $diag->baseurl('http://mybaseurl.luna.akamaiapis.net');
 my $loc  = $diag->locations();
 my $dig  = $diag->dig({hostname => 'cpan.org', queryType => 'A', location => 'Frankfurt, Germany'});
 my $mtr  = $diag->mtr({destinationDomain => 'cpan.org', sourceIp => '23.62.61.24'});

=head1 ABOUT

I<Akamai::Open::DiagnosticTools> provides an API client for the 
Akamai Open DiagnosticTools API which is described L<here|https://developer.akamai.com/api/luna/diagnostic-tools/reference.html>.

=head1 USAGE

All API calls for the DiagnosticTools API are described and explained
at the L<Akamai Open DiagnosticTools API Portal|https://developer.akamai.com/api/luna/diagnostic-tools/reference.html>.

=head2 Akamai::Open::DiagnosticTools->new(client => $client)

For every I<Akamai::Open> API call you'll need some client credentials.
These are provided by the L<Akamai::Open:Client|http://search.cpan.org/perldoc?Akamai::Open::Client> 
module and can reviewed at the LUNA control center.

A succesfull call to I<new()> will return a I<Moose> powered 
I<Akamai::Open::DiagnosticTools> object.

=head2 $diag->baseurl($baseurl)

To successfully access an I<Akamai Open API> you'll need a baseurl, 
which is provided by the I<LUNA control center Manage API Portal> 
and is uniq to every configured API user and API itself.

I<baseurl()> is a I<Moose> powered getter/setter method, to set 
and receive the object's assigned baseurl.

=head2 $diag->locations()

To initiate diagnostinc actions inside the Akamai network, you'll
need the information about the locations from which diagnostic 
actions are available.

I<locations()> provides the informations. On success it returns a 
Perl-style array reference. On error it returns I<undef> and sets 
the I<last_error()> appropriate.

=head2 $diag->mtr($hash_ref)

I<mtr()> returns a network trace like the well know I<mtr> Unix command.

I<mtr()> accepts the following parameters in $hash_ref as a Perl-style
hash reference:

=over 4

=item * destinationDomain

The domain name you want to get information about. Example: I<cpan.org>.
This parameter is mandatory.

=item * location

Location of a Akamai Server you want to run mtr from. You can find 
servers using the I<locations()> call. This paramter is optional. 
Either location or sourceIp has to be passed to I<mtr()>

=item * sourceIp

A Akamai Server IP you want to run mtr from. This paramter is optional. 
Either location or sourceIp has to be passed to I<mtr()>

=back

On success it returns a Perl-style hash reference. On error it returns 
I<undef> and sets the I<last_error()> appropriate.

The hash reference has the following format:

  {
     'source' => ...,
     'packetLoss' => '...',
     'destination' => '...',
     'errorString' => ...,
     'analysis' => '...',
     'host' => '...',
     'avgLatency' => '...',
     'hops' => [
                 {
                   'num' => '...',
                   'avg' => '...',
                   'last' => '...',
                   'stDev' => '...',
                   'host' => '...',
                   'worst' => '...',
                   'loss' => '...',
                   'sent' => '...',
                   'best' => '...'
                 }
               ]
  }

=head2 $diag->dig($hash_ref)

I<dig()> returns dns information like the well know I<dig> Unix command.

I<dig()> accepts the following parameters in $hash_ref as a Perl-style
hash reference:

=over 4

=item * hostname

The hostname you want to get information about. Example: I<cpan.org>.
This parameter is mandatory.

=item * queryType

The query type for the dig command call, valid types are A, AAAA, 
PTR, SOA, MX and CNAME. This parameter is mandatory.

=item * location

Location of Akamai Server you want to run dig from. You can find 
servers using the I<locations()> call. This paramter is optional. 
Either location or sourceIp has to be passed to I<dig()>

=item * sourceIp

A Akamai Server IP you want to run dig from. This paramter is optional. 
Either location or sourceIp has to be passed to I<dig()>

=back

On success it returns a Perl-style hash reference. On error it returns 
I<undef> and sets the I<last_error()> appropriate.

The hash reference has the following format:

  {
      'authoritySection' => [
                             {
                                'recordType' => '...',
                                'domain' => '...',
                                'value' => '...',
                                'ttl' => '...',
                                'preferenceValues' => ...,
                                'recordClass' => '...'
                              }
                            ],
      'answerSection' => [
                          {
                             'recordType' => '...',
                             'domain' => '...',
                             'value' => '...',
                             'ttl' => '...',
                             'preferenceValues' => ...,
                             'recordClass' => '...'
                           }
                         ],
      'errorString' => ...,
      'queryType' => '...',
      'hostname' => '...',
      'result' => '...'
  }

=head2 $diag->last_error()

Just returns the last occured error.

=head1 AUTHOR

Martin Probst <internet+cpan@megamaddin.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Martin Probst.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
