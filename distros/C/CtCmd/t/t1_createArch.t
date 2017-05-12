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
ClearCase::CtCmd::version();
$x = ClearCase::CtCmd->new();
$OS = &os_test;
use Test;
BEGIN { plan tests => 27 };
$view_netname = "";
$rv = 0;
$tmpDir = '/var/tmp';
$tmpDir = $ENV{CC_CTCMD_TMP} if $ENV{CC_CTCMD_TMP};

$pre = "";

#use this for random number which will aviod the confliction.
$randNum = "007"; #not actually random number, depends on tmp file is creatable or not. 

#write this randNum to tmp file, which will be used by cleanArch.t
$tmpFile = "tmpCtCmdRand";
if(open(TMPFH,">$tmpFile")){
    $randNum = $$;   #actually random number current process id
    print TMPFH $randNum;
    close(TMPFH);
    print STDERR "\nTemp file: $tmpFile was created.\n";
}else{
    print STDERR "\nERROR: can't open tmp file to write\n";
}

if($OS eq "Window"){
    $pre = $ENV{'USERNAME'}.$randNum  .$ENV{'COMPUTERNAME'};
    $view_netname = $ENV{CC_VIEW_NETNAME} ? $ENV{CC_VIEW_NETNAME} : '\\\view\\';
}else{
    $pre = "Unix".$randNum;
}

INITIAL:{
   $tstViewName = $pre . "CtCmdTstView";
   $tstViewStg = $tstViewName . ".vws";    #Stg mean storage
   $pvobName = $pre . "_tmp_pvob";
   $pvobStg  = $pvobName . ".vbs";
   $vobName = $pre . "_tmp_vob";
   $vobStg = $vobName . ".vbs";
   @folders = qw/fd_1 fd_2 fd_1_1 fd_1_2 fd_1_2_1/;

   $projName = $pre . "projCtCmd";

   $streamInt = $pre . "CtCmd_int1Str";
   $streamDev = $pre . "CtCmd_dev1Str";

   $intViewName = $pre . "CtCmdIntView";
   $intViewStg = $intViewName . ".vws";

   $devViewName = $pre . "CtCmdDevView";
   $devViewStg = $devViewName . ".vws";

   $actName = $pre . "CtCmdAct";
}
if($OS eq "Window"){
    $servStgVob = "";
    $servStgView = "";

    &mkTmpStg;
    if($servStgVob eq "" ||$servStgView eq ""){
	print STDERR "\nERROR: Can't make tmp storage for this test\n";
	exit(7); #personal favor
    }
    $dfDrive = "";
    @drArray = ();

    #difference of Unix and NT 

    $vob_tmpDirFP = $servStgVob . "\\";
    $view_tmpDirFP = $servStgView . "\\";
    
    $tstViewStgFP = $view_tmpDirFP . $tstViewStg;

    #difference for pvob tag name Unix /vobs/xxpvob, NT \xxpvob
    #stg is the same naming both unix and NT

    $pvobNameFP = "\\". $pvobName;
    $pvobStgFP = $vob_tmpDirFP . $pvobStg;

    $vobNameFP = "\\".$vobName;
    $vobStgFP = $vob_tmpDirFP . $vobStg;

    $intViewStgFP = $view_tmpDirFP . $intViewStg;
    $devViewStgFP = $view_tmpDirFP . $devViewStg;

    $fName = "dump.c";
    #the full path name can't be explicitly as unix, it gonna to be depends on the vob
    $fNameFP = $vobNameFP . "\\" . $fName;
    
}else{
    $tmpDirFP = $tmpDir . "/";    #FP nean full path 
    $vob_tmpDirFP = $tmpDirFP;
    $view_tmpDirFP = $tmpDirFP;

    $tstViewStgFP = $view_tmpDirFP . $tstViewStg;
   
    $pvobNameFP = $vob_tmpDirFP . $pvobName;
    $pvobStgFP = $vob_tmpDirFP . $pvobStg;

    $vobNameFP = $vob_tmpDirFP . $vobName;
    $vobStgFP = $vob_tmpDirFP . $vobStg;

   
    $intViewStgFP = $view_tmpDirFP . $intViewStg;
    $devViewStgFP = $view_tmpDirFP . $devViewStg;

    $fName = "dump.c";
    $fNameFP = $vobNameFP . "/" . $fName;
   
}

createArch();

#clean NT mapped driver
#used for WINNT mapped drivers clean up otherwise all driver will be mapped!!!
if($OS eq "Window"){
    my($item);
    foreach $item (@drArray){
	my $cmd= "net use " . $item . " /delete";
	`$cmd`;
    }
}

sub createArch{

    print STDERR "\n--- mkview testing view: $tstViewName ---\n";
    @aa = $x->exec('mkview','-tag',$tstViewName, $tstViewStgFP);
    die "must be able to make view" unless ok(0,$x->status,"$aa[2]");
    

    print STDERR "\n--- setview to testing view: $tstViewName ---\n";
    if($OS eq "Window"){
	&mapDrive($view_netname . $tstViewName);
	$rv = chdir $dfDrive;
	$rv = $rv? 0 : 1;
    }else{
	$i=0;
	@aa = $x->exec('setview',$tstViewName);
	$rv = $x->status;
    }

    die "must be able to set view" unless ok(0,$rv,"set view to $tstViewName ".$aa[2]);


    print STDERR "\n--- mkvob ucm vob $pvobNameFP ---\n";
    @aa = $x->exec('mkvob','-nc','-ucm','-tag',$pvobNameFP, $pvobStgFP);
    die "must be able to make vob" unless ok(0,$x->status,"$aa[2]");

    $rv="";
    if($OS !~ /Window/){
	$rv = mkdir($pvobNameFP,0755);
    }

    print STDERR "\n--- mount ucm vob $pvobNameFP ---\n";
    @aa = $x->exec('mount',$pvobNameFP);
    die "must be able to mount vob" unless ok(0,$x->status,$aa[2].$rv);

    print STDERR "\n--- mkvob component $vobNameFP ---\n";
    @aa = $x->exec('mkvob','-nc','-tag', $vobNameFP, $vobStgFP);
    die "must be able to make vob" unless ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkattr Tested in $pvobNameFP ---\n";
    @aa = $x->exec('mkattype','-nc','-enum','"TRUE","FALSE"','-default','"FALSE"','Tested@'.$vobNameFP);
    ok(0,$x->status,"$aa[2]");

    $rv="";
    if($OS !~ /Window/){ 
       $rv = mkdir($vobNameFP,0755);
   }

    print STDERR "\n--- mount $vobNameFP ---\n";
    @aa = $x->exec('mount',$vobNameFP);
    die "must be able to mount vob" unless ok(0,$x->status,$aa[2].$rv);

    print STDERR "\n--- lsvob $vobNameFP ---\n";
    @aa = $x->exec('lsvob','-long', $vobNameFP);
    die "must be able to list vob" unless ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- add component $vobName ---\n";
    @aa = $x->exec('mkcomp','-nc', '-root', $vobNameFP, ($vobName . '@' . $pvobNameFP));
    die "must be able to make component" unless ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkfolder level  first ---\n";
    @aa = $x->exec('mkfolder','-nc','-in',("RootFolder@" . $pvobNameFP),($folders[0]. '@' . $pvobNameFP));
    die "must be able to make folder 0" unless ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkfolder level 1 second ---\n";
    @aa = $x->exec('mkfolder','-nc','-in',("RootFolder@" . $pvobNameFP),($folders[1] . '@' . $pvobNameFP));
    die "must be able to make folder 1" unless ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkfolder flevel 1 within $folders[1] ---\n";
    @aa = $x->exec('mkfolder','-nc','-in',($folders[1] . '@' . $pvobNameFP),($folders[2] . '@' . $pvobNameFP));
    die "must be able to make folder 2" unless     ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkfolder level 2 within $folders[1] ---\n";
    @aa = $x->exec('mkfolder','-nc','-in',($folders[1] . '@' . $pvobNameFP),($folders[3] . '@' . $pvobNameFP));
    die "must be able to make folder 3" unless     ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkfolder level 3 within $folders[3] ---\n";
    @aa = $x->exec('mkfolder','-nc','-in',($folders[3] . '@' . $pvobNameFP),($folders[4] . '@' . $pvobNameFP));
    die "must be able to make folder 4" unless     ok(0,$x->status,"$aa[2]"); 

    print STDERR "\n--- mkproject $projName---\n";
    @aa = $x->exec('mkproject', '-mod',($vobName . '@' . $pvobNameFP), '-in', ($folders[4] . '@' . $pvobNameFP), ($projName . '@' . $pvobNameFP));
    die "must be able to make project" unless     ok(0,$x->status,"$aa[2]"); 

    @aa = $x->exec('lsbl', '-comp', ($vobName . '@' . $pvobNameFP));

    #get baseline

    $rv="";
    (my $cctime,my $baseline) = split(" ",$aa[1]);
    my $sstr = $vobName . "_INITIAL";
    if($rv = $baseline =~ /$sstr/){
	print STDERR "\n--- baseline is: $baseline ---\n";
    }
    die "must be able to derive baseline" unless     ok(0,$x->status && $rv,"$aa[2]".$aa[1]); 


    print STDERR "\n--- mkstream integration stream: $streamInt ---\n";
    @aa = $x->exec('mkstream','-integration', '-baseline',$baseline, '-in',($projName . '@' . $pvobNameFP), ($streamInt . '@' . $pvobNameFP));
    die "must be able to make stream" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- mkstream dev stream: $streamDev ---\n";
    @aa = $x->exec('mkstream','-baseline', $baseline, '-in',($projName . '@' . $pvobNameFP), ($streamDev . '@' . $pvobNameFP) );
    die "must be able to make stream" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- mkview integration view: $intViewName ---\n";
    @aa = $x->exec('mkview','-tag',$intViewName,'-stream',($streamInt . '@' .$pvobNameFP), $intViewStgFP);
    die "must be able to make view" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- mkview development view: $devViewName ---\n";
    @aa = $x->exec('mkview','-tag',$devViewName,'-stream',($streamDev . '@' .$pvobNameFP), $devViewStgFP);
    die "must be able to make view" unless  ok(0,$x->status,"$aa[2]");    

    $rv="";
    print STDERR "\n--- setview to $devViewName---\n";
    if($OS eq "Window"){
	&mapDrive($view_netname . $devViewName);
	$rv = chdir $dfDrive;    
	$rv = $rv? 0 : 1;
    }else{
	$i=0;
	@aa = $x->exec('setview',$devViewName);	
	$rv = $x->status;
    }
    die "must be able to set view" unless ok(0,$rv,"set view to $devViewName ".$aa[2]);

    print STDERR "\n--- pwv ---\n";
    @aa = $x->exec('pwv');
    for(@aa){
    };
    die "must be able to print working view" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- mkactivity $actName ---\n";
    @aa = $x->exec('mkact','-force',$actName);
    die "must be able to make activity" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- checkout directory $vobNameFP ---\n";
    @aa = $x->exec('co','-nc',$vobNameFP);
    die "must be able to check out directory" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- mkelem $fNameFP ---\n";
    @aa = $x->exec('mkelem','-nc','-nco', $fNameFP);
    die "must be able to make element" unless  ok(0,$x->status,"$aa[2]");

    print STDERR "\n--- describe element $fNameFP ---\n";
    @aa = $x->exec('describe', $fNameFP);
    die "must be able to describe element" unless  ok(0,$x->status,"$aa[2]");
   
    print STDERR "\n--- checkin directory $vobNameFP ---\n";
    @aa = $x->exec('ci','-nc',$vobNameFP);
    die "must be able to check in directory " unless  ok(0,$x->status,"$aa[2]");

}


sub os_test{

    eval "use Config";
    if(!defined($Config{osname}) || $Config{osname} =~ /Win/){
	return "Window";
    }
    else{
	return "Unix";
    }
}

sub mkTmpStg{
    my $x="";
    my $tmp_dir_name = '\CtCmdTmp7';
    my $prefix_1;
    ($prefix_1 = $ENV{TMP}) ||  ($prefix_1 = $ENV{tmp}) || ($prefix_1 = $ENV{Tmp});
    die "There must be an environment variable TMP=<path to system temporary storage, full control by everyone>"
	unless $prefix_1;
    my $pwd=`CHDIR`; chomp $pwd;
    my $rv = `net share`;
    system('net share /del CtCmdTmp') if $rv =~ /CtCmdTmp/;
    $rv = 0;
    if(!(-d ($rv=$prefix_1.$tmp_dir_name))){
		die "Unable to make temporary directory $prefix_1.$tmp_dir_name  " 
	    	unless mkdir($rv = $prefix_1.$tmp_dir_name,0644)  ;
		print STDERR "---Created temporary directory $rv ---\n";
    }
	$x=system(qq(net share "CtCmdTmp=$rv" /grant:$ENV{USERDOMAIN}\\$ENV{USERNAME},FULL));
	if($x){
	    die "Unable to net share CtCmdTmp=$rv"
	}else{
	    $servStgVob = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
	    $servStgView = "\\\\$ENV{'COMPUTERNAME'}\\"."CtCmdTmp";
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
#not currently used, in case of future usage
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

#used for mkcomp, without this it won't go through.
sub mapDrive{
    my $mapped = 3; # 3 means not mapped yet
    my $i = 0;
    my $view = shift @_;
    my $aa = `net use`;  #use $ instead of @
    my $dName = "";
    for($i=0;$i<20&&$mapped !=0;$i++){
	#use 71 means beginning from G:
	$dName = chr(71+$i) . ':' ;

	if($aa !~ /$dName/){    
	    $mapped = system('net', 'use', $dName, $view);
	}
    }
    if($mapped == 0){
	$dfDrive = $dName ;
	push(@drArray, $dfDrive);
        print STDERR "--- Mapped the view to $dName  ---\n";
    }else {
	print STDERR "\nERROR: on mapping the view!\n";
    }
}





