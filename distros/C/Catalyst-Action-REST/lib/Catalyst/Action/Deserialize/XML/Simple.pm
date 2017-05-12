package Catalyst::Action::Deserialize::XML::Simple;
$Catalyst::Action::Deserialize::XML::Simple::VERSION = '1.20';
use Moose;
use namespace::autoclean;
use Scalar::Util qw(openhandle);

extends 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ( $controller, $c, $test ) = @_;

    eval {
        require XML::Simple;
    };
    if ($@) {
        $c->log->debug("Could not load XML::Simple, refusing to deserialize: $@")
            if $c->debug;
        return 0;
    }

    my $body = $c->request->body;
    if ($body) {
        my $xs = XML::Simple->new('ForceArray' => 0,);
        my $rdata;
        eval {
            if(openhandle $body){ # make sure we rewind the file handle
                seek($body, 0, 0); # in case something has already read from it
            }
            $rdata = $xs->XMLin( $body );
        };
        if ($@) {
            return $@;
        }
        if (exists($rdata->{'data'})) {
            $c->request->data($rdata->{'data'});
        } else {
            $c->request->data($rdata);
        }
    } else {
        $c->log->debug(
            'I would have deserialized, but there was nothing in the body!')
                if $c->debug;
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
