package Catalyst::Action::Serialize::XML::Simple;
$Catalyst::Action::Serialize::XML::Simple::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    eval {
        require XML::Simple
    };
    if ($@) {
        $c->log->debug("Could not load XML::Serializer, refusing to serialize: $@")
            if $c->debug;
        return;
    }
    my $xs = XML::Simple->new(ForceArray => 0,);

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'} 
        ) || 'rest';
    my $output = $xs->XMLout({ data => $c->stash->{$stash_key} });
    $c->response->output( $output );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
