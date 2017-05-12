package CGI::Snapp::Demo::Four::Wrapper;

use parent 'CGI::Snapp::Demo::Four';
use strict;
use warnings;

use Config::Plugin::Tiny; # For config_tiny().

use File::Spec;
use File::Temp;

use Hash::FieldHash ':all';

# We inherit from CGI::Snapp::Demo::Four, which inherits from CGI::Snapp.
# Now, since CGI::Snapp has log() method, the next line overrides that with
# the log() method from Log::Handler::Plugin::DBI.

use Log::Handler::Plugin::DBI; # For configure_logger(), log() and log_object().

fieldhash my %config_file => 'config_file';

our $VERSION = '1.02';

# --------------------------------------------------

sub _init
{
	my($self, $arg)    = @_;
	$$arg{config_file} ||= ''; # Caller can set.
	$self              = $self -> SUPER::_init($arg);
	my($config)        = $self -> config_tiny($self -> config_file);

	# Use the section called [logger] as the whole config hashref.

	$config = $$config{logger};

	# Overwrite the default dsn dbname '/tmp/logger.test.sqlite' with something suiting the OS.

	my($dir_object) = File::Temp -> newdir('temp.XXXX', EXLOCK => 0, TMPDIR => 1);
	my($dir_name)   = $dir_object -> dirname;
	my($file_name)  = File::Spec -> catdir($dir_name, 'four.sql');
	$$config{dsn}   =~ s|/tmp/cgi.snapp.demo.four|$file_name|;

	# The logger() method, here given a new log object, is defined in CGI::Snapp.

	$self -> configure_logger($config);
	$self -> logger($self -> log_object);

	return $self;

} # End of _init.

# --------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Demo::Four::Wrapper - A wrapper around CGI::Snapp::Demo::Four, to simplify using Log::Handler::Plugin::DBI

=head1 Synopsis

See L<CGI::Snapp::Demo::Four/Synopsis>.

=head1 Description

Acts as a wrapper class around L<CGI::Snapp::Demo::Four> to simplify using a L<Config::Plugin::Tiny> *.ini file to configure a logger using L<Log::Handler::Plugin::DBI>.

=head1 Distributions

See L<CGI::Snapp::Demo::Four/Distributions>.

=head1 Installation

See L<CGI::Snapp::Demo::Four/Installation>.

=head1 Constructor and Initialization

See L<CGI::Snapp::Demo::Four/Constructor and Initialization>.

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

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Demo::Four::Wrapper>.

=head1 Author

L<CGI::Snapp::Demo::Four::Wrapper> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
