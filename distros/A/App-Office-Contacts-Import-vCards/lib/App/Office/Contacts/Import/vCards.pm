package App::Office::Contacts::Import::vCards;

use strict;
use warnings;

our $VERSION = '1.12';

# -----------------------------------------------

1;

=head1 NAME

C<App::Office::Contacts::Import::vCards> - Import vCards for use by App::Office::Contacts

=head1 Synopsis

The scripts discussed here, I<vcards.cgi> and I<vcards.psgi>, are shipped with this module.

A classic CGI script, I<vcards.cgi>:

	use strict;
	use warnings;

	use CGI;
	use CGI::Application::Dispatch;

	# ---------------------

	my($cgi) = CGI -> new;

	CGI::Application::Dispatch -> dispatch
	(
		args_to_new => {QUERY => $cgi},
		prefix      => 'App::Office::Contacts::Import::vCards::Controller',
		table       =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

A L<Plack> script, I<vcards.psgi>:

	#!/usr/bin/perl

	use strict;
	use warnings;

	use CGI::Application::Dispatch::PSGI;

	use Plack::Builder;

	# ---------------------

	my($app) = CGI::Application::Dispatch -> as_psgi
	(
		prefix => 'App::Office::Contacts::Import::vCards::Controller',
		table  =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

	builder
{
		enable "Plack::Middleware::Static",
		path => qr!^/(assets|yui)/!,
		root => '/var/www';
		$app;
	};

For more on Plack, see L<My intro to Plack|http://savage.net.au/Perl/html/plack.for.beginners.html>.

=head1 Description

C<App::Office::Contacts::Import::vCards> implements importing vCards for use by C<App::Office::Contacts>.

C<App::Office::Contacts::Import::vCards> uses C<Moose>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing distros.

=head1 Installation Pre-requisites

The primary pre-requisite is C<App::Office::Contacts>. You should study the documentation for that
module before proceeding.

=head1 Installing the module

Install C<App::Office::Contacts::Import::vCards> as you would for any C<Perl> module:

Run I<cpan>: shell>sudo cpan App::Office::Contacts::Import::vCards

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

Either way, you'll need to install all the other files which are shipped in the distro.

=head2 Install the C<HTML::Template> files.

Copy the distro's htdocs/assets/ directory to your web server's doc root.

Specifically, my doc root is /var/www/, so I end up with /var/www/assets/.

=head2 Install the trivial CGI script and the L<Plack> script

Copy the distro's httpd/cgi-bin/office/ directory to your web server's cgi-bin/ directory,
and make I<vcards.cgi> executable.

So, I end up with /usr/lib/cgi-bin/office/import/vcards.cgi.

Now I can run http://127.0.0.1/cgi-bin/office/import/vcards.cgi.

=head2 Start testing

Point your broswer at http://127.0.0.1/cgi-bin/import/vcards.cgi (trivial script).

=head1 FAQ

=over 4

=item Does the import code guess any values?

Yes, both gender and title are derived from the data, rather than being just pieces
of data. This means neither of these 2 values are guaranteed to be correct.

=back

=head1 Support

Email the author, or log a bug on RT:

https://rt.cpan.org/Public/Dist/Display.html?Name=App-Office-Contacts-Import-vCards

=head1 Author

C<App::Office::Contacts::Import::vCards> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2009, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
