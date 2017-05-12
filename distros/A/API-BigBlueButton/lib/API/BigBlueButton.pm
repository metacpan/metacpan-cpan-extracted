package API::BigBlueButton;

=encoding utf-8

=head1 NAME

API::BigBlueButton

=head1 SYNOPSIS

    use API::BigBlueButton;

    my $bbb = API::BigBlueButton->new( server => 'bbb.myhost', secret => '1234567890' );
    my $res = $bbb->get_version;

    if ( $res->success ) {
        my $version = $res->response->version
    }
    else {
        warn "Error occured: " . $res->error . ", Status: " . $res->status;
    }

=head1 DESCRIPTION

client for BigBlueButton API

=cut

use 5.008008;
use strict;
use warnings;

use Carp qw/ confess /;
use LWP::UserAgent '6.05';

use API::BigBlueButton::Response;

use base qw/ API::BigBlueButton::Requests /;

use constant REQUIRE_PARAMS => qw/ secret server /;

our $VERSION = "0.013";

=head1 VERSION
 
version 0.013

=cut

=head1 METHODS

=over

=item B<new(%param)>

Constructor

%param:

server

    Ip-address or hostname in which the server is located. Required parameter.

secret

    Shared secret. Required parameter.

timeout

    Connection timeout. Optional parameter.

use_https

    Use/not use https. Optional parameter.
=cut

sub new {
    my $class = shift;

    $class = ref $class || $class;

    my $self = {
        timeout => 30,
        secret  => '',
        server  => '',
        use_https => 0,
        (@_),
    };

    for my $need_param ( REQUIRE_PARAMS ) {
        confess "Parameter $need_param required!" unless $self->{ $need_param };
    }

    return bless $self, $class;
}

sub abstract_request {
    my ( $self, $data ) = @_;

    my $request = delete $data->{request};
    my $checksum = delete $data->{checksum};
    confess "Parameter request required!" unless $request;

    my $url = $self->{use_https} ? 'https://' : 'http://';
    $url .= $self->{server} . '/bigbluebutton/api/' . $request . '?';

    if ( scalar keys %{ $data } > 0 ) {
        $url .= $self->generate_url_query( $data );
        $url .= '&';
    }
    $url .= 'checksum=' . $checksum;

    return $self->request( $url );
}

sub request {
    my ( $self, $url ) = @_;

    my $ua = LWP::UserAgent->new;

    $ua->ssl_opts(verify_hostname => 0) if $self->{use_https};
    $ua->timeout( $self->{ timeout } );

    my $res = $ua->get( $url );

    return API::BigBlueButton::Response->new( $res );
}

1;

__END__

=back

=head1 SEE ALSO

L<API::BigBlueButton::Requests>

L<API::BigBlueButton::Response>

L<BigBlueButton API|https://code.google.com/p/bigbluebutton/wiki/API>

=head1 AUTHOR

Alexander Ruzhnikov E<lt>a.ruzhnikov@reg.ruE<gt>

=cut
