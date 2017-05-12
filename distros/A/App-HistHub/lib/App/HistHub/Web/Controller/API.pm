package App::HistHub::Web::Controller::API;
use strict;
use warnings;
use parent 'Catalyst::Controller';

__PACKAGE__->mk_accessors(qw/result error/);

=head1 NAME

App::HistHub::Web::Controller::API - API Controller for App::HistHub::Web

=head1 DESCRIPTION

L<App::HistHub>.

=head1 METHODS

=head2 init

=cut

sub init :Local :Args(0) {
    my ($self, $c) = @_;

    my $peer = $c->model('DB::Peer')->create({});
    $self->result({ uid => $peer->uid });
}

=head2 poll

=cut

sub poll :Local :Args(0) {
    my ($self, $c) = @_;

    my $uid  = $c->req->param('uid') or return $self->error('require uid');
    my $peer = $c->model('DB::Peer')->find({ uid => $uid }) or return $self->error('no such uid');

    if ($c->req->method eq 'POST' and my $data = $c->req->param('data')) {
        my @peers = $c->model('DB::Peer')->search({ uid => { '!=', $uid } });
        $_->push_queue($data) for @peers;
    }

    $self->result( $peer->pop_queue );
}

=head2 end

=cut

sub end :Private {
    my ($self, $c) = @_;

    if (@{ $c->error }) {
        (my $last_error = $c->error->[-1]) =~ s/ on .*?$//;

        use YAML;
        warn Dump $last_error;

        $c->res->status(500);
        $c->stash->{json} = {
            error => $last_error,
        };
        $c->error(0);
    }
    else {
        $c->stash->{json} = {
            result => $self->result || '',
            error  => $self->error || '',
        };
    }

    $c->forward( $c->view('JSON') );
}

=head1 AUTHOR

Daisuke Murase

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
