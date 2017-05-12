#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/GetCharMenu.pl,v 1.8 2003/03/28 05:51:56 jcmurphy Exp $
#
# NAME
#   GetCharMenu.pl
#
# USAGE
#   GetCharMenu.pl [server] [username] [password] [menuname]
#
# DESCRIPTION
#   Retrieve and print information about the named menu.
#
# AUTHOR
#   Jeff Murphy
#   jcmurphy@acsu.buffalo.edu
#
# $Log: GetCharMenu.pl,v $
# Revision 1.8  2003/03/28 05:51:56  jcmurphy
# more 5.x edits
#
# Revision 1.7  2001/10/24 14:21:27  jcmurphy
# MergeEntry doc update, minor test/example tweaks
#
# Revision 1.6  2000/05/24 18:05:26  jcmurphy
# primary ars4.5 integration in this checkpoint.
#
# Revision 1.5  1998/10/14 13:55:34  jcmurphy
# fixed syntax error
#
# Revision 1.4  1998/09/16 14:38:31  jcmurphy
# updated changeDiary code
#
# Revision 1.3  1998/02/25 19:21:32  jcmurphy
# updated to printout query if query style menu
#
# Revision 1.2  1997/11/10 23:36:52  jcmurphy
# added refreshCode to the output
#
# Revision 1.1  1996/11/21 20:13:51  jcmurphy
# Initial revision
#
#

use ARS;
require 'ars_QualDecode.pl';

# SUBROUTINE
#   printl
#
# DESCRIPTION
#   prints the string after printing X number of tabs

sub printl {
    my $t = shift;
    my @s = @_;

    if(defined($t)) {
	for( ; $t > 0 ; $t--) {
	    print "\t";
	}
	print @s;
    }
}

($server, $username, $password, $name) = @ARGV;
if(!defined($name)) {
    print "Usage: $0 [server] [username] [password] [menuname]\n";
    exit 0;
}

$ctrl = ars_Login($server, $username, $password);

print "Calling ars_GetCharMenu($ctrl, $name)..\n";
($finfo = ars_GetCharMenu($ctrl, $name)) ||
    die "error in GetCharMenu: $ars_errstr";

# 10005
print "Calling ars_GetCharMenuItems($ctrl, $name)..\n";
my ($menuItems) = ars_GetCharMenuItems($ctrl, $name);
die "$ars_errstr\n" unless defined($menuItems);
print "menuItems=<<$menuItems>> (should be an array ref)\n";
die "hmm. that wasnt an array ref." unless ref ($menuItems) eq "ARRAY";

print "** Menu Info:\n";
print "Name        : \"".$finfo->{"name"}."\"\n";
print "helpText    : ".$finfo->{"helpText"}."\n";
print "timestamp   : ".localtime($finfo->{"timestamp"})."\n";
print "owner       : ".$finfo->{"owner"}."\n";
print "lastChanged : ".$finfo->{"lastChanged"}."\n";
print "changeDiary : ".$finfo->{"changeDiary"}."\n";

foreach (@{$finfo->{"changeDiary"}}) {
    print "\tTIME: ".localtime($_->{"timestamp"})."\n";
    print "\tUSER: $_->{'user'}\n";
    print "\tWHAT: $_->{'value'}\n";
}

print "refreshCode : ".$finfo->{"refreshCode"}."\n";
print "menuType    : ".$finfo->{"menuType"}."\n";

if($finfo->{menuType} eq "query") {

	ARS::insertValueForCurrentTransaction($ctrl, 
					 $finfo->{'menuQuery'}{'schema'},
					 $finfo->{'menuQuery'}{'qualifier'});


    print "menuQuery definitions:\n";
    print "\tschema      : ".$finfo->{menuQuery}{schema}."\n";
    print "\tserver      : ".$finfo->{menuQuery}{server}."\n";
    print "\tlabelField  : ".$finfo->{menuQuery}{labelField}."\n";
    print "\tvalueField  : ".$finfo->{menuQuery}{valueField}."\n";
    print "\tsortOnLabel : ".$finfo->{menuQuery}{sortOnLabel}."\n";
    print "\tquery       : ".$finfo->{menuQuery}{qualifier}."\n";
    $dq = ars_perl_qualifier($ctrl, $finfo->{menuQuery}{qualifier});
    $qualtext = ars_Decode_QualHash($ctrl, 
				    $finfo->{menuQuery}{schema}, 
				    $dq);
    print "\t$qualtext\n";

}

elsif($finfo->{menuType} eq "file") {
    print "menuFile definitions:\n";
    print "\tfileLocation  : ".("", "Server", "Client")[$finfo->{menuFile}{fileLocation}]."\n";
    print "\tfilename      : ".$finfo->{menuFile}{filename}."\n";
}

elsif($finfo->{menuType} eq "sql") {
    print "menuSQL definitions:\n";
    print "\tserver      : ".$finfo->{menuSQL}{server}."\n";
    print "\tsqlCommand  : ".$finfo->{menuSQL}{sqlCommand}."\n";
    print "\tlabelIndex  : ".$finfo->{menuSQL}{labelIndex}."\n";
    print "\tvalueIndex  : ".$finfo->{menuSQL}{valueIndex}."\n";
}

print "Menu Items  :\n";
printMenuItems(1, $menuItems);
print "Simple Menu : (with 'prepend' = false)\n";
print "\t", join("\n\t", ars_simpleMenu($menuItems, 0)), "\n";
print "Simple Menu : (with 'prepend' = true)\n";
print "\t", join("\n\t", ars_simpleMenu($menuItems, 1)), "\n";

ars_Logoff($ctrl);

exit 0;

sub printMenuItems {
	my ($l, $m) = (shift, shift);
	my ($i) = 0;
	for ($i = 0 ; $i <= $#$m ; $i += 2) {
		printl($l, $m->[$i]);
		if(ref($m->[$i+1]) eq "ARRAY") {
			print "\n";
			printMenuItems($l+1, $m->[$i+1]);
		} else {
			print " -> ".$m->[$i+1]."\n";
		}
	}
}
