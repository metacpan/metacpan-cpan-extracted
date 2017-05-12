print "1..9\n";

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
	CGI::Safe->import( qw/ admin taint / );
}
# stop spurious warnings about only used once
$CGI::DISABLE_UPLOADS = $CGI::DISABLE_UPLOADS;
$CGI::POST_MAX = $CGI::POST_MAX;

eval {
   CGI::Safe->set( POST_MAX => $limit );
};
print "not " if $@;
print "ok 1\n";

eval {
   CGI::Safe::set( DISABLE_UPLOADS => $upload );
};
print "not " if $@;
print "ok 2\n";

my $q;
eval {
    $q = CGI::Safe->new( source => { color => 'red', color => 'blue', name => 'Ovid' } );
};
print "not " if $@ or ! defined $q;
print "ok 3\n";

print "not " unless $CGI::POST_MAX == $limit;
print "ok 4\n";

print "not " unless $CGI::DISABLE_UPLOADS == $upload;
print "ok 5\n";

my $header = $q->header;
print "not " unless $header =~ /content/i;
print "ok 6\n";

my @colors = $q->param('color');
print "not " unless grep { /blue/ } @colors;
print "ok 7\n";

print "not " if exists $ENV{ 'IFS ' };
print "ok 8\n";

print "not " unless $ENV{ 'PATH' } eq $path;
print "ok 9\n";
