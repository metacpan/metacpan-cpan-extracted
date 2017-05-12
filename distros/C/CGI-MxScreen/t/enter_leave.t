#
# $Id: enter_leave.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: enter_leave.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..12\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/enter_leave");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bScreen A\b/;
ok 3, $page->raw_content =~ /\benter-leave counters are 1-0\b/;

my $page2 = $page->forms->[0]->submit_by_name("ok")->press;
ok 4, !$page2->is_error;
ok 5, $page2->raw_content =~ /\bScreen B\b/;
ok 6, $page->raw_content =~ /\benter-leave counters are 1-0\b/;

my $page3 = $page2->forms->[0]->submit_by_name("back")->press;
ok 7, !$page3->is_error;
ok 8, $page3->raw_content =~ /\bScreen A\b/;
ok 9, $page3->raw_content =~ /\benter-leave counters are 2-1\b/;

my $page4 = $page3->forms->[0]->submit_by_name("redraw")->press;
ok 10, !$page4->is_error;
ok 11, $page4->raw_content =~ /\bScreen A\b/;
ok 12, $page4->raw_content =~ /\benter-leave counters are 2-1\b/;

