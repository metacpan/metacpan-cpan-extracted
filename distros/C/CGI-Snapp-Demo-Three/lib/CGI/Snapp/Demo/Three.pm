package CGI::Snapp::Demo::Three;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '1.02';

# ------------------------------------------------

sub build_form
{
	my($self, $run_mode, $next_mode) = @_;

	return "<br /><form id='three_form'>This is run mode '$run_mode'.<br /><button id='submit'>Click to submit run mode '$next_mode'</button><input type='hidden' name='rm' id='rm' value='$next_mode' /></form>";

} # End of build_form.

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

sub build_visits
{
	my($self) = @_;
	my($html) = '';
	$html     .= "Methods visited which are hooked to run before setup(),<br />in which case they can't don't normally contribute to the HTML:<br />cgiapp_init()<br />";
	$html     .= '<br />Methods visited which are not run modes:<br />' . join('<br />', @{$self -> param('non_mode_visited')}) . '<br />';
	$html     .= '<br />Methods visited which are run modes:<br />' . join('<br />', @{$self -> param('run_mode_visited')}) . '<br />';
	$html     .= "<br />Methods not visited until after the run mode runs,<br />in which case they can't contribute to the HTML:</br />" .
		join('<br />', 'cgiapp_postrun()', 'teardown()') . '<br />';

	return $html;

} # End of build_visits.

# --------------------------------------------------
# You don't see the output from this method because it is hooked to run before setup().

sub cgiapp_init
{
	my($self) = @_;

} # End of cgiapp_init.

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;
	my($ara)  = $self -> param('non_mode_visited');

	push @$ara, 'cgiapp_prerun()';

	$self -> param(non_mode_visited => $ara);

} # End of cgiapp_prerun.

# --------------------------------------------------
# You don't see the output from this method because it runs after the run modes have build the HTML.

sub cgiapp_postrun
{
	my($self) = @_;
	my($ara)  = $self -> param('non_mode_visited');

	push @$ara, 'cgiapp_postrun()';

	$self -> param(non_mode_visited => $ara);

} # End of cgiapp_postrun.

# ------------------------------------------------

sub first_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	push @$ara, 'first_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> build_head . $self -> build_form($self -> get_current_runmode, 'second_rm') . $self -> build_visits . $self -> build_tail;

} # End of first_rm_method.

# ------------------------------------------------

sub second_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	push @$ara, 'second_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> build_head . $self -> build_form($self -> get_current_runmode, 'third_rm') . $self -> build_visits . $self -> build_tail;

} # End of second_rm_method.

# ------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> add_callback('forward_prerun', 'third_rm_prerun');
	$self -> param(run_mode_visited => []);
	$self -> param(non_mode_visited => []);
	$self -> start_mode('first_rm');
	$self -> run_modes(first_rm => 'first_rm_method', second_rm => 'second_rm_method', third_rm => 'third_rm_method');

} # End of setup.

# --------------------------------------------------
# You don't see the output from this method because it runs after the run modes have build the HTML.

sub teardown
{
	my($self) = @_;

} # End of teardown.

# ------------------------------------------------

sub third_rm_method
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	push @$ara, 'third_rm_method()';

	$self -> param(run_mode_visited => $ara);

	return $self -> forward('first_rm');

} # End of third_rm_method.

# --------------------------------------------------

sub third_rm_prerun
{
	my($self) = @_;
	my($ara)  = $self -> param('run_mode_visited');

	push @$ara, 'third_rm_prerun()';

	$self -> param(run_mode_visited => $ara);

} # End of third_rm_prerun.

# ------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Demo::Three - A template-free demo of CGI::Snapp using the forward() method

=head1 Synopsis

After installing the module, do one or both of:

=over 4

=item o Use the L<CGI> script

Unpack the distro and copy http/cgi-bin/cgi.snapp.three.cgi to your web server's cgi-bin/ directory, and make it executable.

Then browse to http://127.0.0.1/cgi-bin/cgi.snapp.three.cgi.

=item o Use the L<PSGI> script

Note: In order to not require users to install L<Starman> or L<Plack>, they have been commented out in Build.PL and Makefile.PL.

Edit httpd/cgi-bin/cgi.snapp.three.psgi and change my value for the web server's doc root from /dev/shm/html to match your set up.

/dev/shm/ is a directory provided by L<Debian|http://www.debian.org/> which is actually a RAM disk, and within that my doc root is the sub-directory /dev/shm/html/.

Then, install L<Plack> and L<Starman> and then do one or both of:

=over 4

=item o Use L<Starman>

Start starman with: starman -l 127.0.0.1:5173 --workers 1 httpd/cgi-bin/cgi.snapp.three.psgi &

=item o Use L<Plack>

Start plackup with: plackup -l 127.0.0.1:5173 httpd/cgi-bin/cgi.snapp.three.psgi &

=back

Then, with either starman or plackup, direct your browser to hit 127.0.0.1:5173/.

These commands are copied from comments within httpd/cgi-bin/cgi.snapp.three.psgi. The value 5173 is of course just a suggestion. All demos in this series use port 5171 and up.

=back

=head1 Description

Shows how to use the forward() method to interrupt processing of a run mode.

The output reports which methods were and were not entered per run mode.

Also, it shows how to hook the 'forward_prerun' hook.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<CGI::Snapp::Demo::Three> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp::Demo::Three

or run:

	sudo cpan CGI::Snapp::Demo::Three

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

C<new()> is called as C<< my($app) = CGI::Snapp::Demo::Three -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp::Demo::Three>.

See http/cgi-bin/cgi.snapp.three.cgi.

=head1 Methods

=head2 run()

Runs the code which responds to HTTP requests.

See http/cgi-bin/cgi.snapp.three.cgi.

=head1 Troubleshooting

=head2 It doesn't work!

Hmmm. Things to consider:

=over 4

=item o Run the *.cgi script from the command line

shell> perl httpd/cgi-bin/cgi.snapp.three.cgi

If that doesn't work, you're in b-i-g trouble. Keep reading for suggestions as to what to do next.

=item o The system Perl 'v' perlbrew

Are you using perlbrew? If so, recall that your web server will use the first line of http/cgi-bin/cgi.snapp.three.cgi to find a Perl, and that line says #!/usr/bin/env perl.

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

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Demo::Three>.

=head1 Author

L<CGI::Snapp::Demo::Three> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
