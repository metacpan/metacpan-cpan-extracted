package Acme::Perl::VM;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.006';

use constant APVM_DEBUG  => ( $ENV{APVM} || $ENV{APVM_DEBUG} || 0 );
use constant {
    APVM_TRACE => scalar(APVM_DEBUG =~ /\b trace \b/xmsi),
    APVM_SCOPE => scalar(APVM_DEBUG =~ /\b scope \b/xmsi),
    APVM_CX    => scalar(APVM_DEBUG =~ /\b (?: cx | context ) \b/xmsi),
    APVM_STACK => scalar(APVM_DEBUG =~ /\b stack \b/xmsi),

    APVM_DUMMY => scalar(APVM_DEBUG =~ /\b dummy \b/xmsi),
};

use Exporter qw(import);

BEGIN{
    our @EXPORT      = qw(run_block call_sv);
    our @EXPORT_OK   = qw(
        $PL_op $PL_curcop
        @PL_stack @PL_markstack @PL_cxstack @PL_scopestack @PL_savestack @PL_tmps
        $PL_tmps_floor
        $PL_comppad $PL_comppad_name @PL_curpad
        $PL_last_in_gv
        $PL_runops
        @PL_ppaddr

        PUSHMARK POPMARK TOPMARK
        PUSH POP TOP SET SETval
        mPUSH
        GET_TARGET
        GET_TARGETSTACKED
        GET_ATARGET
        MAXARG

        PUSHBLOCK POPBLOCK TOPBLOCK
        PUSHSUB POPSUB
        PUSHLOOP POPLOOP

        dounwind

        ENTER LEAVE LEAVE_SCOPE
        SAVETMPS FREETMPS
        SAVE SAVECOMPPAD SAVECLEARSV
        SAVEPADSV
        save_scalar save_ary save_hash

        OP_GIMME GIMME_V LVRET

        PAD_SV PAD_SET_CUR_NOSAVE PAD_SET_CUR
        CX_CURPAD_SAVE CX_CURPAD_SV

        dopoptosub dopoptoloop dopoptolabel

        deb apvm_warn apvm_die croak ddx

        GVOP_gv

        vivify_ref
        sv_newmortal sv_mortalcopy sv_2mortal
        SvPV SvNV SvIV SvTRUE
        av_assign av_store
        hv_store hv_store_ent hv_scalar

        defoutgv
        gv_fullname

        looks_like_number
        sv_defined is_null is_not_null
        mark_list
        not_implemented
        dump_object dump_value dump_stack dump_si

        apvm_extern
        cv_external

        APVM_DEBUG APVM_DUMMY
        APVM_SCOPE APVM_TRACE
    );
    our %EXPORT_TAGS = (
        perl_h => \@EXPORT_OK,
    );

    if(APVM_DEBUG && -t *STDERR){
        require Term::ANSIColor;

        *deb = \&_deb_colored;
    }
    else{
        *deb = \&_deb;
    }
}

use Scalar::Util qw(looks_like_number refaddr);
use Carp ();

use Acme::Perl::VM::Context;
use Acme::Perl::VM::Scope;
use Acme::Perl::VM::PP;
use Acme::Perl::VM::B;

our $PL_runops = (APVM_TRACE || APVM_STACK)
    ? \&runops_debug
    : \&runops_standard;

our $PL_op;
our $PL_curcop;

our @PL_stack;
our @PL_markstack;
our @PL_cxstack;
our @PL_scopestack;
our @PL_savestack;
our @PL_tmps;

our $PL_tmps_floor;

our $PL_comppad;
our $PL_comppad_name;
our @PL_curpad;

our $PL_last_in_gv;

our @PL_ppaddr;

our $color = 'GREEN BOLD'; # for debugging log

sub not_implemented;

{
    my $i = 0;
    while(my $ppname = B::ppname($i)){
        my $ppaddr = \$Acme::Perl::VM::PP::{$ppname};

        if(ref($ppaddr) eq 'GLOB'){
            $PL_ppaddr[$i] = *{$ppaddr}{CODE};
        }

        $PL_ppaddr[$i] ||= sub{ not_implemented($ppname) };

        $i++;
    }
}

sub runops_standard{ # run.c
    1 while(${ $PL_op = &{$PL_ppaddr[ $PL_op->type ]} });
    return;
}

sub _op_trace{
    my $flags = $PL_op->flags;
    my $name  = $PL_op->name;

    deb '.%s', $name;
    if(ref($PL_op) eq 'B::COP'){
        deb '(%s%s %s:%d)', 
            ($PL_op->label ? $PL_op->label.': ' : ''),
            $PL_op->stashpv,
            $PL_op->file, $PL_op->line,
        ;
    }
    elsif($name eq 'entersub'){
        my $gv = TOP;
        if(!$gv->isa('B::GV')){
            $gv = $gv->GV;
        }
        deb '(%s)', gv_fullname($gv, '&');
    }
    elsif($name eq 'aelemfast'){
        my $name;
        if($flags & OPf_SPECIAL){
            my $padname = $PL_comppad_name->ARRAYelt($PL_op->targ);
            $name = $padname->POK ? '@'.$padname->PVX : '[...]';
        }
        else{
            $name = gv_fullname(GVOP_gv($PL_op), '@');
        }
        deb '[%s[%s]]', $name, $PL_op->private;
    }
    elsif($PL_op->targ && $name !~ /leave/){
        if($name eq 'const' || $name eq 'method_named'){
            my $sv = PAD_SV($PL_op->targ);

            if(is_scalar($sv)){
                deb '(%s)', $sv->POK ? B::perlstring($sv->PVX) : $sv->as_string;
            }
            else{
                deb '(%s)', ddx([$sv->object_2svref])->Indent(0)->Dump;
            }
        }
        else{
            my $padname = $PL_comppad_name->ARRAYelt($PL_op->targ);
            if($padname->POK){
                deb '(%s)', $padname->PVX;
                deb ' INTRO' if $PL_op->private & OPpLVAL_INTRO;
            }
        }
    }
    elsif($PL_op->can('sv')){
        my $sv = SVOP_sv($PL_op);
        if($sv->class eq 'GV'){
            my $prefix = $name eq 'gvsv' ? '$' : '*';
            deb '(%s)', gv_fullname($sv, $prefix);
            deb ' INTRO' if $PL_op->private & OPpLVAL_INTRO;
        }
        else{
            deb '(%s)', B::perlstring(SvPV(SVOP_sv($PL_op)));
        }
    }

    deb ' VOID'    if( ($flags & OPf_WANT) == OPf_WANT_VOID   );
    deb ' SCALAR'  if( ($flags & OPf_WANT) == OPf_WANT_SCALAR );
    deb ' LIST'    if( ($flags & OPf_WANT) == OPf_WANT_LIST   );

    deb ' KIDS'    if $flags & OPf_KIDS;
    deb ' PARENS'  if $flags & OPf_PARENS;
    deb ' REF'     if $flags & OPf_REF;
    deb ' MOD'     if $flags & OPf_MOD;
    deb ' STACKED' if $flags & OPf_STACKED;
    deb ' SPECIAL' if $flags & OPf_SPECIAL;

    deb "\n";
}

sub runops_debug{
    _op_trace();
    while(${ $PL_op = &{$PL_ppaddr[$PL_op->type]} }){
        if(APVM_STACK){
            dump_stack();
        }

        _op_trace();
    }
    if(APVM_STACK){
        dump_stack();
    }
    return;
}

sub _deb_colored{
    my($fmt, @args) = @_;
    printf STDERR Term::ANSIColor::colored($fmt, $color), @args;
    return;
}
sub _deb{
    my($fmt, @args) = @_;
    printf STDERR $fmt, @args;
    return;
}

sub mess{ # util.c
    my($fmt, @args) = @_;
    my $msg = sprintf $fmt, @args;
    return sprintf "[APVM] %s in %s at %s line %d.\n",
        $msg, $PL_op->desc, $PL_curcop->file, $PL_curcop->line;
}

sub longmess{
    my $msg = mess(@_);
    my $cxix = $#PL_cxstack;
    while( ($cxix = dopoptosub($cxix)) >= 0 ){
        my $cx   = $PL_cxstack[$cxix];
        my $cop  = $cx->oldcop;

        my $args;

        if($cx->argarray){
            $args = sprintf '(%s)', join q{,},
            map{ defined($_) ? qq{'$_'} : 'undef' }
                @{ $cx->argarray->object_2svref };
        }
        else{
            $args = '';
        }

        my $cvgv = $cx->cv->GV;
        $msg .= sprintf qq{[APVM]   %s%s called at %s line %d.\n},
            gv_fullname($cvgv), $args,
            $cop->file, $cop->line;

        $cxix--;
    }
    return $msg;
}

sub apvm_warn{
    #warn APVM_DEBUG ? longmess(@_) : mess(@_);
    print STDERR longmess(@_);
}
sub apvm_die{
    # not yet implemented completely
    # cf.
    # die_where() in pp_ctl.c
    # vdie()      in util.c
    die  APVM_DEBUG ? longmess(@_) : mess(@_);
}
sub croak{
    die  APVM_DEBUG ? longmess(@_) : mess(@_);
}

sub PUSHMARK(){
    push @PL_markstack, $#PL_stack;
    return;
}
sub POPMARK(){
    return pop @PL_markstack;
}
sub TOPMARK(){
    return $PL_markstack[-1];
}

sub PUSH{
    push @PL_stack, @_;
    return;
}
sub mPUSH{
    PUSH(map{ sv_2mortal($_) } @_);
    return;
}
sub POP(){
    return pop @PL_stack;
}
sub TOP(){
    return $PL_stack[-1];
}
sub SET{
    my($sv) = @_;
    $PL_stack[-1] = $sv;
    return;
}
sub SETval{
    my($val) = @_;
    $PL_stack[-1] = PAD_SV( $PL_op->targ )->setval($val);
    return;
}

sub GET_TARGET{
    return PAD_SV($PL_op->targ);
}
sub GET_TARGETSTACKED{
    return $PL_op->flags & OPf_STACKED ? POP : PAD_SV($PL_op->targ);
}
sub GET_ATARGET{
    return $PL_op->flags & OPf_STACKED ? $PL_stack[$#PL_stack-1] : PAD_SV($PL_op->targ);
}

sub MAXARG{
    return $PL_op->private & 0x0F;
}

sub PUSHBLOCK{
    my($type, %args) = @_;

    $args{oldcop}     = $PL_curcop;
    $args{oldmarksp}  = $#PL_markstack;
    $args{oldscopesp} = $#PL_scopestack;

    my $cx = "Acme::Perl::VM::Context::$type"->new(\%args);
    push @PL_cxstack, $cx;

    if(APVM_CX){
        deb "%s" . "Entering %s\n", (q{>} x @PL_cxstack), $type;
    }

    return $cx;
}

sub POPBLOCK{
    my $cx = pop @PL_cxstack;

    $PL_curcop      = $cx->oldcop;
    $#PL_markstack  = $cx->oldmarksp;
    $#PL_scopestack = $cx->oldscopesp;

    if(APVM_CX){
        deb "%s" . "Leaving %s\n", (q{>} x (@PL_cxstack+1)), $cx->type;
    }

    return $cx;
}
sub TOPBLOCK{
    my $cx = $PL_cxstack[-1];

    $#PL_stack      = $cx->oldsp;
    $#PL_markstack  = $cx->oldmarksp;
    $#PL_scopestack = $cx->oldscopesp;

    return $cx;
}

sub POPSUB{
    my($cx) = @_;
    if($cx->hasargs){
        *_ = $cx->savearray;

        @{ $cx->argarray->object_2svref } = ();
    }
    return;
}

sub POPLOOP{
    my($cx) = @_;

    if($cx->ITERVAR){
        if($cx->padvar){
            my $padix  = $cx->iterdata;
            #my $curpad = $PL_comppad->object_2svref;

            #delete $curpad->[$padix];
            #$curpad->[$padix] = $cx->itersave;
            #dump_object($PL_curpad[$padix], $cx->itersave);
            $PL_curpad[$padix] = $cx->itersave;
        }
    }
    return;
}

sub dounwind{
    my($cxix) = @_;

    while($#PL_cxstack > $cxix){
        my $cx   = pop @PL_cxstack;
        my $type = $cx->type;

        if($type eq 'SUBST'){
            POPSUBST($cx);
        }
        elsif($type eq 'SUB'){
            POPSUB($cx);
        }
        elsif($type eq 'EVAL'){
            POPEVAL($cx);
        }
        elsif($type eq 'LOOP'){
            POPLOOP($cx);
        }
    }
    return;
}

sub ENTER{
    push @PL_scopestack, $#PL_savestack;
    if(APVM_SCOPE){
        deb "%s" . "ENTER\n", ('>' x @PL_scopestack);
    }
    return;
}

sub LEAVE{
    my $oldsave = pop @PL_scopestack;
    LEAVE_SCOPE($oldsave);

    if(APVM_SCOPE){
        deb "%s" . "LEAVE\n", ('>' x (@PL_scopestack+1));
    }
    return;
}
sub LEAVE_SCOPE{
    my($oldsave) = @_;

    while( $oldsave < $#PL_savestack ){
        my $ss = pop @PL_savestack;

        if(APVM_SCOPE){
            deb "%s" . "leave %s %s\n",
                ('>' x (@PL_cxstack+1)), $ss->type, $ss->saved_state;
        }
        $ss->leave();
    }
    return;
}

sub SAVETMPS{
    push @PL_savestack, Acme::Perl::VM::Scope::Tmps->new(
        value     =>  $PL_tmps_floor,
        value_ref => \$PL_tmps_floor,
    );
    $PL_tmps_floor = $#PL_tmps;
    return;
}
sub FREETMPS{
    $#PL_tmps = $PL_tmps_floor;
    return;
}

sub SAVE{
    push @PL_savestack, Acme::Perl::VM::Scope::Value->new(
        value     =>  $_[0],
        value_ref => \$_[0],
    );
    return;
}
sub SAVECOMPPAD{
    push @PL_savestack, Acme::Perl::VM::Scope::Comppad->new(
        comppad      => $PL_comppad,
        comppad_name => $PL_comppad_name,
    );
    return;
}
sub SAVECLEARSV{
    my($sv) = @_;
    push @PL_savestack, Acme::Perl::VM::Scope::Clearsv->new(
        sv  => $sv,
    );
    return;
}
sub SAVEPADSV{
    my($off) = @_;
    push @PL_savestack, Acme::Perl::VM::Scope::Padsv->new(
        off     => $off,
        value   => ${$PL_curpad[$off]->object_2svref},
        comppad => $PL_comppad,
    );
    return;
}
sub save_scalar{
    my($gv) = @_;
    push @PL_savestack, Acme::Perl::VM::Scope::Scalar->new(gv => $gv);
    return $PL_savestack[-1]->sv;
}
sub save_ary{
    my($gv) = @_;
    push @PL_savestack, Acme::Perl::VM::Scope::Array->new(gv => $gv);
    return $PL_savestack[-1]->sv;
}
sub save_hash{
    my($gv) = @_;
    push @PL_savestack, Acme::Perl::VM::Scope::Hash->new(gv => $gv);
    return $PL_savestack[-1]->sv;
}

sub PAD_SET_CUR_NOSAVE{
    my($padlist, $nth) = @_;

    $PL_comppad_name = $padlist->ARRAYelt(0);
    $PL_comppad      = $padlist->ARRAYelt($nth);
    @PL_curpad       = ($PL_comppad->ARRAY);

    return;
}
sub PAD_SET_CUR{
    my($padlist, $nth) = @_;

    SAVECOMPPAD();
    PAD_SET_CUR_NOSAVE($padlist, $nth);

    return;
}

sub PAD_SV{
    #my($targ) = @_;

    return $PL_curpad[ $_[0] ];
}

sub dopoptosub{
    my($startingblock) = @_;

    for(my $i = $startingblock; $i >= 0; $i--){
        my $type = $PL_cxstack[$i]->type;

        if($type eq 'EVAL' or $type eq 'SUB'){
            return $i;
        }
    }
    return -1;
}

my %loop;
@loop{qw(SUBST SUB EVAL NULL)} = ();
$loop{LOOP}    = TRUE;

sub dopoptoloop{
    my($startingblock) = @_;

    for(my $i = $startingblock; $i >= 0; --$i){
        my $cx   = $PL_cxstack[$i];
        my $type = $cx->type;

        if(exists $loop{$type}){
            if(!$loop{$type}){
                apvm_warn 'Exsiting %s via %s', $type, $PL_op->name;
                $i = -1 if $type eq 'NULL';
            }
            return $i;
        }
    }
    return -1;
}
sub dopoptolabel{
    my($label) = @_;

    for(my $i = $#PL_cxstack; $i >= 0; --$i){
        my $cx   = $PL_cxstack[$i];
        my $type = $cx->type;

        if(exists $loop{$type}){
            if(!$loop{$type}){
                apvm_warn 'Exsiting %s via %s', $type, $PL_op->name;
                return $type eq 'NULL' ? -1 : $i;
            }
            elsif($cx->label && $cx->label eq $label){
                return $i;
            }
        }
    }
    return -1;
}

sub OP_GIMME{ # op.h
    my($op, $default) = @_;
    my $op_gimme = $op->flags & OPf_WANT;
    return $op_gimme == OPf_WANT_VOID   ? G_VOID
        :  $op_gimme == OPf_WANT_SCALAR ? G_SCALAR
        :  $op_gimme == OPf_WANT_LIST   ? G_ARRAY
        :                                 $default;
}

sub OP_GIMME_REVERSE{ # op.h
    my($flags) = @_;
    $flags &= G_WANT;
    return $flags == G_VOID   ? OPf_WANT_VOID
        :  $flags == G_SCALAR ? OPf_WANT_SCALAR
        :                       OPf_WANT_LIST;
}

sub gimme2want{
    my($gimme) = @_;
    $gimme &= G_WANT;
    return $gimme == G_VOID   ? undef
        :  $gimme == G_SCALAR ? 0
        :                       1;
}
sub want2gimme{
    my($wantarray) = @_;

    return !defined($wantarray) ? G_VOID
        :          !$wantarray  ? G_SCALAR
        :                         G_ARRAY;
}

sub block_gimme{
    my $cxix = dopoptosub($#PL_cxstack);

    if($cxix < 0){
        return G_VOID;
    }

    return $PL_cxstack[$cxix]->gimme;
}

sub GIMME_V(){ # op.h
    my $gimme = OP_GIMME($PL_op, -1);
    return $gimme != -1 ? $gimme : block_gimme();
}

sub LVRET(){ # cf. is_lvalue_sub() in pp_ctl.h
    if($PL_op->flags & OPpMAYBE_LVSUB){
        my $cxix = dopoptosub($#PL_cxstack);

        if($PL_cxstack[$cxix]->lval && $PL_cxstack[$cxix]->cv->CvFLAGS & CVf_LVALUE){
            not_implemented 'lvalue';
            return TRUE;
        }
    }
    return FALSE;
}

sub SVOP_sv{
    my($op) = @_;
    return USE_ITHREADS ? PAD_SV($op->padix) : $op->sv;
}
sub GVOP_gv{
    my($op) = @_;
    return USE_ITHREADS ? PAD_SV($op->padix) : $op->gv;
}

sub vivify_ref{
    not_implemented 'vivify_ref';
}

sub sv_newmortal{
    my $sv;
    push @PL_tmps, \$sv;
    return B::svref_2object(\$sv);
}
sub sv_mortalcopy{
    my($sv) = @_;

    if(!defined $sv){
        Carp::confess('sv_mortalcopy(NULL)');
    }

    my $newsv =${$sv->object_2svref};
    push @PL_tmps, \$newsv;
    return B::svref_2object(\$newsv);
}
sub sv_2mortal{
    my($sv) = @_;

    if(!defined $sv){
        Carp::confess('sv_2mortal(NULL)');
    }

    push @PL_tmps, $sv->object_2svref;
    return $sv;
}

sub SvTRUE{
    my($sv) = @_;

    return ${ $sv->object_2svref } ? TRUE : FALSE;
}

sub SvPV{
    my($sv) = @_;
    my $ref = $sv->object_2svref;

    if(!defined ${$ref}){
        apvm_warn 'Use of uninitialized value';
        return q{};
    }

    return "${$ref}";
}

sub SvNV{
    my($sv) = @_;
    my $ref = $sv->object_2svref;

    if(!defined ${$ref}){
        apvm_warn 'Use of uninitialized value';
        return 0;
    }

    return ${$ref} + 0;
}

sub SvIV{
    my($sv) = @_;
    my $ref = $sv->object_2svref;

    if(!defined ${$ref}){
        apvm_warn 'Use of uninitialized value';
        return 0;
    }

    return int(${$ref});
}

sub av_assign{
    my $av   = shift;
    my $ref  = $av->object_2svref;
    $#{$ref} = $#_;
    for(my $i = 0; $i < @_; $i++){
        tie $ref->[$i], 'Acme::Perl::VM::Alias', $_[$i]->object_2svref;
    }
    return;
}

sub av_store{
    my($av, $ix, $sv) = @_;
    tie $av->object_2svref->[$ix],
        'Acme::Perl::VM::Alias', $sv->object_2svref;
    return;
}

sub hv_store{
    my($hv, $key, $sv) = @_;
    tie $hv->object_2svref->{$key},
        'Acme::Perl::VM::Alias', $sv->object_2svref;
    return;
}

sub hv_store_ent{
    my($hv, $key, $sv) = @_;
    tie $hv->object_2svref->{ ${$key->object_2svref} },
        'Acme::Perl::VM::Alias', $sv->object_2svref;
    return;
}

sub hv_scalar{
    my($hv) = @_;
    my $sv = sv_newmortal();
    $sv->setval(scalar %{ $hv->object_2svref });
    return $sv;
}

sub defoutgv{
    no strict 'refs';
    return \*{ select() };
}

sub gv_fullname{
    my($gv, $prefix) = @_;
    $prefix = '' unless defined $prefix;

    my $stashname = $gv->STASH->NAME;
    if($stashname eq 'main'){
        $prefix .= $gv->SAFENAME;
    }
    else{
        $prefix .= join q{::}, $stashname, $gv->SAFENAME;
    }
    return $prefix;
}

# Utilities

sub sv_defined{
    my($sv) = @_;

    return $sv && ${$sv} && defined(${ $sv->object_2svref });
}

sub is_not_null{
    my($sv) = @_;
    return ${$sv};
}
sub is_null{
    my($sv) = @_;
    return !${$sv};
}

my %not_a_scalar;
@not_a_scalar{qw(AV HV CV IO)} = ();
sub is_scalar{
    my($sv) = @_;
    return !exists $not_a_scalar{ $sv->class };
}

sub mark_list{
    my($mark) = @_;
    return map{ ${ $_->object_2svref } } splice @PL_stack, $mark+1;
}


our %external;

sub apvm_extern{
    foreach my $arg(@_){
        if(ref $arg){
            if(ref($arg) ne 'CODE'){
                Carp::croak('Not a CODE reference for apvm_extern()');
            }
            $external{refaddr $arg} = 1;
        }
        else{
            my $stash = do{ no strict 'refs'; \%{$arg .'::'} };
            while(my $name = each %{$stash}){
                my $code_ref = do{ no strict 'refs'; *{$arg . '::' . $name}{CODE} };
                if(defined $code_ref){
                    $external{refaddr $code_ref} = 1;
                }
            }
        }
    }
    return;
}

sub cv_external{
    my($cv) = @_;
    return $cv->XSUB || $external{ ${$cv} };
}

sub ddx{
    require Data::Dumper;
    my $ddx = Data::Dumper->new(@_);
    $ddx->Indent(1);
    $ddx->Terse(TRUE);
    $ddx->Quotekeys(FALSE);
    $ddx->Useqq(TRUE);
    return $ddx if defined wantarray;

    my $name = ( split '::', (caller 2)[3] )[-1];
    print STDERR $name, ': ', $ddx->Dump(), "\n";
    return;
}
sub dump_object{
    ddx([[ map{ $_ ? $_->object_2svref : $_ } @_ ]]);
}

sub dump_value{
    ddx([\@_]);
}


sub dump_stack{
    require Data::Dumper;
    no warnings 'once';

    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Terse     = TRUE;
    local $Data::Dumper::Quotekeys = FALSE;
    local $Data::Dumper::Useqq     = TRUE;

    deb "(%s)\n", join q{,}, map{
        # find variable name
        my $varname = '';
        my $class   = $_->class;

        if($class eq 'SPECIAL'){
            ($varname = $_->special_name) =~ s/^\&PL_//;
            $varname;
        }
        elsif($class eq 'CV'){
            $varname = '&' . gv_fullname($_->GV);
        }
        else{
            for(my $padix = 0; $padix < @PL_curpad; $padix++){
                my $padname;
                if(${ $PL_curpad[$padix] } == ${ $_ }){
                    $padname = $PL_comppad_name->ARRAYelt($padix);
                }
                elsif($_->ROK && ${$PL_curpad[$padix]} == ${ $_->RV }){
                    $padname = $PL_comppad_name->ARRAYelt($padix);
                    $varname .= '\\';
                }

                if($padname){
                    if($padname->POK){
                        $varname .= $padname->PVX . ' ';
                    }
                    last;
                }
            }
            $varname . Data::Dumper->Dump([is_scalar($_) ? ${$_->object_2svref} : $_->object_2svref], [$_->ROK ? 'SV' : '*SV']);
        }

    } @PL_stack;

    return;
}
sub _dump_stack{
    my $warn;
    my $ddx = ddx([[map{
            if(ref $_){
                is_scalar($_) ? ${$_->object_2svref} : $_->object_2svref;
            }
            else{
                $warn++;
                $_;
            }
    } @PL_stack]], ['*PL_stack']);
    $ddx->Indent(0);
    deb "  %s\n", $ddx->Dump();

    if($warn){
        apvm_die 'No sv found (%d)', $warn;
    }
    return;
}

sub dump_si{
    my %stack_info = (
        stack     => \@PL_stack,
        markstack => \@PL_markstack,
        cxstack   => \@PL_cxstack,
        scopstack => \@PL_scopestack,
        savestack => \@PL_savestack,
        tmps      => \@PL_tmps,
    );

    ddx([\%stack_info]);
}

sub not_implemented{
    if(!@_){
        if($PL_op && is_not_null($PL_op)){
            @_ = ($PL_op->name);
        }
        else{
            @_ = (caller 0)[3];
        }
    }

    push @_, ' is not implemented';
    goto &Carp::confess;
}


sub call_sv{ # perl.h
    my($sv, $flags) = @_;

    if($flags & G_DISCARD){
        ENTER;
        SAVETMPS;
    }

    my $cv = $sv->toCV();

    my $old_op  = $PL_op;
    my $old_cop = $PL_curcop;

    $PL_op = Acme::Perl::VM::OP_CallSV->new(
        cv    => $cv,
        next  => NULL,
        flags => OP_GIMME_REVERSE($flags),
    );
    $PL_curcop = $PL_op;

    PUSH($cv);
    my $oldmark  = TOPMARK;

    $PL_runops->();

    my $retval = $#PL_stack - $oldmark;

    if($flags & G_DISCARD){
        $#PL_stack = $oldmark;
        $retval = 0;
        FREETMPS;
        LEAVE;
    }

    $PL_op     = $old_op;
    $PL_curcop = $old_cop;

    return $retval;
}

sub run_block(&@){
    my($code, @args) = @_;

    if(APVM_DUMMY){
        return $code->(@args);
    }
    local $SIG{__DIE__}  = \&Carp::confess if APVM_DEBUG;
    local $SIG{__WARN__} = \&Carp::cluck   if APVM_DEBUG;

    ENTER;
    SAVETMPS;

    PUSHMARK;
    PUSH(@args);

    my $gimme  = want2gimme(wantarray);
    my $mark   = $#PL_stack - call_sv(B::svref_2object($code), $gimme);
    my @retval = mark_list($mark);

    FREETMPS;
    LEAVE;

    if($gimme == G_SCALAR){
        return $retval[-1];
    }
    elsif($gimme == G_ARRAY){
        return @retval;
    }

    return;
}

package
    Acme::Perl::VM::OP_CallSV;

use Mouse;

has cv => (
    is  => 'ro',
    isa => 'B::CV',

    required => 1,
);

has next => (
    is  => 'ro',
    isa => 'B::OBJECT',

    required => 1,
);

has flags => (
    is  => 'ro',
    isa => 'Int',

    required => 1,
);

use constant {
    class => 'OP',
    type  => B::opnumber('entersub'),
    name  => 'entersub',
    desc  => 'subroutine entry',

    file  => __FILE__,
    line  => 0,
};

sub isa{
    shift;
    return B::COP->isa(@_);
}

no Mouse;
__PACKAGE__->meta->make_immutable();

package
    Acme::Perl::VM::Alias;


sub TIESCALAR{
    my($class, $scalar_ref) = @_;
    return bless [$scalar_ref], $class;
}
sub FETCH{
    return ${ $_[0]->[0] }
}
sub STORE{
    ${ $_[0]->[0] } = $_[1];
    return;
}


1;
__END__

=head1 NAME

Acme::Perl::VM - A Perl5 Virtual Machine in Pure Perl (APVM)

=head1 VERSION

This document describes Acme::Perl::VM version 0.006.

=head1 SYNOPSIS

    use Acme::Perl::VM;

    run_block{
        print "Hello, APVM world!\n",
    };

=head1 DESCRIPTION

C<Acme::Perl::VM> is an implementation of Perl5 virtual machine in pure Perl.

Perl provides a feature to access compiled syntax trees (B<opcodes>) by
C<B> module. C<B::*> modules walk into opcodes and do various things;
C<B::Deparse> retrieves Perl source code from subroutine references,
C<B::Concise> reports formatted syntax trees, and so on.

This module also walks into the opcodes, and executes them with its
own B<ppcodes>.

You can run any Perl code:

    use Acme::Perl::VM;

    run_block {
        print "Hello, APVM world!\n";
    };

This code says B<Hello, APVM world> to C<stdout> as you expect.

Here is a more interesting example:

    BEGIN{ $ENV{APVM} = 'trace' }
    use Acme::Perl::VM;

    run_block {
        print "Hello, APVM world!\n";
    };

And you'll get a list of opcodes as the code runs:

    .entersub(&__ANON__) VOID
    .nextstate(main -:4) VOID
    .pushmark SCALAR
    .const("Hello, APVM world!\n") SCALAR
    .print SCALAR KIDS
    Hello, APVM world!
    .leavesub KIDS

The first C<entersub> is the start of the block. The next C<nextstate>
indicates the statement that says hello. C<pushmark>, C<const>, and
C<print> are opcodes which runs on the statement. The last C<leavesub> is
the end of the block. This is a future of the module.

In short, the module has no purpose :)

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 SEE ALSO

L<perlapi>.

L<perlhack>.

F<pp.h> for PUSH/POP macros.

F<pp.c>, F<pp_ctl.c>, and F<pp_hot.c> for ppcodes.

F<op.h> for opcodes.

F<cop.h> for COP and context blocks.

F<scope.h> and F<scope.c> for scope stacks.

F<pad.h> and F<pad.c> for pad variables.

F<run.c> for runops.

L<B>.

L<B::Concise>.

L<Devel::Optrace>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
