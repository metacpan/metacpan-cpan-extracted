package CGI::Snapp::Demo::One;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '1.02';

# ------------------------------------------------

sub build_head
{
	my($self)     = @_;
	my $localtime = localtime();
	my($package)  = __PACKAGE__;

	return "<html><head><title>$package</title></head><body>This module is: $package.<br />The time is: $localtime.<br />";

} # End of build_head.

# ------------------------------------------------

sub build_tail
{
	my($self) = @_;

	return '</body></html>';

} # End of build_tail.

# ------------------------------------------------

sub first_rm_method
{
	my($self)    = @_;
	my($package) = __PACKAGE__;

	return $self -> build_head . $self -> build_tail;

} # End of first_rm_method.

# ------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> start_mode('first_rm');
	$self -> run_modes(first_rm => 'first_rm_method');

} # End of setup.

# ------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Demo::One - A template-free demo of CGI::Snapp using just 1 run mode

=head1 Synopsis

After installing the module, do one or both of:

=over 4

=item o Use the L<CGI> script

Unpack the distro and copy http/cgi-bin/cgi.snapp.one.cgi to your web server's cgi-bin/ directory, and make it executable.

Then browse to http://127.0.0.1/cgi-bin/cgi.snapp.one.cgi.

=item o Use the L<PSGI> script

Note: In order to not require users to install L<Starman> or L<Plack>, they have been commented out in Build.PL and Makefile.PL.

Edit httpd/cgi-bin/cgi.snapp.one.psgi and change my value for the web server's doc root from /dev/shm/html to match your set up.

/dev/shm/ is a directory provided by L<Debian|http://www.debian.org/> which is actually a RAM disk, and within that my doc root is the sub-directory /dev/shm/html/.

Then, install L<Plack> and/or L<Starman> and then do one or both of:

=over 4

=item o Use L<Starman>

Start starman with: starman -l 127.0.0.1:5171 --workers 1 httpd/cgi-bin/cgi.snapp.one.psgi &

=item o Use L<Plack>

Start plackup with: plackup -l 127.0.0.1:5171 httpd/cgi-bin/cgi.snapp.one.psgi &

=back

Then, with either starman or plackup, direct your browser to hit 127.0.0.1:5171/.

These commands are copied from comments within httpd/cgi-bin/cgi.snapp.one.psgi. The value 5171 is of course just a suggestion. All demos in this series use port 5171 and up.

=back

=head1 Description

Shows how to write a minimal CGI script using L<CGI::Snapp>, with 1 run mode.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<CGI::Snapp::Demo::One> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp::Demo::One

or run:

	sudo cpan CGI::Snapp::Demo::One

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($app) = CGI::Snapp::Demo::One -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp::Demo::One>.

See http/cgi-bin/cgi.snapp.one.cgi.

=head1 Methods

=head2 run()

Runs the code which responds to HTTP requests.

See http/cgi-bin/cgi.snapp.one.cgi.

=head1 Troubleshooting

=head2 It doesn't work!

Hmmm. Things to consider:

=over 4

=item o Run the *.cgi script from the command line

shell> perl httpd/cgi-bin/cgi.snapp.one.cgi

If that doesn't work, you're in b-i-g trouble. Keep reading for suggestions as to what to do next.

=item o The system Perl 'v' perlbrew

Are you using perlbrew? If so, recall that your web server will use the first line of http/cgi-bin/cgi.snapp.one.cgi to find a Perl, and that line says #!/usr/bin/env perl.

So, you'd better turn perlbrew off and install L<CGI::Snapp> and this module under the system Perl, before trying again.

=item o Generic advice

L<http://www.perlmonks.org/?node_id=380424>.

=back

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

L<CGI::Snapp::Demo::One> - A template-free demo of CGI::Snapp using just 1 run mode

L<CGI::Snapp::Demo::Two> - A template-free demo of CGI::Snapp using N run modes

L<CGI::Snapp::Demo::Three> - A template-free demo of CGI::Snapp using the forward() method.

L<CGI::Snapp::Demo::Four> - A template-free demo of CGI::Snapp using Log::Handler::Plugin::DBI

L<CGI::Snapp::Demo::Four::Wrapper> - A wrapper around CGI::Snapp::Demo::Four, to simplify using Log::Handler::Plugin::DBI

L<Config::Plugin::Tiny> - A plugin which uses Config::Tiny

L<Config::Plugin::TinyManifold> - A plugin which uses Config::Tiny with 1 of N sections

L<Data::Session> - Persistent session data management

L<Log::Handler::Plugin::DBI> - A plugin for Log::Handler using Log::Hander::Output::DBI

L<Log::Handler::Plugin::DBI::CreateTable> - A helper for Log::Hander::Output::DBI to create your 'log' table

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Demo::One>.

=head1 Author

L<CGI::Snapp::Demo::One> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
