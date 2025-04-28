package Catalyst::View::TT::Progressive;

use strict;
use warnings;

use Moose; # Catalyst::View;
extends 'Catalyst::View::TT';
our $VERSION = '0.04';
use JSON;

around 'render' => sub {
	my ($meth, $orig, $c, $template, $args) = (@_, $_[2]->stash());
	my ($wrapper, $ext) = (
		($args->{WRAPPER} || $c->req->header($orig->config->{WRAPPER_HEADER} || 'WRAPPER') || $orig->config->{WRAPPER}),
		($orig->config->{TEMPLATE_EXTENSION} || '.tt')
	);
	$wrapper .= $ext unless (!$wrapper || $wrapper =~ m/\Q$ext\E/);
	$orig->{template}->{SERVICE}->{WRAPPER} = ($args->{NO_WRAPPER} || $c->req->header($orig->config->{NO_WRAPPER_HEADER} || 'NO_WRAPPER'))
			? []
			: [$wrapper];
	$orig->$meth($c, $template, $args);
};


sub process {
	my ( $self, $c ) = @_;

	my $template = $c->stash->{template}
	  ||  $c->action . $self->config->{TEMPLATE_EXTENSION};

	unless (defined $template) {
		$c->log->debug('No template specified for rendering') if $c->debug;
		return 0;
	}

	local $@;
	my $output = eval { $self->render($c, $template) };
	if (my $err = $@) {
		return $self->_rendering_error($c, $template . ': ' . $err);
	}
	if (blessed($output) && $output->isa('Template::Exception')) {
		$self->_rendering_error($c, $output);
	}

	if ($c->stash->{JSON}) {
		my $body = $self->build_json($c, $c->stash->{JSON});
		$body->{html} = $output;
		$output = JSON->new->encode($body);
		$c->response->content_type("application/json; charset=UTF-8");
	} else {
		unless ( $c->response->content_type ) {
			my $default = $self->content_type || 'text/html; charset=UTF-8';
			$c->response->content_type($default);
		}
	}

	$c->response->body($output);

	return 1;
}

sub build_json {
	my ($self, $c, $json) = @_;
	return ref $json ? $json : {};
}

1;

__END__

=head1 NAME

Catalyst::View::TT::Progressive - Control the wrapper

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	package MyApp::View::HTML;

	use Moose;
	extends 'Catalyst::View::TT::Progressive';

	__PACKAGE__->config(
		TEMPLATE_EXTENSION => '.tt',
		INCLUDE_PATH => [
			MyApp->path_to('root', 'templates'),
		],
		TIMER => 0,
		WRAPPER => 'wrapper.tt',
		WRAPPER_HEADER => 'WRAPPER',
		NO_WRAPPER_HEADER => 'NO_WRAPPER'
	);

	1;

=== wrapper.tt ===

	<!doctype html>
	<html lang="en">
		<head>
			<meta charset="utf-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<meta name="description" content="A basic test application.">
			<title>Test Application</title>
			<link rel="stylesheet" href="/static/css/app.css" integrity="sha384-" crossorigin="anonymous">
		</head>
		<body>
			<div id="layout">
				<a href="#menu" id="menuLink" class="menu-link">
					<span></span>
				</a>
				<div id="menu">
					<a class="menu-heading" href="#">Company</a>

					<ul class="menu-list">
						<li class="menu-item menu-selected">
							<a href="[% c.uri_for('/') %]" class="menu-link">Home</a>
						</li>
						<li class="menu-item">
							<a href="[% c.uri_for('/one') %]" class="menu-link">One</a>
						</li>
						<li class="menu-item menu-item-divided">
							<a href="[% c.uri_for('/two') %]" class="menu-link">Two</a>
						</li>
						<li class="menu-item">
							<a href="[% c.uri_for('/three') %]" class="menu-link">Three</a>
						</li>
					</ul>
				</div>
				<div id="main" progressive>
					[% content %]
				</div>
			</div>
			<script src="/static/js/app.js"></script>
		</body>
	</html>

=== new_wrapper.tt ===
	
	[% content %]

=== Your app.js === 

	// A naive implementation
	(function () {
		var progressive = {	
			menu: document.getElementById('menu'),
			request: function (url, cb, ecb) {
				if (url.match('^#')) return;
				var request = new XMLHttpRequest();
				request.onreadystatechange = function () {
					if (request.readyState === XMLHttpRequest.DONE) request.status === 200 ? cb(request.response) : ecb(request);
				};
				request.open('GET', url);
				request.setRequestHeader('WRAPPER', 'new_wrapper.tt');
				request.send();
			},
			render: function (res) {
				var wrapper = document.querySelector('[progressive]');
				wrapper.innerHTML = res;
			},
			error: function (req) {}
		};

		window.addEventListener('click', function (event) {
			if (event.target.tagName === 'A') {
				event.preventDefault();
				progressive.request(event.target.href, progressive.render, progressive.error);
			}
		});

		document.querySelectorAll('.menu-link').forEach(function (link) {
			link.addEventListener('click', function (event) {
				progressive.menu.querySelector('.menu-selected').classList.remove('menu-selected');
				event.target.parentNode.classList.add('menu-selected');
			});
		});

		...

	})();


=== Alternative app.js when handling a json response ===

	$c->stash(JSON => {
		abc => 1
	});
 
	(function () {
		var progressive = {	
			menu: document.getElementById('menu'),
			request: function (url, cb, ecb) {
				if (url.match('^#')) return;
				var request = new XMLHttpRequest();
				request.onreadystatechange = function () {
					if (request.readyState === XMLHttpRequest.DONE) request.status === 200 
						? cb(JSON.parse(request.response)) 
						: ecb(request); 
				};
				request.open('GET', url);
				request.setRequestHeader('api', 1);
				request.setRequestHeader('WRAPPER', 'new_wrapper.tt');
				request.send();
			},
			render: function (res) {
				var wrapper = document.querySelector('[progressive]');
				wrapper.innerHTML = res.html;
				if (res.abc) {
					... instantiate some JS ...
				}
			},
			error: function (req) {}
		};

		...
	})();

when using this approach you may want to prevent accessing of endpoints directly from a browser an easy way of achieving this is checking for a header in Root->auto and then redirecting.

        unless ($c->req->header('api')) {
                $c->response->redirect($c->uri_for('/invalid_url'));
                return;
        }

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-tt-progressive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-TT-Progressive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::TT::Progressive

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-TT-Progressive>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-TT-Progressive/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019->2025 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Catalyst::View::TT::Progressive
