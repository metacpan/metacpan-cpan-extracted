package App::Office::Contacts::Donations;

use strict;
use warnings;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '1.10';

# -----------------------------------------------

1;

=head1 NAME

C<App::Office::Contacts::Donation> - A web-based donations manager

=head1 Synopsis

The scripts discussed here, I<donations.cgi> and I<donations.psgi>, are shipped with this module.

A classic CGI script, I<donations.cgi>:

	use strict;
	use warnings;

	use CGI;
	use CGI::Application::Dispatch;

	# ---------------------

	my($cgi) = CGI -> new;

	CGI::Application::Dispatch -> dispatch
	(
		args_to_new => {QUERY => $cgi},
		prefix      => 'App::Office::Contacts::Donations::Controller',
		table       =>
		[
		''              => {app => 'Initialize', rm => 'display'},
		':app'          => {rm => 'display'},
		':app/:rm/:id?' => {},
		],
	);

A L<Plack> script, I<donations.psgi>:

	#!/usr/bin/perl

	use strict;
	use warnings;

	use CGI::Application::Dispatch::PSGI;

	use Plack::Builder;

	# ---------------------

	my($app) = CGI::Application::Dispatch -> as_psgi
	(
		prefix => 'App::Office::Contacts::Donations::Controller',
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

C<App::Office::Contacts::Donations> implements web-based, personal and group, donations.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing distros.

=head1 Installation Pre-requisites

The primary pre-requisite is C<App::Office::Contacts>. You should study the documentation for that
module before proceeding.

=head1 Install the module

Install C<App::Office::Contacts::Donations> as you would for any C<Perl> module:

Run I<cpan>: shell>sudo cpan App::Office::Contacts::Donations

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

Copy the distro's htdocs/assets/ directory to your doc root.

Specifically, my doc root is /var/www/, so I end up with /var/www/assets/.

=head2 Install the trivial CGI script and the L<Plack> script

Copy the distro's httpd/cgi-bin/office/ directory to your web server's cgi-bin/ directory,
and make I<donations.cgi> executable.

My cgi-bin/ dir is /usr/lib/cgi-bin/, so I end up with /usr/lib/cgi-bin/office/donations.cgi.

Now I can run http://127.0.0.1/cgi-bin/office/donations.cgi (but not yet!).

=head2 Creating and populating the database

The distro contains a set of text files which are used to populate constant tables.
All such data is in the data/ directory.

This data is loaded into the 'contacts' database using programs in the distro.
All such programs are in the scripts/ directory.

After unpacking the distro, create and populate the database:

	shell>cd CGI-Office-Contacts-1.00
	shell>perl -Ilib scripts/drop.tables.pl -v
	shell>perl -Ilib scripts/create.tables.pl -v
	shell>perl -Ilib scripts/populate.tables.pl -v
	shell>perl -Ilib scripts/report.tables.pl -v

Note: The '-Ilib' means 2 things:

=over 4

=item Perl looks in the current directory structure for the modules

That is, Perl does not use the installed version of the code, if any.

=item The code looks in the current directory structure for .htoffice.contacts.conf

That is, it does not use the installed version of this file, if any.

=back

So, if you leave out the '-Ilib', Perl will use the version of the code which has been
formally installed, and then the code will look in the same place for .htoffice.contacts.conf.

=head2 Start testing

Point your broswer at http://127.0.0.1/cgi-bin/donations.cgi (trivial script).

=head1 FAQ

=over 4

=item Where does the list of currencies come from?

http://au.finance.yahoo.com/currency

Save this page in data/currencies.html, and run scripts/currency.codes.pl.

=item I'm having trouble dropping and recreating the tables.

Firstly, drop the tables associated with donations, then the basic tables. Then recreate them.

=over 4

=item Donation tables

cd CGI-Office-Contacts-Donations
scripts/drop.tables.pl -v

=item Basic tables

cd CGI-Office-Contacts
scripts/drop.tables.pl -v
scripts/create.tables.pl -v
scripts/populate.tables.pl -v
scripts/report.tables.pl -v

=item Donation tables

cd CGI-Office-Contacts-Donations
scripts/create.tables.pl -v
scripts/populate.tables.pl -v
scripts/report.tables.pl -v

=back

=back

=head1 Support

Email the author, or log a bug on RT:

https://rt.cpan.org/Public/Dist/Display.html?Name=App-Office-Contacts-Donations

=head1 Author

C<App::Office::Contacts::Donations> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2009, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
