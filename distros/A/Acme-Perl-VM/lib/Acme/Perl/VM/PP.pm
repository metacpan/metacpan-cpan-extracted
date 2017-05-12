package Acme::Perl::VM::PP;
use strict;
use warnings;

use Acme::Perl::VM qw(:perl_h);
use Acme::Perl::VM::B;


#NOTE:
#        perl  APVM
#
#         dSP  (nothing)
#          SP  $#PL_stack
#         *SP  $PL_stack[-1]
#       dMARK  my $mark = POPMARK
#        MARK  $mark
#       *MARK  $PL_stack[$mark]
#   dORIGMARK  my $origmark = $mark
#    ORIGMARK  $origmark
#     SPAGAIN  (nothing)
#     PUTBACK  (nothing)

sub pp_nextstate{
    $PL_curcop = $PL_op;

    $#PL_stack = $PL_cxstack[-1]->oldsp;
    FREETMPS;

    return $PL_op->next;
}

sub pp_pushmark{
    PUSHMARK;
    return $PL_op->next;
}

sub pp_const{
    my $sv = is_not_null($PL_op->sv) ? $PL_op->sv : PAD_SV($PL_op->targ);
    PUSH($sv);
    return $PL_op->next;
}

sub pp_gv{
    PUSH( GVOP_gv($PL_op) );
    return $PL_op->next;
}

sub pp_gvsv{
    if($PL_op->private & OPpLVAL_INTRO){
        PUSH(save_scalar(GVOP_gv($PL_op)));
    }
    else{
        PUSH(GVOP_gv($PL_op)->SV);
    }
    return $PL_op->next;
}

sub _do_kv{
    my $hv = POP;

    if($hv->class ne 'HV'){
        apvm_die 'panic: do_kv';
    }

    my $gimme = GIMME_V;

    if($gimme == G_VOID){
        return $PL_op->next;
    }
    elsif($gimme == G_SCALAR){

        if($PL_op->flags & OPf_MOD || LVRET){
            not_implemented $PL_op->name . ' for lvalue';
        }

        my $num = keys %{ $hv->object_2svref };
        mPUSH( svref_2object(\$num) );
        return $PL_op->next;
    }


    my($dokeys, $dovalues);
    if($PL_op->name eq 'keys'){
        $dokeys = TRUE;
    }
    elsif($PL_op->name eq 'values'){
        $dovalues = TRUE;
    }
    else{
        $dokeys = $dovalues = TRUE;
    }

    my $hash_ref = $hv->object_2svref;
    while(my $k = each %{$hash_ref}){
        mPUSH( svref_2object(\$k) )               if $dokeys;
        PUSH(  svref_2object(\$hash_ref->{$k}) )  if $dovalues;
    }
    return $PL_op->next;
}

sub pp_rv2gv{
    my $sv = TOP;

    if($sv->ROK){
        $sv = $sv->RV;
    }

    if($sv->class ne 'GV'){
        apvm_die 'Not a GLOB reference';
    }

    if($PL_op->private & OPpLVAL_INTRO){
        not_implemented 'rv2gv for OPpLVAL_INTRO';
    }

    SET($sv);
    return $PL_op->next;
}

sub pp_rv2sv{
    my $sv = TOP;
    my $gv;

    if($sv->ROK){
        if(!is_scalar($sv)){
            apvm_die 'Not a SCALAR reference';
        }
    }
    else{
        if($sv->class ne 'GV'){
            not_implemented 'rv2xv for soft references';
        }
        $gv = $sv;
    }

    if($PL_op->flags & OPf_MOD){
        if($PL_op->private & OPpLVAL_INTRO){
            if($PL_op->first->name eq 'null'){
                $sv = save_scalar(TOP);
            }
            else{
                $sv = save_scalar($gv);
            }
        }
        elsif($PL_op->private & OPpDEREF){
            vivify_ref($sv, $PL_op->private & OPpDEREF);
        }
    }
    SET($sv);
    return $PL_op->next;
}

sub pp_rv2av{
    my $sv    = TOP;
    my $name;
    my $class;
    my $save;

    if($PL_op->name eq 'rv2av'){
        $name  = 'an ARRAY';
        $class = 'AV';
        $save  = \&save_ary;
    }
    else{
        $name  = 'a HASH';
        $class = 'HV';
        $save  = \&save_hash;
    }
    my $gimme = GIMME_V;

    if($sv->ROK){
        $sv = $sv->RV;

        if($sv->class ne $class){
            apvm_die "Not $name reference";
        }
        if($PL_op->flags & OPf_REF){
            SET($sv);
            return $PL_op->next;
        }
        elsif(LVRET){
            not_implemented 'rv2av for lvalue';
        }
        elsif($PL_op->flags & OPf_MOD
                && $PL_op->private & OPpLVAL_INTRO){
            apvm_die q{Can't localize through a reference};
        }
    }
    else{
        if($sv->class eq $class){
            if($PL_op->flags & OPf_REF){
                SET($sv);
                return $PL_op->next;
            }
            elsif(LVRET){
                not_implemented 'rv2av for lvalue';
            }
        }
        else{
            if($sv->class ne 'GV'){
                not_implemented 'rv2av for symbolic reference';
            }

            if($PL_op->private & OPpLVAL_INTRO){
                $sv = $save->($sv);
            }
            else{
                $sv = $sv->$class();
            }

            if($PL_op->flags & OPf_REF){
                SET($sv);
                return $PL_op->next;
            }
            elsif(LVRET){
                not_implemented 'rv2av for lvalue';
            }
        }
    }

    if($class eq 'AV'){ # rv2av
        if($gimme == G_ARRAY){
            POP;
            PUSH( $sv->ARRAY );
        }
        elsif($gimme == G_SCALAR){
            SETval( $sv->FILL + 1 );
        }
    }
    else{ # rv2hv
        if($gimme == G_ARRAY){
            return &_do_kv;
        }
        elsif($gimme == G_SCALAR){
            SET(hv_scalar($sv));
        }
    }

    return $PL_op->next;
}
sub pp_rv2hv{
    goto &pp_rv2av;
}

sub pp_padsv{
    my $targ = GET_TARGET;
    PUSH($targ);

    if($PL_op->flags & OPf_MOD){
        if(($PL_op->private & (OPpLVAL_INTRO|OPpPAD_STATE)) == OPpLVAL_INTRO){
            SAVECLEARSV($targ);
        }
    }
    return $PL_op->next;
}

sub pp_padav{
    my $targ = GET_TARGET;

    if(($PL_op->private & (OPpLVAL_INTRO|OPpPAD_STATE)) == OPpLVAL_INTRO){
            SAVECLEARSV($targ);
    }
    if($PL_op->flags & OPf_REF){
        PUSH($targ);
        return $PL_op->next;;
    }
    elsif(LVRET){
        not_implemented 'padav for lvalue';
    }

    my $gimme = GIMME_V;
    if($gimme == G_ARRAY){
        PUSH( $targ->ARRAY );
    }
    elsif($gimme == G_SCALAR){
        my $sv = sv_newmortal();
        $sv->setval($targ->FILL + 1);
        PUSH($sv);
    }

    return $PL_op->next;
}

sub pp_padhv{
    my $targ = GET_TARGET;

    if(($PL_op->private & (OPpLVAL_INTRO|OPpPAD_STATE)) == OPpLVAL_INTRO){
        SAVECLEARSV($targ);
    }

    PUSH($targ);

    if($PL_op->flags & OPf_REF){
        return $PL_op->next;
    }
    elsif(LVRET){
        not_implemented 'padhv for lvalue';
    }

    my $gimme = GIMME_V;
    if($gimme == G_ARRAY){
        return &_do_kv;
    }
    elsif($gimme == G_SCALAR){
        SET( hv_scalar($targ) );
    }

    return $PL_op->next;;
}

sub pp_anonlist{
    my $mark = POPMARK;
    my @ary  = mark_list($mark);

    if($PL_op->flags & OPf_SPECIAL){
        my $ref = \@ary;
        mPUSH(svref_2object(\$ref));
    }
    else{
        mPUSH(svref_2object(\@ary));
    }
    return $PL_op->next;
}
sub pp_anonhash{
    my $mark     = POPMARK;
    my $origmark = $mark;
    my %hash;

    while($mark < $#PL_stack){
        my $key = $PL_stack[++$mark];
        my $val;
        if($mark < $#PL_stack){
            $val = ${ $PL_stack[++$mark]->object_2svref };
        }
        else{
            apvm_warn 'Odd number of elements';
        }
        $hash{ ${ $key->object_2svref } } = $val;
    }
    $#PL_stack = $origmark;
    if($PL_op->flags & OPf_SPECIAL){
        my $ref = \%hash;
        mPUSH(svref_2object(\$ref));
    }
    else{
        mPUSH(svref_2object(\%hash));
    }
    return $PL_op->next;
}

sub _refto{
    my($sv) = @_;

    if($sv->class eq 'PVLV'){
        not_implemented 'ref to PVLV';
    }
    my $rv = $sv->object_2svref;
    return sv_2mortal( svref_2object(\$rv) );
}

sub pp_srefgen{
    $PL_stack[-1] = _refto($PL_stack[-1]);
    return $PL_op->next;
}
sub pp_refgen{
    my $mark = POPMARK;
    if(GIMME_V == G_ARRAY){
        while(++$mark <= $#PL_stack){
            $PL_stack[$mark] = _refto($PL_stack[$mark]);
        }
    }
    else{
        if(++$mark <= $#PL_stack){
            $PL_stack[$mark] = _refto($PL_stack[-1]);
        }
        else{
            $PL_stack[$mark] = _refto(sv_undef);
        }
        $#PL_stack = $mark;
    }
    return $PL_op->next;
}

sub pp_list{
    my $mark = POPMARK;

    if(GIMME_V != G_ARRAY){
        if(++$mark <= $#PL_stack){
            $PL_stack[$mark] = $PL_stack[-1];
        }
        else{
            $PL_stack[$mark] = sv_undef;
        }
        $#PL_stack = $mark;
    }
    return $PL_op->next;
}


sub _method_common{
    my($meth) = @_;

    my $name = SvPV($meth);
    my $sv   = $PL_stack[ TOPMARK() + 1];

    if(!sv_defined($sv)){
        apvm_die q{Can't call method "%s" on an undefined value}, $name;
    }

    my $invocant = ${$sv->object_2svref};

    my $code = do{
        local $@;
        eval{ $invocant->can($name) };
    };

    if(!$code){
        apvm_die q{Can't locate object method "%s" via package "%s"}, $name, ref($invocant) || $invocant;
    }

    return svref_2object($code);
}

sub pp_method{
    my $sv = TOP;

    if($sv->ROK){
        if($sv->RV->class eq 'CV'){
            SET($sv->RV);
            return $PL_op->next;
        }
    }

    SET(_method_common($sv));
    return $PL_op->next;
}
sub pp_method_named{
    my $sv = is_not_null($PL_op->sv) ? $PL_op->sv : PAD_SV($PL_op->targ);

    PUSH(_method_common($sv));
    return $PL_op->next;
}

sub pp_entersub{
    my $sv = POP;
    my $cv = $sv->toCV();

    if(is_null($cv)){
        apvm_die 'Undefined subroutine %s called', gv_fullname($sv, '&');
    }
    my $hasargs = ($PL_op->flags & OPf_STACKED) != 0;

    ENTER;
    SAVETMPS;

    my $mark  = POPMARK;
    my $gimme = GIMME_V;

    if(!cv_external($cv)){
        my $cx = PUSHBLOCK(SUB =>
            oldsp => $mark,
            gimme => $gimme,

            cv      => $cv,
            hasargs => $hasargs,
            retop   => $PL_op->next,
        );

        #XXX: How to do {$cv->DEPTH++}?
        PAD_SET_CUR($cv->PADLIST, $cv->DEPTH+1);

        if($hasargs){
            my $av = PAD_SV(0);

            $cx->savearray(\@_);
            *_ = $av->object_2svref;
            $cx->CURPAD_SAVE();
            $cx->argarray($av);

            #@_ = mark_list($mark);
            av_assign($av, splice @PL_stack, $mark+1);
        }

        return $cv->START;
    }
    else{
        my @args;
        av_assign(svref_2object(\@args), splice @PL_stack, $mark+1);

        if($gimme == G_SCALAR){
            my $ret = $cv->object_2svref->(@args);
            mPUSH(svref_2object(\$ret));
        }
        elsif($gimme == G_ARRAY){
            my @ret = $cv->object_2svref->(@args);
            mPUSH(map{ svref_2object(\$_) } @ret);
        }
        else{
            $cv->object_2svref->(@args);
        }
        return $PL_op->next;
    }
}

sub pp_leavesub{
    my $cx    = POPBLOCK;
    my $newsp = $cx->oldsp;
    my $gimme = $cx->gimme;

    if($gimme == G_SCALAR){
        my $mark = $newsp + 1;

        if($mark <= $#PL_stack){
            $PL_stack[$mark] = sv_mortalcopy(TOP);
        }
        else{
            $PL_stack[$mark] = sv_undef;
        }
        $#PL_stack = $mark;
    }
    elsif($gimme == G_ARRAY){
        for(my $mark = $newsp + 1; $mark <= $#PL_stack; $mark++){
            $PL_stack[$mark] = sv_mortalcopy($PL_stack[$mark]);
        }
    }
    else{
        $#PL_stack = $newsp;
    }

    LEAVE;

    POPSUB($cx);
    # XXX: How to do {$cv->DEPTH = $cx->olddepth}?

    return $cx->retop;
}
sub pp_return{
    my $mark = POPMARK;

    my $cxix = dopoptosub($#PL_cxstack);
    if($cxix < 0){
        apvm_die q{Can't return outside a subroutine};
    }

    if($cxix < $#PL_cxstack){
        dounwind($cxix);
    }

    my $cx = POPBLOCK;
    my $popsub2;
    my $retop;

    if($cx->type eq 'SUB'){
        $popsub2 = TRUE;
        $retop   = $cx->retop;
    }
    else{
        not_implemented 'return for ' . $cx->type
    }

    my $newsp = $cx->oldsp;
    my $gimme = $cx->gimme;
    if($gimme == G_SCALAR){
        if($mark < $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy(TOP);
        }
        else{
            $PL_stack[++$newsp] = sv_undef;
        }
    }
    elsif($gimme == G_ARRAY){
        while(++$mark <= $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy($PL_stack[$mark]);
        }
    }
    $#PL_stack = $newsp;

    LEAVE;

    if($popsub2){
        POPSUB($cx);
    }
    return $retop;
}

sub pp_enter{

    my $gimme = OP_GIMME($PL_op, -1);

    if($gimme == -1){
        if(@PL_cxstack){
            $gimme = $PL_cxstack[-1]->gimme;
        }
        else{
            $gimme = G_SCALAR;
        }
    }

    ENTER;
    SAVETMPS;

    PUSHBLOCK(BLOCK =>
        oldsp => $#PL_stack,
        gimme => $gimme
    );

    return $PL_op->next;
}
sub pp_leave{

    my $cx    = POPBLOCK;
    my $newsp = $cx->oldsp;
    my $gimme = OP_GIMME($PL_op, -1);
    if($gimme == -1){
        if(@PL_cxstack){
            $gimme = $PL_cxstack[-1]->gimme;
        }
        else{
            $gimme = G_SCALAR;
        }
    }

    if($gimme == G_VOID){
        $#PL_stack = $newsp;
    }
    elsif($gimme == G_SCALAR){
        my $mark = $newsp + 1;
        if($mark <= $#PL_stack){
            $PL_stack[$mark] = sv_mortalcopy(TOP);
        }
        else{
            $PL_stack[$mark] = sv_undef;
        }
        $#PL_stack = $mark;
    }
    else{ # G_ARRAY
        for(my $mark = $newsp + 1; $mark <= $#PL_stack; $mark++){
            $PL_stack[$mark] = sv_mortalcopy($PL_stack[$mark]);
        }
    }

    LEAVE;

    return $PL_op->next;
}


sub pp_enterloop{

    ENTER;
    SAVETMPS;
    ENTER;

    PUSHBLOCK(LOOP => 
        oldsp   => $#PL_stack,
        gimme   => GIMME_V,

        resetsp => $#PL_stack,
    );

    return $PL_op->next;
}

sub pp_leaveloop{
    my $cx = POPBLOCK;

    my $mark  = $cx->oldsp;
    my $gimme = $cx->gimme;
    my $newsp = $cx->resetsp;

    if($gimme == G_SCALAR){
        if($mark < $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy($PL_stack[-1]);
        }
        else{
            $PL_stack[++$newsp] = sv_undef;
        }
    }
    elsif($gimme == G_ARRAY){
        while($mark < $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy($PL_stack[++$mark]);
        }
    }

    $#PL_stack = $newsp;

    POPLOOP($cx);

    LEAVE;
    LEAVE;

    return $PL_op->next;
}

sub _range_is_numeric{
    my($min, $max) = @_;
    return looks_like_number(${$min->object_2svref})
        && looks_like_number(${$max->object_2svref});
}

sub pp_enteriter{
    my $mark = POPMARK;
    my $sv;
    my $iterdata;
    my $padvar  = FALSE;
    my $for_def = FALSE;

    ENTER;
    SAVETMPS;

    if($PL_op->targ){
        if(USE_ITHREADS){
            #SAVEPADSV($PL_op->targ);
            $padvar   = TRUE;
            $iterdata = $PL_op->targ;
        }
        else{
            SAVE($PL_curpad[$PL_op->targ]);
            $sv = $PL_curpad[$PL_op->targ];
            $iterdata = $sv;
        }
    }
    else{
        my $gv = POP;
        $sv = save_scalar($gv);
        if(USE_ITHREADS){
            $iterdata = $gv;
        }
        else{
            $iterdata = $sv;
        }
    }

#    if($PL_op->private & OPpITER_DEF){
#        $for_def = TRUE;
#    }

    ENTER;

    my $cx = PUSHBLOCK(FOREACH => 
        oldsp => $#PL_stack,
        gimme => GIMME_V,

        resetsp  => $mark,
        iterdata => $iterdata,
        padvar   => $padvar,
        for_def  => $for_def,
    );

    if($PL_op->flags & OPf_STACKED){
        my $iterary = POP;
        if($iterary->class ne 'AV'){
            my $sv    = POP;
            my $right = $iterary;
            if(_range_is_numeric($sv, $right)){
                $cx->iterix(SvIV($sv));
                $cx->itermax(SvIV($right));
            }
            else{
                $cx->iterlval(SvPV($sv));
                $cx->iterary(SvPV($sv));
            }
        }
        else{
            $cx->iterary([$iterary->ARRAY]);

            if($PL_op->private & OPpITER_REVERSED){
                $cx->itermax(0);
                $cx->iterix($iterary->FILL + 1);
            }
            else{
                $cx->iterix(-1);
            }
        }

        # XXX: original code does not have this adjustment.
        #      is it OK?
        $cx->oldsp($#PL_stack);
    }
    else{
        $cx->iterary(\@PL_stack);
        if($PL_op->private & OPpITER_REVERSED){
            $cx->itermax($mark + 1);
            $cx->iterix($cx->oldsp + 1);
        }
        else{
            $cx->iterix($mark);
        }
    }
    return $PL_op->next;
}
sub pp_iter{
    my $cx = $PL_cxstack[-1];

    my $itersv  = $cx->ITERVAR;
    my $iterary = $cx->iterary;

    if(ref($iterary) ne 'ARRAY'){ # iterate range
        if(my $cur = $cx->iterlval){
            not_implemented 'string range in foreach';
        }

        # integer increment
        if($cx->iterix > $cx->itermax){
            PUSH(sv_no);
            return $PL_op->next;
        }

        $itersv->setval($cx->iterix);
        $cx->iterix($cx->iterix+1);

        PUSH(sv_yes);
        return $PL_op->next;
    }

    # iteratte array
    if($PL_op->private & OPpITER_REVERSED){
        if($cx->iterix <= $cx->itermax){
            PUSH(sv_no);
            return $PL_op->next;
        }
        $cx->iterix($cx->iterix-1);
    }
    else{
        my $max = $iterary == \@PL_stack ? $cx->oldsp : $#{$iterary};
        if($cx->iterix >= $max){
            PUSH(sv_no);
            return $PL_op->next;
        }
        $cx->iterix($cx->iterix+1);
    }

    my $sv = $iterary->[$cx->iterix] || sv_no;
    $itersv->setsv($sv);

    PUSH(sv_yes);
    return $PL_op->next;
}

sub pp_lineseq{
    return $PL_op->next;
}

sub pp_unstack{
    $#PL_stack = $PL_cxstack[-1]->oldsp;

    FREETMPS;
    LEAVE_SCOPE($PL_scopestack[-1]);

    return $PL_op->next;
}

sub pp_stub{
    if(GIMME_V == G_SCALAR){
        PUSH(sv_undef);
    }
    return $PL_op->next;
}


sub _dopoptoloop{
    my $cxix;
    if($PL_op->flags & OPf_SPECIAL){
        $cxix = dopoptoloop($#PL_cxstack);
        if($cxix < 0){
            apvm_die q{Can't "%s" outside a loop block}, $PL_op->name
        }
    }
    else{
        $cxix = dopoptolabel($PL_op->pv);
        if($cxix < 0){
            apvm_die q{Label not found for "%s %s"}, $PL_op->name, $PL_op->pv;
        }
    }

    return $cxix;
}

sub pp_last{
    my $cxix = _dopoptoloop();
    if($cxix < $#PL_cxstack){
        dounwind($cxix);
    }

    my $cx   = POPBLOCK;
    my $newsp= $cx->oldsp;
    my $mark = $newsp;
    my $type = $cx->type;
    my $nextop;

    if($type eq 'LOOP'){
        $newsp  = $cx->resetsp;
        $nextop = $cx->myop->lastop->next;
    }
    elsif($type eq 'SUB'){
        $nextop = $cx->retop;
    }
    else{
        not_implemented "last($type)";
    }

    my $gimme = $cx->gimme;
    if($gimme == G_SCALAR){
        if($mark < $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy($PL_stack[-1]);
        }
        else{
            $PL_stack[++$newsp] = sv_undef;
        }
    }
    elsif($gimme == G_SCALAR){
        while($mark < $#PL_stack){
            $PL_stack[++$newsp] = sv_mortalcopy($PL_stack[-1]);
        }
    }
    $#PL_stack = $newsp;
    LEAVE;

    if($type eq 'LOOP'){
        POPLOOP($cx);
        LEAVE;
    }
    elsif($type eq 'SUB'){
        POPSUB($cx);
    }
    return $nextop;
}

sub pp_next{
    my $cxix = _dopoptoloop();
    if($cxix < $#PL_cxstack){
        dounwind($cxix);
    }

    my $cx    = TOPBLOCK;
    LEAVE_SCOPE($PL_scopestack[-1]);
    $PL_curcop = $cx->oldcop;
    return $cx->nextop;
}
sub pp_redo{
    my $cxix = _dopoptoloop();

    my $op = $PL_cxstack[$cxix]->myop->redoop;

    if($op->name eq 'enter'){
        $cxix++;
        $op = $op->next;
    }

    if($cxix < $#PL_cxstack){
        dounwind($cxix);
    }

    my $cx = TOPBLOCK;
    LEAVE_SCOPE($PL_scopestack[-2]);
    FREETMPS;

    $PL_curcop = $cx->oldcop;
    return $op;
}


sub pp_sassign{
    my $right = POP;
    my $left  = TOP;

    if($PL_op->private & OPpASSIGN_BACKWARDS){
        ($left, $right) = ($right, $left);
    }
    $right->setsv($left);
    SET($right);
    return $PL_op->next;
}

sub pp_aassign{
    my $last_l_elem  = $#PL_stack;
    my $last_r_elem  = POPMARK();
    my $first_r_elem = POPMARK() + 1;
    my $first_l_elem = $last_r_elem + 1;

    my @lhs = @PL_stack[$first_l_elem .. $last_l_elem];
    my @rhs = @PL_stack[$first_r_elem .. $last_r_elem];

    if($PL_op->private & OPpASSIGN_COMMON){
        for(my $r_elem = $first_r_elem; $r_elem <= $last_r_elem; $r_elem++){
            $PL_stack[$r_elem] = sv_mortalcopy($PL_stack[$r_elem]);
        }
    }

    my $ary_ref;
    my $hash_ref;

    my $l_elem = $first_l_elem;
    my $r_elem = $first_r_elem;

    my $gimme = GIMME_V;
    my $hv;

    while($l_elem <= $last_l_elem){
        my $sv = $PL_stack[$l_elem++];

        if($sv->class eq 'AV'){
            $ary_ref = $sv->object_2svref;
            @{ $ary_ref } = ();
            while($r_elem <= $last_r_elem){
                push @{$ary_ref}, ${ $PL_stack[$r_elem]->object_2svref };
                $PL_stack[$r_elem++] = svref_2object(\$ary_ref->[-1]);
            }
        }
        elsif($sv->class eq 'HV'){
            $hv = $sv;
            $hash_ref = $sv->object_2svref;
            %{$hash_ref} = ();

            while($r_elem < $last_r_elem){
                my $key = $PL_stack[$r_elem++];
                my $val = $PL_stack[$r_elem++];

                $sv->store_ent($key, $val || sv_undef);
            }

            if($r_elem == $last_r_elem){
                apvm_warn 'Odd number of elements in hash assignment';
                $r_elem++;
            }
        }
        else{
            if($$sv == ${sv_undef()}){ # (undef) = (...)
                if($r_elem <= $last_r_elem){
                    $r_elem++;
                }
            }
            elsif($r_elem <= $last_r_elem){
                $sv->setsv($PL_stack[$r_elem]);
                $PL_stack[$r_elem++] = $sv;
            }
        }
    }

    if($gimme == G_VOID){
        $#PL_stack = $first_r_elem - 1;
    }
    elsif($gimme == G_SCALAR){
        $#PL_stack = $first_r_elem;
        SETval($last_r_elem - $first_r_elem + 1);
    }
    else{
        $l_elem = $first_l_elem + ($r_elem + $first_r_elem);
        while($r_elem <= $#PL_stack){
            $PL_stack[$r_elem++] = ($l_elem <= $last_l_elem) ? $PL_stack[$l_elem++] : sv_undef;
        }

        if($ary_ref){
            $#PL_stack = $last_r_elem;
        }
        elsif($hash_ref){
            $#PL_stack = $first_r_elem;
            SET($hv);

            return &_do_kv;
        }
        else{
            $#PL_stack = $first_r_elem + ($last_l_elem - $first_l_elem);
        }
    }

    return $PL_op->next;
}

sub pp_cond_expr{
    if(SvTRUE(POP)){
        return $PL_op->other;
    }
    else{
        return $PL_op->next;
    }
}

sub pp_and{
    if(!SvTRUE(TOP)){
        return $PL_op->next;
    }
    else{
        --$#PL_stack;
        return $PL_op->other;
    }
}
sub pp_or{
    if(SvTRUE(TOP)){
        return $PL_op->next;
    }
    else{
        --$#PL_stack;
        return $PL_op->other;
    }
}
sub pp_andassign{
    if(!SvTRUE(TOP)){
        return $PL_op->next;
    }
    else{
        return $PL_op->other;
    }
}
sub pp_orassign{
    if(SvTRUE(TOP)){
        return $PL_op->next;
    }
    else{
        return $PL_op->other;
    }
}

sub pp_stringify{
    my $sv = TOP;
    SETval(SvPV($sv));
    return $PL_op->next;
}

sub pp_defined{
    my $sv   = POP;
    my $type = $sv->class;
    my $ref  = $sv->object_2svref;

    my $defined;
    if($type eq 'AV'){
        $defined = defined @{$ref};
    }
    elsif($type eq 'HV'){
        $defined = defined %{$ref};
    }
    elsif($type eq 'CV'){
        $defined = defined &{$ref};
    }
    else{
        $defined = defined ${$ref};
    }
    PUSH($defined ? sv_yes : sv_no);
    return $PL_op->next;
}

sub pp_range{
    if(GIMME_V == G_ARRAY){
        return $PL_op->next;
    }

    if(SvTRUE(GET_TARGET)){
        return $PL_op->other;
    }
    else{
        return $PL_op->next;
    }
}

sub pp_flip{
    if(GIMME_V == G_ARRAY){
        return $PL_op->first->other;
    }

    not_implemented 'flip-flop in scalar context';
}
sub pp_flop{
    if(GIMME_V == G_ARRAY){
        my $right = POP;
        my $left  = POP;

        my $i   = ${$left->object_2svref};
        my $max = ${$right->object_2svref};

        if(_range_is_numeric($left, $right) && $i >= $max){
            return $PL_op->next;
        }


        $max++;
        while($i ne $max){
            my $sv = sv_newmortal();
            $sv->setval($i);
            PUSH($sv);
            $i++;
        }
    }
    else{
        not_implemented 'flip-flop in scalar context';
    }

    return $PL_op->next;
}


sub pp_preinc{
    ${ TOP()->object_2svref }++;

    return $PL_op->next;
}
sub pp_postinc{
    my $targ = GET_TARGET;
    my $sv   = TOP;
    my $ref  = $sv->object_2svref;

    if(defined ${$sv}){
        $targ->setsv($sv);
    }
    else{
        $targ->setval(0);
    }
    ${$ref}++;

    SET($targ);
    return $PL_op->next;
}

sub pp_eq{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) == SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_ne{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) != SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_lt{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) < SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_le{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) <= SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_gt{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) > SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_ge{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) >= SvNV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_ncmp{
    my $right = POP;
    my $left  = TOP;
    SET(SvNV($left) <=> SvNV($right));
    return $PL_op->next;
}

sub pp_seq{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) eq SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_sne{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) ne SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_slt{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) lt SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_sle{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) le SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_sgt{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) gt SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_sge{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) ge SvPV($right) ? sv_yes : sv_no);
    return $PL_op->next;
}
sub pp_scmp{
    my $right = POP;
    my $left  = TOP;
    SET(SvPV($left) cmp SvPV($right));
    return $PL_op->next;
}


sub pp_add{
    my $targ  = GET_ATARGET;
    my $right = POP;
    my $left  = TOP;

    SET( $targ->setval(SvNV($left) + SvNV($right)) );
    return $PL_op->next;
}

sub pp_multiply{
    my $targ  = GET_ATARGET;
    my $right = POP;
    my $left  = TOP;

    SET( $targ->setval(SvNV($left) * SvNV($right)) );
    return $PL_op->next;
}

sub pp_concat{
    my $targ = GET_ATARGET;
    my $right= POP;
    my $left = TOP;

    SET( $targ->setval(SvPV($left) . SvPV($right)) );
    return $PL_op->next;
}

sub pp_readline{
    $PL_last_in_gv = POP;
    if($PL_last_in_gv->class ne 'GV'){
        PUSH($PL_last_in_gv);
        &pp_rv2gv;
        $PL_last_in_gv = POP;
    }

    # do_readline
    my $targ    = GET_TARGETSTACKED;
    my $istream = $PL_last_in_gv->object_2svref;

    my $gimme = GIMME_V;
    if($gimme == G_ARRAY){
        mPUSH(map{ svref_2object(\$_) } readline $istream);
    }
    else{
        $targ->setval(scalar readline $istream);
        PUSH($targ);
    }

    return $PL_op->next;
}

sub pp_print{
    my $mark     = POPMARK;
    my $origmark = $mark;
    my $gv   = ($PL_op->flags & OPf_STACKED) ? $PL_stack[++$mark]->object_2svref : defoutgv;

    my $ret  = print {$gv} mark_list($mark);

    $#PL_stack = $origmark;
    PUSH( $ret ? sv_yes : sv_no );
    return $PL_op->next;
}
sub pp_say{
    my $mark     = POPMARK;
    my $origmark = $mark;
    my $gv   = ($PL_op->flags & OPf_STACKED) ? $PL_stack[++$mark]->object_2svref : defoutgv;

    local $\ = "\n";
    my $ret  = print {$gv} mark_list($mark);

    $#PL_stack = $origmark;
    PUSH( $ret ? sv_yes : sv_no );
    return $PL_op->next;
}

sub pp_bless{
    my $pkg;
    if(MAXARG == 1){
        $pkg = $PL_curcop->stashpv;
    }
    else{
        my $sv = POP;
        if($sv->ROK){
            apvm_die 'Attempt to bless into a reference';
        }
        $pkg = SvPV($sv);
        if($pkg eq ''){
            apvm_warn q{Explicit blessing to '' (assuming package main)};
        }
    }
    bless ${TOP->object_2svref}, $pkg;
    return $PL_op->next;
}

sub pp_push{
    my $mark = POPMARK;
    my $av   = $PL_stack[++$mark];
    my $n    = push @{$av->object_2svref}, mark_list($mark);
    SETval($n);
    return $PL_op->next;
}

sub pp_pop{
    my $av  = POP;
    my $val = pop @{$av->object_2svref};
    mPUSH(svref_2object(\$val));
    return $PL_op->next;
}

sub pp_shift{
    my $av  = POP;
    my $val = shift @{$av->object_2svref};
    mPUSH(svref_2object(\$val));
    return $PL_op->next;
}

sub pp_unshift{
    my $mark = POPMARK;
    my $av   = $PL_stack[++$mark];
    my $n    = unshift @{$av->object_2svref}, mark_list($mark);
    SETval($n);
    return $PL_op->next;
}

sub pp_join{
    my $mark = POPMARK;

    my $delim = $PL_stack[++$mark];
    SETval(join SvPV($delim), mark_list($mark));
    return $PL_op->next;
}

sub pp_aelemfast{
    my $av   = $PL_op->flags & OPf_SPECIAL ? PAD_SV($PL_op->targ) : GVOP_gv($PL_op)->AV;
    my $lval = $PL_op->flags & OPf_MOD || LVRET;

    PUSH( svref_2object(\$av->object_2svref->[$PL_op->private]) );
    return $PL_op->next;
}

sub pp_aelem{
    my $elemsv = POP;
    my $av     = TOP;
    my $lval   = $PL_op->flags & OPf_MOD || LVRET;

    if($elemsv->ROK){
        apvm_warn q{Use of reference %s as array index}, $elemsv->object_2svref;
    }

    SET( svref_2object(\$av->object_2svref->[SvIV($elemsv)]) );
    return $PL_op->next;
}

sub pp_helem{
    my $keysv = POP;
    my $hv    = TOP;
    my $lval  = $PL_op->flags & OPf_MOD || LVRET;

    SET( svref_2object(\$hv->object_2svref->{SvPV($keysv)}) );
    return $PL_op->next;
}
sub pp_keys{
    return &_do_kv;
}
sub pp_values{
    return &_do_kv;
}

sub pp_wantarray{
    my $cxix = dopoptosub($#PL_cxstack);
    if($cxix < 0){
        PUSH(sv_undef);
    }
    else{
        my $gimme = $PL_cxstack[$cxix]->gimme;
        if($gimme == G_ARRAY){
            PUSH(sv_yes);
        }
        elsif($gimme == G_SCALAR){
            PUSH(sv_no);
        }
        else{
            PUSH(sv_undef);
        }
    }
    return $PL_op->next;
}

sub pp_undef{
    if(!$PL_op->private){
        PUSH(sv_undef);
        return $PL_op->next;
    }

    not_implemented 'undef(expr)';
}

sub pp_scalar{
    return $PL_op->next;
}

sub pp_not{
    SET( !SvTRUE(TOP) ? sv_yes : sv_no );
    return $PL_op->next;
}

sub pp_qr{
    my $re = $PL_op->precomp;

    mPUSH(svref_2object(\qr/$re/));
    return $PL_op->next;
}


1;
__END__

=head1 NAME

Acme::Perl::VM::PP - ppcodes for APVM

=head1 SYNOPSIS

    use Acme::Perl::VM;

=head1 PPCODE

Implemented ppcodes:

=over 4

=item pp_nextstate

=item pp_pushmark

=item pp_const

=item pp_gv

=item pp_padsv

=item pp_padav

=item pp_rv2av

=item pp_list

=item pp_method

=item pp_method_named

=item pp_entersub

=item pp_leavesub

=item pp_return

=item pp_enter

=item pp_leave

=item pp_enterloop

=item pp_leaveloop

=item pp_lineseq

=item pp_stub

=item pp_unstack

=item pp_sassign

=item pp_aassign

=item pp_cond_expr

=item pp_and

=item pp_or

=item pp_range

=item pp_preinc

=item pp_lt

=item pp_add

=item pp_concat

=item pp_print

=item pp_aelemfast

=item pp_aelem

=item pp_helem

=item pp_undef

=item pp_scalar

=item pp_not

=item pp_anonhash

=item pp_anonlist

=item pp_defined

=item pp_enterite

=item pp_eq

=item pp_ge

=item pp_gt

=item pp_gvsv

=item pp_enteriter

=item pp_iter

=item pp_keys

=item pp_last

=item pp_le

=item pp_ne

=item pp_next

=item pp_padhv

=item pp_postinc

=item pp_readline

=item pp_redo

=item pp_refgen

=item pp_rv2gv

=item pp_rv2hv

=item pp_rv2sv

=item pp_say

=item pp_srefgen

=item pp_values

=back

=cut

