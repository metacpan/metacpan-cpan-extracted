#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/del_all.pl,v 1.5 1998/09/14 17:39:29 jcmurphy Exp $
#
# NAME
#   del_all.pl [server] [user] [password] [pattern]
#
# DESCRIPTION
#   delete all ars objects (*all*!) that match "pattern".
#   be careful!! if you want to delete "HD:.*" items BE SURE
#   to use "^HD:.*" as the pattern.
#
#   BACKUP ALL OBJECTS BEFORE USING THIS SCRIPT!
#
# AUTHOR
#   jeff murphy


use ARS;

if($#ARGV != 3) {
    print "Usage: $0 [server] [user] [pwd] [pattern]\n";
    print $#ARGV."\n";
    exit 0;
}

($c = ars_Login(shift, shift, shift)) ||
    die "Login: $ars_errstr";

$pat = shift;

print "Fetching..\n";
print "\tActiveLinks .. "; 
@al = ars_GetListActiveLink($c);
print $#al." found.\n";

print "\tAdminExtensions .. "; 
@ae = ars_GetListAdminExtension($c);
print $#ae." found.\n";

print "\tCharMenus .. "; 
@cm = ars_GetListCharMenu($c);
print $#cm." found.\n";

print "\tEscalations .. "; 
@es = ars_GetListEscalation($c);
print $#es." found.\n";

print "\tFilters .. "; 
@fi = ars_GetListFilter($c);
print $#fi." found.\n";

print "\tSchemas .. "; 
@sc = ars_GetListSchema($c, 0, 1024);
print $#sc." found.\n";

print "Sleeping for 5 seconds. control-c to abort!\n";
sleep(5);

print "\nDeleting Activelinks:\n";

foreach (@al) { 
    if($_ =~ /$pat/) {
	print "\t$_\n"; 
	ars_DeleteActiveLink($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting AdminExtensions:\n";

foreach (@ae) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteAdminExtension($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting CharMenus:\n";

foreach (@cm) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteCharMenu($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Escalations:\n";

foreach (@es) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteEscalation($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Filters:\n";

foreach (@fi) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteFilter($c, $_) || die "$ars_errstr";
    }
}

print "\nDeleting Schemas:\n";

foreach (@sc) { 
    if($_ =~ /$pat/) {
	print "\t$_\n";
	ars_DeleteSchema($c, $_, 2) || die "$ars_errstr";
    } 
}

ars_Logoff($c);

