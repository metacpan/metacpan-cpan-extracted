BEGIN {
	@list = qw(
		Apache::Voodoo::Zombie
		Apache::Voodoo::Loader::Static
		Apache::Voodoo::Loader::Dynamic
		Apache::Voodoo::Engine
		Apache::Voodoo::Validate
		Apache::Voodoo::Application
		Apache::Voodoo::Session::Instance
		Apache::Voodoo::Session::File
		Apache::Voodoo::Session::MySQL
		Apache::Voodoo::Debug
		Apache::Voodoo::Install
		Apache::Voodoo::Exception
		Apache::Voodoo::MP::Common
		Apache::Voodoo::Test
		Apache::Voodoo::Application::ConfigParser
		Apache::Voodoo::Session
		Apache::Voodoo::Handler
		Apache::Voodoo::MP
		Apache::Voodoo::View
		Apache::Voodoo::View::HTML
		Apache::Voodoo::View::HTML::Theme
		Apache::Voodoo::View::JSON
		Apache::Voodoo::Validate::datetime
		Apache::Voodoo::Validate::text
		Apache::Voodoo::Validate::bit
		Apache::Voodoo::Validate::signed_int
		Apache::Voodoo::Validate::unsigned_decimal
		Apache::Voodoo::Validate::time
		Apache::Voodoo::Validate::Plugin
		Apache::Voodoo::Validate::signed_decimal
		Apache::Voodoo::Validate::unsigned_int
		Apache::Voodoo::Validate::varchar
		Apache::Voodoo::Validate::date
		Apache::Voodoo::Debug::Native
		Apache::Voodoo::Debug::Handler
		Apache::Voodoo::Debug::Native::SQLite
		Apache::Voodoo::Debug::Native::common
		Apache::Voodoo::Debug::FirePHP
		Apache::Voodoo::Debug::Common
		Apache::Voodoo::Loader
		Apache::Voodoo::Pager
		Apache::Voodoo::Constants
		Apache::Voodoo::Table
		Apache::Voodoo::Table::Probe
		Apache::Voodoo::Table::Probe::MySQL
		Apache::Voodoo::Install::Post
		Apache::Voodoo::Install::Updater
		Apache::Voodoo::Install::Pid
		Apache::Voodoo::Install::Config
		Apache::Voodoo::Install::Distribution
		Apache::Voodoo
	);

	# .pm => prerequsite
	%optional = (
		'Apache::Voodoo::MP::V1'          => 'Apache::Request',
		'Apache::Voodoo::MP::V2'          => 'Apache2::Request',
		'Apache::Voodoo::Debug::Log4perl' => 'Log::Log4perl',
		'Apache::Voodoo::Soap'            => 'SOAP::Lite'
	);
		
};

use Test::More tests => scalar @list + keys %optional;

foreach (@list) {
	use_ok($_);
}

foreach (keys %optional) {
	SKIP: {
		eval {
			$f = $optional{$_};
			$f =~ s/::/\//g;
			$f .= ".pm";
			require $f;
		};
		skip "$optional{$_} not installed", 1 if ($@);
		use_ok($_);
	};
}
