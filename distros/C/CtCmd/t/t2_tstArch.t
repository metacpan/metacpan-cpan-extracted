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

use CC::View;
use CC::Vob;
use CC::VobObject;
use CC::CompHlink;
use CC::Component;
use CC::Folder;
use CC::Baseline;
use ClearCase::CtCmd;
#used to disable some test

use Test;
BEGIN { plan tests => 66 };

$view_netname = "";
$rv = 0;
@aa = ();
$this_activity=NULL;

$tmpDir = '/var/tmp';
$tmpDir = $ENV{CC_CTCMD_TMP} if $ENV{CC_CTCMD_TMP};

$OS = &os_test;

use Test;

$x = ClearCase::CtCmd->new();

$pre = "";
$randNum = "007"; #not actually random number, depends on tmp file is creatable or not.
$tmpFile = "tmpCtCmdRand";
if(open(TMPFH,"$tmpFile")){
    my $fLine = <TMPFH>;
    $fLine =~ tr/[0-9]//cd;  #delete none numerical chr and others
    $randNum = $fLine;
    close(TMPFH);
}else{
    print STDERR "\nERROR: can't open tmp file to read\n";
}


if($OS eq "Window"){
    $pre = $ENV{'USERNAME'}.$randNum  .$ENV{'COMPUTERNAME'};
    $view_netname = $ENV{CC_VIEW_NETNAME} ? $ENV{CC_VIEW_NETNAME} : '\\\view\\';
}else{
    $pre = "Unix".$randNum;
}

INITIAL:{

    $vobName = $pre . "_tmp_vob";
    $devViewName = $pre . "CtCmdDevView";
}

if($OS eq "Window"){

    $dfDrive = "";
    @drArray = ();
    $vobNameFP = "\\".$vobName;

    $fName = "dump.c";
    #the full path name can't be explicitly as unix, it  depends on the vob
    $fNameFP = $vobNameFP . "\\" . $fName; 

}else{
    $tmpDirFP = $tmpDir . "/";    #FP means full path 
    $vob_tmpDirFP = $tmpDirFP;

    $vobNameFP = $vob_tmpDirFP . $vobName;
    $fName = "dump.c";
    $fNameFP = $vobNameFP . "/" . $fName;
}


    print  STDERR "\n--- setview to $devViewName---\n";
    @aa = $x->exec('lsview',$devViewName);
    die "development view $devViewName does not exist" unless ok(0,$x->status,"$aa[2]");

    if($OS eq "Window"){
	&mapDrive($view_netname . $devViewName);
	$rv = chdir $dfDrive;
	$rv = $rv? 0 : 1;
    }else{   
	@aa = $x->exec('setview',$devViewName);
	$rv = $x->status;
    }
    die "must be able to set view" unless ok(0,$rv,"set view to $devViewName ".$aa[2]);

    $c_view=CC::View::current_view;
    print  "The view tag of the current view is: ",join("\n",$c_view->tag),"\n";


for($i = 0; $ i < 4; $i ++){
    tstArch($i);
}

#clean NT mapped driver
#used for WINNT mapped drivers clean up otherwise all driver will be mapped!!!
if($OS eq "Window"){
    my($item);
    foreach $item (@drArray){
	my $cmd= "net use " . $item . " /delete";
	`$cmd`;
    }
}

1;

#
# To test the arch just built using CC module.
#

sub tstArch{

    my $iter = shift;

    print  "==================================================\n";
    print  "=================UCM Arch Testing ",$iter + 1," ==============\n";
    print  "==================================================\n";

    $element = $fNameFP;

    $attr_type='Tested';

    

    print  "The vob object is $element\n";

    $element = CC::CompHlink->new($element);

    print STDERR  "\n--- Vob Tag:", $rv=$element->vob->tag," ---\n";

    ok(0,$element->{status},$rv);


    $boolean_complement{TRUE}='FALSE';$boolean_complement{FALSE}='TRUE';


    if($version_for_attr){
	print "Existing attribute: ",$version_for_attr->name,"\n";
	if ($version_for_attr->has_attr($attr_type)){
	    print "Has an attribute $attr_type\n";
	    my $val = $version_for_attr->get_attr($attr_type);
	    chomp $val;
	    $version_for_attr->set_attr($attr_type,$boolean_complement{$val});
	    $rv =  $version_for_attr->has_attr($attr_type);
	    
	}
    }else{
	$version_for_attr = CC::Version->new($element->name);
	print  "New attribute: \t",$version_for_attr->name,"\n";
	$version_for_attr->set_attr($attr_type,"FALSE")
	};

    $rv = $version_for_attr->get_attr($attr_type);
    chomp $rv;
    print STDERR "\n--- Has attr\? ",$version_for_attr->has_attr($attr_type)," Attribute set to ",$rv, " ---\n";

    ok(0,$version_for_attr->{status},$rv);

    @method=(['name'],['objsel'],['dbid'],['metatype'],['type'],['vob',"",'tag']);


    for (@method){
	my $method=$$_[0]; 
	my $parameter=$$_[1];
	my $submethod=$$_[2];
	if ($submethod){
	    print STDERR "\n--- ", $submethod,"\t",$element->$method()->$submethod($parameter)," ---\n" }
	else{
	    print STDERR  "\n--- ", $method,"\t",$element->$method($parameter)," ---\n";  
	}
	ok(0,$element->{status},"$method failed");
    }

    
    my $pv = $element->adminvob;
    print  STDERR "\n--- Adminvob: ", $pv->tag," ---\n";

    die "must be able to open admninvob" unless ok(0,$element->{status});

    print  "Listing Components in Project Vob:\n" unless $iter;
    @comps = $pv->list;

    for $x (@comps){
	my @bb=$x->describe;
	my $comp = $bb[0];

	#FIX

	print  "original: $comp \n";
	$comp =~ s/.*\"(.+)\".*/$1/;
	
	print  $comp,"\n";
	my $nc=CC::Component->new($comp,$pv);
	print  STDERR "\n--- Component name ",$nc->name," \nobjsel ",$nc->objsel,
	" \nroot directory ",$nc->root_directory->full_path," ---\n" unless $iter;
	ok(0,$nc->{status},"Component $comp") 
    }



    my $rf = CC::Folder::root_folder($pv);

    ok(0,$rf->{status},"Root folder in pvob\?");

    print STDERR  "\n--- ",name_title($rf,"Root Folder");

    my @foldrs = $rf->folders;

    do_folders("\t",@foldrs) unless $iter;


    print  "\n\n",name_title($this_activity,"The Chosen Activity");
    $this_activity->start_work(CC::View->current_view);

    for $component ($this_activity->stream->components){
	$path=$this_activity->stream->foundation_baseline($component)->component->root_directory->path;
	print STDERR "\n--- $path ---\n";
    }
    ok(0,$this_activity->{status},$this_activity->name." no components");
    print  "The Foundation Baseline's Component Root Directory path is: ";
    $path =~ s/\.$//; 
    print  $path,"\n";

    $rv = ClearCase::CtCmd::exec('find',$path,'-name','dump.c','-print');
    $rv =~ s/\@\@\s*$//;
    print  "$rv\n";
    my $this_version=CC::Version->new($rv);
    print  "We just picked a Version:",$this_version->name,"\n";
    my @this_changeset = $this_activity->changeset;


    print  "Number of activities in changeset: $#this_changeset \n";
    if (@this_changeset){
	print  $this_activity->name," Changeset\n";
	for $version (@this_changeset){print  "\t",$version->name,"\n"}
    }else{ print  "No Changeset\n";}

    if ($#this_changeset >= 2){
	print  "Delivering to ",name_title($this_activity->stream->project->integration_stream,"The Integration Stream of ".$this_activity->name);
	my $rv=$this_activity->stream->deliver("-complete","-force");
	if ($rv =~ /HASH/){ print  name_title($rv,"Delivery succeeded returning this activity");}
	else{print  $rv}
    }

    my $fname=$this_version->path;



    $rv=$this_version->checkout($this_version) unless $this_version->ischeckedout;
    print  STDERR "\n--- Results of Checkout: of $fname Version: ",$this_version->name,": ---\n";
    ok(0,$this_version->{status},$this_version->name);
    
    if ($rv){
	print STDERR "\n--- ", $rv->full_path," ---\n";
    }

   
 
    print STDERR  "\n--- Adding some text: ",my $txt=newstring()," ---\n";
	
    $rv = open F, ">>$fname";
    ok(1,$rv,"$! Can't open  $fname.  Must be able to write to checked out version") or die;
    print F $txt."\n";
    close F;
    @rv=$this_version->checkin($this_version);
    print  "Checked in: @rv\n";


    @this_changeset = $this_activity->changeset;

    ok(0,$this_activity->{status},"No Changeset");

    if (@this_changeset){
	print STDERR "\n--- ", $this_activity->name," Changeset ---\n";
	for $version (@this_changeset){print STDERR "\t",$version->name," ---\n"}
    }


    print  "\nComponents and some baselines in Activity ",name_title($this_activity," - "), "Project ",$this_activity->stream->project->name,"\n";

    for $component ($this_activity->stream->components){
	print STDERR  "\n--- Component: ",$component->name," ---\n";
	@baselines=$component->baselines; 
	my $i = 0;
	for(@baselines){	 
		print STDERR "\t",$_->name,"\n"

	}
    };

    ok(0,$this_activity->{status},"Components and some baselines in Activity");

    print  "==================================================\n";
    print  "=================UCM Arch Tested ", $iter + 1,"  ==============\n";
    print  "==================================================\n\n";

sub get_rand{
	my @aa = @_;
	@aa=A..Z unless @aa; 
	my $char = $aa[int( rand $#aa + 1)];
	return $char;
    }
   
sub do_folders{
    my $recurse_char=shift;
    my @folders=@_;

    for (@folders){
	print  $recurse_char;
	my @sub_folders=$_->folders;
	print  name_title($_,"Folder");
	

	if ($#sub_folders >= 0){
			   do_folders($recurse_char."\t",@sub_folders);
		       }
	my @projs=$_->projects;
	if (@projs){
	    for $proj (@projs){
		my $p_c=$recurse_char."\t";
		print  name_title($proj,"Project",$p_c);
		my $istream=$proj->integration_stream;

		if ($istream){
		    print  name_title($istream,"Integration Stream",$p_c);
		    my @activities=$istream->activities;
		    if ($#activities >=0){
		    }else{

		    }
		}else{
		    print  $p_c,"No Integration Stream\n";
		}
		my @dstreams = $proj->development_streams;
		if (@dstreams){
		    for $development_stream (@dstreams){

# Defect 43060 relates to the following line

			next if $development_stream->project->integration_stream->name eq $development_stream->name;
			print  $p_c,"Development Streams:\n";
			print  name_title($development_stream,"Development Stream",$p_c);
			my @views=$development_stream->views;
			for (@views){
			    print  $p_c,"View: ",$_->tag,"\n";
			}
			my @activities=$development_stream->activities;
			if($#activities <0){
			    print  $p_c,"There are ",$#activities + 1," activities \n";
			    my $c = get_rand(Fl,Br,Sp,Ch);
			    my $cc = get_rand('Nerdu','Blobu','Flatu','Dweebu'); print  "c is $c cc is $cc\n";
			    my $act=$development_stream->create_activity('stream',$development_stream,'name',$c."atman",'title',$cc."lonium");
			    $this_activity = $act;
			    print  name_title($act,"Activity Just Created",$p_c);
			}else{
			    for (@activities){
				print  name_title($_,"Activity",$p_c);
			    }
			    #xchen: always use the first one
			    #$this_activity=$activities[rand($#activities)];
			    $this_activity=$activities[0];
			    
			}
		    }

		}else{
		    print  $p_c,"No Development Streams\n";
		}
	    }
	}else{

	}
	
    }


}


sub name_title{
    my $obj=shift;
    my $id=shift;
   # my $indent=shift;
    my $string = $obj->name."\t";
    $string = $string.$id."\t" if $id;
   #  $string = $indent.$string.$obj->title."\n";
    $string = $string."\n";
    return $string;
}


sub newstring{
    my $this = shift;
    my $min = shift || 2 ;
    my $max = shift || 9;
    my @aa = A..Z;
    my @bb;
    srand;
    for(1..($min + int(rand($max)))){push @bb, $aa[int( rand $#aa + 1)]};
    return join "",@bb;
}

} #end of tstArch

sub os_test{

    eval "use Config";
    if(!defined($Config{osname}) || $Config{osname} =~ /Win/){
	return "Window";
    }
    else{
	return "Unix";
    }
}

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
        print  "--- Mapped the view to $dName  ---\n";
    }else {
	print STDERR "\nERROR: on mapping the view";
    }
}


