package Catalyst::Plugin::CustomErrorMessage;

=head1 NAME

Catalyst::Plugin::CustomErrorMessage - Catalyst plugin to have more "cute" error message.

=head1 SYNOPSIS

	use Catalyst qw( CustomErrorMessage );
	
	# optional (values in this example are the defaults)
	__PACKAGE__->config->{'custom-error-message'}->{'uri-for-not-found'} = '/';
	__PACKAGE__->config->{'custom-error-message'}->{'error-template'}    = 'error.tt2';
	__PACKAGE__->config->{'custom-error-message'}->{'content-type'}      = 'text/html; charset=utf-8';
	__PACKAGE__->config->{'custom-error-message'}->{'view-name'}         = 'TT';
	__PACKAGE__->config->{'custom-error-message'}->{'response-status'}   = 500;

=head1 DESCRIPTION

You can use this module if you want to get rid of:

	(en) Please come back later
	(fr) SVP veuillez revenir plus tard
	(de) Bitte versuchen sie es spaeter nocheinmal
	(at) Konnten's bitt'schoen spaeter nochmal reinschauen
	(no) Vennligst prov igjen senere
	(dk) Venligst prov igen senere
	(pl) Prosze sprobowac pozniej

What it does is that it inherites finalize_error to $c object.

See finalize_error() function. 

=cut

use base qw{ Class::Data::Inheritable };

use HTML::Entities;
use URI::Escape qw{ uri_escape_utf8 };
use MRO::Compat;

use strict;
use warnings;

our $VERSION = "0.06";


=head1 FUNCTIONS

=head2 finalize_error

In debug mode this function is skipped and user sees the original Catalyst error page in debug mode.

In "production" (non debug) mode it will return page with template set in

	$c->config->{'custom-error-message'}->{'error-template'}
	||
	'error.tt2'

$c->stash->{'finalize_error'} will be set to contain the error message.

For non existing resources (like misspelled url-s) if will do http redirect to

	$c->uri_for(
		$c->config->{'custom-error-message'}->{'uri-for-not-found'}
		||
		'/'
	)

$c->flash->{'finalize_error'} will be set to contain the error message.

To set different view name configure:

	$c->config->{'custom-error-message'}->{'view-name'} = 'Mason';

Content-type and response status can be configured via: 

	$c->config->{'custom-error-message'}->{'content-type'}    = 'text/plain; charset=utf-8';
	$c->config->{'custom-error-message'}->{'response-status'} = 500;

=cut

sub finalize_error {
	my $c = shift;
	my $config = $c->config->{'custom-error-message'} || $c->config->{'custome-error-messsage'} || $c->config->{'custom-error-messsage'};
	
	# in debug mode return the original "page" 
	if ( $c->debug ) {
		$c->maybe::next::method;
		return;
	}
	
	# create error string out of error array
	my $error = join '<br/> ', map { encode_entities($_) } @{ $c->error };
	$error ||= 'No output';

	# for wrong url that has no action associated do redirect
	if (not defined $c->action) {
		$c->flash->{'finalize_error'} = $error;
		$c->_save_flash(); # hack but must be called otherwise the flash data will be lost
		$c->response->redirect($c->uri_for(
			$config->{'uri-for-not-found'}
			||
			'/'
		));

		return;
	}
	
	# render the template
	my $action_name = $c->action->reverse;
	$c->stash->{'finalize_error'} = $action_name.': '.$error;
	$c->response->content_type(
		$config->{'content-type'}
		||
		'text/html; charset=utf-8'
	);
	my $view_name = $config->{'view-name'} || 'TT';
	eval {
		$c->response->body($c->view($view_name)->render($c,
			$config->{'error-template'}
			||
			'error.tt2'
		));
	};
	if ($@) {
		$c->log->error($@);
		$c->maybe::next::method;
	}
	
	my $response_status = $config->{'response-status'};
	$response_status = 500 if not defined $response_status;
	$c->response->status($response_status);
}

1;

=head1 AUTHOR

Jozef Kutej - E<lt>jkutej@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
