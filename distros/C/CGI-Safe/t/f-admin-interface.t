print "1..7\n";

use strict;
my $limit = 666;
my $upload = 17;
use vars qw/ $path $shell /;

BEGIN {
	# This test cannot "use" CGI safe or else we'll have PATH
	# and SHELL gone before we can get their values
	$path  = $ENV{ 'PATH' };
	$shell = $ENV{ 'SHELL' };

	require CGI::Safe;
	CGI::Safe->import( qw/ :standard admin / );
}

# stop spurious warnings about only used once
$CGI::DISABLE_UPLOADS = $CGI::DISABLE_UPLOADS;
$CGI::POST_MAX = $CGI::POST_MAX;

eval {
   set( POST_MAX => $limit );
};
print "not " if $@;
print "ok 1\n";

eval {
   set( DISABLE_UPLOADS => $upload );
};
print "not " if $@;
print "ok 2\n";

print "not " unless $CGI::POST_MAX == $limit;
print "ok 3\n";

print "not " unless $CGI::DISABLE_UPLOADS == $upload;
print "ok 4\n";

my $header = header;
print "not " unless $header =~ /content/i;
print "ok 5\n";

print "not " if exists $ENV{ 'IFS ' };
print "ok 6\n";

print "not " unless $ENV{ 'PATH' } eq $path;
print "ok 7\n";
