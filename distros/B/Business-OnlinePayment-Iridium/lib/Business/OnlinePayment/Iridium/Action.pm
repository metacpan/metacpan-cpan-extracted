package Business::OnlinePayment::Iridium::Action;

use Moose::Role;
use Template;
use LWP::UserAgent ();
use HTTP::Request  ();
use XML::Simple    ();

# PODNAME: Business::OnlinePayment::Iridium::Action
# ABSTRACT: Send / receive data to / from PayVector


sub SERVERS {
    return ( 'https://gw1.iridiumcorp.net/', 'https://gw2.iridiumcorp.net/', 'https://gw3.iridiumcorp.net/' );
}

has 'MerchantID' => (
    isa      => 'Str',
    is       => 'rw',
    required => '1'
);

has 'Password' => (
    isa      => 'Str',
    is       => 'rw',
    required => '1'
);

has 'CurrencyCode' => (
    isa     => 'Int',
    is      => 'rw',
    default => '826'    # GBP
);

has 'PassOutData' => (
    isa      => 'Str',
    is       => 'rw',
    required => '0'
);

has '_user_agent' => (
    isa     => 'LWP::UserAgent',
    is      => 'ro',
    default => sub {
        return LWP::UserAgent->new( agent => 'Business::OnlinePayment::Iridium',
        );
    }
);

has '_type' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => '1'
);

requires '_build__type';

requires 'template';

sub _build_req_content {
    my $self = shift;
    my $vars = {
        map {
            my $attr_name = $_->name;
            $attr_name => $self->$attr_name
          } $self->meta->get_all_attributes
    };
    my ( $template, $output ) = ( $self->template, '' );
    my $tt = Template->new();
    $tt->process( \$template, $vars, \$output ) || confess $tt->error;
    return $output;
}


sub request {
    my $self       = shift;
    my $content    = $self->_build_req_content;
    my $action_url = 'https://www.thepaymentgateway.net/';
    my $ua         = $self->_user_agent;
    my @SERVERS    = $self->SERVERS;

    my $req = HTTP::Request->new( POST => $SERVERS[0] );
    $req->content_type('text/xml; charset=UTF-8');
    $req->header( 'SOAPAction' => $action_url . $self->_type );
    $req->content($content);
    $req->content_length( length($content) );
    my $res = $ua->request($req);

    if ( $res->is_success ) {
        return $self->parse_response( $res->content );
    }
    else {
        $req->uri( $SERVERS[1] );
        $res = $ua->request($req);

        if ( $res->is_success && $res->content ) {
            return $self->parse_response( $res->content );
        }
        else {
            confess $res->status_line;
        }
    }
}


sub parse_response {
    my ( $self, $content ) = @_;
    my $parser = XML::Simple->new;
    return $parser->XMLin($content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::OnlinePayment::Iridium::Action - Send / receive data to / from PayVector

=head1 VERSION

version 1.01

=head2 SERVERS

List of 3 servers to send payment attempts to

=head2 request

Send our request to PayVector

=head2 parse_response

Turn the PayVector response into XML

=head1 AUTHOR

[ 'Gavin Henry <ghenry@surevoip.co.uk>', 'Wallace Reis <reis.wallace@gmail.com>' ]

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by [ 'Gavin Henry', 'Wallace Reis' ].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
