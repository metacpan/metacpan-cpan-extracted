#
# $Id: states.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: states.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..13\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/bounce");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bScreen A\b/;

my $page2 = $page->forms->[0]->submit_by_name("ok")->press;
ok 3, !$page2->is_error;
ok 4, $page2->raw_content =~ /\bScreen B\b/;

my $page3 = $page2->forms->[0]->submit_by_name("next")->press;
ok 5, !$page3->is_error;
ok 6, $page3->raw_content =~ /\bScreen C from B\b/;

my $page4 = $page3->forms->[0]->submit_by_name("back")->press;
ok 7, !$page4->is_error;
ok 8, $page4->raw_content =~ /\bScreen B\b/;

$page = $ct->GET("$BASE/bounce?id=2");
ok 9, !$page->is_error;
ok 10, $page->raw_content =~ /\bScreen C from A\b/;
ok 11, $page->raw_content !~ /\bScreen A\b/;	# swallowed into sink

$page2 = $page->forms->[0]->submit_by_name("back")->press;
ok 12, !$page2->is_error;
ok 13, $page2->raw_content =~ /\bScreen B\b/;

