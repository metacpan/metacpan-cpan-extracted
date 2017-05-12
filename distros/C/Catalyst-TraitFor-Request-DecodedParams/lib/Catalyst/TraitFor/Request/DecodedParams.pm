package Catalyst::TraitFor::Request::DecodedParams;

use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.02';

requires qw/_build_params_decoder _do_decode_params/;

has '_params_decoder' => (
    init_arg => undef, is => 'ro',
    lazy => 1, builder => '_build_params_decoder',
);

has decoded_params => (
    init_arg => undef, isa => 'HashRef',
    is => 'ro', lazy => 1, builder => '_build_decoded_params',
);

sub _build_decoded_params {
    my $self = shift;
    return $self->_do_decode_params($self->params);
}

sub decoded_parameters { return shift->decoded_params }

sub dparams { return shift->decoded_params }

has decoded_query_params => (
    init_arg => undef, isa => 'HashRef',
    is => 'ro', lazy => 1, builder => '_build_decoded_query_params',
);

sub _build_decoded_query_params {
    my $self = shift;
    return $self->_do_decode_params($self->query_params);
}

sub decoded_query_parameters { return shift->decoded_query_params }

sub dquery_params { return shift->decoded_query_params }

has decoded_body_params => (
    init_arg => undef, isa => 'HashRef',
    is => 'ro', lazy => 1, builder => '_build_decoded_body_params',
);

sub _build_decoded_body_params {
    my $self = shift;
    return $self->_do_decode_params($self->body_params);
}

sub decoded_body_parameters { return shift->decoded_body_params }

sub dbody_params { return shift->decoded_body_params }

1;

__END__

=head1 NAME

Catalyst::TraitFor::Request::DecodedParams - A request trait for params decoding

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use namespace::autoclean;
    use CatalystX::RoleApplicator;
    use Catalyst;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::DecodedParams::JSON
    /);

    1;

=head1 METHODS

=over

=item decoded_query_parameters

decoded_query_params, dquery_params

=item decoded_body_parameters

decoded_body_params, dbody_params

=item decoded_parameters

decoded_params, dparams

=back

=head1 AUTHOR

Wallace Reis C<< <wreis at cpan.org> >>

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.
=cut
