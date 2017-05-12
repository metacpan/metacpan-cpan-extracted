print "1..7\n";

use strict;
my $limit = 666;
my $upload = 17;

use CGI::Safe qw/:standard/;
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

print "not " if exists $ENV{ 'PATH' };
print "ok 6\n";

print "not " if exists $ENV{ 'IFS ' };
print "ok 7\n";