package CGI::AppBuilder::Security;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use CGI ':standard';
use CGI::Cookie;
use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:echo_msg);

our $VERSION = 0.12;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(access_ok get_cookies set_cookies
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

=head2 access_ok($ar)

Input variables:

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

First define the parameters in the initial file or define all the parameters
in a hash array reference as $ar->{$p} where $p are

  task     = task_name
  sel_sn1  = a_db_name_or_server_name
  app_user = logname_or_logid
  usr_role = {
    usr1 = [qw(dba owb)],
    usr2 = [qw(r1 r2)],
   }
  usr_task = {
    usr1 = [qw(task1 task2)],
    usr2 = [qw(task3 task4)],
    }
  rol_task = {
    dba => [qw(task1 task3 task5)],
    owb => [qw(task2 task4)],
    }
  allowed_ip = {
    all   => [10.0.0.127,10.0.0.185,10.0.1.125)],
    task1 => [192.168.1.1,192.168.1.2],
    task2 => [10.0.0.5],
    }
  arg_required = {
    task1 => 'input1:input2',
    task2 => 'p_dnm:p_prj:p_tab:p_own',
    }    
  svr_allowed = {
    task1 => {svr1=>1},
    task2 => {svr1=>1,svr2=>1,svr3=>1},
    }  
  # $time = timelocal($sec,$min,$hour,$mday,$mon,$year);
  #   $sec : 0~59
  #   $min : 0~59
  #   $hour: 0~23
  #   $mday: 1~31
  #   $mon : 0~11
  #   $year: yyyy-1900
  #   ex   : [0,0,0,16,8,109] = 2009/09/16 00:00:00
  task_expired = {
    task1 => [0,0,0,25,0,109],   # 2009/01/25
    task1 => [0,0,0,17,8,119],   # 2019/09/17
    }

  my ($q, $ar, $ar_log) = $self->start_app($0, \@ARGV);
  or
  my $ar = $self->read_init_file('/tmp/my_init.cfg');
  my ($status, $err_msg) = $self->access_ok($ar);
  if ($status > 0) {
    print "OK\n";
  } else {
    print "Failed: $err_msg\n";
  }

  my ($ok, $msg) = $self->access_ok($task, $ar); 
  if ($ok) { 
      $self->exe_sql($q, $ar);
  } else {
      print $self->disp_form($q, $ar);
      print "<font color=red>$msg</font>\n" if $ar->{write_log}; 
      $self->echo_msg($msg,0);
  }

Return: ($status, $msg) where $status is 1 (ok) or 0 (not), and the msg
is the error message. 

=cut

sub access_ok {
    my ($s, $ar) = @_;

    # $s->disp_param($ar); 
    
    # 0. get parameters
    my $vs = 'REMOTE_ADDR';
    my ($ip) = $s->get_params($vs, \%ENV);
    $vs = 'task,sel_sn1,sel_sn2,app_user';
    my ($tsk,$sn,$s2,$usr) = $s->get_params($vs, $ar);
    $usr = $ENV->{LOGNAME} if !$usr; 
    my ($pn, $ok, $msg) = ('',1,'');
   
    # 1. check required inputs
    return (0, "ERR: missing task name.") 	if !$tsk;
    return (0, "ERR: missing server/DB name.") 	if !$sn;
    
    # 2. check if the task is allowed for the specified server
    $pn = 'svr_allowed';
    if (exists $ar->{$pn}) { 
      my $sa = eval $s->set_param($pn, $ar); 
      $ok = (!$sa || ! exists $sa->{$tsk}) ? 1 : (
         (exists $sa->{$tsk}{$sn}) ?  $sa->{$tsk}{$sn} : 0);  
      return ($ok, "ERR: Action $tsk is not allowed in DB $sn") if !$ok;
    }
    
    # 3. check arguments
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

    # 4. task expiration
    $pn = 'task_expired';
    if (exists $ar->{$pn}) { 
      my $texp = eval $s->set_param($pn, $ar); 		# task expiration date
      # $s->echo_msg($texp,0); 
      if (exists $texp->{$tsk})  {
        my $exp_tm = timelocal (@{$texp->{$tsk}}); 
        my $exp_dt = strftime "%Y/%m/%d %H:%M:%S", (@{$texp->{$tsk}});
        $ok = (exists $texp->{$tsk} && (time > $exp_tm)) ? 0 : 1;
        return ($ok, "ERR: Task ($tsk) expired on $exp_dt") if !$ok;
      }      
    }
    
    # 5. check if it is allowed to run from the IP address
    $pn = 'allowed_ip';
    if (exists $ar->{$pn}) { 
      my $aip = eval $s->set_param($pn, $ar);
      my ($ok1, $ok2); 
      if (exists $aip->{all}) {
        my $alp = {};
        for my $i (0..$#{$aip->{all}}) { 
          my $k = $aip->{all}[$i]; 
          $k =~ s/(^\s*|\s*$)//; $alp->{$k} = 1; 
        }
        $ok1 = (exists $alp->{$ip}) ? 1 : 0;   
        $s->echo_msg("INFO: 1 - $aip->{all},$ip,$ok1",2);
        # $s->echo_msg($alp,0);
      } 
      if (exists $aip->{$tsk}) {  # ip addrs are provided for indivisual task
        my $ap = {};
        for my $i (0..$#{$aip->{$tsk}}) { 
          my $k = $aip->{$tsk}[$i]; 
          $k =~ s/(^\s*|\s*$)//; $ap->{$k} = 1; 
        }
        # print "$ip,$ap->{$ip}<br>\n"; 
        $ok2 = (exists $ap->{$ip}) ? 1 : 0;
        $s->echo_msg("INFO: 2 - $aip->{$tsk},$ip,$ok2",2);
        # $s->echo_msg($ap,0);
      }
      $ok = $ok1 + $ok2;
      if (!$ok) {
        my $msg = "ERR: You are not allowed to run $tsk from IP address $ip"; 
        # $s->echo_msg($msg,0);
        # $s->echo_msg($aip,0);
        return ($ok, $msg);
      }
    }

    # 6. check if the task is a DBA task
    # we do not check this if no application user is specified.
    return (1,'') if !$usr; 
    if (!exists $ar->{rol_task} && !exists $ar->{usr_task}) { 
      return (1,'WARN: rol_task and usr_task is not defined'); 
    }
    return (1,'WARN: usr_role is not defined') if !exists $ar->{usr_role} && 
      exists $ar->{rol_task}; 
    return (1,'WARN: rol_task is not defined') if exists $ar->{usr_role} && 
      !exists $ar->{rol_task}; 
    my $usr_role = eval $s->set_param('usr_role', $ar);
    my $usr_task = eval $s->set_param('usr_task', $ar);
    my $rol_task = eval $s->set_param('usr_task', $ar);

    # build user and task list
    my $utk = {};   # hash array for user and task list
    if (exists $ar->{usr_task}) {
      foreach my $u (keys %{$usr_task}) {
        map { my $t = $usr_task->{$u}[$_]; $utk->{$t} = 1; } 
          0..$#{$usr_task->{$u}};
      }
    }
    if (exists $ar->{usr_role}) {
      foreach my $u (keys %{$usr_role}) {		# user
        for my $i (0..$#{$usr_role->{$u}}) {		# role
          my $r = $usr_role->{$u}[$i]; 
          next if ! exists $rol_task->{$r}; 
          map { my $t = $rol_task->{$u}[$_]; $utk->{$t} = 1; } 
            0..$#{$rol_task->{$u}};
        }
      }
    }
    $ok = ( (exists $usr_role->{$usr} || exists $usr_task->{$usr}) &&
            (!exists $utk->{$tsk} || !$utk->{$tsk} ) ) ? 0 : 1;
    return ($ok, "ERR: User $usr is not allowed to run Task $tsk!") if !$ok;

    return ($ok,$msg);
}

# ---------------------------------------------------------------------------------

=head3 get_cookies ($cgi,$ar)

Input variables:

  $cgi - CGI object
  $ar  - Array ref containing all the parameters

Variables used or routines called: 

  disp_param - display parameters

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->get_cookies($q, \%cfg);

Return: ($ck_ar, $ck1, $ck2, $ck3) - hash array reference for cookies 
(${$ck_ar}{$ck}{$ck}) and cookie names.

This method retrieves and parses cookies set by previous process and 
returns them in a hash array reference.

=cut

sub get_cookies {
    my $s = shift;
    my ($q, $ar) = @_;
    
    # retrieve cookies
    # my %cookies = fetch CGI::Cookie;
    my %cookies = CGI::Cookie->fetch;
$s->disp_param(\%cookies);     
    
    my %cks = ();  # parsed cookies
    foreach my $k (sort keys %cookies) {
        foreach my $rec (split /;/, $cookies{$k}) {
            my ($k1, $v1) = split /=/, $rec;
            $cks{$k}{$k1} = $v1;
        }
    }
    $s->disp_param(\%cks) if exists $ar->{v} && $ar->{v};
    wantarray ? %cks : \%cks;       
}


=head3 set_cookies ($cgi,$ar, $cr, $dr)

Input variables:

  $cgi - CGI object
  $ar  - Array ref containing all the parameters
  $cr  - cookie array ref
  $dr  - access array ref

Variables used or routines called: 

  get_cookies - get cookie hash array ref
  get_access  - get access hash array ref

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->get_cookies($q, \%cfg);

Return: 1 or 0 to indicates whether setting cookies is sucessfull.

This method retrieves and parses cookies set by previous process and 
returns them in a hash array reference.

=cut

sub set_cookies {
    my $s = shift;
    my ($q, $ar, $cr, $dr) = @_;
    
    # $cr = $s->get_cookies($q, $ar) if ! $cr;
    # $dr = $s->get_access($q, $ar)  if ! $dr;
    $cr = $s->get_cookies($q, $ar);
    # $s->echo_msg($cr, 0);
    
    my $dn = $ENV{HTTP_HOST};
    my $vs = 'UID,PWD,SID';
    my $kv = {}; 
    my $ck  = [];
    foreach my $k (split ',',$vs) {
      my $k1 = "ck$k";
      my $k2 = "user_" . lc($k);
      my $v  = (exists $ar->{$k2}) ? $ar->{$k2} : '';
      if ($k =~ /^timeout/i && $v) {
        # convert YYYYMMDD.HH24MISS to perl time
        # $time = timelocal($sec,$min,$hour,$mday,$mon,$year);
        my $yr = substr($v,1,4) - 1900;
        my $mn = substr($v,5,2);
        my $dd = substr($v,7,2);
        my $hh = substr($v,10,2);
        my $mm = substr($v,12,2);
        my $ss = substr($v,14,2);
        $v = timelocal($ss,$mm,$hh,$dd,$mn,$yr); 
      } 
      $v  = $cr->{$k1} 	if !$v && exists $cr->{$k1}; 
      $kv->{$k1} = $v;          
      push @$ck, $q->cookie(-name=>$k1,-value=>$v,-domain=>$dn, 
        -expires=>'+3M');
    }
    $ar->{_cookie} = $ck;
    # print header(-cookie=>$ck); 
    # for my $i (0..$#$ck) { my $c = $ck->[$i]; print "Set-Cookie: $c\n";  } 
    # print "Content-Type: text/html\n\n"; 

    # $s->echo_msg($kv, 3); 
    # $s->echo_msg($ck, 0);
    # my $c2 = $s->get_cookies($q, $ar); 
    # $s->echo_msg($c2, 0);
    return 0 if !$kv->{ckUID} || !$kv->{ckPWD};
    return 1;       
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version ported from ora_jobs.pl on 9/17/2009.

=item * Version 0.20

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

