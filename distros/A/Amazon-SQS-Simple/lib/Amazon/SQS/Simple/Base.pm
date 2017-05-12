package Amazon::SQS::Simple::Base;

use strict;
use warnings;
use Carp qw( croak carp );
use Digest::HMAC_SHA1;
use Digest::SHA qw(hmac_sha256 sha256);
use LWP::UserAgent;
use MIME::Base64;
use URI::Escape;
use XML::Simple;
use HTTP::Date;
use HTTP::Request::Common;
use AWS::Signature4;
use POSIX qw(strftime);
use Encode qw(encode);
use Data::Dumper;
use VM::EC2::Security::CredentialCache;

use base qw(Exporter);

use constant ({ 
    SQS_VERSION_2012_11_05 => '2012-11-05',
    BASE_ENDPOINT          => 'http://sqs.us-east-1.amazonaws.com',
    DEF_MAX_GET_MSG_SIZE   => 4096, # Messages larger than this size will use a POST request.
    MAX_RETRIES            => 4,
});
                                       

our $DEFAULT_SQS_VERSION = SQS_VERSION_2012_11_05;
our @EXPORT = qw(SQS_VERSION_2012_11_05);
our $URI_SAFE_CHARACTERS = '^A-Za-z0-9-_.~'; # defined by AWS, same as URI::Escape defaults

sub new {
    my $class      = shift;
    my @args = @_;
    if (scalar(@args) >= 2 && $args[0] ne 'UseIAMRole') {
        my $access_key = shift @args;
        my $secret_key = shift @args;
        @args = (AWSAccessKeyId => $access_key,
                 SecretKey => $secret_key, @args);
    }
    my $self = {
        Endpoint         => +BASE_ENDPOINT,
        SignatureVersion => 4,
        Version          => $DEFAULT_SQS_VERSION,
        @args
    };

    if (!defined($self->{UserAgent})) {
        $self->{UserAgent} = LWP::UserAgent->new(keep_alive => 4);
    }

    if (defined($self->{Timeout})) {
        $self->{UserAgent}->timeout($self->{Timeout});
    }

    if (!defined($self->{Region})) {
        $self->{Region} = 'us-east-1';
    }

    $self->{UserAgent}->env_proxy;

    if (!$self->{UseIAMRole} && (!$self->{AWSAccessKeyId} || !$self->{SecretKey})) {
        croak "Missing AWSAccessKey or SecretKey";
    }

    $self = bless($self, $class);
    return $self;
}

sub _api_version {
    my $self = shift;
    return $self->{Version};
}

sub _dispatch {
    my $self         = shift;
    my $params       = shift || {};
    my $force_array  = shift || [];
    my $url          = $self->{Endpoint};
    my $response;
    my $post_body;
    my $post_request = 0;

    $params = {
        Version             => $self->{Version},
        %$params
    };

    if (!$params->{Timestamp} && !$params->{Expires}) {
        $params->{Timestamp} = _timestamp();
    }

    foreach my $try (1..MAX_RETRIES) {	
        
        my $req = HTTP::Request->new(POST => $url);
        $req->header(host => URI->new($url)->host);
        my $now = time;
        my $http_date = strftime('%Y%m%dT%H%M%SZ', gmtime($now));
        my $date = strftime('%Y%m%d', gmtime($now));
        
        $req->protocol('HTTP/1.1');
        $req->header('Date' => $http_date);
        $req->header('x-amz-target', 'AmazonSQSv20121105.' . $params->{Action});
        $req->header('content-type' => 'application/x-www-form-urlencoded;charset=utf-8');

        if ($self->{UseIAMRole}) {
            my $creds = VM::EC2::Security::CredentialCache->get();
            defined($creds) || die("Unable to retrieve IAM role credentials");
            $self->{AWSAccessKeyId} = $creds->accessKeyId;
            $self->{SecretKey} = $creds->secretAccessKey;
            $req->header('x-amz-security-token' => $creds->sessionToken);
        }

        $params->{AWSAccessKeyId} = $self->{AWSAccessKeyId};

        my $escaped_params = $self->_escape_params($params);
        my $payload = join('&', map { $_ . '=' . $escaped_params->{$_} } keys %$escaped_params);
        $req->content($payload);
        $req->header('Content-Length', length($payload));

        my $signer = AWS::Signature4->new(-access_key => $self->{AWSAccessKeyId},
                                          -secret_key => $self->{SecretKey});
        $signer->sign($req);

        $self->_debug_log($req->as_string());
        
        $response = $self->{UserAgent}->request($req);
        
        if ($response->is_success) { # note, 500 and 503 are NOT success :D
            $self->_debug_log($response->content);
            my $href = XMLin($response->content, ForceArray => $force_array, KeyAttr => {});
            return $href;
        } else {
            # advice from internal AWS support - most client libraries try 3 times in the face
            # of 500 errors, so ours should too
            # use exponential backoff.
		
            if ($response->code == 500 || $response->code == 503) {
                my $sleep_amount= 2 ** $try * 50 * 1000;
                $self->_debug_log("Doing sleep for: $sleep_amount");
                Time::HiRes::usleep($sleep_amount);
                next;
            }
            die("Got an error: " . $response->as_string());
        }
    }

    # if we fall out of the loop, then we have either a non-500 error or a persistent 500.
	
    my $msg;
    eval {
        my $href = XMLin($response->content);
        $msg = $href->{Error}{Message};
    };
 
    my $error = "ERROR: On calling $params->{Action}: " . $response->status_line;
    $error .= " ($msg)" if $msg;
    croak $error;
}

sub _debug_log {
    my ($self, $msg) = @_;
    return unless $self->{_Debug};
    chomp($msg);
    print {$self->{_Debug}} $msg . "\n\n";
}

sub _escape_params {
    my ($self, $params) = @_;

    # Need to escape + characters in signature
    # see http://docs.amazonwebservices.com/AWSSimpleQueueService/2006-04-01/Query_QueryAuth.html

    # Likewise, need to escape + characters in ReceiptHandle
    # Many characters are possible in MessageBody:
    #    #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
    # probably should encode all keys and values for consistency and future-proofing
    my $to_escape = qr{^(?:Signature|MessageBody|ReceiptHandle)|\.\d+\.(?:MessageBody|ReceiptHandle)$};
    foreach my $key (keys %$params) {
        next unless $key =~ m/$to_escape/;
        my $octets = encode('utf-8-strict', $params->{$key});
        $params->{$key} = uri_escape($octets, $URI_SAFE_CHARACTERS);
    }
    return $params;
}

sub _escape_param {
    my $params  = shift;
    my $single  = shift;
    my $multi_n = shift;
    
    if ($params->{$single}) {
        $params->{$single} = uri_escape($params->{$single});
    } else {
        foreach my $i (1..10) {
            my $multi = $multi_n;
            $multi =~ s/\.n\./\.$i\./;
            if ($params->{$multi}) {
                $params->{$multi} = uri_escape($params->{$multi});
            } else {
                last;
            }
        }        
    }   
}

sub _max_get_msg_size {
    my $self = shift;
    # a user-defined cut-off
    if (defined $self->{MAX_GET_MSG_SIZE}) {
        return $self->{MAX_GET_MSG_SIZE};
    }
    # the default cut-off
    else {
        return DEF_MAX_GET_MSG_SIZE;
    }
}

sub _timestamp {
    my $t = shift;
    if (!defined($t)) {
        $t = time;
    }
    my $formatted_time = HTTP::Date::time2isoz($t);
    $formatted_time =~ s/ /T/;
    return $formatted_time;
}

1;

__END__

=head1 NAME

Amazon::SQS::Simple::Base - No user-serviceable parts included

=head1 AUTHOR

Copyright 2007-2008 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>
Copyright 2013-2017 Mike (no relation) Whitaker E<lt>penfold@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

