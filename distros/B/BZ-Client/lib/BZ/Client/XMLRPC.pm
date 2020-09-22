#!/bin/false
# PODNAME: BZ::Client::XMLRPC
# ABSTRACT: Performs XML-RPC calls on behalf of the client.
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

package BZ::Client::XMLRPC;
$BZ::Client::XMLRPC::VERSION = '4.4003';

use URI;
use Encode qw/ encode_utf8 /;
use XML::Writer;
use HTTP::Tiny;
use File::Spec;
use BZ::Client::Exception;
use BZ::Client::XMLRPC::Parser;
use DateTime::Format::Strptime;
use DateTime::TimeZone;



my $counter;
my $fmt = DateTime::Format::Strptime->new(
                    pattern   => '%C%Y-%m-%dT%T',
                    time_zone => 'UTC' );
my $tz = DateTime::TimeZone->new( name => 'UTC' );


sub new {
    my $class = shift;
    my $self = { @_ };
    bless($self, ref($class) || $class);
    return $self
}

sub url {
    my $self = shift;
    if (@_) {
        $self->{'url'} = shift;
    }
    else {
        return $self->{'url'};
    }
}

sub web_agent {
    my $self = shift;
    if (@_) {
        $self->{'web_agent'} = shift;
    }
    else {
        my $wa = $self->{'web_agent'};
        my $connect = $self->{'connect'} || {};
        $self->error(q/'connect' parameter in new() not a hashref/)
            unless ref $connect eq 'HASH';
        if (!defined($wa)) {
            $wa = HTTP::Tiny->new(
                %$connect,
                agent => sprintf('BZ::Client::XMLRPC %s (perl %s; %s)',
                                 $BZ::Client::XMLRPC::VERSION, $^V, $^O)
            );
            $self->web_agent($wa);
        }
        return $wa;
    }
}

sub error {
    my($self, $message, $http_code, $xmlrpc_code) = @_;
    BZ::Client::Exception->throw('message'     => $message,
                                 'http_code'   => $http_code,
                                 'xmlrpc_code' => $xmlrpc_code)
}

{

my %actions = (

    'HASH' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('struct');
        for my $key (sort keys %$value) {
            $writer->startTag('member');
            $writer->startTag('name');
            $writer->characters($key);
            $writer->endTag('name');
            $self->value($writer, $value->{$key});
            $writer->endTag('member');
        }
        $writer->endTag('struct');
        $writer->endTag('value');
    },

    'ARRAY' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('array');
        $writer->startTag('data');
        for my $val (@$value) {
            $self->value($writer, $val);
        }
        $writer->endTag('data');
        $writer->endTag('array');
        $writer->endTag('value');
    },

    'BZ::Client::XMLRPC::int' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('i4');
        $writer->characters( $value->stringify() );
        $writer->endTag('i4');
        $writer->endTag('value');
    },

    'BZ::Client::XMLRPC::base64' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('base64');
        $writer->characters( $value->base64() );
        $writer->endTag('base64');
        $writer->endTag('value');
    },

    'BZ::Client::XMLRPC::boolean' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('boolean');
        $writer->characters( $value->stringify() );
        $writer->endTag('boolean');
        $writer->endTag('value');
    },

    'BZ::Client::XMLRPC::double' => sub {
        my($self, $writer, $value) = @_;
        $writer->startTag('value');
        $writer->startTag('double');
        $writer->characters( $value->stringify() );
        $writer->endTag('double');
        $writer->endTag('value');
    },

    'DateTime' => sub {
        my($self, $writer, $value) = @_;
        my $clone = $value->clone();
        $clone->set_time_zone($tz);
        $clone->set_formatter($fmt);
        $writer->startTag('value');
        $writer->startTag('dateTime.iso8601');
        $writer->characters($clone->iso8601(). 'Z');
        $writer->endTag('dateTime.iso8601');
        $writer->endTag('value');
    },

);

sub value {
    my($self, $writer, $value) = @_;

    if ($actions{ ref($value) }) {
        $actions{ ref($value) }->($self, $writer, $value);
    }
    else {
        $writer->startTag('value');
        $writer->characters($value);
        $writer->endTag('value');
    }
}

}

sub create_request {
    my($self, $methodName, $params) = @_;
    my $contents;
    my $writer = XML::Writer->new(
                OUTPUT   => \$contents,
                ENCODING => 'UTF-8' );
    $writer->startTag('methodCall');
    $writer->startTag('methodName');
    $writer->characters($methodName);
    $writer->endTag('methodName');
    $writer->startTag('params');
    for my $param (@$params) {
        $writer->startTag('param');
        $self->value($writer, $param);
        $writer->endTag('param');
    }
    $writer->endTag('params');
    $writer->endTag('methodCall');
    $writer->end();
    return encode_utf8($contents)
}

sub get_response {
    my($self, $contents) = @_;
    return _get_response(
            $self,
            {
                'url'         => $self->url() . '/xmlrpc.cgi',
                'contentType' => 'text/xml',
                'contents'    => encode_utf8($contents)
            }
    )
}

sub _get_response {
    my($self, $params) = @_;
    my $url = $params->{'url'};
    my $contentType = $params->{'contentType'};
    my $contents = $params->{'contents'};
    if (ref($contents) eq 'ARRAY') {
        my $uri = URI->new('http:');
        $uri->query_form($contents);
        $contents = $uri->query();
    }

    my %options = (
        headers => {
            'Content-Type' => $contentType,
        },
        content => $contents, # carefull of the s
    );

    my $wa = $self->web_agent();

    my($logDir,$logId) = $self->logDirectory();

    if ($logDir) {
        $logId = ++$counter;
        my $fileName = File::Spec->catfile($logDir, "$$.$logId.request.log");
        if (open(my $fh, '>', $fileName)) {
            while (my($header,$value) = each %{$options{headers}} ) {
                print $fh "$header: $value\n";
            }
            print $fh 'user-agent: ', $wa->agent(), "\n";
            if ($wa->{cookie_jar}) {
                print $fh join("\n", $wa->{cookie_jar}->dump_cookies());
            }
            print $fh "\n";
            print $fh $contents;
            close($fh);
        }
    }

    my $res = $wa->request(POST => $url, \%options);
    my $response = $res->{success} ? $res->{content} : undef;
    if ($logDir) {
        my $fileName = File::Spec->catfile($logDir, "$$.$logId.response.log");
        if (open(my $fh, '>', $fileName)) {
            for my $header (sort keys %{$res->{headers}}) {
                my $value = $res->{headers}->{$header};
                if (ref $value) {
                    print $fh "$header: $_\n" for @$value;
                }
                else {
                    print $fh "$header: $value\n";
                }
            }
            print $fh "\n";
            print $fh $res->{content} if $res->{content};
            close($fh);
        }
    }
    if (!$res->{success}) {
        my $code = $res->{status};
        if ($code == 401) {
            $self->error('Authorization error, perhaps invalid user name and/or password', $code);
        }
        elsif ($code == 404) {
            $self->error('Bugzilla server not found, perhaps invalid URL.', $code);
        }
        else {
            my $msg = $res->{reason};
            $msg .= ' : ' . $res->{content} if $res->{content};
            $self->error("Unknown error: $msg", $code);
        }
    }

    return $response
}

sub parse_response {
    my($self, $contents) = @_;
    my $parser = BZ::Client::XMLRPC::Parser->new();
    return $parser->parse($contents)
}

sub request {
    my $self = shift;
    my %args = @_;
    my $methodName = $args{'methodName'};
    $self->error('Missing argument: methodName')
        unless defined($methodName);
    my $params = $args{'params'};
    $self->error('Missing argument: params')
        unless defined($params);
    $self->error('Invalid argument: params (Expected array)')
        unless ref($params) eq 'ARRAY';
    my $contents = $self->create_request($methodName, $params);
    $self->log('debug', "BZ::Client::XMLRPC::request: Sending method $methodName to " . $self->url());
    my $response = $self->get_response($contents);
    $self->log('debug', "BZ::Client::XMLRPC::request: Got result for method $methodName");
    return $self->parse_response($response)
}

sub log {
    my($self, $level, $msg) = @_;
    my $logger = $self->logger();
    if ($logger) {
        &$logger($level, $msg);
    }
}

sub logger {
    my($self) = shift;
    if (@_) {
        $self->{'logger'} = shift;
    }
    else {
        return $self->{'logger'};
    }
}

sub logDirectory {
    my($self) = shift;
    if (@_) {
        $self->{'logDirectory'} = shift;
    }
    else {
        return $self->{'logDirectory'};
    }
}

### Objects to represent data types

package BZ::Client::XMLRPC::int;
$BZ::Client::XMLRPC::int::VERSION = '4.4003';
sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

sub stringify {
    my $self = shift;
    return $$self
}

package BZ::Client::XMLRPC::base64;
$BZ::Client::XMLRPC::base64::VERSION = '4.4003';
use MIME::Base64 qw( encode_base64 decode_base64 );

sub new {
    my($class, $value) = @_;
    return bless(
        {
            raw    => $value,
            base64 => encode_base64($value, '')
        },
        (ref($class) || $class))
}

sub new64 {
    my($class, $value) = @_;
    return bless(
        {
            raw    => decode_base64($value),
            base64 => $value
        },
        (ref($class) || $class))
}

sub base64 {
    my $self = shift;
    return $self->{base64}
}

sub raw {
    my $self = shift;
    return $self->{raw}
}

package BZ::Client::XMLRPC::boolean;
$BZ::Client::XMLRPC::boolean::VERSION = '4.4003';
sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

sub stringify {
    my $self = shift;
    return $$self ? '1' : '0';
}

{

my $true = BZ::Client::XMLRPC::boolean->new(1);
my $false = BZ::Client::XMLRPC::boolean->new(0);

sub TRUE  { $true }
sub FALSE { $false }

}

package BZ::Client::XMLRPC::double;
$BZ::Client::XMLRPC::double::VERSION = '4.4003';
sub new {
    my($class, $value) = @_;
    return bless(\$value, (ref($class) || $class))
}

sub stringify {
    my $self = shift;
    return $$self
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::XMLRPC - Performs XML-RPC calls on behalf of the client.

=head1 VERSION

version 4.4003

=head1 SYNOPSIS

  my $xmlrpc = BZ::Client::XMLRPC->new( url => $url );
  my $result = $xmlrpc->request( methodName => $methodName, params => $params );

An instance of BZ::Client::XMLRPC is able to perform XML-RPC calls against the
given URL. A request is performed by passing the method name and the method
parameters to the method L</request>. The request result is returned.

=head1 CLASS METHODS

This section lists the possible class methods.

=head2 new

  my $xmlrpc = BZ::Client::XMLRPC->new( url => $url );

Creates a new instance with the given URL.

=head1 INSTANCE METHODS

This section lists the possible instance methods.

=head2 url

  my $url = $xmlrpc->url();
  $xmlrpc->url( $url );

Returns or sets the XML-RPC servers URL.

=head2 request

  my $result = $xmlrpc->request( methodName => $methodName, params => $params );

Calls the XML-RPC servers method C<$methodCall>, passing the parameters given by
C<$params>, an array of parameters. Parameters may be hash refs, array refs, or
atomic values. Array refs and hash refs may recursively contain array or hash
refs as values. An instance of L<BZ::Client::Exception> is thrown in case of
errors.

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::Exception>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
