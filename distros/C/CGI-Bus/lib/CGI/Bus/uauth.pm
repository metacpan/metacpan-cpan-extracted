#!perl -w
#
# CGI::Bus::uauth - User Authentication Base Class
#
# admiral 
#
# 

package CGI::Bus::uauth;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::Base);


my $cooknme ='_cgi_bus_uauth';
my $guest   ='guest';
my $w32afl  =0; # 0 - adsi, 1 - findgrp, 2 - win32api::net
my $w32ver  =$^O eq 'MSWin32' ? (Win32::GetOSVersion())[1] : undef;


if ($ENV{MOD_PERL}) {
   eval('use Apache qw(exit);');
}


1;



#######################

sub w32oleget{	# Windows OLE object
 my $s =shift;
 eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)');
 Win32::OLE->GetObject(@_)
}


sub usdomain {	# User names Server Domain
 my $s =shift;
 $ENV{DOMAINNAME}
 ||($^O eq 'MSWin32' 
 ? (($w32afl <1 && $w32ver >= 5
    &&	(eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)')
	&& Win32::OLE->CreateObject("ADSystemInfo")->{DomainShortName}
	|| $ENV{COMPUTERNAME} ||Win32::NodeName()
	))
   ||eval('use Win32::TieRegistry; $Registry->{\'LMachine\\\\SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\Winlogon\\\\\\\\CachePrimaryDomain\'} || $Registry->{\'LMachine\\\\SOFTWARE\\\\Microsoft\\\\Windows NT\\\\CurrentVersion\\\\Winlogon\\\\\\\\DefaultDomainName\'}')
   ||eval('use Win32; Win32::DomainName()'))
 : '')
 || ($s->surl =~/^[^\/\.]+[\/]+w*\.*([^\/]+)/i ? $1 : '')
}


sub userver {	# User names Server
 my $s =shift;
 if ($^O eq 'MSWin32') {
	my $hn =$ENV{COMPUTERNAME} || eval{Win32::NodeName()};
	my $dc ='';
	$w32ver >= 5
	&& eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); 1')
	&& ($dc =Win32::OLE->CreateObject("ADSystemInfo")->GetAnyDCName)
	|| eval{eval('use Win32API::Net'); 
		Win32API::Net::GetDCName($hn,$s->parent->usdomain,$dc)};
	$dc ||$hn ||''
 }
 else {
    eval ('use Sys::Hostname; Sys::Hostname')
 }
}


sub user {	# User name
 my $s =shift;
 my $u =
   ($_[0] || $ENV{REMOTE_USER} || $ENV{AUTH_USER}
    ||($ENV{CERT_SUBJECT} ? ($ENV{CERT_SUBJECT} .'/' .$ENV{CERT_ISSUER}) : '')
    ||$s->signchk ||$guest);
 $u
}


sub guest {	# Guest name
 $guest
}


sub ugroups {	# User groups
 my $s =$_[0];
 my $p =$s->parent;
 my($un,$ul) =$_[1] ? ($_[1],$_[1]) : ($s->user(), $s->useron());
 my $u =[]; return($u) if !$p->user;
 my $c =$p->{-ugflt};
 my $f =undef;
 local $_;
 if ($s->{-udata}) {
    $u =$p->udata->param('uauth_groups') ||[]
 }
 elsif (($f =$s->{-AuthGroupFile})
 || ($^O eq 'MSWin32' && $w32afl <1 && $w32ver >=5 && $s->w32adaf()
 && ($f =$s->dpath('uauth/uagroup')))) {
	#$s->pushmsg("ugroups via file");
	local *FG; 
	open(FG, "<$f")	&& flock(FG, 1)	# LOCK_SH
	||$s->die($s->lng(0, 'ugroups') .": open('$f')->$!");
	while(my $r =readline *FG) {
		next if $r !~/[:\s](?:\Q$un\E|\Q$ul\E)(?:\s|\Z)/i;
		next if $r !~/^([^:]+)\s*:/;
		push @$u, $1
	}
	flock(FG,8); close(FG);	# LOCK_UN
	$u =$s->w32adug($ul ||$un)
		if 0 && !@$u && $^O eq 'MSWin32' && $w32afl <1 && $w32ver >=5;
 }
 elsif ($^O eq 'MSWin32') {
    if (0) {}
    elsif ($w32afl <1 && $w32ver >=5) {
	# $s->pushmsg("ugroups via adsi");
	$u =$s->w32adug($ul ||$un);
    }
    elsif ($w32afl <2
	&& do{	my $d =$s->parent->usdomain;
		my $n =$ul ||$un;
		   $n ="$d\\$n" if index($n,'\\') <0;
		my $h =$ENV{COMPUTERNAME} || eval{Win32::NodeName()};
		   $h =$h ? "\\\\$h" : $d;
		my $f =($n =~/^$d\\/i ? '/q' : '');
		my $gd=(!$f && $n =~/^([^\\]+)/ ? $1 : '');
		my @g =`findgrp.exe $h $n $f`; # !!! Using Windows Resource Kit !!!
		if (scalar(@g)) {
			# $s->pushmsg("ugroups via findgrp.exe '$n','$d','$f'");
			$w32afl =1;
			my $gd1;
			foreach my $v (@g) {
				next if !$v || $v =~/^\s*$/;
				if ($v =~/^[^\s]/) {
					$gd1 =$gd if !$f && $v=~/^User\s/i && $v=~/\sGlobal\s/i;
					next;
				}
				$v =$1 if $v =~/^[\s]*([^\n]+)/;
				push @$u, $gd1 ? "$gd1\\$v" : $v
			}
			$u
		}
		else {
			undef
		}
	}) {
    }
    else {
	# !!! failure Win32API::Net::UserGetGroups
	# $s->pushmsg("ugroups via Win32API::Net");
	$w32afl =2;
	my $n =$ul ||$un;
	my $d =$s->parent->usdomain;
	my $h =$ENV{COMPUTERNAME} || eval{Win32::NodeName()};
	my $gd=($n !~/^$d\\/i && $n =~/^([^\\]+)/ ? $1 : '');
	my %g;
	my @g;
	eval('use Win32API::Net');
	return $u if $@;
	if (Win32API::Net::UserGetGroups($s->parent->userver, $n, \@g)) {
		$gd ? (map {$g{"$gd\\$_"} =1} @g) : (map {$g{$_} =1} @g)
	} else { 
		$s->pushmsg("Win32API::Net::UserGetGroups('" .$s->parent->userver ."', '$n')-> " .Win32::GetLastError() ." $^E");
	}
	if (Win32API::Net::UserGetLocalGroups($h, $n, \@g, Win32API::Net::LG_INCLUDE_INDIRECT())) {
		map {$g{$_} =1} @g 
	} else { 
		$s->pushmsg("Win32API::Net::UserGetLocalGroups('$h', '$n')-> " .Win32::GetLastError() ." $^E");
	}
	delete $g{'None'};
	$u =[sort {lc($a) cmp lc($b)} keys(%g)];
    }
 }
 else {
 }
 $u =[map {&$c($p) ? ($_) : ()
		} @$u
	] if $c;
 @$u =($guest) if !@$u;
 $u
}


sub uglist {	# User & Group List
 my $s =shift;
 my $p =$s->parent;
 my $o =defined($_[0]) && substr($_[0],0,1) eq '-' ? shift : '-ug';
 my $fg=$p->{-ugflt};
 my $fu=$p->{-unflt};
 my $r =shift ||[];
 my $a;
 local $_;
 if ($s->{-udata}) {
	my $l =$s->parent->udata->uglist;
	$r =ref($r) eq 'HASH'
		? {map {($_ => $_)} @$l}
		: $l
 }
 elsif ($s->{-AuthUserFile} ||$s->{-AuthGroupFile}) {
	my @r;
	push @r, map {!$fu || &{$fu}($p)
			} map {/^([^:]+):/ ? ($1) : ()
				} $p->fut->fread('-a',$s->{-AuthUserFile})
		if $s->{-AuthUserFile} && $o =~/u/;

	push @r, map {!$fg || &{$fg}($p)
			} map {/^([^:]+):/ ? ($1) : ()
				} $p->fut->fread('-a',$s->{-AuthGroupFile})
		if $s->{-AuthGroupFile} && $o =~/g/;
	$r =ref($r) eq 'HASH'
		? {map {($_ => $_)} @r}
		: [@r]
 }
 elsif ($^O eq 'MSWin32'
     && $w32afl <1 && $w32ver >=5 && $s->w32adaf()) {
 	my $f =$s->dpath('uauth/ualist');
	local *FG;
	open(FG, "<$f") && flock(FG, 1) # LOCK_SH
	||$s->die($s->lng(0, 'uglist') .": open('$f')->$!");
	while(my $rr =readline *FG) {
		my ($en, $ef, $ep, $ec, $ed) =(split /:\t/, $rr)[0,1,2,3,4];
		my $ev =$en =~/[\@\\]/ && $o !~/[<>]/ ? $ef : $en;
		$_ =$en;
		if ($o =~/g/ && $ec =~/^g/i) {
			next if $fg && !&{$fg}($p, $en, $ef, $ep, $ed);
			if (ref($r) eq 'ARRAY') {
				push(@$r, $en)
			}
			else {
				$r->{$en} =!$ed
					? $ev
					: $o =~/[<>]/
					? (length($ed)+length($ev)+3 >60 
						? substr($ed, 0, 60 -length($ev)-6) .'...' 
						: $ed) 
					  .' <' .$ev .'>'
					: $ed =~/^\Q$en\E\s*([,-:]*)\s*(.*)/i
					? $ev .($1 ? " $1 " : ' - ') .$2
					: "$ev, $ed"
			}
		}
		if ($o =~/u/ && $ec =~/^u/i) {
			next if $fu && !&{$fu}($p, $en, $ef, $ep, $ed);
			if (ref($r) eq 'ARRAY') {
				push(@$r, $en)
			}
			else {
				$r->{$en} =$ed .' <' .$ev .'>'
			}
		}
	}
	flock(FG,8); close(FG);
 }
 elsif ($^O eq 'MSWin32'
     && $w32afl <1 && $w32ver >=5 
     &&($a =$s->w32oleget('WinNT://' .$s->parent->usdomain))) {
	if ($o =~/u/) {
		$a->{Filter} =['User'];
		foreach my $e (Win32::OLE::in($a)) {
			next if !$e ||!$e->{Class};
			$_ =$e->{Name};
			next if $fu && !&{$fu}($p, $e->{Name}, $e->{Name}, $e->{ADsPath}, $e->{FullName}||$e->{Name});
			if (ref($r) eq 'ARRAY') {
				push(@$r, $e->{Name})
			}
			else {
				$r->{$e->{Name}} =($e->{FullName} ||$e->{Name})
				.' <' .$e->{Name} .'>';
			}
		}
	}
	if ($o =~/g/) {
		$a->{Filter} =['Group'];
		foreach my $e (Win32::OLE::in($a)) {
			next if !$e ||!$e->{Class};
			$_ =$e->{Name};
			next if $fg && !&{$fg}($p, $e->{Name}, $e->{Name}, $e->{ADsPath}, $e->{Description});
			if (ref($r) eq 'ARRAY') {
				push(@$r, $e->{Name})
			}
			else {
				my $l =($e->{Description} ||'');
				$r->{$e->{Name}} =$e->{Name} .($l ? ', ' .$l :'');
			}
		}
	}
	if ($o =~/g/) {
		$a =$s->w32oleget('WinNT://' .($ENV{COMPUTERNAME} ||eval{Win32::NodeName()}));
		$a->{Filter} =['Group'];
		foreach my $e (Win32::OLE::in($a)) {
			next if !$e ||!$e->{Class} || $e->{groupType} ne '4';
			$_ =$e->{Name};
			next if $fg && !&{$fg}($p, $e->{Name}, $e->{Name}, $e->{ADsPath}, $e->{Description});
			if (ref($r) eq 'ARRAY') {
				push(@$r, $e->{Name})
			}
			else {
				my $l =($e->{Description} ||'');
				$r->{$e->{Name}} =$e->{Name} .($l ? ', ' .$l :'');
			}
		}
	}
 }
 elsif ($^O eq 'MSWin32') {
    $w32afl =2;
    eval("use Win32API::Net");
    return $r if $@;
    my $srv =$s->parent->userver;
    my @g;    
    my %i;
    my $l;
    if ($o =~/g/ && Win32API::Net::GroupEnum($srv, \@g)) {
       @g =map {&{$fg}($p) ? ($_) : ()} @g if $fg;
       if (ref($r) eq 'ARRAY') {
          push(@$r, @g) 
       }
       else {
          foreach my $g (@g) {
             %i =() if !Win32API::Net::GroupGetInfo($srv,$g,1,\%i);
             $l =$i{comment} ||'';
             $r->{$g} =$g .($l ? ', ' .$l :'');
          }
       }
    }
    if ($o =~/g/ && Win32API::Net::LocalGroupEnum($srv, \@g)) {
       @g =map {&{$fg}($p) ? ($_) : ()} @g if $fg;
       if (ref($r) eq 'ARRAY') {
          push(@$r, @g)
       }
       else {
          foreach my $g (@g) {
             %i =() if !Win32API::Net::LocalGroupGetInfo($srv,$g,1,\%i);
             $l =$i{comment} ||'';
             $r->{$g} =$g .($l ? ', ' .$l :'');
          }
       }
    }
    if ($o =~/u/ && Win32API::Net::UserEnum($srv, \@g)) {
       @g =map {&{$fu}($p) ? ($_) : ()} @g if $fu;
       if (ref($r) eq 'ARRAY') {
          push(@$r, @g)
       }
       else {
          foreach my $g (@g) {
             %i =() if !Win32API::Net::UserGetInfo($srv,$g,10,\%i);
             $l =$i{fullName} || $i{usrComment} ||$i{comment} ||'';
             $r->{$g} =$g .($l ? ', ' .$l :'');
          }
       }
    }
 }
 else {
 }
 $r
}



sub w32adaf {	# Win32 AD Auth Files write/refresh
 return(undef) if $^O ne 'MSWin32';
 my $s  =$_[0];						# self object
    $s	=$s->parent if $s && !$s->isa('CGI::Bus');
 my $fs =$_[1] ||$s->dpath('uauth');			# filesystem
 my $mo =$_[2];						# mandatory operation
 my $df =$_[3] ||$s->{-udflt} ||sub{1};			# domain filter
 my $fg =$fs .'/' .'uagroup';				# file 'group'
 my $fl =$fs .'/' .'ualist';				# file list
 return(1) 						# update frequency
	if (defined($s->{-w32adaf}) && $s->{-w32adaf}==0)
	|| ((-f $fg) && (time() -[stat($fg)]->[9] <
		($s->{-w32adaf}||(60*60*4)))); # 60*60);
 if (!$mo) {						# check mode
	if (!-f $fg) {			# immediate interactive
		$s->pushmsg($s->pushlog('w32adaf new ' .$fg));
		$s->fut->mkdir($s->dpath('uauth'));
	}
	elsif ($mo =$s && $s->{-endh}) {# end request handlers
		$mo->{w32adaf} =sub{w32adaf($_[0],$fs,'q',$df)};
		return(1)
	}
 }
 elsif ($mo eq 'q') {					# queued mode
	if (ref($s)			# reverted reject
	&&  $s->{-w32IISdpsn} && ($s->{-w32IISdpsn} <2)
	&&  $s->{-cache} && $s->{-cache}->{-RevertToSelf}) {
		return(0)
	}
	elsif (1) {			# inline
	}
	elsif (eval("use Thread; 1")	# threads
	&& ($mo =eval{Thread->new(sub{w32adaf(undef,$fs,'t',$df)})})
		) {
		$mo->detach;
		return(1);
	}
	elsif ($mo =fork) {		# fork parent success
		$SIG{CHLD} ='IGNORE';
		return(1);
	}
	elsif (!defined($mo)) {		# fork error, immediate interactive
	}
	else {				# fork child
		$mo ='f';
		w32adaf(undef,$fs,$mo,$df);
		exit(0);
	}
 }
 local(*FG, *FL, *FW);
 open(FG, "+>>$fg.tmp")
	|| ($s && $s->die($s->lng(0, 'w32adaf') .": open('$fg.tmp') -> $!"))
	|| croak("open('<$fg.tmp') -> $!");
 open(FL, "+>>$fl.tmp")
	|| ($s && $s->die($s->lng(0, 'w32adaf') .": open('$fl.tmp') -> $!"))
	|| croak("open('<$fl.tmp') -> $!");
 while (!flock(FG,2|4) ||!flock(FL,2|4)) { # LOCK_EX | LOCK_NB
	next if !-f $fg;
	flock(FG,8); close(FG);	# LOCK_UN
	flock(FL,8); close(FL);
	return(1)
 }
 truncate(FG,0); truncate(FL,0);
 seek(FG,0,0); seek(FL,0,0);
 eval('use Win32::OLE'); Win32::OLE->Option('Warn'=>0);
 my $od =Win32::OLE->GetObject('WinNT://' .(Win32::NodeName()) .',computer');
 my $hdu=$od	&& $od->{Name}		|| ''; 		# host domain name
 my $hdn=$od	&& lc($od->{Name})	|| ''; 		# host domain name		
 my $hdp=$od	&& $od->{ADsPath}	|| '';		# host domain path
 my $hdc=lc($hdp);					# host domain comparable
 my $ldp=$od	&& $od->{Parent}	|| '';		# local domain path
    $od =Win32::OLE->GetObject("$ldp,domain");
 my $ldu=$od	&& $od->{Name}		|| '';		# local domain name
 my $ldn=$od	&& lc($od->{Name})	|| '';		# local domain name
 my $ldc=lc($ldp);					# local domain comparable
 my %dnl=(!$hdn ?() :($hdn=>1), !$ldn ?() :($ldn=>1));	# domains to list
 my @dnl=(!$hdu ?() :$hdu, !$ldu ?() :$ldu);		# domains to list
 my $fgm;						# group lister/unfolder
    $fgm=sub{	my $om =$_[1]->{Members};
		join("\t"
		,(map {!$_ || !$_->{Class} || !$_->{Name} || substr($_->{Name},-1,1) eq '$' || substr($_->{Name},-1,1) eq '&'
		? ()
		: do {	my $dn =$_->{Parent} =~/([^\\\/]+)$/ ? $1 : $_->{Parent};
			map {$_ # $_ ne lc($_) ? ($_, lc($_)) : $_
				} lc($_->{Parent}) ne ($ldn ? $ldc : $hdc)
				? ($dn . '\\' .$_->{Name})
				: ($_->{Name}, ($dn . '\\' .$_->{Name}))
				#, $_->{Name} .'@' .$dn
			}} do {$om->{Filter} =['User']; Win32::OLE::in($om)})
		,(map {!$_ || !$_->{Class} || !$_->{Name} || !$_->{groupType} || substr($_->{Name},-1,1) eq '$' || substr($_->{Name},-1,1) eq '&'
		? ()
		: do {	if ($_->{groupType} eq '2') {
				my $du =$_->{Parent} =~/([^\\\/]+)$/ ? $1 : $_->{Parent};
				my $dn =lc($du);
				if (!$dnl{$dn} && $dn !~/^(?:nt authority|builtin)$/) {
					$dnl{$dn} =1;
					push @dnl, $du;
				}
			}
			(&$fgm($_[0], $_))
			}} do {$om->{Filter} =['Group']; Win32::OLE::in($om)})
		)};
 for (my $di =0; $di <=$#dnl; $di++) {
	my $du =$dnl[$di];
	local $_ =$du;
	next if !$du ||!&$df($s, $du);
	my $dn =lc($du);
	$od =Win32::OLE->GetObject("WinNT://$du");
	next if !$od || !$od->{Class};
	# standalone host:	local users, local groups
	# domain member	:	domain users, local groups, domain groups
	# domain controller:	domain users, local groups, domain groups
	my $dp =$dn eq $ldn || $dn eq $hdn ? '' : $du;
	unless ($hdn && $ldn && ($dn eq $hdn)) {
		$od->{Filter} =['User'];
		foreach my $oe (Win32::OLE::in($od)) {
			next if !$oe || !$oe->{Class} || !$oe->{Name} || substr($oe->{Name},-1,1) eq '$' || substr($oe->{Name},-1,1) eq '&';
			next if $oe->{AccountDisabled};
			next if $oe->{Name} =~/^(?:SYSTEM|INTERACTIVE|NETWORK|IUSR_|IWAM_|HP ITO |opc_op|patrol|SMS |SMS&_|SMSClient|SMSServer|SMSService|SMSSvc|SMSLogon|SMSInternal|SMS Site|SQLDebugger|sqlov|SharePoint|RTCService)/i;
			print FL $dp ? "$dp\\" : '', $oe->{Name}
			,":\t", $oe->{Name} .'@' .$du
			,":\t", $oe->{ADsPath}
			,":\t", $oe->{Class}
			,":\t", $oe->{FullName}||($oe->{Name} .'@' .$du)
			,":\t", $oe->{Description}||''
			, "\n";
		}
	}
	unless (0) {
		$od->{Filter} =['Group'];
		foreach my $oe (Win32::OLE::in($od)) {
			next if !$oe || !$oe->{Class} || !$oe->{Name} || substr($oe->{Name},-1,1) eq '$' || substr($oe->{Name},-1,1) eq '&';
			next	if	$dn ne $hdn
				?	$oe->{groupType} ne '2'  # global
				:	$oe->{groupType} ne '4'; # local
			next if $oe->{Name} =~/^(?:Domain Controllers|Domain Computers|Pre-Windows 2000|RAS and IAS Servers|MTS Trusted|SMSInternal|NetOp Activity)/i;
			my $sgm =&$fgm($_[0], $oe);
			print FL $dp ? "$dp\\" : '', $oe->{Name}
			,":\t", $oe->{Name} .'@' .$du
			,":\t", $oe->{ADsPath}
			,":\t", $oe->{Class}
			,":\t", $oe->{Description}||($oe->{Name} .'@' .$du)
			,":\t", $oe->{Description}||''
			,":\t", $sgm
			, "\n";
			print FG $dp ? "$dp\\" : '', $oe->{Name}, ":\t", $sgm, "\n"
			#,$dp ? ($oe->{Name}, '@', $dp, ":\t", $sgm, "\n") : ()
			#,$oe->{Name} .'@' .$du, ":\t", $sgm, "\n"
			;
		}
	}
 }
 seek(FG,0,0); seek(FL,0,0);
 open(FW, "+>>$fg") && flock(FW,2)	# LOCK_EX
 	&& truncate(FW,0) && seek(FW,0,0)
	&& do {while(my $rr =readline *FG){print FW $rr}; 1}
	&& flock(FW,8) && close(FW)	# LOCK_UN
	|| ($s && $s->die($s->lng(0, 'w32adaf') .": open('$fg') -> $!"))
	|| croak("open('<$fg') -> $!");
 flock(FG,8); close(FG); unlink("$fg.tmp");
 open(FW, "+>>$fl") && flock(FW,2)	# LOCK_EX
 	&& truncate(FW,0) && seek(FW,0,0)
	&& do {while(my $rr =readline *FL){print FW $rr}; 1}
	&& flock(FW,8) && close(FW)	# LOCK_UN
	|| ($s && $s->die($s->lng(0, 'w32adaf') .": open('$fl') -> $!"))
	|| croak("open('<$fl') -> $!");
 flock(FL,8); close(FL); unlink("$fl.tmp");
 1;
}


sub w32adug {	# Win32 AD retrieve user groups
 my $uif =$_[1];		# user input full name
 my $uid ='';			# user input domain name
 my $uin ='';			# user input name shorten

 eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)');
 if	($uif =~/^([^\\]+)\\(.+)/)	{ $uid =$1;	$uin =$2 }
 elsif	($uif =~/^([^@]+)\@(.+)/)	{ $uid =$2;	$uin =$1 }
 else					{ $uin =$uif;	$uid =Win32::OLE->CreateObject("ADSystemInfo")->{DomainShortName} ||Win32::NodeName()}

 my $gn =[];			# group names
 my $gp =[];			# group paths
 my $oh =Win32::OLE->GetObject('WinNT://' .Win32::NodeName() .',computer');
 return($gn) if !$oh;
 my $ou =Win32::OLE->GetObject("WinNT://$uid/$uin,user");
 return($gn) if !$ou;
 my $dp =			# !!!domain prefix for global groups, optional!!!
	  lc($oh->{Parent}) eq lc($ou->{Parent})
	? ''
	: $ou->{Parent} =~/([^\\\/]+)$/
	? $1 .'\\'
	: '';

 foreach my $og (Win32::OLE::in($ou->{Groups})) { # global groups from user's domain
	next if !$og || !$og->{Class} || $og->{groupType} ne '2';
	push @$gn, $dp .$og->{Name};
	push @$gp, $og->{ADsPath};
 }
 my $uc =lc($ou->{ADsPath});	# user compare
 my $gc =[map {lc($_)} @$gp];	# group compare
 $oh->{Filter} =['Group'];
 foreach my $og (Win32::OLE::in($oh)) {
	next if !$og || !$og->{Class} || $og->{groupType} ne '4';
	foreach my $om (Win32::OLE::in($og->{Members})) {
		next if !$om || !$om->{Class} || ($om->{Class} ne 'User' && $om->{Class} ne 'Group');
		my $mc =lc($om->{ADsPath});
		foreach my $p (@$gc) {
			next if $p ne $mc;
			push @$gn, $og->{Name};
			push @$gp, $og->{ADsPath};
			$mc =undef;
			last;
		}
		last if !$mc;
		if ($mc eq $uc) {
			push @$gn, $og->{Name};
			push @$gp, $og->{ADsPath};
			last;
		}
	}
 }
 $gn;
}


sub w32aduo {	# Win32 AD user object
	eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)');
	my ($dn, $gn) =	$_[1] =~/^([^\\]+)\\(.+)/ 
			? ($1,$2) 
			: $_[1] =~/^([^@]+)@(.+)/ 
			? ($2,$1) 
			: (Win32::NodeName(),$_);
	Win32::OLE->GetObject("WinNT://$dn/$gn");
}


sub w32adud {	# Win32 user display
	return($_[1]) if $^O ne 'MSWin32';
	my ($dn, $gn) =	$_[1] =~/^([^\\]+)\\(.+)/ 
			? ($1,$2)
			: $_[1] =~/^([^@]+)@(.+)/ 
			? ($2,$1)
			: (Win32::NodeName(),$_);
	my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); 1')
		&& Win32::OLE->GetObject("WinNT://$dn/$gn");
	!$o
	? $_[1]
	: $o->{Class} eq 'User'
	? $o->{FullName} ||$_[1]
	: $o->{Class} eq 'Group'
	? $o->{Description} ||$_[1]
	: $_[1]
}


sub w32adum {	# E-mail address of user
 my($s, $u) =@_[0,1];	# self, ?user, ?ad fields
	$u  =$s->parent()->user() if !$u;
 join(', '
	, map {	my $v =$_;
		my $o =eval{$s->w32aduo($v)};
		if ($o) {
			foreach my $f ($#_ >1 ? @_[2..$#_] : ('EmailAddress','Description')) {
			# !!! 'EmailAddress' not supported via WinNT://
			# LDAP://servername/<GUID=XXXXX>
			# GetObject("LDAP://<GUID=63560110f7e1d111a6bfaaaf842b9cfa>")
				if ((eval{$o->{$f}}||'') =~/\b([\w\d_+-]+\@[\w\d.]+)\b/) {
					$v =$1; last
				}
			}
		}
		# $v =~/\\([^\\]+)/ ? $1 : $v;
		$v
		} split /\s*[,;]\s*/, $u)
}


sub auth {	# Authenticate User
 my $s =shift;
 my $m =shift if ref($_[0]); # auth methods
                             # redirect url
 if ($s->parent->uguest() && ($s->{-login}||$s->parent->set('-login'))) {
    my $l =$s->{-login}||$s->parent->set('-login');
    if ($l =~/\/$/) {
       $l.=($s->qurl() =~m{/([^/]+)$} ? $1 : '') .($ENV{QUERY_STRING} ? ('?' .$ENV{QUERY_STRING}) :'');
    }
    else {
       $l =$s->parent->htmlurl($l,$cooknme,$s->url .($ENV{QUERY_STRING} ? ('?' .$ENV{QUERY_STRING}) :''));
    }
    my @p =(-uri=>$l);
    push @p, (-nph=>1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/
                       || ($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER}) # PerlSendHeader Off
                       ;
    $s->parent->print()->redirect(@p);
    eval{$s->parent->reset()};
    exit;
 }
 if (($ENV{SERVER_SOFTWARE}||'') =~/IIS/) {
    if    ($s->signchk)        {}
    elsif (1	# IIS Deimpersonation: 'Low (IIS Process)', !'Index Server'
	# && $ENV{REMOTE_USER}
	&& ($s->{-login}||$s->parent->set('-login')||'') =~/\/$/i) {
		if (($s->qparam('_run')||'') eq 'SEARCH') {
			$s->parent->user($ENV{REMOTE_USER}||$guest);
		}
		elsif (!defined($s->parent->{-w32IISdpsn})
			|| ($s->parent->{-w32IISdpsn} >1)) {
			$s->parent->user($ENV{REMOTE_USER}||$guest);
			$s->parent->w32IISdpsn();
		}
		else {
			$s->parent->user($ENV{REMOTE_USER}||$guest);
		}
	}
    elsif (!$s->parent->uguest()) {
       $s->signset(@_);
    }
    else {
       # 401 Access Denied
       # WWW-Authenticate: NTLM
       # WWW-Authenticate: Basic realm="194.1.1.32"
         push @$m, 'NTLM';
         push @$m, 'Basic realm="' .$s->surl .'"';
         print $s->cgi->header( #-nph=>1,
            -status=>'401 Access Denied'
          , -WWW_Authenticate => $m->[0] # [@m]
          , -Error =>'Authentication Required');
       # print "Status: 401 Access Denied\r\n";
       # print join("\r\n", map {'www-authenticate: ' .$_} @$m);
       # print "\r\nContent-Type: text/html; charset=ISO-8859-1\r\n";
       # print "error: Authentication Required\r\n\r\n";
         eval{$s->parent->reset()};
         exit;
    }
 }
 elsif (!$s->parent->uguest() && !$s->signchk()) {
    $s->signset(@_);
 }
 $s->parent->user()
}


sub _signrand {	# generate a random key
 my $c =$_[1] || 32;
 my @a =('.', '/', 0..9, 'A'..'Z', 'a'..'z');
 my $r ='';
 for (my $i =0; $i <$c; $i ++) {$r .=$a[rand(64)]}
 $r
}


sub _signmk {	# generate auth cookie data
 my ($s,$k) =(shift,shift);
 my $m =$s->{-digest} ||'MD5';
 eval('use Digest');
 return '' if $@;
 [@_[0..2], Digest->new($m)->add(
      Digest->new($m)->add($k .':' .join("\t", @_[0..2]))->hexdigest
      .':' .$k)->hexdigest]
}


sub signget {	# Get authentication cookie
 my $s =shift;
 my $c =[$s->cgi->cookie($cooknme)];
 return undef if !scalar(@$c) ||!defined($c->[0]) ||$c->[0] eq '';
 $c
}


sub signchk {	# Check authentication
 my $s =shift;
 my $c =$s->signget;
 return '' if !$c;
 my $u =$c->[0]; $s->die("Invalid authentication cookie user\n") if !$u;
 my $a =$c->[1]; $s->die("Invalid authentication cookie address\n") if $ENV{REMOTE_ADDR} && $a ne $ENV{REMOTE_ADDR};
 my $t =$c->[2]; $s->die("Invalid authentication cookie time\n") if !$t;
 $s->parent->udata->unload;
 $s->parent->user($u);
 my $d =$s->udata->param('-ses');
 my $v =$u;
 $v =undef if !$d || !$d->{$t} || !ref($d->{$t}) || !$d->{$t}->{-key};
 if ($v) {
    $s->die("Invalid authentication cookie session\n") if !$d || !$d->{$t} || !ref($d->{$t}) || !$d->{$t}->{-key};
    $v =$s->_signmk($d->{$t}->{-key}, @$c);
 }
 if (!$v) {
    $s->parent->udata->unload;
    $s->parent->user($guest);
    $s->parent->{-cache}->{-unames}  =undef;
    $s->parent->{-cache}->{-ugroups} =undef;
    $s->parent->{-cache}->{-ugnames} =undef;
    return ''
 }
 $s->die("Invalid authentication cookie signature\n") if $v->[3] ne $c->[3];
#$ENV{REMOTE_USER} =$u;
 $u;
}


sub signset {	# Set authentication
 my $s =shift;
 my $u =$ENV{REMOTE_USER}||''; $s->parent->user($u);
 my $c =[$u, $ENV{REMOTE_ADDR}||'', time];
 my $d =$s->parent->udata->param; $d->{-ses} ={} if !$d->{-ses};
 foreach my $k (sort {$a <=> $b} keys %{$d->{-ses}}) {
    delete $d->{-ses}->{$k} if (time -$k) >(60*60*24);
 }
 $d->{-ses}->{$c->[2]} ={-key=> $s->_signrand
                        ,-time=>$s->parent->strtime($c->[2])
                        ,-addr=>$c->[1]
                        };
 $c =$s->_signmk($d->{-ses}->{$c->[2]}->{-key}, @$c);
 return '' if !$c;
 $s->udata->store();
 my $r =shift ||$s->cgi->param($cooknme) ||$s->url; #||$ENV{HTTP_REFERER}
 my @p =(-uri=>$r
        ,-cookie=>[$s->cgi->cookie(-name=>$cooknme,-value=>$c,-path=>'/')]
        );
 push @p, (-nph=>1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/
                    || ($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER}); # PerlSendHeader Off
 $s->parent->print->redirect(@p);
 eval{$s->parent->reset};  # for mod_perl
 delete $ENV{REMOTE_USER}; # for mod_perl
 exit;
}



sub logout {	# Clear authentication
 my $s =shift;
 my $r =$_[0] ||$ENV{HTTP_REFERER};
 my @p =(-uri=>$r
        ,-cookie=>[$s->cgi->cookie(-name=>$cooknme,-value=>['',''],-path=>'/',-expires=>'-1d')]
        );
 push @p, (-nph=>1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/
                    || ($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER}); # PerlSendHeader Off
 $s->parent->print->redirect(@p);
 eval{$s->parent->reset};  # for mod_perl
 delete $ENV{REMOTE_USER}; # for mod_perl
 exit;
}




sub authurl {	# URL to authentication screen with return address
 my $s =shift;
 my $l =scalar(@_) >1 ? shift : ($s->{-login}||$s->parent->set('-login'));
 return '' if !$l;
 return $l .($s->qurl =~m{/([^/]+)$} ? $1 : '') if $l =~m{/$};
 $s->parent->htmlurl($l, $cooknme, shift ||($s->url .($ENV{QUERY_STRING} ? ('?' .$ENV{QUERY_STRING}) :'')));
}



sub authscr {	# User authentication screen
 my $s =shift;
 my $g =$s->cgi;
 $s->parent->userauth(@_);
 my $ha={-align=>'left',-valign=>'top'};
 my $back =$s->cgi->param($cooknme) ||$ENV{HTTP_REFERER};
 $s->print->htpgstart(undef,$s->parent->{-htpnstart});
 $s->print->h1($s->lng(0,'Authentication'));
 $s->print('<table><tr>');
 $s->print->th($ha,$s->lng(0,'UserName'))    ->td($ha,$s->htmlescape($s->parent->user))->text('</tr><tr>');
 $s->print->th($ha,$s->lng(0,'OriginalName'))->td($ha,$s->htmlescape($s->parent->useron))->text('</tr><tr>');
 $s->print->th($ha,$s->lng(0,'Cookie'))      ->td($ha,$s->htmlescape(join(', ',$s->cookie($cooknme))))->text('</tr><tr>');
 $s->print->th($ha,$s->lng(0,'Return'))      ->td($ha,$g->a({href=>$back}, $s->htmlescape($back)))->text('</tr><tr>');
 $s->print('</tr></table>');
 $s->print->htpgend;
}



sub loginscr {	# login via cgi screen
 my $s =shift;
 my $o =shift ||'-lir'; # login, info, register
 my $g =$s->cgi;
 my $rdr =$g->param($cooknme)||$ENV{HTTP_REFERER};
 my $u;
 my $d;
 if ($o !~/l/) {
     $g->param('UserInfo',1) if $o =~/i/; # user info dialog only
     $g->param('Register',1) if $o =~/r/; # register user dialog only
 }
 if (($g->param('Login') || $g->param('UserInfo'))
 && $g->param('user') && $g->param('passwd')) { 
    $u =$s->parent->user($g->param('user'));
    $s->parent->udata->load;
    $d =$s->parent->udata->param;
    $s->die("Wrong password\n") if ($d->{-passwd}||'') ne crypt($g->param('passwd'||''),$u);
    $ENV{REMOTE_USER} =$s->parent->useron;
    if   (!$g->param('UserInfo')) {$s->signset($rdr)}
    else {$s->signset($s->qurl('', $cooknme =>$rdr, 'UserInfo'=>1))}
    exit; # above always
 }
 if ($g->param('UserInfo') ||$g->param('Register')) {
    $s->print->htpgstart(undef,$s->parent->{-htpnstart});
    $s->print('<form method=post>');
    $s->print->hidden($cooknme, $rdr);
    $u ='';
    if ($g->param('UserInfo')) {
       $u =$s->signchk;
       $s->die("No user cookie\n") if !defined($u) ||$u eq '';
       $u =$s->parent->user($u);
     # $s->parent->udata->load; # in signchk
       foreach my $p (qw(email firstname middlename lastname fullname comment)) {
          $g->param($p => $s->udata->param("-$p"))
       }
    }
    $s->print->h1( $g->param('Register')
                 ? $s->lng(0,'Register')
                 : ($s->lng(0,'UserInfo') ." - $u"));
    $s->print->text('<table>');
    my $ha={-align=>'left',-valign=>'top'};
    my @hd=(-size =>30, '-name');
    my @ht=(-cols =>23, -rows=>4, '-name');
    $s->print->tr($g->th($ha,'UserName'),   $g->td($ha,$g->textfield(@hd,'user'))) 
        if $g->param('Register');
    $s->print->tr($g->th($ha,'EMail'),      $g->td($ha,$g->textfield(@hd,'email')));
    $s->print->tr($g->th($ha,'FirstName'),  $g->td($ha,$g->textfield(@hd,'firstname')));
    $s->print->tr($g->th($ha,'MiddleName'), $g->td($ha,$g->textfield(@hd,'middlename')));
    $s->print->tr($g->th($ha,'LastName'),   $g->td($ha,$g->textfield(@hd,'lastname')));
    $s->print->tr($g->th($ha,'FullName'),   $g->td($ha,$g->textfield(@hd,'fullname')));
    $s->print->tr($g->th($ha,'Comment'),    $g->td($ha,$g->textarea (@ht,'comment')));
    $s->print->tr($g->th($ha,'Password'),   $g->td($ha,$g->textfield(@hd,'passwd1')));
    $s->print->tr($g->th($ha,'Password'),   $g->td($ha,$g->textfield(@hd,'passwd2')));
    $s->print->tr($g->th($ha,'&nbsp;'),     $g->td($ha,$g->submit('Register1',$s->lng(0, 'Register'))))
        if $g->param('Register');
    $s->print->tr($g->th($ha,'&nbsp;'),     $g->td($ha,$g->submit('UserInfo1',$s->lng(0, 'Update'))))
        if $g->param('UserInfo');
    $s->print("</table>");
    $s->print->htpfend();
    eval{$s->parent->reset}; # for mod_perl
    exit;
 }
 if ($g->param('Register1') ||($g->param('UserInfo1') && !$s->parent->uguest)) {
    if ($g->param('Register1')) {
       $u =$s->parent->user($g->param('user'));
       $s->parent->udata->load;
       $s->die("User '$u' already registered\n") if $s->udata->param('-passwd') 
                                                 || $s->udata->param('-ses');
    }
    else {
       $u =$s->signchk;
       $u =$s->parent->user($u);
     # $s->parent->udata->load; # in signchk
    }
    $s->die("Passwords does not match\n") if  $g->param('passwd1') ne $g->param('passwd2')
                                          ||(!$g->param('passwd1') && $g->param('Register1'));
    $g->param('passwd', crypt($g->param('passwd1'),$u)) if $g->param('passwd1');
    foreach my $p (qw(email firstname middlename lastname fullname comment passwd)) {
       $s->udata->param("-$p", $g->param($p));
    }
    $s->parent->udata->store;
    $ENV{REMOTE_USER} =$s->parent->useron;
    $s->signset($rdr);
 }
 if (1) {
    $s->print->htpgstart(undef,$s->parent->{-htpnstart});
    $s->print('<form method=post>');
    $s->print->h1('Authentication required');
    $s->print->hidden($cooknme, $rdr);
    my $ha={-align=>'left',-valign=>'top'};
    $s->print('<table><tr>')
      ->th($ha, 'UserName')
      ->td($ha, $g->textfield('user'))
      ->text('</tr><tr>')
      ->th($ha, 'Password')
      ->td($ha, $g->password_field('passwd'))
      ->text('</tr><tr>')
      ->th($ha, '&nbsp;')
      ->td($ha, $g->submit('Login','Login')
              .($o =~/i/ ? $g->submit('UserInfo',$s->lng(0, 'UserInfo')) :'') 
              .($o =~/r/ ? $g->submit('Register',$s->lng(0, 'Register')) : ''))
      ->text('</tr></table>');
    $s->print->htpfend;
    eval{$s->parent->reset}; # for mod_perl
    exit;
 }
 $s
}


