package Config::Plugin::Tiny;

use strict;
use warnings;

use Carp;

use Config::Tiny;

use vars qw(@EXPORT @ISA);

@EXPORT = ('config_tiny');
@ISA    = ('Exporter');

our $VERSION = '1.01';

# --------------------------------------------------

sub config_tiny
{
	my($self, $file_name) = @_;
	$file_name  ||= '';
	my($config) = Config::Tiny -> read($file_name);

	croak 'Error: ' . Config::Tiny -> errstr . "\n" if (Config::Tiny -> errstr);

	return $config;

} # End of config_tiny.

# --------------------------------------------------

1;

=pod

=head1 NAME

Config::Plugin::Tiny - A plugin which uses Config::Tiny

=head1 Synopsis

	package My::App;

	use strict;
	use warnings;

	use Config::Plugin::Tiny; # For config_tiny().

	use File::Spec;

	# ------------------------------------------------

	sub marine
	{
		my($self)   = @_;
		my($config) = $self -> config_tiny(File::Spec -> catfile('some', 'dir', 'config.tiny.ini') );

	} # End of marine.

	# --------------------------------------------------

	1;

t/config.tiny.ini ships with the L<Config::Plugin::Tiny> distro, and is used in the test file t/test.t.

=head1 Description

When you 'use' this module (as in the Synopsis), it automatically imports into your class the method L</config_tiny($file_name)> to give you access to config data stored in an *.ini file.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Config::Plugin::Tiny> as you would for any C<Perl> module:

Run:

	cpanm Config::Plugin::Tiny

or run:

	sudo cpan Config::Plugin::Tiny

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

This module does not have, and does not need, a constructor.

=head1 Methods

=head2 config_tiny($file_name)

Returns a *.ini-style config file as a hashref.

Here, the [] indicate an optional parameter.

The $file_name is passed to L<Config::Tiny>'s read($file_name) method.

=head1 FAQ

=head2 When would I use this module?

In your sub-class of L<CGI::Snapp> for example, or anywhere else you want effortless access to a *.ini file.

For example, if you wish to load a config for use by a module such as L<Log::Handler::Plugin::DBI>, try Config::Plugin::Tiny or L<Config::Plugin::TinyManifold>.

=head2 Why didn't you call the exported method config()?

Because L</config_tiny($file_name)> allows both L<Config::Plugin::Tiny> and L<Config::Plugin::TinyManifold> to be used in the same code.

=head2 Can this module be used in any non-CGI-Snapp module?

Yes.

=head2 Why don't you 'use Exporter;'?

It is not needed; it would be for documentation only.

For the record, Exporter V 5.567 ships with Perl 5.8.0. That's what I had in Build.PL and Makefile.PL until I tested the fact I can omit it.

=head2 What's the error message format?

Every message passed to croak matches /^Error/ and ends with "\n".

=head1 See Also

L<CGI::Application>

The following are all part of this set of distros:

L<CGI::Snapp> - A almost back-compat fork of CGI::Application

L<CGI::Snapp::Demo::One> - A template-free demo of CGI::Snapp using just 1 run mode

L<CGI::Snapp::Demo::Two> - A template-free demo of CGI::Snapp using N run modes

L<CGI::Snapp::Demo::Three> - A template-free demo of CGI::Snapp using CGI::Snapp::Plugin::Forward

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

=head1 Credits

Please read L<https://metacpan.org/module/CGI::Application::Plugin::Config::Simple#AUTHOR>, since a lot of the ideas for this module were copied from
L<CGI::Application::Plugin::Config::Simple>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config::Plugin::Tiny>.

=head1 Author

L<Config::Plugin::Tiny> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
