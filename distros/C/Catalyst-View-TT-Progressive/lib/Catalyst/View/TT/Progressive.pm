package Catalyst::View::TT::Progressive;

use strict;
use warnings;

use Moose; # Catalyst::View;
extends 'Catalyst::View::TT';
our $VERSION = '0.01';

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

1;

__END__

=head1 NAME

Catalyst::View::TT::Progressive - Control the wrapper

=head1 VERSION

Version 0.01

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
			<meta name="description" content="A layout example with a side menu that hides on mobile, just like the Pure website.">
			<title>Responsive Side Menu &ndash; Layout Examples &ndash; Pure</title>

			<link rel="stylesheet" href="/static/css/pure-min.css" integrity="sha384-" crossorigin="anonymous">
				<!--[if lte IE 8]>
					<link rel="stylesheet" href="css/layouts/side-menu-old-ie.css">
				<![endif]-->
				<!--[if gt IE 8]><!-->
					<link rel="stylesheet" href="/static/css/layouts/side-menu.css">
				<!--<![endif]-->
		</head>
		<body>
			<div id="layout">
				<!-- Menu toggle -->
				<a href="#menu" id="menuLink" class="menu-link">
					<!-- Hamburger icon -->
					<span></span>
				</a>
				<div id="menu">
					<div class="pure-menu">
						<a class="pure-menu-heading" href="#">Company</a>

						<ul class="pure-menu-list">
							<li class="pure-menu-item pure-menu-selected"><a href="[% c.uri_for('/') %]" class="pure-menu-link">Home</a></li>
							<li class="pure-menu-item"><a href="[% c.uri_for('/one') %]" class="pure-menu-link">One</a></li>
							<li class="pure-menu-item menu-item-divided">
								<a href="[% c.uri_for('/two') %]" class="pure-menu-link">Two</a>
							</li>
							<li class="pure-menu-item"><a href="[% c.uri_for('/three') %]" class="pure-menu-link">Three</a></li>
						</ul>
					</div>
				</div>
				<div id="main" progressive>
					[% content %]
				</div>
			</div>
			<script src="/static/js/app.js"></script>
		</body>
	</html>

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
			}
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

		document.querySelectorAll('.pure-menu-link').forEach(function (link) {
			link.addEventListener('click', function (event) {
				progressive.menu.querySelector('.pure-menu-selected').classList.remove('pure-menu-selected');
				event.target.parentNode.classList.add('pure-menu-selected');
			});
		});

		....

	})();
		
L<https://developers.google.com/web/progressive-web-apps/>

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

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-TT-Progressive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-TT-Progressive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-TT-Progressive>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-TT-Progressive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 LNATION.

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
