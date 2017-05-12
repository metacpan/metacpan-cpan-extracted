#!perl -w
#
# CGI::Bus - CGI Application Object Model
#
# admiral 
#


package CGI::Bus;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
$VERSION = '0.62';

use vars qw($SELF);

$SELF =undef;

if ($ENV{MOD_PERL}) { # $ENV{GATEWAY_INTERFACE} && $ENV{GATEWAY_INTERFACE} =~/^CGI-Perl\//
   eval('use Apache qw(exit);');
 # *exit =\&Apache::exit;
}

1;


#######################

sub new {
 my $c=shift;
 my $s ={};
 bless $s,$c;
 $s =$s->initialize(@_);
}


sub fcgicount {
 my $s =shift;
 if    (!ref($s))   {$s =CGI::Bus->new(@_)} # while (fcgicount) {}
 elsif (scalar(@_)) {$s =CGI::Bus->new(@_)} # while (fcgicount) {}
 else               {}                      # while(1) {new ;,,, last if !fcgicount}
 return(undef) if !$s->{-cgi};
 $s->{-fcgicount} =($s->{-fcgicount} ||0) +1;
 return(undef) if $s->{-fcgicount} >($s->{-fcgimax}||0);
 $s;
}


sub initialize {
 my $s =shift;
 local $SELF =$s;
 if (ref($_[0]) && eval{$_[0]->isa('CGI::Bus')}) { # reuse
   my $r =shift;     # reuse object
   $r->reset($s->{-reset});
   $s  =$r;          # in doubt 
   $s->{-cache} ={}; # -> reset?
   foreach my $k (qw(-cgi -qpath -qurl)) {
     $s->{$k} =undef;
   }
 }
 else {
   shift if !defined($_[0]);
   %$s =(
    -classes    =>{}              # Classes to autocreate Objects
  #,-import     =>{}              # add Classes or Methods & Packages
   ,-reset      =>{}              # Slotes to destroy on reuse
   ,-endh	=>{}		  # End handlers, used in 'reset'
  #,-reimport   =>{}              # add Classes {} or Slotes [] to reset
   ,-debug      =>0               # Debug Mode
   ,-problem    =>undef           # Current problem set by problem()
   ,-cache      =>{               # Data cache
   #,-lngbase   =>undef           # Language messages base
   #,-pushmsg   =>undef           # Messages to accumulate and display
   #,-qrun      =>undef           # Query to run
   #,-user      =>undef           # Current user name
   #,-usdomain  =>undef           # Server's User Domain
   #,-unames    =>undef           # User names list
   #,-ugroups   =>undef           # User groups list
   #,-ugnames   =>undef           # User and groups names list
   #,-httpheader=>undef           # HTTP header output from print->httpheader()
   #,-htmlstart =>undef           # HTML start output from print->htmlstart()
   #,-htpgstart =>undef           # HTML page begin output from print->htpgstart()
    }              
   ,-lngname    =>undef           # Name and charset of the language to use
   ,-pushlog    =>undef           # Log file name

   ,-cgi        =>undef           # CGI predefined object
  #,-fcgimax    =>undef           # CGI::Fast requests max
  #,-fcgicount  =>undef           # CGI::Fast requests counter
   ,-dbi        =>undef           # DBI predefined object

  #,-qpath      =>undef           # Query (script) Path
  #,-qurl       =>undef           # Query (script) URL
  #,-spath      =>undef           # Site Path
  #,-surl       =>undef           # Site URL
  #,-bpath      =>undef           # Binary Path
  #,-burl       =>undef           # Binary URL
  #,-dpath      =>undef           # Data Path
  #,-tpath      =>undef           # Temporary Files Path
  #,-ppath      =>undef           # Publish Path
  #,-purl       =>undef           # Publish URL
  #,-fpath      =>undef           # Files Store Path
  #,-furf       =>undef           # Files Store file URL
  #,-furl       =>undef           # Files Store URL
  #,-hpath      =>undef           # Homes Store Path
  #,-hurf       =>undef           # Homes Store file URL
  #,-hurl       =>undef           # Homes Store URL
  #,-urfcnd     =>undef           # URFs condition sub{}
  #,-iurl       =>undef           # Apaceh Images URL '/images'

  #,-user       =>undef           # User name get optional sub
  #,-usdomain   =>undef           # Server's User Domain optional sub
  #,-ugroups    =>undef           # User groups list optional sub
  #,-usercnv    =>undef           # User/Group names convertor optional sub
  #,-ugrpcnv    =>undef           # User/Group names convertor optional sub
  #,-userauth   =>undef           # User authentication optional sub
  #,-uadmins    =>undef           # Administrators list
  #,-w32IISdpsn	=>($ENV{SERVER_SOFTWARE}||'') =~/IIS/ ? 2 : 0 # MsIIS deimpersonation

  #,-httpheader =>undef           # HTTP header hash ref, for httpheader()
  #,-htmlstart  =>undef           # HTML start hash ref, for htmlstart()
  #,-htpnstart  =>undef           #      Navigator pane HTML start
  #,-htpgstart  =>undef           #      HTML page HTML start
  #,-htpfstart  =>undef           #      HTML form HTML start
  #,-htpgtop    =>undef           # HTML page begin, for htpgstart()
  #,-htpgend    =>undef           # HTML page end, for htpgend() 
   );
 }
 $s->set(@_);
 if ($ENV{MOD_PERL}) {
    Apache->push_handlers("PerlCleanupHandler"
           ,sub{eval{$s->reset}; eval('Apache::DECLINED;')}); # or '$s->reset' at the bottom of scripts
 }
 if (!$s->{-cgi}) {
    eval('use CGI::Fast') if $s->{-fcgimax};
    eval('use CGI qw(-no_xhtml);');
  # $CGI::POST_MAX =-1;                                 # default in CGI.pm 
  # $MultipartBuffer::INITIAL_FILLUNIT =1024*4;         # default in CGI.pm 
    local $ENV{CONTENT_TYPE} ='multipart/form-data'     # !!! fix CGI.pm: $boundary = "--$boundary" unless CGI::user_agent('MSIE\s+3\.0[12];\s*Mac')
      if ($ENV{CONTENT_TYPE}||'') =~m|^multipart/form-data|
      && !$ENV{MOD_PERL}; # !!! beter to read boundary from input, but CGI.pm BUG: This won't work correctly under mod_perl
  # $s->pushmsg($ENV{CONTENT_TYPE});
    no warnings;
    $s->{-cgi} =(!$s->{-fcgimax} ? eval('CGI->new') : eval('CGI::Fast->new'))
               ||CGI::Carp::croak("'CGI->new' failure: $@\n");
    $CGI::Q =$s->{-cgi};
    $CGI::XHTML =0;
    if ((($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
	||  ($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER})) {
	$CGI::NPH =1;
    }
#CGI quote:
#die "Malformed multipart POST: "
#.'boundary: ' .$self->{BOUNDARY} ."***\n"
#.'buffer: ' .$self->{BUFFER} ."***\n"
#." start=$start; selflen=" .$self->{LENGTH} .'; '
#.join(',', map {($_=>$ENV{$_}||'')} qw (REQUEST_METHOD REQUEST_URI CONTENT_TYPE CONTENT_LENGTH))
#unless ($start >= 0) || ($self->{LENGTH} > 0);
 }
 $s
}


sub class {
 substr($_[0], 0, index($_[0],'='))
}


sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($s, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $s->{$k} =$opt{$k};
 }
 my $h;
 if ($h =$opt{-import}) {    # Import Classes or Methods and Packages
    delete $s->{-import};
    foreach my $k (keys %$h) {
      my $l =  $h->{$k};
      if    (ref($l) eq 'HASH') {  # 'use...'=>{-method=>call,...},...
         my $p =$k =~/^([^\;\s\(]+)/ ? $1 : $k;
         foreach my $c (keys %$l) {
           my $m =$l->{$c};
           $s->{$m} =
             sub{$s->{$m} =eval("use $k; \\\&$p::$c");
                 eval("use $k; &$p::$c(\@_)")}
         }
      }
      elsif (ref($l) eq 'ARRAY') { # 'use...'=>[method,...],...
         my $p =$k =~/^([^\;\s\(]+)/ ? $1 : $k;
         foreach my $m (@$l) {
           $s->{"-$m"} =
             sub{$s->{"-$m"} =eval("use $k; \\\&$p::$m"); 
                 eval("use $k; &$p::$m(\@_)")}
         }
      }
      else {                       # -key=>class,....
         $s->{-classes}->{$k} =$h->{$k}
      }
    }
 }
 if ($h =$opt{-reimport}) {  # Reset or Load Classes
    delete $s->{-reimport};
    if    (ref($h) eq 'HASH') {    # {-key=>class,...}
       foreach my $k (keys %$h) {
         $s->{-classes}->{$k} =$h->{$k}; 
         $s->{-reset}->{$k} =1
       }
    }
    elsif (ref($h) eq 'ARRAY') {   # [-key,...]
       foreach my $k (@$h) {$s->{-reset}->{$k} =1}
    }
    else {                         #  -key
       $s->{-reset}->{$h} =1;
    }
 }
 if ($opt{-debug}) {
	$SIG{__WARN__} =sub{return if $^S;
	eval{$s->pushmsg('WARN: ' .($_[0] =~/(.+)[\n\r]+$/ ? $1 : $_[0]))}};
 }
 $TempFile::TMPDIRECTORY =$opt{-tpath} # use CGI
		if $opt{-tpath}
		&& ((-d $opt{-tpath}) ||$s->fut->mkdir($opt{-tpath}));
 $s
}


sub reset {
 my $s =shift;
 local $SELF =$s;
 my $v =!scalar(@_)
	? $s->{-reset}
	:ref($_[0]) eq 'ARRAY'
	? {map {$_=>1} @{$_[0]}}
	:$_[0];
 foreach my $k (sort keys %{$s->{-endh}}) {
	eval{&{$s->{-endh}->{$k}}($s)}
 }
 $s->{-endh} ={};
 foreach my $k (keys %$v) {
	my $o =$s->{$k};
	my $t =ref($o);
	next if !$t || $t eq 'HASH' || $t eq 'ARRAY';
	delete $s->{$k};
	eval {$o->DESTROY()};
	eval {delete $o->{'CGI::Bus'} if ref($o) && $o->isa('HASH')};
 }
 $SELF =undef;
 if (!scalar(@_) && $ENV{MOD_PERL}) {
    delete $ENV{REMOTE_USER};
 }
 $s
}


sub DESTROY {
 my $s =shift;
 $s->reset($s);
 $s
}


sub evalsub {
 my ($s, $c) =(shift, shift);
 local $SELF =$s;
 ref($c) ? &$c(@_) : eval $c 
}


sub AUTOLOAD {# Objects & Methods Loader
 my $s =shift;  confess("!object($s) in AUTOLOAD") if !ref($s);
 my $m =substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
 my $k ='-' .$m;
 if    (ref($s->{$k}) eq 'CODE')      {$s->evalsub($s->{$k},@_)}
 elsif (!scalar(@_) && ref($s->{$k})) {$s->{$k}}
 elsif ($s->{-classes}->{$k})  {
       local $SELF =$s;
       my $c =$s->{-classes}->{$k};
       my $o =ref($c) ? &$c(@_) : eval("use $c; $c->new(\@_)");
       $s->die($@) if $@;
       eval {$o->{'CGI::Bus'}=$s if $o->isa('HASH')};
       $s->{$k} =$o; # cycle ref!
 }
#elsif (grep {$m eq $_} qw(select tr link delete accept sub vars)) 
#                             {$m =ucfirst($m); $s->{-cgi}->$m(@_)}
#else {$s->{-cgi}->$m(@_)}
#else {eval {$s->{-cgi}->$m(@_)}; $s->_selfload(@_) if $@}
 else  {
       my @r;
       wantarray ? eval{@r =$s->{-cgi}->$m(@_)} : eval{$r[0] =$s->{-cgi}->$m(@_)};
       if ($@) {
          if (grep {$m eq $_} qw(select tr link delete accept sub vars)) {
             $m =ucfirst($m);
       wantarray ? eval{@r =$s->{-cgi}->$m(@_)} : eval{$r[0] =$s->{-cgi}->$m(@_)};
          }
          $r[0] =$s->_selfload(@_) if $@;
       }       
       wantarray ? @r : $r[0]
 }
}


sub launch {  # Objects Factory
 my ($s,$m) =(shift, shift);
 return  CGI::BusLauncher->new($s) if !defined($m);
 my $k ='-' .$m;
 local $SELF =$s;
 local $s->{$k};
 my $o;
 if ($s->{-classes}->{$k})  {     
     my $c =$s->{-classes}->{$k};
     $o =ref($c) ? &$c(@_) : eval("use $c; $c->new(\@_)");
 }
 else {
     $o =eval "use CGI::Bus::$m; CGI::Bus::$m->new (\@_)";
 }
 $s->die($@) if $@;
 $s->die("Object not created '$m'") if !defined($o);
 eval {$o->{'CGI::Bus'}=$s if $o->isa('HASH')};
 $o
}


sub _selfload{# Self SubObject Loader
 my $s =shift;
 local $SELF =$s;
 my $e =$@; chomp($e);
 my $o;
 $o =eval "use $AUTOLOAD; $AUTOLOAD->new(\@_)"; 
 if (defined($o)) {
    $s->{'-' .substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2)} =$o;
    eval {$o->{'CGI::Bus'}=$s if $o->isa('HASH')};
    $o
 }
 else {
    $s->die("$e. $@")
 }
}


sub microtest{# Microtest of the Object
 my $s =shift;
 $s->{-debug} ? $s->print->hr : $s->print->htpgstart;
#local $s->{-debug} =0;
 if (($s->{-debug}||0) >4) {
 $s->print->h2('Methods');
 foreach my $k (qw(class request qpath qurl qrun spath surl bpath burl dpath ppath purl furl user usdomain useron usersn usercn userfn userds unames ugroups ugnames)) {
   $s->print->text("$k = " ._stringify($s->$k()))->br;
 }
 }
 $s->print->h2('Slotes');
 foreach my $k (sort keys %$s) {
   $s->print->text("$k = " ._stringify($s->{$k}))->br;
 }
 $s->print->h2('Environment Variables');
 foreach my $k (sort keys %ENV) {
   $s->print->text($s->htmlescape("$k = '" .$ENV{$k} ."'"))->br;
 }
 $s->print->text($s->htmlescape( "login = '" .(eval{$^O eq 'MSWin32' ? Win32::LoginName() : getlogin()} ||'') ."'"))->br;
 $s->print->text($s->htmlescape("\$0    = '$0'"))->br;
 $s->print->text($s->htmlescape("\$^V   = '$^V'"))->br;
 $s->print->text($s->htmlescape("\$^X   = '$^X'"))->br if $^X;
 local $s->{-debug} =0;
 $s->print->htpgend();
}


sub microenv {# Microenv text of the Object
 my $s =shift;
 join(', ',('LOGIN=' .(eval{$^O eq 'MSWin32' ? Win32::LoginName() : getlogin()} ||''))
          ,map {$_ .'=' .($ENV{$_}||'')} qw(REMOTE_USER REMOTE_ADDR REMOTE_PORT HTTP_USER_AGENT REQUEST_METHOD REQUEST_URI CONTENT_TYPE CONTENT_LENGTH HTTP_COOKIE GATEWAY_INTERFACE))
}


sub _stringify {
 my $v =$_[0];
 my $p ='';
 if    (!defined($v)) {$p ='null'}
 elsif (UNIVERSAL::isa($v,'ARRAY')) {
    $p =$v .'[';
    foreach my $e (@$v) {$p .=_stringify($e) .','}
    chop($p) if scalar(@$v);
    $p .=']';
 }
 elsif (UNIVERSAL::isa($v,'HASH') && !UNIVERSAL::isa($v,'CGI::Bus')) {
    $p =$v .'{';
    foreach my $e (sort keys %$v) {$p .=$e .'=>' ._stringify($v->{$e}) .','}
    chop($p) if scalar(%$v);
    $p .='}';
 }
 else {
  # if (ref($CGI::Bus::USED{$v})) { $p ="''" ._stringify($CGI::Bus::USED{$v})}
  # else {$p ="'" .$v ."'"}
    $p ="'" .$v ."'"
 }
 $p
}


#######################

sub lngname {   # language name
 if (!$_[0]->{-lngname} || $_[1]) {
    if (defined($_[1])) {
       $_[0]->{-lngname} =$_[1]
    }
    else {
       $_[0]->{-lngname} =$_[0]->{-cgi}->http('Accept_language')||'';
                      # .($_[0]->{-cgi}->http('Accept_charset') ||'')
       $_[0]->{-lngname} =$_[0]->{-lngname} =~/^([^ ;,]+)/ ? $1 : $_[0]->{-lngname};
    }
 }
 $_[0]->{-lngname}
}


sub lngload {   # language load
 my ($s, $c, $l) =@_;
 $c =$s->class   if !$c;
 $l =$s->lngname if !$l;
 my $r;
 foreach my $m ($c .'_' .$l, $c) {
   $m =~s/::/_/g;
   $m =~s/[ -]/_/g;
   eval("use CGI::Bus::lngbase::${m}; \$r ={CGI::Bus::lngbase::${m}::lngbase}");
   last if $r;
 }
 return $r
}


sub lng {       # language string
 $_[0]->{-cache}->{-lngbase} =$_[0]->lngload($_[0]->class) if !$_[0]->{-cache}->{-lngbase};
 my $r =$_[0]->{-cache}->{-lngbase};
 $r = !defined($_[2]) ? $r->{$_[1]}
      :!defined($r->{$_[2]}) ||!defined($r->{$_[2]}->[$_[1]]) ? $_[2]
      :$r->{$_[2]}->[$_[1]];
 foreach my $e (@_[3..$#_]) {
   $r =~s/\$_/$e/e;
 }
 $r
}


sub pushmsg {   # messages to accumulate and display
 my $s =shift;
 $s->{-cache}->{-pushmsg} =[] if !$s->{-cache}->{-pushmsg};
 push @{$s->{-cache}->{-pushmsg}}, @_ if scalar(@_);
 $s->{-cache}->{-pushmsg}
}


sub pushlog {   # push messages to log file
 my $s =shift;
 return @_ if !$s->{-pushlog};
 my $b ="[" .$0 ."\t" .$s->user ."\t" .$s->strtime() ."]\t";
 $s->fut->fstore('-', '>' .$s->{-pushlog}, map {$b .(defined($_) ?$_ :'')} @_);
 @_
}


sub problem {   # problem flag
 $_[0]->pushmsg($_[0]->{-problem} =$_[1] || $@ || $!);
}


sub warn {      # warning
 problem(@_);
 my $m =$_[1] || $@ || $!;
 if ($m !~/\n/) {
    CGI::Carp::cluck($m) # carp cluck
 }
 else {
    eval {$_[0]->pushlog('Warning $m')};
    $m=$_[0]->htmlescape($m);
    if (!$_[0] ||!$_[0]->{-cache} ||!$_[0]->{-cache}->{-httpheader}) {
      print STDOUT "Content-type: text/html\n\n";
    }
    print STDOUT '<hr /><h1>' .$_[0]->lng(0,'Warning') ."</h1>\n";
    print STDOUT "$m<hr />\n";
 }
}


sub die {       # stop error
 my $m =$_[1] || $@ || $!;
 if (!CGI::Carp::ineval) { #!$^S
    eval {$_[0]->pushlog('Error $m', @{$_[0]->pushmsg} ,'<---Error')};
    if ($m !~/\n/ || !$_[0]->{-cgi}) {
       eval{$_[0]->reset};    # for mod_perl
       CGI::Carp::confess($m) # croak confess
    }
    $m=$_[0]->htmlescape($m);
    if (!$_[0] ||!$_[0]->{-cache} ||!$_[0]->{-cache}->{-httpheader}) {
      print STDOUT "Content-type: text/html\n\n";
    }
    print STDOUT '<hr /><h1>' .$_[0]->lng(0,'Error') ."</h1>\n";
    print STDOUT "$m<br />\n";
    print STDOUT '<font size="2">'
               , join(';<br />', map {$_[0]->htmlescape($_)} @{$_[0]->pushmsg})
               , '</font>';
    print STDOUT "<hr />\n";
    eval{$_[0]->reset};  # for mod_perl
    exit;
 }
 $m !~/\n/ ? CGI::Carp::confess($m) : CORE::die($m); # croak confess
}


#######################


sub cgi {      # CGI object
 $_[0]->{-cgi}
}


sub request {  # Web server request object
 $ENV{MOD_PERL} ? Apache->request
 : $_[0]->{-cgi}
}


sub dbi {      # DBI object
 if (scalar(@_) >1) {
    my $s =shift;
    $s->{-dbi} =eval('use DBI; DBI->connect(@_)') ||$s->die("Cannot connect to database\n")
 }
 elsif (!$_[0]->{-dbi} && $_[0]->{-classes}->{-dbi}) {
    my $s =shift;
  # $s->pushmsg('DBI connect');
    my $v =$s->{-classes}->{-dbi};
    $s->{-dbi} =ref($v) eq 'CODE' ? &$v($s) : $s->dbi(@$v);
 }
 else {
    $_[0]->{-dbi}
 }
}


sub dbquote {
   $_[0]->{-dbi} ||$_[0]->{-classes}->{-dbi}
 ? $_[0]->dbi->quote(@_[1..$#_])	
 : ('"' .join('', map {my $v=$_; $v=~s/([\\"])/\\$1/g; $v} @_[1..$#_]) .'"')
}


sub dblikesc {
 join('', map {my $v =$_; $v =~s/([\\%_])/\\$1/g; $v} @_[1..$#_])
}


#######################



sub url {	# CGI script URL
 if ($#_ >0) {
	local $^W =0;
	my $v =($_[0]->{-cgi}||$_[0]->cgi)->url(@_[1..$#_]);
	if ($v) {}
	elsif (!($ENV{PERLXS} ||(($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/))) {}
	elsif (($#_ >2) ||(($#_ ==2) && !$_[2])) {}
	elsif ($_[1] eq '-relative') {
		$v =$ENV{SCRIPT_NAME};
		$v =$1 if $v =~/[\\\/]([^\\\/]+)$/;
	}
	elsif ($_[1] eq '-absolute') {
		$v =$ENV{SCRIPT_NAME}
	}
	return($v)
 }
 return($_[0]->{-cache}->{-url})
	if $_[0]->{-cache}->{-url};
 local $^W =0;
 $_[0]->{-cache}->{-url} =$_[0]->cgi->url();
 if ($ENV{PERLXS} ||(($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/)) {
	$_[0]->{-cache}->{-url} .=
		(($_[0]->{-cache}->{-url} =~/\/$/) ||($ENV{SCRIPT_NAME} =~/^\//) ? '' : '/')
		.$ENV{SCRIPT_NAME}
		if ($_[0]->{-cache}->{-url} !~/\w\/\w/) && $ENV{SCRIPT_NAME};
 }
 $_[0]->{-cache}->{-url}
}


sub url_form {	# form url	for start_form
	$_[0]->url
	# $_[0]->url(-absolute=>1,-path=>1)
	# $_[0]->cgi->self_url()
}


sub qpath {   # Query (script) path
 defined($_[0]->{-qpath}) ||($_[0]->{-qpath} =$ENV{SCRIPT_FILENAME} ||$ENV{PATH_TRANSLATED}); 
 (!defined($_[1]) ? $_[0]->{-qpath} : $_[0]->{-qpath} .'/' .$_[1])
}


sub qurl  {   # Query (script) URL
 defined($_[0]->{-qurl}) ||($_[0]->{-qurl} =$_[0]->url);
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-qurl} : ($_[0]->{-qurl} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) :'')
}


sub qparam {  # Query param(s) set or get
 my $s =shift;
 if (!ref($_[0])) { # CGI param call
    $s->{-cgi}->param(@_)
 }
 elsif (ref($_[0]) eq 'ARRAY') {
    if (!defined($_[1])) { # qparam([names]) -> [values]
       my $r =[];
       for (my $i =0; $i <=$#{$_[0]}; $i++) {push @$r, $s->{-cgi}->param($_[0]->[$i])}
       $r
    }
    else {                 # qparam([names]=>[values]) -> [values]
       for (my $i =0; $i <=$#{$_[0]}; $i++) {$s->{-cgi}->param($_[0]->[$i], $_[1]->[$i])}
       $_[1]
    }
 }
 elsif (ref($_[0]) eq 'HASH') { # qparam({name=>value,...}) -> {name=>value,...}
    foreach my $k (keys(%{$_[0]})) {$s->{-cgi}->param($k,$_[0]->{$k})}
    $_[0]
 }
 else {             # CGI param call
    $s->{-cgi}->param(@_)
 }
}


sub param {   # CGI param call
 shift->{-cgi}->param(@_)
}


sub qparamh { # Query params get as hash ref
 my $s =shift;
 return $s->qparam(@_) if ref($_[0]) ne 'ARRAY' || defined($_[1]);
 my $r ={};
 for (my $i =0; $i <=$#{$_[0]}; $i++) {$r->{$_[0]->[$i]} =$s->{-cgi}->param($_[0]->[$i])}
 $r
}


sub qrun {    # Query 'run' param - Script to run
 $_[0]->{-cache}->{-qrun} =$_[1]
           ## || $ENV{REQUEST_URI} ? substr($ENV{REQUEST_URI}, length($ENV{SCRIPT_NAME})+1) :''
              || $_[0]->{-cgi}->param('_run')
              || $_[0]->{-cgi}->url_param('')
              || $_[0]->{-cgi}->url_param('run')
        if !$_[0]->{-cache}->{-qrun} || $_[1];
 $_[0]->{-cache}->{-qrun}
}


#######################


sub spath {   # Site Path
 if (!defined($_[0]->{-spath})) {
    $_[0]->{-spath} =substr($ENV{SCRIPT_FILENAME} ||$ENV{PATH_TRANSLATED}
                           , 0
                           , -length($ENV{SCRIPT_NAME} ||$ENV{PATH_INFO}));
 }
 !defined($_[1]) ? $_[0]->{-spath} : $_[0]->{-spath} .'/' .$_[1]
}


sub surl {    # Site URL
 ($_[0]->{-surl} 
  || ($_[0]->{-surl} = 
      $_[0]->url() =~/^([^\/]+:\/\/[^\/]+)/ ? $1 : $_[0]->url()))
 . ((!defined($_[1]) || $_[1] eq '' ? '' : '/') 
 . (scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) :''));
}


sub bpath {   # Binary Path
 if (!defined($_[0]->{-bpath})) {
    $_[0]->{-bpath} =(($ENV{SCRIPT_FILENAME} ||$ENV{PATH_TRANSLATED} ||$0) =~/^(.+?)[\\\/][^\\\/]+$/ ? $1 : '');
 }
 !defined($_[1]) ? $_[0]->{-bpath} : $_[0]->{-bpath} .'/' .$_[1]
}


sub burl {    # Binary URL
 if (!defined($_[0]->{-burl})) {
    my $pv =(($ENV{SCRIPT_NAME} ||$ENV{PATH_INFO} ||$0) =~/^[\\\/]*(.+?)[\\\/]+[^\\\/]+$/ ? $1 : '');
    $_[0]->{-burl} =$_[0]->surl .($pv ? '/' .$pv :'');
 }
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-burl} : ($_[0]->{-burl} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub dpath {   # Data Path
 if (!defined($_[0]->{-dpath})) {
    $_[0]->{-dpath} =$_[0]->tpath;
 }
 !defined($_[1]) ? $_[0]->{-dpath} : $_[0]->{-dpath} .'/' .$_[1]
}


sub tpath {   # Temporary files Path
 if (!defined($_[0]->{-tpath})) {
    $_[0]->{-tpath} =$TempFile::TMPDIRECTORY # use CGI
                   ||$ENV{TMP} ||$ENV{TEMP} 
                   ||$_[0]->orarg('-d'
                                 ,$^O eq 'MSWin32'
                                 ?('c:/tmp','c:/temp')
                                 :('/tmp','/temp'));
    $_[0]->{-tpath} = ($_[0]->{-tpath} ||'') .'/cgi-bus'
 }
 !defined($_[1]) ? $_[0]->{-tpath} : $_[0]->{-tpath} .'/' .$_[1]
}


sub ppath {   # Publish Path
 if (!defined($_[0]->{-ppath})) {
    $_[0]->{-ppath} =$ENV{DOCUMENT_ROOT} ||$ENV{PATH_TRANSLATED} ||'.';
 }
 !defined($_[1]) ? $_[0]->{-ppath} : $_[0]->{-ppath} .'/' .$_[1]
}


sub purl {    # Publish URL
 if (!defined($_[0]->{-purl})) {
    $_[0]->{-purl} =$_[0]->surl;
 }
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-purl} : ($_[0]->{-purl} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub fpath {   # File Store Path
 $_[0]->{-fpath} =$_[0]->ppath if !defined($_[0]->{-fpath});
 !defined($_[1]) ? $_[0]->{-fpath} : $_[0]->{-fpath} .'/' .$_[1]
}


sub furl {    # File Store URL
 $_[0]->{-furl} =$_[0]->purl if !defined($_[0]->{-furl});
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-furl} : ($_[0]->{-furl} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub furf {    # File Store file URL
 $_[0]->{-furf} ='file://' .$_[0]->fpath if !defined($_[0]->{-furf});
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-furf} : ($_[0]->{-furf} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub hpath {   # Homes Store Path
 $_[0]->{-hpath} =$_[0]->ppath if !defined($_[0]->{-hpath});
 !defined($_[1]) ? $_[0]->{-hpath} : $_[0]->{-hpath} .'/' .$_[1]
}


sub hurl {    # Homes Store URL
 $_[0]->{-hurl} =$_[0]->purl if !defined($_[0]->{-hurl});
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-hurl} : ($_[0]->{-hurl} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub hurf {    # Homes Store file URL
 $_[0]->{-hurf} ='file://' .$_[0]->hpath if !defined($_[0]->{-hurf});
 (!defined($_[1]) || $_[1] eq '' ? $_[0]->{-hurf} : ($_[0]->{-hurf} .'/')) 
.(scalar(@_) >1 ? $_[0]->htmlurl(@_[1..$#_]) : '')
}


sub urfcnd {  # Use URFs?
 my $s =shift;
 ($s->{-cgi}->user_agent||'') =~/MSIE|StarOffice/
 && ( ref($s->{-urfcnd}) eq 'CODE' ? &{$s->{-urfcnd}}(@_)
    : exists $s->{-urfcnd} ? $s->{-urfcnd}
    : 1 # $ENV{REMOTE_ADDR}
    )
}


#######################


sub hmerge {  # merge hash ref with data given
 my ($s, $h) =(shift, shift);
 my $r =$h ? {%$h} : {};
 my %h =@_;
 foreach my $k (keys %h) {$r->{$k} =$h{$k} if !exists($r->{$k})}
 $r
}


sub max {     # maximal number
 (($_[1]||0) >($_[2]||0) ? $_[1] : $_[2])||0
}


sub min {     # minimal number
 (($_[1]||0) >($_[2]||0) ? $_[2] : $_[1])||0
}


sub orarg {   # argument of true result
 shift(@_);
 my $s =ref($_[0]) ? shift 
       :index($_[0], '-') ==0 ? eval('sub{' .shift(@_) .' $_}')
       :eval('sub{' .shift(@_) .'($_)}');
 local $_;
 foreach (@_) {return $_ if &$s($_)};
 undef
}


sub strtime { # Stringify Time
 my $s =shift;
 my $msk =@_ ==0 || $_[0] =~/^\d+$/i ? 'yyyy-mm-dd hh:mm:ss' : shift;
 my @tme =@_ ==0 ? localtime(time) : @_ ==1 ? localtime($_[0]) : @_;
 $msk =~s/yyyy/%Y/;
 $msk =~s/yy/%y/;
 $msk =~s/mm/%m/;
 $msk =~s/mm/%M/i;
 $msk =~s/dd/%d/;
 $msk =~s/hh/%H/;
 $msk =~s/hh/%h/i;
 $msk =~s/ss/%S/;
 eval('use POSIX');
 POSIX::strftime($msk, @tme)
}


sub timestr { # Time from String
 my $s   =shift;
 my $msk =@_ <2 || !$_[1] ? 'yyyy-mm-dd hh:mm:ss' : shift;
 my $ts  =shift;
 my %th;
 while ($msk =~/(yyyy|yy|mm|dd|hh|MM|ss)/) {
    my $m=$1; $msk =$';
    last if !($ts =~/(\d+)/);
    my $d =$1; $ts   =$';
    $d   -=1900   if $m eq 'yyyy' ||$m eq '%Y';
    $m    =chop($m);
    $m    ='M'    if $m eq 'm' && $th{$m};
    $m    =lc($m) if $m ne 'M';
    $th{$m}=$d;
 }
 eval('use POSIX');
 POSIX::mktime($th{'s'}||0,$th{'M'}||0,$th{'h'}||0,$th{'d'}||0,($th{'m'}||1)-1,$th{'y'}||0)
}


sub timeadd { # Adjust time to years, months, days,...
 my $s =shift;
 my @t =localtime(shift);
 my $i =5;
 foreach my $a (@_) {$t[$i] += ($a||0); $i--}
 eval('use POSIX');
 POSIX::mktime(@t[0..5])
}


sub cptran {  # Translate strings between codepages
 my ($s,$f,$t,@s) =@_; 
 foreach my $v ($f, $t) {
   if    ($v =~/oem|866/i)   {$v ='€‚ƒ„…ð†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™œ›šžŸ ¡¢£¤¥ñ¦§¨©ª«¬­®¯àáâãäåæçèéìëêíîï'}
   elsif ($v =~/ansi|1251/i) {$v ='ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÜÛÚÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùüûúýþÿ'}
   elsif ($v =~/koi/i)       {$v ='áâ÷çäå³öúéêëìíîïðòóôõæèãþûýøùÿüàñÁÂ×ÇÄÅ£ÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝØÙßÜÀÑ'}
   elsif ($v =~/8859-5/i)    {$v ='°±²³´µ¡¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÌËÊÍÎÏÐÑÒÓÔÕñÖ×ØÙÚÛÜÝÞßàáâãäåæçèéìëêíîï'}
 }
 map {eval("~tr/$f/$t/")} @s; 
 @s >1 ? @s : $s[0];
}


sub dumpout { # Data dump out
 my ($s, $d) =@_;
 eval('use Data::Dumper');
 my $o =Data::Dumper->new([$d]); 
 $o->Indent(1);
 $o->Dump();
}


sub dumpin {  # Data dump in
 my ($s, $d) =@_;
 my $e; for(my $i=0; !$e && $i<10; $i++) {$e =eval('use Safe; Safe->new()')};
 defined($e) && $e->reval($d)
}


sub ishtml {  # Is html code?
 ($_[1] ||'') =~m/^<(?:(?:B|BIG|BLOCKQUOTE|CENTER|CITE|CODE|DFN|DIV|EM|I|KBD|P|SAMP|SMALL|SPAN|STRIKE|STRONG|STYLE|SUB|SUP|TT|U|VAR)\s*>|(?:BR|HR)\s*\/{0,1}>|(?:A|BASE|BASEFONT|DIR|DIV|DL|!DOCTYPE|FONT|H\d|HEAD|HTML|IMG|IFRAME|MAP|MENU|OL|P|PRE|TABLE|UL)\b)/i
}



#######################



sub user {    # User name
 if (!$_[0]->{-cache}->{-user} ||$_[1]) {
    $_[0]->{-cache}->{-user} =$_[0]->{-cache}->{-useron} =
       $_[1] ? $_[1] :
       ref($_[0]->{-user}) eq 'CODE' ? &{$_[0]->{-user}}(@_)
                                     : $_[0]->uauth->user(@_[1..$#_]);
    if ($_[0]->{-usercnv}) {
       local $_ =$_[0]->{-cache}->{-user};
       $_[0]->{-cache}->{-user} =&{$_[0]->{-usercnv}}(@_)
    }
 }
 $_[0]->{-cache}->{-user}
}


sub useron {  # User original name
 $_[0]->user if !$_[0]->{-cache}->{-useron};
 $_[0]->{-cache}->{-useron}
}


sub uadmin {  # Is admin?
 my $s =shift;
 my $u =$s->user;
 if    (scalar(@_)) {
       return $u if $_[0] eq $u;
       return $s->uadmin ? $s->uglist 
            : ($s->udata->paramj('uauth_managed') ||[])
            if ref($_[0]);
       my $l =$s->udata->paramj('uauth_managed') ||[];
       foreach my $n (@$l) {
          return $n if $n eq $_[0]
       }
 }
 if    (!defined($s->{-uadmins}))       {}
 elsif (ref($s->{-uadmins}) eq 'CODE')  {return &{$s->{-uadmins}}($s)}
 elsif (ref($s->{-uadmins}) eq 'ARRAY') {
       foreach my $n (@{$s->ugnames})   {
          next if !defined($n);
          return $n if grep {$_ eq $n} @{$s->{-uadmins}}
       }
 }
 else  {return $u if $u eq $s->{-uadmins}}
 return '';
}


sub uguest {  # Is guest?
 ($_[1] ||$_[0]->user ||'') eq $_[0]->uauth->guest
}


sub usercn {  # User name CN
 my $v =scalar(@_) >1 ? $_[1] : $_[0]->user;
 return($v) if !defined($v) || $v eq '';
    $v =~/CN=([^=,]+)/i ? $1
  : $v =~/^([^\@])\@/i  ? $1
  : $v =~/\\([^\\]+)$/  ? $1
  : $v
}


sub usersn {  # User Shorten Name, remove domain if default
 my $v =scalar(@_) >1 ? $_[1] : $_[0]->user;
 return($v) if !defined($v) || $v eq '';
 my $d =$_[0]->usdomain;
 if    ($v =~m/^(.*?)[\/@]\Q$d\E$/i) {$1}
 elsif ($v =~m/^\Q$d\E[\\](.*)$/i)   {$1}
 else  {$v}
}


sub userfn {  # User name translated to filename
 my $v =scalar(@_) >1 ? $_[1] : $_[0]->user;
 return($v) if !defined($v) || $v eq '';
 $v =~ s/[\\\/|\+\:\*\?\[\]\(\) &,]/-/g;
 $v
}


sub userds {  # User name as dir structure
 my $u =scalar(@_) >1 ? $_[1] : $_[0]->user;
 return($u) if !defined($u) || $u eq '';
 my $p =$_[0]->userfn($_[0]->usercn($u)); 
    $p =substr($p,0,1) .'/' .substr($p,0,2) .'/' .$_[0]->userfn($u);
}


sub unames {  # User Names
 if (!defined($_[0]->{-cache}->{-unames})) {
    my $s =$_[0];
    return('') if !defined($s->user);
    $s->{-cache}->{-unames} =[];
    local $_;
    foreach my $v ($_ =$s->user, $s->useron
			# , lc($s->user), $s->usercn, lc($s->usercn)
		#, $s->user   =~/^([^\\]+)\\(.+)$/ ? lc("$2\@$1") : ()
		#, $s->useron =~/^([^\\]+)\\(.+)$/ ? lc("$2\@$1") : ()
		, $s->user   =~/^([^@]+)\@(.+)$/  ? lc("$2\\$1") : ()
		, $s->useron =~/^([^@]+)\@(.+)$/  ? lc("$2\\$1") : ()
		, ref($s->{-unmsadd}) eq 'ARRAY'
		? map {&$_($s)} @{$s->{-unmsadd}}
		: ref($s->{-unmsadd})
		? &{$s->{-unmsadd}}($s)
		: ()
		) {
	push @{$s->{-cache}->{-unames}}, $v
		if !grep /^\Q$v\E$/, @{$s->{-cache}->{-unames}};
    }
 }
 $_[0]->{-cache}->{-unames}
}


sub usdomain {# User names Server Domain
 if (!$_[0]->{-cache}->{-usdomain} ||$_[1]) {
    $_[0]->{-cache}->{-usdomain} =$_[1] 
     || (ref($_[0]->{-usdomain}) eq 'CODE' 
        ? &{$_[0]->{-usdomain}}(@_)
        : $_[0]->uauth->usdomain(@_[1..$#_]));
 }
 $_[0]->{-cache}->{-usdomain}
}


sub userver { # User names Server
 if (!$_[0]->{-cache}->{-userver} ||$_[1]) {
    $_[0]->{-cache}->{-userver} =$_[1]
     ||(ref($_[0]->{-userver}) eq 'CODE' 
       ? &{$_[0]->{-userver}}(@_)
       : $_[0]->uauth->userver(@_[1..$#_]));
 }
 $_[0]->{-cache}->{-userver}
}


sub ugroups { # User groups [user name]
 if (!defined($_[0]->{-cache}->{-ugroups}) 
 || ($_[1]	&& (lc($_[0]->useron	||'') ne lc($_[1]))
		&& (lc($_[0]->user	||'') ne lc($_[1])))) {
	my $s =$_[0];
	my $r =[];
	return($r) if !defined($s->user) && !$_[1];
	$r = ref($s->{-ugroups}) eq 'CODE' 
		? &{$s->{-ugroups}}(@_)
		: $_[0]->uauth->ugroups(@_[1..$#_]);
	if ($_[0]->{-ugrpcnv}) {
		my $ga =[];
		local $_;
		foreach $_ (@$r) {
			$_ =&{$_[0]->{-ugrpcnv}}(@_);
			push(@$ga, $_) if defined($_) && $_ ne '';
		}
		$r =$ga;
	}
	if ($_[0]->{-ugrpadd}) {
		local $_ =$r;
		my $ugadd=ref($s->{-ugrpadd}) eq 'CODE' ? &{$s->{-ugrpadd}}(@_) : $s->{-ugrpadd};
		foreach my $e (	  ref($ugadd) eq 'ARRAY'
				? @{$ugadd}
				: ref($ugadd) eq 'HASH'
				? keys(%$ugadd)
				: $ugadd){
			push @$r, $e if !grep /^\Q$e\E$/i, @$r
		}
	}
	{ use locale;
	  $r =[sort {lc($a) cmp lc($b)} @$r];
	}
	$s->{-cache}->{-ugroups} =$r 
		if !$_[1]
		|| (lc($_[0]->useron)	eq lc($_[1]))
		|| (lc($_[0]->user)	eq lc($_[1]));
	return($r)
 }
 $_[0]->{-cache}->{-ugroups}
}


sub ugnames { # User & Group Names
 if (!defined($_[0]->{-cache}->{-ugnames})) {
    my $s =$_[0];
    return('') if !defined($s->user);
    $s->{-cache}->{-ugnames} =[];
    push @{$s->{-cache}->{-ugnames}}, @{$s->unames};
    push @{$s->{-cache}->{-ugnames}}, @{$s->ugroups};
 }
 $_[0]->{-cache}->{-ugnames}
}


sub uglist {  # User & Group List
 my $s =shift;
 my $o =defined($_[0]) && substr($_[0],0,1) eq '-' ? shift : '-ug';
 my $r =
     ref($s->{-uglist}) eq 'CODE' ? &{$s->{-uglist}}($s,$o,@_)
                                  : $s->uauth->uglist($o,@_);
 if ($s->{-ugrpadd}) {
	local $_ =$r;
	my $ugadd=ref($s->{-ugrpadd}) eq 'CODE' ? &{$s->{-ugrpadd}}(@_) : $s->{-ugrpadd};
	if ((ref($r) eq 'HASH')
	&&  (ref($ugadd) eq 'HASH')) {
		foreach my $e (keys(%$ugadd)) {
			$r->{$e} =$ugadd->{$e} if !$r->{$e}
		}
	}
	else {
		foreach my $e (	  ref($ugadd) eq 'ARRAY'
				? @{$ugadd}
				: ref($ugadd) eq 'HASH'
				? keys(%$ugadd)
				: $ugadd){
			if (ref($r) eq 'HASH') {
				$r->{$e} =$e if !$r->{$e}
			}
			else {
				push @$r, $e if !grep /^\Q$e\E$/i, @$r
			}
		}
	}
 }
 $r =do{use locale; [sort {lc($a) cmp lc($b)} @$r]} if ref($r) eq 'ARRAY';

 if ($s->{-ugrpcnv}) {
    local $_;
    if (ref($r) eq 'ARRAY') {
       my @g;
       foreach $_ (@$r) {
          $_ =&{$s->{-ugrpcnv}}($s,$o);
          push(@g, $_) if defined($_) && $_ ne '';
       }
       $r =[sort {lc($a) cmp lc($b)} @g];
    }
    else {
       my $w =$_[1]; # width of label
       foreach my $k (keys %$r) {
         $_ =$k;
         $_ =&{$s->{-ugrpcnv}}($s,$o);
         if (defined($_) && $_ ne '') {
            $r->{$_} =$r->{$k};
            $r->{$_} =substr($r->{$_},0,$w) if $w;
         }
         elsif (!defined($_) || $_ eq '' || $_ ne $k) {
            delete $r->{$k}
         }
       }
    }
 }
 $r
}


sub unamesun {# User Names Unique list
 my $s =shift;
 my $r =[];
 foreach my $n (ref($_[0]) ? @{$_[0]} : @_) {
   next if grep {lc($n) eq lc($_) 
              || lc($s->usercn($n)) eq lc($s->usercn($_))} @$r;
   push @$r, $n;
 }
 $r
}


sub userauth {# User Authenticate
 my $s =shift;
 $s->{-w32IISdpsn} =($ENV{SERVER_SOFTWARE}||'') !~/IIS/ 
	? 0
	: ($s->{-login}||'') =~/\/$/i
	? 2
	: 0
	if !defined($s->{-w32IISdpsn});
 ref($s->{-userauth}) eq 'CODE'    ? &{$s->{-userauth}}($s,@_)
 : ref($s->{-userauth}) eq 'ARRAY' ? $s->uauth->auth($s->{-userauth},@_)
 : $s->{-userauth}                 ? $s->uauth->auth([$s->{-userauth}],@_)
 : $s->uauth->auth(@_);
 $s->{-cache}->{-userauth} =$s->user
}



sub userauthopt { # User Authenticate optional
 my $s =shift;
 if ($s->{-cache}->{-userauth}) {
 }
 elsif ($s->uguest()
  &&(defined($s->{-cgi}->param('_auth'))
  || defined($s->{-cgi}->param('_login')))) {
    $s->userauth(@_)
 }
 elsif ((($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
      &&($s->url() =~/\/_*(login|auth|a|ntlm|search|guest)\//i)) { # !!! IIS impersonation avoid
    my $url  =$s->url();
    $s->userauth(@_)	if $url !~/\/_*(search|guest)\//i
		##	&& !$s->{-cache}->{-RevertToSelf}	# -w32IISdpsn
			&& (!$s->{-cache}->{-RevertToSelf} && (!defined($s->{-w32IISdpsn}) ? ($s->{-login}||'') =~/\/$/i : $s->{-w32IISdpsn} >1))
			&& !$s->uauth()->signget(); # $s->uguest
     if ((($s->qparam('_run')||'') ne 'SEARCH')
	&& !$s->{-cache}->{-RevertToSelf}
	&& (!defined($s->{-w32IISdpsn}) || ($s->{-w32IISdpsn} >1))
	) { # see 'search' in 'upws'
       $url  =~s/\/_*(login|auth|a|ntlm|search|guest)\//\//i;
       $url .=($ENV{QUERY_STRING} ? ('?' .$ENV{QUERY_STRING}) :'');
       $s->print()->redirect(-uri=>$url, -nph=>1);
       eval{$s->reset()};
       exit;
    }
 }
 $s->user
}



sub w32IISdpsn {# deimpersonate Microsoft IIS impersonated process
		# 'Win32::API' used.
		# Set 'IIS / Home Directory / Application Protection' = 'Low (IIS Process)'
		# or see 'Administrative Tools / Component Services'.
		# Do not use quering to 'Index Server'.
 return(undef)	if (defined($_[0]->{-w32IISdpsn}) && !$_[0]->{-w32IISdpsn})
		|| $_[0]->{-cache}->{-RevertToSelf}
		|| ($^O ne 'MSWin32')
		|| !(($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
		|| $ENV{'FCGI_SERVER_VERSION'};
 $_[0]->user();
 my $o =eval('use Win32::API; new Win32::API("advapi32.dll","RevertToSelf",[],"N")');
 my $l =eval{Win32::LoginName()}||'';
 if ($o && $o->Call() && ($l ne (eval{Win32::LoginName()} ||''))) {
	$_[0]->{-cache}->{-RevertToSelf} =(Win32::LoginName()||'?');
	$_[1] && $_[0]->{-debug}
	&& $_[0]->pushmsg('w32IISdpsn(' .(defined($_[0]->{-w32IISdpsn}) ? $_[0]->{-w32IISdpsn} : 'undef') .')' .($_[0]->{-debug} >2 ? ' '. $_[0]->{-cache}->{-RevertToSelf} : ''))
 }
 else {
	return $_[0]->die($_[0]->lng(0, 'w32IISdpsn') .": Win32::API('RevertToSelf') -> " .join('; ', map {$_ ? $_ : ()} $@,$!,$^E))
 }
 1
}


#######################


sub oscmd {     # OS Command with logging
 my $s   =shift;
 my $opt = substr($_[0],0,1) eq '-' ? shift : ''; # 'h'ide, 'i'gnore
 my $sub =ref($_[$#_]) eq 'CODE' ? pop : undef;
 my $r;
 my $o;
 $s->pushmsg(join(' ',@_)) if $opt !~/h/;
 local(*RDRFH, *WTRFH);
 if ($^X =~/(?:perlis|perlex)\d*\.dll$/i) { # !!! ISAPI IIS problem
    if ($sub) {
       open(WTRFH, '|' .join(' ',@_)) && defined(*WTRFH) || $s->die(join(' ',@_) .' -> ' .$!);
     # open(WTRFH, '|' ,@_) && defined(*WTRFH) || $s->die(join(' ',@_) .' -> ' .$!);
       my $ls =select(); select(WTRFH); $| =1;
       &$sub($s);
       select($ls);
       eval{close(WTRFH)};
    }
    else {
       if ($opt !~/h/ && $_[0] =~/cacls/) { # !!! IIS/cacls behaviour debug
          $r  =join(' ',@_,'2>&1');
          @$o =`$r`;
        # push @$o, Win32::LoginName, `logname`; # 'SYSTEM'/'IUSR_' || 'IUSR_'/'IWAM'
       }
       else {
          system(@_)
       }
    }
 }
 else {
    eval('use IPC::Open2');
    my $pid = IPC::Open2::open2(\*RDRFH, \*WTRFH, @_); 
    if ($pid) {
       if ($sub) {
          my $select =select();
          select(WTRFH);
          $| =1;
          &$sub($s);
          select($select);
       }
       @$o =<RDRFH>;
       waitpid($pid,0);
    }
 }
 $r =$?>>8;
 $s->pushmsg(@$o) if $o && $opt !~/h/;
 $s->die(join(' ',@_) .($opt !~/h/ ? '' : ' -> ' .join('',@{$o||[]})) ." -> $r\n") if $r && $opt !~/i/;
 !$r
}



#######################


sub httpheader {
 my $s =shift;
 my %p =!defined($_[0]) ? () : @_==1 && ref($_[0]) ? %{$_[0]} : @_;
 if (ref($s->{-httpheader})) {
    foreach my $k (keys(%{$s->{-httpheader}})) {
      if (!exists($p{$k})) {$p{$k} =$s->{-httpheader}->{$k}}
    }
 }
 $s->{-cgi}->header(%p)
}


sub htmlstart {
 my $s =shift;
 my %p =!defined($_[0]) ? () : @_==1 && ref($_[0]) ? %{$_[0]} : @_;
 if (ref($s->{-htmlstart})) {
    foreach my $k (keys(%{$s->{-htmlstart}})) {
      if (!exists($p{$k})) {$p{$k} =$s->{-htmlstart}->{$k}}
    }
 }
 $p{-style} ={code=>
	".Form, .List, .Help, .MenuArea, .FooterArea {margin-top:0px; font-size: 8pt; font-family: Verdana, Helvetica, Arial, sans-serif; }\n"
	#."a:link.ListTable {font-weight: bold}\n"
	.".MenuButton {background-color: buttonface; color: black; text-decoration: none; font-size: 7pt;}\n"
	#."td.MenuButton {background-color: activeborder;}\n"
	#.".MenuArea {background-color: blue; color: white;}"
	#.".MenuButton {background-color: blue; color: white; text-decoration: none; font-size: 7pt;}\n"
	.".PaneLeft, .PaneForm, .PaneList {margin-top:0px; font-size: 8pt; font-family: Verdana, Helvetica, Arial, sans-serif; }\n"
	."td.ListTable {border-style: inset; border-bottom-width: 1px; border-top-width: 0px; border-left-width: 0px; border-right-width: 0px; padding-top: 0;}\n"
	."th.ListTable {border-style: inset; border-bottom-width: 1px; border-top-width: 0px; border-left-width: 0px; border-right-width: 0px;}\n"
	} if !exists($p{-style});
 $s->{-debug} && $s->{-debug} >2
 ? $s->{-cgi}->start_html(%p)
  .("\n<!-- " .$s->{-cgi}->escapeHTML($s->microenv) ." -->\n")
 : $s->{-cgi}->start_html(%p) 
}


sub htmlend {
 $_[0]->microtest if $_[0]->{-debug} && $_[0]->{-debug} >3;
 $_[0]->{-cgi}->end_html
}


sub htpgstart {
  $_[0]->httpheader($_[1])
 .$_[0]->htmlstart($_[2])
 .($_[0]->{-htpgtop}||'')
}


sub htpgend {
  ($_[0]->{-htpgbot}||'')
 .$_[0]->htmlend
}


sub htpfstart {
 my $s =shift;
 $s->htpgstart($_[0],$_[1]) ."\n" 
 .((($ENV{HTTP_USER_AGENT} ||'') =~m{^[^/]+/(\d)} ? $1 >=3 : 0)
  ? $s->{-cgi}->start_multipart_form({-action=>$s->url_form()
		, -acceptcharset=>$s->{-httpheader} ?$s->{-httpheader}->{-charset} :undef
		, $_[2] ? %{$_[2]} : ()
		})
  : $s->{-cgi}->start_form({-action=>$s->url_form()
		, -acceptcharset=>$s->{-httpheader} ?$s->{-httpheader}->{-charset} :undef}
		, $_[2] ? %{$_[2]} : ()
		)
  ) ."\n"
}


sub htpfend {
 "\n</form>\n" .$_[0]->htpgend(@_)
}


sub htmlescape {
 !defined($_[1]) ? '' : shift->{-cgi}->escapeHTML(@_)
}


sub htmlescapetext {
 my $s =shift;
 my $r =join("\n",@_);
 my $g =$s->cgi;
 my ($e, $m, $l) =('');
 while ($r =~/\b(\w{3,5}:\/\/[^\s\t,()<>\[\]"']+[^\s\t.,;()<>\[\]"'])/) {
   $m  =$1;  $r =$';
   $l  =$g->escapeHTML($`); $l =~s/( {2,})/'&nbsp;' x length($1)/ge; $l =~s/\n/<br \/>\n/g; $l =~s/\r//g;
   $e .=$l;
   $m  =~s/^(host|urlh):\/\//\//;
   $m  =~s/^(url|urlr):\/\//$s->url(-relative=>1)/e;
   $e .=$g->a({-href=>$m, -target=>'_blank'}, $g->escapeHTML($m));
 }
 $r  =$g->escapeHTML($r); $r =~s/( {2,})/'&nbsp;' x length($1)/ge; $r =~s/\n/<br \/>\n/g; $r =~s/\r//g;
 $e .=$r;
 $e  ="<code>$e</code>" if $e =~/&nbsp;&nbsp;/;
 $e
}


sub urlescape {
 !defined($_[1]) ? '' : shift->{-cgi}->escape(@_)
}


sub htmlurl { # Create URL from call string and parameters
 return($_[0]->url .($ENV{QUERY_STRING} ? '?' .$ENV{QUERY_STRING} : '')) if scalar(@_) <2;
 my $rsp = $_[1]; # do not escape at all?!!!
    $rsp ='' if !defined($rsp);
 chop $rsp if $rsp ne '' && substr($rsp, length($rsp) -1, 0) eq '/';
 $rsp  =~s/([^a-zA-Z0-9_\.\-\/\?\=\&;:%])/uc sprintf("%%%02x",ord($1))/eg; # see cgi->escape
 $rsp .=($rsp =~/\?/ ? '&' : '?');
 for (my $i =2; $i <$#_; $i +=2) { # see cgi->escape
   my @a =($_[$i], $_[$i+1]);
      map {!defined($_) ? ($_ ='')
       : ~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg} @a; 
   $rsp .=$a[0] .'=' .$a[1] .'&';
 }
 chop($rsp);
 $rsp;
}


sub htmlddlb {      # HTML Drop-Down List Box - Input helper
 shift->wg->ddlb(@_);
}

sub htmltextfield { # HTML Text filed with autosizing
 shift->wg->textfield(@_);
}


sub htmltextarea {  # HTML Text area with autorowing and hrefs
 shift->wg->textarea(@_);
}


sub htmlfsdir {     # HTML Filesystem dir field
 shift->wg->fsdir(@_);
}


#######################


sub print {    # print and CGI::BusCgiPrint object
 my $s =shift;
#return(undef) if scalar(@_) && !CORE::print @_;
 CORE::print @_;
 CGI::BusCgiPrint->new($s);
}


sub text {     # Retransalte text for print->text()
 shift; join('',@_)
}



#######################

                            # Autoload Launcher Object
package CGI::BusLauncher;   # Used with 'launch'
use vars qw($AUTOLOAD);
1;

sub new {
 my $c=shift;
 my $s =[$_[0]];
 bless $s,$c;
}

sub DESTROY { 
 eval {$_[0]->[0] =undef}
}

sub AUTOLOAD {
 shift->[0]->launch(substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2), @_)
}



#######################

                            # Autoload CGI method, print it result, return self
package CGI::BusCgiPrint;   # Used with 'print'
use vars qw($AUTOLOAD);
1;

sub new {
 my $c=shift;
 my $s =[$_[0]];
 bless $s,$c;
}

sub DESTROY { 
 eval {$_[0]->[0] =undef}
}


sub httpheader {
 my $s =shift;
 $s->[0]->print($s->[0]->{-cache}->{-httpheader} ? ''
              :($s->[0]->{-cache}->{-httpheader} =$s->[0]->httpheader(@_)));
}


sub htmlstart {
 my $s =shift;
 $s->[0]->print($s->[0]->{-cache}->{-htmlstart} ? ''
              :($s->[0]->{-cache}->{-htmlstart} =$s->[0]->htmlstart(@_)));
}


sub htpgstart {
  $_[0]->httpheader($_[1]);
  $_[0]->htmlstart ($_[2]);
  $_[0]->[0]->print($_[0]->[0]->{-cache}->{-htpgstart} ? ''
                  :($_[0]->[0]->{-cache}->{-htpgstart} =$_[0]->[0]->{-htpgtop}||''))
}


sub htpfstart {
 $_[0]->htpgstart($_[1],$_[2]);
 $_[0]->[0]->print("\n" 
 .((($ENV{HTTP_USER_AGENT} ||'') =~m{^[^/]+/(\d)} ? $1 >=3 : 0)
  ? $_[0]->[0]->{-cgi}->start_multipart_form({-action=>$_[0]->[0]->url_form()
		, -acceptcharset=>$_[0]->[0]->{-httpheader} ?$_[0]->[0]->{-httpheader}->{-charset} :undef
		, $_[3] ? %{$_[3]} : ()})
  : $_[0]->[0]->{-cgi}->start_form({-action=>$_[0]->[0]->url_form()
		,-acceptcharset=>$_[0]->[0]->{-httpheader} ?$_[0]->[0]->{-httpheader}->{-charset} :undef
		, $_[3] ? %{$_[3]} : ()})
 ) ."\n")
}


sub br {
 $_[0]->[0]->print('<br />')
}


sub AUTOLOAD {
 my $s =shift;
 my $m =substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
 $s->[0]->print($s->[0]->$m(@_));
}


