#
# $Id: config.t,v 0.1 2001/04/22 17:57:05 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: config.t,v $
# Revision 0.1  2001/04/22 17:57:05  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;
use File::Path;

print "1..16\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $dirs = [qw(t/logs t/sessions)];
rmtree $dirs;
mkpath $dirs;

my $page = $ct->GET("$BASE/config");
ok 1, !$page->is_error;

my $form = $page->forms->[0];
ok 2, defined $form->hidden_by_name("_mxscreen_session");
ok 3, defined $form->hidden_by_name("_mxscreen_token");

ok 4, -s "t/logs/mx.log";
ok 5, -f "t/logs/mx.err";
ok 6, 0 == -s "t/logs/mx.err";

rmtree $dirs;
mkpath $dirs;

my $page2 = $ct->GET("$BASE/config_sup");
ok 7, !$page2->is_error;

my $form2 = $page2->forms->[0];
ok 8, !defined $form2->hidden_by_name("_mxscreen_session");
ok 9, !defined $form2->hidden_by_name("_mxscreen_token");
ok 10, defined $form2->hidden_by_name("_mxscreen_md5");

ok 11, -s "t/logs/mx2.log";
ok 12, -f "t/logs/mx2.err";
ok 13, 0 == -s "t/logs/mx2.err";
ok 14, !-e "t/logs/mx.log";
ok 15, !-e "t/logs/mx.err";
ok 16, -s "t/logs/mx2.out";

rmtree $dirs;

