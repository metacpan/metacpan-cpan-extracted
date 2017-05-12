package CGI::AppBuilder::HTML;

# Perl standard modules
use strict;
use warnings;
use Getopt::Std;
use POSIX qw(strftime);
use Carp;
use File::Basename;
use File::Path; 

our $VERSION = 1.001;
require Exporter;
our @ISA         = qw(Exporter CGI::AppBuilder);
our @EXPORT      = qw();
our @EXPORT_OK   = qw(disp_index disp_top disp_left disp_linkedfiles
                      disp_header disp_footer disp_frd
                   );
our %EXPORT_TAGS = (
    frame => [qw(disp_top)],
    all  => [@EXPORT_OK]
);

use CGI::AppBuilder;
use CGI::AppBuilder::Message qw(:all);

=head1 NAME

CGI::AppBuilder::HTML - generating HTML Codes

=head1 SYNOPSIS

  use CGI::AppBuilder::HTML;

  my $ab = CGI::AppBuilder::HTML->new(
     'ifn', 'my_init.cfg', 'opt', 'vhS:a:');
  my ($q, $ar, $ar_log) = $ab->start_app($0, \%ARGV);
  print $ab->disp_form($q, $ar); 

=head1 DESCRIPTION

This class provides methods for randering HTNL codes. 

=cut

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 disp_top ($q, $ar)

Input variables:

  $q  - CGI object
  $ar - parameter hash array

How to use:

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub disp_top {
    my $s = shift;
    my ($q, $ar) = @_; 

    print $s->disp_header($q,$ar);
    
    my $prg = 'AbbBuilder::HTML->disp_top';
    # 1. get variable definition
    my $pv = (exists $ar->{page_var}) ? (eval $ar->{page_var}) : {}; 
    $s->echo_msg("ERR: ($prg) $@", 0) if $@;  

    my $vs = 'task,web_url,pid,sel_sn1'; 
    my ($tsk,$url,$pid,$sn) = $s->get_params($vs, $ar); 
    my $pg = (exists $ar->{pg_fns}) ? (eval $ar->{pg_fns}) : {}; 
    my $hlp = (exists $pg->{$pid}{hlp})?$pg->{$pid}{hlp}:'/owb/map_hlp.htm';
      $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
    my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n";     
    my $u1b = "$url&task=disp_new&new_task=run_login"; 
    my $s1b = sprintf $f_a2, $u1b, "R", "Login User", "Login>>";    
       $vs  = 'guid,user_uid,user_pwd,user_sid,user_tmo';
    my ($usr_gid,$usr_uid,$usr_pwd,$usr_sid,$usr_tmo) = $s->get_params($vs,$ar);
    my @aa = ($usr_gid) ? (split /:/, $usr_gid) : (); 
       $usr_sid = $aa[0]	if !$usr_sid; 
       $usr_uid = $aa[1]	if !$usr_uid; 
       $usr_tmo = $aa[2]	if !$usr_tmo; 
    my $sid = (exists $ar->{logout} && $ar->{logout}) ? "" : "&guid=$usr_gid";    
    my $mpt = (exists $pv->{mpt} && $pv->{mpt}) ? $pv->{mpt} : "&task=disp_links";
    my $msg = "($prg) ";     
    
    # 2. get page definition
    my $pd = {}; 
       $pd = eval $ar->{page_def} if exists $ar->{page_def};
    my $t_lgin = "&task=new_task&new_task=run_login$sid";       
    if (! exists $pd->{top}) { 
      my $t_lgin = "&task=disp_new&new_task=run_login$sid";       
      my $t_lgot = "&task=disp_new&new_task=run_logout$sid";       
      my $t_help = "&task=disp_links$sid";
      $pd->{top} = [
         # href, target, title, txt
         ["$hlp"		,"R"	,"Display Instruction"	,"Home"],
         ["$url$t_lgin"		,"R"	,"Login Page"		,"Login"],
         ["$url$sid"		,"D"	,"Start Admin Panel"	,"Admin"],
         ["$url$mpt$sid"	,"L"	,"Start User Panel"	,"Users"],
         ["$url$t_help"		,"L"	,"Display Task Helps"	,"Help"],
         ["$url$t_lgot"		,"R"	,"Logout Page"		,"Logout"]
         ];
    };     
    # 3. build HTML code
    my $f_a = "<a href='%s', target='%s' title='%s'>%s</a>\n";
    my $f_img = "<IMG src='%s' border=0 align=middle title='%s' width=60>\n";
    my $f_ft = "<font size=%s>%s</font>\n";
    
    my $t1 = '  <td align=left>';
    $t1 .= sprintf $f_img, $ar->{logo}, 'Company Logo'	if exists $ar->{logo}; 
    $t1 .= sprintf $f_ft, "+1", $ar->{app_name}		if exists $ar->{app_name};
    $t1 .= sprintf $f_ft, "-2", " [V $ar->{app_version}]" if exists $ar->{app_version};
    $t1 .= "  </td>\n"; 
    
    my $t2 = '';
    for my $i (0..$#{$pd->{top}}) {
      my $v = $pd->{top}[$i]; 
      $t2 .= ($t2) ? '| ' : "[\n";
      $t2 .= sprintf $f_a, @$v; 
    }
    $t2 .= "]\n"; 
    $t2 = "  <td>$t2  </td>\n";
    
    my $t = "<table align=center width=780>\n";
    $t .= "<tr>\n$t1$t2</tr>\n";
    $t .= "</table>\n";

    print $t; 

}

=head2 disp_frd ($q, $ar)

Input variables:

  $q  - CGI object
  $ar - parameter hash array

How to use:

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub disp_frd {
    my $s = shift;
    my ($q, $ar) = @_; 

    print $s->disp_header($q,$ar);

    my $prg = 'AbbBuilder::HTML->disp_frd';
    # 1. get variable definition
    my $pv = (exists $ar->{page_var}) ? (eval $ar->{page_var}) : {}; 
    $s->echo_msg("ERR: ($prg) $@", 0) if $@;      
    
    my $vs = 'web_url,pid,sel_sn1,log_outdir,ds'; 
    my ($url,$pid,$sn,$ldr,$ds) = $s->get_params($vs, $ar); 
      $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
    my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n";     
    my $u1b = "$url&task=disp_new&new_task=run_login"; 
    my $s1b = sprintf $f_a2, $u1b, "R", "Login User", "Login>>";    
       $vs  = 'guid,user_uid,user_pwd,user_sid,user_tmo';
    my ($usr_gid,$usr_uid,$usr_pwd,$usr_sid,$usr_tmo) = $s->get_params($vs,$ar);

    # my $sid = "&user_uid=$usr_uid&user_sid=$usr_sid&user_tmo=$usr_tmo";    
    my $sid = "&guid=$usr_gid";    
    my $mpt = (exists $pv->{mpt} && $pv->{mpt}) ? $pv->{mpt} : "&task=disp_links";
    my $msg = "($prg) ";     
        
    # 2. get page definition
    my $pd = {}; 
       $pd = eval $ar->{page_def} if exists $ar->{page_def};
    if (! exists $pd->{frd}) { 
      $pd->{frd} = [
        {cols=>"1/4,1/4,1/4,1/4",frameborder=>'no',border=>'0',framespacing=>'0'},[
        {src=>"$url&task=disp_client$sid",name=>"D1"},
        {src=>"",name=>"D2"},
        {src=>"",name=>"D3"},
        {src=>"",name=>"D4"} ]
        ];
    };     
    # 3. print HTML code
    my $t = $s->frame_set($q, $pd->{frd},$ar);
#    my $ofn = join $ds, $ldr, "disp_frd$ar->{hms}.htm"; 
#    open HTM, ">>$ofn" or croak "ERR: ($prg) could not write to file - $ofn:$!\n";
#    print HTM $t; 
#    close HTM;
  my $ct = "Content-Type: text/html\n\n";    
  my $ht = "<html>\n"; 
#    print $ht; 
    print $t;
}


=head2 disp_index ($q, $ar)

Input variables:

  $q  - CGI object
  $ar - parameter hash array

How to use:

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub disp_index {
    my $s = shift;
    my ($q, $ar) = @_; 

    my $prg = 'AbbBuilder::HTML->disp_index';
    # 1. get page variable definition
    my $pv  = (exists $ar->{page_var}) ? (eval $ar->{page_var}) : {};    
    $s->echo_msg("ERR: ($prg) $@", 0) if $@;  

    my $vs = 'task,web_url,pid,sel_sn1'; 
    my ($tsk,$url,$pid,$sn) = $s->get_params($vs, $ar); 
      $url .= "?pid=$pid&no_dispform=1&sel_sn1=$sn";
    my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n";     
    my $u1b = "$url&task=disp_new&new_task=run_login"; 
    my $s1b = sprintf $f_a2, $u1b, "R", "Login User", "Login>>";    
       $vs  = 'guid,user_uid,user_pwd,user_sid,user_tmo';
    my ($usr_gid,$usr_uid,$usr_pwd,$usr_sid,$usr_tmo) = $s->get_params($vs,$ar);

    # my $sid = "&user_uid=$usr_uid&user_sid=$usr_sid&user_tmo=$usr_tmo";    
    my $sid = ($tsk =~ /logout$/i) ? "&guid=$usr_gid&logout=1" : "&guid=$usr_gid";    
    my $mpt = (exists $pv->{mpt} && $pv->{mpt}) ? $pv->{mpt} : "&task=disp_links";
    my $msg = "($prg) "; 
    if (!$usr_gid) {
      $msg = "No user credential ($usr_gid)."; 
      print $q->header("text/html");
      print $q->start_html(%{$ar->{html_header}});
      $s->disp_param($ar->{_sql_output}) if exists $ar->{_sql_output}; 
      print "$msg<br> Please $s1b<br>\n";
      print $q->end_html; 
      exit;
    } else { 
      my @ss = split /:/, $usr_gid;
      $usr_sid = $ss[0] if !$usr_sid;
      $usr_uid = $ss[1] if !$usr_uid;
      $usr_tmo = $ss[2] if !$usr_tmo;
    }    
    my $op = (exists $ar->{_sql_output}) ? $ar->{_sql_output} : [];
    if (exists $ar->{out_num} && $ar->{out_num} > 0) {
      print $q->header("text/html");
      $ar->{html_header}{-target} = "R";
      print $q->start_html(%{$ar->{html_header}});
      print "<pre>\n@$op\n</pre>\n";
      exit; 
    }
    
    # 2. build a output page
    my $pg = (exists $ar->{pg_fns}) ? (eval $ar->{pg_fns}) : {}; 
    my $hlp = (exists $pg->{$pid}{hlp})?$pg->{$pid}{hlp}:'/owb/map_hlp.htm';
    my $blk = (exists $pg->{$pid}{blk})?$pg->{$pid}{blk}:'/owb/map_blank.htm';
    my $dr  = (exists $ar->{out_dir})? (eval $ar->{out_dir}) : {}; 
    my $rt  = (exists $dr->{$sn}{usr_log}) ? $dr->{$sn}{usr_log} : ""; 
       $rt  = (exists $dr->{$sn}{log}) ? $dr->{$sn}{log} : ""	if !$rt;
       $rt  = ($^O =~ /^MSWin/i) ? 'c:\temp' : '/tmp'		if !$rt;
    my $ds  = (exists $ar->{ds}) ? $ar->{ds} : ''; 
       $ds  = ($^O =~ /^MSWin/i) ? '\\' : '/' 	if ! $ds; 
    my ($odr,$ofn,$u_hlp) = ("","","");
    my ($sfx) = ($tsk =~ /(login|logout)$/i); 
    my $ymd = strftime "%Y$ds%m$ds%d", localtime; 
    if ($tsk && $tsk =~ /(login|logout)$/i) {
      $s->echo_msg("WARN: ($prg) log dir has not been defined.",1) if !$rt; 
      my $uuid = ($usr_uid) ? $usr_uid : 'xxx';
      my $usid = ($usr_sid) ? $usr_sid : substr(time, length(time)-5); 
      my $sf2 = $sfx . '_' . substr(time, length(time)-3); 
      $odr = join $ds, $rt, $uuid, $ymd; 
      eval { mkpath($odr,0,0777) };
      $s->echo_msg("ERR: ($prg) could not mkdir - $odr: $!: $@",0) if ($@);
      $ofn = join $ds, $odr, "${uuid}_${usid}_$sf2.htm";
      open  FF,">$ofn" or carp "ERR: could not write to $ofn: $!\n";
      # print FF $s->disp_header($q,$ar); 
      print FF "<pre>\n@$op\n</pre>\n";
      close FF; 
      $u_hlp = "$url&task=disp_file&f=$ofn$sid"; 
    } else {
      if (exists $ar->{sess_ofn} && $ar->{sess_ofn}) {
        $u_hlp = "$url&task=disp_file&f=$ar->{sess_ofn}$sid";
      } else { 
        $u_hlp = $hlp;
      }
    }
    my $u_lft = (($sfx && $sfx =~ /^logout/i) || 
       (exists $ar->{logout} && $ar->{logout})) ? "" : "$url$mpt$sid"; 
    my $u_top = (($sfx && $sfx =~ /^logout/i) || 
       (exists $ar->{logout} && $ar->{logout})) ? "$url&task=disp_top&logout=1" 
       : "$url&task=disp_top$sid"; 
    
    # 3. get page definition
    my $pd = {}; 

#    if (exists $ar->{page_def}) {
#      $s->expand_vars($ar->{page_def}, $pv); 
#      $pd = eval $ar->{page_def};
#      if ($@) { 
#        $s->echo_msg("ERR: ($prg) $@",0); 
#      } else { 
#        print $s->frame_set($pd->{index},$ar);
#      }
#      return; 
#    }
    
    # 4. let's build a index page
    my $u2i = "$url$sid&task=disp_index";
       $u2i .= "&user_uid=$usr_uid"	if $usr_uid;
       $u2i .= "&user_tmo=$usr_tmo"	if $usr_tmo;
       $u2i .= "&user_sid=$usr_sid"	if $usr_sid;
       $u2i .= "&user_pwd=$usr_pwd"	if $usr_pwd;
       $u2i .= "&logout=1"		if ($tsk && $tsk =~ /logout$/i); 
    if ($ofn) {       
      my $tmp = $ofn; $tmp =~ s{\\}{\\\\}g; 
      $u2i .= "&sess_ofn=$tmp";
    }       
    my $js = "  if (top.frames.length > 0) top.location.replace(self.location);";
    my $j2 = "  function breakOut(inStr) {\n";
      $j2 .= "    if (self != top || inStr != \"\" || inStr != null)\n";
      $j2 .= "      window.open(\"$u2i\",\"_top\",\"\");\n";
      $j2 .= "  }\n"; 
    if ($tsk =~ /(login|logout)$/i) {
      $ar->{body_attr} = {} if !exists $ar->{body_attr}; 
      $ar->{body_attr}{onLoad} = "breakOut(\"$1\")";
      push @{$ar->{html_header}{-script}}, 
        ({-language=>'JavaScript1.2', -code=>$j2}); 
    }

    $pd = {index => [{frameborder=>'no',border=>'0',framespacing=>'0', target=>'_top'}, [
      [{rows=>"60,*",frameborder=>'no',border=>'0',framespacing=>'0'},
        [{src=>"$u_top",name=>"T"},
          [{cols=>"200,*",name=>'M'},[
            {src=>"$u_lft",name=>"L"},
          [{rows=>'250,*',name=>"C"},[
            {src=>"$blk",name=>"D"},
            {src=>"$u_hlp",name=>"R"}]
          ]
      ]]
     ]]]],
     };
    $ar->{page_def} = $pd; 
    
    # 5. display the frames
    $s->disp_header($q,$ar,1);
  my $ct = "Content-Type: text/html\n\n";    
  my $ht = "<html>\n"; 
#    print $ht; 
    print $s->frame_set($q, $pd->{index},$ar);
}

=head2 disp_left ($q, $ar)

Input variables:

  $q  - CGI object
  $ar - parameter hash array

How to use:

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub disp_left {
    my $s = shift;
    my ($q, $ar) = @_; 

    my $prg = 'AbbBuilder::HTML->disp_left';
    # 1. get variable definition
    my $pv = (exists $ar->{page_var}) ? (eval $ar->{page_var}) : {};    
    $s->echo_msg("ERR: ($prg) $@", 0) if $@;    

    # 2. get page definition
    if (! exists $ar->{page_def}) {
      $s->echo_msg("ERR: ($prg) no page definition.", 0);
      return; 
    }
    my $x = {xx=>$ar->{page_def}}; 
    my $pc = $s->eval_var($x, $pv); 
    # print "PC: $x->{xx}<br>\n"; 
    $ar->{page_def} = $x->{xx}; 

    my $pd = eval $ar->{page_def};
    $s->echo_msg("ERR: ($prg) $@",0) if $@; 
    # $s->disp_param($pd);
        
    # 3. build HTML code
    my $f_a = "<a href='%s', target='%s' title='%s'>%s</a>\n";
    my $f_img = "<IMG src='%s' border=0 align=middle title='%s' width=60>\n";
    my $f_ft = "<font size=%s>%s</font>\n";
    
    my $t1 = '  <td align=left>';
    $t1 .= sprintf $f_img, $ar->{logo}, 'Company Logo'	if exists $ar->{logo}; 
    $t1 .= sprintf $f_ft, "+1", $ar->{app_name}		if exists $ar->{app_name};
    $t1 .= sprintf $f_ft, "-2", " [V $ar->{app_version}]" if exists $ar->{app_version};
    $t1 .= "  </td>\n"; 
    
    my $t2 = '';
    for my $i (0..$#{$pd->{top}}) {
      my $v = $pd->{top}[$i]; 
      $t2 .= ($t2) ? '| ' : "[\n";
      $t2 .= sprintf $f_a, @$v; 
    }
    $t2 .= "]\n"; 
    $t2 = "  <td>$t2  </td>\n";
    
    my $t = "<table align=center width=780>\n";
    $t .= "<tr>\n$t1$t2</tr>\n";
    $t .= "</table>\n";
    
    print $t; 

}

sub disp_header {
  my ($s, $q, $ar, $prt, $add_ct) = @_;

  my $ck = (exists $ar->{_cookie} && $ar->{_cookie} 
           && ref($ar->{_cookie}) =~ /^ARRAY/ ) ? $ar->{_cookie} : [];
  # for my $i (0..$#$ck) { my $c = $ck->[$i]; print "Set-Cookie: $c\n";  } 
  
  my $f_ma = "  <meta name=\"%s\" content=\"%s\" />\n";
  my $f_ss = "  <link rel=\"stylesheet\" type=\"text/css\" href=\"%s\" />\n";
  my $f_sc = "<script src=\"%s\" type=\"text/javascript\"></script>\n";
  my $f_s2 = "<script type=\"text/javascript\">\n%s\n</script>\n";
  my $f_bs = "  <base href=\"%s\" target=\"%s\" />\n";

  my $vs = 'cgi_script,home_url,HomeLoc';
  my ($cgi,$home_url,$home_loc) = $s->get_params($vs, $ar); 
     $cgi = $home_url if ! $cgi; 
     $cgi = $home_loc if ! $cgi; 
  my $hr = (exists $ar->{html_header}) ? $ar->{html_header} : {}; 

  my $tit = (exists $hr->{-title})  ? $hr->{-title}  : ""; 
  my $atr = (exists $hr->{-author}) ? $hr->{-author} : ""; 
  my $tgt = (exists $hr->{-target}) ? $hr->{-target} : ""; 
  my $t = "";
  $t .= "Content-Type: text/html\n\n" 	if $add_ct;
#  $t .= '<?xml version="1.0" encoding="iso-8859-1"?>' . "\n"; 
#  $t .= '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"' . "\n";
#  $t .= "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
#  $t .= '<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">';
  $t .= "<html>\n<head>\n";
  $t .= "  <title>$tit</title>\n" 				if $tit; 
  $t .= "  <link rev=\"made\" href=\"mailto:$atr\" />\n" 	if $atr; 
  $t .= sprintf $f_bs, $cgi, $tgt 				if $tgt; 

  foreach my $k (keys %{$hr->{meta}}) {
    my $v = $hr->{meta}{$k}; 
    $t .= sprintf $f_ma, $k, $v; 
  } 
  my $hr1 = $hr->{-style}; 
  $t .= (ref($hr1) =~ /^HASH/ && exists $hr1->{src}) ?  
         sprintf $f_ss, $hr1->{src} : $hr->{-style}; 
  for my $i (0..$#{$hr->{-script}}) {
    my $g = $hr->{-script}[$i]{-language}; 
    if (exists $hr->{-script}[$i]{-src}) {
      $t .= sprintf $f_sc, $hr->{-script}[$i]{-src};
    } elsif (exists $hr->{-script}[$i]{-code}) {
      $t .= sprintf $f_s2, $hr->{-script}[$i]{-code};
    }
  }
  my $f_ot = "  <sql_out>%s</sql_out>\n";
  if (exists $ar->{_sql_output}) {
    $t .= "<!-- SQL_OUTPUT: \n";
    for my $i (0..$#{$ar->{_sql_output}}) {
      # chomp ($v = $ar->{_sql_output}[$i]);
      $t .= $ar->{_sql_output}[$i]; 
    } 
    $t .= "-->\n"; 
  } 
  $t .= "</head>\n";
  my $ba = (exists $ar->{body_attr}) ? $ar->{body_attr} : {}; 
  if (exists $ar->{body_attr}) {
     $t .= "<body";
     foreach my $k (keys %{$ar->{body_attr}}) {
       $t .= " $k=$ar->{body_attr}{$k}"; 
     }
     $t .= ">\n"; 
  } 
#  else {
#    $t .= "<body>\n"; 
#  }
  print $t if $prt; 
  
  return $t; 
}

sub disp_footer {
  my ($s, $q, $ar, $prt) = @_;

  my $t = "</body>\n</html>\n";
  print $t if $prt; 
  return $t; 
}

sub expand_idx {
  my ($s, $rr, $vr) = @_;
  return if ! @$rr; 
  my ($hh, $aa) = @$rr; 
  $hh->{src} = $s->expand_vars($hh->{src}, $vr) if exists $hh->{src};
  $s->expand_idx($aa,$vr) if ref($aa) =~ /^ARRAY/; 
}


=head2 disp_linkedfiles ($q, $ar)

Input variables:

  $q  - CGI object
  $ar - parameter hash array
  $pr - array ref for a list of file names
  $rt - whether to return the HTML codes

How to use:

Return: HTML codes.

This method generates HTML codes based on the information provided.

=cut

sub disp_linkedfiles {
  my $s = shift;
  my ($q, $ar, $pr, $rt) = @_; 

  # $s->disp_param($ar);
  my $prg = 'AppBuilder::HTML->disp_linkedfiles';

  if (ref($pr) !~ /^ARRAY/ || !@$pr)  {
    $s->echo_msg("ERR: ($prg) no files to be linked.", 0);
    return; 
  }

  my $vs = 'pid,sid,guid,script_url';
  my ($pid,$sid,$usr_gid,$url) = $s->get_params($vs,$ar); 
  my $ug = ($usr_gid) ? "&guid=$usr_gid" : ""; 
  
  my $u1  = "$url?pid=$pid&sel_sn1=$sid$ug&task=disp_file&f=";
  my $f_aa = "<a href=\"%s\" target=R>%s</a>\n"; 
  my $f_a2 = "<a href=\"%s\" target=\"%s\" title=\"%s\">%s</a>\n"; 
  my $f_li = "  <li><a href=\"%s\">%s</a></li>\n";  

  my $t = "<ul>\n"; 
  for my $i (0..$#$pr) {
    my $f = $pr->[$i];
    my ($fname, $path, $sfx) = fileparse($f,qr{\..*});    
    my $aa = sprintf $f_a2, "$u1$f", "R", "$path", "$fname$sfx"; 
    $t .= "  <li>$aa";  
  }
  $t .= "</ul>\n"; 
  
  return $t if $rt; 
  print $t; 
}

1;

=head1 HISTORY

=over 4

=item * Version 0.10

This version includes the frame_set method. 

=item * Version 0.20

=cut

=head1 SEE ALSO (some of docs that I check often)

Oracle::Loader, Oracle::Trigger, CGI::Getopt, File::Xcopy,
CGI::AppBuilder, CGI::AppBuilder::Message, CGI::AppBuilder::Log,
CGI::AppBuilder::Config, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

