package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

=head2 test_sendfile

=cut

sub test_sendfile : Local {
		my ($self, $c) = @_;

		my $config = $c->view('ReproxyFile')->config;

		$config->{lighttpd} = 1;
		$config->{perlbal} = 0;

		$c->stash->{reproxy_file} = '/etc/passwd';
		$c->forward('View::ReproxyFile');
}

=head2 test_reproxy_file

=cut

sub test_reproxy_file : Local {
		my ($self, $c) = @_;

		my $config = $c->view('ReproxyFile')->config;

		$config->{lighttpd} = 0;
		$config->{perlbal} = 1;

		$c->stash->{reproxy_file} = '/etc/passwd';
		$c->forward('View::ReproxyFile');
}

=head2 test_reproxy_url

=cut

sub test_reproxy_url: Local {
		my ($self, $c) = @_;

		my $config = $c->view('ReproxyFile')->config;

		$config->{lighttpd} = 0;
		$config->{perlbal} = 1;

		# 'path2' => 'http://127.0.0.1:7500/dev1/0/000/000/0000000337.fid',
		# 'path1' => 'http://127.0.0.1:7500/dev3/0/000/000/0000000337.fid',

		$c->stash->{reproxy_url} = [
				'http://127.0.0.1:7500/dev1/0/000/000/0000000337.fid', 
				'http://127.0.0.1:7500/dev3/0/000/000/0000000337.fid'
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
