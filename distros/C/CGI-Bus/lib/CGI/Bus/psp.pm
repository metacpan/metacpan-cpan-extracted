#!perl -w
#
# CGI::Bus::psp - Perl Script Processor
#
# admiral 
#
# 

package CGI::Bus::psp;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::Base;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::Base);


1;


#######################


sub _fdir {           # File Dir
 ($_[1] ||'') =~/^(.+?)[\\\/][^\\\/]+$/ ? $1 : ($_[0]->ppath ||$_[1] ||'')
}


sub _furl {           # File URL
 my $s =shift;
 my $f =$_[0] ||$s->qpath;
 foreach my $b ('p','b') {
   my $m =$b .'path';
   my $p =$s->$m();
   next if lc(substr($f,0,length($p))) ne lc($p);
   my $u =length($f) >length($p)+1 ? substr($f,length($p)+1) : '';
   $m =$b .'url';
   return $s->$m($u)
 }
 $s->purl
}


sub evalf {           # PerlScript Eval File
  local @_ =@_;
  my $s =shift;
  my $o =substr($_[0],0,1) eq '-' ? shift : '-';
  my $u =shift;
  my $f =ref($u) ? $u->[0] : $u;
  my $t;
  my $h =CORE::eval('use IO::File; IO::File->new()');
  $h->open($f,'r') ||$s->parent->die("Cannot open file '" .($f||'') ."': $!");
  read($h, $t, -s $f) && close($h) || $s->parent->die("Cannot load '$f'");
  $s->eval($o,$s->parse($o, $t, $u), $f, @_);
}


sub eval {            # PerlScript Eval Source
 my $s =shift;
 my $p =$s->parent;
 my $o =substr($_[0],0,1) eq '-' ? shift : '-';
 my $t =shift;
 $p->print->httpheader() if $o !~/e/;  # -e to embed html
 $p->evalsub($t, $p, $o, @_);
 $p->die($@) if $@
}


sub parse {           # PerlScript Parse Source
 my $s   =shift;
 my $opt =substr($_[0],0,1) eq '-' ? shift : '-';
 my $i   =$_[0];
 my $o   ='';
 my ($ol,$or) =('','');
 my ($ts,$tl,$ta,$tc) =('','','','');
 if ($i =~/<(!DOCTYPE|html|head)/i && $`) {
     $i ='<' .$1 .$'
 }
 if ($_[1] && $i =~m{(<body[^>]*>)}i) {
     my ($i0,$i1) =($` .$1 ,$');
     $i =$i0
        .('<base href="'. $s->htmlescape(ref($_[1]) ? $_[1]->[1] : $s->_furl($s->_fdir($_[1]))).'/" />')
        .$i1
 }
 if ($opt =~/e/i && $i =~m{<body[^>]*>}i) {
    $i =$';
    $i =$` if $i =~m{</body>}i
 }
 while ($i) {
    if (not $i =~m{<(\%@|\%|SCRIPT) *(Language *= *|)* *(PerlScript|Perl|)* *(RUNAT *= *Server|)*[ >]*}i) {
       $ol =$i; $i ='';
       $ts ='';
    }
    elsif (($2 && !$3) || (!$3 && $tl eq '1')) {
       $ol =$` .$&;
       $i  =$';
       $tl =1;
       $tc =$ts ='';
    }
    elsif ($1) {
       $ol =$`; $i =$';
       $ts =uc($1||''); $tl =($2 && $3)||''; $ta=$4||'';
       if ($i =~m{ *(\%>|</SCRIPT>)}i) {$tc =$`; $i =$'}
       else                            {$tc =''}
    }
    else {
       $ol =$i; $i ='';
    }
    $ol =~s/(["\$\@%\\])/\\$1/g;
    $ol =~s/[\n]/\\n");\n\$_[0]->print("/g;
    $o .= "\$_[0]->print(\"$ol\\n\");\n";
    next if !$ts || !$tc || $ts eq '%@';
    $tc =~s/\&lt;?/</g;
    $tc =~s/\&gt;?/>/g;
    $tc =~s/\&amp;?/\&/g;
    $tc =~s/\&quot;?/"/g;
    if    ($ts eq '%')      { $o .= "\$_[0]->print($tc);\n" }
    elsif ($ts eq 'SCRIPT') { $o .= $tc .";\n"}
 }
 $o;
}


