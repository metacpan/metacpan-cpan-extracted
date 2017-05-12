#
# $Id: buffering.t,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: buffering.t,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use CGI::Test;
use File::Path;

require "t/code.pl";

print "1..10\n";

my $BASE = "http://server:18/cgi-bin";

my $ct = CGI::Test->make(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

my $dirs = [qw(t/logs t/sessions)];
mkpath $dirs;

my $page = $ct->GET("$BASE/config");
ok 1, !$page->is_error;

# With buffering, context is stored at the beginning.

my $form = $page->forms->[0];
my @widgets = $form->widget_list;
ok 2, $widgets[0]->name eq "_mxscreen_session";
ok 3, $widgets[1]->name eq "_mxscreen_token";

my $page2 = $ct->GET("$BASE/config_nobuf");
ok 4, !$page2->is_error;

# No buffering, context is emitted at the end.

my $form2 = $page2->forms->[0];
my @widgets2 = $form2->widget_list;
ok 5, $widgets2[-2]->name eq "_mxscreen_session";
ok 6, $widgets2[-1]->name eq "_mxscreen_token";

my $page3 = $ct->GET("$BASE/early_write");
ok 7, !$page->is_error;
ok 8, $page->raw_content !~ /EARLY PRINTING/;
ok 9, contains("t/logs/mx.out", "EARLY PRINTING");
ok 10, contains("t/logs/mx.err", "EARLY PRINTING");

rmtree $dirs;

