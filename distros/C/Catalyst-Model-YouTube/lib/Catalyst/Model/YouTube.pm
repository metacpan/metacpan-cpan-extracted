package Catalyst::Model::YouTube;

use strict;
use base 'Catalyst::Model';

use Catalyst::Utils;
use Class::C3;
use WebService::YouTube::Videos;

our $VERSION = '0.14';

=head1 NAME

Catalyst::Model::YouTube - Catalyst Model for the YouTube Web Services

=head1 SYNOPSIS

    # use the helper
    myapp/script/myapp_create.pl create model YouTube YouTube [dev_id]

    # lib/MyApp/Model/YouTube.pm
    
    package MyApp::Model::YouTube;

    use base 'Catalyst::Model::YouTube';

    __PACKAGE__->config(
        dev_id => 'yourdevid'
    );

    1;

    # In a controller:
    @videos = $c->model('YouTube')->list_featured;

=head1 DESCRIPTION

A simple model class that interfaces with L<WebService::YouTube> to query
the YouTube webservice APIs to fetch and display videos.


=head1 METHODS

=over 4

=item new

Initialized the YouTube object.

=cut

sub new {
    my ( $self, $c, $arguments ) = @_;
    $self = $self->next::method(@_);

    return new WebService::YouTube::Videos( { %$self } );
}

=back 

=head1 SEE ALSO

L<Catalyst>, L<WebService::YouTube>

=head1 AUTHOR

J. Shirley <jshirley@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

