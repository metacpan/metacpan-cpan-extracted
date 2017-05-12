package App::HistHub::Web::View::JSON;
use strict;
use base 'Catalyst::View::JSON';

use JSON::XS ();

__PACKAGE__->config(
    allow_callback   => 0,
    expose_stash     => 'json',
    no_x_json_header => 1,
);

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{encoder} = JSON::XS->new->latin1;
    $self;
}

sub encode_json {
    my ($self, $c, $data) = @_;
    $self->{encoder}->encode($data);
}

=head1 NAME

App::HistHub::Web::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<App::HistHub::Web>

=head1 DESCRIPTION

Catalyst JSON View.

=head1 AUTHOR

Daisuke Murase

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
