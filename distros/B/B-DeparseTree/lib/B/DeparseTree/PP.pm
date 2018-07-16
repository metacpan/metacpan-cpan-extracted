# Copyright (c) 2015, 2018 Rocky Bernstein

# Common PP (push-pull) opcodes methods. Most of these are called
# from the method dispatch in Common.
#
# Specifc Perl versions can override these.  Note some PP opcodes are
# handled via table lookup to their underlying base-handling function,
# e.g. binop, listop, unop, ....

use strict;
use warnings ();
require feature;

my %feature_keywords = (
  # keyword => 'feature',
    state   => 'state',
    say     => 'say',
    given   => 'switch',
    when    => 'switch',
    default => 'switch',
    break   => 'switch',
    evalbytes=>'evalbytes',
    __SUB__ => '__SUB__',
   fc       => 'fc',
);

use rlib '../..';

package B::DeparseTree::PP;

use B::DeparseTree::SyntaxTree;
use B::DeparseTree::OPflags;
use B::DeparseTree::PPfns;
use B::DeparseTree::TreeNode;
use B::Deparse;
our($VERSION, @EXPORT, @ISA);
$VERSION = '3.2.0';

@ISA = qw(Exporter B::Deparse );

# Copy unchanged functions from B::Deparse
*lex_in_scope = *B::Deparse::lex_in_scope;
*gv_or_padgv = *B::Deparse::gv_or_padgv;
*padany = *B::Deparse::padany;
*padname = *B::Deparse::padname;
*pp_anonhash = *B::Deparse::pp_anonhash;
*pp_anonlist = *B::Deparse::pp_anonlist;
*pp_i_negate = *B::Deparse::pp_i_negate;
*pp_negate = *B::Deparse::pp_negate;
*real_negate = *B::Deparse::real_negate;
use B qw(
    OPf_MOD OPpENTERSUB_AMPER
    OPf_SPECIAL
    OPf_STACKED
    OPpEXISTS_SUB
    OPpTRANS_COMPLEMENT
    OPpTRANS_DELETE
    OPpTRANS_SQUASH
    SVf_POK
    SVf_ROK
    class
    opnumber
);

@EXPORT = qw(
    feature_enabled
    gv_or_padgv
    pp_aelem
    pp_aelemfast
    pp_aelemfast_lex
    pp_and
    pp_anonhash
    pp_anonlist
    pp_aslice
    pp_avalues
    pp_backtick
    pp_boolkeys
    pp_clonecv
    pp_cmp
    pp_cond_expr
    pp_connect
    pp_const
    pp_delete
    pp_dofile
    pp_entereval
    pp_entersub
    pp_eq
    pp_exec
    pp_exists
    pp_exp
    pp_flop
    pp_ge
    pp_gelem
    pp_glob
    pp_gt
    pp_gv
    pp_gvsv
    pp_helem
    pp_hslice
    pp_i_cmp
    pp_i_eq
    pp_i_ge
    pp_i_gt
    pp_i_le
    pp_i_lt
    pp_i_ne
    pp_i_negate
    pp_introcv
    pp_kvaslice
    pp_kvhslice
    pp_le
    pp_leave
    pp_leavegiven
    pp_leaveloop
    pp_leavetry
    pp_leavewhen
    pp_lineseq
    pp_list
    pp_lslice
    pp_lt
    pp_mapstart
    pp_ne
    pp_negate
    pp_not
    pp_null
    pp_once
    pp_open_dir
    pp_or
    pp_padcv
    pp_pos
    pp_preinc
    pp_print
    pp_prtf
    pp_pushre
    pp_qr
    pp_rcatline
    pp_readline
    pp_refgen
    pp_require
    pp_rv2cv
    pp_sassign
    pp_scalar
    pp_scmp
    pp_scope
    pp_seq
    pp_sge
    pp_sgt
    pp_sle
    pp_slt
    pp_sne
    pp_sockpair
    pp_split
    pp_smartmatch
    pp_stringify
    pp_stub
    pp_subst
    pp_substr
    pp_trans
    pp_transr
    pp_truncate
    pp_unstack
    pp_values
    pp_vec
    pp_waitpid
    pp_xor
    );

BEGIN {
    # List version-specific constants here.
    # Easiest way to keep this code portable between version looks to
    # be to fake up a dummy constant that will never actually be true.
    foreach (qw(OPpCONST_ARYBASE OPpEVAL_BYTES)) {
	eval { import B $_ };
	no strict 'refs';
	*{$_} = sub () {0} unless *{$_}{CODE};
    }
}

BEGIN { for (qw[ const stringify rv2sv list glob pushmark null aelem
		 nextstate dbstate rv2av rv2hv helem custom ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

sub feature_enabled {
	my($self,$name) = @_;
	my $hh;
	my $hints = $self->{hints} & $feature::hint_mask;
	if ($hints && $hints != $feature::hint_mask) {
	    $hh = B::Deparse::_features_from_bundle($hints);
	}
	elsif ($hints) { $hh = $self->{'hinthash'} }
	return $hh && $hh->{"feature_$feature_keywords{$name}"}
}

# FIXME: These don't seem to be able to go into the table.
# PPfns calls pp_sockpair for example?
sub pp_avalues  { unop(@_, "values") }
sub pp_exec     { maybe_targmy(@_, \&listop, "exec") }
sub pp_exp      { maybe_targmy(@_, \&unop, "exp") }
sub pp_leave    { scopeop(1, @_); }
sub pp_lineseq  { scopeop(0, @_); }
sub pp_or       { logop(@_, "or",  2, "||", 10, "unless") }
sub pp_preinc   { pfixop(@_, "++", 23) }
sub pp_print    { indirop(@_, "print") }
sub pp_prtf     { indirop(@_, "printf") }
sub pp_sockpair { listop(@_, "socketpair") }
sub pp_values   { unop(@_, "values") }
sub pp_pushre   { matchop(@_, "m", "/") }  # Is also in OP_PP table
sub pp_qr       { matchop(@_, "qr", "") }  # Is also in OP_PP table

# Convert these to table entries...
sub pp_aelem { maybe_local(@_, elem(@_, "[", "]", "padav")) }
sub pp_aslice   { maybe_local(@_, slice(@_, "[", "]", "rv2av", "padav")) }
sub pp_cmp { binop(@_, "<=>", 14) }
sub pp_eq { binop(@_, "==", 14) }
sub pp_ge { binop(@_, ">=", 15) }
sub pp_gt { binop(@_, ">", 15) }
sub pp_helem { maybe_local(@_, elem(@_, "{", "}", "padhv")) }
sub pp_hslice   { maybe_local(@_, slice(@_, "{", "}", "rv2hv", "padhv")) }
sub pp_i_cmp { maybe_targmy(@_, \&binop, "<=>", 14) }
sub pp_i_eq { binop(@_, "==", 14) }
sub pp_i_ge { binop(@_, ">=", 15) }
sub pp_i_gt { binop(@_, ">", 15) }
sub pp_i_le { binop(@_, "<=", 15) }
sub pp_i_lt { binop(@_, "<", 15) }
sub pp_i_ne { binop(@_, "!=", 14) }
sub pp_kvaslice { slice(@_, "[", "]", "rv2av", "padav")  }
sub pp_kvhslice { slice(@_, "{", "}", "rv2hv", "padhv")  }
sub pp_le { binop(@_, "<=", 15) }
sub pp_lt { binop(@_, "<", 15) }
sub pp_ne { binop(@_, "!=", 14) }

sub pp_sassign { binop(@_, "=", 7, SWAP_CHILDREN) }
sub pp_scmp { binop(@_, "cmp", 14) }
sub pp_seq { binop(@_, "eq", 14) }
sub pp_sge { binop(@_, "ge", 15) }
sub pp_sgt { binop(@_, "gt", 15) }
sub pp_sle { binop(@_, "le", 15) }
sub pp_slt { binop(@_, "lt", 15) }
sub pp_sne { binop(@_, "ne", 14) }

sub pp_aelemfast
{
    my($self, $op, $cx) = @_;
    # optimised PADAV, pre 5.15
    return $self->pp_aelemfast_lex(@_) if ($op->flags & OPf_SPECIAL);

    my $gv = $self->gv_or_padgv($op);
    my($name,$quoted) = $self->stash_variable_name('@',$gv);
    $name = $quoted ? "$name->" : '$' . $name;
    my $i = $op->private;
    $i -= 256 if $i > 127;
    return info_from_list($op, $self, [$name, "[", ($op->private + $self->{'arybase'}), "]"],
		      '', 'pp_aelemfast', {});
}

sub pp_aelemfast_lex
{
    my($self, $op, $cx) = @_;
    my $name = $self->padname($op->targ);
    $name =~ s/^@/\$/;
    return info_from_list($op, $self, [$name, "[", ($op->private + $self->{'arybase'}), "]"],
		      '', 'pp_aelemfast_lex', {});
}

sub pp_backtick
{
    my($self, $op, $cx) = @_;
    # skip pushmark if it exists (readpipe() vs ``)
    my $child = $op->first->sibling->isa('B::NULL')
	? $op->first : $op->first->sibling;
    if ($self->pure_string($child)) {
	return $self->single_delim($op, "qx", '`', $self->dq($child, 1)->{text});
    }
    unop($self, $op, $cx, "readpipe");
}

sub pp_boolkeys
{
    # no name because its an optimisation op that has no keyword
    unop(@_,"");
}

sub pp_dofile
{
    my $code = unop(@_, "do", 1); # llafr does not apply
    if ($code =~ s/^((?:CORE::)?do) \{/$1({/) { $code .= ')' }
    $code;
}

sub pp_gelem
{
    my($self, $op, $cx) = @_;
    my($rv2gv, $part) = ($op->first, $op->last);
    my $glob = $rv2gv->first; # skip rv2gv
    $glob = $glob->first if $glob->name eq "rv2gv"; # this one's a bug
    my $scope = B::Deparse::is_scope($glob);
    my $glob_node = $self->deparse($glob, 0);
    my $part_node = $self->deparse($part, 1);
    my $fmt = ($scope ? '*{%c}{%c}' : '*%c{%c}');
    # FIXME: fill in $rv2gv and possibly other node skipped above.
    return $self->info_from_template("gelem *", $fmt, undef,
				     [$glob_node, $part_node],
				     {other_ops => [$rv2gv]});
}

sub pp_leavegiven { givwhen(@_, $_[0]->keyword("given")); }
sub pp_leavewhen  { givwhen(@_, $_[0]->keyword("when")); }

sub pp_lslice
{
    my ($self, $op, $cs) = @_;
    my $idx = $op->first;
    my $list = $op->last;
    my(@elems, $kid);
    my $list_info = $self->deparse($list, 1, $op);
    my $idx_info = $self->deparse($idx, 1, $op);
    return $self->info_from_template('lslice ()[]',
				     $op, '(%c)[%c]', undef,
				     [$list_info, $idx_info]);
}

sub pp_pos { maybe_local(@_, unop(@_, "pos")) }

sub pp_not
{
    my($self, $op, $cx) = @_;
    if ($cx <= 4) {
	$self->listop($op, $cx, "not", $op->first);
    } else {
	$self->pfixop($op, $cx, "!", 21);
    }
}


# skip down to the old, ex-rv2cv
sub pp_rv2cv {
    my ($self, $op, $cx) = @_;
    if (!B::Deparse::null($op->first) && $op->first->name eq 'null' &&
	$op->first->targ == OP_LIST)
    {
	return $self->rv2x($op->first->first->sibling, $cx, "&")
    }
    else {
	return $self->rv2x($op, $cx, "")
    }
}


sub pp_scalar
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    if (not B::Deparse::null $kid->sibling) {
	# XXX Was a here-doc
	return $self->dquote($op);
    }
    $self->unop($op, $cx, "scalar");
}

sub pp_smartmatch {
    my ($self, $op, $cx) = @_;
    if ($op->flags & OPf_SPECIAL) {
	my $child = $self->deparse($op->last, $cx, $op);
	return $self->info_from_template('~~ special',
					 '%c', undef, [$child]);
    } else {
	binop(@_, "~~", 14);
    }
}

# Truncate is special because OPf_SPECIAL makes a bareword first arg
# be a filehandle. This could probably be better fixed in the core
# by moving the GV lookup into ck_truc.

sub pp_truncate
{
    my($self, $op, $cx) = @_;
    my(@exprs);
    my $parens = ($cx >= 5) || $self->{'parens'};
    my $opts = {'other_ops' => [$op->first]};
    my $kid = $op->first->sibling;
    my $fh;
    if ($op->flags & B::OPf_SPECIAL) {
	# $kid is an OP_CONST
	$fh = $self->const_sv($kid)->PV;
    } else {
	$fh = $self->deparse($kid, 6, $op);
        $fh = "+$fh" if not $parens and substr($fh, 0, 1) eq "(";
    }
    my $len = $self->deparse($kid->sibling, 6, $op);
    my $name = $self->keyword('truncate');
    my $args = "$fh->{text}, $len->{text}";
    if ($parens) {
	return info_from_list($op, $self, [$name, '(', $args, ')'], '',
			      'truncate_parens', $opts);
    } else {
	return info_from_list($op, $self, [$name, $args], '', 'truncate', $opts);
    }
}

sub pp_vec { maybe_local(@_, listop(@_, "vec")) }

sub pp_glob
{
    my($self, $op, $cx) = @_;

    my $opts = {other_ops => [$op->first]};
    my $kid = $op->first->sibling;  # skip pushmark
    my $keyword =
	$op->flags & OPf_SPECIAL ? 'glob' : $self->keyword('glob');

    if ($keyword =~ /^CORE::/ or $kid->name ne 'const') {
	my $kid_info = $self->dq($kid, $op);
	my $body = [$kid_info];
	my $text = $kid_info->{text};
	if ($text =~ /^\$?(\w|::|\`)+$/ # could look like a readline
	    or $text =~ /[<>]/) {
	    $kid_info = $self->deparse($kid, 0, $op);
	    $body = [$kid_info];
	    $text = $kid_info->{text};
	    $opts->{body} = $body;
	    if ($cx >= 5 || $self->{'parens'}) {
		# FIXME: turn into template
		return info_from_list($op, $self, [$keyword, '(', $text, ')'], '',
				      'glob_paren', $opts);
	    } else {
		# FIXME: turn into template
		return info_from_list($op, $self, [$keyword, $text], ' ',
				      'glob_space', $opts);
	    }
	} else {
	    return $self->info_from_template('<FH>', $op, '<%c>', undef,
					     [$kid_info], $opts);
	}
    }
    return $self->info_from_string("<>", $op, $opts);
}

sub pp_clonecv {
    my $self = shift;
    my($op, $cx) = @_;
    my $sv = $self->padname_sv($op->targ);
    my $name = substr $sv->PVX, 1; # skip &/$/@/%, like $self->padany
    return $self->info_from_string("clonev my sub",  $op, "my sub  $name");
}

sub pp_delete($$$)
{
    my($self, $op, $cx) = @_;
    my $arg;
    my ($info, $body, $type);
    if ($op->private & B::OPpSLICE) {
	if ($op->flags & B::OPf_SPECIAL) {
	    # Deleting from an array, not a hash
	    $info = $self->pp_aslice($op->first, 16);
	    $type = 'delete slice';
	}
    } else {
	if ($op->flags & B::OPf_SPECIAL) {
	    # Deleting from an array, not a hash
	    $info = $self->pp_aelem($op->first, 16);
	    $type = 'delete array'
	} else {
	    $info = $self->pp_helem($op->first, 16);
	    $type = 'delete hash';
	}
    }
    my @texts = $self->maybe_parens_func("delete",
					 $info->{text}, $cx, 16);
    return info_from_list($op, $self, \@texts, '', $type, {body => [$info]});
}

sub pp_exists
{
    my($self, $op, $cx) = @_;
    my ($info, $type);
    my $name = $self->keyword("exists");
    if ($op->private & OPpEXISTS_SUB) {
	# Checking for the existence of a subroutine
	$info = $self->pp_rv2cv($op->first, 16);
	$type = 'exists sub';
    } elsif ($op->flags & OPf_SPECIAL) {
	# Array element, not hash helement
	$info = $self->pp_aelem($op->first, 16);
	$type = 'exists array';
    } else {
	$info = $self->pp_helem($op->first, 16);
	$type = 'exists hash';
    }
    my @texts = $self->maybe_parens_func($name, $info->{text}, $cx, 16);
    return info_from_list($op, $self, \@texts, '', $type, {});
}

sub pp_introcv
{
    my($self, $op, $cx) = @_;
    # For now, deparsing doesn't worry about the distinction between introcv
    # and clonecv, so pretend this op doesn't exist:
    return info_from_text($op, $self, '', 'introcv', {});
}

sub pp_leaveloop { shift->loop_common(@_, undef); }

sub pp_leavetry {
    my ($self, $op, $cx) = @_;
    my $leave_info = $self->pp_leave($op, $cx);
    return $self->info_from_template('eval {}', $op, "eval {\n%+%c\n%-}",
				     undef, [$leave_info]);
}

sub pp_list
{
    my($self, $op, $cx) = @_;
    my($expr, @exprs);

    my $pushmark_op = $op->first;
    my $kid = $pushmark_op->sibling; # skip a pushmark
    my @other_ops = ($pushmark_op);

    if (class($kid) eq 'NULL') {
	return $self->info_from_string("list ''", $op, '', {other_ops => \@other_ops});
    }
    my $lop;
    my $local = "either"; # could be local(...), my(...), state(...) or our(...)
    for ($lop = $kid; !B::Deparse::null($lop); $lop = $lop->sibling) {
	# This assumes that no other private flags equal 128, and that
	# OPs that store things other than flags in their op_private,
	# like OP_AELEMFAST, won't be immediate children of a list.
	#
	# OP_ENTERSUB and OP_SPLIT can break this logic, so check for them.
	# I suspect that open and exit can too.
	# XXX This really needs to be rewritten to accept only those ops
	#     known to take the OPpLVAL_INTRO flag.

	if (!($lop->private & (B::Deparse::OPpLVAL_INTRO|B::Deparse::OPpOUR_INTRO)
		or $lop->name eq "undef")
	    or $lop->name =~ /^(?:entersub|exit|open|split)\z/)
	{
	    $local = ""; # or not
	    last;
	}
	if ($lop->name =~ /^pad[ash]v$/) {
	    if ($lop->private & B::Deparse::OPpPAD_STATE) { # state()
		($local = "", last) if $local =~ /^(?:local|our|my)$/;
		$local = "state";
	    } else { # my()
		($local = "", last) if $local =~ /^(?:local|our|state)$/;
		$local = "my";
	    }
	} elsif ($lop->name =~ /^(gv|rv2)[ash]v$/
			&& $lop->private & B::Deparse::OPpOUR_INTRO
		or $lop->name eq "null" && $lop->first->name eq "gvsv"
			&& $lop->first->private & B::Deparse::OPpOUR_INTRO) { # our()
	    ($local = "", last) if $local =~ /^(?:my|local|state)$/;
	    $local = "our";
	} elsif ($lop->name ne "undef"
		# specifically avoid the "reverse sort" optimisation,
		# where "reverse" is nullified
		&& !($lop->name eq 'sort' && ($lop->flags & B::Deparse::OPpSORT_REVERSE)))
	{
	    # local()
	    ($local = "", last) if $local =~ /^(?:my|our|state)$/;
	    $local = "local";
	}
    }
    $local = "" if $local eq "either"; # no point if it's all undefs
    if (B::Deparse::null $kid->sibling and not $local) {
	my $info = $self->deparse($kid, $cx, $op);
	$info->update_other_ops($pushmark_op);
	return $info;
    }

    for (; !B::Deparse::null($kid); $kid = $kid->sibling) {
	if ($local) {
	    if (class($kid) eq "UNOP" and $kid->first->name eq "gvsv") {
		push @other_ops, $kid;
		$lop = $kid->first;
	    } else {
		$lop = $kid;
	    }
	    $self->{'avoid_local'}{$$lop}++;
	    $expr = $self->deparse($kid, 6, $op);
	    delete $self->{'avoid_local'}{$$lop};
	} else {
	    $expr = $self->deparse($kid, 6, $op);
	}
	push @exprs, $expr;
    }

    if ($local) {
	return $self->info_from_template("$local ()", $op,
					 "$local(%C)", [[0, $#exprs, ', ']],
					 \@exprs, {other_ops => \@other_ops});

    } else {
	return $self->info_from_template("list", $op,
					 "%C", [[0, $#exprs, ', ']],
					 \@exprs,
					 {maybe_parens => [$self, $cx, 6],
					 other_ops => \@other_ops});
    }
}

sub pp_padcv($$$) {
    my($self, $op, $cx) = @_;
    return info_from_text($op, $self, $self->padany($op), 'padcv', {});
}

sub pp_refgen
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    if ($kid->name eq "null") {
	my $other_ops = [$kid];
	my $anoncode = $kid = $kid->first;
	if ($anoncode->name eq "anonconst") {
	    $anoncode = $anoncode->first->first->sibling;
	}
	if ($anoncode->name eq "anoncode"
	 or !B::Deparse::null($anoncode = $kid->sibling) and
		 $anoncode->name eq "anoncode") {
            return $self->e_anoncode({ code => $self->padval($anoncode->targ) });
	} elsif ($kid->name eq "pushmark") {
            my $sib_name = $kid->sibling->name;
            if ($sib_name =~ /^enter(xs)?sub/) {
                my $kid_info = $self->deparse($kid->sibling, 1, $op);
                # Always show parens for \(&func()), but only with -p otherwise
		my @texts = ('\\', $kid_info->{text});
		if ($self->{'parens'} or $kid->sibling->private & OPpENTERSUB_AMPER) {
		    @texts = ('(', "\\", $kid_info->{text}, ')');
		}
		return info_from_list($op, $self, \@texts, '', 'refgen_entersub',
				      {body => [$kid_info],
				       other_ops => $other_ops});
            }
        }
    }
    local $self->{'in_refgen'} = 1;
    $self->pfixop($op, $cx, "\\", 20);
}

sub pp_require
{
    my($self, $op, $cx) = @_;
    my $opname = $op->flags & OPf_SPECIAL ? 'CORE::require' : 'require';
    if (class($op) eq "UNOP" and $op->first->name eq "const"
	and $op->first->private & B::OPpCONST_BARE) {
	my $name = $self->const_sv($op->first)->PV;
	$name =~ s[/][::]g;
	$name =~ s/\.pm//g;
	return info_from_list($op, $self, [$opname, $name], ' ',
			      'require',
			      {maybe_parens => [$self, $cx, 16]});
    } else {
	return $self->unop(
	    $op, $cx,
	    $op->first->name eq 'const'
	    && $op->first->private & B::OPpCONST_NOVER
	    ? "no"
	    : $opname,
	    1, # llafr does not apply
	    );
    }
    Carp::confess("unhandled condition in pp_require");
}


sub pp_scope { scopeop(0, @_); }
sub pp_and { logop(@_, "and", 3, "&&", 11, "if") }

sub pp_cond_expr
{
    my $self = shift;
    my($op, $cx) = @_;
    my $cond = $op->first;
    my $true = $cond->sibling;
    my $false = $true->sibling;
    my $cuddle = $self->{'cuddle'};
    my $type = 'if';
    unless ($cx < 1 and (B::Deparse::is_scope($true) and $true->name ne "null") and
	    (B::Deparse::is_scope($false) || B::Deparse::is_ifelse_cont($false))
	    and $self->{'expand'} < 7) {
	# FIXME: turn into template
	my $cond_info = $self->deparse($cond, 8, $op);
	my $true_info = $self->deparse($true, 6, $op);
	my $false_info = $self->deparse($false, 8, $op);
	return $self->info_from_template('ternary ?', $op, "%c ? %c : %c",
					 [0, 1, 2],
					 [$cond_info, $true_info, $false_info],
					 {maybe_parens => [$self, $cx, 8]});
    }

    my $cond_info = $self->deparse($cond, 1, $op);
    my $true_info = $self->deparse($true, 0, $op);
    my $fmt = "%|if (%c) {\n%+%c\n%-}";
    my @exprs = ($cond_info, $true_info);
    my @args_spec = (0, 1);

    my $i;
    for ($i=0; !B::Deparse::null($false) and B::Deparse::is_ifelse_cont($false); $i++) {
	my $newop = $false->first;
	my $newcond = $newop->first;
	my $newtrue = $newcond->sibling;
	$false = $newtrue->sibling; # last in chain is OP_AND => no else
	if ($newcond->name eq "lineseq")
	{
	    # lineseq to ensure correct line numbers in elsif()
	    # Bug #37302 fixed by change #33710.
	    $newcond = $newcond->first->sibling;
	}
	my $newcond_info = $self->deparse($newcond, 1, $op);
	my $newtrue_info = $self->deparse($newtrue, 0, $op);
	push @args_spec, scalar(@args_spec), scalar(@args_spec)+1;
	push @exprs, $newcond_info, $newtrue_info;
	$fmt .= " elsif ( %c ) {\n%+%c\n\%-}";
    }
    $type .= " elsif($i)" if $i;
    my $false_info;
    if (!B::Deparse::null($false)) {
	$false_info = $self->deparse($false, 0, $op);
	$fmt .= "${cuddle}else {\n%+%c\n%-}";
	push @args_spec, scalar(@args_spec);
	push @exprs, $false_info;
	$type .= ' else';
    }
    return $self->info_from_template($type, $op, $fmt, \@args_spec, \@exprs);
}

sub pp_const {
    my $self = shift;
    my($op, $cx) = @_;
    if ($op->private & OPpCONST_ARYBASE) {
        return $self->info_from_string('const $[', $op, '$[');
    }
    # if ($op->private & OPpCONST_BARE) { # trouble with '=>' autoquoting
    # 	return $self->const_sv($op)->PV;
    # }
    my $sv = $self->const_sv($op);
    return $self->const($sv, $cx);;
}

# Handle subroutine calls. These are a bit complicated.
# NOTE: this is not right for CPerl, so it needs to be split out.
sub pp_entersub
{
    my($self, $op, $cx) = @_;
    return $self->e_method($op, $self->_method($op, $cx))
        unless B::Deparse::null $op->first->sibling;
    my $prefix = "";
    my $amper = "";
    my($kid, @exprs, @args_spec);
    if ($op->flags & OPf_SPECIAL && !($op->flags & OPf_MOD)) {
	$prefix = "do ";
    } elsif ($op->private & OPpENTERSUB_AMPER) {
	$amper = "&";
    }

    $kid = $op->first;

    my $other_ops = [$kid, $kid->first];
    $kid = $kid->first->sibling; # skip ex-list, pushmark

    my $kid_start = $kid;
    # FIXME: phase this out.
    for (; not B::Deparse::null $kid->sibling; $kid = $kid->sibling) {
	push @exprs, $kid;
    }
    my ($simple, $proto, $subname_info) = (0, undef, undef);
    if (B::Deparse::is_scope($kid)) {
	$amper = "&";
	$subname_info = $self->deparse($kid, 0, $op);
	$subname_info->{texts} = ['{', $subname_info->texts, '}'];
	$subname_info->{text} = join('', @$subname_info->{texts});
    } elsif ($kid->first->name eq "gv") {
	my $gv = $self->gv_or_padgv($kid->first);
	my $cv;
	if (class($gv) eq 'GV' && class($cv = $gv->CV) ne "SPECIAL"
	 || $gv->FLAGS & SVf_ROK && class($cv = $gv->RV) eq 'CV') {
	    $proto = $cv->PV if $cv->FLAGS & SVf_POK;
	}
	$simple = 1; # only calls of named functions can be prototyped
	$subname_info = $self->deparse($kid, 24, $op);
	my $fq;
	# Fully qualify any sub name that conflicts with a lexical.
	if ($self->lex_in_scope("&$kid")
	 || $self->lex_in_scope("&$kid", 1))
	{
	    $fq++;
	} elsif (!$amper) {
	    if ($subname_info->{text} eq 'main::') {
		$subname_info->{text} = '::';
	    } else {
	      if ($kid !~ /::/ && $kid ne 'x') {
		# Fully qualify any sub name that is also a keyword.  While
		# we could check the import flag, we cannot guarantee that
		# the code deparsed so far would set that flag, so we qual-
		# ify the names regardless of importation.
		if (exists $feature_keywords{$kid}) {
		    $fq++ if $self->feature_enabled($kid);
		} elsif (do { local $@; local $SIG{__DIE__};
			      eval { () = prototype "CORE::$kid"; 1 } }) {
		    $fq++
		}
	      }
	    }
	    if ($subname_info->{text} !~ /^(?:\w|::)(?:[\w\d]|::(?!\z))*\z/) {
		$subname_info->{text} = $self->single_delim($$kid, "q", "'", $kid) . '->';
	    }
	}
    } elsif (B::Deparse::is_scalar ($kid->first) && $kid->first->name ne 'rv2cv') {
	$amper = "&";
	$subname_info = $self->deparse($kid, 24, $op);
    } else {
	$prefix = "";
	my $arrow = B::Deparse::is_subscriptable($kid->first)
	    || $kid->first->name eq "padcv" ? "" : "->";
	$subname_info = $self->deparse($kid, 24, $op);
	$subname_info->{text} .= $arrow;
    }

    # Doesn't matter how many prototypes there are, if
    # they haven't happened yet!
    my $declared;
    my $sub_name = $subname_info->{text};
    {
	no strict 'refs';
	no warnings 'uninitialized';
	$declared = exists $self->{'subs_declared'}{$sub_name}
	    || (
		 defined &{ ${$self->{'curstash'}."::"}{$sub_name} }
		 && !exists
		     $self->{'subs_deparsed'}{$self->{'curstash'}."::" . $sub_name}
		 && defined prototype $self->{'curstash'}."::" . $sub_name
	       );
	if (!$declared && defined($proto)) {
	    # Avoid "too early to check prototype" warning
	    ($amper, $proto) = ('&');
	}
    }

    my (@texts, @nodes, $type);
    @nodes = ();
    if ($declared and defined $proto and not $amper) {
	my $args;
	($amper, $args) = $self->check_proto($op, $proto, @exprs);
	if ($amper eq "&") {
	    $self->deparse_op_siblings(\@nodes, $kid_start, $op, 6);
	} else {
	    @nodes = @$args if @$args;
	}
    } else {
	$self->deparse_op_siblings(\@nodes, $kid_start, $op, 6);
	@nodes  = map($self->deparse($_, 6, $op), @exprs);
    }

    if ($prefix or $amper) {
	if ($sub_name eq '&') {
	    # &{&} cannot be written as &&
	    $subname_info->{texts} = ["{", @{$subname_info->{texts}}, "}"];
	    $subname_info->{text} = join('', $subname_info->{texts});
	}
	if ($op->flags & OPf_STACKED) {
	    $type = "$prefix$amper call()";
	    @texts = ($prefix, $amper, $subname_info, "(", $self->combine2str(', ', \@nodes), ")");
	} else {
	    $type = "$prefix$amper call";
	    @texts = ($prefix, $amper, $subname_info);
	}
    } else {
	# It's a syntax error to call CORE::GLOBAL::foo with a prefix,
	# so it must have been translated from a keyword call. Translate
	# it back.
	$subname_info->{text} =~ s/^CORE::GLOBAL:://;
	my $dproto = defined($proto) ? $proto : "undefined";
        if (!$declared) {
	    $type = 'call (fn without prototype)';
	    my ($fmt, $args_spec);
	    my $first_param_text = (@nodes > 0) ? $nodes[0]->{text} : '';
	    unshift @nodes, $subname_info;
	    if ($self->dedup_func_parens(\@nodes)) {
		$fmt = "%c %c";
		$args_spec = undef;
	    } else {
		$fmt = "%c(%C)";
		$args_spec = [0, [1, $#nodes, ', ']];
	    }
	    my $node = $self->info_from_template($type, $op, $fmt, $args_spec,
						 \@nodes,
						 {other_ops => $other_ops});


	    # Take the subname_info portion of $node and use that as the
	    # part of the parent, null, pushmark ops.
	    if ($subname_info && $other_ops) {
		my $str = $node->{text};
		my $position = [0, length($subname_info->{text})];
		my @new_ops = ();
		foreach my $skipped_op (@$other_ops) {
		    my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
							 {position => $position});
		    push @new_ops, $new_op;
		}
		$node->{other_ops} = \@new_ops;
	    }
	    return $node;

	} elsif ($dproto =~ /^\s*\z/) {
	    $type = 'call no protype';
	    @texts = ($subname_info);
	} elsif ($dproto eq "\$" and B::Deparse::is_scalar($exprs[0])) {
	    $type = 'call - $ prototype';
	    # is_scalar is an excessively conservative test here:
	    # really, we should be comparing to the precedence of the
	    # top operator of $exprs[0] (ala unop()), but that would
	    # take some major code restructuring to do right.
	    @texts = $self->maybe_parens_func($sub_name,
					      $self->combine2str(', ', \@nodes), $cx, 16);
	} elsif ($dproto ne '$' and defined($proto) || $simple) { #'
	    $type = "call $sub_name having prototype";
	    @texts = $self->maybe_parens_func($sub_name,
					      $self->combine2str(', ', \@nodes), $cx, 5);
	    return B::DeparseTree::TreeNode->new($op, $self, \@texts,
						 '', $type,
						 {other_ops => $other_ops});
	} else {
	    $type = 'call';
	    @texts = dedup_parens_func($self, $subname_info, \@nodes);
	    return B::DeparseTree::TreeNode->new($op, $self, \@texts,
						 '', $type,
						 {other_ops => $other_ops});
	}
    }
    my $node = $self->info_from_template($type, $op,
					 '%C', [[0, $#texts, '']], \@texts,
					 {other_ops => $other_ops});

    # Take the subname_info portion of $node and use that as the
    # part of the parent, null, pushmark ops.
    if ($subname_info && $other_ops) {
	my $str = $node->{text};
	my $position = [0, length($subname_info->{text})];
	my @new_ops = ();
	foreach my $skipped_op (@$other_ops) {
	    my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
						 {position => $position});
	    push @new_ops, $new_op;
	}
	$node->{other_ops} = \@new_ops;
    }
    return $node;
}

sub pp_entereval {
    unop(
      @_,
      $_[1]->private & OPpEVAL_BYTES ? 'evalbytes' : "eval"
    )
}

sub pp_flop
{
    my $self = shift;
    my($op, $cx) = @_;
    my $flip = $op->first;
    my $type = ($flip->flags & OPf_SPECIAL) ? "..." : "..";
    my $node =$self->range($flip->first, $cx, $type);
    return $self->info_from_template("pp_flop $type", $op, "%c", undef, [$node], {});
}

sub pp_gv
{
    my($self, $op, $cx) = @_;
    my $gv = $self->gv_or_padgv($op);
    my $name = $self->gv_name($gv);
    return $self->info_from_string("global variable $name", $op, $name);
}

# FIXME: adjust use of maybe_local_str
sub pp_gvsv
{
    my($self, $op, $cx) = @_;
    my $gv = $self->gv_or_padgv($op);
    return $self->maybe_local_str($op, $cx,
				  $self->stash_variable("\$",
							$self->gv_name($gv), $cx));
}

sub pp_null
{
    $] < 5.022 ? null_older(@_) : null_newer(@_);
}

sub pp_once
{
    my ($self, $op, $cx) = @_;
    my $cond = $op->first;
    my $true = $cond->sibling;

    return $self->deparse($true, $cx);
}

sub pp_or  { logop(@_, "or",  2, "||", 10, "unless") }
sub pp_dor { logop(@_, "//", 10) }

sub pp_mapwhile { mapop(@_, "map") }
sub pp_grepwhile { mapop(@_, "grep") }

sub pp_preinc { pfixop(@_, "++", 23) }
sub pp_predec { pfixop(@_, "--", 23) }
sub pp_i_preinc { pfixop(@_, "++", 23) }
sub pp_i_predec { pfixop(@_, "--", 23) }

sub pp_rcatline {
    my ($self, $op) = @_;
    return $self->info_from_string('rcatline <$fh>', $op,
				   sprintf "<%s>", $self->gv_name($self->gv_or_padgv($op)));
}

sub pp_readline {
    my $self = shift;
    my($op, $cx) = @_;
    my $first_kid = $op->first;
    my $kid = $first_kid;
    my @other_ops;
    # Do we have <$fh>?
    if ($first_kid->name eq "rv2gv") {
	push @other_ops, $kid;
	$kid  = $first_kid->first;
    }
    if (B::Deparse::is_scalar($kid) and
	($] < 5.021 or
	 ($op->flags & OPf_SPECIAL))) {
	my $kid_node = $self->deparse($kid, 1, $op);
	if ($kid_node->{text} eq 'ARGV') {
	    if (@other_ops) {
		# skipped first node, also add $kid_node.
		push @other_ops, $kid_node;
	    } else {
		# upgrade @other_ops from an op to a node
		@other_ops = ($kid_node);
	    }
	    return $self->info_from_string('readline <<>>', $op, '<<>>',
					   {other_ops => [$first_kid, $kid_node]});
	} else {
	    return $self->info_from_template('readline <$fh>', $op, "<%c>",
					     undef, [$kid_node],
					     {other_ops => @other_ops});
	}
    }
    my $node = $self->unop($op, $cx, "readline");
    push @{$node->{other_ops}}, $first_kid;
    return $node
}

sub pp_split {
    # 5.20 might drop "maybe_targmy?"
    maybe_targmy(@_, \&split, "split");
}

sub pp_stringify {
    $] < 5.022 ? stringify_older(@_) : stringify_newer(@_);
}

sub pp_subst {
    $] < 5.022 ? subst_older(@_) : subst_newer(@_);
}

# Perl 5.14 doesn't have this
use constant OPpSUBSTR_REPL_FIRST => 16;

sub pp_substr {
    my ($self,$op,$cx) = @_;
    if ($op->private & OPpSUBSTR_REPL_FIRST) {
	my $left = listop($self, $op, 7, "substr", $op->first->sibling->sibling);
	my $right = $self->deparse($op->first->sibling, 7, $op);
	return info_from_list($op, $self,[$left, '=', $right], ' ',
			      'substr_repl_first', {});
    }
    return maybe_local(@_, listop(@_, "substr"))
}

# FIXME:
# Different between 5.20 and 5.22. We've used 5.22 though.
# Go over and make sure this is okay.
sub pp_stub {
    my ($self, $op) = @_;
    $self->info_from_string('stub ()', $op, '()')
};

sub pp_trans {
    my $self = shift;
    my($op, $cx) = @_;
    my($from, $to);
    my $class = class($op);
    my $priv_flags = $op->private;
    if ($class eq "PVOP") {
	($from, $to) = B::Deparse::tr_decode_byte($op->pv, $priv_flags);
    } elsif ($class eq "PADOP") {
	($from, $to)
	  = tr_decode_utf8($self->padval($op->padix)->RV, $priv_flags);
    } else { # class($op) eq "SVOP"
	($from, $to) = B::Deparse::tr_decode_utf8($op->sv->RV, $priv_flags);
    }
    my $flags = "";
    $flags .= "c" if $priv_flags & OPpTRANS_COMPLEMENT;
    $flags .= "d" if $priv_flags & OPpTRANS_DELETE;
    $to = "" if $from eq $to and $flags eq "";
    $flags .= "s" if $priv_flags & OPpTRANS_SQUASH;
    return info_from_list($op, $self, ['tr', double_delim($from, $to), $flags],
		      '', 'pp_trans', {});
}

sub pp_transr {
    my $self = $_[0];
    my $op = $_[1];
    my $info = pp_trans(@_);
    # FIXME: thrn into template as below
    return $self->info_from_string('pp_transr', $op, $info->{text} . 'r',
				   {other_ops => [$info]});
    # return $self->info_from_template("trans r", "%cr", undef, [$info]);
}

sub pp_unstack {
    my ($self, $op) = @_;
    # see also leaveloop
    return $self->info_from_string("unstack", $op, '');
}

# xor is syntactically a logop, but it's really a binop (contrary to
# old versions of opcode.pl). Syntax is what matters here.
sub pp_xor { logop(@_, "xor", 2, "",   0,  "") }

1;
