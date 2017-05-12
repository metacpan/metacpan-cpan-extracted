#
# $Id: action.t,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: action.t,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..22\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/action");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bScreen A\b/;
ok 3, $page->raw_content =~ /\bRun count = 0\b/;
ok 4, $page->raw_content !~ /\bError:/;

$page->forms->[0]->input_by_name("amount")->replace("");
my $page2 = $page->forms->[0]->submit_by_name("ok")->press;
ok 5, !$page2->is_error;
ok 6, $page2->raw_content =~ /\bScreen A\b/;
ok 7, $page2->raw_content =~ /\bRun count = 1\b/;
ok 8, $page2->raw_content =~ /\bError: field is mandatory\b/;

$page2->forms->[0]->input_by_name("amount")->replace("a");
my $page3 = $page2->forms->[0]->submit_by_name("ok")->press;
ok 9, !$page3->is_error;
ok 10, $page3->raw_content =~ /\bScreen A\b/;
ok 11, $page3->raw_content =~ /\bRun count = 2\b/;
ok 12, $page3->raw_content =~ /\bError: must be a numerical value\b/;

$page3->forms->[0]->input_by_name("amount")->replace(1);
my $page4 = $page3->forms->[0]->submit_by_name("ok")->press;
ok 13, !$page4->is_error;
ok 14, $page4->raw_content =~ /\bScreen B\b/;
ok 15, $page4->raw_content =~ /\bWas run = 3\b/;

my $page5 = $ct->GET("$BASE/action?abort=1");
ok 16, !$page5->is_error;
ok 17, $page5->raw_content =~ /\bScreen A\b/;
ok 18, $page->raw_content =~ /\bRun count = 0\b/;

$page5->forms->[0]->input_by_name("amount")->replace("");
my $page6 = $page5->forms->[0]->submit_by_name("ok")->press;
ok 19, !$page6->is_error;
ok 20, $page6->raw_content =~ /\bScreen A\b/;
ok 21, $page6->raw_content =~ /\bError: field is mandatory\b/;
ok 22, $page6->raw_content =~ /\bRun count = 0\b/;

