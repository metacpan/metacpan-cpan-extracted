#
# $Id: example.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: example.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

# Ensure the example held in the documentation behaves as expected.

use CGI::Test;

print "1..16\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/example");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bChoose Color\b/;
ok 3, $page->raw_content !~ /\bYou told me/;

my $form = $page->forms->[0];
ok 4, $form->menu_by_name("color")->is_selected("Green");
$form->menu_by_name("color")->select("Blue");

my $page2 = $form->submit_by_name("Redraw")->press;
ok 5, !$page2->is_error;
ok 6, $page2->raw_content =~ /\bChoose Color\b/;
ok 7, $page2->raw_content !~ /\bYou told me/;

my $form2 = $page2->forms->[0];
ok 8, $form2->menu_by_name("color")->is_selected("Blue");

my $page3 = $form2->submit_by_name("Next")->press;
ok 9, !$page3->is_error;
ok 10, $page3->raw_content =~ /\bChoose Day\b/;
ok 11, $page3->raw_content =~ /\byour favorite color was Blue/;

my $form3 = $page3->forms->[0];
ok 12, $form3->menu_by_name("day")->is_selected("Mon");
$form3->menu_by_name("day")->select("Fri");

my $page4 = $form3->submit_by_name("Back")->press;
ok 13, !$page4->is_error;
ok 14, $page4->raw_content =~ /\bChoose Color\b/;
ok 15, $page4->raw_content =~ /\byour favorite weekday was Fri/;
ok 16, $page4->forms->[0]->menu_by_name("color")->is_selected("Blue");

