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
	  # Include single quotes around the required test libraries. Ignore
	  # $module which is used for prerequisites. The regular modules are
	  # modules that are part of Perl core according to corelist and they
	  # were added before 5.26, or they are part of distributions like many
	  # of the Mojo modules that belong to Mojolicious.
	  [qw('./t/cert.pl' './t/test.pl' $module B Encode File::Basename
	  File::Path File::Temp Getopt::Long IO::Socket::IP List::Util
	  Mojo::IOLoop Mojo::IOLoop::Server Mojo::Log Mojo::UserAgent Pod::Text
	  Socket Term::ReadLine Test::More utf8 warnings)]);
