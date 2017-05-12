package AnyEvent::EC2::Tiny;
{
  $AnyEvent::EC2::Tiny::VERSION = '0.002';
}
# ABSTRACT: Tiny asynchronous (non-blocking) interface to EC2 using AnyEvent

use Moo;
use Carp;
use HTTP::Tiny;
use AnyEvent::HTTP;

extends 'Net::EC2::Tiny';

sub _request {
    my $self       = shift;
    my $request    = shift;
    my $headers    = shift;
    my $success_cb = shift;
    my $fail_cb    = shift;

    http_post $self->base_url, $request, headers => $headers, sub {
        my ( $body, $hdr ) = @_;

        # in case we fail
        $hdr->{'Status'} !~ /^2/ and return $fail_cb->( {
            type => 'HTTP',
            data => { headers => $hdr, body => $body },
            text => sprintf "POST Request failed: %s %s %s\n",
                    ( $hdr->{'Status'}, $hdr->{'Reason'}, $body ),
        } );

        # we succeeded
        my $xml = $self->_process($body);
        $xml->{'Errors'} and return $fail_cb->( {
            type => 'XML',
            data => {
                headers => $hdr,
                body    => $body,
                xml     => $xml,
                errors  => $xml->{'Errors'},
            },
            text => "Error: $body\n",
        } );

        $success_cb->($xml);
    };
}

sub send {
    my $self        = shift;
    my %args        = @_;
    my $success_cb  = delete $args{'success_cb'};
    my $fail_cb     = delete $args{'fail_cb'};
    my $request     = $self->_sign(%args);
    my $request_str = HTTP::Tiny->www_form_urlencode($request);
    my $headers     = { 'Content-Type' => 'application/x-www-form-urlencoded' };

    $self->_request( $request_str, $headers, $success_cb, $fail_cb );
}

1;

__END__

=pod

=head1 NAME

AnyEvent::EC2::Tiny - Tiny asynchronous (non-blocking) interface to EC2 using AnyEvent

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use v5.14;
    use AnyEvent::EC2::Tiny;

    my $ec2 = AnyEvent::EC2::Tiny->new(
        AWSAccessKey => $ENV{'AWS_ACCESS_KEY'},
        AWSSecretKey => $ENV{'AWS_SECRET_KEY'},
        region       => $ENV{'AWS_REGION'},
        debug        => 1,
    );

    # We are essentially encoding 'raw' EC2 API calls with a v2
    # signature and turning XML responses into Perl data structures
    my $xml = $ec2->send(
        'RegionName.1' => 'us-east-1',
        Action         => 'DescribeRegions',

        success_cb => sub {
            my $xml = shift;

            # prints ec2.us-east-1.amazonaws.com
            say $xml->{'regionInfo'}{'item'}[0]{'regionEndpoint'};
        },

        fail_cb => sub {
            my $error = shift;
            $error->{'type'} # HTTP or XML
            $error->{'data'} # hashref to body, errors, xml, headers, etc.
            $error->{'text'} # text of the error
        },
    );

=head1 DESCRIPTION

This is a basic asynchronous, non-blocking, interface to EC2 based on
L<Net::EC2::Tiny>. It's relatively compatible while the only difference is
with regards to the callbacks and returned information.

=head1 METHODS

=head2 send

C<send()> expects the same arguments as C<send()> in L<Net::EC2::Tiny>, except
you should also provide two additional arguments.

=head3 success_cb

    $ec2->send(
        ...
        success_cb => sub {
            my $xml = shift;
            # do whatever you want with it
        },
    );

Receives the resulting XML you would normally receive. Then you do whatever
you want with it, such as fetching the information or using it to create
another request.

=head3 fail_cb

    $ec2->send(
        ...
        fail_cb => sub {
            my $error = shift;

            if ( $error->{'type'} eq 'HTTP' ) {
                # this was an HTTP error
                my $http_headers = $error->{'data'}{'headers'};
                my $http_body    = $error->{'data'}{'body'};

                warn 'HTTP error received: ', $error->{'text'};
            } else {
                # $error->{'type'} eq 'XML'
                # this was an XML error
                my $http_headers = $error->{'data'}{'headers'};
                my $http_body    = $error->{'data'}{'body'};
                my $xml          = $error->{'data'}{'xml'};
                my $xml_errors   = $error->{'data'}{'errors'};

                warn "XML error received: ', $error->{'text'};
            }
        },
    );

Since we can't simply C<die> or C<croak> in event-based code (the event loop
would catch it and you won't be able to do much about it), we instead provide
a failure callback. The failure callback receives a hash reference including
all information relevant to the request.

These are the available keys in the returned hash reference:

=over 4

=item C<type>

Either B<HTTP> or B<XML>.

Since there are two possible failures (one being the HTTP request, and the
other being any problems expressed in the XML returned) you can use the C<type>
key to know which type of error you received.

=item C<data>

Additional information for the error.

B<HTTP> error receives the HTTP body (C<body>) and headers (C<headers>).

B<XML> error receives the HTTP body (C<body>), headers (C<headers>), XML data
(C<xml>) and XML errors (C<errors>).

=item C<text>

A string containing the error that occured. This matches the errors returned
by L<Net::EC2::Tiny>.

=back

=head1 CREDITS

Credit goes to Mark Allen for L<Net::EC2::Tiny>.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
