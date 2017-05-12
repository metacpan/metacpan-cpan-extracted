package CGI::AppBuilder::MapSecus;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI ':standard';
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);
use CGI::AppBuilder::HTML qw(:all);

our $VERSION=0.13; 
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(access_ok2 get_guid set_guid sel_guid set_ids
                   );
our %EXPORT_TAGS = (
    access => [qw(access_ok)],
    all  => [@EXPORT_OK]
);

=head1 NAME

CGI::AppBuilder::Security - Security Procedures

=head1 SYNOPSIS

  use CGI::AppBuilder::Security;

  my $sec = CGI::AppBuilder::Security->new();
  my ($sta, $msg) = $sec->access_ok($ar); 

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

=head2 access_ok2($q,$ar)

Input variables:

  $q   - CGI object
  $ar  - array ref containing the following variables:
  task		: task name required ($t)
  sel_sn1	: select one (DB/server name)
  sel_sn2	: select two (Argument)
  allowed_ip	: allowed ip address for each task
  roles		: roles allowed to access a list of tasks
  svr_allowed	: server allowed for each task
  arg_required	: required argument for each task

Variables used or routines called:

  None

How to use:
  
  See access_ok

Return: ($status, $msg) where $status is 1 (ok) or 0 (not), and the msg
is the error message. 

=cut

sub access_ok2 {
  my ($s, $q, $ar) = @_;

  # $s->disp_param($ar); 
  my ($ok ,$msg) = (1,"");
    
  # 0. get input parameters
  my $vs = 'REMOTE_ADDR,LOGNAME';
  my ($ip,$user_log) = $s->get_params($vs, \%ENV);
  $vs = 'task,sel_sn1,sel_sn2,new_task,app_user';
  my ($tsk,$sn,$s2,$ntsk,$usr_app)=$s->get_params($vs,$ar);
  $vs = 'web_url,pid,guid'; 
  my ($url,$pid,$guid) = $s->get_params($vs, $ar); 
      $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
  my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n";     
  my $u1b = "$url&task=disp_new&new_task=run_login"; 
  my $s1b = sprintf $f_a2, $u1b, "R", "Login User", "Login ->";    
  $vs = 'user_sid,user_uid,user_tmo,users_pwd'; 
  my ($usr_sid,$usr_uid,$usr_tmo,$usr_pwd) = $s->get_params($vs, $ar); 

  return (1,'OK') if (($ntsk && $ntsk =~ /(login|logout)$/i) 
    || $tsk =~ /(login|logout)$/i
    || $tsk =~ /^disp_(client|project|study|list|job|link|frd)/i
    || $tsk =~ /^(sel_stat)/i
    || (exists $ar->{logout} && $ar->{logout}) );
  my $ctm = strftime "%Y%m%d.%H%M%S", localtime; 
  
  # we return OK if the tmo has more than 10 minutes remaining
  return (1, 'OK') if ($usr_tmo && ($usr_tmo>$ctm) 
    && (($usr_tmo-$ctm) > 0.0010));

  # 1. check session id
  my ($id_OK, $usr_gid) = $s->set_guid($ar); 
  $usr_gid = ($usr_gid) ? $usr_gid : '' ;
  if (! $id_OK) {
    print $q->header("text/html");
    print $q->start_html(%{$ar->{html_header}});
    print "$usr_gid<br>\n"; 
    print "Please $s1b<br>\n";
    print $q->end_html; 
    exit;
  }
  if (!$usr_gid) {
    # $msg = "No user credential.<br>"; 
    print $q->header("text/html");
    print $q->start_html(%{$ar->{html_header}});
    print "Please $s1b<br>\n";
    print $q->end_html; 
    exit;
  } else { 
    my @ss = split /:/, $usr_gid;
    $usr_sid = $ss[0] if !$usr_sid;
    $usr_uid = $ss[1] if !$usr_uid;
    $usr_tmo = $ss[2] if !$usr_tmo;
  }
  $ar->{app_user} = $usr_uid if !$usr_app && $usr_uid; 
  $ar->{guid}     = $usr_gid if !$guid    && $usr_gid; 

  # 2. check timeout

  $msg = "OK: "; 
  $msg .= "got user $usr_uid " 	if $usr_uid;
  $msg .= "and its password " 	if $usr_pwd;
  $msg .= "and GID = $usr_gid " if $usr_gid;
  $msg .= "for task $tsk";
  $msg .= ($ntsk) ? "->$ntsk.<br>\n" : ".<br>\n"; 
  if ($usr_tmo && $usr_tmo > $ctm) { 
    $msg .= "This session will be expired at $usr_tmo.<br>"; 
  } else {
    $msg .= "This session has expired at <b>$usr_tmo</b>.<br>" if $usr_tmo; 
  }
  return (1,$msg) if ( ($tsk =~ /(login)$/i && $usr_uid && $usr_pwd) 
    || ($usr_tmo && $usr_tmo > $ctm) || $tsk =~ /(setanypwd)$/i); 

  # 3. check if we need to start the login page
  $u1b .= "&guid=$usr_gid"; 
  
  if (!$usr_gid || $usr_tmo && $usr_tmo < $ctm ) {
    print $q->header("text/html");
    print $q->start_html(%{$ar->{html_header}});
    print "$msg\nPlease $s1b<br>\n";
    print $q->end_html; 
    exit; 
  }    

  # 4. check required inputs
  return (0, "ERR: missing task name.") 	if !$tsk;
  return (0, "ERR: missing server/DB name.") 	if !$sn;
    
  # 5. check if the task is allowed for the specified server
  my $pn = 'svr_allowed';
  if (exists $ar->{$pn}) { 
    my $sa = eval $s->set_param($pn, $ar); 
    $ok = (!$sa || ! exists $sa->{$tsk}) ? 1 : (
       (exists $sa->{$tsk}{$sn}) ?  $sa->{$tsk}{$sn} : 0);  
    return ($ok, "ERR: Action $tsk is not allowed in DB $sn") if !$ok;
  }
    
  # 6. check arguments
  $pn = 'arg_required';
  if (exists $ar->{$pn}) { 
    my $amr = eval $s->set_param($pn, $ar);		# ARG is required
    my @a = ();
       @a = split /:/, $amr->{$tsk} if exists $amr->{$tsk} && $amr->{$tsk}; 
    my $arg = {};
    if ($s2) { 
        my @b = split /:/, $s2;
        for my $i (0..$#b) { 
          $arg->{"a$i"} = $b[$i]; 
          $ar->{$a[$i]} = $b[$i] if $a[$i];  
        }
    }
    $ok = (exists $amr->{$tsk} && (!$arg || ! exists $arg->{a0})) ? 0 : 1;
    return ($ok, "ERR: Task ($tsk) requires ARGS ($amr->{$tsk})") if !$ok;
  }

  return ($ok,$msg);
}


sub set_guid {
  my ($s, $ar) = @_;

  my $prg = 'AppBuilder::Common->set_guid'; 
  # 1. get current parameters
  my $vs  = 'user_uid,user_pwd,user_sid,user_tmo,guid,upd_tm_itv';
  my ($usr_uid,$usr_pwd,$usr_sid,$usr_tmo,$guid,$uti) = $s->get_params($vs,$ar);
  my @sid = ($guid) ? (split /:/, $guid) : ();
  if (@sid) { 
    $usr_sid = (!$usr_sid) ? $sid[0] : $usr_sid;
    $usr_uid = (!$usr_uid) ? $sid[1] : $usr_uid;
    $usr_tmo = (!$usr_tmo) ? $sid[2] : $usr_tmo; 
  } 
  if ($usr_sid !~ /^\d+$/) {
    my $msg  = "No user session ID (USER_SID).";
    print $s->disp_header(undef, $ar); 
    $s->echo_msg($msg, 0); return ""; 
  }
  # 2. get parameters from DB
  my $t = $s->sel_guid($ar); 
  my @ss = ($t) ? (split /:/, $t) : ();
     $usr_sid = $ss[0] if !$usr_sid;
     $usr_uid = $ss[1] if !$usr_uid;
     $usr_tmo = $ss[2] if exists $ss[2] && $ss[2]; 

  # 3. check timeout
  my $ctm = strftime "%Y%m%d.%H%M%S", localtime; 
  my $msg = "OK: "; 
     $msg .= "got user $usr_uid " 	if $usr_uid;
     $msg .= "and its password " 	if $usr_pwd;
  if ($usr_tmo && $usr_tmo < $ctm) { 
     $msg .= "This session has expired at <b>$usr_tmo</b>.<br>" if $usr_tmo; 
     return (0,$msg);
  }
  # 4. it has not expired so we need to extend the tmo
  # we only reset it if it is less than 60 seconds (0.0007 day) to expire
  # 0.0035 day = 300 seconds (5 minutes)
  $uti = 0.0005 if ! $uti; 
  if ($usr_tmo && $ctm && $uti && ($usr_tmo-$ctm) < $uti) { 	
    # get SESSION_TIMEOUT
    my $cns = 'cfgvar_value'; 
    my $whr = " WHERE upper(CFGVAR_NAME) = 'SESSION_TIMEOUT' "; 
    my $r = $s->run_sqlcmd($ar, $cns, 'sp_cfgvars', $whr); 
    my $cfg_tmo = $r->[0]{cfgvar_value};   
    my $cfg_tm2 = $cfg_tmo/(24*3600); 

    my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
      $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
      $sql .= "Update sp_sessions SET timeout_time = timeout_time + $cfg_tm2 ";
      $sql .= "Where ses_id = $usr_sid;\n";
      $sql .= "commit;\n";
    my $rst  = $s->open_cmd($sql,$ar);
  } 

  #. 5. get the DB parameters again 
  if ($usr_tmo && $ctm && $uti && ($usr_tmo-$ctm) < $uti) { 	
    $t = $s->sel_guid($ar); 
    @ss = ($t) ? (split /:/, $t) : ();
    $usr_sid = $ss[0] if !$usr_sid;
    $usr_uid = $ss[1] if !$usr_uid;
    $usr_tmo = $ss[2] if exists $ss[2] && $ss[2]; 
  }   
  $usr_uid = ($usr_uid) ? $usr_uid : '';
  $usr_sid = ($usr_sid) ? $usr_sid : '';
  $usr_tmo = ($usr_tmo) ? $usr_tmo : '';
  $ar->{user_uid} = $usr_uid;
  $ar->{user_sid} = $usr_sid;
  $ar->{user_tmo} = $usr_tmo;
  # $ar->{user_pwd} = $usr_pwd; 
  return (1,"$usr_sid:$usr_uid:$usr_tmo");    
}

sub get_guid {
  my ($s, $ar) = @_;

  my $vs  = 'user_uid,user_pwd,user_sid,user_tmo';
  my ($usr_uid,$usr_pwd,$usr_sid,$usr_tmo) = $s->get_params($vs,$ar);

  return "$usr_sid:$usr_uid:$usr_tmo";    
}

sub sel_guid {
  my ($s, $ar) = @_;

  my $prg = 'AppBuilder::Common->sel_guid'; 
  # 1. check inputs
  my $vs  = 'user_uid,user_pwd,user_sid,user_tmo';
  my ($msg) = ("");
  my ($usr_uid,$usr_pwd,$usr_sid,$usr_tmo) = $s->get_params($vs,$ar);
  if ($usr_sid !~ /^\d+$/ && !$usr_uid) {
#    $msg  = "ERR: No USER_UID and USER_SID ($usr_uid,$usr_sid).";
#    $s->echo_msg($msg, 0); 
    return ""; 
  } 
  # 2. get info from sp_sessions
  my $cns = 'ses_id,user_id,start_time,end_time,timeout_time,os_user';
  my $whr = " WHERE "; 
  my $r = []; 
  if ($usr_sid =~ /^\d+$/) {
    $whr .= " ses_id = $usr_sid ";
  } else {
    $whr .= "upper(user_id) = '" . uc($usr_uid) . "' ";
    $whr .= " ORDER BY start_time DESC ";
  }
  $r = $s->run_sqlcmd($ar, $cns, 'sp_sessions', $whr); 
  if (@$r) {
    $usr_sid = $r->[0]{ses_id};
    $usr_uid = $r->[0]{user_id};
    $usr_tmo = $r->[0]{timeout_time}
  } else {
    $msg  = "ERR: ($prg) no record for ses_id or user_id ";
    $msg .= "($usr_sid,$usr_uid)";
    $s->echo_msg($msg,0);
    return ""; 
  }
  if (exists $ar->{user_uid} && "$ar->{user_uid}" ne "$usr_uid") {
    $msg .= "$ar->{user_uid} NE $usr_uid. Set USER_ID to $usr_uid.";
    $s->echo_msg($msg,1);
  }
  $ar->{user_uid} = $usr_uid;
  $ar->{user_sid} = $usr_sid;
  $ar->{user_tmo} = $usr_tmo;
  # get info from sp_users
  $cns = 'user_id,usr_pwd'; 
  $whr = " WHERE upper(user_id) = '" . uc($usr_uid) . "' "; 
  $r = $s->run_sqlcmd($ar, $cns, 'sp_users', $whr); 
  $usr_pwd = $r->[0]{usr_pwd}; 
  # $ar->{user_pwd} = $usr_pwd;   

  return "$usr_sid:$usr_uid:$usr_tmo";  
}


sub set_ids {
  my ($s, $ar) = @_;

  my $prg = 'AppBuilder::Common->set_ids'; 
  # 1. check inputs
  my $vs  = 'cln_id,prj_id,study_id,list_id,job_id';
  my ($cid,$pid,$sid,$lid,$jid) = $s->get_params($vs,$ar);
  
  # 2. build sql statement
  my $cns = "sp_findids_fn("; 
    $cns .= ($jid =~ /^\d+$/) ? $jid : 'null'; 
    $cns .= ($lid =~ /^\d+$/) ? $lid : ',null';
    $cns .= ($sid =~ /^\d+$/) ? $sid : ',null';
    $cns .= ($pid =~ /^\d+$/) ? $pid : ',null';
    $cns .= ') as record '; 
  my $sql = "ALTER session SET nls_date_format='YYYYMMDD.HH24MISS';\n";
    $sql .= "SET linesize 999 serveroutput ON SIZE 1000000 FORMAT WRAPPED;\n";
    $sql .= "SELECT '==,'||$cns FROM dual;\n";
  my $rst  = $s->open_cmd($sql,$ar); 
  my $vr = ['cln_id','prj_id','study_id','list_id','job_id','stg_schema']; 
  # $ar->{var_arf} = $vr;
  my $rr  = $s->parse_records($rst, $vr, '==', ','); 
  
  # 3. set ids
  my $r = {}; 
  foreach my $k (split /,/, $vs) {
    $r->{$k}  = $rr->[0]{$k}; 
    $ar->{$k} = $rr->[0]{$k} if !exists $ar->{$k} || $ar->{$k} !~ /^\d+$/; 
  }
  my $usr_gid = (exists $ar->{guid}) ? $ar->{guid} : "";
  my $aa = ($usr_gid) ? [split /:/, $usr_gid] : []; 
  $ar->{user_sid} = $aa->[0] 	if !exists $ar->{user_sid} && exists $aa->[0]; 
  $ar->{user_uid} = $aa->[1] 	if !exists $ar->{user_uid} && exists $aa->[1]; 
  $ar->{user_tmo} = $aa->[2] 	if !exists $ar->{user_tmo} && exists $aa->[2]; 
  
  wantarray ? %$r : $r; 
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version extracted from jp2.pl on 09/08/2010.

=item * Version 0.20

  02/08/2012 (htu): added access_ok2
  02/10/2012 (htu): added get_guid, set_guid and sel_guid
  02/14/2012 (htu): added set_ids

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::AppBuilder, File::Xcopy,
CGI::AppBuilder::Message

=head1 AUTHOR

Copyright (c) 2012 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
