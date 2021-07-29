use Test::More;
eval "use Test::Prereq";

my $msg;
if (not $ENV{TEST_AUTHOR}) {
  $msg = 'Checking prerequisites is an author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
} elsif ($@) {
  $msg = 'Test::Prereq required to test dependencies';
}
plan skip_all => $msg if $msg;
prereq_ok("Testing prerequisites",
	  [
	   # Include single quotes around the required test libraries. Ignore
	   # $module which is used for prerequisites.
	   qw('./t/cert.pl' './t/test.pl' './contrib/oddmuse.pl' './script/phoebe' $module),
	   # The regular modules are modules that are part of Perl core
	   # according to corelist and they were added before 5.26, or they are
	   # part of distributions like many of the Mojo modules that belong to
	   # Mojolicious.
	   qw(B Encode File::Basename File::Path File::Temp Getopt::Long
	      IO::Socket::IP List::Util Mojo::IOLoop Mojo::IOLoop::Server
	      Mojo::Log Mojo::JSON Mojo::UserAgent Pod::Text Socket Term::ReadLine
	      Test::More utf8 warnings Exporter Data::Dumper MIME::Base64
	      Pod::Checker Term::ANSIColor),
	   # Skip modules used for some of the plugins. This is a judgement call.
	   # Do we need them or not? Most people won't be installing these, I'm
	   # sure.
	   qw(File::MimeInfo), # Iapetus.pm
	   qw(Graph::Easy), # Ijirait.pm
	   qw(Text::Wrapper), # Gopher.pm, Spartan.pm
	   qw(DateTime::Format::ISO8601), # Oddmuse.pm
	   qw(MediaWiki::API Text::SpanningTable), # Wikipedia.pm
	   qw(Net::DNS Net::IP), # SpeedBump.pm
	   qw(Devel::MAT::Dumper), # HeapDump.pm
	   # Skip modules that are only used for author tests.
	   qw(IPC::Open2), # Chat.t
	  ]);
