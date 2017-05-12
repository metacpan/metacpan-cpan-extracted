#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Show_Menu.pl,v 1.1 1996/11/21 20:13:56 jcmurphy Exp $
#
# EXAMPLE
#    Show_Menu.pl
#
# DESCRIPTION
#    Use ars_GetCharMenuItems to obtain information about a menu.
#
# AUTHOR
#    jeff murphy
#
# 01/12/96
# 
# $Log: Show_Menu.pl,v $
# Revision 1.1  1996/11/21 20:13:56  jcmurphy
# Initial revision
#
#

use ARS;

# Parse command line parameters

($server, $username, $password, $menu_name) = @ARGV;
if(!defined($menu_name)) {
    print "usage: $0 [server] [username] [password] [menu name]\n";
    exit 1;
}

# Log onto the ars server specified

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# SUBROUTINE
#   IndPrint(indentation, string)
#
# DESCRIP
#   This subroutine will print a string with [indentation] number
#   of preceding TABS. 

sub IndPrint {
    my $ind = shift;
    my $s   = shift;
    my $i;

    if(defined($s)) {
	for($i = 0; $i < $ind; $i++) {
	    print "\t";
	}
	print $s;
    }
}
# SUBROUTINE
#   DumpMenu(arraypointer, indentation count)
# 
# DESCRIP
#   Recursive subroutine to dump menu and sub menu items

sub DumpMenu {
    my $m = shift;
    my $i = shift;
    my @m = @$m;
    my $name, $val;

    $i = 0 unless $i;

    while (($name, $val, @m) = @m) {
	if (ref($val)) {
	    IndPrint($i, "SubMenu: $name\n");
	    DumpMenu($val, $i+1);
	} else {
	    IndPrint($i, "Name: $name\t Value: $val\n");
	}
    }
}

# Retrieve info about menu.

DumpMenu(ars_GetCharMenuItems($ctrl, $menu_name));

# Log out of the server.

ars_Logoff($ctrl);
