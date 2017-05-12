#
# $Id: dyn_target.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: dyn_target.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..11\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/dyn_target");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bWelcome to A\b/;

my $form = $page->forms->[0];

$form->input_by_name("name")->replace("foo");
$form->input_by_name("passwd")->replace("bar");

my $page2 = $form->submit_by_name("ok")->press;
ok 3, !$page2->is_error;
ok 4, $page2->raw_content =~ /\bWelcome to B\b/;
ok 5, $page2->raw_content =~ /^Your name is foo\b/m;
ok 6, $page2->raw_content =~ /^Your password is bar\b/m;

my $form2 = $page2->forms->[0];
my $back = $form2->submit_by_name("back");
my $page3 = $back->press;
ok 7, !$page3->is_error;
ok 8, $page3->raw_content =~ /\bWelcome to A\b/;

my $form3 = $page3->forms->[0];
$form3->input_by_name("passwd")->replace("toc");		# bring us to "C"

my $page4 = $form3->submit_by_name("ok")->press;
ok 9, !$page4->is_error;
ok 10, $page4->raw_content =~ /\bBad password\b/;
ok 11, defined $page4->forms->[0]->submit_by_name("back");

