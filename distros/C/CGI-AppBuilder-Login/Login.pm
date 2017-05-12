package CGI::AppBuilder::Login;

use strict;
use vars qw(@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Carp;
use CGI;

$VERSION = 0.01;
@ISA = qw(Exporter);
@EXPORT = qw(login logout check_user  get_access 
          check_timeout	get_version);
@EXPORT_OK = qw(login logout check_user get_access 
             check_timeout get_version
             );
%EXPORT_TAGS = (
  all => [@EXPORT_OK],
  pages => [qw(login)],
);


=head3 login($cgi, $ar, $tmout)

Input variables:

  $cgi - CGI object
  $ar  - parameter array ref
  $tmout - whether the session has been timed out

Variables used or routines called: 

  to_remember - to remember inputs
  check_user  - to check user logins
  set_cookies - to set cookies

How to use:

  my $q = new CGI;
  $self->login($q, 'jsmith', 'jojo');     # login as jsmith
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  $self->login($q, \%cfg, 0);                # login as jsmith

Return: ($toc, $txt): the login screen HTML code

=cut

sub login {
    my $s = shift;
    my ($q, $ar, $tmout) = @_;
    $tmout = 0 if ! defined $tmout;
    $q = new CGI if !$q;
    
    my ($usr, $pwd, $vbm, $i,$m1,$m2,$m3) = ("","","","","","","");
    my ($toc, $txt,$tsg, $pid, $pin, $dob) = ("","","","","","");
    $m1  = $ar->{msg}{'001'}	if exists $ar->{msg}{'001'};
    $m1  = 'Login Page'     	if !$m1;
    $m2  = $ar->{msg}{'002'}	if exists $ar->{msg}{'002'};
    $m2  = 'User'           	if !$m2;
    $m3  = $ar->{msg}{'003'}	if exists $ar->{msg}{'003'};
    $m3  = 'Password'   	if !$m3;
    $vbm = $ar->{v} 		if exists $ar->{v};
    $tsg = $ar->{table_noborder} if exists $ar->{table_noborder};

    my $cu_status = 0;
    $cu_status = $s->check_user($q, $ar) if !$tmout; 
    $cu_status = 150                     if  $tmout;

    $toc .= $s->get_version($q, $ar, 'login');
    $toc .= "<h2 align=center>$m1</h2>\n";
    
    if ($cu_status>999) {   # login ok, move to next page
        $s->set_cookies($q, $ar); 
        return $s->info1($q, $ar);
    }
    $usr = $ar->{user_id} 	if exists $ar->{user_id};
    $pwd = $ar->{user_pwd}	if exists $ar->{user_pwd};
    my $err_msg = "";
    $err_msg = $ar->{msg}{$cu_status} if exists $ar->{msg}{$cu_status};
if ($usr && $pwd) { # XXX: 
   $txt = "<b>User ($usr) has successfully logged in</b>"; 
    print "$toc $txt"; 
    return ($toc, $txt, "");
}
    
    my $uid = 'user_id';

    $usr = ${$ar}{$uid} if exists ${$ar}{$uid};
    my $stm = time;            # session start time
    my $fmt = "<INPUT TYPE=hidden NAME=%s VALUE=%s>\n";
    my $td1 = "<td colspan=2>";
    $txt  = "";
    $txt .= "<center>\n<table>\n";
    $txt .= $q->start_form(${$ar}{method},${$ar}{action},${$ar}{encoding});
    $txt .= sprintf $fmt, 'a', 'l';
    $txt .= sprintf $fmt, 'stm', $stm; 
    $txt .= sprintf $fmt, 'v', 'y' if $vbm;
    $txt .= sprintf $fmt, "task", "login";

    $usr  =~ s/\%40/\@/g;
    $txt .= $s->to_remember($q, $ar, "$uid|pwd|stm|sid|task") 
            if exists ${$ar}{to_remember} && ${$ar}{to_remember};
    if ($ENV{SCRIPT_NAME} =~ /_prod/) {
        $txt .= "<tr><td colspan=3>${$ar}{msg}{'024'}</td></tr>";
    } else {
        $txt .= "<tr><td colspan=3>${$ar}{msg}{'023'}</td></tr>";
    }
    
    $txt .= "<tr>$td1<b>$ar->{msg}{'020'}</b><br><br></td>\n</tr>\n";
    $txt .= "<tr><td>$m2: \n<td>";
    $txt .= $q->textfield("$uid",$usr,50,80) . "\n";
    $txt .= "</tr>\n<tr><td>$m3: \n<td>";
    $txt .= $q->password_field('pwd','',50,80) . "\n";
    $txt .= "<tr><td colspan=2 align=center>";
    $txt .= $q->submit('submit', 'Go');
    $txt .= $q->end_form() . "</tr>\n";
    $txt .= "<tr>$td1<br><p class=err>$err_msg</p></td>\n</tr>\n";
    $txt .= "</table>\n</center>\n";
    print "$toc$txt"; 
    return ($toc, $txt, "");
}


sub logout {
    my $s = shift;
    my ($q, $ar, $tmout) = @_;
    
    print "<b>You have been logged out.</b>"; 

}


=head3 get_version ($cgi, $ar, $sub)

Input variables: 

  $cgi - CGI object
  $ar  - Array ref containing all the parameters
  $sub - sub procedure name.
         display user first name if it is 'login'

Variables used or routines called: 

  None.

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->get_version($q, \%cfg);

Return: $t - HTML code

This method forms HTML code to show demorgraphic information about the
subject.

=cut

sub get_version {
    my $s = shift;
    my ($q, $ar, $sub) = @_; 
    $sub = "" if ! $sub;
    
    my $toc = ""; 
    if ($sub =~ /login/) {
        $toc = "Welcome $ar->{usr_fn}!<br>" 
            if exists $ar->{usr_fn} && $ar->{usr_fn};
    }
    $toc .= "[version $ar->{app_version}]" if exists $ar->{app_version};
    if ($ENV{SCRIPT_NAME} =~ /_prod/) {
        $toc .= " - production<br>\n";
    } else {
        $toc .= " - training<br>\n";
    }
    return $toc;
}


=head3 check_timeout($cgi, $ar)

Input variables: 

  $cgi - CGI object
  $ar  - Array ref containing all the parameters

Variables used or routines called: 

  None.

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->check_timeout($q, \%cfg);

Return: 1 or 0: 1 - timed out; 0 - not timed out

This method checks to see if the session has been timed out.
The default time out is 20 minutes.

=cut

sub check_timeout {
    my $s = shift;
    my ($q, $ar) = @_; 
    my ($cdt,$stm, $tmout) = (time, 0, 0); 
       $stm   = $ar->{stm}             if exists $ar->{stm};
       $tmout = $ar->{session_timeout} if exists $ar->{session_timeout};
    return ($tmout && ($cdt-$stm)>$tmout)?1:0;
}


=head3 get_access ($cgi,$ar)

Input variables:

  $cgi - CGI object
  $ar  - Array ref containing all the parameters

Variables used or routines called: 

  None

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->get_access($q, \%cfg);

Return: $hr - access hash array ref: ${$hr}{uid|gid}{$name} = $uid|$giu

This method retrieves portal access user and group files and access_users and
access_groups in the configuration file to build an access list.

=cut

sub get_access {
    my $s = shift;
    my ($q, $ar) = @_;
    
    require XML::Simple;

    my $ua_list = lc ${$ar}{access_users};
       $ua_list =~ s/\s*,\s*/\|/g;
    my $ga_list = lc ${$ar}{access_groups};
       $ga_list =~ s/\s*,\s*/\|/g;

    # get portal xml access files
    my $xml_grp = ${$ar}{xml_group};
    my $xml_usr = ${$ar}{xml_user};
   
    my $xs = new XML::Simple;
    my $grf = $xs->XMLin($xml_grp);
    my $urf = $xs->XMLin($xml_usr);
    
    my %uid = ();  # User ID   hash array 
    my %gid = ();  # Group ID  hash array
    my %lku = ();  # User and group ID lookup 
    foreach my $hr (@{${$urf}{user}}) {
        my $i = ${$hr}{uid};
        my $e = lc ${$hr}{email};
        next if $e !~ /^($ua_list)/i;
        foreach my $k (keys %{$hr}) {
            next if $k =~ /^(uid)$/i;
            $uid{"$i"}{$k} = ${$hr}{$k};
            $lku{uid}{$e} = $i;
        }
    }

    ${$ar}{_uid} = \%uid;
    $s->disp_param(${$ar}{_uid}) if ${$ar}{v};
    foreach my $hr (@{${$grf}{group}}) {
        my $i = ${$hr}{gid};
        my $e = lc ${$hr}{groupname};
        next if $e !~ /^($ga_list)/i;
        foreach my $k (keys %{$hr}) {
            next if $k =~ /^gid/i;
            $gid{$i}{$k} = ${$hr}{$k};
            $lku{gid}{$e} = $i;
        }
    }
    ${$ar}{_gid} = \%gid;
    $s->disp_param(${$ar}{_gid}) if ${$ar}{v};
    # build a access list
    my %ac = ();
    
    foreach my $k (split /\|/, $ua_list) { 
        $ac{uid}{$k} = (exists $lku{uid}{$k})?$lku{uid}{$k}:"";
        print "WARN: User $k does not exist.\n" if !$ac{uid}{$k} && ${$ar}{v};
    }
    foreach my $k (split /\|/, $ga_list) { 
        $ac{gid}{$k} = (exists $lku{gid}{$k})?$lku{gid}{$k}:""; 
        print "WARN: Group $k does not exist.\n" if !$ac{gid}{$k} && ${$ar}{v};
    }
    $s->disp_param(\%ac) if ${$ar}{v};
    return \%ac;
}

=head3 check_user ($cgi,$ar)

Input variables:

  $cgi - CGI object
  $ar  - Array ref containing all the parameters

Variables used or routines called: 

  disp_param  - display parameters
  get_cookies - get cookies
  get_access  - get access information

How to use:

  my $q = new CGI;
  my %cfg = (usr=>'jsmith', pwd=>'jojo');
  my @names = $q->param;
  foreach my $k (@names) { $cfg{$k} = $q->param($k) if ! exists $cfg{$k}; }
  $self->check_user($q, \%cfg);

Return: $n - status code

  0 - no user name from input nor from cookie
  1 - user name does not exists
  2 - user does not belong to any group which has granted access
  >9 - user has access to the application

A successful user authentication includes: 
1) the user has to be a valid web portal user; 
2) user's password matches
3) user has to be a authorized user or in an authorized group to use this 
application. The autorization parameters are access_users and access_groups
in the configuration file.

=cut

sub check_user {
    my $s = shift;
    my ($q, $ar) = @_;
    
    my ($usr, $pwd) = ("","");
    $usr = $ar->{user_id}	if exists $ar->{user_id};
    $ar->{user_pwd} = ""	if !$usr && exists $ar->{user_pwd};
    $pwd = $ar->{user_pwd}	if exists $ar->{user_pwd};
    return 160                  if !$pwd && $usr;

    # No user and we try to retrieve it from cookies
    my $ck1 = 'ckUID'; 		# User id
    my $ck2 = 'ckPWD'; 		# User password
    my $cr  = $s->get_cookies($q, $ar); 
    return 151   if !$usr 
        && !exists $cr->{$ck1}{$ck1} && !exists $cr->{$ck2}{$ck2}; 
    
    my ($svr,$obj); 
    $usr = $cr->{$ck1}{$ck1}  if !$usr && exists $cr->{$ck1}{$ck1};

    my ($uid, $obj_u, $s_pwd, $usr_fn, $usr_ln) = ("","","","",""); 
    $ar->{user_id} = $usr if $usr;
    return 0             if !$pwd && !$usr; 
    return 151           if !$usr;  # no user name from input nor from cookie
    return 160           if !$pwd && $usr;

    # we have user_id and password so far
    $usr =~ s/\%40/\@/g;
    # return 152 if !$uid;

    return 153 if $pwd ne $s_pwd;
        
    # So far, we have authenticated the user.
    # We need to authorize the user
    my $ua_list = ${$ar}{access_users};
       $ua_list =~ s/\s*,\s*/\|/g;
    my $ga_list = ${$ar}{access_groups};
       $ga_list =~ s/\s*,\s*/\|/g;
    my %ac = ();    # access list
    foreach my $k (split /\|/, $ua_list) { 
        my $u1 = $obj->GetUserID($k);     # get user id
        next if ! $u1;                    # did not find the user        
        my $o1 = $obj->GetUserObj($u1);   # get user object
        $ac{uid}{"$u1"} = $k;             # user id and name
    }
    foreach my $k (split /\|/, $ga_list) { 
        my $g1 = $obj->GetGroupID($k);    # get group id
        next if ! $g1;                    # did not find the group        
        my $o1 = $obj->GetGroupObj($g1);  # get group object
        $ac{gid}{"$g1"} = $k;             # group id and name
    }
    return 1000 if exists $ac{uid}{"$uid"}; 

    foreach my $g (split /,/, ${$obj_u}{GroupsList}) {
        my $go = $obj->GetGroupObj($g);
        my $gi = ${$go}{GroupID};
        return 1001 if exists $ac{gid}{"$gi"};
    }
    return 154;   # did not find in the group access
}

1;
