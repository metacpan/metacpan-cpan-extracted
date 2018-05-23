# B::DeparseTree::P522.pm
# Copyright (c) 1998-2000, 2002, 2003, 2004, 2005, 2006 Stephen McCamant.
# Copyright (c) 2015, 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module B::Deparse (for perl 5.22) by Stephen McCamant.
# It has been extended save tree structure, and is addressible
# by opcode address.

# B::Parse in turn is based on the module of the same name by Malcolm Beattie,
# but essentially none of his code remains.

use v5.22;

use rlib '../..';

package B::DeparseTree::P522;
use Carp;
use B qw(class opnumber
    OPf_WANT OPf_WANT_VOID OPf_WANT_SCALAR OPf_WANT_LIST
    OPf_KIDS OPf_REF OPf_STACKED OPf_SPECIAL OPf_MOD OPf_PARENS
    OPpLVAL_INTRO OPpOUR_INTRO OPpENTERSUB_AMPER OPpSLICE OPpCONST_BARE
    OPpTRANS_SQUASH OPpTRANS_DELETE OPpTRANS_COMPLEMENT OPpTARGET_MY
    OPpSORT_NUMERIC OPpSORT_INTEGER OPpREPEAT_DOLIST
    OPpSORT_REVERSE OPpMULTIDEREF_EXISTS OPpMULTIDEREF_DELETE
    SVf_ROK SVpad_OUR SVf_FAKE SVs_RMG SVs_SMG
    SVpad_TYPED
    CVf_METHOD
    PMf_KEEP PMf_GLOBAL PMf_CONTINUE PMf_EVAL PMf_ONCE
    PMf_MULTILINE PMf_SINGLELINE PMf_FOLD PMf_EXTENDED PMf_EXTENDED_MORE
    PADNAMEt_OUTER
    MDEREF_reload
    MDEREF_AV_pop_rv2av_aelem
    MDEREF_AV_gvsv_vivify_rv2av_aelem
    MDEREF_AV_padsv_vivify_rv2av_aelem
    MDEREF_AV_vivify_rv2av_aelem
    MDEREF_AV_padav_aelem
    MDEREF_AV_gvav_aelem
    MDEREF_HV_pop_rv2hv_helem
    MDEREF_HV_gvsv_vivify_rv2hv_helem
    MDEREF_HV_padsv_vivify_rv2hv_helem
    MDEREF_HV_vivify_rv2hv_helem
    MDEREF_HV_padhv_helem
    MDEREF_HV_gvhv_helem
    MDEREF_ACTION_MASK
    MDEREF_INDEX_none
    MDEREF_INDEX_const
    MDEREF_INDEX_padsv
    MDEREF_INDEX_gvsv
    MDEREF_INDEX_MASK
    MDEREF_FLAG_last
    MDEREF_MASK
    MDEREF_SHIFT
);

use B::DeparseTree::Common;
use B::DeparseTree::PP;
use B::Deparse;

# Copy unchanged functions from B::Deparse
*begin_is_use = *B::Deparse::begin_is_use;
*const_sv = *B::Deparse::const_sv;
*gv_name = *B::Deparse::gv_name;
*padname_sv = *B::Deparse::padname_sv;
*meth_sv = *B::Deparse::meth_sv;
*meth_rclass_sv = *B::Deparse::meth_rclass_sv;
*re_flags = *B::Deparse::re_flags;
*tr_chr = *B::Deparse::tr_chr;

use strict;
use vars qw/$AUTOLOAD/;
use warnings ();
require feature;

our(@EXPORT, @ISA);
our $VERSION = '3.0.0';

@ISA = qw(Exporter B::DeparseTree::Common);
@EXPORT = qw(compile);

BEGIN {
    # List version-specific constants here.
    # Easiest way to keep this code portable between version looks to
    # be to fake up a dummy constant that will never actually be true.
    foreach (qw(OPpSORT_INPLACE OPpSORT_DESCEND OPpITER_REVERSED OPpCONST_NOVER
		OPpPAD_STATE PMf_SKIPWHITE RXf_SKIPWHITE
		RXf_PMf_CHARSET RXf_PMf_KEEPCOPY CVf_ANONCONST
		CVf_LOCKED OPpREVERSE_INPLACE OPpSUBSTR_REPL_FIRST
		PMf_NONDESTRUCT OPpCONST_ARYBASE OPpEVAL_BYTES)) {
	eval { import B $_ };
	no strict 'refs';
	*{$_} = sub () {0} unless *{$_}{CODE};
    }
}

BEGIN { for (qw[ const stringify rv2sv list glob pushmark null aelem
		 nextstate dbstate rv2av rv2hv helem custom ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

sub deparse_format($$$)
{
    my ($self, $form, $parent) = @_;
    my @texts;
    local($self->{'curcv'}) = $form;
    local($self->{'curcvlex'});
    local($self->{'in_format'}) = 1;
    local(@$self{qw'curstash warnings hints hinthash'})
		= @$self{qw'curstash warnings hints hinthash'};
    my $op = $form->ROOT;
    local $B::overlay = {};
    $self->pessimise($op, $form->START);
    my $info = {
	op  => $op,
	parent => $parent,
	cop => $self->{'curcop'}
    };
    $self->{optree}{$$op} = $info;

    if ($op->first->name eq 'stub' || $op->first->name eq 'nextstate') {
	my $info->{text} = "\f.";
	return $info;
    }

    $op->{other_ops} = [$op->first];
    $op = $op->first->first; # skip leavewrite, lineseq
    my $kid;
    while (not null $op) {
	push @{$op->{other_ops}}, $op;
	$op = $op->sibling; # skip nextstate
	my @body;
	push @{$op->{other_ops}}, $op->first;
	$kid = $op->first->sibling; # skip a pushmark
	push @texts, "\f".$self->const_sv($kid)->PV;
	push @{$op->{other_ops}}, $kid;
	$kid = $kid->sibling;
	for (; not null $kid; $kid = $kid->sibling) {
	    push @body, $self->deparse($kid, -1, $op);
	    $body[-1] =~ s/;\z//;
	}
	push @texts, "\f".$self->combine2str("\n", \@body) if @body;
	$op = $op->sibling;
    }

    $info->{text} = $self->combine2str(\@texts) . "\f.";
    $info->{texts} = \@texts;
    return $info;
}

sub ambient_pragmas {
    my $self = shift;
    my ($arybase, $hint_bits, $warning_bits, $hinthash) = (0, 0);

    while (@_ > 1) {
	my $name = shift();
	my $val  = shift();

	if ($name eq 'strict') {
	    require strict;

	    if ($val eq 'none') {
		$hint_bits &= $strict_bits{$_} for qw/refs subs vars/;
		next();
	    }

	    my @names;
	    if ($val eq "all") {
		@names = qw/refs subs vars/;
	    }
	    elsif (ref $val) {
		@names = @$val;
	    }
	    else {
		@names = split' ', $val;
	    }
	    $hint_bits |= $strict_bits{$_} for @names;
	}

	elsif ($name eq '$[') {
	    if (OPpCONST_ARYBASE) {
		$arybase = $val;
	    } else {
		croak "\$[ can't be non-zero on this perl" unless $val == 0;
	    }
	}

	elsif ($name eq 'integer'
	    || $name eq 'bytes'
	    || $name eq 'utf8') {
	    require "$name.pm";
	    if ($val) {
		$hint_bits |= ${$::{"${name}::"}{"hint_bits"}};
	    }
	    else {
		$hint_bits &= ~${$::{"${name}::"}{"hint_bits"}};
	    }
	}

	elsif ($name eq 're') {
	    require re;
	    if ($val eq 'none') {
		$hint_bits &= ~re::bits(qw/taint eval/);
		next();
	    }

	    my @names;
	    if ($val eq 'all') {
		@names = qw/taint eval/;
	    }
	    elsif (ref $val) {
		@names = @$val;
	    }
	    else {
		@names = split' ',$val;
	    }
	    $hint_bits |= re::bits(@names);
	}

	elsif ($name eq 'warnings') {
	    if ($val eq 'none') {
		$warning_bits = $warnings::NONE;
		next();
	    }

	    my @names;
	    if (ref $val) {
		@names = @$val;
	    }
	    else {
		@names = split/\s+/, $val;
	    }

	    $warning_bits = $warnings::NONE if !defined ($warning_bits);
	    $warning_bits |= warnings::bits(@names);
	}

	elsif ($name eq 'warning_bits') {
	    $warning_bits = $val;
	}

	elsif ($name eq 'hint_bits') {
	    $hint_bits = $val;
	}

	elsif ($name eq '%^H') {
	    $hinthash = $val;
	}

	else {
	    croak "Unknown pragma type: $name";
	}
    }
    if (@_) {
	croak "The ambient_pragmas method expects an even number of args";
    }

    $self->{'ambient_arybase'} = $arybase;
    $self->{'ambient_warnings'} = $warning_bits;
    $self->{'ambient_hints'} = $hint_bits;
    $self->{'ambient_hinthash'} = $hinthash;
}

# Sort of like maybe_parens in that we may possibly add ().  However we take
# an op rather than text, and return a tree node. Also, we get around
# the 'if it looks like a function' rule.
sub maybe_parens_unop($$$$$)
{
    my $self = shift;
    my($name, $op, $cx, $parent) = @_;
    my $info =  $self->deparse($op, 1, $parent);
    my $fmt;
    my @exprs = ($info);
    if ($name eq "umask" && $info->{text} =~ /^\d+$/) {
	# Display umask numbers in octal.
	# FIXME: add as a info_node option to run a transformation function
	# such as the below
	$info->{text} = sprintf("%#o", $info->{text});
	$exprs[0] = $info;
    }
    $name = $self->keyword($name);
    if ($cx > 16 or $self->{'parens'}) {
	return $self->info_from_template("$name()", $op,
					 "$name(%c)",[0], \@exprs);
    } else {
	# FIXME: we don't do \cS
	# if (substr($text, 0, 1) eq "\cS") {
	#     # use op's parens
	#     return info_from_list($op, $self,[$name, substr($text, 1)],
	# 			  '',  'maybe_parens_unop_cS', {body => [$info]});
	# } else
	if (substr($info->{text}, 0, 1) eq "(") {
	    # avoid looks-like-a-function trap with extra parens
	    # ('+' can lead to ambiguities)
	    return $self->info_from_template("$name(())", $op,
					     "$name(%c)", [0], \@exprs);
	} else {
	    return $self->info_from_template("$name <args>", $op,
					     "$name %c", [0], \@exprs);
	}
    }
    Carp::confess("unhandled condition in maybe_parens_unop");
}

sub maybe_my {
    my $self = shift;
    my($op, $cx, $text, $forbid_parens) = @_;
    if ($op->private & OPpLVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	my $my_str = $op->private & OPpPAD_STATE
	    ? $self->keyword("state")
	    : "my";
	if ($forbid_parens || B::Deparse::want_scalar($op)) {
	    return info_from_list($op, $self, [$my_str,  $text], ' ',
				  'maybe_my_no_parens', {});
	} else {
	    return info_from_list($op, $self, [$my_str,  $text], ' ',
				  'maybe_my_parens',
				  {maybe_parens => [$self, $cx, 16]});
	}
    } else {
	return info_from_text($op, $self, $text, 'maybe_my_avoid_local', {});
    }
}

# The following OPs don't have functions:

# pp_padany -- does not exist after parsing

sub AUTOLOAD {
    if ($AUTOLOAD =~ s/^.*::pp_//) {
	warn "unexpected OP_".uc $AUTOLOAD;
    } else {
	Carp::confess "Undefined subroutine $AUTOLOAD called";
    }
}

sub DESTROY {}	#	Do not AUTOLOAD

# The BEGIN {} is used here because otherwise this code isn't executed
# when you run B::Deparse on itself.
my %globalnames;
BEGIN { map($globalnames{$_}++, "SIG", "STDIN", "STDOUT", "STDERR", "INC",
	    "ENV", "ARGV", "ARGVOUT", "_"); }

# Return the name to use for a stash variable.
# If a lexical with the same name is in scope, or
# if strictures are enabled, it may need to be
# fully-qualified.
sub stash_variable {
    my ($self, $prefix, $name, $cx) = @_;

    $name = $self->info2str($name);
    return "$prefix$name" if $name =~ /::/;

    unless ($prefix eq '$' || $prefix eq '@' || $prefix eq '&' || #'
	    $prefix eq '%' || $prefix eq '$#') {
	return "$prefix$name";
    }

    if ($name =~ /^[^[:alpha:]_+-]$/) {
      if (defined $cx && $cx == 26) {
	if ($prefix eq '@') {
	    return "$prefix\{$name}";
	}
	elsif ($name eq '#') { return '${#}' } #  "${#}a" vs "$#a"
      }
      if ($prefix eq '$#') {
	return "\$#{$name}";
      }
    }

    return $prefix . $self->maybe_qualify($prefix, $name);
}

sub lex_in_scope {
    my ($self, $name, $our) = @_;
    substr $name, 0, 0, = $our ? 'o' : 'm'; # our/my
    $self->populate_curcvlex() if !defined $self->{'curcvlex'};

    return 0 if !defined($self->{'curcop'});
    my $seq = $self->{'curcop'}->cop_seq;
    return 0 if !exists $self->{'curcvlex'}{$name};
    for my $a (@{$self->{'curcvlex'}{$name}}) {
	my ($st, $en) = @$a;
	return 1 if $seq > $st && $seq <= $en;
    }
    return 0;
}

sub populate_curcvlex {
    my $self = shift;
    for (my $cv = $self->{'curcv'}; class($cv) eq "CV"; $cv = $cv->OUTSIDE) {
	my $padlist = $cv->PADLIST;
	# an undef CV still in lexical chain
	next if class($padlist) eq "SPECIAL";
	my @padlist = $padlist->ARRAY;
	my @ns = $padlist[0]->ARRAY;

	for (my $i=0; $i<@ns; ++$i) {
	    next if class($ns[$i]) eq "SPECIAL";
	    if (class($ns[$i]) eq "PV") {
		# Probably that pesky lexical @_
		next;
	    }
            my $name = $ns[$i]->PVX;
	    next unless defined $name;
	    my ($seq_st, $seq_en) =
		($ns[$i]->FLAGS & SVf_FAKE)
		    ? (0, 999999)
		    : ($ns[$i]->COP_SEQ_RANGE_LOW, $ns[$i]->COP_SEQ_RANGE_HIGH);

	    push @{$self->{'curcvlex'}{
			($ns[$i]->FLAGS & SVpad_OUR ? 'o' : 'm') . $name
		  }}, [$seq_st, $seq_en, $ns[$i]];
	}
    }
}

sub find_scope_st { ((find_scope(@_))[0]); }
sub find_scope_en { ((find_scope(@_))[1]); }

# Recurses down the tree, looking for pad variable introductions and COPs
sub find_scope {
    my ($self, $op, $scope_st, $scope_en) = @_;
    carp("Undefined op in find_scope") if !defined $op;
    return ($scope_st, $scope_en) unless $op->flags & OPf_KIDS;

    my @queue = ($op);
    while(my $op = shift @queue ) {
	for (my $o=$op->first; $$o; $o=$o->sibling) {
	    if ($o->name =~ /^pad.v$/ && $o->private & OPpLVAL_INTRO) {
		my $s = int($self->padname_sv($o->targ)->COP_SEQ_RANGE_LOW);
		my $e = $self->padname_sv($o->targ)->COP_SEQ_RANGE_HIGH;
		$scope_st = $s if !defined($scope_st) || $s < $scope_st;
		$scope_en = $e if !defined($scope_en) || $e > $scope_en;
		return ($scope_st, $scope_en);
	    }
	    elsif (is_state($o)) {
		my $c = $o->cop_seq;
		$scope_st = $c if !defined($scope_st) || $c < $scope_st;
		$scope_en = $c if !defined($scope_en) || $c > $scope_en;
		return ($scope_st, $scope_en);
	    }
	    elsif ($o->flags & OPf_KIDS) {
		unshift (@queue, $o);
	    }
	}
    }

    return ($scope_st, $scope_en);
}

# Returns a list of subs which should be inserted before the COP
sub cop_subs {
    my ($self, $op, $out_seq) = @_;
    my $seq = $op->cop_seq;
    # If we have nephews, then our sequence number indicates
    # the cop_seq of the end of some sort of scope.
    if (class($op->sibling) ne "NULL" && $op->sibling->flags & OPf_KIDS
	and my $nseq = $self->find_scope_st($op->sibling) ) {
	$seq = $nseq;
    }
    $seq = $out_seq if defined($out_seq) && $out_seq < $seq;
    return $self->seq_subs($seq);
}

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

# keywords that are strong and also have a prototype
#
my %strong_proto_keywords = map { $_ => 1 } qw(
    pos
    prototype
    scalar
    study
    undef
);

sub keyword {
    my $self = shift;
    my $name = shift;
    return $name if $name =~ /^CORE::/; # just in case
    if (exists $feature_keywords{$name}) {
	my $hh;
	my $hints = $self->{hints} & $feature::hint_mask;
	if ($hints && $hints != $feature::hint_mask) {
	    $hh = _features_from_bundle($hints);
	}
	elsif ($hints) { $hh = $self->{'hinthash'} }
	return "CORE::$name"
	 if !$hh
	 || !$hh->{"feature_$feature_keywords{$name}"}
    }
    if ($strong_proto_keywords{$name}
        || ($name !~ /^(?:chom?p|do|exec|glob|s(?:elect|ystem))\z/
	    && !defined eval{prototype "CORE::$name"})
    ) { return $name }
    if (
	exists $self->{subs_declared}{$name}
	 or
	exists &{"$self->{curstash}::$name"}
    ) {
	return "CORE::$name"
    }
    return $name;
}

sub pp_not
{
    my($self, $op, $cx) = @_;
    if ($cx <= 4) {
	$self->listop($op, $cx, "not", $op->first);
    } else {
	$self->pfixop($op, $cx, "!", 21);
    }
}

# Note: maybe_local things can't be moved to PP yet.
sub pp_pos { maybe_local(@_, unop(@_, "pos")) }
sub pp_sin { maybe_targmy(@_, \&unop, "sin") }
sub pp_cos { maybe_targmy(@_, \&unop, "cos") }
sub pp_exp { maybe_targmy(@_, \&unop, "exp") }
sub pp_log { maybe_targmy(@_, \&unop, "log") }
sub pp_sqrt { maybe_targmy(@_, \&unop, "sqrt") }
sub pp_int { maybe_targmy(@_, \&unop, "int") }
sub pp_hex { maybe_targmy(@_, \&unop, "hex") }
sub pp_oct { maybe_targmy(@_, \&unop, "oct") }
sub pp_abs { maybe_targmy(@_, \&unop, "abs") }

sub pp_length { maybe_targmy(@_, \&unop, "length") }
sub pp_ord { maybe_targmy(@_, \&unop, "ord") }
sub pp_chr { maybe_targmy(@_, \&unop, "chr") }

sub pp_each { unop(@_, "each") }
sub pp_values { unop(@_, "values") }
sub pp_keys { unop(@_, "keys") }
{ no strict 'refs'; *{"pp_r$_"} = *{"pp_$_"} for qw< keys each values >; }
sub pp_boolkeys
{
    # no name because its an optimisation op that has no keyword
    unop(@_,"");
}
sub pp_aeach { unop(@_, "each") }
sub pp_avalues { unop(@_, "values") }
sub pp_akeys { unop(@_, "keys") }
sub pp_pop { unop(@_, "pop") }
sub pp_shift { unop(@_, "shift") }

sub pp_caller { unop(@_, "caller") }
sub pp_reset { unop(@_, "reset") }
sub pp_exit { unop(@_, "exit") }
sub pp_prototype { unop(@_, "prototype") }

sub pp_close { unop(@_, "close") }
sub pp_fileno { unop(@_, "fileno") }
sub pp_umask { unop(@_, "umask") }
sub pp_untie { unop(@_, "untie") }
sub pp_tied { unop(@_, "tied") }
sub pp_dbmclose { unop(@_, "dbmclose") }
sub pp_getc { unop(@_, "getc") }
sub pp_eof { unop(@_, "eof") }
sub pp_tell { unop(@_, "tell") }
sub pp_getsockname { unop(@_, "getsockname") }
sub pp_getpeername { unop(@_, "getpeername") }

sub pp_chroot { maybe_targmy(@_, \&unop, "chroot") }
sub pp_readlink { unop(@_, "readlink") }
sub pp_rmdir { maybe_targmy(@_, \&unop, "rmdir") }
sub pp_readdir { unop(@_, "readdir") }
sub pp_telldir { unop(@_, "telldir") }
sub pp_rewinddir { unop(@_, "rewinddir") }
sub pp_closedir { unop(@_, "closedir") }
sub pp_getpgrp { maybe_targmy(@_, \&unop, "getpgrp") }
sub pp_localtime { unop(@_, "localtime") }
sub pp_gmtime { unop(@_, "gmtime") }
sub pp_alarm { unop(@_, "alarm") }
sub pp_sleep { maybe_targmy(@_, \&unop, "sleep") }

sub pp_dofile
{
    my $code = unop(@_, "do", 1); # llafr does not apply
    if ($code =~ s/^((?:CORE::)?do) \{/$1({/) { $code .= ')' }
    $code;
}

sub pp_ghbyname { unop(@_, "gethostbyname") }
sub pp_gnbyname { unop(@_, "getnetbyname") }
sub pp_gpbyname { unop(@_, "getprotobyname") }
sub pp_shostent { unop(@_, "sethostent") }
sub pp_snetent { unop(@_, "setnetent") }
sub pp_sprotoent { unop(@_, "setprotoent") }
sub pp_sservent { unop(@_, "setservent") }
sub pp_gpwnam { unop(@_, "getpwnam") }
sub pp_gpwuid { unop(@_, "getpwuid") }
sub pp_ggrnam { unop(@_, "getgrnam") }
sub pp_ggrgid { unop(@_, "getgrgid") }

sub pp_lock { unop(@_, "lock") }

sub pp_continue { unop(@_, "continue"); }
sub pp_break { unop(@_, "break"); }

sub givwhen
{
    my($self, $op, $cx, $givwhen) = @_;

    my $enterop = $op->first;
    my ($head, $block);
    if ($enterop->flags & OPf_SPECIAL) {
	$head = $self->keyword("default");
	$block = $self->deparse($enterop->first, 0, $enterop, $op);
    }
    else {
	my $cond = $enterop->first;
	my $cond_str = $self->deparse($cond, 1, $enterop, $op);
	$head = "$givwhen ($cond_str)";
	$block = $self->deparse($cond->sibling, 0, $enterop, $op);
    }

    return info_from_list($op, $self, [$head, "{",
			   "\n\t", $block->{text}, "\n\b",
			   "}\cK"], '', 'givwhen',
			  {body => [$block]});
}

sub pp_leavegiven { givwhen(@_, $_[0]->keyword("given")); }
sub pp_leavewhen  { givwhen(@_, $_[0]->keyword("when")); }

sub pp_delete
{
    my($self, $op, $cx) = @_;
    my $arg;
    my ($info, $body, $type);
    if ($op->private & OPpSLICE) {
	if ($op->flags & OPf_SPECIAL) {
	    # Deleting from an array, not a hash
	    $info = $self->pp_aslice($op->first, 16);
	    $type = 'delete_slice';
	}
    } else {
	if ($op->flags & OPf_SPECIAL) {
	    # Deleting from an array, not a hash
	    $info = $self->pp_aelem($op->first, 16);
	    $type = 'delete_array'
	} else {
	    $info = $self->pp_helem($op->first, 16);
	    $type = 'delete_hash';
	}
    }
    my @texts = $self->maybe_parens_func("delete",
					 $info->{text}, $cx, 16);
    return info_from_list($op, $self, \@texts, '', $type, {body => [$info]});
}

sub pp_require
{
    my($self, $op, $cx) = @_;
    my $opname = $op->flags & OPf_SPECIAL ? 'CORE::require' : 'require';
    if (class($op) eq "UNOP" and $op->first->name eq "const"
	and $op->first->private & OPpCONST_BARE) {
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
	    && $op->first->private & OPpCONST_NOVER
	    ? "no"
	    : $opname,
	    1, # llafr does not apply
	    );
    }
    Carp::confess("unhandled condition in pp_require");
}

sub pp_scalar
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    if (not null $kid->sibling) {
	# XXX Was a here-doc
	return $self->dquote($op);
    }
    $self->unop($op, $cx, "scalar");
}


sub padval
{
    my $self = shift;
    my $targ = shift;
    return $self->{'curcv'}->PADLIST->ARRAYelt(1)->ARRAYelt($targ);
}

sub anon_hash_or_list
{
    my $self = shift;
    my($op, $cx) = @_;

    my $name = $op->name;
    my($pre, $post) = @{{"anonlist" => ["[","]"],
			 "anonhash" => ["{","}"]}->{$name}};
    my($expr, @exprs);
    my $other_ops = [$op->first];
    $op = $op->first->sibling; # skip pushmark
    for (; !null($op); $op = $op->sibling) {
	$expr = $self->deparse($op, 6, $op);
	push @exprs, [$expr, $op];
    }
    if ($pre eq "{" and $cx < 1) {
	# Disambiguate that it's not a block
	$pre = "+{";
    }
    my $texts = [$pre, $self->combine(", ", \@exprs), $post];
    return info_from_list($op, $self, $texts, '', $name,
			  {body => \@exprs,
			   other_ops => $other_ops
			  });
}

sub pp_anonlist {
    my $self = shift;
    my ($op, $cx) = @_;
    if ($op->flags & OPf_SPECIAL) {
	return $self->anon_hash_or_list($op, $cx);
    }
    warn "Unexpected op pp_" . $op->name() . " without OPf_SPECIAL";
    return info_from_text($op, $self, 'XXX', 'bad_anonlist', {});
}

*pp_anonhash = \&pp_anonlist;

sub e_anoncode($$)
{
    my ($self, $info) = @_;
    my $sub_info = $self->deparse_sub($info->{code});
    return info_from_list($sub_info->{op}, $self,
			  ['sub', $sub_info->{text}], ' ', 'e_anoncode',
			  {body=> [$sub_info]});
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
	 or !null($anoncode = $kid->sibling) and
		 $anoncode->name eq "anoncode") {
            return $self->e_anoncode({ code => $self->padval($anoncode->targ) });
	} elsif ($kid->name eq "pushmark") {
            my $sib_name = $kid->sibling->name;
            if ($sib_name eq 'entersub') {
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

sub pp_srefgen { pp_refgen(@_) }

sub pp_readline {
    my $self = shift;
    my($op, $cx) = @_;
    my $kid = $op->first;
    $kid = $kid->first if $kid->name eq "rv2gv"; # <$fh>
    if (is_scalar($kid)) {
	my $body = [$self->deparse($kid, 1, $op)];
	return info_from_list($op, $self, ['<', $body->[0]{text}, '>'], '',
			      'readline_scalar', {body=>$body});
    }
    return $self->unop($op, $cx, "readline");
}

sub pp_rcatline {
    my $self = shift;
    my($op) = @_;
    return info_from_list($op, $self, ["<", $self->gv_name($self->gv_or_padgv($op)), ">"],
			  '', 'rcatline', {});
}

sub pp_ucfirst { dq_unop(@_, "ucfirst") }
sub pp_lcfirst { dq_unop(@_, "lcfirst") }
sub pp_uc { dq_unop(@_, "uc") }
sub pp_lc { dq_unop(@_, "lc") }
sub pp_quotemeta { maybe_targmy(@_, \&dq_unop, "quotemeta") }
sub pp_fc { dq_unop(@_, "fc") }

# loop expressions
sub loopex
{
    my ($self, $op, $cx, $name) = @_;
    my $opts = {maybe_parens => [$self, $cx, 7]};
    my ($type, $body);
    if (class($op) eq "PVOP") {
	return info_from_list($op, $self, [$name, $op->pv], ' ', 'loopex_pvop', {});
    } elsif (class($op) eq "OP") {
	# no-op
	$type = 'loopex_op';
	return info_from_text($op, $self, $name, 'loopex_op', $opts);
    } elsif (class($op) eq "UNOP") {
	(my $kid_info = $self->deparse($op->first, 7, $op)) =~ s/^\cS//;
	$opts->{body} = [$kid_info];
	return info_from_list($op, $self, [$name, $op->pv], ' ', 'loopex_unop', $opts);
    } else {
	return info_from_text($op, $self, $name, 'loopex', $opts);
    }
    Carp::confess("unhandled condition in lopex");
}

sub pp_last { loopex(@_, "last") }
sub pp_next { loopex(@_, "next") }
sub pp_redo { loopex(@_, "redo") }
sub pp_goto { loopex(@_, "goto") }
sub pp_dump { loopex(@_, "CORE::dump") }

sub ftst
{
    my($self, $op, $cx, $name) = @_;
    if (class($op) eq "UNOP") {
	# Genuine '-X' filetests are exempt from the LLAFR, but not
	# l?stat()
	if ($name =~ /^-/) {
	    (my $kid = $self->deparse($op->first, 16, $op)) =~ s/^\cS//;
	    return info_from_list($op, $self, [$name, $kid->{text}], ' ',
				  'ftst_unop_dash',
				  {body => [$kid],
				  maybe_parens => [$self, $cx, 16]});
	}
	return $self->maybe_parens_unop($name, $op->first, $cx, $op);
    } elsif (class($op) =~ /^(SV|PAD)OP$/) {
	my @list = $self->maybe_parens_func($name, $self->pp_gv($op, 1), $cx, 16);
	return info_from_list($op, $self, \@list, ' ', 'ftst_list', {});
    } else { # I don't think baseop filetests ever survive ck_ftst, but...
	return info_from_text($op, $self, $name, 'unop', {});
    }
}

sub pp_lstat    { ftst(@_, "lstat") }
sub pp_stat     { ftst(@_, "stat") }
sub pp_ftrread  { ftst(@_, "-R") }
sub pp_ftrwrite { ftst(@_, "-W") }
sub pp_ftrexec  { ftst(@_, "-X") }
sub pp_fteread  { ftst(@_, "-r") }
sub pp_ftewrite { ftst(@_, "-w") }
sub pp_fteexec  { ftst(@_, "-x") }
sub pp_ftis     { ftst(@_, "-e") }
sub pp_fteowned { ftst(@_, "-O") }
sub pp_ftrowned { ftst(@_, "-o") }
sub pp_ftzero   { ftst(@_, "-z") }
sub pp_ftsize   { ftst(@_, "-s") }
sub pp_ftmtime  { ftst(@_, "-M") }
sub pp_ftatime  { ftst(@_, "-A") }
sub pp_ftctime  { ftst(@_, "-C") }
sub pp_ftsock   { ftst(@_, "-S") }
sub pp_ftchr    { ftst(@_, "-c") }
sub pp_ftblk    { ftst(@_, "-b") }
sub pp_ftfile   { ftst(@_, "-f") }
sub pp_ftdir    { ftst(@_, "-d") }
sub pp_ftpipe   { ftst(@_, "-p") }
sub pp_ftlink   { ftst(@_, "-l") }
sub pp_ftsuid   { ftst(@_, "-u") }
sub pp_ftsgid   { ftst(@_, "-g") }
sub pp_ftsvtx   { ftst(@_, "-k") }
sub pp_fttty    { ftst(@_, "-t") }
sub pp_fttext   { ftst(@_, "-T") }
sub pp_ftbinary { ftst(@_, "-B") }

sub SWAP_CHILDREN () { 1 }
sub ASSIGN () { 2 } # has OP= variant
sub LIST_CONTEXT () { 4 } # Assignment is in list context

my(%left, %right);

sub assoc_class {
    my $op = shift;
    my $name = $op->name;
    if ($name eq "concat" and $op->first->name eq "concat") {
	# avoid spurious '=' -- see comment in pp_concat
	return "concat";
    }
    if ($name eq "null" and class($op) eq "UNOP"
	and $op->first->name =~ /^(and|x?or)$/
	and null $op->first->sibling)
    {
	# Like all conditional constructs, OP_ANDs and OP_ORs are topped
	# with a null that's used as the common end point of the two
	# flows of control. For precedence purposes, ignore it.
	# (COND_EXPRs have these too, but we don't bother with
	# their associativity).
	return assoc_class($op->first);
    }
    return $name . ($op->flags & OPf_STACKED ? "=" : "");
}

# Left associative operators, like '+', for which
# $a + $b + $c is equivalent to ($a + $b) + $c

BEGIN {
    %left = ('multiply' => 19, 'i_multiply' => 19,
	     'divide' => 19, 'i_divide' => 19,
	     'modulo' => 19, 'i_modulo' => 19,
	     'repeat' => 19,
	     'add' => 18, 'i_add' => 18,
	     'subtract' => 18, 'i_subtract' => 18,
	     'concat' => 18,
	     'left_shift' => 17, 'right_shift' => 17,
	     'bit_and' => 13,
	     'bit_or' => 12, 'bit_xor' => 12,
	     'and' => 3,
	     'or' => 2, 'xor' => 2,
	    );
}

sub deparse_binop_left {
    my $self = shift;
    my($op, $left, $prec) = @_;
    if ($left{assoc_class($op)} && $left{assoc_class($left)}
	and $left{assoc_class($op)} == $left{assoc_class($left)})
    {
	return $self->deparse($left, $prec - .00001, $op);
    } else {
	return $self->deparse($left, $prec, $op);
    }
}

# Right associative operators, like '=', for which
# $a = $b = $c is equivalent to $a = ($b = $c)

BEGIN {
    %right = ('pow' => 22,
	      'sassign=' => 7, 'aassign=' => 7,
	      'multiply=' => 7, 'i_multiply=' => 7,
	      'divide=' => 7, 'i_divide=' => 7,
	      'modulo=' => 7, 'i_modulo=' => 7,
	      'repeat=' => 7,
	      'add=' => 7, 'i_add=' => 7,
	      'subtract=' => 7, 'i_subtract=' => 7,
	      'concat=' => 7,
	      'left_shift=' => 7, 'right_shift=' => 7,
	      'bit_and=' => 7,
	      'bit_or=' => 7, 'bit_xor=' => 7,
	      'andassign' => 7,
	      'orassign' => 7,
	     );
}

sub deparse_binop_right {
    my $self = shift;
    my($op, $right, $prec) = @_;
    if ($right{assoc_class($op)} && $right{assoc_class($right)}
	and $right{assoc_class($op)} == $right{assoc_class($right)})
    {
	return $self->deparse($right, $prec - .00001, $op);
    } else {
	return $self->deparse($right, $prec, $op);
    }
}

sub pp_add { maybe_targmy(@_, \&binop, "+", 18, ASSIGN) }
sub pp_multiply { maybe_targmy(@_, \&binop, "*", 19, ASSIGN) }
sub pp_subtract { maybe_targmy(@_, \&binop, "-",18,  ASSIGN) }
sub pp_divide { maybe_targmy(@_, \&binop, "/", 19, ASSIGN) }
sub pp_modulo { maybe_targmy(@_, \&binop, "%", 19, ASSIGN) }
sub pp_i_add { maybe_targmy(@_, \&binop, "+", 18, ASSIGN) }
sub pp_i_multiply { maybe_targmy(@_, \&binop, "*", 19, ASSIGN) }
sub pp_i_subtract { maybe_targmy(@_, \&binop, "-", 18, ASSIGN) }
sub pp_i_divide { maybe_targmy(@_, \&binop, "/", 19, ASSIGN) }
sub pp_i_modulo { maybe_targmy(@_, \&binop, "%", 19, ASSIGN) }
sub pp_pow { maybe_targmy(@_, \&binop, "**", 22, ASSIGN) }

sub pp_left_shift { maybe_targmy(@_, \&binop, "<<", 17, ASSIGN) }
sub pp_right_shift { maybe_targmy(@_, \&binop, ">>", 17, ASSIGN) }
sub pp_bit_and { maybe_targmy(@_, \&binop, "&", 13, ASSIGN) }
sub pp_bit_or { maybe_targmy(@_, \&binop, "|", 12, ASSIGN) }
sub pp_bit_xor { maybe_targmy(@_, \&binop, "^", 12, ASSIGN) }

sub pp_eq { binop(@_, "==", 14) }
sub pp_ne { binop(@_, "!=", 14) }
sub pp_lt { binop(@_, "<", 15) }
sub pp_gt { binop(@_, ">", 15) }
sub pp_ge { binop(@_, ">=", 15) }
sub pp_le { binop(@_, "<=", 15) }
sub pp_ncmp { binop(@_, "<=>", 14) }
sub pp_i_eq { binop(@_, "==", 14) }
sub pp_i_ne { binop(@_, "!=", 14) }
sub pp_i_lt { binop(@_, "<", 15) }
sub pp_i_gt { binop(@_, ">", 15) }
sub pp_i_ge { binop(@_, ">=", 15) }
sub pp_i_le { binop(@_, "<=", 15) }
sub pp_i_ncmp { binop(@_, "<=>", 14) }

sub pp_seq { binop(@_, "eq", 14) }
sub pp_sne { binop(@_, "ne", 14) }
sub pp_slt { binop(@_, "lt", 15) }
sub pp_sgt { binop(@_, "gt", 15) }
sub pp_sge { binop(@_, "ge", 15) }
sub pp_sle { binop(@_, "le", 15) }
sub pp_scmp { binop(@_, "cmp", 14) }

sub pp_sassign { binop(@_, "=", 7, SWAP_CHILDREN) }
sub pp_aassign { binop(@_, "=", 7, SWAP_CHILDREN | LIST_CONTEXT) }

sub pp_smartmatch {
    my ($self, $op, $cx) = @_;
    if ($op->flags & OPf_SPECIAL) {
	return $self->deparse($op->last, $cx, $op);
    }
    else {
	binop(@_, "~~", 14);
    }
}

sub bin_info_join($$$$$$$) {
    my ($self, $op, $lhs, $rhs, $mid, $sep, $type) = @_;
    my $texts = [$lhs->{text}, $mid, $rhs->{text}];
    return info_from_list($op, $self, $texts, ' ', $type, {})
}

sub bin_info_join_maybe_parens($$$$$$$$$) {
    my ($self, $op, $lhs, $rhs, $mid, $sep, $cx, $prec, $type) = @_;
    my $info = bin_info_join($self, $op, $lhs, $rhs, $mid, $sep, $type);
    $info->{text} = $self->maybe_parens($info->{text}, $cx, $prec);
    return $info;
}

# '.' is special because concats-of-concats are optimized to save copying
# by making all but the first concat stacked. The effect is as if the
# programmer had written '($a . $b) .= $c', except legal.
sub pp_concat { maybe_targmy(@_, \&real_concat) }
sub real_concat {
    my $self = shift;
    my($op, $cx) = @_;
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    my $prec = 18;
    if ($op->flags & OPf_STACKED and $op->first->name ne "concat") {
	$eq = "=";
	$prec = 7;
    }
    my $lhs = $self->deparse_binop_left($op, $left, $prec);
    my $rhs  = $self->deparse_binop_right($op, $right, $prec);
    return $self->bin_info_join_maybe_parens($op, $lhs, $rhs, ".$eq", " ", $cx, $prec,
					     'real_concat');
}

sub range {
    my $self = shift;
    my ($op, $cx, $type) = @_;
    my $left = $op->first;
    my $right = $left->sibling;
    $left = $self->deparse($left, 9, $op);
    $right = $self->deparse($right, 9, $op);
    return info_from_list($op, $self, [$left, $type, $right], ' ', 'range',
			  {maybe_parens => [$self, $cx, 9]});
}

sub pp_flop
{
    my $self = shift;
    my($op, $cx) = @_;
    my $flip = $op->first;
    my $type = ($flip->flags & OPf_SPECIAL) ? "..." : "..";
    return info_from_text($op, $self, $self->range($flip->first, $cx, $type), 'pp_flop', {});
}

sub logassignop
{
    my ($self, $op, $cx, $opname) = @_;
    my $left = $op->first;

    my $right = $op->first->sibling->first; # skip sassign
    $left = $self->deparse($left, 7, $op);
    $right = $self->deparse($right, 7, $op);
    return info_from_list($op, $self, [$left->{text}, $opname, $right->{text}], ' ',
			  'logassignop',
			  {other_ops => [$op->first->sibling],
			   body => [$left, $right],
			   maybe_parens => [$self, $cx, 7]});
}

sub pp_andassign { logassignop(@_, "&&=") }
sub pp_orassign  { logassignop(@_, "||=") }
sub pp_dorassign { logassignop(@_, "//=") }

sub rv2gv_or_string {
    my($self,$op, $parent) = @_;
    if ($op->name eq "gv") { # could be open("open") or open("###")
	my($name,$quoted) =
	    $self->stash_variable_name("", $self->gv_or_padgv($op));
	return info_from_text($op, $self, $quoted ? $name : "*$name", 'r2gv_or_string', {});
    }
    else {
	return $self->deparse($op, 6, $parent);
    }
}

sub pp_bless { listop(@_, "bless") }
sub pp_atan2 { maybe_targmy(@_, \&listop, "atan2") }
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
sub pp_vec { maybe_local(@_, listop(@_, "vec")) }
sub pp_index { maybe_targmy(@_, \&listop, "index") }
sub pp_rindex { maybe_targmy(@_, \&listop, "rindex") }
sub pp_sprintf { maybe_targmy(@_, \&listop, "sprintf") }
sub pp_formline { listop(@_, "formline") } # see also deparse_format
sub pp_crypt { maybe_targmy(@_, \&listop, "crypt") }
sub pp_unpack { listop(@_, "unpack") }
sub pp_pack { listop(@_, "pack") }
sub pp_join { maybe_targmy(@_, \&listop, "join") }
sub pp_splice { listop(@_, "splice") }
sub pp_push { maybe_targmy(@_, \&listop, "push") }
sub pp_unshift { maybe_targmy(@_, \&listop, "unshift") }
sub pp_reverse { listop(@_, "reverse") }
sub pp_warn { listop(@_, "warn") }
sub pp_die { listop(@_, "die") }
sub pp_return { listop(@_, "return", undef, 1) } # llafr does not apply
sub pp_open { listop(@_, "open") }
sub pp_pipe_op { listop(@_, "pipe") }
sub pp_tie { listop(@_, "tie") }
sub pp_binmode { listop(@_, "binmode") }
sub pp_dbmopen { listop(@_, "dbmopen") }
sub pp_sselect { listop(@_, "select") }
sub pp_select { listop(@_, "select") }
sub pp_read { listop(@_, "read") }
sub pp_sysopen { listop(@_, "sysopen") }
sub pp_sysseek { listop(@_, "sysseek") }
sub pp_sysread { listop(@_, "sysread") }
sub pp_syswrite { listop(@_, "syswrite") }
sub pp_send { listop(@_, "send") }
sub pp_recv { listop(@_, "recv") }
sub pp_seek { listop(@_, "seek") }
sub pp_fcntl { listop(@_, "fcntl") }
sub pp_ioctl { listop(@_, "ioctl") }
sub pp_flock { maybe_targmy(@_, \&listop, "flock") }
sub pp_socket { listop(@_, "socket") }
sub pp_sockpair { listop(@_, "socketpair") }
sub pp_bind { listop(@_, "bind") }
sub pp_connect { listop(@_, "connect") }
sub pp_listen { listop(@_, "listen") }
sub pp_accept { listop(@_, "accept") }
sub pp_shutdown { listop(@_, "shutdown") }
sub pp_gsockopt { listop(@_, "getsockopt") }
sub pp_ssockopt { listop(@_, "setsockopt") }
sub pp_chown { maybe_targmy(@_, \&listop, "chown") }
sub pp_unlink { maybe_targmy(@_, \&listop, "unlink") }
sub pp_chmod { maybe_targmy(@_, \&listop, "chmod") }
sub pp_utime { maybe_targmy(@_, \&listop, "utime") }
sub pp_rename { maybe_targmy(@_, \&listop, "rename") }
sub pp_link { maybe_targmy(@_, \&listop, "link") }
sub pp_symlink { maybe_targmy(@_, \&listop, "symlink") }
sub pp_mkdir { maybe_targmy(@_, \&listop, "mkdir") }
sub pp_open_dir { listop(@_, "opendir") }
sub pp_seekdir { listop(@_, "seekdir") }
sub pp_waitpid { maybe_targmy(@_, \&listop, "waitpid") }
sub pp_system { maybe_targmy(@_, \&listop, "system") }
sub pp_exec { maybe_targmy(@_, \&listop, "exec") }
sub pp_kill { maybe_targmy(@_, \&listop, "kill") }
sub pp_setpgrp { maybe_targmy(@_, \&listop, "setpgrp") }
sub pp_getpriority { maybe_targmy(@_, \&listop, "getpriority") }
sub pp_setpriority { maybe_targmy(@_, \&listop, "setpriority") }
sub pp_shmget { listop(@_, "shmget") }
sub pp_shmctl { listop(@_, "shmctl") }
sub pp_shmread { listop(@_, "shmread") }
sub pp_shmwrite { listop(@_, "shmwrite") }
sub pp_msgget { listop(@_, "msgget") }
sub pp_msgctl { listop(@_, "msgctl") }
sub pp_msgsnd { listop(@_, "msgsnd") }
sub pp_msgrcv { listop(@_, "msgrcv") }
sub pp_semget { listop(@_, "semget") }
sub pp_semctl { listop(@_, "semctl") }
sub pp_semop { listop(@_, "semop") }
sub pp_ghbyaddr { listop(@_, "gethostbyaddr") }
sub pp_gnbyaddr { listop(@_, "getnetbyaddr") }
sub pp_gpbynumber { listop(@_, "getprotobynumber") }
sub pp_gsbyname { listop(@_, "getservbyname") }
sub pp_gsbyport { listop(@_, "getservbyport") }
sub pp_syscall { listop(@_, "syscall") }

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
		return info_from_list($op, $self, [$keyword, '(', $text, ')'], '',
				      'glob_paren', $opts);
	    } else {
		return info_from_list($op, $self, [$keyword, $text], ' ',
				      'glob_space', $opts);
	    }
	} else {
	    return info_from_list($op, $self, ['<', $text, '>'], '', 'glob_angle', $opts);
	}
    }
    return info_from_list($op, $self, ['<', '>'], '', 'glob_angle', $opts);
}

# Truncate is special because OPf_SPECIAL makes a bareword first arg
# be a filehandle. This could probably be better fixed in the core
# by moving the GV lookup into ck_truc.

sub pp_truncate
{
    my($self, $op, $cx) = @_;
    my(@exprs);
    my $parens = ($cx >= 5) || $self->{'parens'};
    my $kid = $op->first->sibling;
    my $fh;
    if ($op->flags & OPf_SPECIAL) {
	# $kid is an OP_CONST
	$fh = $self->const_sv($kid)->PV;
    } else {
	$fh = $self->deparse($kid, 6, $op);
        $fh = "+$fh" if not $parens and substr($fh, 0, 1) eq "(";
    }
    my $len = $self->deparse($kid->sibling, 6, $op);
    my $name = $self->keyword('truncate');
    my $opts = {body => [$fh, $len]};
    my $args = "$fh->{text}, $len->{text}";
    if ($parens) {
	return info_from_list($op, $self, [$name, '(', $args, ')'], '',
			      'truncate_parens', $opts);
	return "$name($fh, $len)";
    } else {
	return info_from_list($op, $self, [$name, $args], '', 'truncate', $opts);
    }
}

sub is_ifelse_cont
{
    my $op = shift;
    return ($op->name eq "null" and class($op) eq "UNOP"
	    and $op->first->name =~ /^(and|cond_expr)$/
	    and is_scope($op->first->first->sibling));
}

sub for_loop {
    my $self = shift;
    my($op, $cx, $parent) = @_;
    my $init = $self->deparse($op, 1, $parent);
    my $s = $op->sibling;
    my $ll = $s->name eq "unstack" ? $s->sibling : $s->first->sibling;
    return $self->loop_common($ll, $cx, $init);
}

sub pp_leavetry {
    my ($self, $op, $cx) = @_;
    my $leave_info = $self->pp_leave($op, $cx);
    return info_from_list($op, $self, ['eval', '{\n\t"', $leave_info->{text}, "\n\b}"],
			  ' ', 'leavetry', {body=>[$leave_info]});
}

sub _op_is_or_was {
  my ($op, $expect_type) = @_;
  my $type = $op->type;
  return($type == $expect_type
         || ($type == OP_NULL && $op->targ == $expect_type));
}

sub padname {
    my $self = shift;
    my $targ = shift;
    return $self->padname_sv($targ)->PVX;
}

sub padany {
    my $self = shift;
    my $op = shift;
    return substr($self->padname($op->targ), 1); # skip $/@/%
}

sub pp_padsv {
    my $self = shift;
    my($op, $cx, $forbid_parens) = @_;
    return $self->maybe_my($op, $cx, $self->padname($op->targ),
			   $forbid_parens);
}

sub pp_padav { pp_padsv(@_) }
sub pp_padhv { pp_padsv(@_) }

my @threadsv_names = B::threadsv_names;
sub pp_threadsv {
    my $self = shift;
    my($op, $cx) = @_;
    return $self->maybe_local_str($op, $cx, "\$" .  $threadsv_names[$op->targ]);
}

sub gv_or_padgv {
    my $self = shift;
    my $op = shift;
    if (class($op) eq "PADOP") {
	return $self->padval($op->padix);
    } else { # class($op) eq "SVOP"
	return $op->gv;
    }
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

sub pp_gv
{
    my($self, $op, $cx) = @_;
    my $gv = $self->gv_or_padgv($op);
    return info_from_text($op, $self, $self->gv_name($gv),
			  'global variable', {});
}

sub pp_aelemfast_lex
{
    my($self, $op, $cx) = @_;
    my $name = $self->padname($op->targ);
    $name =~ s/^@/\$/;
    return info_from_list($op, $self, [$name, "[", ($op->private + $self->{'arybase'}), "]"],
		      '', 'pp_aelemfast_lex', {});
}

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

sub pp_rv2sv { maybe_local(@_, rv2x(@_, "\$")) }
sub pp_rv2hv { maybe_local(@_, rv2x(@_, "%")) }
sub pp_rv2gv { maybe_local(@_, rv2x(@_, "*")) }

# skip rv2av
sub pp_av2arylen {
    my $self = shift;
    my($op, $cx) = @_;
    if ($op->first->name eq "padav") {
	return $self->maybe_local_str($op, $cx, '$#' . $self->padany($op->first));
    } else {
	return $self->maybe_local($op, $cx,
				  $self->rv2x($op->first, $cx, '$#'));
    }
}

# skip down to the old, ex-rv2cv
sub pp_rv2cv {
    my ($self, $op, $cx) = @_;
    if (!null($op->first) && $op->first->name eq 'null' &&
	$op->first->targ == OP_LIST)
    {
	return $self->rv2x($op->first->first->sibling, $cx, "&")
    }
    else {
	return $self->rv2x($op, $cx, "")
    }
}

sub list_const($$$) {
    my $self = shift;
    my($op, $cx, @list) = @_;
    my @a = map $self->const($_, 6), @list;
    my @texts = $self->map_texts(\@a);
    my $type = 'list_const';
    my $prec = 6;
    if (@texts == 0) {
	return info_from_list($op, $self, ['(', ')'], '', 'list_const_null', {});
    } elsif (@texts == 1) {
	return info_from_text($op, $self, $texts[0], 'list_const_one',
	    {body => \@a});
    } elsif ( @texts > 2 and !grep(!/^-?\d+$/, @texts)) {
	# collapse (-1,0,1,2) into (-1..2)
	my ($s, $e) = @texts[0,-1];
	my $i = $s;
	unless (grep $i++ != $_, @texts) {
	    @texts = ($s, '..', $e);
	    $type = 'list_const_range';
	    $prec = 9;
	}
    }
    return info_from_list($op, $self, \@texts,  '', $type,
	{maybe_parens => [$self, $cx, $prec]});
}

sub pp_rv2av {
    my $self = shift;
    my($op, $cx) = @_;
    my $kid = $op->first;
    if ($kid->name eq "const") { # constant list
	my $av = $self->const_sv($kid);
	return $self->list_const($kid, $cx, $av->ARRAY);
    } else {
	# FIXME?
	return $self->maybe_local($op, $cx, $self->rv2x($op, $cx, "\@"));
    }
 }

sub elem_or_slice_array_name
{
    my $self = shift;
    my ($array, $left, $padname, $allow_arrow) = @_;

    if ($array->name eq $padname) {
	return $self->padany($array);
    } elsif (is_scope($array)) { # ${expr}[0]
	return "{" . $self->deparse($array, 0) . "}";
    } elsif ($array->name eq "gv") {
	($array, my $quoted) =
	    $self->stash_variable_name(
		$left eq '[' ? '@' : '%', $self->gv_or_padgv($array)
	    );
	if (!$allow_arrow && $quoted) {
	    # This cannot happen.
	    die "Invalid variable name $array for slice";
	}
	return $quoted ? "$array->" : $array;
    } elsif (!$allow_arrow || is_scalar $array) { # $x[0], $$x[0], ...
	return $self->deparse($array, 24)->{text};
    } else {
	return undef;
    }
}

sub elem_or_slice_single_index($$)
{
    my ($self, $idx, $parent) = @_;

    my $idx_info = $self->deparse($idx, 1, $parent);
    my $idx_str = $idx_info->{text};

    # Outer parens in an array index will confuse perl
    # if we're interpolating in a regular expression, i.e.
    # /$x$foo[(-1)]/ is *not* the same as /$x$foo[-1]/
    #
    # If $self->{parens}, then an initial '(' will
    # definitely be paired with a final ')'. If
    # !$self->{parens}, the misleading parens won't
    # have been added in the first place.
    #
    # [You might think that we could get "(...)...(...)"
    # where the initial and final parens do not match
    # each other. But we can't, because the above would
    # only happen if there's an infix binop between the
    # two pairs of parens, and *that* means that the whole
    # expression would be parenthesized as well.]
    #
    $idx_str =~ s/^\((.*)\)$/$1/ if $self->{'parens'};

    # Hash-element braces will autoquote a bareword inside themselves.
    # We need to make sure that C<$hash{warn()}> doesn't come out as
    # C<$hash{warn}>, which has a quite different meaning. Currently
    # B::Deparse will always quote strings, even if the string was a
    # bareword in the original (i.e. the OPpCONST_BARE flag is ignored
    # for constant strings.) So we can cheat slightly here - if we see
    # a bareword, we know that it is supposed to be a function call.
    #
    $idx_str =~ s/^([A-Za-z_]\w*)$/$1()/;

    return info_from_text($idx_info->{op}, $self, $idx_str,
			  'elem_or_slice_single_index',
			  {body => [$idx_info]});
}

sub elem
{
    my ($self, $op, $cx, $left, $right, $padname) = @_;
    my($array, $idx) = ($op->first, $op->first->sibling);

    my $idx_info = $self->elem_or_slice_single_index($idx, $op);
    my $opts = {body => [$idx_info]};

    unless ($array->name eq $padname) { # Maybe this has been fixed
	$opts->{other_ops} = [$array];
	$array = $array->first; # skip rv2av (or ex-rv2av in _53+)
    }
    my @texts = ();
    my $info;
    my $array_name=$self->elem_or_slice_array_name($array, $left, $padname, 1);
    if ($array_name) {
	if ($array_name !~ /->\z/) {
	    if ($array_name eq '#') {
		$array_name = '${#}';
	    }  else {
		$array_name = '$' . $array_name ;
	    }
	}
	push @texts, $array_name;
	push @texts, $left if $left;
	push @texts, $idx_info->{text}, $right;
	return info_from_list($op, $self, \@texts, '', 'elem', $opts)
    } else {
	# $x[20][3]{hi} or expr->[20]
	my $type;
	my $array_info = $self->deparse($array, 24, $op);
	push @{$info->{body}}, $array_info;
	@texts = ($array_info->{text});
	if (is_subscriptable($array)) {
	    push @texts, $left, $idx_info->{text}, $right;
	    $type = 'elem_no_arrow';
	} else {
	    push @texts, '->', $left, $idx_info->{text}, $right;
	    $type = 'elem_arrow';
	}
	return info_from_list($op, $self, \@texts, '', $type, $opts);
    }
    Carp::confess("unhandled condition in elem");
}

# a simplified version of elem_or_slice_array_name()
# for the use of pp_multideref

sub multideref_var_name($$$)
{
    my ($self, $gv, $is_hash) = @_;

    my ($name, $quoted) =
        $self->stash_variable_name( $is_hash  ? '%' : '@', $gv);
    return $quoted ? "$name->"
                   : $name eq '#'
                        ? '${#}'       # avoid ${#}[1] => $#[1]
                        : '$' . $name;
}

sub pp_multideref
{
    my($self, $op, $cx) = @_;
    my @texts = ();

    if ($op->private & OPpMULTIDEREF_EXISTS) {
        @texts = ($self->keyword("exists"), ' ');
    }
    elsif ($op->private & OPpMULTIDEREF_DELETE) {
        @texts = ($self->keyword("delete"), ' ')
    }
    elsif ($op->private & OPpLVAL_INTRO) {
        @texts = ($self->keyword("local"), ' ')
    }

    if ($op->first && ($op->first->flags & OPf_KIDS)) {
        # arbitrary initial expression, e.g. f(1,2,3)->[...]
	my $first = $self->deparse($op->first, 24, $op);
	push @texts, $first->{text};
    }

    my @items = $op->aux_list($self->{curcv});
    my $actions = shift @items;

    my $is_hash;
    my $derefs = 0;

    while (1) {
        if (($actions & MDEREF_ACTION_MASK) == MDEREF_reload) {
            $actions = shift @items;
            next;
        }

        $is_hash = (
	    ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_pop_rv2hv_helem
	    || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_gvsv_vivify_rv2hv_helem
	    || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_padsv_vivify_rv2hv_helem
	    || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_vivify_rv2hv_helem
	    || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_padhv_helem
	    || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_gvhv_helem
	    );

        if (   ($actions & MDEREF_ACTION_MASK) == MDEREF_AV_padav_aelem
	       || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_padhv_helem)
        {
            $derefs = 1;
            push @texts, '$' . substr($self->padname(shift @items), 1);
        }
        elsif (   ($actions & MDEREF_ACTION_MASK) == MDEREF_AV_gvav_aelem
		  || ($actions & MDEREF_ACTION_MASK) == MDEREF_HV_gvhv_helem)
        {
            $derefs = 1;
            push @texts, $self->multideref_var_name(shift @items, $is_hash);
        }
        else {
            if (   ($actions & MDEREF_ACTION_MASK) ==
		   MDEREF_AV_padsv_vivify_rv2av_aelem
		   || ($actions & MDEREF_ACTION_MASK) ==
		   MDEREF_HV_padsv_vivify_rv2hv_helem)
            {
                push @texts, $self->padname(shift @items);
            }
            elsif (   ($actions & MDEREF_ACTION_MASK) ==
		      MDEREF_AV_gvsv_vivify_rv2av_aelem
		      || ($actions & MDEREF_ACTION_MASK) ==
		      MDEREF_HV_gvsv_vivify_rv2hv_helem)
            {
                push @texts, $self->multideref_var_name(shift @items, $is_hash);
            }
            elsif (   ($actions & MDEREF_ACTION_MASK) ==
		      MDEREF_AV_pop_rv2av_aelem
		      || ($actions & MDEREF_ACTION_MASK) ==
		      MDEREF_HV_pop_rv2hv_helem)
            {
                if (   ($op->flags & OPf_KIDS)
		       && (   _op_is_or_was($op->first, OP_RV2AV)
			      || _op_is_or_was($op->first, OP_RV2HV))
		       && ($op->first->flags & OPf_KIDS)
		       && (   _op_is_or_was($op->first->first, OP_AELEM)
			      || _op_is_or_was($op->first->first, OP_HELEM))
                    )
                {
                    $derefs++;
                }
            }

            push(@texts, '->') if !$derefs++;
        }


        if (($actions & MDEREF_INDEX_MASK) == MDEREF_INDEX_none) {
            last;
        }

        push(@texts, $is_hash ? '{' : '[');

        if (($actions & MDEREF_INDEX_MASK) == MDEREF_INDEX_const) {
            my $key = shift @items;
            if ($is_hash) {
                push @texts, $self->const($key, $cx)->{text};
            }
            else {
                push @texts, $key;
            }
        }
        elsif (($actions & MDEREF_INDEX_MASK) == MDEREF_INDEX_padsv) {
            push @texts, $self->padname(shift @items);
	}
	elsif (($actions & MDEREF_INDEX_MASK) == MDEREF_INDEX_gvsv) {
	    push @texts,('$' .  ($self->stash_variable_name('$', shift @items))[0]);
	}

	push(@texts, $is_hash ? '}' : ']');

        if ($actions & MDEREF_FLAG_last) {
            last;
        }
        $actions >>= MDEREF_SHIFT;
    }

    return info_from_list($op, $self, \@texts, '', 'multideref', {});
}

sub pp_aelem { maybe_local(@_, elem(@_, "[", "]", "padav")) }
sub pp_helem { maybe_local(@_, elem(@_, "{", "}", "padhv")) }

sub pp_gelem
{
    my($self, $op, $cx) = @_;
    my($glob, $part) = ($op->first, $op->last);
    $glob = $glob->first; # skip rv2gv
    $glob = $glob->first if $glob->name eq "rv2gv"; # this one's a bug
    my $scope = is_scope($glob);
    $glob = $self->deparse($glob, 0);
    $part = $self->deparse($part, 1);
    return "*" . ($scope ? "{$glob}" : $glob) . "{$part}";
}

sub slice
{
    my ($self, $op, $cx, $left, $right, $regname, $padname) = @_;
    my $last;
    my(@elems, $kid, $array);
    if (class($op) eq "LISTOP") {
	$last = $op->last;
    } else { # ex-hslice inside delete()
	for ($kid = $op->first; !null $kid->sibling; $kid = $kid->sibling) {}
	$last = $kid;
    }
    $array = $last;
    $array = $array->first
	if $array->name eq $regname or $array->name eq "null";
    my $array_info = $self->elem_or_slice_array_name($array, $left, $padname, 0);
    $kid = $op->first->sibling; # skip pushmark

    if ($kid->name eq "list") {
	# skip list, pushmark
	$kid = $kid->first->sibling;
	for (; !null $kid; $kid = $kid->sibling) {
	    push @elems, $self->deparse($kid, 6, $op);
	}
    } else {
	@elems = ($self->elem_or_slice_single_index($kid, $op));
    }
    my $list = join(', ', map($_->{text}, @elems));
    my $lead = '@';
    $lead = '%' if $op->name =~ /^kv/i;
    my (@texts, $type);
    if ($array_info) {
	@texts = ($lead, $array_info, $left, $list, $right);
	$type='slice1';
    } else {
	@texts = ($lead, $left, $list, $right);
	$type='slice';
    }
    return info_from_list($op, $self, \@texts, '', $type, {body => \@elems});
}

sub pp_aslice   { maybe_local(@_, slice(@_, "[", "]", "rv2av", "padav")) }
sub pp_kvaslice {                 slice(@_, "[", "]", "rv2av", "padav")  }
sub pp_hslice   { maybe_local(@_, slice(@_, "{", "}", "rv2hv", "padhv")) }
sub pp_kvhslice {                 slice(@_, "{", "}", "rv2hv", "padhv")  }

sub pp_lslice
{
    my ($self, $op, $cs) = @_;
    my $idx = $op->first;
    my $list = $op->last;
    my(@elems, $kid);
    my $list_info = $self->deparse($list, 1, $op);
    my $idx_info = $self->deparse($idx, 1, $op);
    return info_from_list($op, $self, ['(', $list_info->{text}, ')', '[', $idx_info->{text}, ']'],
	'', 'lslice', {body=>[$list_info, $idx_info]});
}

sub _method
{
    my($self, $op, $cx) = @_;
    my @other_ops = ($op->first);
    my $kid = $op->first->sibling; # skip pushmark
    my($meth, $obj, @exprs);
    if ($kid->name eq "list" and B::Deparse::want_list $kid) {
	# When an indirect object isn't a bareword but the args are in
	# parens, the parens aren't part of the method syntax (the LLAFR
	# doesn't apply), but they make a list with OPf_PARENS set that
	# doesn't get flattened by the append_elem that adds the method,
	# making a (object, arg1, arg2, ...) list where the object
	# usually is. This can be distinguished from
	# '($obj, $arg1, $arg2)->meth()' (which is legal if $arg2 is an
	# object) because in the later the list is in scalar context
	# as the left side of -> always is, while in the former
	# the list is in list context as method arguments always are.
	# (Good thing there aren't method prototypes!)
	$meth = $kid->sibling;
	push  @other_ops, $kid->first;
	$kid = $kid->first->sibling; # skip pushmark
	$obj = $kid;
	$kid = $kid->sibling;
	for (; not null $kid; $kid = $kid->sibling) {
	    push @exprs, $kid;
	}
    } else {
	$obj = $kid;
	$kid = $kid->sibling;
	for (; !null ($kid->sibling) && $kid->name!~/^method(?:_named)?\z/;
	     $kid = $kid->sibling) {
	    push @exprs, $kid
	}
	$meth = $kid;
    }

    if ($meth->name eq "method_named") {
	$meth = $self->meth_sv($meth)->PV;
    } elsif ($meth->name eq "method_super") {
	$meth = "SUPER::".$self->meth_sv($meth)->PV;
    } elsif ($meth->name eq "method_redir") {
        $meth = $self->meth_rclass_sv($meth)->PV.'::'.$self->meth_sv($meth)->PV;
    } elsif ($meth->name eq "method_redir_super") {
        $meth = $self->meth_rclass_sv($meth)->PV.'::SUPER::'.
                $self->meth_sv($meth)->PV;
    } else {
	$meth = $meth->first;
	if ($meth->name eq "const") {
	    # As of 5.005_58, this case is probably obsoleted by the
	    # method_named case above
	    $meth = $self->const_sv($meth)->PV; # needs to be bare
	}
    }

    return {
	method => $meth,
	variable_method => ref($meth),
	object => $obj,
	args => \@exprs,
	other_ops => \@other_ops
    }, $cx;
}

sub e_method {
    my ($self, $op, $minfo, $cx) = @_;
    my $obj = $self->deparse($minfo->{object}, 24, $op);
    my @body = ($obj);
    my $other_ops = $minfo->{other_ops};

    my $meth_name = $minfo->{method};
    my $meth_info;
    if ($minfo->{variable_method}) {
	$meth_info = $self->deparse($meth_name, 1, $op);
	push @body, $meth_info;
    }
    my @args = map { $self->deparse($_, 6, $op) } @{$minfo->{args}};
    push @body, @args;
    my @args_texts = map $_->{text}, @args;
    my $args = join(", ", @args_texts);

    my $opts = {other_ops => $other_ops};
    my @texts = ();
    my $type;


    my $meth_object = $meth_info ? defined($meth_info) : $meth_name;
    if ($minfo->{object}->name eq 'scope' && B::Deparse::want_list $minfo->{object}) {
	# method { $object }
	# This must be deparsed this way to preserve list context
	# of $object.
	my $need_paren = $cx >= 6;
	if ($need_paren) {
	    @texts = ('(', $meth_object,  substr($obj,2),
		      $args, ')');
	    $type = 'e_method list ()';
	} else {
	    @texts = ($meth_object,  substr($obj,2), $args);
	    $type = 'e_method list, no ()';
	}
	return info_from_list($op, $self, \@texts, '', $type, $opts);
    }

    if (length $args) {
	@texts = ($obj, '->', $meth_object, '(', $args, ')');
	$type = 'e_method -> ()';
    } else {
	@texts = ($obj, '->', $meth_object);
	$type = 'e_method -> no ()';
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

# returns "&"  and the argument bodies if the prototype doesn't match the args,
# or ("", $args_after_prototype_demunging) if it does.
sub check_proto {
    my $self = shift;
    my $op = shift;
    return ('&', []) if $self->{'noproto'};
    my($proto, @args) = @_;
    my($arg, $real);
    my $doneok = 0;
    my @reals;
    # An unbackslashed @ or % gobbles up the rest of the args
    1 while $proto =~ s/(?<!\\)([@%])[^\]]+$/$1/;
    $proto =~ s/^\s*//;
    while ($proto) {
	$proto =~ s/^(\\?[\$\@&%*_]|\\\[[\$\@&%*]+\]|;)\s*//;
	my $chr = $1;
	if ($chr eq "") {
	    return ('&', []) if @args;
	} elsif ($chr eq ";") {
	    $doneok = 1;
	} elsif ($chr eq "@" or $chr eq "%") {
	    push @reals, map($self->deparse($_, 6), @args, $op);
	    @args = ();
	} else {
	    $arg = shift @args;
	    last unless $arg;
	    if ($chr eq "\$" || $chr eq "_") {
		if (B::Deparse::want_scalar $arg) {
		    push @reals, $self->deparse($arg, 6, $op);
		} else {
		    return ('&', []);
		}
	    } elsif ($chr eq "&") {
		if ($arg->name =~ /^(s?refgen|undef)$/) {
		    push @reals, $self->deparse($arg, 6, $op);
		} else {
		    return ('&', []);
		}
	    } elsif ($chr eq "*") {
		if ($arg->name =~ /^s?refgen$/
		    and $arg->first->first->name eq "rv2gv")
		  {
		      $real = $arg->first->first; # skip refgen, null
		      if ($real->first->name eq "gv") {
			  push @reals, $self->deparse($real, 6, $op);
		      } else {
			  push @reals, $self->deparse($real->first, 6, $op);
		      }
		  } else {
		      return ('&', []);
		  }
	    } elsif (substr($chr, 0, 1) eq "\\") {
		$chr =~ tr/\\[]//d;
		if ($arg->name =~ /^s?refgen$/ and
		    !null($real = $arg->first) and
		    ($chr =~ /\$/ && is_scalar($real->first)
		     or ($chr =~ /@/
			 && class($real->first->sibling) ne 'NULL'
			 && $real->first->sibling->name
			 =~ /^(rv2|pad)av$/)
		     or ($chr =~ /%/
			 && class($real->first->sibling) ne 'NULL'
			 && $real->first->sibling->name
			 =~ /^(rv2|pad)hv$/)
		     #or ($chr =~ /&/ # This doesn't work
		     #   && $real->first->name eq "rv2cv")
		     or ($chr =~ /\*/
			 && $real->first->name eq "rv2gv")))
		  {
		      push @reals, $self->deparse($real, 6, $op);
		  } else {
		      return ('&', []);
		  }
	    }
       }
    }
    return ('&', []) if $proto and !$doneok; # too few args and no ';'
    return ('&', []) if @args;               # too many args
    return ('', \@reals);
}

sub pp_enterwrite { unop(@_, "write") }

# Split a floating point number into an integer mantissa and a binary
# exponent. Assumes you've already made sure the number isn't zero or
# some weird infinity or NaN.
sub split_float {
    my($f) = @_;
    my $exponent = 0;
    if ($f == int($f)) {
	while ($f % 2 == 0) {
	    $f /= 2;
	    $exponent++;
	}
    } else {
	while ($f != int($f)) {
	    $f *= 2;
	    $exponent--;
	}
    }
    my $mantissa = sprintf("%.0f", $f);
    return ($mantissa, $exponent);
}

sub dq
{
    my ($self, $op, $parent) = @_;
    my $type = $op->name;
    my $info;
    if ($type eq "const") {
	return info_from_text($op, $self, '$[', 'dq_const_ary', {}) if $op->private & OPpCONST_ARYBASE;
	return info_from_text($op, $self,
			      B::Deparse::uninterp(B::Deparse::escape_str(B::Deparse::unback($self->const_sv($op)->as_string))),
			 'dq_const', {});
    } elsif ($type eq "concat") {
	my $first = $self->dq($op->first, $op);
	my $last  = $self->dq($op->last, $op);

	# Disambiguate "${foo}bar", "${foo}{bar}", "${foo}[1]", "$foo\::bar"
	($last =~ /^[A-Z\\\^\[\]_?]/ &&
	    $first =~ s/([\$@])\^$/${1}{^}/)  # "${^}W" etc
	    || ($last =~ /^[:'{\[\w_]/ && #'
		$first =~ s/([\$@])([A-Za-z_]\w*)$/${1}{$2}/);

	return info_from_list($op, $self, [$first->{text}, $last->{text}], '', 'dq_concat',
			      {body => [$first, $last]});
    } elsif ($type eq "join") {
	return $self->deparse($op->last, 26, $op); # was join($", @ary)
    } else {
	return $self->deparse($op, 26, $parent);
    }
    my $kid = $self->dq($op->first->sibling, $op);
    my $kid_text = $kid->{text};
    if ($type eq "uc") {
	$info = info_from_lists(['\U', $kid, '\E'], '', 'dq_uc', {});
    } elsif ($type eq "lc") {
	$info = info_from_lists(['\L', $kid, '\E'], '', 'dq_lc', {});
    } elsif ($type eq "ucfirst") {
	$info = info_from_lists(['\u', $kid, '\E'], '', 'dq_ucfirst', {});
    } elsif ($type eq "lcfirst") {
	$info = info_from_lists(['\l', $kid, '\E'], '', 'dq_lcfirst', {});
    } elsif ($type eq "quotemeta") {
	$info = info_from_lists(['\Q', $kid, '\E'], '', 'dq_quotemeta', {});
    } elsif ($type eq "fc") {
	$info = info_from_lists(['\F', $kid, '\E'], '', 'dq_fc', {});
    }
    $info->{body} = [$kid];
    return $info;
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

# OP_STRINGIFY is a listop, but it only ever has one arg
sub pp_stringify {
    my ($self, $op, $cx) = @_;
    my $kid = $op->first->sibling;
    my @other_ops = ();
    while ($kid->name eq 'null' && !null($kid->first)) {
        push(@other_ops, $kid);
	$kid = $kid->first;
    }
    my $info;
    if ($kid->name =~ /^(?:const|padsv|rv2sv|av2arylen|gvsv|multideref
			  |aelemfast(?:_lex)?|[ah]elem|join|concat)\z/x) {
	$info = maybe_targmy(@_, \&dquote);
    }
    else {
	# Actually an optimised join.
	my $info = listop(@_,"join");
	$info->{text} =~ s/join([( ])/join$1$self->{'ex_const'}, /;
    }
    push @{$info->{other_ops}}, @other_ops;
    return $info;
}


# tr/// and s/// (and tr[][], tr[]//, tr###, etc)
# note that tr(from)/to/ is OK, but not tr/from/(to)
sub double_delim {
    my($from, $to) = @_;
    my($succeed, $delim);
    if ($from !~ m[/] and $to !~ m[/]) {
	return "/$from/$to/";
    } elsif (($succeed, $from) = balanced_delim($from) and $succeed) {
	if (($succeed, $to) = balanced_delim($to) and $succeed) {
	    return "$from$to";
	} else {
	    for $delim ('/', '"', '#') { # note no "'" -- s''' is special
		return "$from$delim$to$delim" if index($to, $delim) == -1;
	    }
	    $to =~ s[/][\\/]g;
	    return "$from/$to/";
	}
    } else {
	for $delim ('/', '"', '#') { # note no '
	    return "$delim$from$delim$to$delim"
		if index($to . $from, $delim) == -1;
	}
	$from =~ s[/][\\/]g;
	$to =~ s[/][\\/]g;
	return "/$from/$to/";
    }
}

# Only used by tr///, so backslashes hyphens
sub pchr { # ASCII
    my($n) = @_;
    if ($n == ord '\\') {
	return '\\\\';
    } elsif ($n == ord "-") {
	return "\\-";
    } elsif ($n >= ord(' ') and $n <= ord('~')) {
	return chr($n);
    } elsif ($n == ord "\a") {
	return '\\a';
    } elsif ($n == ord "\b") {
	return '\\b';
    } elsif ($n == ord "\t") {
	return '\\t';
    } elsif ($n == ord "\n") {
	return '\\n';
    } elsif ($n == ord "\e") {
	return '\\e';
    } elsif ($n == ord "\f") {
	return '\\f';
    } elsif ($n == ord "\r") {
	return '\\r';
    } elsif ($n >= ord("\cA") and $n <= ord("\cZ")) {
	return '\\c' . chr(ord("@") + $n);
    } else {
	# return '\x' . sprintf("%02x", $n);
	return '\\' . sprintf("%03o", $n);
    }
}

sub collapse {
    my(@chars) = @_;
    my($str, $c, $tr) = ("");
    for ($c = 0; $c < @chars; $c++) {
	$tr = $chars[$c];
	$str .= pchr($tr);
	if ($c <= $#chars - 2 and $chars[$c + 1] == $tr + 1 and
	    $chars[$c + 2] == $tr + 2)
	{
	    for (; $c <= $#chars-1 and $chars[$c + 1] == $chars[$c] + 1; $c++)
	      {}
	    $str .= "-";
	    $str .= pchr($chars[$c]);
	}
    }
    return $str;
}

sub tr_decode_byte {
    my($table, $flags) = @_;
    my(@table) = unpack("s*", $table);
    splice @table, 0x100, 1;   # Number of subsequent elements
    my($c, $tr, @from, @to, @delfrom, $delhyphen);
    if ($table[ord "-"] != -1 and
	$table[ord("-") - 1] == -1 || $table[ord("-") + 1] == -1)
    {
	$tr = $table[ord "-"];
	$table[ord "-"] = -1;
	if ($tr >= 0) {
	    @from = ord("-");
	    @to = $tr;
	} else { # -2 ==> delete
	    $delhyphen = 1;
	}
    }
    for ($c = 0; $c < @table; $c++) {
	$tr = $table[$c];
	if ($tr >= 0) {
	    push @from, $c; push @to, $tr;
	} elsif ($tr == -2) {
	    push @delfrom, $c;
	}
    }
    @from = (@from, @delfrom);
    if ($flags & OPpTRANS_COMPLEMENT) {
	my @newfrom = ();
	my %from;
	@from{@from} = (1) x @from;
	for ($c = 0; $c < 256; $c++) {
	    push @newfrom, $c unless $from{$c};
	}
	@from = @newfrom;
    }
    unless ($flags & OPpTRANS_DELETE || !@to) {
	pop @to while $#to and $to[$#to] == $to[$#to -1];
    }
    my($from, $to);
    $from = collapse(@from);
    $to = collapse(@to);
    $from .= "-" if $delhyphen;
    return ($from, $to);
}

# XXX This doesn't yet handle all cases correctly either

sub tr_decode_utf8 {
    my($swash_hv, $flags) = @_;
    my %swash = $swash_hv->ARRAY;
    my $final = undef;
    $final = $swash{'FINAL'}->IV if exists $swash{'FINAL'};
    my $none = $swash{"NONE"}->IV;
    my $extra = $none + 1;
    my(@from, @delfrom, @to);
    my $line;
    foreach $line (split /\n/, $swash{'LIST'}->PV) {
	my($min, $max, $result) = split(/\t/, $line);
	$min = hex $min;
	if (length $max) {
	    $max = hex $max;
	} else {
	    $max = $min;
	}
	$result = hex $result;
	if ($result == $extra) {
	    push @delfrom, [$min, $max];
	} else {
	    push @from, [$min, $max];
	    push @to, [$result, $result + $max - $min];
	}
    }
    for my $i (0 .. $#from) {
	if ($from[$i][0] == ord '-') {
	    unshift @from, splice(@from, $i, 1);
	    unshift @to, splice(@to, $i, 1);
	    last;
	} elsif ($from[$i][1] == ord '-') {
	    $from[$i][1]--;
	    $to[$i][1]--;
	    unshift @from, ord '-';
	    unshift @to, ord '-';
	    last;
	}
    }
    for my $i (0 .. $#delfrom) {
	if ($delfrom[$i][0] == ord '-') {
	    push @delfrom, splice(@delfrom, $i, 1);
	    last;
	} elsif ($delfrom[$i][1] == ord '-') {
	    $delfrom[$i][1]--;
	    push @delfrom, ord '-';
	    last;
	}
    }
    if (defined $final and $to[$#to][1] != $final) {
	push @to, [$final, $final];
    }
    push @from, @delfrom;
    if ($flags & OPpTRANS_COMPLEMENT) {
	my @newfrom;
	my $next = 0;
	for my $i (0 .. $#from) {
	    push @newfrom, [$next, $from[$i][0] - 1];
	    $next = $from[$i][1] + 1;
	}
	@from = ();
	for my $range (@newfrom) {
	    if ($range->[0] <= $range->[1]) {
		push @from, $range;
	    }
	}
    }
    my($from, $to, $diff);
    for my $chunk (@from) {
	$diff = $chunk->[1] - $chunk->[0];
	if ($diff > 1) {
	    $from .= tr_chr($chunk->[0]) . "-" . tr_chr($chunk->[1]);
	} elsif ($diff == 1) {
	    $from .= tr_chr($chunk->[0]) . tr_chr($chunk->[1]);
	} else {
	    $from .= tr_chr($chunk->[0]);
	}
    }
    for my $chunk (@to) {
	$diff = $chunk->[1] - $chunk->[0];
	if ($diff > 1) {
	    $to .= tr_chr($chunk->[0]) . "-" . tr_chr($chunk->[1]);
	} elsif ($diff == 1) {
	    $to .= tr_chr($chunk->[0]) . tr_chr($chunk->[1]);
	} else {
	    $to .= tr_chr($chunk->[0]);
	}
    }
    #$final = sprintf("%04x", $final) if defined $final;
    #$none = sprintf("%04x", $none) if defined $none;
    #$extra = sprintf("%04x", $extra) if defined $extra;
    #print STDERR "final: $final\n none: $none\nextra: $extra\n";
    #print STDERR $swash{'LIST'}->PV;
    return (B::Deparse::escape_str($from), B::Deparse::escape_str($to));
}

sub pp_trans {
    my $self = shift;
    my($op, $cx) = @_;
    my($from, $to);
    my $class = class($op);
    my $priv_flags = $op->private;
    if ($class eq "PVOP") {
	($from, $to) = tr_decode_byte($op->pv, $priv_flags);
    } elsif ($class eq "PADOP") {
	($from, $to)
	  = tr_decode_utf8($self->padval($op->padix)->RV, $priv_flags);
    } else { # class($op) eq "SVOP"
	($from, $to) = tr_decode_utf8($op->sv->RV, $priv_flags);
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
    return info_from_text($op, $self, $info->{text} . 'r', 'pp_transr',
			  {body => [$info]});
}

sub re_dq_disambiguate {
    my ($first, $last) = @_;
    # Disambiguate "${foo}bar", "${foo}{bar}", "${foo}[1]"
    ($last =~ /^[A-Z\\\^\[\]_?]/ &&
	$first =~ s/([\$@])\^$/${1}{^}/)  # "${^}W" etc
	|| ($last =~ /^[{\[\w_]/ &&
	    $first =~ s/([\$@])([A-Za-z_]\w*)$/${1}{$2}/);
    return $first . $last;
}

# Like dq(), but different
sub re_dq {
    my $self = shift;
    my ($op, $extended) = @_;
    my ($re_dq_info, $fmt);

    my $type = $op->name;
    my ($re, @texts);
    my $opts = {};
    if ($type eq "const") {
	return info_from_text($op, $self, '$[', 're_dq_const', {})
	    if $op->private & OPpCONST_ARYBASE;
	my $unbacked = B::Deparse::re_unback($self->const_sv($op)->as_string);
	return B::Deparse::re_uninterp_extended(escape_extended_re($unbacked))
	    if $extended;
	return B::Deparse::re_uninterp(B::Deparse::escape_str($unbacked));
    } elsif ($type eq "concat") {
	my $first = $self->re_dq($op->first, $extended);
	my $last  = $self->re_dq($op->last,  $extended);
	return re_dq_disambiguate($first, $last);
    } elsif ($type eq "uc") {
	$re_dq_info = $self->re_dq($op->first->sibling, $extended);
	$fmt = '\U%c\E';
	$type .= ' uc';
    } elsif ($type eq "lc") {
	$re_dq_info = $self->re_dq($op->first->sibling, $extended);
	$fmt = '\L%c\E';
	$type .= ' lc';
    } elsif ($type eq "ucfirst") {
	$re_dq_info = $self->re_dq($op->first->sibling, $extended);
	$fmt = '\u%c';
	$type .= ' ucfirst';
    } elsif ($type eq "lcfirst") {
	$re_dq_info = $self->re_dq($op->first->sibling, $extended);
	$fmt = '\u%c';
	$type .= ' lcfirst';
    } elsif ($type eq "quotemeta") {
	$re = $self->re_dq($op->first->sibling, $extended);
	@texts = ['\Q', $re->{text},'\E'];
	$type .= ' quotemeta';
    } elsif ($type eq "fc") {
	$re = $self->re_dq($op->first->sibling, $extended);
	@texts = ['\F', $re->{text},'\E'];
	$type .= ' fc';
    } elsif ($type eq "join") {
	return $self->deparse($op->last, 26, $op); # was join($", @ary)
    } else {
	my $info = $self->deparse($op, 26, $op);
	$info->{type} = 're_dq';
	$info->{text} =~ s/^\$([(|)])\z/\${$1}/; # $( $| $) need braces
	return $info;
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

sub pure_string {
    my ($self, $op) = @_;
    return 0 if null $op;
    my $type = $op->name;

    if ($type eq 'const' || $type eq 'av2arylen') {
	return 1;
    }
    elsif ($type =~ /^(?:[ul]c(first)?|fc)$/ || $type eq 'quotemeta') {
	return $self->pure_string($op->first->sibling);
    }
    elsif ($type eq 'join') {
	my $join_op = $op->first->sibling;  # Skip pushmark
	return 0 unless $join_op->name eq 'null' && $join_op->targ == OP_RV2SV;

	my $gvop = $join_op->first;
	return 0 unless $gvop->name eq 'gvsv';
        return 0 unless '"' eq $self->gv_name($self->gv_or_padgv($gvop));

	return 0 unless ${$join_op->sibling} eq ${$op->last};
	return 0 unless $op->last->name =~ /^(?:[ah]slice|(?:rv2|pad)av)$/;
    }
    elsif ($type eq 'concat') {
	return $self->pure_string($op->first)
            && $self->pure_string($op->last);
    }
    elsif (is_scalar($op) || $type =~ /^[ah]elem$/) {
	return 1;
    }
    elsif ($type eq "null" and $op->can('first') and not null $op->first and
	  ($op->first->name eq "null" and $op->first->can('first')
	   and not null $op->first->first and
	   $op->first->first->name eq "aelemfast"
          or
	   $op->first->name =~ /^aelemfast(?:_lex)?\z/
	  )) {
	return 1;
    }
    else {
	return 0;
    }

    return 1;
}

sub regcomp
{
    my($self, $op, $cx, $extended) = @_;
    my @other_ops = ();
    my $kid = $op->first;
    if ($kid->name eq "regcmaybe") {
	push @other_ops, $kid;
	$kid = $kid->first;
    }
    if ($kid->name eq "regcreset") {
	push @other_ops, $kid;
	$kid = $kid->first;
    }
    if ($kid->name eq "null" and !null($kid->first)
	and $kid->first->name eq 'pushmark') {
	my $str = '';
	push(@other_ops, $kid);
	$kid = $kid->first->sibling;
	my @body = ();
	while (!null($kid)) {
	    my $first = $str;
	    my $last = $self->re_dq($kid, $extended);
	    push @body, $last;
	    push(@other_ops, $kid);
	    $str = re_dq_disambiguate($first,
				      $self->info2str($last));
	    $kid = $kid->sibling;
	}
	return (info_from_text($op, $self, $str, 'regcomp',
			       {other_ops => \@other_ops,
				body => \@body}), 1);
    }

    if ($self->pure_string($kid)) {
	my $info = $self->re_dq($kid, $extended);
	my @kid_ops = $info->{other_ops} ? @{$info->{other_ops}} : ();
	push @other_ops, @kid_ops;
	$info->{other_ops} = \@other_ops;
	return ($info, 1);
    }
    return ($self->deparse($kid, $cx, $op), 0, $op);
}

sub re_flags
{
    my ($self, $op) = @_;
    my $flags = '';
    my $pmflags = $op->pmflags;
    $flags .= "g" if $pmflags & PMf_GLOBAL;
    $flags .= "i" if $pmflags & PMf_FOLD;
    $flags .= "m" if $pmflags & PMf_MULTILINE;
    $flags .= "o" if $pmflags & PMf_KEEP;
    $flags .= "s" if $pmflags & PMf_SINGLELINE;
    $flags .= "x" if $pmflags & PMf_EXTENDED;
    $flags .= "p" if $pmflags & RXf_PMf_KEEPCOPY;
    if (my $charset = $pmflags & RXf_PMf_CHARSET) {
	# Hardcoding this is fragile, but B does not yet export the
	# constants we need.
	$flags .= qw(d l u a aa)[$charset >> 5]
    }
    # The /d flag is indicated by 0; only show it if necessary.
    elsif ($self->{hinthash} and
	     $self->{hinthash}{reflags_charset}
	    || $self->{hinthash}{feature_unicode}
	or $self->{hints} & $feature::hint_mask
	  && ($self->{hints} & $feature::hint_mask)
	       != $feature::hint_mask
	  && do {
		$self->{hints} & $feature::hint_uni8bit;
	     }
  ) {
	$flags .= 'd';
    }
    $flags;
}

# osmic acid -- see osmium tetroxide

my %matchwords;
map($matchwords{join "", sort split //, $_} = $_, 'cig', 'cog', 'cos', 'cogs',
    'cox', 'go', 'is', 'ism', 'iso', 'mig', 'mix', 'osmic', 'ox', 'sic',
    'sig', 'six', 'smog', 'so', 'soc', 'sog', 'xi');

sub matchop
{
    my($self, $op, $cx, $name, $delim) = @_;
    my $kid = $op->first;
    my $info = {};
    my @body = ();
    my ($binop, $var, $re_str) = ("", "", "");
    my $re;
    if ($op->flags & OPf_STACKED) {
	$binop = 1;
	$var = $self->deparse($kid, 20, $op);
	push @body, $var;
	$kid = $kid->sibling;
    }
    my $quote = 1;
    my $pmflags = $op->pmflags;
    my $extended = ($pmflags & PMf_EXTENDED);
    my $rhs_bound_to_defsv;
    if (null $kid) {
	my $unbacked = B::Deparse::re_unback($op->precomp);
	if ($extended) {
	    $re_str = B::Deparse::re_uninterp_extended(B::Deparse::escape_extended_re($unbacked));
	} else {
	    $re_str = B::Deparse::re_uninterp(B::Deparse::escape_str(B::Deparse::re_unback($op->precomp)));
	}
    } elsif ($kid->name ne 'regcomp') {
	carp("found ".$kid->name." where regcomp expected");
    } else {
	($re, $quote) = $self->regcomp($kid, 21, $extended);
	push @body, $re;
	$re_str = $re->{text};
	my $matchop = $kid->first;
	if ($matchop->name eq 'regcrest') {
	    $matchop = $matchop->first;
	}
	if ($matchop->name =~ /^(?:match|transr?|subst)\z/
	   && $matchop->flags & OPf_SPECIAL) {
	    $rhs_bound_to_defsv = 1;
	}
    }
    my $flags = '';
    $flags .= "c" if $pmflags & PMf_CONTINUE;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $matchwords{$flags} if $matchwords{$flags};

    if ($pmflags & PMf_ONCE) { # only one kind of delimiter works here
	$re_str =~ s/\?/\\?/g;
	$re_str = "?$re_str?";
    } elsif ($quote) {
	my $re = $self->single_delim($kid, $name, $delim, $re_str);
	push @body, $re;
	$re_str = $re->{text};
    }
    my $opts = {body => \@body};
    my @texts;
    $re_str .= $flags if $quote;
    my $type;
    if ($binop) {
	if ($rhs_bound_to_defsv) {
	    @texts = ($var->{text}, ' =~ ', "(", '$_', ' =~ ', $re_str, ')');
	} else {
	    @texts = ($var->{text}, ' =~ ', $re_str);
	}
	$opts->{maybe_parens} = [$self, $cx, 20];
	$type = 'matchop_binop';
    } else {
	@texts = ($re_str);
	$type = 'matchop_unnop';
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

sub pp_match { matchop(@_, "m", "/") }
sub pp_pushre { matchop(@_, "m", "/") }
sub pp_qr { matchop(@_, "qr", "") }

sub pp_runcv { unop(@_, "__SUB__"); }

sub pp_split {
    maybe_targmy(@_, \&split, "split");
}

sub split
{
    my($self, $op, $cx) = @_;
    my($kid, @exprs, $ary_info, $expr);
    my $ary = '';
    my @body = ();
    my @other_ops = ();
    $kid = $op->first;

    # For our kid (an OP_PUSHRE), pmreplroot is never actually the
    # root of a replacement; it's either empty, or abused to point to
    # the GV for an array we split into (an optimization to save
    # assignment overhead). Depending on whether we're using ithreads,
    # this OP* holds either a GV* or a PADOFFSET. Luckily, B.xs
    # figures out for us which it is.
    my $replroot = $kid->pmreplroot;
    my $gv = 0;
    my $stacked = $op->flags & OPf_STACKED;
    if (ref($replroot) eq "B::GV") {
	$gv = $replroot;
    } elsif (!ref($replroot) and $replroot > 0) {
	$gv = $self->padval($replroot);
    } elsif ($kid->targ) {
	$ary = $self->padname($kid->targ)
    } elsif ($stacked) {
	$ary_info = $self->deparse($op->last, 7, $op);
	push @body, $ary_info;
	$ary = $ary_info->{text};
    }
    $ary_info = $self->maybe_local(@_,
			      $self->stash_variable('@',
						     $self->gv_name($gv),
						     $cx))
	if $gv;

    # Skip the last kid when OPf_STACKED is set, since it is the array
    # on the left.
    for (; !null($stacked ? $kid->sibling : $kid); $kid = $kid->sibling) {
	push @exprs, $self->deparse($kid, 6, $op);
    }

    my $opts = {body => \@exprs};

    my @args_texts = map $_->{text}, @exprs;
    # handle special case of split(), and split(' ') that compiles to /\s+/
    # Under 5.10, the reflags may be undef if the split regexp isn't a constant
    # Under 5.17.5-5.17.9, the special flag is on split itself.
    $kid = $op->first;
    if ( $op->flags & OPf_SPECIAL ) {
	$exprs[0]->{text} = "' '";
    }

    my $sep = '';
    my $type;
    my @expr_texts;
    if ($ary) {
	@expr_texts = ("$ary", '=', join(', ', @args_texts));
	$sep = ' ';
	$type = 'split_array';
	$opts->{maybe_parens} = [$self, $cx, 7];
    } else {
	@expr_texts = ('split', '(', join(', ', @args_texts), ')');
	$type = 'split';

    }
    return info_from_list($op, $self, \@expr_texts, $sep, $type, $opts);
}

# Kind of silly, but we prefer, subst regexp flags joined together to
# make words. For example: s/a/b/xo => s/a/b/ox

# oxime -- any of various compounds obtained chiefly by the action of
# hydroxylamine on aldehydes and ketones and characterized by the
# bivalent grouping C=NOH [Webster's Tenth]

my %substwords;
map($substwords{join "", sort split //, $_} = $_, 'ego', 'egoism', 'em',
    'es', 'ex', 'exes', 'gee', 'go', 'goes', 'ie', 'ism', 'iso', 'me',
    'meese', 'meso', 'mig', 'mix', 'os', 'ox', 'oxime', 'see', 'seem',
    'seg', 'sex', 'sig', 'six', 'smog', 'sog', 'some', 'xi', 'rogue',
    'sir', 'rise', 'smore', 'more', 'seer', 'rome', 'gore', 'grim', 'grime',
    'or', 'rose', 'rosie');

sub pp_subst
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    my($binop, $var, $re, @other_ops) = ("", "", "", ());
    my @body = ();
    my ($repl, $repl_info);
    if ($op->flags & OPf_STACKED) {
	$binop = 1;
	$var = $self->deparse($kid, 20, $op);
	$kid = $kid->sibling;
    }
    my $flags = "";
    my $pmflags = $op->pmflags;
    if (null($op->pmreplroot)) {
	$repl = $kid;
	$kid = $kid->sibling;
    } else {
	push @other_ops, $op->pmreplroot;
	$repl = $op->pmreplroot->first; # skip substcont
    }
    while ($repl->name eq "entereval") {
	push @other_ops, $repl;
	$repl = $repl->first;
	    $flags .= "e";
    }
    {
	local $self->{in_subst_repl} = 1;
	if ($pmflags & PMf_EVAL) {
	    $repl_info = $self->deparse($repl->first, 0, $repl);
	} else {
	    $repl_info = $self->dq($repl);
	}
    }
    my $extended = ($pmflags & PMf_EXTENDED);
    if (null $kid) {
	my $unbacked = B::Deparse::re_unback($op->precomp);
	if ($extended) {
	    $re = B::Deparse::re_uninterp_extended(escape_extended_re($unbacked));
	}
	else {
	    $re = B::Deparse::re_uninterp(B::Deparse::escape_str($unbacked));
	}
    } else {
	my ($re_info, $junk) = $self->regcomp($kid, 1, $extended);
	push @body, $re_info;
	$re = $re_info->{text};
    }
    $flags .= "r" if $pmflags & PMf_NONDESTRUCT;
    $flags .= "e" if $pmflags & PMf_EVAL;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $substwords{$flags} if $substwords{$flags};
    my $info;
    push @body, $repl_info;
    my $repl_text = $repl_info->{text};
    my $opts = {body => \@body};
    $opts->{other_ops} = \@other_ops if @other_ops;
    if ($binop) {
	my @texts = ($var->{text}, " ", "=~", " ", "s", double_delim($re, $repl_text), $flags);
	$opts->{maybe_parens} = [$self, $cx, 20];
	return info_from_list($op, $self, \@texts, '', 'subst_binop', $opts);
    } else {
	return info_from_list($op, $self, ['s', double_delim($re, $repl_text)], '', 'subst',
			      $opts);
    }
    Carp::confess("unhandled condition in pp_subst");
}

sub pp_introcv
{
    my($self, $op, $cx) = @_;
    # For now, deparsing doesn't worry about the distinction between introcv
    # and clonecv, so pretend this op doesn't exist:
    return info_from_text($op, $self, '', 'introcv', {});
}

# Note 5.20 and up
sub pp_null
{
    my($self, $op, $cx) = @_;
    my $info;
    if (class($op) eq "OP") {
	if ($op->targ == B::Deparse::OP_CONST) {
	    # The Perl source constant value can't be recovered.
	    # We'll use the 'ex_const' value as a substitute
	    return info_from_text($op, $self, $self->{'ex_const'}, 'constant unrecoverable', {})
	} else {
	    return info_from_text($op, $self, '', 'constant ""', {});
	}
    } elsif (class ($op) eq "COP") {
	    return $self->pp_nextstate($op, $cx);
    }
    my $kid = $op->first;
    if ($op->first->name eq 'pushmark'
             or $op->first->name eq 'null'
                && $op->first->targ == B::Deparse::OP_PUSHMARK
	&& B::Deparse::_op_is_or_was($op, B::Deparse::OP_LIST)) {
	return $self->pp_list($op, $cx);
    } elsif ($kid->name eq "enter") {
	return $self->pp_leave($op, $cx);
    } elsif ($kid->name eq "leave") {
	return $self->pp_leave($kid, $cx);
    } elsif ($kid->name eq "scope") {
	return $self->pp_scope($kid, $cx);
    } elsif ($op->targ == B::Deparse::OP_STRINGIFY) {
	return $self->dquote($op, $cx);
    } elsif ($op->targ == B::Deparse::OP_GLOB) {
	my @other_ops = ($kid, $kid->first, $kid->first->first);
	my $info = $self->pp_glob(
	    $kid    # entersub
	    ->first    # ex-list
	    ->first    # pushmark
	    ->sibling, # glob
	    $cx
	    );
	push @{$info->{other_ops}}, @other_ops;
	return $info;
    } elsif (!null($kid->sibling) and
    	     $kid->sibling->name eq "readline" and
    	     $kid->sibling->flags & OPf_STACKED) {
    	my $lhs = $self->deparse($kid, 7, $op);
    	my $rhs = $self->deparse($kid->sibling, 7, $kid);
    	return $self->bin_info_join_maybe_parens($op, $lhs, $rhs, '=', " ", $cx, 7,
						 'readline');
    } elsif (!null($kid->sibling) and
    	     $kid->sibling->name eq "trans" and
    	     $kid->sibling->flags & OPf_STACKED) {
    	my $lhs = $self->deparse($kid, 20, $op);
    	my $rhs = $self->deparse($kid->sibling, 20, $op);
    	return $self->bin_info_join_maybe_parens($op, $lhs, $rhs, '=~', " ", $cx, 20,
	                                         'trans');
    } elsif ($op->flags & OPf_SPECIAL && $cx < 1 && !$op->targ) {
    	my $kid_info = $self->deparse($kid, $cx, $op);
	return info_from_list($op, $self, ['do', "{\n\t", $kid_info->{text},
			       "\n\b};"], '', 'null_special',
	    {body => [$kid_info]});
    } elsif (!null($kid->sibling) and
	     $kid->sibling->name eq "null" and
	     class($kid->sibling) eq "UNOP" and
	     $kid->sibling->first->flags & OPf_STACKED and
	     $kid->sibling->first->name eq "rcatline") {
	my $lhs = $self->deparse($kid, 18, $op);
	my $rhs = $self->deparse($kid->sibling, 18, $op);
	return $self->bin_info_join_maybe_parens($op, $lhs, $rhs, '=', " ", $cx, 20,
						 'null_rcatline');
    } else {
	return $self->deparse($kid, $cx, $op);
    }
    Carp::confess("unhandled condition in null");
}

sub pp_clonecv {
    my $self = shift;
    my($op, $cx) = @_;
    my $sv = $self->padname_sv($op->targ);
    my $name = substr $sv->PVX, 1; # skip &/$/@/%, like $self->padany
    return info_from_list($op, $self, ['my', 'sub', $name], ' ', 'clonev', {});
}

sub pp_padcv {
    my($self, $op, $cx) = @_;
    return info_from_text($op, $self, $self->padany($op), 'padcv', {});
}

unless (caller) {
    eval "use Data::Printer;";

    eval {
	sub fib($) {
	    my $x = shift;
	    return 1 if $x <= 1;
	    return(fib($x-1) + fib($x-2))
	}
	sub baz {
	    no strict;
	    CORE::wait;
	}
    };

    # use B::Deparse;
    # my $deparse_old = B::Deparse->new("-l", "-sC");
    # print $deparse_old->coderef2text(\&baz);
    # exit 1;
    my $deparse = __PACKAGE__->new("-l", "-c", "-sC");
    my $info = $deparse->coderef2info(\&baz);
    import Data::Printer colored => 0;
    Data::Printer::p($info);
    print "\n", '=' x 30, "\n";
    # print $deparse->indent($deparse->deparse_subname('fib')->{text});
    # print "\n", '=' x 30, "\n";
    # print "\n", '-' x 30, "\n";
    while (my($key, $value) = each %{$deparse->{optree}}) {
	my $parent_op_name = 'undef';
	if ($value->{parent}) {
	    my $parent = $deparse->{optree}{$value->{parent}};
	    $parent_op_name = $parent->{op}->name if $parent->{op};
	}
	printf("0x%x %s/%s of %s |\n%s",
	       $key, $value->{op}->name, $value->{type},
	       $parent_op_name, $deparse->indent($value->{text}));
	printf " ## line %s\n", $value->{cop} ? $value->{cop}->line : 'undef';
	print '-' x 30, "\n";
    }
}

# FIXME:
# Different in 5.20. Go over differences to see if okay in 5.20.
sub pp_chdir {
    my ($self, $op, $cx) = @_;
    if (($op->flags & (OPf_SPECIAL|OPf_KIDS)) == (OPf_SPECIAL|OPf_KIDS)) {
	my $kw = $self->keyword("chdir");
	my $kid = $self->const_sv($op->first)->PV;
	my $code = $kw
		 . ($cx >= 16 || $self->{'parens'} ? "($kid)" : " $kid");
	maybe_targmy(@_, sub { $_[3] }, $code);
    } else {
	maybe_targmy(@_, \&unop, "chdir")
    }
}

sub pp_entereval
{
    unop(
      @_,
      $_[1]->private & OPpEVAL_BYTES ? 'evalbytes' : "eval"
    )
}


# Not in Perl 5.20 and presumeably < 5.20. No harm in adding to 5.20?
*pp_ncomplement = *pp_complement;
sub pp_scomplement { maybe_targmy(@_, \&pfixop, "~.", 21) }

unless (caller) {
    eval "use Data::Printer;";

    eval {
	our($Fileparse_fstype);
	sub fib($) {
	    my $x = shift;
	    return 1 if $x <= 1;
	    return(fib($x-1) + fib($x-2))
	}
	sub fileparse {
	    no strict;
  # my($fullname,@suffices) = @_;

  my $tail   = '';
  $tail = $1 . $tail;

  # Ensure taint is propagated from the path to its pieces.
  $tail .= $taint;
  wantarray ? ($basename .= $taint, $dirpath .= $taint, $tail)
            : ($basename .= $taint);
}
	sub baz {
	    no strict;
	    if ($basename =~ s/$pat//s) {
	    }
	}
    };

    my $deparse = __PACKAGE__->new("-l", "-c");
    my $info = $deparse->coderef2info(\&fileparse);
    # my $info = $deparse->coderef2info(\&baz);
    import Data::Printer colored => 0;
    Data::Printer::p($info);
    print "\n", '=' x 30, "\n";
    # print $deparse->indent($deparse->deparse_subname('fib')->{text});
    # print "\n", '=' x 30, "\n";
    # print "\n", '-' x 30, "\n";
    while (my($key, $value) = each %{$deparse->{optree}}) {
	my $parent_op_name = 'undef';
	if ($value->{parent}) {
	    my $parent = $deparse->{optree}{$value->{parent}};
	    $parent_op_name = $parent->{op}->name if $parent->{op};
	}
	if (eval{$value->{op}->name}) {
	    printf("0x%x %s/%s of %s |\n%s",
		   $key, $value->{op}->name, $value->{type},
		   $parent_op_name, $deparse->indent($value->{text}));
	} else {
	    printf("0x%x %s of %s |\n%s",
		   $key, $value->{type},
		   $parent_op_name, $deparse->indent($value->{text}));
	}
	printf " ## line %s\n", $value->{cop} ? $value->{cop}->line : 'undef';
	print '-' x 30, "\n";
    }
    # use B::Deparse;
    # my $deparse_old = B::Deparse->new("-l", "-sC");
    # print $deparse_old->coderef2text(\&baz);
}

1;
