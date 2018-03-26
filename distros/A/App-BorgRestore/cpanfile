requires 'DBD::SQLite';
requires 'DBI';
requires 'Path::Tiny';
requires 'File::pushd';
requires 'Function::Parameters';
requires 'Getopt::Long';
requires 'IPC::Run';
requires 'List::Util';
requires 'Log::Any';
requires 'Log::Any::Adapter::Log4perl';
requires 'Log::Log4perl';
requires 'Log::Log4perl::Appender::Screen';
requires 'Log::Log4perl::Appender::ScreenColoredLevels';
requires 'Log::Log4perl::Layout::PatternLayout';
requires 'Log::Log4perl::Level';
requires 'Pod::Usage';
requires 'autodie';
requires 'perl', 'v5.14.0';
requires 'Version::Compare';
requires 'JSON';
requires 'Date::Parse';
requires 'Number::Bytes::Human';

on configure => sub {
	requires 'Devel::CheckBin';
	requires 'Module::Build::Tiny', '0.035';
};

on 'test' => sub {
	requires 'Test::Differences';
	requires 'Test::Exception';
	requires 'Test::MockObject';
	requires 'Test::More', '0.98';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
	requires 'Software::License::GPL_3';
};

