#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/WhoUsesIt.pl,v 1.4 2005/04/06 19:13:57 jeffmurphy Exp $
#
# NAME 
#   WhoUsesIt.pl
#
# USAGE
#   WhoUsesIt.pl [-v] [-s schema] [-a | -f | -m | -e | -p | -M [name]] 
#                [username] [password]
#
# DESCRIPTION
#   Search all schemas and determine who uses the specified active link,
#   filter, menu or escalation. 
#
#   -a   list all schemas that use this active link
#   -f   .. this filter
#   -m   .. this menu
#   -e   .. this escalation
#   -M   list all menus that use this file
#   -p   list all filters that call this process
#   -s   specify a specific schema to search
#   -v   verbose output
#
# AUTHOR
#   jeff murphy
#   jcmurphy@acsu.buffalo.edu
#
# $Log: WhoUsesIt.pl,v $
# Revision 1.4  2005/04/06 19:13:57  jeffmurphy
# WhoUsesIt mod
#
# Revision 1.3  2005/04/06 18:02:28  jeffmurphy
# added Zeros
#
# Revision 1.2  2003/04/02 05:12:22  jcmurphy
# added Alert functions
#
# Revision 1.1  1996/11/21 21:55:43  jcmurphy
# Initial revision
#
# Revision 1.1  1996/10/12 21:26:37  jcmurphy
# Initial revision
#

use ARS;
require 'getopts.pl';  # a standard perl module

$pname = $0;
$pname =~ s/.*\///g;

Getopts('s:a:f:m:e:p:M:Dhv');

$debug = $opt_D;
($server, $username, $password) = @ARGV;

$SCHEMA = defined($opt_s)?$opt_s:".*";

if($debug) {
    print STDERR "a: ".(defined($opt_a)?"$opt_a":"undef")."\n";
    print STDERR "f: ".(defined($opt_f)?"$opt_f":"undef")."\n";
    print STDERR "m: ".(defined($opt_m)?"$opt_m":"undef")."\n";
    print STDERR "e: ".(defined($opt_e)?"$opt_e":"undef")."\n";
    print STDERR "p: ".(defined($opt_p)?"$opt_p":"undef")."\n";
    print STDERR "s: ".(defined($opt_p)?"$opt_s":"undef")."\n";
    print STDERR "M: ".(defined($opt_M)?"$opt_M":"undef")."\n";
    print STDERR "d: ".(defined($opt_d)?"defined":"undef")."\n";
    print STDERR "v: ".(defined($opt_v)?"defined":"undef")."\n";
    print STDERR "h: ".(defined($opt_h)?"defined":"undef")."\n";
}

if((!defined($opt_a) &&
    !defined($opt_f) &&
    !defined($opt_m) &&
    !defined($opt_p) &&
    !defined($opt_M) &&
    !defined($opt_e)) ||
   defined($opt_h)) {
    Usage();
    exit 0;
}

if($username eq "") {
    print "Username: ";
    chomp($username = <STDIN>);
    if($username eq "") {
	print "Goodbye.\n";
	exit 0;
    }
}

if($password eq "") {
    print "Password: ";
    system 'stty', '-echo';
    chomp($password = <STDIN>);
    system 'stty', 'echo';
    print "\n";
}

($ctrl = ars_Login($server, $username, $password)) || 
    die "couldn't allocate control structure";

(@schemas = ars_GetListSchema($ctrl)) ||
    die "can't read schema list: $ars_errstr";

if($opt_M) {
    # fine any menu that uses this file as it's
    # source of menu items.

    print "Menus that use the file \"$opt_M\"... (this may take a minute or so to do)\n";

    @menus = ars_GetListCharMenu($ctrl, 0);
    if($#menus != -1) {
	foreach $menu (@menus) {
	    print "Searching: $menu\n" if $debug;
	    ($menuDef = ars_GetCharMenu($ctrl, $menu)) ||
		die "ars_GetCharMenu: $ars_errstr";
	    #next unless ($menu eq "PT-Assignees");
	    #use Data::Dumper; print Dumper($menuDef); exit 0;
	    # 3 is legacy. 
	    if( ($menuDef->{menuType} == 3) || ($menuDef->{menuType} =~ /format_quotes/i) ) {
		print "\tIs type File (points to ".qq{"$menuDef->{menuFile}{filename}"}.")\n" if $debug;
		if ($menuDef->{menuFile}{filename} =~ /$opt_M/) {
		    $users{$menu} = $1;
		}
	    }
	}
	foreach (sort keys %users) {
	    print "\t$_\n";
	}
    } else {
	print "No menu's available!\n$ars_errstr\n";
    }

} elsif($opt_a) {
    # find any schema that uses this active link.

    print "Searching for Active Link \"$opt_a\" in Schema \"$SCHEMA\"...\n";

    foreach $schema (@schemas) {
	if($schema =~ /$SCHEMA/) {
	    print "Searching schema $schema..\n" if $debug;
	    @alinks = ars_GetListActiveLink($ctrl, $schema);
	    foreach $link (@alinks) {
		if($link =~ /$opt_a/) {
		    $users{$schema} .= "$link,";
		}
	    }
	}
    }

    foreach $schema (sort keys %users) {
	print "\t$schema\n";
	foreach $link (split(/,/, substr($users{$schema}, 0, length($users{$schema})-1))) {
	    print "\t\t$link\n";
	}
    }

} elsif($opt_f) {
    # find any schema that uses this filter.

    print "Searching for Filter \"$opt_f\" in Schema \"$SCHEMA\" ...\n";

    foreach $schema (@schemas) {
	if($schema =~ /$SCHEMA/) {
	    @filters = ars_GetListFilter($ctrl, $schema);
	    foreach $filter (@filters) {
		if($filter =~ /^$opt_f$/) {
		    $users{$schema} .= "$filter,";
		}
	    }
	}
    }

    foreach $schema (sort keys %users) {
	print "\t$schema\n";
	foreach $filter (split(/,/, substr($users{$schema}, 0, length($users{$schema})-1))) {
	    print "\t\t$filter\n";
	}
    }

} elsif($opt_m) {
    # find any schema that uses this menu.
    # this particular routine will take longer, because we
    # need to open each schema, and then retrieve all field
    # definitions and finally flip thru each field and see
    # what menus (if any) are attached. 

    print "Searching for Menu \"$opt_m\" in schema \"$opt_s\"...\n";
    print "(this may take some time)\n";

    foreach $schema (@schemas) {
	if($schema =~ /$SCHEMA/) {
	    print "Searching schema: $opt_s\n" if $debug;
	    @fields = ars_GetListField($ctrl, $schema);
	    foreach $field (@fields) {
		$finfo = ars_GetField($ctrl, $schema, $field);
		if(($finfo->{dataType} eq "char") && 
		   defined($finfo->{limit})) {
		    if(($finfo->{limit}{charMenu} ne "") && 
		       ($finfo->{limit}{charMenu} =~ /$opt_m/)) {
			$users{$schema} .= "$finfo->{limit}{charMenu},";
		    }
		}
	    }
	}
    }

    foreach $schema (sort keys %users) {
	print "\t$schema\n";
	foreach $menu (split(/,/, substr($users{$schema}, 0, length($users{$schema})-1))) {
	    print "\t\t$menu\n";
	}
    }

} elsif($opt_e) {
    # find any schema that uses this escalation.

    print "Searching for Escalation \"$opt_e\"...\n";

    foreach $schema (@schemas) {
	@escalations = ars_GetListEscalation($ctrl, $schema);
	if(grep(/^$opt_e$/, @escalations)) {
	    $users{$schema} = 1;
	}
    }

    foreach (sort keys %users) {
	print "\t$_\n";
    }

} elsif($opt_p) {
    # find any *filters* that call the named process

    print "Searching for filters that call \"$opt_p\"...\n";

    @filters = ars_GetListFilter($ctrl);
    if($#filters != -1) {
	foreach $filter (@filters) {
	    $finfo = ars_GetFilter($ctrl, $filter);
	    foreach $action (@{$finfo->{actionList}}) {
		if(defined($action->{process})) {
		    print "filter $filter process ".$action->{process}."\n" if $debug;
		    if($action->{process} =~ /$opt_p/) {
			$users{$filter} = $action->{process};
		    }
		}
	    }
	}
	foreach $f (sort keys %users) {
	    if(!$opt_v) {
		print "\t$f\n";
	    } else {
		print "\t$f\n\t\t$users{$f}\n";
	    }
	}
    }

} else {
    print "nothing to do!\n";
}

ars_Logoff($ctrl);

exit 0;

# ROUTINE
#   Usage()
# 
# DESCRIPTION
#   Dump usage information.
#
# AUTHOR
#   jeff murphy

sub Usage {
    print "Usage: $pname [-v] [-h] [-s schema] [-a | -f | -m | -e | -p [name]]\n";
    print "       [username] [password]\n"
}

