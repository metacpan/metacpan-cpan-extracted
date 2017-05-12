#!perl -w
#
# CGI::Bus::wg - HTML Widgets
#
# admiral 
#
# 

package CGI::Bus::wg;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA $AUTOLOAD);
@ISA =qw(CGI::Bus::Base);


1;


#######################


sub ddlb {     # Drop-Down List Box - Input helper
 my ($s,$w,$n,$ds) =(shift
	#,!$_[0] || $_[0] =~/^(?:<|\$_|\s)/ || $_[0] =~/(?:>|\$_|\s)$/ ? shift : undef
	,shift
	,shift, shift);
 my $x; if (ref($n)) {$x =$n; $n =$x->{-name}}
 my $g =$s->cgi;
 my $r ='';
 if ($g->param($n .'_B')) {
    my $ff =(ref($_[0]) ? $_[0]->[0] : $_[0]);
    my $fs =sub{
	'{var k;'
	."var l=window.document.forms[0].${n}_L;"
	.(!$_[0]
	? "k=window.document.forms[0].$ff.value +String.fromCharCode(window.event.keyCode);"
	: $_[0] eq '1'
	# ? "k=window.document.forms[0].$ff.value +=String.fromCharCode(window.event.keyCode);"
	# ? "window.document.forms[0].$ff.fireEvent(\"onkeypress\"); k=window.document.forms[0].$ff.value;"
	? "window.document.forms[0].$ff.focus(); k=window.document.forms[0].$ff.value =String.fromCharCode(window.event.keyCode); "
	: $_[0] eq '2'
	? "k=prompt('Enter search string',String.fromCharCode(window.event.keyCode));"
	# $_[0] eq '3'
	: "k=prompt('Enter search substring',''); ${n}_L.focus();"
	)
	.'if(!k){return(false)}; k=k.toLowerCase();'
	.'for (var i=0; i <l.length; ++i) {'
	.($g->user_agent('MSIE')
	?'if (l.options.item(i).value.toLowerCase().indexOf(k)'
		.($_[0] eq '3' ?'>=' :'==') .'0 || l.options.item(i).innerText.toLowerCase().indexOf(k)'
		.($_[0] eq '3' ?'>=' :'==') .'0){'
	:'if (l.options.item(i).value.toLowerCase().indexOf(k)'
		.($_[0] eq '3' ?'>=' :'==') .'0){')
	.'l.selectedIndex =i; break;}}'
	.($_[0] ? 'return(false);' : '')
	.'}'};
    if ($ff !~/^\t/ && $w) {
	$r .='<script for="' .$ff 
	.'" event="onkeypress()" >' .&$fs(0) .'</script>';
    }
    $r .=$w if $w;
    $r .=$g->submit(($x ? (%$x) : ())
		,-name=>($n .'_C')
		,-value=>$s->lng(0,'ddlbclose')
		,-title=>$s->lng(1,'ddlbclose'));
    $r .='<br />';
    $ds = &$ds($s) if ref($ds) eq 'CODE';
    my $dl;
    if (ref($ds) eq 'HASH') {
	$dl =$ds;
	$ds =do{use locale; [sort {lc($ds->{$a}) cmp lc($ds->{$b})} keys %$ds]};
	foreach my $k (keys %$dl) {$dl->{$k} =substr($dl->{$k},0,60) .'...' if length($dl->{$k}) >60}
    }
    $r .=$g->scrolling_list(($x ? (%$x) : ())
		,-name=>($n .'_L')
		,-values=>$ds
		,-labels=>$dl
		,-size=>(scalar(@$ds) <10 ? scalar(@$ds) : 10)
		,-onDblClick=>"{${n}_L.nextSibling.nextSibling.click();"
			.($ff !~/^\t/ && scalar(@_) >1 ? ' submit();' : '')
			.' return(false)}'
		,($ff !~/^\t/ && $w 
		? (-onKeyPress=>&$fs(1))
		: ())
		,-default=> 0 ? '' : $ff !~/^\t/ ? $g->param($ff) : ''
		);
    chomp($r);
    $r .='<br />';
    if (scalar(@_) == 1 && $ff !~/^\t/) {
       $r .=$g->submit(($x ? (%$x) : ())
		,-name=>($n .'_S')
		,-value=>'<' 
		.(ref($_[0]) ?($_[0]->[1] || $_[0]->[0]) :($_[0] || ''))
		,-title=>$s->lng(1,'ddlbsetvalue'));
    }
    else {
       foreach my $ff (@_) {
          next if !$ff;
	  my ($fn, $l) =ref($ff) ? (@$ff) : ($ff, '');
	  next if !$fn;
	  my $wn =($fn =~/([^\t]+)$/ ? $1 : $fn);	# /^\t(.*)/
	  $l =scalar(@_) ==1 ? '' : $wn if !$l ||($l eq $fn);
          $r .=
          $g->button(($x ? (%$x) : ())
	   ,-name=>''
	   ,-value=>(($fn !~/^\t/ ? '<' : '<+') .$l)
           ,-onClick=>	 "var fs =window.document.forms[0].${n}_L; "
			."var ft =window.document.forms[0].$wn; "
			."var i  =fs.selectedIndex; "
           .($g->user_agent('MSIE') 
            ?($fn !~/^\t/ ? "ft.value =(fs.options.item(i).value ==\"\" ? fs.options.item(i).text : fs.options.item(i).value); "
              : "ft.value =(ft.value ==\"\" ? \"\" : (ft.value +\", \")) +(fs.options.item(i).value ==\"\" ? fs.options.item(i).text : fs.options.item(i).value); ")
            :($fn !~/^\t/ ? "ft.value =fs[i].value; "
              : "ft.value =(ft.value ==\"\" ? \"\" : (ft.value +\", \")) +fs[i].value; ")
             )
           ,-title=>$s->lng(1,'ddlbsetvalue'));
       }
    }
    $r .=$g->button(($x ? (%$x) : ())
		,-name=>''
		,-value=>$s->lng(0,'ddlbfind')
		,-title=>$s->lng(1,'ddlbfind')
		,-onClick=>&$fs(3));
    $r .=$g->submit(($x ? (%$x) : ())
		,-name=>($n .'_C')
		,-value=>$s->lng(0,'ddlbclose')
		,-title=>$s->lng(1,'ddlbclose'));
    $r .='<script for="window" event="onload">{'
	# .'window.scrollTo(window.document.forms[0].' .$n .'_L, window.screenTop);'
	.(0 && $ff !~/^\t/ && $w && defined($g->param($ff)) && ($g->param($ff) ne '')
	? "window.document.forms[0].${ff}.select(); window.document.forms[0].${ff}.focus();"
	: "window.document.forms[0].${n}_L.focus();"
	).'}</script>';
 }
 else {
    $g->param(ref($_[0]) ? $_[0]->[0] : $_[0], $g->param($n .'_L')) 
        if scalar(@_) == 1 && $g->param($n .'_S');
    $r .=$w if $w;
    my $fn =(ref($_[0]) ?($_[0]->[0] || $_[0]->[1]) :($_[0] || ''));
    my $wn =($fn =~/([^\t]+)$/ ? $1 : $fn);
    $r .="<script language=\"jscript\"></script><script language=\"VBScript\">
	function ${n}_O_O(fldnme)
	Dim Users1
	Dim t
	Dim item
	Dim field
	${n}_O_O =\"\"
	On Error Resume Next
	rem EnsureImport()
	Set field =Document.getElementsByName(fldnme)(0)
	Set t = CreateObject(\"MsSvAbw.AddrBookWrapper\")
	if Err <> 0 then
		Err.Clear
		set t = CreateObject(\"MsoSvAbw.AddrBookWrapper\")
	end if
	if IsObject(t) then
		t.AddressBook \"Microsoft Address Book\", 1, \"\", \"\", \"\", Users1
		if Err = 0 or Err <> 0 then
			For each item in Users1
				if len(field.value) <> 0 then
					field.value =field.value & \", \" & item.SMTPAddress
				else
					field.value =item.SMTPAddress
				end if
			Next
			rem MsgBox(field.value)
			${n}_O_O =\"fldnme\"
		else
			MsgBox(\"Error=\" & Err.Description)
			Err.Clear
		end if
	end if
	End function"
	."</script><script language=\"jscript\"></script>"
    if ($fn =~/msab\t/) && $g->user_agent('MSIE');
    $r .=$g->submit(($x ? (%$x) : ())
		,-name=>($n .'_B')
		,-value=>$s->lng(0,'ddlbopen')
		,-title=>$s->lng(1,'ddlbopen')
		,($fn =~/msab\t/) && $g->user_agent('MSIE')
			? (-OnClick=>"if(${n}_O_O('$wn')) {return(false)};")
			: ()
		);
    $r .='<script for="window" event="onload">{'
	.'window.document.forms[0].' .$n .'_B.focus();}</script>'
	if ($g->param($n .'_S') ||$g->param($n .'_C'));
 }
 $r
}


sub textfield {# Text filed with autosizing
 my $s =shift;
 my %a =@_;
 my $v =exists($a{-default}) ? $a{-default} : $s->qparam($a{-name});
    $v ='' if !defined($v);
 if ($a{-asize}) {
     $a{-size} =($a{-asize} >length($v) ? $a{-asize} :length($v));
     delete $a{-asize};
 }
 $s->cgi->textfield(%a)
}


sub textarea { # Text Area with autorowing and hrefs
 my $s =shift;
 my %a =@_;
 my $r ='';
 my $r1='';
 my $v =exists($a{-default}) ? $a{-default} : $s->qparam($a{-name});
    $v ='' if !defined($v);
 if ($a{-htmlopt}) {
	delete $a{-htmlopt};
	my $n =$a{-name};
#	$r1 .="<input type=\"submit\" name=\"${n}__b\" value=\"R\" "
#		."title=\"Rich/Text edit: ^Bold, ^Italic, ^Underline, ^Link, Enter/shift-Enter, ^(shift)T ident, ^Z undo, ^Y redo.\nSwitch to 'T'ext before saving!!!\" "
#		."style=\"font-style: italic;\" "
#			# ; font-weight: bold; font-family: fantasy
#		."onclick=\"{if(${n}__b.value=='R') {${n}__b.value='T'; ${n}__r.DocumentHTML=$n.value ? $n.value : ''; $n.style.display='none'; ${n}__r.style.display='inline'; ${n}__r.width='100%'; ${n}__r.height=250 }\n"
#		."else {var r; ${n}__b.value='R'; r=${n}__r.DocumentHTML.match(/&lt;BODY&gt;[\\s]*([\\s\\S]*)[\\s]*&lt;\\/BODY&gt;/); "
#		."$n.value=r ? r[1] : ${n}__r.DocumentHTML; ${n}__r.style.display='none'; $n.style.display='inline';};\n"
#		." return(false)}\" />\n"
#		."<object classid=\"clsid:2D360201-FFF5-11d1-8D03-00A0C959BC0A\" id=${n}__r height=\"100%\" width=\"250\" style=\"display: none;\" name=\"${n}__r\" title=\"DHTML Editing Component\"></object>\n"
#		#DHTML Edit Control for IE5, DHTML Editing Component, HTMLRichtextElement:
#		#http://msdn.microsoft.com/archive/default.asp?url=/archive/en-us/dnaredcom/html/dhtmledit.asp
#		if $n && ($ENV{HTTP_USER_AGENT}||'') =~/MSIE/;
#	$r1 .="<input type=\"submit\" name=\"${n}__b\" value=\"R\" "
#		."title=\"Rich/Text edit: ^Bold, ^Italic, ^Underline, ^Link, Enter/shift-Enter, ^(shift)T ident, ^Z undo, ^Y redo.\nSwitch to 'T'ext before saving!!!\" "
#		."style=\"font-style: italic;\" "
#			# ; font-weight: bold; font-family: fantasy
#		."onclick=\"{if(${n}__b.value=='R') {$n.rows='1'; ${n}__b.value='T'; "
#		."\n var r; r =document.createElement('<object classid=&quot;clsid:2D360201-FFF5-11d1-8D03-00A0C959BC0A&quot; id=&quot;${n}__r&quot; height=&quot;250&quot; width=&quot;100%&quot; name=&quot;${n}__r&quot; title=&quot;DHTML Editing Component&quot ></object>'); ${n}__b.parentNode.appendChild(r);\n"
#		."r.normalize; r.Refresh; r.DocumentHTML=$n.value ? $n.value : '';}\n"
#		."else {var r; ${n}__b.value='R'; r=${n}__r.DocumentHTML.match(/&lt;BODY&gt;[\\s]*([\\s\\S]*)[\\s]*&lt;\\/BODY&gt;/); "
#		."$n.value=r ? r[1] : ${n}__r.DocumentHTML; ${n}__r.removeNode(true); $n.rows='6'};\n"
#		." return(false)}\" />\n"
#		#DHTML Edit Control for IE5, DHTML Editing Component, HTMLRichtextElement:
#		#http://msdn.microsoft.com/archive/default.asp?url=/archive/en-us/dnaredcom/html/dhtmledit.asp
#		if $n && ($ENV{HTTP_USER_AGENT}||'') =~/MSIE/;
	$r1 .="<input type=\"submit\" name=\"${n}__b\" value=\"R\" "
		.($a{-class} ? 'class="' .$a{-class} .'" ' : '')
		."title=\"Rich/Text edit: ^Bold, ^Italic, ^Underline, ^hyperlinK, Enter/shift-Enter, ^(shift)T ident, ^Z undo, ^Y redo.\" "
		."style=\"font-style: italic;\" "
		."onclick=\"{if(${n}__b.value=='R') {${n}__b.value='T'; $n.style.display='none'; "
		."\n var r; r =document.createElement('<span contenteditable=true id=&quot;${n}__r&quot; title=&quot;MSHTML Editing Component&quot; ondeactivate=&quot;{$n.value=${n}__r.innerHTML}&quot;></span>'); ${n}__b.parentNode.insertBefore(r,$n);\n"
		# r.execCommand('Font', 1)
		."r.contentEditable='true'; r.style.borderStyle='inset'; r.style.borderWidth='thin'; r.normalize; r.innerHTML =$n.value ? $n.value : ' '; r.focus();}\n"
		."else {${n}__b.value='R'; $n.value=${n}__r.innerHTML ? ${n}__r.innerHTML : ''; ${n}__r.removeNode(true); $n.style.display='inline'; $n.focus();};\n"
		." return(false)}\" />\n"
		#MSHTML Edit Control for IE5.5
		if $n && ($ENV{HTTP_USER_AGENT}||'') =~/MSIE/;
 }	
 if ($a{-arows}) {
    my $h =0;
    $a{-cols} =20 if !$a{-cols};
    if ($a{-wrap} && lc($a{-wrap}) eq 'off') {
          my @a =split /\n/, $v;
          $h =scalar(@a)
    }
    else {
       foreach my $r (split /\n/, $v) {
          $h +=1 +(length($r) >$a{-cols} ? int(length($r)/$a{-cols}) +1 :0);
       }
    }
    $a{-rows} =($a{-arows} >$h ? $a{-arows} : $h);
    $a{-rows} =30 if $a{-rows} >30;
    delete $a{-arows}
 }
 if (defined($a{-hrefs})) {
    my $v =$v;
    my @h;
    while ($v =~/\b([\w-]{3,7}:\/\/[^\s\t,()<>\[\]"']+[^\s\t.,;()<>\[\]"'])/) {
       my $t =$1;
       $v =$';
       $t =~s/^(host|urlh):\/\//\//;
       $t =~s/^(url|urlr):\/\//$s->url(-relative=>1)/e;
       push @h, $t;
    }
    $r .=join(';&nbsp; '
		,map {$s->a({-href=>$_, -target=>'_blank', -title=>$_}
			,$s->htmlescape(length() >49 ? substr($_,0,47) .'...' : $_))
			} @h);
    $r .='<br />' if $r;
    delete $a{-hrefs};
 }
 $r .=$s->cgi->textarea(%a);
 $r .=$r1;
 $r
}


sub fsdir {	# Filesystem dir field
		# name,edit,path,URL,URF,rows,cols
 my ($s, $nm, $ed, $ea, $fp, $fu, $fr, $sr, $sc) =@_;
 my $x; if (ref($nm)) {$x =$nm; $nm =$x->{-name}};
 my $p =$s->parent;
 my ($nml, $nma, $nmu, $nmc, $nmo) =("${nm}_l", "${nm}_d", "${nm}_u", "${nm}_c", "${nm}_o");
 my $r =$p->cgi->a({-href=>$fr||$fu,-target=>'_blank',-title=>$p->htmlescape($s->lng(1,'Files'))}
		, $p->{-iurl}
		? ('<img border="0" src="' .$p->{-iurl} .'/folder.open.gif" />')
		: ('<strong>' .$p->htmlescape($s->lng(0,'Files')) ."&nbsp;&nbsp;&nbsp;</strong>")
		) ."\n";	
 my $fo=undef;
	$s->_fsclose($fp, [$p->cgi->param($nmc)])
		if $ed && $p->cgi->param($nmc);
	$fo = $ed && ($p->cgi->param($nmc)||$p->cgi->param($nmo)) && $s->_fsopens($fp,{});
 if (1 && $p->urfcnd && $ed && $fr) {
    $r .=$p->cgi->submit(($x ? (%$x) : ())
		,-name=>$nmo
		,-value=>$s->lng(0,'fsopens')
		,-title=>$s->lng(1,'fsopens')) ."\n"
		if !$fo && $^O eq 'MSWin32';
    $r .="<br />"
	.$p->cgi->scrolling_list(($x ? (%$x) : ())
		, -name=>$nmc, -override=>1, -multiple=>'true'
		, -values=>	['---' .$s->lng(0,'fsclose') .'---'
				,ref($fo) eq 'HASH' ? sort keys %$fo : @$fo]
		, ref($fo) eq 'HASH' ? (-labels=>$fo) : ()
		)
        .$p->cgi->submit(($x ? (%$x) : ())
			,-name=>$nma
			,-value=>$s->lng(0,'fsclose')
			,-title=>$s->lng(1,'fsclose')) ."\n"
		if $fo;
    if ($ed && $fr && $fr =~/^file:(.*)/i) {
	my $fs =$1; $fs =~s/\//\\/g;
	$r .='<span style="font-size: smaller;" '
	#.' onclick="window.event.srcElement.select" '
	#.' ondblclick="{window.clipboardData.setData(\'Text\',' .$p->htmlescape($fs) .'\'); return(false)}" '
	# window.event.srcElement
	# document.selection.empty(); 
	.' title="' .$p->htmlescape($s->lng(1,'Files') .' ') .'" '
	.'><sub>' 
	.$p->htmlescape($fs) ."</sub></span>"
    }
    $r .="<br />\n";
  # !!! filefield may be useful to attach files, but file creation time will not be saved !!!
  # $r .=$p->cgi->filefield(-name=>$nmu);
  # $s->_fsdirupload($nmu, $fp) if $ea && $p->cgi->param($nmu);
    $r .='<iframe scrolling="auto" src="' .$p->htmlescape($fr) .'"';
    $r .=' application="yes"';
    $r .=' height="' .$sr .'"' if $sr;
    $r .=' width="'  .$sc .'"' if $sc;
    $r .='> </iframe>';
    return $r;
 }
 my $fb =$p->urfcnd && $ed ? ($fr ||$fu) : ($fu ||$fr);
 if (!$ed) {
    my $fl =join(",\n"
           , map {$p->cgi->a({-href=>"$fb/$_", -target=>'_blank'
			}, $p->htmlescape($_))} 
             eval{$p->fut->globn("$fp/*")}
           );
    $r .=$fl ."\n" if $fl;
    my  $fd;
    if ($fd =$p->orarg('-f',"$fp/index.html","$fp/index.htm")) {
     my $fn =($fd =~/([^\\\/]+)$/ ? $1 : $fd);
     #  $fd ='<embed scr="' ."$fb/$fn" .'" height=100% width=100% />';
     #  $fd ='<iframe scroling="auto" src="' .$p->htmlescape("$fb/$fn") .'" width=100% height=100%></iframe>';
        $fd =$p->fut->fload('-b',$fd);
        $fd =$' if $fd =~m/<body\b[^>]*>/i;
        $fd =$` if $fd =~m/<\/body\b/i;
        $fd ='<base href="' .($fb =~/:\/\// ? $fb : $p->surl($fb)) .'/" />' .$fd if $fd !~m/<base\b/i; # !!! May be a problem
        $r .='<hr />' .$fd .'<br />';
    }
 }
 elsif ($ed) {
    $s->_fsdirupload($nmu, $fp) if $ea && $p->cgi->param($nmu);
    if ($ea && $p->cgi->param($nma)) {
       foreach my $fn ($p->cgi->param($nml)) {
         $p->fut->delete('-r',"$fp/$fn");
       }
    }
    $r .=$p->cgi->filefield(($x ? (%$x) : ()), -name=>$nmu, -title=>$s->lng(1,'fsbrowse'));
    $r .=$p->cgi->submit(($x ? (%$x) : ()), -name=>$nma, -value=>$s->lng(0,'+|-'), -title=>$s->lng(1,'+|-'));
    $r .=$p->cgi->submit(($x ? (%$x) : ()), -name=>$nmo, -value=>$s->lng(0,'fsopens'), -title=>$s->lng(1,'fsopens'))
		if !$fo && $^O eq 'MSWin32';
    $r .=$p->cgi->scrolling_list(($x ? (%$x) : ())
		, -name=>$nmc, -override=>1, -multiple=>'true'
		, -values=>	['---' .$s->lng(0,'fsclose') .'---'
				,ref($fo) eq 'HASH' ? sort keys %$fo : @$fo]
		, ref($fo) eq 'HASH' ? (-labels=>$fo) : ()
		) ."\n"
		if $fo;
    if ($ed && $fr && $fr =~/^file:(.*)/i) {
	my $fs =$1; $fs =~s/\//\\/g;
	$r .='<span style="font-size: smaller;" '
	.' title="' .$p->htmlescape($s->lng(1,'Files') .' ') .'" '
	.'><sub>' 
	.$p->htmlescape($fs) ."</sub></span>"
    }
    $r .="<br />\n"; # $r .="\n&nbsp;&nbsp;&nbsp;\n";
    
    foreach my $fn (eval{$p->fut->globn("$fp/*")}) {
       $r .=$p->cgi->a({-href=>"$fb/$fn", -target=>'_blank'}
           ,$p->cgi->checkbox(($x ? (%$x) : ()), -name=>$nml, -value=>$fn, -label=>$fn, -title=>$s->lng(1,'fsdelmrk')))
          ."&nbsp;&nbsp;&nbsp;\n";
    }
 }
 $r
}


sub _fsdirupload { # Filesystem dir field file upload
 my ($s, $nmu, $fp) =@_;
 my $fa =$s->cgi->param($nmu);
 if ($fa) {
    my $fn =$fa =~/[\\\/]([^\\\/]+)$/ ? $1 : $fa;
    my $fh =$s->cgi->upload($nmu);
    if ($fh) {
       $s->pushmsg("upload '$fn' from '$fa'");
       binmode($fh);
       eval('use File::Copy');
       File::Copy::copy($fh, "$fp/$fn")
       ||$s->die("Upload '$fn' from '$fa': $!\n");
       close($fh);
    }
    else {
      $s->die("Empty filehandle '$fn' from '$fa': " .($!||$@||'') ."\n");
    }
 }
}


sub _fsopens {	# opened files (`net file`; NetFileEnum; IADsResource, IADsFileServiceOperations)
		# (mask, ?container)
 return(undef) if $^O ne 'MSWin32';
 my $rc	=$_[2]||[];
 my $mask =$_[1]||''; $mask =~s/\//\\/ig;
 my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); Win32::OLE->GetObject("WinNT://'
	.(eval{Win32::NodeName()}||$ENV{COMPUTERNAME}) .'/lanmanserver")');
 return(undef) if !$o;
 if (ref($rc) eq 'HASH') {
	%$rc =map {(substr($_->{Path}, length($mask)+1), $_->{User} .': ' .substr($_->{Path}, length($mask)+1))
		} grep {(eval{$_->{Path}}||'') =~/^\Q$mask\E/i
			} Win32::OLE::in($o->Resources());
	# %$rc =(1=>'1.1',2=>'2.1',3=>'3.1');
	$rc =undef if !%$rc
 }
 else {
	@$rc =map {eval{substr($_->{Path}, length($mask)+1)}
		} grep {(eval{$_->{Path}}||'') =~/^\Q$mask\E/i  # $_->GetInfo;
			} Win32::OLE::in($o->Resources());
	$rc =undef if !@$rc
 }
 $rc
}


sub _fsclose {	# close opened files (`net file /close`)
		# (mask, [files])
 return(0) if $^O ne 'MSWin32';
 my $mask =$_[1]||''; $mask =~s/\//\\/ig;
 my $list =$_[2]||[];
 my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); Win32::OLE->GetObject("WinNT://'
	.(eval{Win32::NodeName()}||$ENV{COMPUTERNAME}) .'/lanmanserver")');
 return(0) if !$o;
 foreach my $f (grep {$_ && (eval{$_->{Path}}||'')=~/^\Q$mask\E/i
			} Win32::OLE::in($o->Resources())) {
	my $n =eval{$f->{Path} =~/^\Q$mask\E[\\\/]*(.+)/i ? $1 : undef};
	next if !$n || !grep /^\Q$n\E$/i, @$list;
	$_[0]->oscmd('net','file',$f->{Name},'/close');
 }
 1
}

