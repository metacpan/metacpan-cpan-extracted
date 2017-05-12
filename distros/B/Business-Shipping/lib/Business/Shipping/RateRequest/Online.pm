package Business::Shipping::RateRequest::Online;

=head1 NAME

Business::Shipping::RateRequest::Online - Abstract rates class

=head1 METHODS

=cut

use Any::Moose;
use Business::Shipping::Logging;
use XML::Simple;
use LWP::UserAgent;
use CHI;
use version; our $VERSION = qv('400');

extends 'Business::Shipping::RateRequest';

has 'test_mode' => (is => 'rw');
has 'user_id'   => (is => 'rw');
has 'password'  => (is => 'rw');
has 'response'  => (is => 'rw');

__PACKAGE__->meta()->make_immutable();

sub Required { return ($_[0]->SUPER::Required, qw/ user_id password /); }
sub Optional { return ($_[0]->SUPER::Optional, qw/ prod_url test_url /); }

=head2 perform_action()

Sends request to server.

=cut

sub perform_action {
    my $self    = shift;
    my $request = $self->_gen_request();
    trace('Please wait while we get a response from the server...');
    $self->response($self->_get_response($request));

    #trace( "response content = " . $self->response()->content() );

    if (!$self->response()->is_success()) {
        $self->user_error("HTTP Error. Status line: "
                . $self->response->status_line
                . "Content: "
                . $self->response->content());
    }

   #use Data::Dumper; trace "self->response = " . Dumper( $self->response() );

    return (undef);
}

sub _gen_url {
    trace '()';
    my ($self) = shift;

    return ($self->test_mode() ? $self->test_url() : $self->prod_url());
}

sub _gen_request {
    trace '()';
    my ($self) = shift;

    my $request_xml = $self->_gen_request_xml();

    #trace( $request_xml );
    info("gen_url = " . $self->_gen_url());
    my $request = HTTP::Request->new('POST', $self->_gen_url());
    $request->header('content-type'   => 'application/x-www-form-urlencoded');
    $request->header('content-length' => length($request_xml));
    $request->content($request_xml);

    return ($request);
}

sub _get_response {
    my ($self, $request_param) = @_;
    trace 'called';

    my $ua = LWP::UserAgent->new;
    my $response;
    $ua->timeout(15);    # TODO: Make configurable
    $ua->env_proxy();    # Read proxy settings from environment variables.

    my $try_limit
        = $Business::Shipping::Config::Try_Limit;    # TODO: Make config
    my $tries;
    my $success;

    # The following are known, common errors.
    #    'HTTP Error. Status line: 500',
    #    'HTTP Error. Status line: 500 Server Error',
    #    'HTTP Error. Status line: 500 read timeout',
    #    'HTTP Error. Status line: 500 Bizarre copy of ARRAY',
    #    'HTTP Error. Status line: 500 Connect failed:',
    #    'HTTP Error. Status line: 500 Can\'t connect to ',

    for ($tries = 1; $tries <= $try_limit; $tries++) {
        $response = $ua->request($request_param);

        if (!$response->is_success()) {
            sleep
                2;  # Default recommended wait time. # TODO: Make configurable
            next;
        }
        else {
            last;
        }
    }

    if (!$response->is_success()) {
        $self->user_error("There was an error on the rate server: \""
                . $self->response->status_line
                . "\".  Please try again later");
        $self->is_success(0);
        return;
    }

    return $response;
}

1;

__END__

=head1 AUTHOR

Daniel Browning, db@kavod.com, L<http://www.kavod.com/>

=head1 COPYRIGHT AND LICENCE

Copyright 2003-2011 Daniel Browning <db@kavod.com>. All rights reserved.
This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself. See LICENSE for more info.

=cut
