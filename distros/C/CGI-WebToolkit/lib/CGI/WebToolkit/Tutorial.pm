package CGI::WebToolkit::Tutorial;

use 5.008006;

1;
__END__

=head1 NAME

CGI::WebToolkit::Tutorial

=head1 SYNOPSIS

This tutorial is a brief startup guide for working with CGI::WebToolkit
in order to create a dynamic website.

=head1 DESCRIPTION

=head2 Summary

This tutorial will give instructions on how to create a website with
CGI::WebToolkit. This process can be broken down into the following
steps, each of which is explained in detail below.

=over 1

=item 1 Install the module CGI::WebToolkit.

=item 2 Create the directory structure.

=item 3 Create a cgi script.

=item 4 Create a basic workflow function.

=back

=head2 Install the module CGI::WebToolkit

The CGI::WebToolkit module is a pure perl module and is usually
installed via the cpan shell. To do this you need the cpan shell
installed on your machine (Note: the cpan shell comes with most
perl distributions):

	$ sudo cpan
	...
	cpan> install CGI::WebToolkit
	...
	cpan> exit

If this does not work, you can also install the module manually.
Go to http://www.cpan.org, search for "CGI::WebToolkit",
download the latest version and unpack it. Start your shell
or command prompt and go into the unpacked module directory:

	$ perl Makefile.PL
	$ make
	$ make test
	$ sudo make install

This should install the CGI::WebToolkit module globally to
your system. If you have already downloaded the module, you
can keep it, because it contains files we later need for
the simple example website.

To test weither it was installed successfully, try to load
the module documentation:

	$ perldoc CGI::WebToolkit

=head2 Create the directory structure

In the following examples the name of this project will be "my_project".

Go to http://www.cpan.org, search for "CGI::WebToolkit",
download the latest version and unpack it.

Create a directory on your server that is accessable via http, aka
inside the document root of your webserver. Go into the unpacked
module directory and copy all subdirectories from I<t/public/>
to the directory of yours.

It should now contain the following subdirectories:

	core/
	themes/
	uploads/

Make the I<uploads/> subdirectory writeable to the webserver user.

Then create another directory which is I<not> accessable via http,
aka outside of the document root of your webserver. Go into the unpacked
module directory and copy all subdirectories from I<t/private/>
to the directory of yours.

It should now contain the following subdirectories:

	accesschecks/
	accessconfigs/
	cacheconfigs/
	configs/
	generators/
	javascripts/
	logs/
	modules/
	schemas/
	styles/	
	templates/
	workflows/

There is only one thing left to do in order to get a working website:
a cgi script.

=head2 Create a cgi script

Go to the directory on your server where cgi Perl scripts are executed
and create a new script, while making the file itself executable:

	#!/usr/bin/perl
	
	use strict;
	use CGI::Carp qw(fatalsToBrowser);
	use CGI::WebToolkit;
	
	my $wtk = CGI::WebToolkit->new(
		-privatepath => '/path/to/your/private/directory',
		-publicpath  => '/path/to/your/public/directory',
		-publicurl   => 'http://url.of.your.site/path/to/public/directory/',
		-cgipath     => '/path/to/your/cgi/directory',
		-cgiurl      => 'http://url.of.your.site/path/to/cgi/directory/',
		-entryaction => 'my_project.home',
	);
	
	print $wtk->handle();

Please, fill out the paths and urls so they match the configuration of
your webserver, otherwise it won't work. Sometimes that Perl executable
is in another location that I<#!/usr/bin/perl> - adjust it your
architecture.

=head2 Create a basic workflow function

Go to your private directory, into the subdirectory I<workflows> and
create a subdirectory I<my_project>. This will contain all the workflow
functions for this simple example website.

In this newly created subdirectory, create a file called I<home.pl>
with this content:

	return output(1,'ok',"Hello, World!");

Startup your favourite webbrowser and go to the url of your cgi script.
You should see the words "Hello, World!". You have successfully created
a simple website using CGI::WebToolkit.

=head2 Go on from here

Read in the documentation of CGI::WebToolkit about other configuration
options, database access, caching, localization, sessions and access
management etc. Have fun!

=head1 EXPORT

None.

=head1 SEE ALSO

CGI::WebToolkit.

There is no website for this module.

If you have any questions, hints or something else to say,
please mail to tokirc@gmx.net or post in the comp.lang.perl.modules
mailing list- thank you for helping make CGI::WebToolkit better!

=head1 AUTHOR

Tom Kirchner, tokirc@gmx.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
