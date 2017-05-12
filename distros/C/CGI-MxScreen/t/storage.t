#
# $Id: storage.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: storage.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..7\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/storage");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bScreen A\b/;

$page->forms->[0]->input_by_name("context_var")->replace("context");
$page->forms->[0]->input_by_name("hash_var")->replace("hash");
$page->forms->[0]->input_by_name("ary_var")->replace("array");
$page->forms->[0]->input_by_name("object_var")->replace("object");

my $page2 = $page->forms->[0]->submit_by_name("ok")->press;
ok 3, $page2->raw_content =~ /\bScreen B\b/;
ok 4, $page2->raw_content =~ /\bcontext var = context\b/;
ok 5, $page2->raw_content =~ /\bhash var = hash\b/;
ok 6, $page2->raw_content =~ /\barray var = array\b/;
ok 7, $page2->raw_content =~ /\bobject var = object\b/;

