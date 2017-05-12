#!./perl -I./blib/arch -I.

##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2004. All rights reserved.           #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# Xue-Dong Chen - Creation and framework.                                #
#                                                                        #
# William Spurlin - Maintenance and defect fixes                         #
#                                                                        #
##########################################################################

$| = 1;

use ClearCase::CtCmd;
use Test;
BEGIN { plan tests => 8 };


my $prefix_1;

my $OS = $^O =~ /Win/ ? "Window" : "Unix";

$tmpDir = '/var/tmp';
$tmpDir = $ENV{CC_CTCMD_TMP} if $ENV{CC_CTCMD_TMP};


$prefix_1 || ($prefix_1 = $ENV{TMP}) ||  ($prefix_1 = $ENV{tmp}) || ($prefix_1 = $ENV{Tmp});
die "There must be an environment variable TMP=<path to system temporary storage, full control by everyone>"
    unless $prefix_1 || $OS !~ /Win/;




$x = ClearCase::CtCmd->new();
$pre = "";
$randNum = "007"; #not actually random number, depends on tmp file is creatable or not.
$tmpFile = "tmpCtCmdRand";
if(open(TMPFH,"$tmpFile")){
    my $fLine = <TMPFH>;
    $fLine =~ tr/[0-9]//cd;  #delete none numerical chr and others
    $randNum = $fLine;
    close(TMPFH);

    #clean the tmpFile: tmpCtCmdRand
    unlink $tmpFile;
    print STDERR "\nTemp file: $tmpFile was removed.\n";
}else{
    print STDERR "\nERROR: can't open tmp file to read\n";
}
if($OS eq "Window"){
    $pre = $ENV{'USERNAME'}.$randNum  .$ENV{'COMPUTERNAME'};
}else{
    $pre = "Unix".$randNum;
}

INITIAL:{
    $tstViewName = $pre . "CtCmdTstView";

    $pvobName = $pre . "_tmp_pvob";
    $pvobStg  = $pvobName . ".vbs";

    $vobName = $pre . "_tmp_vob";
    $vobStg = $vobName . ".vbs";

    $intViewName = $pre . "CtCmdIntView";
    $devViewName = $pre . "CtCmdDevView";
}

if($OS eq "Window"){
    $servStgVob = "";
    $servStgView = "";

    &getTmpStg;
    if($servStgVob eq "" ||$servStgView eq ""){
	print STDERR "\nERROR: Can't find tmp storage for this test\n";
	exit(7); #personal favor
    }

    $vob_tmpDirFP = $servStgVob . "\\";

    $pvobNameFP = "\\".$pvobName;
    $pvobStgFP = $vob_tmpDirFP . $pvobStg;

    $vobNameFP = "\\".$vobName;
    $vobStgFP = $vob_tmpDirFP . $vobStg;

}else{
    $tmpDirFP = $tmpDir . "/";    #FP nean full path 
    $vob_tmpDirFP = $tmpDirFP;

    $pvobNameFP = $vob_tmpDirFP . $pvobName;
    $pvobStgFP = $vob_tmpDirFP . $pvobStg;

    $vobNameFP = $vob_tmpDirFP . $vobName;
    $vobStgFP = $vob_tmpDirFP . $vobStg;
    print STDERR "\n";
}


cleanArch();
if($OS eq "Window"){
    cleanTmpStg();
}
sub cleanArch{

    print STDERR "\n--- rmview $tstViewName ---\n";
    @aa = $x->exec('rmview','-force','-tag',$tstViewName);
    ok(0,$x->status," on removing testing view $tstViewName");

    print STDERR "\n--- rmview dev view $devViewName ---\n";
    @aa = $x->exec('rmview','-force','-tag',$devViewName);
    ok(0,$x->status, " on removing dev view $devViewName ");

    print STDERR "\n--- rmview integration view $intViewName ---\n";
    @aa = $x->exec('rmview','-force','-tag',$intViewName);
    ok(0,$x->status, " on removing integration view $intViewName ");

    if($OS eq "Window"){
	print STDERR "\n--- !!please wait for 200 second while removing vobs!! --- \n";
    	sleep(200);
    }

    print STDERR "\n--- umount $vobNameFP---\n";
    @aa = $x->exec('umount', $vobNameFP);
    ok(0,$x->status, " on umounting vob $vobNameFP ");

    print STDERR "\n--- rmvob $vobNameFP ---\n";
    @aa = $x->exec('rmvob','-force', $vobStgFP);
    ok(0,$x->status, " on removing $vobNameFP\n");

    my $rv = 1;    
    if($OS ne "Window"){$rv = rmdir($vobNameFP);}
    ok(1,$rv,"rmdir $vobNameFP");

    print STDERR "\n--- umount ucm vob: $pvobNameFP ---\n";
    @aa = $x->exec('umount', $pvobNameFP);
    ok(0,$x->status, " on umounting ucm vob: $pvobNameFP ");



    print STDERR "\n--- rmpvob $pvobNameFP---\n";
    @aa = $x->exec('rmvob','-force', $pvobStgFP);
    ok(0,$x->status, " on removing ucm vob $pvobNameFP ");


    if($OS ne "Window"){rmdir($pvobNameFP);}

    #print "==================================================\n";
    #print "=================UCM Arch CleanUp=================\n";
    #print "==================================================\n";
}



sub getTmpStg{
    my $x=1;
    my $rv;
    $x=system('net share CtCmdTmp');
    if($x){ #failed
	if(!system('net share CtCmdTmp='.$prefix_1.'\CtCmdTmp7') ){
	    $servStgVob = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
	    $servStgView = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
	}else{die "Can't get temporary storage"}
    }else{
	$servStgVob = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
	$servStgView = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
    }
}
sub cleanTmpStg{
    `net share CtCmdTmp /delete`;
    if(-d ($rv = $prefix_1.'\CtCmdTmp7')){
	rmdir($rv);
	print STDERR "---Removed the temporary dir $rv ---\n";
    }
}
sub getStgVob{
    #my $localStgVob = "\\\\$ENV{'COMPUTERNAME'}\\ccstg_d\\VOBs"; 
    my $localStgVob ="";
    @aa = `net share`;
    for(@aa){
	if($_ !~ /\$/ && $_ =~ /:/){
	    @line = split(" ",$_);

	    #take the first element $line[0]
	    #bypass if the Share name and Resource are not in the same line
	    #bypass the NETLOGON for NT server
	    if($line[0]=~/:/ || $line[0]=~/NETLOGON/ ){next;}

	    $localStgVob= "\\\\$ENV{'COMPUTERNAME'}\\" . $line[0];
	    if(-d $localStgVob && -w $localStgVob){
		$servStgVob = $localStgVob;
		last;  #as break in c
	    }else{$localStgVob = "";} #for the next statement
	}
    }
    if($localStgVob eq ""){
	@aa = $x->exec('lsstgloc','-vob');
	if($#aa >=1 && $aa[1] =~/\\\\/){ #$aa[1] mean the first line of out put.
	    @line = split(" ", $aa[1]);
	    #take the second part
	    $servStgVob = $line[1];
	
	}else{ $servStgVob = "";}
    }
}
#not used in this script, may be used for future
sub getStgView{
   #my $localStgView = "\\\\$ENV{'COMPUTERNAME'}\\ccstg_d\\views"; 
    my $localStgView ="";
    @aa = `net share`;
    for(@aa){
	if($_ !~ /\$/ && $_ =~ /:/){
	    @line = split(" ",$_);

	    #take the first element
	    #bypass if the Share name and Resource are not in the same line
	    #bypass the NETLOGON for NT server
	    if($line[0]=~/:/ || $line[0]=~/NETLOGON/ ){next;}

	    $localStgView= "\\\\$ENV{'COMPUTERNAME'}\\" . $line[0];
	    if(-d $localStgView && -w $localStgView){
		$servStgView = $localStgView;
		last;  #as break in c
	    }else{ $localStgView = "";}
	}
    }
    if($localStgView eq ""){
	@aa = $x->exec('lsstgloc','-view');
	if($#aa >=1 && $aa[1] =~/\\\\/){
	    @line = split(" ", $aa[1]);
	    # take the second part
	    $servStgView = $line[1];
	}else{ $servStgView = "";}
    }
}
