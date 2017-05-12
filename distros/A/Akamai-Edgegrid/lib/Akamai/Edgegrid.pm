package Akamai::Edgegrid;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base 'LWP::UserAgent';
use Data::Dumper;
use Digest::SHA qw(hmac_sha256_base64 sha256_base64);
use POSIX qw(strftime);
use Data::UUID;
use Config::IniFiles;

=head1 NAME

Akamai::Edgegrid - User agent for Akamai {OPEN} Edgegrid

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0.5';

=head1 SYNOPSIS

    use Akamai::Edgegrid;

    my $agent = new Akamai::Edgegrid(
                    config_file => "$ENV{HOME}/.edgerc",
                    section   => "default");
    my $baseurl = "https://" . $agent->{host};

    my $resp = $agent->get("$baseurl/diagnostic-tools/v1/locations");
    print $resp->content;

=head1 DESCRIPTION

This module implements the Akamai {OPEN} Edgegrid Authentication scheme as specified by L<https://developer.akamai.com/introduction/Client_Auth.html>.

=cut

sub _eg_timestamp {
    return strftime('%Y%m%dT%H:%M:%S+0000', gmtime(time));
}

sub _new_nonce {
    my $ug = new Data::UUID;
    return $ug->create_str;
}

# see http://search.cpan.org/~mshelor/Digest-SHA-5.88/lib/Digest/SHA.pm#PADDING_OF_BASE64_DIGESTS
sub _pad_digest {
    my $digest = shift;
    while (length($digest) % 4) {
        $digest .= '=';
    }
    return $digest;
}

sub _padded_hmac_sha256_base64 {
    my ($data, $key) = @_; 
    return _pad_digest(hmac_sha256_base64($data, $key));
}

sub _padded_sha256_base64 {
    my ($data) = @_;
    return _pad_digest(sha256_base64($data));
}

## methods

sub _debug {
    my ($self, $msg) = @_;
    if ($self->{debug}) {
        $msg =~ s/\n$//;
        warn "$msg\n";
    }
}

sub _make_signing_key {
    my ($self, $timestamp) = @_;
    my $signing_key = _padded_hmac_sha256_base64($timestamp, $self->{client_secret});
    $self->_debug("signing_key: $signing_key");

    return $signing_key;
}

sub _canonicalize_headers {
    my ($self, $r) = @_;
    return join("\t", 
        map {
            my $header_name = lc($_);
            my $header_val = $r->header($_);
            $header_val =~ s/^\s+//g;
            $header_val =~ s/\s+$//g;
            $header_val =~ s/\s+/ /g;

            "$header_name:$header_val";

        } grep { 
            defined $r->header($_) 
        } @{$self->{headers_to_sign}}
    );
}

sub _make_content_hash {
    my ($self, $r) = @_;
    if ($r->method eq 'POST' and length($r->content) > 0) {
        my $body = $r->content;
        if (length($body) > $self->{max_body}) {
            $self->_debug(
                "data length " . length($body) . " is larger than maximum " . $self->{max_body}
            );

            $body = substr($body, 0, $self->{max_body});

            $self->_debug(
                "data truncated to " . length($body) . " for computing the hash"
            );
        }
        return _padded_sha256_base64($body);
    }
    return "";
}

sub _make_data_to_sign {
    my ($self, $r, $auth_header) = @_;
    my $data_to_sign = join("\t", (
        $r->method,
        $r->url->scheme,
        $r->url->host,
        $r->url->path_query,
        $self->_canonicalize_headers($r),
        $self->_make_content_hash($r),
        $auth_header
    ));

    my $display_to_sign = $data_to_sign;
    $display_to_sign =~ s/\t/\\t/g;
    $self->_debug("data to sign: $display_to_sign");

    return $data_to_sign;
}

sub _sign_request {
    my ($self, $r, $timestamp, $auth_header) = @_;

    return _padded_hmac_sha256_base64(
        $self->_make_data_to_sign($r, $auth_header),
        $self->_make_signing_key($timestamp)
    );
}

sub _make_auth_header {
    my ($self, $r, $timestamp, $nonce) = @_;
    my @kvps = (
        ['client_token' => $self->{client_token}],
        ['access_token' => $self->{access_token}],
        ['timestamp' => $timestamp],
        ['nonce' => $nonce]
    );
    my $auth_header = "EG1-HMAC-SHA256 " . join(';', map {
            my ($k,$v) = @$_;
            "$k=$v";
        } @kvps) . ';';

    $self->_debug("unsigned authorization header: $auth_header");

    my $signed_auth_header = 
        $auth_header . 'signature=' .  $self->_sign_request($r, $timestamp, $auth_header);

    $self->_debug("signed authorization header: $signed_auth_header");

    return $signed_auth_header;
}

=head1 CONSTRUCTOR METHOD

=over 2

=item $ua = Akamai::Edgegrid->new( %options )

This method constructs a new C<Akamai::EdgeGrid> object and returns it.  This
is a subclass of C<LWP::UserAgent> and accepts all Key/value pair arguments
accepted by the parent class.  In addition The following required key/value
pairs must be provided:

    KEY           SOURCE
    ------------- -----------------------------------------------
    client_token  from "Credentials" section of Manage APIs UI
    client_secret from "Credentials" section of Manage APIs UI
    access_token  from "Authorizations" section of Manage APIs UI

The following optional key/value pairs may be provided:

    KEY             DESCRIPTION
    --------------- -------------------------------------------------------
    debug           if true enables additional logging
    headers_to_sign listref of header names to sign (in order) (default [])
    max_body        maximum body size for POSTS (default 2048)

=cut

sub new {
    my $class = shift @_;
    my %args = @_;

    my @local_args = qw(config_file section client_token client_secret access_token headers_to_sign max_body debug);
    my @required_args = qw(client_token client_secret access_token);
    my @cred_args = qw(client_token client_secret access_token host);
    my %local = ();

    for my $arg (@local_args) {
        $local{$arg} = delete $args{$arg};
    }

    my $self = LWP::UserAgent::new($class, %args);

    for my $arg (@local_args) {
        $self->{$arg} = $local{$arg};
    }

    # defaults
    unless ($self->{config_file}) {
        $self->{config_file} = "$ENV{HOME}/.edgerc";
    }
    if (-f $self->{config_file} and $self->{section} ) {
        my $cfg = Config::IniFiles->new( -file => $self->{config_file} );
        for my $variable (@cred_args) {
            if ($cfg->val($self->{section}, $variable)) {
                $self->{$variable} = $cfg->val($self->{section}, $variable);
            } else {
                die ("Config file " .  $self->{config_file} .
                    " is missing required argument " . $variable .
                    " in section " . $self->{section} );
            }
        }
        if ( $cfg->val($self->{section}, "max_body") ) {
            $self->{max_body} = $cfg->val($self->{section}, "max_body");
        }
    }

    for my $arg (@required_args) {
    unless ($self->{$arg}) {
            die "missing required argument $arg";
        }
    }

    unless ($self->{headers_to_sign}) {
        $self->{headers_to_sign} = [];
    }
    unless ($self->{max_body}) {
        $self->{max_body} = 131072;
    }

    $self->add_handler('request_prepare' => sub {
        my ($r, $ua, $h) = @_;

        my $nonce = _new_nonce();
        my $timestamp = _eg_timestamp();

        $r->header('Authorization', $ua->_make_auth_header($r, $timestamp, $nonce));
    });

    return $self;
}

=back

=head1 AUTHOR

Jonathan Landis, C<< <jlandis at akamai.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://github.com/akamai-open/edgegrid-perl/issues>.  

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Akamai::Edgegrid


You can also look for information at: 

=over 4

=item * Akamai's OPEN Developer Community

L<https://developer.akamai.com>

=item * Github issues (report bugs here)

L<https://github.com/akamai-open/AkamaiOPEN-edgegrid-perl/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/edgegrid-perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/edgegrid-perl>

=item * Search CPAN

L<http://search.cpan.org/dist/edgegrid-perl/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Akamai Technologies, Inc. All rights reserved

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

1; # End of Akamai::Edgegrid
