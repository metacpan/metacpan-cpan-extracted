requires 'Carp::Assert';
requires 'DBD::SQLite', '1.60';
requires 'DBI';
requires 'Date::Parse';
requires 'File::pushd';
requires 'Function::Parameters';
requires 'Getopt::Long';
requires 'IPC::Run';
requires 'JSON';
requires 'List::Util', '1.33';
requires 'Log::Any';
requires 'Log::Any::Adapter::Log4perl';
requires 'Log::Log4perl';
requires 'Log::Log4perl::Appender::Screen';
requires 'Log::Log4perl::Appender::ScreenColoredLevels';
requires 'Log::Log4perl::Layout::PatternLayout';
requires 'Log::Log4perl::Level';
requires 'Number::Bytes::Human';
requires 'Path::Tiny';
requires 'Pod::Usage';
requires 'Version::Compare';
requires 'autodie';
requires 'perl', 'v5.14.0';
requires 'strictures';

on configure => sub {
	requires 'Devel::CheckBin';
	requires 'Module::Build::Tiny', '0.035';
};

on 'test' => sub {
	requires 'Log::Any::Adapter::TAP';
	requires 'Software::License::GPL_3';
	requires 'Test::Differences';
	requires 'Test::Exception';
	requires 'Test::MockObject';
	requires 'Test::More', '0.98';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};

