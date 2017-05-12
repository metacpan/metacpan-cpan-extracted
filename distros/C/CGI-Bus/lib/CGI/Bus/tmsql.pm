#!perl -w
#
# CGI::Bus::tmsql - SQL Transaction Manager
#
# admiral 
#
# 

package CGI::Bus::tmsql;
require 5.000;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Bus::tm;
use vars qw(@ISA);
@ISA =qw(CGI::Bus::tm);


1;



sub _setform {  # Arrange Form to Fields
 my $s =shift;
 $s->{-fields} ={};
 my ($st, $sta);
 my $lng  =$s->lngname;
 my $lngl ='-lbl' .($lng ? "_$lng" : '');
 my $lngc ='-cmt' .($lng ? "_$lng" : '');

 foreach my $f (@{$s->{-form}}) {
   next if !ref($f) || ref($f) eq 'CODE';

   if ($f->{-tbl}) {
      $st  =$f;
      $sta =$st->{-alias}||$st->{-tbl};
      next;
   }

   $s->{-fields}->{$f->{-fld}} =$f;
   $f->{-table} =$st->{-tbl};     # parent table
   $f->{-talias}=$sta;            # parent table alias
   $f->{-colns} =                 # column name for select
                 !$f->{-col} ? $sta .'.' .$f->{-fld} 
                :index($f->{-col},'(') >=0 ? $f->{-col}
                :index($f->{-col},'.') >=0 ? $f->{-col}
                :$sta .'.' .$f->{-col};

   $s->{-keyfld} =$f->{-fld}      # key field
              if !$s->{-keyfld} && $f->{-flg} =~/k/;
   if ($lng) {
      $f->{-lbl} =$f->{$lngl} if $f->{$lngl};
      $f->{-cmt} =$f->{$lngc} if $f->{$lngc};
   }
 }
}




###################################
# TRANSACTION METHODS
###################################

 
sub eval {     # Transaction DBI run
 my $s =shift;
 my $r =ref($_[$#_]) eq 'CODE' ? pop : sub{$s->cmd('-cmd')};
 my $e =undef;
 my $d =$s->dbi(@_);
 local $s->parent->{-problem} ='';
 my $ac =$d->{AutoCommit};
 CORE::eval {$d->{AutoCommit}=0};
 if (!CORE::eval {
   local $d->{RaiseError}=1; 
   $r =&$r($s);
   if (!$d->{AutoCommit}) {
      $s->pushmsg('COMMIT');
      $d->commit;
   };
   1;
 }) {
    $e =$@ ||'Undefined Error';
    if (!$d->{AutoCommit}) {
       $s->pushmsg('ROLLBACK');
       CORE::eval{$d->rollback}
    }
    $r =undef
 }
 print $s->htmlres(!$e,$e)	if $e
				||((($s->qparamsw('MIN')||'') !~/r/)
				   && ($s->parent->{-cache}->{-htmlstart} ||!$s->cmd('-lst'))
					);
 $d->{AutoCommit} =$ac if $d->{AutoCommit} ne $ac;
 $r
}




###################################
# SQL GENERATOR UTILITY
###################################



sub htmlddlb {  # HTML Drop-Down List Box - Input Helper
 my ($s,$w,$n,$ds) =(shift
	#,!$_[0] || $_[0] =~/^(?:<|\$_|\s)/ || $_[0] =~/(?:>|\$_|\s)$/ ? shift : undef
	,shift
	,shift, shift);
 my $dc =ref($_[0]) ? shift : [];              # data container
 my $df =ref($_[0]) eq 'CODE' ? shift : undef; # data feed sub
 my $g =$s->cgi;
 if ($g->param($n .'_B')) {
    $ds =&$ds($s) if ref($ds) eq 'CODE';
    if (!ref($ds)) {
        my $sel =$ds;
        if ($s->{-lists}->{$ds}) {
            local $s->{-listrnm} =$s->{-lboxrnm};
            $s->cmdlst('-g!q', $ds);
            $sel =$s->{-gensel};
        }
        $ds =$dc;
        $s->pushmsg($sel);
        my $c =$s->dbi->prepare($sel);
           $c->execute;
        my $lr=$s->{-lboxrnm};
        my $r;
        my $rc =0;
        while ($r =$c->fetch) {
           if    ($df) {&$df($s,$ds,$r)}
           elsif (ref($dc) eq 'ARRAY') {push @$ds, defined($r->[0]) ? $r->[0] : ''}
           else                   {$ds->{defined($r->[0]) ? $r->[0] : ''} =defined($r->[1]) ? $r->[1] : ''}
           last if ++$rc >=$lr;
        }
        $s->pushmsg($rc <=$lr ? $s->lng(1,'rfetch',$rc) : $s->lng(1,'rfetchf',$lr));
        $c->finish;
    }
    $s->parent->htmlddlb($w, {-name=>$n, -class=>'Form'}, $ds
        ,map {[$_=>$s->{-fields}->{$_=~/^\t/ ?substr($_,1) :$_}->{-lbl}||$_]} @_)
 }
 else {
    $s->parent->htmlddlb($w, {-name=>$n, -class=>'Form'}, $ds, @_)
 }
}


sub htmllst {   # List Data by SQL Select or array ref
 my ($s, $ds, $dc, $kc, $hr, $lh, $rj, $cj, $le) =@_;
 my $p =$s->parent;
 my $g =$s->cgi;
 # self, data, display, {key=>name}, [href], rowjoin, coljoin
 my $c;
 $ds =&$ds($s) if ref($ds) eq 'CODE';
 if (!ref($ds)) {
    if ($s->{-lists}->{$ds}) {
       $s->cmdlst('-g!q', $ds);
       $ds =$s->{-gensel};
    }
    $s->pushmsg($ds);
    $c =$s->dbi->prepare($ds);
    $c->execute;
    $ds =undef;
 }
 $lh ='' if !defined($lh);
 $rj ='' if !defined($rj);
 $cj ='' if !defined($cj);
 $le ='' if !defined($le);
 my $lr=$s->qparamsw('LIMIT') ||$s->{-listrnm};
 my $rc =0;
 my $r;
 $r = !$ds ? $c->fetch : shift @$ds;
 @$dc= (0..$#{$r}) if $r && (!defined($dc) || !scalar(@$dc));

 my @hr0=$hr ? @$hr :();
       $hr0[0] =$p->qurl         if !$hr0[0];
       $hr0[1] =$s->pxcb('-cmd') if !$hr0[1];
       $hr0[2] ='-sel'           if !$hr0[2];
 my $mh =-1;
 my $mr =$#{$dc};
    $mh =$mr if $mh <0;
    $mh =-1  if !defined($kc) ||!scalar(%$kc);
 local $_;
 while ($r) {  
   my $href =$p->htmlurl(@hr0
             ,(map {($kc->{$_}, $r->[$_])} sort keys %$kc))
             if $mh >0;
    
   last if !print $rc >0 ? $rj : $lh
       ,join($cj
         ,(map {$g->a({-href=>$href,-target=>$s->{-formtgf}}
                     ,!defined($r->[$_]) || $r->[$_] eq '' ? '&nbsp&nbsp' : $p->htmlescape($r->[$_]))
           } @$dc[0..$mh])
         ,$mr !=$mh ? (map {$p->htmlescape($r->[$_])} @$dc[$mh+1..$mr])
                    : ()
       );
   if (++$rc >=$lr) {
      last
   }
   $r = !$ds ? $c->fetch : shift @$ds
 }
 print $le if $rc;
 $s->pushmsg($s->{-genlstm} =$rc <=$lr ? $s->lng(1,'rfetch',$rc) : $s->lng(1,'rfetchf',$lr));
 $c->finish if $c;
}


sub keyfld {  # Single Key field
 $_[0]->_setform if !$_[0]->{-keyfld};
 $_[0]->{-keyfld}
}


sub keyval {  # Key value
 $_[0]->qparam((!$_[1] ? '' : substr($_[1],0,1) eq '-' ? $_[0]->{$_[1]} : $_[1]) .$_[0]->keyfld)
}




###################################
# SQL GENERATOR TRANSACTION COMMANDS
###################################



sub cmdchk { # Check / Calculate Data before save
 my $s =shift;
 $s->SUPER::cmdchk(@_);
 $s->cgi->delete($s->{-vsd}->{-npf}) 
	if $s->{-vsd} && $s->{-vsd}->{-npf};
 do {$s->cgi->delete($s->pxsw('EDIT')); delete $s->{-cmde}}
	if !$s->{-vsd} || !$s->{-vsd}->{-sf} || !$s->{-vsd}->{-svd} || !$s->qparam($s->{-vsd}->{-sf}) || !($s->qparam($s->{-vsd}->{-sf}) eq $s->{-vsd}->{-svd});
 $s
}


sub cmdsql { # Insert / Update / Delete Record
 my $s    =shift;
 my $cmd  =shift;
 my $op   =substr($cmd,1,1);# 'i'nsert | 'u'pdate | 'd'elete
 my $opt  =(shift) ||'-gx'; # 'g'enerate + e'x'ecute
 my $pxpv =shift;           # previous value param prefix
    $pxpv =!defined($pxpv) ? $s->{-pxpv}
          : substr($pxpv,0,1) eq '-' ? ($s->{$pxpv} ||$pxpv)
          : $pxpv;
 my $pxcv =shift;          # current value param prefix
    $pxcv =!defined($pxcv) ? ''
          : substr($pxcv,0,1) eq '-' ? ($s->{$pxcv} ||$pxpv)
          : $pxcv;
 my $st   =''; # statement table
 my $sta  =''; #           alias
 my $sto  =''; #           oldname
 my $sts  =''; # statement tables string
 my $sws  =''; #           where  string
 my $swps =''; #           where  parameters string
 my $ipns =''; # input parameter names string
 my $ipvs =''; #                 values string

 if ($opt =~/[gp]/) {         # Evaluate Form
    foreach my $f (@{$s->{-form}}) {               # convert field values
      next if !ref($f) || ref($f) eq 'CODE' || $f->{-tbl} || !$f->{'-cdb' .$op};
      local $_ =$s->param($pxcv .$f->{-fld});
      $s->param($pxcv .$f->{-fld}, &{$f->{'-cdb' .$op}}($s, $pxcv));
    }

    if ($opt =~/[x]/) {                            # assure before SQL trigger
        $s->die($s->lng(1,'op!let',$s->lng(0,$cmd)) ."\n") 
	 if ($s->{-rowsav2} &&           !&{$s->{-rowsav2}}($s,$cmd,$opt,$pxpv,$pxcv))
	 || ($s->{-rowsav1} && !$pxcv && !&{$s->{-rowsav1}}($s,$cmd,$opt,$pxpv,$pxcv));
    }
 }
 
 if ($opt =~/[gp]/) {         # Parse Form
    foreach my $f (@{$s->{-form}}) { 
      next if !ref($f) || ref($f) eq 'CODE';
      my $tskip =1; # skip table in 'from'

      if ($f->{-tbl}) {                            # turn on table
         $st  =$f;
         next
      }

      if ($op =~/[iu]/ && $f->{-flg} =~/[a$op]/    # update string
      &&!($op =~/i/ && $f->{-flg} =~/g/)) {        # do not insert generated values
          my $p  =$s->param($pxcv .$f->{-fld});
          local $_ =$p;
          if (defined($p)) {
             $tskip =0;
             $p =&{$f->{-cdb}}($s,$pxcv) if $f->{-cdb};
             $ipns .=($ipns ? ', ' :'') .($f->{-col} ||$f->{-fld});
             $ipvs .=($ipvs ? ', ' :'');
             $ipvs .=($f->{-col} ||$f->{-fld}) .'=' if $op =~/u/;
             if (0) {}
             elsif (defined($f->{-null}) && $p eq $f->{-null}) {$p ='NULL'}
             elsif ($p eq 'NULL') {}
             elsif ($f->{-flg} =~/(["'])/) { # quote
               my $q =$1;
               $p = $s->dbi ? $s->dbi->quote($p) :"$q$p$q";
             }
             $ipvs .=$p
          }
      }

      if ($op =~/[ud]/ && $f->{-flg} =~/[wk]/) {   # where condition
          my $p  =$s->param($pxpv .$f->{-fld});          
          local $_ =$p;
          if ($p || $f->{-flg} =~/[k]/) {
             $tskip =0;
             $p =&{$f->{-cdb}}($s,$pxcv) if $f->{-cdb};
             $swps .=($swps ? ' AND ' :'') .($f->{-col} ||$f->{-fld});
             if (0) {}
             elsif (!defined($p)) {
               $swps .=' IS NULL'
             }
             elsif (defined($f->{-null}) && $p eq $f->{-null}) {
               $swps .=' IS NULL'
             }
             elsif ($p eq 'NULL') {
               $swps .=" IS $p"
             }
             elsif ($f->{-flg} =~/(["'])/) { # quote
               my $q =$1;
               $p = $s->dbi ? $s->dbi->quote($p) :"$q$p$q";
               $swps .=" = $p"
             }
             else {
               $swps .=" = $p"
             }
          }
      }

      if ($st ne $sto && !$tskip) {                # push table
          $sto  =$st;
          $sts .=(!$sts ? '' : ', ') .$st->{-tbl} 
      }
    }
 }

 if ($opt =~/[g]/) {          # Assembly SQL Statement  
    if ($op =~/[ud]/) {
       foreach my $v ($swps, ($s->{-fltedt} ||$s->{-filter})) {
         my $vv=(ref($v) ? &$v($s): $v);
         $sws .=(!$sws ? '' : ' AND ') 
              .'(' . $vv.') '
              if $vv
       }
       $s->{-genwhr} =$sws;
    }
    $s->{-genfrom} =$sts;
    $s->{-genedt}  =$op =~/i/ ? "INSERT INTO $sts ($ipns) VALUES ($ipvs)"
                   :$op =~/u/ ? "UPDATE $sts SET $ipvs WHERE $sws"
                   :$op =~/d/ ? "DELETE FROM $sts WHERE $sws"
                   : '';
 }

 if ($opt =~/x/ && $s->dbi) { # Execute SQL Statement 

    $s->pushmsg($s->{-genedt});
    $s->dbi->do($s->{-genedt});

    foreach my $f (@{$s->{-form}}) { 
      next if !ref($f) || ref($f) eq 'CODE' || !$f->{-fld};
      if ($f->{'-cdb' .$op .'a'}) { # after command   
         local $_ =$s->param($pxcv .$f->{-fld});
         $s->param($pxcv .$f->{-fld}, &{$f->{'-cdb' .$op .'a'}}($s, $pxcv));
      }
    }
    &{$s->{-rowsav2a}}($s,$cmd,$opt,$pxpv,$pxcv) if $s->{-rowsav2a};
    &{$s->{-rowsav1a}}($s,$cmd,$opt,$pxpv,$pxcv) if $s->{-rowsav1a} && !$pxcv;
 }
}


sub _vscmn { # Versioning Common Code
 my $s    =shift;
 my $v    =$s->{-vsd}; return if !$v;
 my $p    =$s->parent;
 my $c    =shift;          # command: 'i'nsert, 'u'pdate, 'd'elete
 my $opt  =shift;          # options
    $opt  ='' if !defined($opt);
 my $pxpv =shift;          # previous value param prefix
    $pxpv =!defined($pxpv) ? $s->{-pxpv}
          : substr($pxpv,0,1) eq '-' ? ($s->{$pxpv} ||$pxpv)
          : $pxpv;
 my $pxcv =shift;          # current value param prefix
    $pxcv =!defined($pxcv) ? ''
          : substr($pxcv,0,1) eq '-' ? ($s->{$pxcv} ||$pxpv)
          : $pxcv;
 my $b =1; # backup
 if ($c =~/[ud]/) {
    $s->die("Editing of version of record prohibited\n") if $v->{-npf} && $s->qparam($pxpv .$v->{-npf});
    $b =$v->{-cvd} ? !&{$v->{-cvd}}($s)
       :$v->{-svd} ? !($v->{-svd} eq $s->qparam($pxpv .$v->{-sf}))
       :1;
    if ($b && $opt !~/!v/) {
       my %save;
     # my $save =$s->qparamh($s->qparampx('-pxpv'));
       if ($v->{-npf}) {
          $save{$v->{-npf}} =$s->qparam($pxpv .$v->{-npf});
          $s->qparam($pxpv .$v->{-npf}, $s->qparam($pxcv .$s->keyfld))
       }
       foreach my $f (@{$s->{-form}}) { 
          next if !ref($f) || ref($f) eq 'CODE' 
               || !$f->{-fld} || !($f->{-cdbi} || $f->{-cdbia});
          $save{$f->{-fld}} =$s->qparam($pxpv .$f->{-fld});
       }

       $s->cmdsql('-ins',undef,undef,'-pxpv');
       if ($s->{-fsd}  # backup files
       && $c eq 'u'
       && (!$v->{-svd} || ($v->{-svd} eq $s->qparam($pxcv .$v->{-sf})))
       && -d $s->fspath) {
          $s->fspathcp(undef,     [1, $s->keyval($pxpv)]);
          $s->fsacl('r', '-pxpv', [1, $s->keyval($pxpv)]);
       }

       foreach my $fn (keys %save) {$s->qparam($pxpv .$fn, $save{$fn})}
    }

    if ($c eq 'd') {
       $s->qparam($pxcv .$v->{-sf}, $v->{-sd}) if $v->{-sd};
    }
 }
 $p->cgi->param($pxcv .$s->{-vsd}->{-uuf}, $p->user)    if $s->{-vsd}->{-uuf};
 $p->cgi->param($pxcv .$s->{-vsd}->{-utf}, $p->strtime) if $s->{-vsd}->{-utf};
}


sub _fscmn {  # File Store Common Code
 my $s    =shift;
 my $v    =$s->{-vsd}; return if !$s->{-fsd};
 my $p    =$s->parent;
 my $c    =shift;          # command: 'i'nsert, 'u'pdate, 'd'elete
 my $opt  =shift;          # options
 my $pxpv =shift;          # previous value param prefix
    $pxpv =!defined($pxpv) ? $s->{-pxpv}
          : substr($pxpv,0,1) eq '-' ? ($s->{$pxpv} ||$pxpv)
          : $pxpv;
 my $pxcv =shift;          # current value param prefix
    $pxcv =!defined($pxcv) ? ''
          : substr($pxcv,0,1) eq '-' ? ($s->{$pxcv} ||$pxpv)
          : $pxcv;
 if ($c =~/[iu]/) {
    my $fsa =!$v ? 'w'
            :$v->{-cvd} ? (&{$v->{-cvd}}($s) ? 'w' : 'r')
            :$v->{-svd} ? (($v->{-svd} eq $s->qparam($pxcv .$v->{-sf})) ? 'w' : 'r')
            :'';
    my $fsc =$c =~/[i]/ && $s->keyval($pxpv) 
                        && -d $s->fspath($s->keyval($pxpv));
    $s->fspathmk($s->qparam($pxcv .$s->keyfld))  
                           if $fsa eq 'w' || $fsc;

    $s->fspathcp($s->keyval($pxpv), $s->keyval($pxcv))
                           if $fsc;
    $s->fsacl($fsa, $pxcv) if ($fsa || $fsc) && -d $s->fspath;
  # $s->fsacl($fsa, $pxcv) if $fsc; # 'fsacl' above was above 'fspathcp'
 }
}


sub cmdins { # Insert Record
 my $s =shift;
 $s->acltest('-ins','');
 $s->die($s->lng(1,'op!let',$s->lng(0,'-ins')) ."\n") 
        if ($s->{-rowins} && !&{$s->{-rowins}}($s)) 
        || ($s->{-rowsav} && !&{$s->{-rowsav}}($s))
	|| ($s->{-opflg}  && ($s->{-opflg} !~/[aci]/ || $s->{-opflg} =~/![ci]/));
 $s->_vscmn('i',@_) if $s->{-vsd};
 $s->cmdsql('-ins',@_);
 $s->_fscmn('i',@_)  if $s->{-fsd};
}


sub cmdupd { # Update Record
 my $s =shift;
 $s->cmdsel(undef,'-pxpv') if !$_[0] || $_[0] !~/!s/;
 $s->acltest('-upd','-pxpv');
 $s->die($s->lng(1,'op!let',$s->lng(0,'-upd')) ."\n") 
        if ($s->{-rowupd} && !&{$s->{-rowupd}}($s)) 
        || ($s->{-rowsav} && !&{$s->{-rowsav}}($s))
	|| ($s->{-opflg}  && ($s->{-opflg} !~/[aeu]/ || $s->{-opflg} =~/![eu]/));
 $s->_vscmn('u',@_) if $s->{-vsd};
 $s->cmdsql('-upd',@_);
 $s->_fscmn('u',@_)  if $s->{-fsd};
}


sub cmddel { # Delete Record
 my $s =shift;
 $s->cmdsel(undef,'-pxpv') if !$_[0] || $_[0] !~/!s/;
 $s->acltest('-del','-pxpv');
 $s->die($s->lng(1,'op!let',$s->lng(0,'-del')) ."\n") 
        if ($s->{-rowdel} && !&{$s->{-rowdel}}($s)) 
        || ($s->{-rowsav} && !&{$s->{-rowsav}}($s))
	|| ($s->{-opflg}  && ($s->{-opflg} !~/[ad]/ || $s->{-opflg} =~/![d]/));
 if ($s->{-vsd}) {
    $s->_vscmn('d',@_);
    $s->cmdsql('-upd',@_);
 }
 else {
    $s->cmdsql('-del',@_);
    $s->fspathrm() if $s->{-fsd} && -d $s->fspath;
 }
}


sub cmdsel { # Select Record
 my $s    =shift;
 my $opt  =shift ||'-gx';         # 'g'enerate + e'x'ecute
 my $pxsv =shift;                 # param name prefix
    $pxsv =!defined($pxsv) ? ''   
          : substr($pxsv,0,1) eq '-' ? ($s->{$pxsv} ||$pxsv)
          : $pxsv;
 my $st   =''; # select table
 my $sta  =''; #              alias
 my $sto  =''; #              oldname
 my $sfdl =[]; # select fields definitions list
 my $sts  =''; # select tables string
 my $sws  =''; #        where  string
 my $swps =''; #        where  parameters string
 
 if ($opt =~/[gp]/) {              # Parse Form
    foreach my $f (@{$s->{-form}}) {
      next if !ref($f) || ref($f) eq 'CODE';
      my $tskip =1; # skip table in 'from'

      if ($f->{-tbl}) {            # turn on table
         $st  =$f;
         $sta =$st->{-alias}||$st->{-tbl};
         next;
      }
      if ($f->{-flg} =~/[sa]/) {   # select fields
          push @$sfdl, $f;
          $tskip =0;
      }
      if ($f->{-flg} =~/[wk]/      # where condition
      &&!($f->{-flg} =~/g/         # do not use generated on insert values
       && $s->{-cmd} eq '-ins')) { 
          my $p  =$s->param($pxsv .$f->{-fld});
          if (defined($p)) {
             $tskip =0;
             if ($f->{-cdb}) {local $_ =$p; $p =&${$f->{-cdb}}($s,$p)}
             my $fm =$f->{-fld};
             $swps .=($swps ? ' AND ' :'');
             if (0) {}
             elsif (defined($f->{-null}) && $p eq $f->{-null}) {
               $swps .="$fm IS NULL"
             }
             elsif ($p eq 'NULL') {
               $swps .="$fm IS $p"
             }
             elsif ($f->{-flg} =~/(["'])/) { # quote
               my $q =$1;
               $p = $s->dbi ? $s->dbi->quote($p) :"$q$p$q";
               $swps .="$fm = $p"
             }
             else {
               $swps .="$fm = $p"
             }
          }
      }
      if ($st ne $sto && !$tskip) {# push table
          $sto  =$st;
          $sts .=(!$sts ? '' : ($st->{-join}||',') .' ') 
                .$st->{-tbl} .' AS ' .$sta 
                .($st->{-joina} ? ' ' .$st->{-joina} :'')
                .' ';
          $sws .=(!$sws ? '' : ' AND ') .'(' .$st->{-joinw} .') ' if $st->{-joinw}
      }
    }
 }

 if ($opt =~/[g]/) {               # Assembly SQL Select Statement  
    foreach my $v ($swps, ($s->{-fltsel} ||$s->{-filter})) {
      my $vv=(ref($v) ? &$v($s): $v);
      $sws .=(!$sws ? '' : ' AND ') 
           .'(' . $vv.') '
           if $vv
    }
    $s->{-genwhr}  =$sws;
    $s->{-genfrom} =$sts;
    $s->{-gensel}  ='SELECT ' .join(', ',map {$_->{-colns} 
                              .' AS ' .$_->{-fld}} @$sfdl)
                   ." FROM $sts "
                   ." WHERE $sws";
 }

 if ($opt =~/x/ && $s->dbi) {      # Execute SQL Select Statement 
    $s->pushmsg($s->{-gensel});
    my $p =$s->parent;
    my $g =$s->cgi();
    my $r =[$s->dbi->selectrow_array($s->{-gensel})];
    $s->pushmsg($s->lng(1,'rfetch', 1)) if  scalar(@$r);
    $s->die($s->lng(1,'!rfetch') ."\n") if !scalar(@$r);
    $s->problem($s->lng(1,'!rfetch') ."\n") if !scalar(@$r) && 0;
    local  $_;
    for (my $c =0; $c <=$#{$r}; $c++) {
      my $f =$sfdl->[$c];      
      $_ =$r->[$c];
      $_ =&{$f->{-cstr}}($s,$_,$r,$c) if $f->{-cstr};
      $_ =$f->{-null} if !defined($_) && defined($f->{-null});
      $g->param(-name=>($pxsv .$f->{-fld}),-value=>$_);
      $g->param(-name=>$s->pxpv($f->{-fld}),-value=>$_) if !$pxsv;
    }
    &{$s->{-rowsel3a}}($s,$s->cmd,$opt,$pxsv) if $s->{-rowsel3a};
    &{$s->{-rowsel2a}}($s,$s->cmd,$opt,$pxsv) if $s->{-rowsel2a};
    &{$s->{-rowsel1a}}($s,$s->cmd,$opt,$pxsv) if $s->{-rowsel1a} && $pxsv;
 }
}


sub cmdcrt { # Create Fields
 my $s   =shift;
 $s->SUPER::cmdcrt(@_);
 $s->cgi->delete($s->{-vsd}->{-npf}) if $s->{-vsd} && $s->{-vsd}->{-npf};
 $s
}


sub cmdqry { # Query Condition Init
 my $s   =shift;
 $s->SUPER::cmdqry(@_);
 $s
}


sub cmdhtm { # Common HTML
  my $s =shift;
  if ($s->{-cmde} && $s->{-acd} && $s->{-fsd} && $s->cmd('-frm') && $s->cmdg('-sel')) {
     $s->cmdsel(undef,'-pxpv') if !$s->cmd('-sel');
     $s->acltest('-sel','')    if  $s->cmd('-sel');
     $s->{-cmde} =eval{$s->acltest('-upd','-pxpv')};
  }
  elsif ($s->{-acd} && $s->cmd('-sel')) {
     $s->acltest('-sel','');
     $s->{-cmde} =eval{$s->acltest('-upd','-pxpv')} if $s->{-cmde};
  }
  $s->SUPER::cmdhtm(@_);
  $s
}


sub cmdfrm { # Record form for Query or Edit
 my $s =shift;
 $s->SUPER::cmdfrm(@_);
 my $p =$s->parent;
 my $ed=$s->{-cmde} && $s->cmdg(qw(-sel -crt -frm));

 if (!$s->cmdg('-qry') && $s->{-fsd} && -d $s->fspath) {
  # $p->print->text('<br />');
    my $ed = $ed && (!$s->{-vsd} 
                 || ($s->{-vsd}->{-cvd} ? (&{$s->{-vsd}->{-cvd}}($s))
                    :$s->{-vsd}->{-svd} ? $s->{-vsd}->{-svd} eq $s->qparampv($s->{-vsd}->{-sf})
                    :0));
    $p->print->htmlfsdir({-name=>$s->pxsw('files'), -class=>'Form'}
	, $ed, $ed && $s->cmd('-frm')
        , $s->fspath, $s->fsurl, $s->fsurf, '20%','100%');
    $p->print("\n");
  # $p->print->text('<hr />')
  #   if $s->cmd('-sel') && $s->{-vsd} && $s->{-vsd}->{-npf};
 }

 if ($s->cmd('-sel') && $s->{-vsd} && $s->{-vsd}->{-npf} && ($s->qparamsw('MIN')||'') !~/v/) {
     $s->_cmdfrmv();
 }

 if ($s->cmdg('-qry')) {
     my $vw =$s->{-lists} ? $s->{-lists}->{$s->qlst} : undef;
     my $vwf=($vw && $vw->{-fields} ? $s->htmlescape(join(', ',@{$vw->{-fields}})):'');
     my $vww=$vw ? ($vw->{-where} || $vw->{-filter} ||'') : '';
        $vww=$s->htmlescape(ref($vww) ? &$vww($s) : $vww);
     my $vwo=($vw && $vw->{-orderby} ? $vw->{-orderby} :'');
        $vwo=$s->htmlescape(ref($vwo) 
                  ? join(',', map {ref($_) ? join(' ',@$_): $_} @$vwo)
                  : $vwo);
     $p->print('<hr />');
     $p->print('<table>');
    if ($s->{-lists}) {
     $p->print('<tr>');
     $p->print->th({-align=>'left',-valign=>'top',-class=>'Form'},$s->lng(0,'LIST'));
     $p->print->td({-valign=>'top',-class=>'Form'}
			,$p->popup_menu(-name=>$s->pxsw('LIST')
			,-title =>$s->lng(1,'LIST')
			,-values=>$s->qlstnmes
			,-labels=>$s->qlstlbls
			,-default=>$s->qlst
			,-class=>'Form')
                  . ($vwf ? "<font style=\"font-size: smaller;\"> ($vwf)</font>" :''));
     $p->print('</tr>');
    }
     $p->print('<tr>');
     $p->print->th({-align=>'left',-valign=>'top',-class=>'Form'},$s->lng(0,'WHERE'));
     $p->print->td({-valign=>'top',-class=>'Form'}
                  ,$p->htmltextarea(-name =>$s->pxsw('WHERE')
				,-title=>$s->lng(1,'WHERE')
				,-class=>'Form'
				,-arows=>2,-cols=>68)
                  .($vw && $vw->{-wherepar} && !$s->qparamsw('WHERE')
                    ? ('<font style="font-size: smaller;"> [ AND (' .$p->htmlescape($vw->{-wherepar}) .') ]</font>') 
                    : '')
                  .($vww ? "<font style=\"font-size: smaller;\"> AND ($vww)</font>" :''));
     $p->print('</tr><tr>');
    if ($s->{-ftext}) {
     $p->print->th({-align=>'left',-valign=>'top',-class=>'Form'},$s->lng(0,'F-TEXT'));
     $p->print->td({-valign=>'top',-class=>'Form'}
                  ,$p->textfield(-name =>$s->pxsw('FTEXT')
				,-title=>$s->lng(1,'F-TEXT')
				,-class=>'Form'
				,-size =>88));
     $p->print('</tr><tr>');
    }
     $p->print->th({-align=>'left',-valign=>'top',-class=>'Form'},$s->lng(0,'ORDER BY'));
     $p->print->td({-valign=>'top',-class=>'Form'}
                  ,$p->textfield(-name =>$s->pxsw('ORDER_BY')
				,-title=>$s->lng(1,'ORDER BY')
				,-class=>'Form'
				,-size =>88) 
                  .($vwo ? "<font style=\"font-size: smaller;\"> ($vwo)</font>" : ''));
     $p->print('</tr><tr>');
     $p->print->th({-align=>'left',-valign=>'top',-class=>'Form'},$s->lng(0,'LIMIT ROWS'));
     $p->print->td({-valign=>'top',-class=>'Form'}
                  ,$p->textfield(-name=>$s->pxsw('LIMIT')
			,-class=>'Form'
			,-title=>$s->lng(1,'LIMIT ROWS')) 
                  .'<font style="font-size: smaller;"> (' .($s->{-listrnm}||'') .')</font>');
     $p->print('</tr>');
     $p->print('</table>');
     $p->print->text('<font style="font-size: smaller;">'
     ."Use <code>expr LIKE 'pattern'</code> for simple match comparison, where "
     ."'%' matches any number of characters (even zero), "
     ."'_'  matches exactly one character, "
     ."'\\' is escape char."
     .'</font>');
     $p->print->text('<br /><font style="font-size: smaller;">Self URL may be useful: ' 
	# .$p->cgi->self_url 
	.$p->qurl() .'?' .join(';', map {$p->urlescape($_) .'=' .$p->urlescape($p->cgi->param($_))} grep {defined($p->cgi->param($_)) && $p->cgi->param($_) ne '' && $_ =~/^(_tsw|_tcb|[^_])/ && $_ !~/^(_tsw_REFERER|_tsw_FRMCOUNT|_tcb_frm)/} $p->cgi->param)
	.'</font>');

     if ($s->{-acd} && eval{$s->acltest('-sys')}) { # System Actions
        print "<hr />\n<strong>System Actions:</strong> ";
        if ($s->{-fsd}) { # FS Scan
           $p->print->submit(-name=>$s->pxcb('fsscan')
                     , -value=>'Check/Correct File Store'
                     , -title=>'Scan File Store for problems');
           $s->fsscan() if $s->param($s->pxcb('fsscan'));
        }
     }
 }
}


sub _cmdfrmv {# List Record's Versions
 my $s =shift;
 return if !$s->{-vsd};
 my $fl =$s->{-fields};
 my $utf=$s->{-vsd}->{-utf};
 my $uuf=$s->{-vsd}->{-uuf};
 my $npf=$s->{-vsd}->{-npf};
 my $kf =$s->keyfld;
 my $kv =$s->param($kf);
 my $tbl = $s->{-fields}->{$kf}->{-table};
 my(@sl, @vl, @kl);
 if ($utf) {push @sl, $utf; push @vl, $#sl};
 if ($uuf) {push @sl, $uuf; push @vl, $#sl};
 if ($kf)  {push @sl, $kf;  push @kl, $#sl};
 if (scalar(@vl) <2)       {push @vl, $#sl};
 my $lr  =!$s->dbi ? undef : ($s->qparamsw('LIMIT') ||$s->{-listrnm});
 my $sql ="SELECT " 
         .join(',',map {$tbl .'.' .($fl->{$_}->{-col}||$_)} @sl)
         ." FROM  $tbl"
         ." WHERE $tbl." .($fl->{$npf}->{-col}||$npf).'=' 
         .($fl->{$kf}->{-flg} =~/["']/ ? $s->dbi->quote($kv) : $kv)
         ." ORDER BY $tbl." 
         .($utf ? ($fl->{$utf}->{-col}||$utf) : ($fl->{$kf}->{-col}||$kf))
         .' DESC'
         .(!$lr ? '' : eval{$s->dbi->{Driver}->{Name} eq 'mysql'} ? (' LIMIT ' .($lr+1) .' ') : '')
         ;
 $s->htmllst($sql,[@vl],{$kl[0]=>$kf},undef
            ,'<hr class="ListList" /><strong class="ListList">' .$s->lng(0,'Versions') .'</strong><span class="ListList" style="font-size: smaller;">&nbsp;&nbsp; '
            ,';&nbsp;&nbsp; ','&nbsp; ','</span>');
}


sub _explain {
 my ($s, $sql) =@_;
 return if !$s->parent->{-debug};
 eval {
    my $c =$s->dbi->prepare("explain $sql");
       $c->execute;
    my $r;
    while ($r =$c->fetchrow_hashref) {
      $s->pushmsg('EXPLAIN: ' .join('; ', map {"$_=" .($r->{$_}||'null')} @{$c->{NAME}}));
    }
 }
}


sub cmdlst { # List Data
 my $s    =shift;
 my $opt  =defined($_[0]) && substr($_[0],0,1) eq '-' ?shift :'-gx'; 
                                           # 'g'enerate + e'x'ecute
    $opt  =~s/-/-m/ if $opt =~/x/ && $opt !~/m/ && ($s->qparamsw('MIN')||'') =~/h/;
 my $vw   =$s->{-lists} ? $s->{-lists}->{shift ||$s->qlst} : undef;
 return &{$vw->{-sub}}($s,$opt,$vw,@_) if $vw->{-sub};
 my $cnd  =shift;
 my $dsub =$vw ? $vw->{-dsub}   :undef;     # data feed sub, instead of SQL
 my $rsub =($vw && $vw->{-rowlst}) ||$s->{-rowlst}; # row processor sub
 my $vwfl =$vw ? $vw->{-fields} :undef;     # view fields list
 my $vwff =$vw ? $vw->{-fetch}  :undef;     # view fields fetch
 my $vwfk =$vw ? $vw->{-key}    :undef;     # view fields key
 my $vwfu =$vw	&& exists($vw->{-listurm})  # view fields unread marks
	   	&& $vw->{-listurm}
		||  $s->{-listurm};
 my $vwfa =$vwfl;                           # view fields all list
	   if ($vwfa && ($vwfk||$vwfu)) {
		$vwfa =[@$vwfa];
		foreach my $f ($vwfk ? @$vwfk : (), $vwfu ? @$vwfu : ()) {
			push @$vwfa, $f if !grep {$_ eq $f} @$vwfa
		}
	   }
 my $st   =''; # select table
 my $sta  =''; #               alias
 my $sto  =''; #               oldname
 my $sfs  =''; # select fields string
 my $sfdl =[]; #               definitions list
    $sfdl->[$#{$vwfa}] =undef if $vwfa;
 my $vfnl =[]; # view   fields numbers list
 my $ffnl =[]; # fetch  fields numbers list
 my $ufnl =[]; # url    fields numbers list
 my $mfnl =[]; # umark  fields numbers list
 my $sts  =''; # select tables string
 my $sws  =''; #        where  string
 my $swfs =''; #        where  find       string
 my $swps =''; #        where  parameters string
 my $swts =''; #        where  title      string
 my $sobs =''; #        orderby string
    $sobs =$s->param($s->pxsw('ORDER_BY'));
    $sobs =$vw->{-orderby} if !$sobs && $vw && $vw->{-orderby};

 # Parse Form & View
 if ($opt =~/[gp]/) {         # Preview condition
     foreach my $v (($opt =~/!q/ ? '' : ($s->qparamsw('WHERE')||($vw && $vw->{-wherepar})||''))
                # , ($opt =~/!q/ ? '' : $swps) # will be filled below
                  ,  $cnd
                  , ($vw ? $vw->{-where} :'')
                  , ($vw && $vw->{-filter} 
                      ? $vw->{-filter}
                      :($s->{-fltlst} || $s->{-filter}))
                  ) {
        my $vv =(!defined($v) ? '' : ref($v) ? &$v($s): $v =~/^ *$/ ? '' : $v);
        $swfs .=(!$swfs ? '' : ' AND ') .'(' . $vv.') ' if $vv
     }
 }
 if ($opt =~/[gp]/) {         # Parse Form
    foreach my $f (@{$s->{-form}}) {
      next if !ref($f) || ref($f) eq 'CODE';
      my $tskip =1;     # skip table in 'from'
      my $findx =undef; # field index
   
      if ($f->{-tbl}) {			# turn on table
         $st  =$f;
         $sta =$st->{-alias}||$st->{-tbl};
         next;
      }

      my $fn =$f->{-fld};

      if ($vwfl) {			# list or select fields defined for view
         for (my $i =0; $i <=$#{$vwfl}; $i++) {
             next if $vwfl->[$i] ne $fn;
             $tskip =0;
             $sfdl->[$i] =$f;
             $findx =$i; 
             $vfnl->[$findx] =$findx;	# list field
             last
         }
      }
      elsif ($f->{-flg} =~/[lsa]/){# list or select fields
           $tskip =0;
           push @$sfdl, $f;
           $findx =$#{$sfdl};
           push @$vfnl, $findx if $f->{-flg} =~/[la]/; # list field
      }

      if ($vwff) {			# fetch fields defined for view
         if (grep {$_ eq $fn} @$vwff) {
            if (defined($findx)) { push @$ffnl, $findx}
            else {push @$sfdl, $f; push @$ffnl, $#{$sfdl}}
         }
      }
      elsif ($f->{-flg} =~/[f]/) {	# fetch field
            if (defined($findx)) { push @$ffnl, $findx}
            else {push @$sfdl, $f; push @$ffnl, $#{$sfdl}}
      }

      if ($vwfk) {			# key fields defined for view
         if (grep {$_ eq $fn} @$vwfk) {
            if (defined($findx)) { push @$ufnl, $findx}
            else {push @$sfdl, $f; push @$ufnl, $#{$sfdl}}
         }
      }
      elsif ($f->{-flg} =~/[k]/) {	# key  field
            if (defined($findx)) { push @$ufnl, $findx}
            else {push @$sfdl, $f; push @$ufnl, $#{$sfdl}}
      }

      if ($vwfu) {			# upd mark fields defined for view
         if (grep {$_ eq $fn} @$vwfu) {
            if (defined($findx)) { push @$mfnl, $findx}
            else {push @$sfdl, $f; push @$mfnl, $#{$sfdl}}
         }
      }
      elsif (!$dsub && !$vw->{-key}
	&&   $f->{-flg} =~/[w]/
	&&   $f->{-flg} !~/[k]/) {	# where key  field
            if (defined($findx)) { push @$mfnl, $findx}
            else {push @$sfdl, $f; push @$mfnl, $#{$sfdl}}
      }

      if (!defined($findx)		# field in condition or sort order
       &&(($swfs && $swfs =~/\b$fn\b/)               # condition check
        ||($sobs && (!ref($sobs) ? $sobs =~/\b$fn\b/ # order by check 
                    : grep {(ref($_) ? $_->[0] : $_) eq $fn} @$sobs
          )))) {
         push @$sfdl, $f;
         $tskip =0;
      }

      if ($opt !~/!q/			# query condition by user
       && !$dsub
       && $f->{-flg} =~/[qa]/) {
          my $p  =$s->param($fn);
          if (!defined($p) && $f->{-qry}) {
             $p =ref($f->{-qry}) eq 'CODE' ? &{$f->{-qry}}($s) : $f->{-qry};
             $s->param($f->{-fld},$p) if defined($p) && $p ne '';
          }
          if (defined($p) && $p ne '') {
             $tskip =0;
             if ($f->{-cdb}) {local $_ =$p; $p =&${$f->{-cdb}}($s,$p)}
             my $fm =defined($findx) ? $fn : $f->{-colns};
             $swps .=($swps ? ' AND ' :'');
             if ($p =~/^ *\(/) { # expr
               $swps .=$p
             }
             elsif ($p =~/^ *([><=]|not\b|in\b|is\b|like|rlike|regexp|similar\s+to\b)/i) { # translate expr
               $p     =~s/(\&|\|\band\b|\bor\b|\() *([=><]|\bnot\b|\bin\b|\bis\b|\blike\b|\brlike\b|\bregexp\b|\bsimilar\s+to\b)/$1 $fm $2/ig;
               $swps .="($fm $p)"
             }
             elsif (defined($f->{-null}) && $p eq $f->{-null}) {
               $swps .="$fm IS NULL"
             }
             elsif ($p eq 'NULL') {
               $swps .="$fm IS $p"
             }
             elsif ($f->{-flg} =~/(["'])/) { # quote
               my $q =$1;
               $p = $s->dbi ? $s->dbi->quote($p) :"$q$p$q";
               $swps .="$fm = $p"
             }
             else {
               $swps .="$fm = $p"
             }
          }
      }
      if ($st ne $sto && !$tskip) {# push table
          $sto  =$st;
          $sts .=(!$sts ? '' : ($st->{-join}||',') .' ') 
               .$st->{-tbl} .' AS ' .$sta 
               .($st->{-joina} ? ' ' .$st->{-joina} :'')
               .' ';
          $sws .=(!$sws ? '' : ' AND ') .'(' .$st->{-joinw} .') ' if $st->{-joinw}
      }
    }
 }
 if ($opt =~/[gp]/) {         # Fill not found view fields
    if ($vwfa) {
       for (my $i =0; $i <=$#$vwfa; $i++) {
           if (!defined($sfdl->[$i])) {
              $sfdl->[$i] =$vwfa->[$i] =~/[()]/
                          ?{-colns=>$vwfa->[$i]}
                          :{-fld=>$vwfa->[$i], -colns=>$vwfa->[$i]};
              push @$ufnl, $i if $vwfk && grep {$_ eq $vwfa->[$i]} @$vwfk;
           }                             
       }
       for (my $i =0; $i <=$#$vwfl; $i++) {
           $vfnl->[$i] =$i if !defined($vfnl->[$i]);
       }
    }
 }

 if ($opt =~/[g]/) {          # Assembly SQL Select Statement

    # Assembly Select list
    $sfs =join(', ', map {$_->{-colns} .($_->{-fld} ? ' AS ' .$_->{-fld} : '')} @$sfdl);

    # Assembly Where Part of SQL Select
    foreach my $v (($opt !~/!q/ ? $swps :'') 
                  , $swfs
                  ) {
      my $vv=(ref($v) ? &$v($s): $v);
      $sws .=(!$sws ? '' : ' AND ') .'(' . $vv.') ' if $vv
    }
    foreach my $v ( ($opt =~/!q/ ? '' : $swps)
                  , ($opt =~/!q/ ? '' : ($s->qparamsw('WHERE')||($vw && $vw->{-wherepar})||''))
                  ) {
      my $vv=(!defined($v) ? '' : ref($v) ? &$v($s): $v =~/^ *$/ ? '' : $v);
      $swts .=(!$swts ? '' : ' AND ') .'(' . $vv .') ' if $vv
    }

    if ($opt !~/!q/ && $s->{-ftext} && $s->qparamsw('FTEXT')) {
       my $c =$s->{-ftext};
       my $v =$s->qparamsw('FTEXT');
       $c =~s/%\$_/$s->dbi->quote('%' .$v .'%')/ge;
       $c =~s/\$_/$s->dbi->quote($v)/ge;
       $sws  .=(!$sws  ? '' : ' AND ') ."($c)";
       $swts .=(!$swts ? '' : ' AND ') ."($c)"
    }
    if ($vw && $vw->{-gant1}) {
       $sws  .=(!$sws  ? '' : ' AND ') 
             .'(' .join(' AND ', map {"$_ IS NOT NULL"} $vw->{-gant1}, $vw->{-gant2}) .')'
    }
    $s->{-genwhr}  =$sws;
    $s->{-genfrom} =$sts;

    # Assembly OrderBy Part of SQL Select
    $sobs =join(',', map {ref($_) ? join(' ',@$_): $_} @$sobs) if ref($sobs);

    # Assembly SQL Select Statement
    my $lr =!$s->dbi ? undef : ($s->qparamsw('LIMIT') || ($vw && $vw->{-listrnm}) || $s->{-listrnm});
    $s->{-gensel} =
          ' FROM ' .$sts
          .($sws ? " WHERE $sws " : '')
          .($vw && $vw->{-groupby} ? ' GROUP BY ' .$vw->{-groupby} .' ' :'')
          .($sobs ? " ORDER BY $sobs " :'')
          .(!$lr ? '' : eval{$s->dbi->{Driver}->{Name} eq 'mysql'} ? (' LIMIT ' .($lr+1) .' ') : '')
          ;
    $s->{-genselg} =$vw && $vw->{-gant1}
         ? 'SELECT MIN(' .$vw->{-gant1} .'), MAX(' .$vw->{-gant2} .')' 
          .     ', MAX(' .$vw->{-gant1} .'), MIN(' .$vw->{-gant2} .')' 
         #.' ' .$s->{-gensel} # 'order by' clause may contain fields to be defined in 'select' list
          .' FROM ' .$sts
          .($sws ? " WHERE $sws " : '')
         : '';
    $s->{-gensel} =
           'SELECT ' .$sfs .($vw && $vw->{-gant1} ? ', ' .join(', ', $vw->{-gant1}, $vw->{-gant2}) : '')
          .$s->{-gensel};
    $s->{-genselt} =$swts;
 }

 if ($opt =~/x/ && $s->dbi) { # Execute SQL Statement 
    my $p =$s->parent;
    my $g =$s->cgi;    
    if ($opt !~/m/) {
       my $t =$p->{-htmlstart}->{-title}||$p->{-htpgstart}->{-title}||'';
       print	'<div class="MenuArea">'
		,($vw && $vw->{-cmt}
		?('<strong class="MenuArea MenuHeader">'
		 ,$p->htmlescape(($t ? "$t - " : '' ), (ref($vw->{-cmt}) ? $vw->{-cmt}->[0] : $vw->{-cmt}))
		 ,"</strong><br />\n")
		:())
		,($vw && $vw->{-cmt} && ref($vw->{-cmt})
		 ?('<span class="MenuArea MenuComment">'
		  ,join("<br />\n"
			,map {$p->htmlescape($_)} @{$vw->{-cmt}}[1..$#{$vw->{-cmt}}])
		  ,"<br /></span>\n")
		 :())
		,($s->{-genselt}
		 ? ('<span class="MenuArea MenuComment" style="font-size: smaller;">'
		   ,$p->htmlescape($s->{-genselt})
		   ,"</span>\n")
		 :())
		,"<hr class=\"MenuArea MenuHeader\"/></div>\n";
    }
    my $c;
    my ($gt1, $gt2, $gm1, $gm2, $gi1, $gi2, $gv1, $gv2, $gs0);
    my $r;
    my $rh;
    if (!$dsub) {
       if ($s->{-genselg}) {
          eval('use POSIX');
          $s->pushmsg($s->{-genselg});
          $s->_explain($s->{-genselg});
          $c =$s->dbi->prepare($s->{-genselg});
          $c->execute;
          if ($gt2 =$c->fetchrow_arrayref) {
             $gt1  =defined($gt2->[3]) && $gt2->[3] lt $gt2->[0] ? $gt2->[3] : $gt2->[0];
             $gt2  =defined($gt2->[2]) && $gt2->[2] gt $gt2->[1] ? $gt2->[2] : $gt2->[1];
             if ($gt1 ||$gt2) {
                $gm1 =int($gt1 =~/(\d+)-(\d+)-(\d+)\s*(\d*):(\d*):(\d*)/ && (POSIX::mktime($6, $5, $4, $3, $2-1, $1 -1900)/86400)) +1;
                $gm2 =int($gt2 =~/(\d+)-(\d+)-(\d+)\s*(\d*):(\d*):(\d*)/ && (POSIX::mktime($6, $5, $4, $3, $2-1, $1 -1900)/86400)) +1;
                $gs0 =$vw && $vw->{-htmlg1}
                     ?$vw->{-htmlg1}
                     :'<td valign=top bgcolor=gray>#</td>';
                if ($gm1 >$gm2) {
                   $c =$gt1; $gt1 =$gt2; $gt2 =$c;
                   $c =$gm1; $gm1 =$gm2; $gm2 =$c;
                }
                $s->pushmsg("Gant margins retrieved: $gt1 (" .gmtime($gm1*86400) ."), $gt2 (" .gmtime($gm2*86400) .")");
             }
          }
       }
       $s->pushmsg($s->{-gensel});
       $s->_explain($s->{-gensel});
       $c =$s->dbi->prepare($s->{-gensel});
       $c->execute;
    }
    else {
       $dsub =&$dsub($s,$vw,$cnd,$sfdl,$rh);
    }
    my $lr=$s->qparamsw('LIMIT') ||($vw && $vw->{-listrnm}) ||$s->{-listrnm};
    my $rc =0;
    my @hr0=$vw && $vw->{-href} ? @{$vw->{-href}} :();
       $hr0[0] =$p->qurl if !$hr0[0];
       $hr0[1] =$s->pxcb('-cmd') if !$hr0[1];
       $hr0[2] ='-sel'   if !$hr0[2];
    my $mh =$vw && $vw->{-hrefc} ? $vw->{-hrefc} :0;
    my $mr =$#{$vfnl};
       $mh =$mr if $mh <0;
    local $_;
    print $vw && $vw->{-htmlts} ? $vw->{-htmlts}
        : $s->{-htmlts}         ? $s->{-htmlts}
        : $gm2 ? "<font style=\"font-size: smaller;\">\n<table class=\"ListTable\" rules=all border=1 cellspacing=0 frame=void style=\"font-size: x-small;\">\n"
                                  # rules=rows|all frame=void
      # : "<table class=\"ListTable\">\n";
        : "<table class=\"ListTable\" cellpadding=\"3%\">\n";
      # : "<table class=\"ListTable\" cellpadding=3>\n";
      # : "<table class=\"ListTable\" rules=all border=1 cellspacing=0 frame=void>\n";
    if ($opt !~/m/) {
       print '<thead><tr>'
            ,map {
             my $v =$sfdl->[$_]->{-lbl}||''; # ||$sfdl->[$_]->{-fld}
             ('<th align="left" valign="top" class="ListTable" title="'
	     ,$sfdl->[$_]->{-cmt} ||$sfdl->[$_]->{-lbl} ||'', '"'
             ,!$sfdl->[$_]->{-width}
              ? ('>', $p->htmlescape($v))
              : $sfdl->[$_]->{-width} =~/\D/
              ? (' width=', $sfdl->[$_]->{-width}, '>')
              : $sfdl->[$_]->{-width} >=length($v)
              ? ('><nobr>', $p->htmlescape($v), '&nbsp;' x($sfdl->[$_]->{-width} -length($v)), '</nobr>')
              : ('>', $p->htmlescape($v), '<br /><nobr>', '&nbsp;' x $sfdl->[$_]->{-width} ,'</nobr>')
             ,"</th>\n")
           } @$vfnl;
       if ($gm2) {
        # print $g->td({-align=>'left',-valign=>'top',-colspan=>20}, $gt1 =~/^([^\s]+)/ ?$1 :$gt1);
          my $r ='<th class="ListTable">&nbsp;</th>' x 2;
          my $gf='';
          for (my $gt=$gm1; $gt <=$gm2; $gt +=1) {
             my @gt =gmtime($gt*86400);
             $r .= $gt[3] ==1 
                 ? $gf =$g->td({-align=>'left',-valign=>'bottom', -colspan=>25, -class=>'ListTable'}
			, $p->strtime('|yyyy-mm-dd',@gt) .' (' .gmtime($gt*86400) .')') 
                 : $gt[3] <=25 && $gf
                 ? ''
                 : '<td class="ListTable"></td>';
          }
          $r .="</tr><tr>\n" .'<th colspan=' .($#{$vfnl}+3) .' class="ListTable"><nobr>'
              .('&nbsp;' x($vw && $vw->{-width} ? $vw->{-width} 
                         : $s->{-width}         ? $s->{-width}
                         : (29*($#{$vfnl}+3))))
              .'</nobr></th>';
          $gf ='';
          for (my $gt=$gm1; $gt <=$gm2; $gt +=1) {
             my @gt =gmtime($gt*86400);
             $r .= $gt[6] ==0 ||$gt[6] ==6
                 ? $g->td({-align=>'left',-valign=>'top', -class=>'ListTable'}
				,'s')
                 : $gt[6] ==1
                 ? $gf =$g->td({-align=>'left',-valign=>'top',-colspan=>3, -class=>'ListTable'}
			, sprintf('%02d',$gt[3]))
                 : $gt[6] <=3 && $gf
                 ? ''
                 : '<td class="ListTable">&nbsp;</td>';
          }
          print $r;
       }
       elsif ($s->{-width} || $vw && $vw->{-width}) {
          print "</tr><tr>\n" .'<th colspan=' .($#{$vfnl}+1) .' class="ListTable"><nobr>' 
                .('&nbsp;' x ($s->{-width} ||$vw->{-width})) .'</nobr></th>';
       }
       print "</tr></thead><tbody>\n";
    }
    if (!$dsub) {
       $r =[];
       $rh={map {($_=>undef)} @{$c->{NAME}}};
       if ($s->{-genselg}) {
          @$r[0..($#{$sfdl}+ 2)] =();
          $gi1 =$#{$sfdl} +1;
          $gi2 =$#{$sfdl} +2;
       }
       else {
          @$r[0..$#{$sfdl}] =();
       }
     # $c->bind_columns(undef,\(@$r));
       $c->bind_columns(undef, map {\($rh->{$_})} @{$c->{NAME}});
    }
    while (!$dsub ? ($r =$c->fetch) : ($r =shift @$dsub)) {  # !!! Optimize ???
       next if $rsub && !(&$rsub($s,$sfdl,$r,$rh));
       my $hurm =join(',',map {$r->[$_] ? ($r->[$_]) : ()} @$mfnl);
       my $href =$p->htmlurl(@hr0
                            ,(map {($sfdl->[$_]->{-fld},$r->[$_])} @$ufnl)
			    ,($hurm ? ('_tsw_listurm'=>$hurm) : ()));
       last if !print '<tr>'
        ,(map { my $c =$_; local $_ =$r->[$c];
           $_ =$sfdl->[$c]->{-clst} ? &{$sfdl->[$c]->{-clst}}($s, $sfdl->[$c], $_, $rh)
              :$sfdl->[$c]->{-cstr} ? $g->escapeHTML(&{$sfdl->[$c]->{-cstr}}($s, $sfdl->[$c], $_))
              :$g->escapeHTML($_);
           ('<td valign="top" class="ListTable"><nobr><a href="'
					, $href, '" class="ListTable"'
           ,$s->{-formtgf} ? (' target="', $s->{-formtgf}, '"') : (), '>'
           ,!defined($_) ||$_ eq '' ? '&nbsp&nbsp' : $_
           ,'</a></nobr></td>'
           )
         } @$vfnl[0..$mh])
        ,(map { my $c =$_; local $_ =$r->[$c];
           $_ =$sfdl->[$c]->{-clst} ? &{$sfdl->[$c]->{-clst}}($s, $sfdl->[$c], $_, $rh)
              :$sfdl->[$c]->{-cstr} ? $g->escapeHTML(&{$sfdl->[$c]->{-cstr}}($s, $sfdl->[$c], $_))
              :$g->escapeHTML($_);
           ('<td valign="top" class="ListTable">', (!defined($_) ? '&nbsp;' : $_), '</td>');
         } @$vfnl[$mh+1..$mr])
        ,($gm2
         && ($gv1 =int($r->[$gi1] =~/(\d+)-(\d+)-(\d+)\s*(\d*):(\d*):(\d*)/ && (POSIX::mktime($6, $5, $4, $3, $2-1, $1 -1900)/86400))+1)
         && ($gv2 =int($r->[$gi2] =~/(\d+)-(\d+)-(\d+)\s*(\d*):(\d*):(\d*)/ && (POSIX::mktime($6, $5, $4, $3, $2-1, $1 -1900)/86400))+1)
         ? ( '<td valign=top><nobr>', $r->[$gi1] =~/^([^\s]+)/, '</nobr></td>'
           , '<td valign=top><nobr>', $r->[$gi2] =~/^([^\s]+)/, '</nobr></td>'
           , '<td></td>' x(abs(($gv1 <$gv2 ? $gv1 : $gv2) -$gm1) +0)
           , $gs0 x(abs($gv2 -$gv1) +1)
           , '<td></td>' x($gm2 -($gv1 <$gv2 ? $gv2 : $gv1))
           )
         : ())
        ,"</tr>\n";
       if (++$rc >=$lr) {
          last
       }
    }
    print $opt !~/m/ ? '</tbody>' : ''
        , $vw && $vw->{-htmlte} ? $vw->{-htmlte}
        : $s->{-htmlte}         ? $s->{-htmlte}
        : $gm2                  ? "</table></font>\n"
        : "</table>\n";
    $s->pushmsg($s->{-genlstm} =$rc <=$lr ? $s->lng(1,'rfetch',$rc) : $s->lng(1,'rfetchf',$lr));
    $c->finish if $c;
 }
}


sub cmdscan {# Scan data like cmdlst and eval code
 my $s   =shift;
 my $opt =defined($_[0]) && substr($_[0],0,1) eq '-' ? shift : '';
 my $cmd =!ref($_[0]) ? shift : undef;
 my $sub =ref($_[$#_]) eq 'CODE' ? pop : undef;
                                        # Get SQL SELECT
 if    (!defined($cmd)) {               # default - current list
       $s->cmdlst('-g' .$opt)
 }
 elsif ($cmd !~/select\b/i) {           # by list name
       $s->cmdlst('-g' .$opt, $cmd, @_);
 }
 else  {                                # implicit
       $s->{-gensel} =$cmd;      
 }
 $cmd =$s->{-gensel};
 $s->pushmsg($cmd);

 my $c =$s->dbi->prepare($cmd);
    $c->execute;

 return($c) if !$sub;                   # Return SELECT initiated

 local $_ =undef;                       # Iterate Sub{} given
 my    $g =$s->cgi;
 print join(";<br />\n", map {$s->htmlescape($_)} @{$s->pushmsg}) && ($opt!~/m/);
 $s->parent->set('-cache')->{-pushmsg} =undef;
 while ($_ =$c->fetchrow_hashref) {
    foreach my $f (@{$s->{-form}}) {    # set pk, reset fields
       next if !ref($f) || ref($f) eq 'CODE' || !$f->{-fld};
       if ($f->{-flg} =~/k/) {$g->param($f->{-fld},$_->{$f->{-fld}})}
       else {$g->delete($f->{-fld})}
    }
    &$sub($s,$_);                       # do sub   
    $s->parent->set('-cache')->{-pushmsg} =undef;
 }
 foreach my $f (@{$s->{-form}}) {       # reset fields
   next if !ref($f) || ref($f) eq 'CODE' || !$f->{-fld};
   $g->delete($f->{-fld})
 }
 $c->finish;
}


sub cmdscan1{# First row of cmdscan, Exists
 my $s =shift;
 my $c =$s->cmdscan(@_);
 my $r =$c->fetchrow_hashref;
 $c->finish;
 $s->pushmsg($s->lng(1,'rfetch', $r ? 1 : 0));
 $r
}


sub cmdhlp {    # Help Command
 my $s =shift;
 $s->SUPER::cmdhlp(@_);
 my $g =$s->cgi;
 my $o =defined($_[0]) && substr($_[0],0,1) eq '-' ? shift : '-tolfcvs';
        # 't'itle, 'o'ther, 'l'ists, 'f'ields, 'c'ommands, 'v'ersioning, files 's'tore
 my $ta={-align=>'left',-valign=>'top'};
 my $sh='';
 if ($o =~/[vo]/ && $s->{-vsd}) {
    $sh ='Versioning';
    print $g->h2($s->htmlescape($s->lng(0, $sh))),"\n";
    $sh =$s->lng(1, $sh);
    print $g->p($s->htmlescape($sh)),"\n" if $sh;
    print "<table>\n";
    foreach my $n (qw(-npf -uuf -utf -cof -sf)) {
       next if !$s->{-vsd}->{$n} || !$s->{-fields}->{$s->{-vsd}->{$n}};
       my $f =$s->{-fields}->{$s->{-vsd}->{$n}};
       next if !$f || ref($f) ne 'HASH' || !$f->{-fld} || !$f->{-cmt};
       print '<tr>';
       print $g->td($ta, '<code>' .$s->htmlescape('[' .$f->{-flg} .']') .'</code>');
       print $g->th($ta, $s->htmlescape($f->{-lbl}||$f->{-fld}));
       print $g->td($ta, '<code>' .$s->htmlescape($f->{-fld}) .'</code>');
       print $g->td($ta, $s->htmlescape($f->{-cmt}));
       print "</tr>\n";
    }
    print '<tr>', $g->td(), $g->th($ta, $s->htmlescape("'" .$s->{-vsd}->{-svd} ."'")), $g->td()
        , $g->td($ta, $s->htmlescape($s->lng(1,'-vsd-svd'))), '</tr>' if $s->{-vsd}->{-svd};
    print '<tr>', $g->td(), $g->th($ta, $s->htmlescape("'" .$s->{-vsd}->{-sd} ."'")), $g->td()
        , $g->td($ta, $s->htmlescape($s->lng(1,'-vsd-sd'))),  '</tr>'            if $s->{-vsd}->{-sd};
    print "</table>\n";
 }
 if ($o =~/[so]/ && $s->{-fsd}) {
    $sh ='File Store';
    print $g->h2($s->htmlescape($s->lng(0, $sh))),"\n";
    $sh =$s->lng(1, $sh);
    print $g->p($s->htmlescape($sh)),"\n" if $sh;
    print "<table>\n";
    print '<tr>', $g->th($ta, '<code>' .$s->htmlescape("'" .($s->{-fsd}->{-urf} ||$s->{-fsd}->{-url}) ."'") .'</code>')
        , $g->td($ta, $s->htmlescape($s->lng(1,'-fsd-url'))),   '</tr>' if $s->{-fsd}->{-url};
    print '<tr>', $g->th($ta, '<code>' .$s->htmlescape("'" .($s->{-fsd}->{-vsurf} ||$s->{-fsd}->{-vsurl}) ."'") .'</code>')
        , $g->td($ta, $s->htmlescape($s->lng(1,'-fsd-vsurl'))), '</tr>' if $s->{-fsd}->{-vsurl};
    my $sf =$s->{-vsd} ? $s->{-vsd}->{-sf} : ''; 
    if ($sf) {
       $sf =$s->{-fields}->{$sf}->{-lbl} ||$sf;
       $sf ='(' .$sf .($s->{-vsd}->{-svd} ? (' = ' .$s->{-vsd}->{-svd}) :'') .')';
    }
    print '<tr>', $g->th($ta, $s->lng(0,'-fsd-vsd-e'))
        , $g->td($s->htmlescape($s->lng(1,'-fsd-vsd-e', $sf)))
        , '</tr>' if $s->{-vsd};
    print '<tr>', $g->th($ta, $s->lng(0,'-fsd-vsd-ei'))
        , $g->td($s->htmlescape($s->lng(1,'-fsd-vsd-ei',$sf)))
        , '</tr>' if $s->{-vsd};
    print "</table>\n";
 }
 $s
}


###################################
# ACCESS CONTROL
###################################


sub acl {        # ACL get
 my ($s, $sub, $cmd, $px) =@_;
 return [] if !$s->{-acd};
 $px =!defined($px) ? ''
     : substr($px,0,1) eq '-' ? ($s->{$px} ||$px)
     : $px;
 if (ref($s->{-acd}->{$sub}) eq 'CODE') { # sub
    &{$s->{-acd}->{$sub}}($s,$sub,$cmd,$px) ||[]
 }
 elsif ($sub =~/^-[so]/ ||$sub =~/i$/) {  # value list
    $s->{-acd}->{$sub} ||[]
 }
 else {                                   # field list
    my $r =[];
    foreach my $e (@{$s->{-acd}->{$sub}}) {
       push @$r, split / *[;,] */, $s->param($px .$e)
    }
    $r
 }
}


sub acltest {    # ACL test command
 my ($s, $cmd, $px) =@_;
 return $s->user if !$s->{-acd};
 my $op =$cmd ? substr($cmd,1,1) : '';
 my $un =$s->ugnames;
 my @l;
 if (grep {$_ eq $cmd} qw(-ins -upd -del)) {
    return $s->user if !grep {$s->{-acd}->{$_}} qw(-swrite -write);
    @l =qw(-swrite -write);
 }
 elsif ($cmd eq '-lst') {
    @l =qw(-sread);
 }
 elsif ($cmd eq '-sys') {
    @l =qw(-swrite -oswrite);
 }
 else {
    return $s->user if !grep {$s->{-acd}->{$_}} qw(-sread -read -swrite -write);
    @l =(qw(-sread -read -write -readsub), ($cmd eq '-sel' ? () : '-swrite'));
 }
 foreach my $cs (@l) {
   my $c =$s->{-acd}->{$cs .$op} ? ($cs .$op) : $cs;
   next      if !defined($s->{-acd}->{$c});
   my $t =$s->acl($c,$cmd,$px);
   next      if !$t;
   return $t if !ref($t);
   return $t if  ref($t) ne 'ARRAY'; # record read delegation via '-readsub'
   next      if  ref($t) ne 'ARRAY';
   foreach my $e (@$t) {return $e if grep {$e =~/(?:^|[,\s])\Q$_\E(?:[,\s]|$)/i} @$un}
 }
 return(0) if $cmd eq '-lst';
 $s->parent->userauth if $s->parent->uguest  # !!! header may be already printed
                      && (!$s->parent->{-cache} ||!$s->parent->{-cache}->{-httpheader});
 $s->die($s->lng(1,'op!acl2',$s->lng(0,$cmd)) ." '" .$s->user ."'\n");
}


sub aclsel {     # ACL Where Select Clause
 my $s =shift;
 my $o =(defined($_[0]) && ($_[0] eq '' ||substr($_[0],0,1) eq '-') ? shift : '') 
        ||'-t'; 
 my $a =(defined($_[0]) && ($_[0] eq '' ||substr($_[0],0,1) eq '-') ? shift : '');
 my $n =(defined($_[0]) && ($_[0] eq '' ||substr($_[0],0,1) eq '-') ? shift : '');
 return('') if $o =~/t/ && $s->{-acd} && $s->acltest('-lst'); ## !'t'est if needed
 my @r;
 if (scalar(@_)) {
    @r =map {ref($_) ? $_ : ($s->{-fields}->{$_}->{-colns}||$_)} @_
 }
 else {
   return('') if !$s->{-acd};
   foreach my $l (qw(-write -read)) {
     next if !$s->{-acd}->{$l};
     foreach my $n (@{$s->{-acd}->{$l}}) {
       my $f = $s->{-fields}->{$n}->{-colns};
       push (@r, $f) if !grep {$_ eq $f} @r;
     }
   }
 }
 return('') if !scalar(@r);
 my $u =$s->ugnames;
 my $r ='';
 my $m =undef;
 foreach my $e (@r) {
   if (ref($e))           {ref($e) eq 'CODE' ? $m =$e : $u =$e; next}
   if (index($e,'$_')>=0) {$m =$e; next}
   $r .=(!$r ? '' : $n ? ' AND ' : ' OR ') 
      . (!$m 
      ? ($e 
        .(scalar(@$u) ==1 
         ? (($n ? '<>' : '=') .$s->dbi->quote($u->[0]))
         : (($n ? ' NOT' : '') .' IN(' .join(',', map {$s->dbi->quote($_)} @$u) .')')))
      : ref($m)
      ? &{$m}($s,$e,$u)
      : $m =~/^\$_(r\w+)$/i
      ? ($e ." $1 " .$s->dbi->quote('[[:<:]](' .join('|', map {$s->dblikesc($_)} @$u) .')[[:>:]]'))
      : join($n ? ' AND ' : ' OR '
            ,map {my $q =$m; $q=~s/\$_f/$e/g; $q=~s/\$_u{0,1}/$s->dbi->quote($_)/ge; $q} @$u)
      );
   $m =undef
 }
 return('') if !$r;
 ($a ? ' AND' : '') .'(' .$r .')'
}


###################################
# FILE STORE
###################################


sub fsname {    # File Store Name (?key value)
 my $s =shift;
 my $c =shift;
 my $v =ref($_[0]) ? ($_[0]->[0] ||0): undef;
    $v =$s->param($s->{-vsd}->{-npf}) if !defined($v) && $s->{-vsd} && $s->{-vsd}->{-npf};
 my $k =ref($_[0]) ?  $_[0]->[1] : $_[0];
    $k =$s->keyval() if !defined($k);
    $k =''           if !defined($k);
 my $d =$s->{-fsd} && defined($s->{-fsd}->{-ksplit}) 
        ? $s->{-fsd}->{-ksplit} :3;
    $d =length($k) if $d eq '0';
 my $r ='';
 if (ref($d) eq 'CODE') {
    local $_ =$k;
    foreach my $v (&$d($s, $k)) {
      next if !defined($v);
      $v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
      $r .='/' .$v;
    }
 }
 else {
    for (my $i =0; $i <length($k); $i +=$d) {
      my $v =substr($k, $i, $d);
      $v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
      $r .='/' .$v;
    }
 }
 $r .='$';
 return($r) if !$c;
 (($v ? $s->{-fsd}->{'-vs' .$c} :'') ||$s->{-fsd}->{'-' .$c} ||return(undef)) .$r
}


sub fsnamekey { # File Store Name -> Key value
 my ($s, $v) =@_;
 chop($v) if substr($v,length($v)-1,1) eq '$';
 $v =~s/[\\\/]//g;
 $v =~s/_(..)/chr(hex($1))/eg;
 $v
}


sub fspath {    # File Store Path
 $_[0]->fsname('path',$_[1]||undef);
}


sub fsurl {     # File Store URL
 $_[0]->fsname('url',$_[1]||undef);
}


sub fsurf {     # File Store Filesystem URL
 $_[0]->fsname($_[0]->{-fsd}->{-urf} ? 'urf' : 'url', $_[1]||undef);
}


sub fspathmk {  # File Store Path Make
 my $s =shift;
 my $p =$s->fspath(@_);
 $s->parent->w32IISdpsn(1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/;
 $s->fut->mkdir($p) if !-d $p;
 $p
}


sub fspathcp {  # File Store Path Copy
 my ($s, $p1, $p2)  =@_;
 $s->parent->w32IISdpsn(1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/;
 $s->fut->copy('-rd', $s->fspath($p1), $s->fspathmk($p2))
}


sub fspathrm {  # File Store Path Remove
 my ($s, $p)  =(shift, shift);
 $s->parent->w32IISdpsn(1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/;
 $s->fut->delete('-r', $s->fspath($p));
}


sub fsacl {     # File Store ACL
 my ($s, $op, $px, $p) =@_;
 $op ='w' if !defined($op); # 'r'ead, 'w'rite
 $px =!defined($px) ? ''
     : substr($px,0,1) eq '-' ? ($s->{$px} ||$px)
     : $px;
 $p  =$s->keyval($px) if !defined($p);
 $p  =$s->fspath($p);

 if ($s->{-fsd}->{-acl}) {               # Developer's Sub{}
    return &{$s->{-fsd}->{-acl}}($s,$op,$px,$p)
 }
 if ((($s->{-fsd}->{-urf}                # Filesystem ACL
     ||$s->{-fsd}->{-url}) =~/^file:/i)
    ||(($ENV{SERVER_SOFTWARE}||'') =~/IIS/)) { 
    if ($^O eq 'MSWin32') {              # Windows ACL (cacls or xcacls or WSH)
       $s->parent->w32IISdpsn(1);
       my @o =('/T','/C','/G');
       my $a =$s->acl('-oswrite', undef, $px);
       if (!scalar(@$a)) {
          $a =[eval{Win32::LoginName}||$ENV{USERNAME}||'Administrators'];
          push @$a, 'System' if !grep {lc($_) eq 'system'} @$a;
       }
       $s->oscmd('cacls', "\"$p\"", @o, (map {"\"$_\":F"} @{$s->unamesun($a)})
                , sub{print "Y\n"});
       unshift @o, '/E';
       foreach my $l (($op ne 'w' ? () : '-swrite'), qw(-write -sread -read)) {
         my $a =$s->unamesun($s->acl($l, undef, $px));
         my $r =($l =~/write/ && $op eq 'w' ? 'F' : 'R');
	 next if !scalar(@$a);
	 if ($l =~/^-s/) {
		$s->oscmd('cacls', $p, @o, map {"\"$_\":$r"} @$a)
	 }
	 else {
		foreach my $n (@$a) {
			$s->oscmd('-i','cacls', $p, @o, "\"$n\":$r")
			|| $s->warn($s->parent->lng(0,'Warning') .": cacls($n:$r) -> " .(($?>>8)||0))
		}
	 }
       }
    }
    else {                               # UNIX ACL
       # Any Standards?
    }
 }
 if ((ref($s->{-acd}->{-htaccess})       # HTTP or DAV ACL      
     ?&{$s->{-acd}->{-htaccess}}($s)
     :  $s->{-acd}->{-htaccess})
    ||(($ENV{SERVER_SOFTWARE}||'') =~/Apache/i)) {
    # .htaccess
    my @a;
    foreach my $l (qw(-oswrite -write -sread -read)) { #  -swrite
      my $a =$s->unamesun($s->acl($l, undef, $px));
      next if !scalar(@$a);
      push @a, @$a;
    }
    if (scalar(@a)) {
      @a =@{$s->unamesun(@a)};
      $s->fut->fstore('-',"$p/.htaccess"
      ,'<Files "*">'
      ,join(' ','require user ', @a)
      ,join(' ','require group ',@a)
      ,'</Files>')
    }
 }
}


sub fsscan {    # File Store Scan
 my ($s,$opt) =@_;
 $opt ='ft' if !$opt;
 return if !$s->{-fsd};
 $s->parent->w32IISdpsn(1) if ($ENV{SERVER_SOFTWARE}||'') =~/IIS/;

 if ($opt =~/f/) {
 foreach my $path ($s->{-fsd}->{-path}, $s->{-fsd}->{-vspath}){
   next if !$path || !-d $path;
   print $s->h1("FileStore/Table Scan: $path"),"\n";
   eval('use File::Find'); $File::Find::prune =0; $File::Find::dir ='';
   File::Find::find(sub{
    if ($_ =~/\$$/) {
       $File::Find::prune =1;
       my $kp =$File::Find::dir .'/' .$_;
       my $kd =substr($kp, length($path) +1);
       my $kv =$s->fsnamekey($kd);
       my $kt =$s->{-fields}->{$s->keyfld}->{-table};
       my $kf =$s->{-fields}->{$s->keyfld}->{-col} ||("$kt." .$s->keyfld);
       my @r  =$s->dbi->selectrow_array("select $kf from $kt where $kf=?",{},$kv);
       my $src="$path/$kd";
       my $dst =$path .$s->fsname('',$s->fsnamekey($kd));
       if    (0 && (eval{$s->fut->delete('-',"$src/.htaccess")} ||1)
                && $s->fut->rmpath($src)) {}
       elsif (!scalar(@r)) {
          print $s->htmlescape("$kp --0> $kv"),"<br />\n";
        # $s->fut->delete('-r', $src) && $s->fut->rmpath($src);
          $s->fut->rmpath($src);
       }
       elsif ($src ne $dst) {
        # print $s->htmlescape("$src --> $dst"),"<br />\n";
          $s->fut->copy('-rd',$src,$dst) 
          && $s->fut->delete('-r',$src)
          && $s->fut->rmpath($src);                    
       }
       if (@{$s->pushmsg}) {
          print join(";<br />\n", map {$s->htmlescape($_)} @{$s->pushmsg}), "<br />\n";
          $s->parent->set('-cache')->{-pushmsg} =undef;
       }
    }
   }, $path);
 }
 }

 if ($opt =~/t/) {
 print $s->h1('Table/FileStore Scan'),"\n";
 my $v =$s->{-vsd};
 local $s->{-rowsel1a} =undef;
 local $s->{-rowsel2a} =undef;
 $s->cmdscan(@_, sub{
    $s->cmdsel;
    my $fsa =!$v ? 'w'
            :$v->{-cvd} ? (&{$v->{-cvd}}($s) ? 'w' : 'r')
            :$v->{-svd} ? (($v->{-svd} eq $s->qparam($v->{-sf})) ? 'w' : 'r')
            :'';
    $s->fsacl($fsa) if $fsa && -d $s->fspath; 
    print join(";<br />\n", map {$s->htmlescape($_)} @{$s->pushmsg}), "<br />\n";
 });
 }
}


