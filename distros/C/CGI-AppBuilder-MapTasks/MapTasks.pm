package CGI::AppBuilder::MapTasks;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use File::Path; 
use Net::Rexec 'rexec';

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_task_form task_url task_usr_input 
                   );
our %EXPORT_TAGS = (
    tasks => [qw(task_url task_usr_input)],
    all   => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::PLSQL - Oracle PL/SQL Procedures

=head1 SYNOPSIS

  use CGI::AppBuilder::MapTasks;

  my $sec = CGI::AppBuilder::PLSQL->new();
  my ($sta, $msg) = $sec->exe_sql($ar); 

=head1 DESCRIPTION

This class provides methods for reading and parsing configuration
files. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

sub task_url {
  my ($s, $ar, $pr, $typ) = @_;
  
  $typ = $ar->{id_type} if !$typ && exists $ar->{id_type} && $ar->{id_type};
  $typ = 'studyid'	if !$typ; 
  my ($study_id,$study_name,$job_id,$job_name,$hjob_id,$list_id,$spec_id) = ();
  $study_id = $ar->{study_id}	if exists $ar->{study_id} && $ar->{study_id};
  $study_id = $ar->{sel_sn2}	if !$study_id 
    && exists $ar->{sel_sn2} && $ar->{sel_sn2} && $typ =~ /^studyid/;
  $job_id   = $ar->{job_id} if exists $ar->{job_id} && $ar->{job_id};
  $hjob_id  = $ar->{hjob_id} if exists $ar->{hjob_id} && $ar->{hjob_id};
  $list_id  = $ar->{list_id} if exists $ar->{list_id} && $ar->{list_id};
  $spec_id  = $ar->{spec_id} if exists $ar->{spec_id} && $ar->{spec_id};
  my $pid = $pr->{pid};				# project id
  my $sn  = $pr->{sid}; 			# server id
  my $url = $pr->{web_url};			# web URL
     $url =~ s/(\?.*)//; 			# remove parameters
  my $u1  = "pid=$pid&no_dispform=1"; 
     $u1 .= "&sel_sn1=$pr->{sid}"	if exists $pr->{sid} && $pr->{sid};
     $u1 .= "&study_id=$study_id"	if $study_id;
     $u1 .= "&job_id=$job_id" 		if $job_id;
     $u1 .= "&hjob_id=$hjob_id" 	if $hjob_id;
     $u1 .= "&list_id=$list_id" 	if $list_id;
     $u1 .= "&spec_id=$spec_id" 	if $spec_id;     
     $u1 .= "&study_name=$ar->{study_name}"	
          if exists $ar->{study_name} && $ar->{study_name};
     $u1 .= "&job_name=$ar->{job_name}" 
          if exists $ar->{job_name} && $ar->{job_name};
  if ($typ && $typ =~ /(cptable|cfgstudy|recfgsch|cfgschema|studyid)/) {
     $u1 .= "&sel_sn2=$study_id" 	if $study_id; 
  } elsif ($typ && $typ =~ /(schjob|jobid)/i) {
     $u1 .= "&sel_sn2=$job_id"		if $job_id; 
  } elsif ($typ && $typ =~ /(htmlrpt|xmlrpt|hjobid)/i) {
     $u1 .= "&sel_sn2=$hjob_id"		if $hjob_id; 
  }
  return "$url?$u1";
}


sub task_usr_input {
  my ($s, $ar, $pr, $typ) = @_;

  $typ = $ar->{id_type} if !$typ && exists $ar->{id_type} && $ar->{id_type};
  $typ = 'studyid'	if !$typ; 
  my ($pid,$study_id,$study_name,$job_id,$job_name,$hjob_id) = ();
  my ($cln_id, $cln_nm, $prj_id, $prj_nm) = ();
  $pid 	    = $ar->{pid}	if exists $ar->{pid}	   && $ar->{pid};
  $cln_id   = $ar->{cln_id} 	if exists $ar->{cln_id}    && $ar->{cln_id};
  $prj_id   = $ar->{prj_id} 	if exists $ar->{prj_id}    && $ar->{prj_id};
  $study_id = $ar->{study_id}	if exists $ar->{study_id}  && $ar->{study_id};
  $job_id   = $ar->{job_id}  	if exists $ar->{job_id}    && $ar->{job_id};
  $hjob_id  = $ar->{hjob_id} 	if exists $ar->{hjob_id}   && $ar->{hjob_id};
  if (!$pid) {
    $s->echo_msg("ERR: pid is not defined.", 0); return; 
  }

  my $fmt = "<input type=\"hidden\" name=\"%s\" value=\"%s\" />\n";
  my $t = sprintf $fmt, "pid", $pid; 
  $t .= sprintf $fmt, "sel_sn1",  $pr->{sid}	if exists $pr->{sid}; 
  $t .= sprintf $fmt, "task",     "disp_usr_task";
  $t .= sprintf $fmt, "id_type",  $typ		if $typ;
  $t .= sprintf $fmt, "cln_id",   $cln_id 	if $cln_id;
  $t .= sprintf $fmt, "prj_id",   $prj_id 	if $prj_id;
  $t .= sprintf $fmt, "study_id", $study_id 	if $study_id;
  $t .= sprintf $fmt, "job_id",   $job_id 	if $job_id;
  $t .= sprintf $fmt, "hjob_id",  $hjob_id 	if $hjob_id;
  $t .= sprintf $fmt, "study_name", $ar->{study_name}
        if exists $ar->{study_name} && $ar->{study_name};
  $t .= sprintf $fmt, "job_name", $ar->{job_name}
        if exists $ar->{job_name} && $ar->{job_name};
  $t .= uc($typ) . ": <input name=\"sel_sn2\" value=\"\" size=5 />\n" ; 
  $t .= "<input name=\"a\" value=\"Set\" type=\"submit\" />"; 
  return $t;
}


=head2 disp_task_form($q,$ar,$txt)

Input variables:

  $q	- CGI class
  $ar	- array ref containing the following variables:
  	pid		: project id such as ckpt, owb, dba, etc.
  	task		: task name required such as task1,task2,etc.
  	target(sel_sn1)	: select one (DB/server name) defining sid
  	args(sel_sn2)	: select two (Arguments)
  	task_fn		: task file name containing all the tasks defined
  	svr_conn	: host/server connection info
  	db_conn		: db connection info for each target/server
  	task_conn	: special connection for tasks. 
  	                  It overwrites db_conn for the task
  
Variables used or routines called:

  None

How to use:


Return: $pr will contain the parameters adn output from running the PL/SQL.


=cut

sub disp_task_form {
  my ($s, $q, $ar, $txt, $ret) = @_;
  
  my $fmn = 'fm1';
     $fmn = $ar->{form_name}
       if exists $ar->{form_name} && $ar->{form_name};
  my %fr = (-name => $fmn, -method=>uc $ar->{method},
      -action=>"$ar->{action}?", -enctype=>$ar->{encoding} );
  if (exists $ar->{hr_form} && $ar->{hr_form}) {
    my $fr_hr = (ref($ar->{hr_form}) =~ /^HASH/) ? 
                $ar->{hr_form} : eval $ar->{hr_form}; 
    foreach my $k (keys %{$fr_hr}) { $fr{$k} = $fr_hr->{$k}; }
  }
  my $t = ""; 
  $t .= $q->start_form(%fr);
  my $hvs = $s->set_param('vars_keep', $ar);
  if ($hvs) {
      foreach my $k (split /,/, $hvs) {
          my $v = $s->set_param($k, $ar);
          next if $v =~ /^\s*$/;
          $t .= $q->hidden($k,$v);
      }
  }
  $t .= "$txt\n";
  $t .= $q->end_form . "\n";
  print  $t if !$ret; 
  return $t if ($ret);
} 

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  09/08/2010 (htu): 
    1. start this PM

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::AppBuilder, File::Xcopy,
CGI::AppBuilder::Message

=head1 AUTHOR

Copyright (c) 2009 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

