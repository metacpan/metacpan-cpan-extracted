package Chandra::Protocol;

use strict;
use warnings;
use Cpanel::JSON::XS ();

our $VERSION = '0.14';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

our $_xs_json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

# _xs_register_bind is now an XSUB in protocol.xs

# XS methods: new, register, schemes, is_registered, inject, js_code

1;

__END__

=head1 NAME

Chandra::Protocol - Custom URL protocol handlers for Chandra applications

=head1 SYNOPSIS

	use Chandra::App;

	my $app = Chandra::App->new(title => 'My App');

	# Register a custom protocol
	$app->protocol->register('myapp', sub {
	    my ($path, $params) = @_;
	    if ($path eq 'settings') {
	        return { page => 'settings', user => $params->{user} };
	    }
	    return { page => $path };
	});

	$app->set_content(q{
	    <a href="myapp://settings?user=admin">Settings</a>
	    <a href="myapp://about">About</a>
	});
	$app->run;

	# In JavaScript:
	#   window.__chandraProtocol.navigate('myapp://dashboard?tab=home')
	#     .then(result => console.log(result));

=head1 DESCRIPTION

Chandra::Protocol enables custom URL scheme handling in Chandra
applications.  When a user clicks a link with a registered scheme
(e.g. C<myapp://path?key=val>), the click is intercepted and the
registered Perl handler is called with the path and parsed query
parameters.

Handlers can also be invoked programmatically from JavaScript via
C<window.__chandraProtocol.navigate(url)>.

The injected JavaScript also transparently intercepts C<< <link> >>,
C<< <script> >>, C<< <img> >>, and C<fetch()> calls whose URLs match
a registered scheme.  For C<< <link> >> and C<< <script> >> elements
the content is fetched via the Perl handler and injected inline; for
C<< <img> >> elements the data is base64-encoded into a data URI.
A C<MutationObserver> watches for dynamically added elements as well.

To avoid C<"Failed to load resource: unsupported URL"> warnings in the
developer console, use C<data-href> / C<data-src> attributes instead of
plain C<href> / C<src>:

    <link rel="stylesheet" data-href="myapp://css/style.css">
    <script data-src="myapp://js/app.js"></script>
    <img data-src="myapp://images/logo.png">

Both forms (C<data-*> and native attributes) are supported.

This is implemented entirely in Perl + JavaScript — no C-level
protocol registration is required.

=head1 METHODS

=head2 new(%args)

Create a new Protocol instance.  Usually accessed via C<< $app->protocol >>.

=head2 register($scheme, $coderef)

Register a handler for a custom URL scheme.  The handler receives
C<($path, $params_hashref)>.

=head2 schemes()

List all registered scheme names.

=head2 is_registered($scheme)

Check whether a scheme is registered.

=head2 inject()

Inject the protocol handler JavaScript.  Called automatically by
C<< Chandra::App->run() >> when protocols are registered.

=head2 js_code()

Return the JavaScript source for manual injection.

=head1 SEE ALSO

L<Chandra::App>

=cut
