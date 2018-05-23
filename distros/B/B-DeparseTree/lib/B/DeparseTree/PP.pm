# Common PP opcodes. Specifc Perl versions can override these.

# Copyright (c) 2015, 2018 Rocky Bernstein
#
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

use B::DeparseTree::Common;
use B::DeparseTree::Node;
use B::Deparse;

*is_ifelse_cont = *B::Deparse::is_ifelse_cont;
*real_negate = *B::Deparse::real_negate;
*pp_negate = *B::Deparse::pp_negate;
*pp_i_negate = *B::Deparse::pp_i_negate;

use B qw(
    class
    OPf_MOD OPpENTERSUB_AMPER
    OPf_SPECIAL
    OPf_STACKED
    OPpEXISTS_SUB
    SVf_POK
    SVf_ROK
);

our($VERSION, @EXPORT, @ISA);
$VERSION = '1.0.0';

@ISA = qw(Exporter B::Deparse);
@EXPORT = qw(

    pp_and
    pp_chomp
    pp_chop
    pp_complement
    pp_cond_expr
    pp_const
    pp_dbstate
    pp_defined
    pp_dor
    pp_egrent pp_ehostent pp_enetent
    pp_entersub
    pp_eprotoent pp_epwent pp_eservent
    pp_exists
    pp_fork pp_getlogin pp_ggrent
    pp_getppid
    pp_ghostent pp_gnetent pp_gprotoent
    pp_gpwent pp_grepstart pp_gservent
    pp_grepwhile
    pp_i_negate
    pp_i_predec
    pp_i_preinc
    pp_leave
    pp_leaveloop
    pp_lineseq
    pp_list
    pp_mapstart
    pp_mapwhile
    pp_negate
    pp_nextstate
    pp_null
    pp_once
    pp_or
    pp_pos
    pp_postdec
    pp_postinc
    pp_predec
    pp_preinc
    pp_print
    pp_prtf
    pp_rand
    pp_ref
    pp_repeat
    pp_say
    pp_schomp
    pp_schop
    pp_scope
    pp_setstate
    pp_sgrent
    pp_sort
    pp_spwent
    pp_srand
    pp_stub
    pp_study
    pp_substr
    pp_symlink
    pp_time
    pp_tms
    pp_undef
    pp_wait
    pp_wantarray
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

sub pp_chomp { maybe_targmy(@_, \&unop, "chomp") }
sub pp_chop { maybe_targmy(@_, \&unop, "chop") }
sub pp_defined { unop(@_, "defined") }
sub pp_egrent { baseop(@_, "endgrent") }
sub pp_ehostent { baseop(@_, "endhostent") }
sub pp_enetent { baseop(@_, "endnetent") }
sub pp_eprotoent { baseop(@_, "endprotoent") }
sub pp_epwent { baseop(@_, "endpwent") }
sub pp_eservent { baseop(@_, "endservent") }
sub pp_fork { baseop(@_, "fork") }
sub pp_getlogin { baseop(@_, "getlogin") }
sub pp_ggrent { baseop(@_, "getgrent") }
sub pp_ghostent { baseop(@_, "gethostent") }
sub pp_gnetent { baseop(@_, "getnetent") }
sub pp_gprotoent { baseop(@_, "getprotoent") }
sub pp_gpwent { baseop(@_, "getpwent") }
sub pp_grepstart { baseop(@_, "grep") }
sub pp_gservent { baseop(@_, "getservent") }
sub pp_leave { scopeop(1, @_); }
sub pp_leaveloop { shift->loop_common(@_, undef); }
sub pp_lineseq { scopeop(0, @_); }

sub pp_list
{
    my($self, $op, $cx) = @_;
    my($expr, @exprs);

    my $other_op = $op->first;
    my $kid = $op->first->sibling; # skip a pushmark

    if (class($kid) eq 'NULL') {
	return info_from_text($op, $self, '', 'list_null',
			      {other_ops => [$other_op]});
    }
    my $lop;
    my $local = "either"; # could be local(...), my(...), state(...) or our(...)
    for ($lop = $kid; !null($lop); $lop = $lop->sibling) {
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
	my @other_ops = $info->{other_ops} ? @{$info->{other_ops}} : ();
	push @other_ops, $other_op;
	$info->{other_ops} = \@other_ops;
	return $info;
    }

    for (; !null($kid); $kid = $kid->sibling) {
	if ($local) {
	    if (class($kid) eq "UNOP" and $kid->first->name eq "gvsv") {
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
	return $self->info_from_template("$local list", $op,
					 "$local(%C)", [[0, $#exprs, ', ']],
					 \@exprs);

    } else {
	return $self->info_from_template("list", $op,
					 "%C", [[0, $#exprs, ', ']],
					 \@exprs,
					 {maybe_parens => [$self, $cx, 6]});
    }
}


sub pp_mapstart { baseop(@_, "map") }
sub pp_ref { unop(@_, "ref") }
sub pp_schomp { maybe_targmy(@_, \&unop, "chomp") }
sub pp_schop { maybe_targmy(@_, \&unop, "chop") }
sub pp_scope { scopeop(0, @_); }
sub pp_sgrent { baseop(@_, "setgrent") }
sub pp_spwent { baseop(@_, "setpwent") }
sub pp_srand { unop(@_, "srand") }
sub pp_study { unop(@_, "study") }
sub pp_tms { baseop(@_, "times") }
sub pp_undef { unop(@_, "undef") }
sub pp_wantarray { baseop(@_, "wantarray") }

# Notice how subs and formats are inserted between statements here;
# also $[ assignments and pragmas.
sub pp_nextstate {
    my $self = shift;
    my($op, $cx) = @_;
    $self->{'curcop'} = $op;
    my @texts;
    my $opts = {};
    my @args_spec = ();
    my $fmt = '%;';
    push @texts, $self->cop_subs($op);
    if (@texts) {
	# Special marker to swallow up the semicolon
	$opts->{'omit_next_semicolon'} = 1;
    }

    my $stash = $op->stashpv;
    if ($stash ne $self->{'curstash'}) {
	push @texts, $self->keyword("package") . " $stash;";
	$self->{'curstash'} = $stash;
    }

    if (OPpCONST_ARYBASE && $self->{'arybase'} != $op->arybase) {
	push @texts, '$[ = '. $op->arybase .";";
	$self->{'arybase'} = $op->arybase;
    }

    my $warnings = $op->warnings;
    my $warning_bits;
    if ($warnings->isa("B::SPECIAL") && $$warnings == 4) {
	$warning_bits = $warnings::Bits{"all"} & WARN_MASK;
    }
    elsif ($warnings->isa("B::SPECIAL") && $$warnings == 5) {
        $warning_bits = $warnings::NONE;
    }
    elsif ($warnings->isa("B::SPECIAL")) {
	$warning_bits = undef;
    }
    else {
	$warning_bits = $warnings->PV & WARN_MASK;
    }

    if (defined ($warning_bits) and
       !defined($self->{warnings}) || $self->{'warnings'} ne $warning_bits) {
	my @warnings = $self->declare_warnings($self->{'warnings'}, $warning_bits);
	foreach my $warning (@warnings) {
	    push @texts, $warning;
	}
    	$self->{'warnings'} = $warning_bits;
    }

    my $hints = $] < 5.008009 ? $op->private : $op->hints;
    my $old_hints = $self->{'hints'};
    if ($self->{'hints'} != $hints) {
	my @hints = $self->declare_hints($self->{'hints'}, $hints);
	foreach my $hint (@hints) {
	    push @texts, $hint;
	}
	$self->{'hints'} = $hints;
    }

    my $newhh;
    if ($] > 5.009) {
	$newhh = $op->hints_hash->HASH;
    }

    if ($] >= 5.015006) {
	# feature bundle hints
	my $from = $old_hints & $feature::hint_mask;
	my $to   = $    hints & $feature::hint_mask;
	if ($from != $to) {
	    if ($to == $feature::hint_mask) {
		if ($self->{'hinthash'}) {
		    delete $self->{'hinthash'}{$_}
			for grep /^feature_/, keys %{$self->{'hinthash'}};
		}
		else { $self->{'hinthash'} = {} }
		$self->{'hinthash'}
		    = _features_from_bundle($from, $self->{'hinthash'});
	    }
	    else {
		my $bundle =
		    $feature::hint_bundles[$to >> $feature::hint_shift];
		$bundle =~ s/(\d[13579])\z/$1+1/e; # 5.11 => 5.12
		push @texts,
		    $self->keyword("no") . " feature ':all'",
		    $self->keyword("use") . " feature ':$bundle'";
	    }
	}
    }

    if ($] > 5.009) {
	# FIXME use format specifiers
	my @hints = $self->declare_hinthash(
	    $self->{'hinthash'}, $newhh, 0, $self->{hints});
	foreach my $hint (@hints) {
	    push @texts, $hint;
	}
	$self->{'hinthash'} = $newhh;
    }


    # This should go after of any branches that add statements, to
    # increase the chances that it refers to the same line it did in
    # the original program.
    if ($self->{'linenums'} && $cx != .5) { # $cx == .5 means in a format
	my $line = sprintf("\n# line %s '%s'", $op->line, $op->file);
	$line .= sprintf(" 0x%x", $$op) if $self->{'opaddr'};
	$opts->{'omit_next_semicolon'} = 1;
	push @texts, $line;
    }

    if ($op->label) {
	$fmt .= "%|%c\n";
	push @args_spec, scalar(@args_spec);
	push @texts, $op->label . ": " ;
    }

    return $self->info_from_template("nextstate", $op, $fmt,
				     \@args_spec, \@texts, $opts);
}

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
    unless ($cx < 1 and (is_scope($true) and $true->name ne "null") and
	    (is_scope($false) || is_ifelse_cont($false))
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
    for ($i=0; !null($false) and is_ifelse_cont($false); $i++) {
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
    if (!null($false)) {
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
        return info_from_text($op, $self, '$[', 'const_ary', {});
    }
    # if ($op->private & OPpCONST_BARE) { # trouble with '=>' autoquoting
    # 	return $self->const_sv($op)->PV;
    # }
    my $sv = $self->const_sv($op);
    return $self->const($sv, $cx);;
}

sub pp_dbstate { pp_nextstate(@_) }

sub pp_entersub
{
    my($self, $op, $cx) = @_;
    return $self->e_method($op, $self->_method($op, $cx))
        unless null $op->first->sibling;
    my $prefix = "";
    my $amper = "";
    my($kid, @exprs);
    if ($op->flags & OPf_SPECIAL && !($op->flags & OPf_MOD)) {
	$prefix = "do ";
    } elsif ($op->private & OPpENTERSUB_AMPER) {
	$amper = "&";
    }
    $kid = $op->first;

    my $other_ops = [$kid, $kid->first];
    $kid = $kid->first->sibling; # skip ex-list, pushmark

    for (; not null $kid->sibling; $kid = $kid->sibling) {
	push @exprs, $kid;
    }
    my ($simple, $proto, $subname_info) = (0, undef, undef);
    if (is_scope($kid)) {
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
    } elsif (is_scalar ($kid->first) && $kid->first->name ne 'rv2cv') {
	$amper = "&";
	$subname_info = $self->deparse($kid, 24, $op);
    } else {
	$prefix = "";
	my $arrow = is_subscriptable($kid->first) || $kid->first->name eq "padcv" ? "" : "->";
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

    my (@texts, @body, $type);
    @body = ();
    if ($declared and defined $proto and not $amper) {
	my $args;
	($amper, $args) = $self->check_proto($op, $proto, @exprs);
	if ($amper eq "&") {
	    @body = map($self->deparse($_, 6, $op), @exprs);
	} else {
	    @body = @$args if @$args;
	}
    } else {
	@body  = map($self->deparse($_, 6, $op), @exprs);
    }

    if ($prefix or $amper) {
	if ($sub_name eq '&') {
	    # &{&} cannot be written as &&
	    $subname_info->{texts} = ["{", @{$subname_info->{texts}}, "}"];
	    $subname_info->{text} = join('', $subname_info->{texts});
	}
	if ($op->flags & OPf_STACKED) {
	    $type = 'prefix- or &-stacked call()';
	    @texts = ($prefix, $amper, $subname_info, "(", $self->combine2str(', ', \@body), ")");
	} else {
	    $type = 'prefix or &- call';
	    @texts = ($prefix, $amper, $subname_info);
	}
    } else {
	# It's a syntax error to call CORE::GLOBAL::foo with a prefix,
	# so it must have been translated from a keyword call. Translate
	# it back.
	$subname_info->{text} =~ s/^CORE::GLOBAL:://;
	my $dproto = defined($proto) ? $proto : "undefined";
        if (!$declared) {
	    $type = 'undeclared call';
	    @texts = dedup_parens_func($self, $subname_info, \@body);
	} elsif ($dproto =~ /^\s*\z/) {
	    $type = 'call no protype';
	    @texts = ($subname_info);
	} elsif ($dproto eq "\$" and is_scalar($exprs[0])) {
	    $type = 'call - $ prototype';
	    # is_scalar is an excessively conservative test here:
	    # really, we should be comparing to the precedence of the
	    # top operator of $exprs[0] (ala unop()), but that would
	    # take some major code restructuring to do right.
	    @texts = $self->maybe_parens_func($sub_name, $self->combine2str(', ', \@body), $cx, 16);
	} elsif ($dproto ne '$' and defined($proto) || $simple) { #'
	    $type = 'call with prototype';
	    @texts = $self->maybe_parens_func($sub_name, $self->combine2str(', ', \@body), $cx, 5);
	} else {
	    $type = 'call';
	    @texts = dedup_parens_func($self, $subname_info, \@body);
	}
    }
    my $info = B::DeparseTree::Node->new($op, $self, \@texts,
					 '', $type,
					 {other_ops => $other_ops});
    return $info;
}

sub pp_once
{
    my ($self, $op, $cx) = @_;
    my $cond = $op->first;
    my $true = $cond->sibling;

    return $self->deparse($true, $cx);
}

sub pp_print { indirop(@_, "print") }
sub pp_prtf { indirop(@_, "printf") }

sub pp_rand { maybe_targmy(@_, \&unop, "rand") }

# 'x' is weird when the left arg is a list
sub pp_repeat {
    my $self = shift;
    my($op, $cx) = @_;
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    my $prec = 19;
    my $other_ops = undef;
    if ($op->flags & OPf_STACKED) {
	$eq = "=";
	$prec = 7;
    }
    my @exprs = ();
    my ($left_info, @body);
    if (null($right)) {
	# list repeat; count is inside left-side ex-list
	$other_ops = [$left->first];
	my $kid = $left->first->sibling; # skip pushmark
	for (my $i=0; !null($kid->sibling); $kid = $kid->sibling) {
	    my $expr = $self->deparse($kid, 6, $op);
	    push @exprs, $expr;
	}
	$right = $kid;
	@body = @exprs;
	$left_info = info_from_list($op, $self,
				    ["(", @exprs, ")"], '', 'repeat_left', {});
    } else {
	$left_info = $self->deparse_binop_left($op, $left, $prec);
    }
    my $right_info  = $self->deparse_binop_right($op, $right, $prec);
    my $texts = [$left_info, "x$eq", $right_info];
    my $info = info_from_list($op, $self, $texts, ' ', 'repeat',
			      {maybe_parens => [$self, $cx, $prec]});
    $info->{other_ops} = $other_ops if $other_ops;
    return $info
}

sub pp_say  { indirop(@_, "say") }
sub pp_srand { unop(@_, "srand") }
sub pp_setstate { pp_nextstate(@_) }
sub pp_sort { indirop(@_, "sort") }

sub pp_or  { logop(@_, "or",  2, "||", 10, "unless") }
sub pp_dor { logop(@_, "//", 10) }

# xor is syntactically a logop, but it's really a binop (contrary to
# old versions of opcode.pl). Syntax is what matters here.
sub pp_xor { logop(@_, "xor", 2, "",   0,  "") }

sub pp_mapwhile { mapop(@_, "map") }
sub pp_grepwhile { mapop(@_, "grep") }

sub pp_complement { maybe_targmy(@_, \&pfixop, "~", 21) }
sub pp_getppid { maybe_targmy(@_, \&baseop, "getppid") }
sub pp_postdec { maybe_targmy(@_, \&pfixop, "--", 23, POSTFIX) }
sub pp_postinc { maybe_targmy(@_, \&pfixop, "++", 23, POSTFIX) }
sub pp_time { maybe_targmy(@_, \&baseop, "time") }
sub pp_wait { maybe_targmy(@_, \&baseop, "wait") }

sub pp_preinc { pfixop(@_, "++", 23) }
sub pp_predec { pfixop(@_, "--", 23) }
sub pp_i_preinc { pfixop(@_, "++", 23) }
sub pp_i_predec { pfixop(@_, "--", 23) }

sub pp_substr {
    my ($self,$op,$cx) = @_;
    if ($op->private & B::Deparse::OPpSUBSTR_REPL_FIRST) {
	my $left = listop($self, $op, 7, "substr", $op->first->sibling->sibling);
	my $right = $self->deparse($op->first->sibling, 7, $op);
	return info_from_list($op, $self,[$left, '=', $right], ' ',
			      'substr_repl_first', {});
    }
    return maybe_local(@_, listop(@_, "substr"))
}
# FIXME:
# Different between 5.20 and 5.20. We've used 5.22 tough
# Go over and make sure this is okay.
sub pp_stub {
    my ($self, $op) = @_;
    info_from_text($op, $self, "()", 'stub', {})
};

sub pp_symlink { maybe_targmy(@_, \&listop, "symlink") }

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
