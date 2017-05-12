#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Show_ALink.pl,v 1.6 2000/06/01 16:54:03 jcmurphy Exp $
#
# EXAMPLE
#    Show_ALink.pl
#
# DESCRIPTION
#    Use ars_GetActiveLink to obtain information about an active link.
#
# NOTES
#    This is a fairly large and involved example, however it illustrates
#    many points about how to decode the more complex information that
#    can be passed back from the API.
#
#    All structures demonstrated herein are documented in the usage.html
#    documentation.
#
#    This example file parse most (but not all) of the active links 
#    fields. 
#
# AUTHOR
#    jeff murphy
#
# 01/12/96
# 
# $Log: Show_ALink.pl,v $
# Revision 1.6  2000/06/01 16:54:03  jcmurphy
# *** empty log message ***
#
# Revision 1.5  1998/09/14 17:41:05  jcmurphy
# added ChangeDiary decoding lines
#
# Revision 1.4  1998/09/11 17:49:47  jcmurphy
# updated EXECUTE_ON definitions
#
# Revision 1.3  1998/09/11 17:22:13  jcmurphy
# changed macroParms from array to hash since it is
# a hashref.
#
# Revision 1.2  1997/11/11 15:04:47  jcmurphy
# added qual decoding
#
# Revision 1.1  1996/11/21 20:13:55  jcmurphy
# Initial revision
#
#

use ARS;
$debug = 0;
require 'ars_QualDecode.pl';

@MessageTypes = ( "Note", "Warn", "Error" );


# Parse command line parameters

($server, $username, $password, $alink_name) = @ARGV;
if(!defined($alink_name)) {
    print "usage: $0 [server] [username] [password] [alink name]\n";
    exit 1;
}

$level = 0;

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

# SUBROUTINE
#   DecodeExecMask
#
# DESCRIPTION
#   Simple routine to return a string representing (in english)
#   the execution mask value(s).

$AR_EXECUTE_ON_NONE          = 0;
$AR_EXECUTE_ON_BUTTON        = 1;
$AR_EXECUTE_ON_RETURN        = 2;
$AR_EXECUTE_ON_SUBMIT        = 4;
$AR_EXECUTE_ON_MODIFY        = 8;
$AR_EXECUTE_ON_DISPLAY       = 16;
$AR_EXECUTE_ON_MODIFY_ALL    = 32;
$AR_EXECUTE_ON_MENU          = 64;
$AR_EXECUTE_ON_MENU_CHOICE   = 128;
$AR_EXECUTE_ON_LOOSE_FOCUS   = 256;
$AR_EXECUTE_ON_SET_DEFAULT   = 512;
$AR_EXECUTE_ON_QUERY         = 1024;
$AR_EXECUTE_ON_AFTER_MODIFY  = 2048;  # Added in 3.2
$AR_EXECUTE_ON_AFTER_SUBMIT  = 4096;
$AR_EXECUTE_ON_GAIN_FOCUS    = 8192;
$AR_EXECUTE_ON_WINDOW_OPEN   = 16384;
$AR_EXECUTE_ON_WINDOW_CLOSE  = 32768;

%ars_ExecuteOn = ($AR_EXECUTE_ON_BUTTON, "Button", 
    $AR_EXECUTE_ON_RETURN,        "Return",
    $AR_EXECUTE_ON_SUBMIT,        "Submit",
    $AR_EXECUTE_ON_MODIFY,        "Modify",
    $AR_EXECUTE_ON_DISPLAY,       "Display", 
    $AR_EXECUTE_ON_MENU,          "Menu", 
    $AR_EXECUTE_ON_MENU_CHOICE,   "Menu_Choice", 
    $AR_EXECUTE_ON_LOOSE_FOCUS,   "Loose_Focus", 
    $AR_EXECUTE_ON_SET_DEFAULT,   "Set_Default",
    $AR_EXECUTE_ON_QUERY,         "Query",
    $AR_EXECUTE_ON_AFTER_MODIFY,  "After_Modify",
    $AR_EXECUTE_ON_AFTER_SUBMIT,  "After_Submit",
    $AR_EXECUTE_ON_GAIN_FOCUS,    "Gain_Focus",
    $AR_EXECUTE_ON_WINDOW_OPEN,   "Window_Open",
    $AR_EXECUTE_ON_WINDOW_CLOSE,  "Window_Close" 
		  );

sub DecodeExecMask {
    my $m = shift;
    my $s, $v;

    if(defined($m)) {
	foreach $v (sort keys %ars_ExecuteOn) {
	    if($v & $m) {
		$s = $s." ".$ars_ExecuteOn{$v};
	    }
	}
    }
    return($s);
}

# SUBROUTINE
#   PrintArith
#
# DESCRIPTION
#   Attempt to "pretty print" the arith expression (just for
#   the hell of it)
#
# NOTES
#   Notic that parenthesis are printed, although they are not
#   explicitly part of the node information. They are derived
#   from the ordering of the tree, instead. If you want to actually
#   *evaluate* the expression, you will have to derive the 
#   parenthetical encoding from the tree ordering.
#
#   Here is an example equation and how it is encoded:
#
#   ((10 + 2) / 3)
#
#          "/"
#         /   \
#       "+"    3
#      /  \
#    10    2
#
#   ARS apparently sorts the operations for you (based on their
#   mathematical precedence) so you should evaluate the tree from 
#   the bottom up. 
#
#   ars_web.cgi has an evaluation routine for computing the value
#   of a arith structure. we will probably break it out into a
#   perl module.
#
# THOUGHTS
#   I don't know if this routine will work for all cases.. but
#   i did some tests and it looked good. Ah.. i just wrote it
#   for the fun of it.. so who cares? :)

sub PrintArith {
    my $a = shift;

    PrintArith_Recurs($a, 0);
    print "\n";
}

sub PrintArith_Recurs {
    my $a = shift;
    my $p = shift;
    my $n, $i;

    if(defined($a)) {
	$n = $a->{left};
	if(defined($n)) {
	    if(defined($n->{arith})) {
		PrintArith_Recurs($n->{arith}, $p+1);
	    } else {
		for($i=1;$i<$p;$i++) {
		    print " ( ";
		}
	    }
	    print " ( $n->{value} " if defined($n->{value});
	    print " ( \$$n->{field}->{fieldId}\$ " if defined($n->{field});
	    print " ( $n->{function} " if defined($n->{function});
	}
	print " $a->{oper} ";
	$n = $a->{right};
	if(defined($n)) {
	    print " $n->{value} ) " if defined($n->{value});
	    print " \$$n->{field}->{fieldId}\$ ) " if defined($n->{field});
	    PrintArith_Recurs($n->{arith}) if defined($n->{arith});
	    print " $n->{function} ) " if defined($n->{function});
	}
    }
}


# SUBROUTINE
#   ProcessArithStruct
#
# DESCRIPTION
#   This routine breaks down the arithmetic structure

sub ProcessArithStruct {
    my $a = shift;
    my $n;

    if(defined($a)) {
	printl 5, "Operation: $a->{oper}\n";
	$n = $a->{left};
	if(defined($n)) {
#	    printl 5, "(Left) ";
	    printl 5, "Value: \"$n->{value}\"\n" if defined($n->{value});
	    printl 5, "Field: \$$n->{field}->{fieldId}\$\n" if defined($n->{field});
	    printl 5, "Process: $n->{process}\n" if defined($n->{process});
	    ProcessArithStruct($n->{arith}) if defined($n->{arith});
	    printl 5, "Function: $n->{function}\n" if defined($n->{function});
	    printl 5, "DDE: DDE not supported in ARSperl\n" if defined($n->{dde});
	}
	$n = $a->{right};
	if(defined($n)) {
#	    printl 5, "(Right) ";
	    printl 5, "Value: \"$n->{value}\"\n" if defined($n->{value});
	    printl 5, "Field: \$$n->{field}->{fieldId}\$\n" if defined($n->{field});
	    printl 5, "Process: $n->{process}\n" if defined($n->{process});
	    ProcessArithStruct($n->{arith}) if defined($n->{arith});
	    printl 5, "Function: $n->{function}\n" if defined($n->{function});
	    printl 5, "DDE: DDE not supported in ARSperl\n" if defined($n->{dde});
	}
    }
}

# SUBROUTINE
#   ProcessFunctionList
#
# DESCRIPTION
#   Parse and dump the function list structure. 

sub ProcessFunctionList {
    my $t = shift;   # how much indentation to use
    my @func = @_;
    my $i;

    printl $t, "Function Name: \"$func[0]\" .. Num of args: $#func\n";

    # we need to process all of the arguments listed.

    for($i=1;$i<=$#func;$i++) {
	printl $t+1, "Value: \"$func[$i]->{value}\"\n" if defined($func[$i]->{value});
	printl $t+1, "Field: \$$func[$i]->{field}->{fieldId}\$\n" if defined($func[$i]->{field});
	printl $t+1, "Process: $func[$i]->{process}\n" if defined($func[$i]->{process});

	PrintArith($func[$i]->{arith}) if defined($func[$i]->{arith});

	# if the arg is a pointer to another function, we need to process
	# it recursively.

	if(defined($func[$i]->{function})) {
	    ProcessFunctionList($t+1, @{$func[$i]->{function}});
	}
	printl $t+1, "DDE: DDE not supported in ARSperl\n" if defined($func[$i]->{dde});
    }
}

# SUBROUTINE
#   ProcessSetFields
#
# DESCRIPTION
#   This routine dumps the various forms of the Set Fields
#   action in active links.

sub ProcessSetFields {
    my $field = shift;

    if(defined($field->{none})) {
	printl 3, "No set fields instructions found.\n";
    }
    if(defined($field->{value})) {
	printl 3, "Value: \$$field->{value}\$\n";
    }
    if(defined($field->{field})) {
	printl 3, "Field: $field->{field}\n";
    }
    if(defined($field->{process})) {
	printl 3, "Process: $field->{process}\n";
    }
    if(defined($field->{arith})) {
	printl 3, "Arithmetic:\n";
#	ProcessArithStruct($field->{arith});
	printl 4, "Expression: ";
	PrintArith($field->{arith});
    }
    if(defined($field->{function})) {
	printl 3, "Function:\n";
	ProcessFunctionList(4, @{$field->{function}});
    }
    if(defined($field->{dde})) {
	printl 3, "DDE not implemented in ARSperl.\n";
    }
}

# SUBROUTINE
#   ProcessMacroStruct
#
# DESCRIPTION
#   This routine breaks down the macro structure and
#   dumps the information contained in it.

sub ProcessMacroStruct {
    my $t = shift;    # how much indentation to use
    my $m = shift;    # the macro struct
    my $i, @p;

    if(defined($m)) {
	printl $t, "Macro Name  : \"$m->{macroName}\"\n";
	printl $t, "Macro Params: $m->{macroParms}\n";

	foreach (keys %{$m->{macroParms}}) {
	    printl $t+1, "$_ = $m->{macroParms}{$_}\n";
	}

	printl $t, "Macro Text  :\n**START**\n$m->{macroText}\n**END**\n";
    }
}


# SUBROUTINE
#   ProcessActions
#
# DESCRIPTION
#   this routine processes the list of actions for this active link,
#   deciding what actions are defined and dumping the appropriate 
#   information.

sub ProcessActions {
    my @actions = @_;
    if(defined(@actions)) {
	$act_num = 1;
	foreach $action (@actions) {
	    printl 1, "Action $act_num:\n";
	    if(defined($action->{macro})) {
		printl 2, "Macro:\n";
		ProcessMacroStruct(3, $action->{macro});
	    }
	    if(defined($action->{assign_fields})) {
		printl 2, "Set Fields:\n";
		foreach $setFields (@{$action->{assign_fields}}) {
		    printl 3, "fieldId: $setFields->{fieldId}\n";
		    ProcessSetFields($setFields->{assignment});
		}
	    }
	    if(defined($action->{message})) {
		printl 2, "Message: \n";
		foreach my $k (keys %{$action->{message}}) {
			printl 3, "$k: $action->{'message'}->{$k}\n";
		}
	    }
	    if(defined($action->{process})) {
		printl 2, "Process: ".$action->{process}."\n";
	    }
	    if(defined($action->{characteristics})) {
		printl 2, "Change Field: ".$action->{characteristics}."\n";
	    }
	    if(defined($action->{dde})) {
		printl 2, "DDE is not implemented in ARSperl.\n";
	    }
	    if(defined($action->{none})) {
		printl 2, "No actions specified.\n";
	    }
	    $act_num++;
	}
	print "\n";
    } else {
	print "No actions to process!\n";
    }
}
# Log onto the ars server specified

($ctrl = ars_Login($server, $username, $password)) || 
    die "can't login to the server";

# Retrieve info about active link.

($a = ars_GetActiveLink($ctrl, $alink_name)) ||
    die "can't fetch info about that active link";


print "Active Link Attributes:\n\n";

print  "Name: ".$a->{name}."\n";
print  "Execution Order: ".$a->{order}."\n";
if(defined($a->{'schema'})) {
	print  "Schema Name: ".$a->{schema}."\n";
} elsif(defined($a->{'schemaList'})) {
	print  "schemaList : ";
	foreach my $s (@{$a->{'schemaList'}}) {
		print "\"$s\" ";
	}
	print "\n";
}
print  "Group Perms: ";

foreach $group (@{$a->{groupList}}) {
    print "$group; ";
}
print "\n";

                                                  # XXX - decode
print  "Execute On: ".DecodeExecMask($a->{executeMask})."\n";
print  "Field: ".$a->{field}."\n";     # XXX - display only when needed (execmask)
print  "Display List:\n";

foreach $display (@{$a->{displayList}}) {
    printl 1, "Display Name: ".$display->{displayTag}."\n";
    printl 2, "x corrd: ".$display->{x}."\n";
    printl 2, "y coord: ".$display->{y}."\n";
    printl 2, "Visible?: ".$display->{option}."\n";
    printl 2, "Button Label: ".$display->{label}."\n";
    printl 2, "Type: ".$display->{type}."\n";
}
print "\n";

#print  "Qualification: ".$a->{query}."\n";

$dq = ars_perl_qualifier($ctrl, $a->{query});
$dq = undef if(isempty($dq));

if(defined($dq)) {
	if(defined($a->{'schema'})) {
		$dq_text = ars_Decode_QualHash($ctrl, $a->{schema}, $dq);
		print  "    Qual Text: $dq_text\n";
	}
	elsif(defined($a->{'schemaList'})) {
		foreach my $s (@{$a->{'schemaList'}}) {
			$dq_text = ars_Decode_QualHash($ctrl, $s, $dq);
			print "     Qual Text (decoded against \"$s\": $dq_text\n";
		}
	}
} else {
	print "    Qual Text: [none defined]\n";
}

print  "Actions:\n";

ProcessActions(@{$a->{actionList}});

print  "Help Text: ".$a->{helpText}."\n";
print  "Owner: ".$a->{owner}."\n";
print  "Last changed by: ".$a->{lastChanged}."\n";
print  "Last Modified: ".localtime($a->{timestamp})."\n";
print  "Change Diary: $a->{changeDiary}\n";

foreach (@{$a->{changeDiary}}) {
    print "\tTIME: ".localtime($_->{timestamp})."\n";
    print "\tUSER: $_->{user}\n";
    print "\tWHAT: $_->{value}\n";
}

# Log out of the server.

ars_Logoff($ctrl);

exit 0;

sub isempty {
	my $r = shift;
	return 1 if !defined($r);
	if(ref($r) eq "ARRAY") {
		return ($#{$r} == -1) ? 1 : 0;
	}
	if(ref($r) eq "HASH") {
		my @k = keys %{$r};
		return ($#k == -1) ? 1 : 0;
	}
	return 1 if($r eq "");
	return 0;
}
