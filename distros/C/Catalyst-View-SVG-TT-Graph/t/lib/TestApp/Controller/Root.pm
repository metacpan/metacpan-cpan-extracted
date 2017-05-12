package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub chart : Chained('/') PathPart('chart') Args() {
    my ( $self, $c, $arg ) = @_;

    die "Invalid chart type" if $arg !~ m/^(?:bar(?:_horizontal)?|pie|line)$/;
    my $type = join("", map { ucfirst } split("_", $arg));
    my $height = $c->req->params->{height} || 200;
    my $width = $c->req->params->{width} || 300;

    my $format = $c->req->params->{format};
    ( $height, $width ) = ( 40, 60 ) if $format eq 'ico';

    $c->stash->{format} = $format;

    my $fields = [ qw(Jan Feb March Apr May) ];
    my $values = [ 51, 40, 57, 33, 38 ];

    my $conf = {
        height => $height,
        width => $width,
        key     => 1,
        key_placement => 'R',
        show_key_data_labels => 1,
        random_colors => 1,
    };

    $c->stash(
        chart_type    => $type,
        chart_title   => 'My Title',
        chart_conf    => $conf,
        chart_fields  => $fields,
        chart_data    => $values
    );
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    
    $c->forward($c->view('Chart'));
}

=head1 AUTHOR

FOSS Hacker,,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
