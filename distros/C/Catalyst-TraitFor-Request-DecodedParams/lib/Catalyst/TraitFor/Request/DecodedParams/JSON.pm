package Catalyst::TraitFor::Request::DecodedParams::JSON;

use Moose::Role;
use namespace::autoclean;
use JSON::Any;
use Try::Tiny;

our $VERSION = '0.01';

with 'Catalyst::TraitFor::Request::DecodedParams';

sub _build_params_decoder { return JSON::Any->new(allow_nonref => 1) }

sub _do_decode_params {
    my ( $self, $params ) = @_;
    my $decoder = $self->_params_decoder;
    my $decoded_param = { %$params };
    foreach my $key ( keys %$decoded_param ) {
        my $value = $decoded_param->{$key};
        $decoded_param->{$key} = try { $decoder->from_json($value) }
            catch { $decoder->from_json( $decoder->to_json($value) ) };
    }
    return $decoded_param;
}

1;

__END__

=head1 NAME

Catalyst::TraitFor::Request::DecodedParams::JSON

=head1 SYNOPSIS

    use CatalystX::RoleApplicator;

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::DecodedParams::JSON
    /);

=head1 AUTHOR & LICENSE

See L<Catalyst::TraitFor::Request::DecodedParams>.

=cut
