package Catalyst::Action::Deserialize::JSON;
$Catalyst::Action::Deserialize::JSON::VERSION = '1.20';
use Moose;
use namespace::autoclean;
use Scalar::Util qw(openhandle);

extends 'Catalyst::Action';
use JSON::MaybeXS qw(JSON);

sub execute {
    my $self = shift;
    my ( $controller, $c, $test ) = @_;

    my $rbody;

    # could be a string or a FH
    if ( my $body = $c->request->body ) {
        if(openhandle $body) {
            seek($body, 0, 0); # in case something has already read from it
            while ( defined( my $line = <$body> ) ) {
                $rbody .= $line;
            }
        } else {
            $rbody = $body;
        }
    }

    if ( $rbody ) {
        my $json = JSON->new->utf8;
        if (my $options = $controller->{json_options}) {
            foreach my $opt (keys %$options) {
                $json->$opt( $options->{$opt} );
            }
        }
        my $rdata = eval { $json->decode( $rbody ) };
        if ($@) {
            return $@;
        }
        $c->request->data($rdata);
    } else {
        $c->log->debug(
            'I would have deserialized, but there was nothing in the body!')
            if $c->debug;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
