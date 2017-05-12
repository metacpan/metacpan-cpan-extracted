#
# $Id: basic.t,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: basic.t,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;

print "1..19\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $page = $ct->GET("$BASE/basic");
ok 1, !$page->is_error;
ok 2, $page->raw_content =~ /\bWelcome to A\b/;

my $form = $page->forms->[0];
ok 3, $form->method eq "POST";

my $ok = $form->submit_by_name("ok");
ok 4, defined $ok;

$form->input_by_name("name")->replace("foo");
$form->input_by_name("passwd")->replace("bar");

my $page2 = $ok->press;
ok 5, !$page2->is_error;
ok 6, $page2->raw_content =~ /\bWelcome to B\b/;
ok 7, $page2->raw_content =~ /^Your name is foo\b/m;
ok 8, $page2->raw_content =~ /^Your password is bar\b/m;

my $form2 = $page2->forms->[0];
ok 9, $form2->method eq "POST";
ok 10, defined $form2->hidden_by_name("_mxscreen_context");
ok 11, defined $form2->hidden_by_name("_mxscreen_md5");

my $back = $form2->submit_by_name("back");
my $page3 = $back->press;
ok 12, !$page3->is_error;
ok 13, $page3->raw_content =~ /\bWelcome to A\b/;

my $form3 = $page3->forms->[0];
ok 14, $form3->input_by_name("name")->value eq "foo";
ok 15, $form3->input_by_name("passwd")->value eq "bar";

$form3->input_by_name("name")->append("2");
my $page4 = $form3->submit_by_name("redraw")->press;
ok 16, !$page4->is_error;
ok 17, $page4->raw_content =~ /\bWelcome to A\b/;

my $form4 = $page4->forms->[0];
ok 18, $form4->input_by_name("name")->value eq "foo2";
ok 19, $form4->input_by_name("passwd")->value eq "bar";

