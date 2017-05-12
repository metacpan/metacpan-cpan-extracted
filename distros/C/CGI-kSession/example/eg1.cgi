#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::kSession;

    my $cgi = new CGI;
    print $cgi->header;

    my $s = new CGI::kSession(lifetime=>10,path=>"/home/user/sessions/",id=>$cgi->param("SID"));
    $s->start();
    # $s->save_path('/home/user/sessions/');

    # registered "zmienna1"
    $s->register("zmienna1");
    $s->set("zmienna1","wartosc1");
    print $s->get("zmienna1"); #should print out "wartosc1"

    if ($s->is_registered("zmienna1")) {
	print "Is registered";
	} else {
	print "Not registered";
	}

    # unregistered "zmienna1"
    $s->unregister("zmienna1");
    $s->set("zmienna1","wartosc2");
    print $s->get("zmienna1"); #should print out -1
    
    $s->unset(); # unregister all variables
    $s->destroy(); # delete session with this ID
