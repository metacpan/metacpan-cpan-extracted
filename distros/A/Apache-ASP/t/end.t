
use Apache::ASP::CGI::Test;
use strict;
use File::Basename qw(basename dirname);

sub my::null {};

my $dir = dirname($0);
if($dir) {
    chdir($dir) || die "can't chdir to $dir";
}

my %args = ( 
	     NoState => 1, 
	     XMLSubsMatch => 'my:\w+',
	     Global => 'null',
	     UseStrict => 1,
#	     Debug => -1,
	     );
my @tests = (
	     [ 'end_basic.inc', sub { $_->test_body_out eq '1' } ],
	     [ 'end_clear.inc', sub { $_->test_body_out eq '' }, ],
	     [ 'end_redirect_basic.inc', sub { 
		 $_->test_header_out =~ /Location: NULL/
		     and $_->test_body_out eq ''
		     } ],
	     [ 'end_redirect_soft.inc', sub {
		 $_->test_header_out =~ /Location: NULL/
		     and $_->test_body_out =~ /^12/
		     }, 
	       { SoftRedirect => 1 } ],
	     [ 'end_xmlsubs_basic.inc', sub { $_->test_body_out eq '1' } ],
	     [ 'end_xmlsubs_redirect.inc', sub { 
		 $_->test_header_out =~ /Location: NULL/
		     and $_->test_body_out eq ''
		     } ],
	     );

print "1..".scalar(@tests)."\n";

for my $tester (@tests) {
    my($file, $test, $args) = @$tester;
    $args ||= {};
    my $r = Apache::ASP::CGI::Test->init($file);
    $r->init_dir_config( %args, %$args );
    my $status = Apache::ASP->handler($r);
    unless($status == 0) {
	$r->log_error("[failure] error status $status for $file");
	next;
    }

#    print $r->test_header_out."\n\n";
#    print $r->test_body_out."\n\n";
    local $_ = $r;
    if(eval { &$test }) {
	print "ok\n";
    } else {
	$r->log_error("[failure] $0 subtest $file failed, output:\n---\n".$r->OUT."\n---\n");
	print "not ok\n";
    }
}
