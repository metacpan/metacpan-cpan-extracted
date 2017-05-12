package TestApp::Controller::Test;

use strict;
use warnings;
use base 'Catalyst::Controller';

use Data::Dump qw/dump/;
use FindBin;

=head1 NAME

TestApp::Controller::Test - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched TestApp::Controller::Test in Test.');
}

=head2 sendfile

=cut

sub sendfile: Local {
		my ($self, $c) = @_;

		$c->stash->{reproxy_file} = $c->path_to('DUMMY')->stringify;
		$c->forward('View::ReproxyFile');
}

=head2 proxy_file

=cut

sub proxy_file: Local {
		my ($self, $c) = @_;

		$c->stash->{reproxy_file} = $c->path_to('DUMMY')->stringify;
		$c->forward('View::ReproxyFile');
}

=head2 proxy_url

=cut

sub proxy_url: Local {
		my ($self, $c) = @_;

		$c->stash->{reproxy_url} = [
				( map { $c->backend_base_url . $_ } qw/DUMMY1 DUMMY2/ )
		];

		$c->forward('View::ReproxyFile');
}

=head1 AUTHOR

Toru Yamaguchi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
