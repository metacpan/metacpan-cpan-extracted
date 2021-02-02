package Config::Plugin::TinyManifold;

use strict;
use warnings;

use Carp;

use Config::Tiny;

use vars qw(@EXPORT @ISA);

@EXPORT = ('config_manifold');
@ISA    = ('Exporter');

our $VERSION = '1.02';

# --------------------------------------------------

sub config_manifold
{
	my($self, $file_name) = @_;
	$file_name ||= '';

	# Check [global].

	my($config) = Config::Tiny -> read($file_name);

	croak 'Error: ' . Config::Tiny -> errstr . "\n" if (Config::Tiny -> errstr);

	my($section) = 'global';
	$section     = $$config{$section}{'section'} if ($$config{$section});

	croak "Error: Config file '$file_name' does not contain the section '$section'\n" if (! $$config{$section});

	return $$config{$section};

} # End of config_manifold.

# --------------------------------------------------

1;

=pod

=head1 NAME

Config::Plugin::TinyManifold - A plugin which uses Config::Tiny with 1 of N sections

=head1 Synopsis

	package My::App;

	use strict;
	use warnings;

	use Config::Plugin::TinyManifold; # For config_manifold().

	use File::Spec;

	# ------------------------------------------------

	sub marine
	{
		my($self)   = @_;
		my($config) = $self -> config_manifold(File::Spec -> catfile('some', 'dir', 'config.tiny.manifold.ini') );

	} # End of marine.

	# --------------------------------------------------

	1;

t/config.tiny.manifold.ini ships with the L<Config::Plugin::TinyManifold> distro, and is used in the test file t/test.t.

=head1 Description

When you 'use' this module (as in the Synopsis), it automatically imports into your class the method L</config_maifold($file_name)> to give you access to config data stored in an *.ini file.

But more than that, it uses a value from the config file to select 1 of N sections within that file as the whole config. See L</config_manifold($file_name)> for details.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Config::Plugin::TinyManifold> as you would for any C<Perl> module:

Run:

	cpanm Config::Plugin::TinyManifold

or run:

	sudo cpan Config::Plugin::TinyManifold

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

=head2 config_manifold($file_name)

Returns a *.ini-style config file as a hashref.

Here, the [] indicate an optional parameter.

The $file_name is passed to L<Config::Tiny>'s read($file_name) method.

It uses a value from the config file to select 1 of N sections within that file as the whole config.

Specifically, the name of the global section is hard-coded as '[global]', and the name of the key within that is hard-coded as 'section'.

So, a sample config file, which ships as t/config.tiny.manifold.ini is:

	[global]

	# The 'section' key:
	# o Specifies which section to use after the [global] section ends.
	# o Case-sensitive options are /^(localhost|webhost)$/.

	section = localhost

	[localhost]

	template_path = /home/ron/assets/templates/CGI/Snapp

	[website]

	template_path = /dev/shm/html/assets/templates/CGI/Snapp

Alternately, you could use sections called [global], [testing] and [production], and so on.

=head1 FAQ

=head2 When would I use this module?

In your sub-class of L<CGI::Snapp> for example, or anywhere else you want effortless access to a *.ini file which contains N alternate sections, and you wish to auto-select 1 of these sections.

For example, if you wish to load a config for use by a module such as L<Log::Handler::Plugin::DBI>, try L<Config::Plugin::Tiny> or Config::Plugin::TinyManifold.

=head2 Why didn't you call the exported method config()?

Because L</config_manifold($file_name)> allows both L<Config::Plugin::Tiny> and L<Config::Plugin::TinyManifold> to be used in the same code.

=head2 Why don't you 'use Exporter;'?

It is not needed; it would be for documentation only.

For the record, Exporter V 5.567 ships with Perl 5.8.0. That's what I had in Build.PL and Makefile.PL until I tested the fact I can omit it.

=head2 What's the error message format?

Every message passed to croak matches /^Error/ and ends with "\n".

=head2 What does 'manifold' mean, exactly?

My paper dictionary lists 8 meanings. The first 2 are:

=over 4

=item 1: of many kinds; numerous and varied: I<manifold duties>

=item 2: having many different parts, elements, features, forms, etc.

=back

So, rather like sections in a *.ini file...

=head1 Repository

L<https://github.com/ronsavage/Config-Plugin-TinyManifold.git>

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

Bugs should be reported via the CPAN bug tracker at

L<https://github.com/ronsavage/Config-Plugin-TinyManifold/issues>

=head1 Author

L<Config::Plugin::TinyManifold> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
