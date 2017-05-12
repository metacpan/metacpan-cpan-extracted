package CGI::Application::Demo::Dispatch;

# Author:
#	Ron Savage <ron@savage.net.au>

our $VERSION = '1.05';

# -----------------------------------------------

1;

=head1 NAME

C<CGI::Application::Demo::Dispatch> - Demonstrate the delights of CGI::Application::Dispatch

=head1 Synopsis

A classic CGI script:

	use strict;
	use warnings;

	use CGI;
	use CGI::Application::Dispatch;

	# ---------------------

	my($cgi) = CGI -> new();

	CGI::Application::Dispatch -> dispatch
	(
		args_to_new => {QUERY => $cgi},
 		prefix      => 'CGI::Application::Demo::Dispatch',
 		table       =>
		[
 		''         => {app => 'Menu', rm => 'display'},
 		':app'     => {rm => 'initialize'},
 		':app/:rm' => {},
		],
	);

A Plack script:

	#!/usr/bin/env perl
	#
	# Run with:
	# starman -l 127.0.0.1:5021 --workers 1 httpd/cgi-bin/cgi/application/demo/dispatch/dispatch.psgi &
	# or, for more debug output:
	# plackup -l 127.0.0.1:5021 httpd/cgi-bin/cgi/application/demo/dispatch/dispatch.psgi &

	use strict;
	use warnings;

	use CGI::Application::Dispatch::PSGI;

	use Plack::Builder;

	# ---------------------

	my($app) = CGI::Application::Dispatch -> as_psgi
	(
		 prefix      => 'CGI::Application::Demo::Dispatch',
		 table       =>
		 [
		  ''         => {app => 'Menu', rm => 'display'},
		  ':app'     => {rm => 'initialize'},
		  ':app/:rm' => {},
		 ],
	);

	builder
	{
		enable "Plack::Middleware::Static",
		path => qr!^/(assets|favicon|yui)/!,
		root => '/dev/shm/html';
		$app;
	};

A modern FCGI script:

	use strict;
	use warnings;

	use CGI::Application::Dispatch;
	use CGI::Fast;
	use FCGI::ProcManager;

	# ---------------------

	my($proc_manager) = FCGI::ProcManager -> new({n_processes => 2});

	$proc_manager -> pm_manage();

	my($cgi);

	while ($cgi = CGI::Fast -> new() )
	{
		$proc_manager -> pm_pre_dispatch();

		CGI::Application::Dispatch -> dispatch
		(
		 args_to_new => {QUERY => $cgi},
		 prefix      => 'CGI::Application::Demo::Dispatch',
		 table       =>
		 [
		  ''         => {app => 'Menu', rm => 'display'},
		  ':app'     => {rm => 'initialize'},
		  ':app/:rm' => {},
		 ],
		);

		$proc_manager -> pm_post_dispatch();
	}

=head1 Description

C<CGI::Application::Demo::Dispatch> demonstrates the delights CGI::Application::Dispatch.

It ships with:

=over 4

=item Two instance scripts: dispatch.cgi and dispatch

I<dispatch.cgi> is a trivial C<CGI> script, while I<dispatch> is a fancy script which uses C<FCGI::ProcManager>.

Both use C<CGI::Application::Dispatch>.

Trivial here refers to using a classic C<CGI>-style script, while fancy refers to using a modern C<FCGID>-style script.

The word fancy was chosen because it allows you to use fancier URLs. For samples, see I<Start Testing>, below.

The scripts are shipped as ./httpd/cgi-bin/dispatch.cgi and ./htdocs/local/dispatch.

These directory names were chosen because you'll be installing I<dispatch.cgi> in your web server's cgi-bin/
directory, whereas you'll install I<dispatch> in a directory under your web server's doc root.

For home-grown modules, I use the namespace Local::*, and for local web server scripts I use the
directory local/ under Apache's doc root.

For C<FCGID>, see http://fastcgi.coremail.cn/.

C<FCGID> is a replacement for the older C<FastCGI>. For C<FastCGI>, see http://www.fastcgi.com/drupal/.

Also, edit I<dispatch.cgi> and I<dispatch> to fix the 'use lib' line. See the I<Note> in those files for details.

=item A set of C<HTML::Template> templates: *.tmpl

See ./htdocs/assets/templates/cgi/application/demo/dispatch/*.

=item A patch to httpd.conf, if you run Apache and FCGID.

See ./httpd/conf/httpd.conf.

Yes, I realise that if you run FCGID you already have this patch installed, but there's nothing
wrong with having such information documented in various places.

=item This Perl module: C<CGI::Application::Demo::Dispatch>

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing distros.

=head1 Installation

All these assume your doc root is /dev/shm/html (/dev/shm/ is Debian's RAM disk).
This really should be read from a config file. See Base.pm line 18.

You will need to patch C<CGI::Application::Demo::Dispatch::Base>, since it where C<HTML::Template>'s
tmpl_path is stored, if using another path.

=head2 Install the module

Note: I<Build.PL> and I<Makefile.PL> refer to C<FCGI::ProcManager>. If you are not going to use
the fancy script, you don't need C<FCGI::ProcManager>.

Install C<CGI::Application::Demo::Dispatch> as you would for any C<Perl> module:

Run I<cpan>: shell>sudo cpan CGI::Application::Demo::Dispatch

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

=head2 Install the C<HTML::Template> files.

Copy the distro's ./htdocs/assets/ directory to your doc root.

=head2 Install the trivial instance script

Copy the distro's ./httpd/cgi-bin/dispatch.cgi to your cgi-bin/ directory,
and make I<dispatch.cgi> executable.

=head2 Install the fancy instance script

Copy the distro's ./htdocs/local/ directory to your doc root, and make I<dispatch> executable.

=head2 Configure C<Apache> to use /local/dispatch

If in fancy mode, add these to C<Apache>'s httpd.conf:

	LoadModule fcgid_module modules/mod_fcgid.so

and:

	<Location /local>
		SetHandler fcgid-script
		Options ExecCGI
		Order deny,allow
		Deny from all
		Allow from 127.0.0.1
	</Location>

Note: My use of '/local' is not mandatory; you could use any URL fragment there.

And don't forget to restart C<Apache> after editing it's httpd.conf.

=head2 Start testing

Point your broswer at http://127.0.0.1/cgi-bin/dispatch.cgi (trivial script), or
http://127.0.0.1/local/dispatch (fancy script).

=head1 Author

C<CGI::Application::Demo::Dispatch> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2009, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
