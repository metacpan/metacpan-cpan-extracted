#!perl -w
#
# Notes application
#
# Initial Settings
#
use vars qw($s);
$s = do("../config.pl");
$s->set('-htmlstart')->{-title} =$s->server_name() .' - Notes';
#
# Form Description
#
$s->tmsql->set(-opflg =>'a') if !$s->uguest; #'<a!v'
$s->tmsql->set(
-form =>[
  {-tbl=>'cgibus.notes', -alias=>'notes'}
 ,{-flg=>'vqiskw"',-fld=>'id', -lbl=>'ID', -cmt=>'Unique identifier of the Note'
        ,-crt=>'New', -cdbi=>sub{$_[0]->user .'/' .$_[0]->strtime('yyyymmddhhmmss')}
        ,-lblhtml=>sub{
          $_[0]->htmlself({},-sel=>'id',$_,'$_')
		# $_[0]->htmlself({-title=>'Open records list'},-lst=>$_[0]->pxsw('LIST'),'AllActual','$_')
         .($_[0]->cmdg('-qry') ||$_[0]->param('idrm_b') ||$_[0]->param('idrm') ?''
          :$_[0]->submit(-name=>'idrm_b',-value=>'...',-title=>'Show record relations fields',-class=>'Form'))
         } 
        ,-inphtml=>'<font style="font-size: smaller;">$_</font>'
        }
 ,''
 ,{-flg=>'vqis"',  -fld=>'cuser'
        ,-lbl=>'Creator', -cmt=>'Who was created the Note'
        ,-crt=>sub{$_[0]->user}, -ins=>sub{$_[0]->user}}
 ,''
 ,{-flg=>'vqis"',  -fld=>'ctime'
        ,-lbl=>'Created', -cmt=>'When was created the Note'
        ,-crt=>sub{$_[0]->strtime}, -ins=>sub{$_[0]->strtime}
        ,-clst=>sub{"<font style=\"font-size: smaller;\"><nobr>$_</nobr></font>"}
        ,-lblhtml=>'',-inphtml=>'<nobr>$_</nobr>'
        }
 ,{-flg=>'vqis"',  -fld=>'idnv'
        ,-lbl=>'NewVer', -cmt=>'Pointer to new version of the Note'
        ,-null=>'', -hide=>sub{!$_}
        ,-lblhtml=>sub{$_[0]->htmlself({-title=>'Open new version of this record'},-sel=>'id'=>$_,'$_')}
        ,-inphtml=>'<font style="font-size: smaller;">$_</font>'
        }
 ,''
 ,{-flg=>'avqiuw"',-fld=>'uuser'
        ,-lbl=>'Updator', -cmt=>'Who was updated the Note'
        ,-crt=>'', -sav=>sub{$_[0]->user}}
 ,''
 ,{-flg=>'avqiu"',-fld=>'utime'
        ,-lbl=>'Updated', -cmt=>'When was updated the Note'
        ,-crt=>'', -sav=>sub{$_[0]->strtime}
        ,-clst=>sub{"<font style=\"font-size: smaller;\"><nobr>$_</nobr></font>"}
        ,-lblhtml=>'',-inphtml=>'<nobr>$_</nobr>'
        }
 ,{-flg=>'a"',     -fld=>'idrm'
        ,-lbl=>'MainRec', -cmt=>'Note above this in hierarchy'
        ,-hidel=>sub{!$_ && !$_[0]->param('idrm_b')}
        ,-null=>'', -crt=>sub{$_[0]->qparampv('id')}, -inp=>{-maxlength=>60}
        ,-lblhtml=>sub{$_[0]->htmlself({-title=>'Main note'},-sel=>'id'=>$_,'$_')}
        ,-inphtml=>'<font style="font-size: smaller;">$_</font>'
        }
 ,{-flg=>'am"', -fld=>'status'
        ,-lbl=>'Status', -cmt=>'Status of the Note'
        ,-crt=>'ok', -qry=>''
        ,-inp=>{-values=>[qw(ok edit deleted), '']}
        ,-clst=>sub{$_ =~/^(edit|deleted)/ ? "<B><FONT COLOR=\"red\">$_</FONT></B>" : $_}}
 ,''
 ,{-flg=>'a"',     -fld=>'prole'
        ,-lbl=>'PRole', -cmt=>'Principal Role, Group of Principals'
        ,-crt=>sub{
             return($_) if $_ ||($_ =$_[0]->udata->param('urole'));
             foreach my $u (@{$_[0]->ugroups}) {return $u if $u =~/(^[o]|\\[o])/};
             foreach my $u (@{$_[0]->ugroups}) {return $u if $u =~/(^[g]|\\[g])/};
             $_[0]->param('cuser')
          }
        ,-null=>'', -inp=>{-maxlength=>60}
        ,-lblhtml=>sub{$_[0]->htmlself({-title=>'Open Users'},-lst=>,$_[0]->pxsw('LIST')
                      ,$_ ? ('AllActual','prole'=>$_) : ('Users'), '$_')}
        ,-inphtml=>sub{$_[0]->htmlddlb('$_','auser_',sub{$_[0]->uglist({})}, qw(prole rrole),"\tmailto")}
        }
 ,''
 ,{-flg=>'a"',  -fld=>'rrole'
        ,-lbl=>'Reader', -cmt=>'Reader Role, Group of Readers of the Note'
        ,-crt=>sub{$_}, -null=>'', -inp=>{-maxlength=>60}
        ,-lblhtml=>sub{$_[0]->htmlself({-title=>'Open Users'},-lst=>,$_[0]->pxsw('LIST')
                      ,$_ ? ('AllActual','rrole'=>$_) : ('Users'), '$_')}
        }
 ,"\t","\t"
 ,{-flg=>'a"',  -fld=>'mailto'
        ,-lbl=>'eMailTo', -cmt=>'Receipients of e-mail about this record'
        ,-hide=>sub{!$_}
        ,-null=>'', -inp=>{-asize=>20, -maxlength=>255}, -colspan=>10
        }
 ,{-flg=>'am"', -fld=>'subject'
        ,-lbl=>'Subject', -cmt=>'Subject or Title followed by optional |URL or |_blank|URL'
        ,-crt=>sub{$_}
        ,-inp=>{-asize=>89, -maxlength=>255}, -colspan=>10
        ,-lblhtml=>sub{$_ && /^([^\|]+)\s*\|\s*(_blank|)[\s|]*((\w{3,5}:\/\/|\/).+)/ ? $_[0]->a({-href=>$3,-target=>$2,-title=>'Open URL'},'$_') : '$_'}
      # ,-inphtml=>'<STRONG>$_</STRONG>'
        ,-clst=>sub{$_ && /^([^\|]+)\s*\|\s*(_blank|)[\s|]*((\w{3,5}:\/\/|\/).+)/ ? $_[0]->a({-href=>$3,-target=>$2},$_[0]->htmlescape($1)) : $_[0]->htmlescape($_)}
        }
 ,{-flg=>'a"',  -fld=>'comment'
        ,-lbl=>'Comment', -cmt=>'Comment text or HTML code; host:// or urlh://, url:// or urlr://, fsurl:// or urlf:// URLs may be used; query condition within <where></where> <order_by></order_by> tags'
        ,-crt=>sub{$_}, -null=>''
        ,-inp=>{-cols=>68,-maxlength=>4*1024,-arows=>3,-hrefs=>1,-htmlopt=>1}
        ,-colspan=>10}
 ]);
#
# Lists (views) Description
#
$s->tmsql->set(
-lists =>{
  'AllVersions'=> {-lbl=>'All Versions', -cmt=>'All notes available, including old versions and deleted'
                  ,-fields=>[qw(utime idnv status subject)]
                  ,-orderby=>'utime desc, ctime desc'}
 ,'AllActual'=>   {-lbl=>,'All Actual', -cmt=>'All actual notes available'
                  ,-fields=>[qw(utime status subject)]
                  ,-orderby=>'utime desc, ctime desc'
                  ,-where=>"status !='deleted' AND notes.idnv is NULL"}

 ,'AllHier'=>     {-lbl=>,'All Hierarchical', -cmt=>'Hierarchy of all actual notes available'
                  ,-fields=>[qw(status subject)]
                  ,-orderby=>'subject asc'
                  ,-where=>"status !='deleted' AND notes.idnv is NULL AND notes.idrm is NULL"}
 ,'OurActual'=>   {-lbl=>'Our Actual', -cmt=>('Notes ' .$s->user .' involved in')
                  ,-fields=>[qw(utime status subject)]
                  ,-orderby=>'utime desc, ctime desc'
                  ,-filter=>sub{"status !='deleted' AND notes.idnv is NULL"
                   .$_[0]->aclsel('-','-and',qw(prole),$_[0]->unames,qw(cuser uuser))
                   }}
 ,'OurReadings'=> {-lbl=>'Our Readings', -cmt=>('Notes to read by ' .$s->user)
                  ,-fields=>[qw(utime status subject)]
                  ,-orderby=>'utime desc, ctime desc'
                  ,-filter=>sub{"status !='deleted' AND notes.idnv is NULL"
                   .$_[0]->aclsel('-','-and',qw(rrole))
                   }}
 ,'OurHier'=>     {-lbl=>'Our Hierarchical', -cmt=>('Hierarchy of notes ' .$s->user .' involved in')
                  ,-fields=>[qw(status subject)]
                  ,-orderby=>'subject asc'
                  ,-filter=>sub{"status !='deleted' AND notes.idnv is NULL AND notes.idrm is NULL"
                   .$_[0]->aclsel('-','-and',qw(prole),$_[0]->unames,qw(cuser uuser))
                   }}
 ,'PersActual'=>  {-lbl=>'Pers Actual', -cmt=>('Personally ' .$s->user .' notes')
                  ,-fields=>[qw(utime status subject)]
                  ,-orderby=>'utime desc, ctime desc'
                  ,-filter=>sub{"status !='deleted' AND notes.idnv is NULL"
                    .$_[0]->aclsel('-','-and',$_[0]->unames,qw(cuser uuser prole))
                   }}
 ,'PersHier_'=>   {-lbl=>'Pers Hierarchical_', -cmt=>('Hierarchy of personally ' .$s->user .' notes')
                  ,-fields=>[qw(status subject)]
                  ,-orderby=>'subject asc'
                  ,-filter=>sub{"status !='deleted' AND notes.idnv is NULL AND notes.idrm is NULL"
                    .$_[0]->aclsel('-','-and',$_[0]->unames,qw(cuser uuser prole))
                   }}
 ,'Users'=>       {-lbl=>'List Users', -cmt=>'List of users of notes'
                  ,-fields=>[qw(user)], -key=>[$s->tmsql->pxsw('WHERE')]
                  ,-href=>[undef,undef,'-lst',$s->tmsql->pxsw('LIST'),'AllActual']
                  ,-dsub=>sub{my $s =$_[0]; my %uh;
                     my @fl =qw(cuser uuser prole rrole);
                     foreach my $f (@fl){
                       my $sql ="SELECT notes.$f AS $f FROM cgibus.notes AS notes GROUP BY $f ORDER BY $f asc";
                       $s->pushmsg($sql);
                       foreach my $r (@{$s->dbi->selectcol_arrayref($sql)}) {
                          $uh{$r} =1 if $r;
                       }
                     }
                     [map {[$_, $s->dbi->quote($_) .' IN('
                              . join(',',map {'notes.'.$_} @fl) .')']}
                          sort keys %uh]
                   }
                  }
 });
#
# Version Store Description
#
$s->tmsql->set(
-vsd =>{
  -npf=>'idnv'     # new version pointer field
 ,-sf =>'status'   # status field
 ,-svd=>'edit'     # status, where record versioning disable
 ,-sd =>'deleted'  # status, where record is logically deleted
 ,-uuf=>'uuser'    # updator user field
 ,-utf=>'utime'    # update  time field
 });
#
#  File Store Description 
#
$s->tmsql->set(
-fsd => {
  -path  =>$s->fpath('notes/act') # actual records path
 ,-vspath=>$s->fpath('notes/ver') # old versions path
 ,-urf   =>$s->furf ('notes/act') # actual records base filesystem URL (for MSIE)
 ,-url   =>$s->furl ('notes/act') # actual records base URL (for all browsers)
 ,-vsurf =>$s->furf ('notes/ver') # old versions base filesystem URL
 ,-vsurl =>$s->furl ('notes/ver') # old versions base URL
 ,-ksplit=>sub{                   # key to dir split sub
           my @v;
           while ($_ =~/([\\\/])/) {$_ =$'; push @v, $` .$1}
           push @v,substr($_,0,4),substr($_,4,2),substr($_,6,2)
                  ,substr($_,8,2),substr($_,10) if @v;
           return @v
           }
 });
#
# Access Control Description
#
$s->tmsql->set(
-acd=>{
  -swrite=>['Administrators']   # system writers
 ,-sread =>['Administrators']   # system readers
 ,-write =>[qw(prole uuser cuser)]       # writer fields
 ,-read  =>[qw(prole uuser cuser rrole)] # reader fields
 });
#
# Filter Description
#
$s->tmsql->set(-fltlst =>sub{$_[0]->aclsel('-t',qw(prole rrole),$_[0]->unames,qw(cuser uuser))});
$s->tmsql->set(-ftext  =>'(' .join(' OR ', map {"notes.$_ LIKE \%\$_"} qw(subject comment cuser uuser prole rrole)) .')');
#
#
#
$s->tmsql->set(-cmdfrm =>sub{  # view related records in record form
    my $s =shift;
    $s->cmdfrm(@_);
    if ($s->cmd('-sel')) {
       $s->print->hr;
       $s->cmdlst('-gxm!q','AllActual'
         ,join(' OR '
              ,(map {"$_=" .$s->dbi->quote($s->qparam('id'))} 'notes.idrm')
              ,($s->qparam('comment')||'') !~/^<where>(.+)<\/where>(?:<order_by>(.+)<\/order_by>){0,1}/
               ? () : (($2 ? $s->qparamsw('ORDER_BY', $2) : 1) && "($1)")
              )
         )
    }
});
#
#
#
$s->tmsql->set(-rowsav1=>sub { # mail send
    my $s =shift;
    return($s) if !$s->param('mailto');
    return($s) if  $s->param('status') =~/edit|template|deleted/;
    my $subj =join(' ', map {$s->param($_)} qw(subject));
    $s->smtp(-host=>'localhost',-domain=>$s->server_name()
     )->mailsend(
        "From: "    .$s->user
       ,"Subject: " .$s->cptran('1251','koi8',$subj)
       ,[split /\s*[;,]\s*/, $s->param('mailto')]
       ,"MIME-Version: 1.0"
       ,"Content-type: text/html; charset=windows-1251\n"
       ,$s->start_html($s->parent->{-htmlstart})  # $s->htpgstart()
       ,$s->htmlself(-sel=>'id'=>$s->param('id'),$subj),'<BR>'
       ,$s->{-fields}->{'comment'}->{-htmlopt} && $s->ishtml($s->param('comment'))
        ? $s->param('comment') : $s->htmlescapetext($s->param('comment'))
       ,$s->htpgend()
       );
    $s
});
#
#
# Run Application
#
$s->tmsql->evaluate;


