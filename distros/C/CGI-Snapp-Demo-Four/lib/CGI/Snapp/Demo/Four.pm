package CGI::Snapp::Demo::Four;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '1.02';

# ------------------------------------------------

sub build_form
{
	my($self, $run_mode, $next_mode) = @_;

	$self -> log(debug => "build_form($run_mode, $next_mode)");

	return "<br /><form id='four_form'>This is run mode '$run_mode'.<br /><button id='submit'>Click to submit run mode '$next_mode'</button><input type='hidden' name='rm' id='rm' value='$next_mode' /></form>";

} # End of build_form.

# ------------------------------------------------

sub build_head
{
	my($self) = @_;

	$self -> log(debug => 'build_head()');

	my $localtime = localtime();
	my($package)  = __PACKAGE__;

	return "<html><head><title>$package</title></head><body>This module is: $package.<br />The time is: $localtime.<br />";

} # End of build_head.

# ------------------------------------------------

sub build_tail
{
	my($self) = @_;

	$self -> log(debug => 'build_tail()');

	return '</body></html>';

} # End of build_tail.

# ------------------------------------------------

sub build_visits
{
	my($self) = @_;

	$self -> log(debug => 'build_visits()');

	my($html) = '';
	$html     .= "Methods visited which are hooked to run before setup(),<br />in which case they can't don't normally contribute to the HTML:<br />cgiapp_init()<br />";
	$html     .= '<br />Methods visited which are not run modes:<br />' . join('<br />', @{$self -> param('non_mode_visited')}) . '<br />';
	$html     .= '<br />Methods visited which are run modes:<br />' . join('<br />', @{$self -> param('run_mode_visited')}) . '<br />';
	$html     .= "<br />Methods not visited until after the run mode runs,<br />in which case they can't contribute to the HTML:</br />" .
		join('<br />', 'cgiapp_postrun()', 'teardown()') . '<br />';

	return $html;

} # End of build_visits.

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;
	my($ara)  = $self -> param('non_mode_visited');

	$self -> log(debug => 'cgiapp_prerun()');

	push @$ara, 'cgiapp_prerun()';

	$self -> param(non_mode_visited => $ara);

} # End of cgiapp_prerun.

# --------------------------------------------------
# You don't see the output from this method because it runs after the run modes have build the HTML.

sub cgiapp_postrun
{
	my($self) = @_;
	my($ara)  = $self -> param('non_mode_visited');

	$self -> log(debug => 'cgiapp_postrun()');

	push @$ara, 'cgiapp_postrun()';

	$self -> param(non_mode_visited => $ara);

} # End of cgiapp_postrun.

# ------------------------------------------------

sub first_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	$self -> log(debug => 'first_rm_method()');

	push @$ara, 'first_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> build_head . $self -> build_form($self -> get_current_runmode, 'second_rm') . $self -> build_visits . $self -> build_tail;

} # End of first_rm_method.

# ------------------------------------------------

sub second_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	$self -> log(debug => 'second_rm_method()');

	push @$ara, 'second_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> build_head . $self -> build_form($self -> get_current_runmode, 'third_rm') . $self -> build_visits . $self -> build_tail;

} # End of second_rm_method.

# ------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> log(debug => 'setup()');

	$self -> param(run_mode_visited => []);
	$self -> param(non_mode_visited => []);
	$self -> start_mode('first_rm');
	$self -> run_modes(first_rm => 'first_rm_method', second_rm => 'second_rm_method', third_rm => 'third_rm_method');

} # End of setup.

# ------------------------------------------------

sub third_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	$self -> log(debug => 'third_rm_method()');

	push @$ara, 'third_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> build_head . $self -> build_form($self -> get_current_runmode, 'first_rm') . $self -> build_visits . $self -> build_tail;

} # End of third_rm_method.

# ------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Demo::Four - A template-free demo of CGI::Snapp using Log::Handler::Plugin::DBI

=head1 Synopsis

After installing the module (see L</Installation>), do one or both of:

=over 4

=item o Use the L<CGI> script

Unpack the distro and copy http/cgi-bin/cgi.snapp.four.cgi to your web server's cgi-bin/ directory, and make it executable.

Then browse to http://127.0.0.1/cgi-bin/cgi.snapp.four.cgi.

=item o Use the L<PSGI> script

Note: In order to not require users to install L<Starman> or L<Plack>, they have been commented out in Build.PL and Makefile.PL.

Edit httpd/cgi-bin/cgi.snapp.four.psgi and change my value for the web server's doc root from /dev/shm/html to match your set up.

/dev/shm/ is a directory provided by L<Debian|http://www.debian.org/> which is actually a RAM disk, and within that my doc root is the sub-directory /dev/shm/html/.

Then, install L<Plack> and L<Starman> and then do one or both of:

=over 4

=item o Use L<Starman>

Start starman with: starman -l 127.0.0.1:5174 --workers 1 httpd/cgi-bin/cgi.snapp.four.psgi &

=item o Use L<Plack>

Start plackup with: plackup -l 127.0.0.1:5174 httpd/cgi-bin/cgi.snapp.four.psgi &

=back

Then, with either starman or plackup, direct your browser to hit 127.0.0.1:5174/.

These commands are copied from comments within httpd/cgi-bin/cgi.snapp.four.psgi. The value 5174 is of course just a suggestion. All demos in this series use port 5171 and up.

=back

=head1 Description

This is a version of L<CGI::Snapp::Demo::Two> which shows how to use a plugin such as L<Log::Handler::Plugin::DBI> within a CGI script based on L<CGI::Snapp>.

The output reports which methods were and were not entered per run mode.

Using a plugin easily requires a wrapper class, which here is L<CGI::Snapp::Demo::Four::Wrapper>. That's why httpd/cgi-bin/cgi.snapp.demo.four.cgi uses the wrapper instead
of using this module directly.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

=head2 Installing the module

Install L<CGI::Snapp::Demo::Four> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp::Demo::Four

or run:

	sudo cpan CGI::Snapp::Demo::Four

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

=head2 Configuring the L<CGI> script's source code and the logger's config file

You I<must> edit both the source code of httpd/cgi-bin/cgi.snapp.demo.four.cgi and the config (text) file, to make this demo work.

Details:

=over 4

=item o The L<CGI> script's source code

In cgi.snapp.demo.four.cgi you'll see this code (which is my default set up, /dev/shm/ being Debian's RAM disk):

	my($doc_root)    = $ENV{DOC_ROOT} || '/dev/shm';
	my($config_dir)  = "$doc_root/assets/config/cgi/snapp/demo/four";
	my($config_file) = "$config_dir/config.logger.conf";

Adjust those 3 lines to suit your environment.

Then copy cgi.snapp.demo.four.cgi to your web server's cgi-bin/ directory, and make it executable.

=item o The logger's config file

This module ships with t/config.logger.conf, which is a copy of the same file from L<Log::Handler::Plugin::DBI>.

So, copy the file t/config.logger.conf to $config_file, as above, and edit it as desired.

L<Log::Handler::Plugin::DBI> ships with a program, scripts/create.table.pl, which can be used to create the 'log' table, using this very config file.

That module's L<FAQ|Log::Handler::Plugin::DBI#FAQ> describes the expected structure of the 'log' table.

=back

With everything in place, and having run the L<CGI> script from the command line (as recommended in L</Troubleshooting>), continue with the procedure suggested in the L</Synopsis>.

=head1 Constructor and Initialization

C<new()> is called as C<< my($app) = CGI::Snapp::Demo::Four -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp::Demo::Four>.

See http/cgi-bin/cgi.snapp.four.cgi.

=head1 Methods

=head2 run()

Runs the code which responds to HTTP requests.

See http/cgi-bin/cgi.snapp.four.cgi.

=head1 Troubleshooting

=head2 It doesn't work!

Hmmm. Things to consider:

=over 4

=item o Run the *.cgi script from the command line

shell> perl httpd/cgi-bin/cgi.snapp.four.cgi

If that doesn't work, you're in b-i-g trouble. Keep reading for suggestions as to what to do next.

=item o Check your edits to Four.pm and config.logger.conf

Most likely the edits are wrong, or the files are installed in the wrong directories, or the file permissions are wrong.

=item o The system Perl 'v' perlbrew

Are you using perlbrew? If so, recall that your web server will use the first line of http/cgi-bin/cgi.snapp.four.cgi to find a Perl, and that line says #!/usr/bin/env perl.

So, you'd better turn perlbrew off and install this module under the system Perl, before trying again.

=item o Generic advice

L<http://www.perlmonks.org/?node_id=380424>.

=back

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

L<CGI::Snapp::Demo::One> - A template-free demo of CGI::Snapp using just 1 run mode

L<CGI::Snapp::Demo::Two> - A template-free demo of CGI::Snapp using N run modes

L<CGI::Snapp::Demo::Three> - A template-free demo of CGI::Snapp using the forward() method

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

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Demo::Four>.

=head1 Author

L<CGI::Snapp::Demo::Four> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
