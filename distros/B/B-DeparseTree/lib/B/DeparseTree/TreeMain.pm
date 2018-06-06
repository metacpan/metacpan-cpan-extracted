# Copyright (c) 2015-2018 Rocky Bernstein
# Copyright (c) 1998-2000, 2002, 2003, 2004, 2005, 2006 Stephen McCamant.

# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module B::Deparse by Stephen McCamant.
# It has been extended save tree structure, and is addressible
# by opcode address.

# B::Parse in turn is based on the module of the same name by Malcolm Beattie,
# but essentially none of his code remains.

# The is the main entrypoint for DeparseTree objects and routines.
# In the future there may be a StringMain which is like this
# but doesn't save copious tree information but instead just gathers
# strings in the same way B::Deparse does.
use strict; use warnings;

package B::DeparseTree;

use B qw(class
         CVf_LVALUE
         CVf_METHOD
         OPf_KIDS
         OPf_SPECIAL
         OPpLVAL_INTRO
         OPpTARGET_MY
         SVf_IOK
         SVf_NOK
         SVf_POK
         SVf_ROK
         SVs_RMG
         SVs_SMG
         main_cv main_root main_start
         opnumber
         perlstring
         svref_2object
         );

use Carp;
use B::Deparse;
use B::DeparseTree::PP_OPtable;
use B::DeparseTree::SyntaxTree;

# Copy unchanged functions from B::Deparse
*find_scope_en = *B::Deparse::find_scope_en;
*find_scope_st = *B::Deparse::find_scope_st;
*gv_name = *B::Deparse::gv_name;
*lex_in_scope = *B::Deparse::lex_in_scope;
*padname = *B::Deparse::padname;
*rv2gv_or_string = *B::Deparse::rv2gv_or_string;
*stash_subs = *B::Deparse::stash_subs;
*stash_variable = *B::Deparse::stash_variable;

our($VERSION, @EXPORT, @ISA);
$VERSION = '3.2.0';
@ISA = qw(Exporter);
@EXPORT = qw(
    %globalnames
    %ignored_hints
    %rev_feature
    WARN_MASK
    coderef2info
    coderef2text
    const
    declare_hinthash
    declare_hints
    declare_warnings
    deparse_sub($$$$)
    deparse_subname($$)
    new
    next_todo
    pragmata
    print_protos
    seq_subs
    style_opts
    );

use Config;
my $is_cperl = $Config::Config{usecperl};

my $module;
if ($] >= 5.016 and $] < 5.018) {
    # 5.16 and 5.18 are the same for now
    $module = "P518";
} elsif ($] >= 5.018 and $] < 5.020) {
    $module = "P518";
} elsif ($] >= 5.020 and $] < 5.022) {
    $module = "P520";
} elsif ($] >= 5.022 and $] < 5.024) {
    $module = "P522";
} elsif ($] >= 5.024 and $] < 5.026) {
    $module = "P524";
} elsif ($] >= 5.026) {
    $module = "P526";
} else {
    die "Can only handle Perl 5.16..5.26";
}

$module .= 'c' if $is_cperl;
@ISA = ("Exporter", "B::DeparseTree::$module");

require "B/DeparseTree/${module}.pm";

# The BEGIN {} is used here because otherwise this code isn't executed
# when you run B::Deparse on itself.
my %globalnames;
BEGIN { map($globalnames{$_}++, "SIG", "STDIN", "STDOUT", "STDERR", "INC",
	    "ENV", "ARGV", "ARGVOUT", "_"); }

my $max_prec;
BEGIN { $max_prec = int(0.999 + 8*length(pack("F", 42))*log(2)/log(10)); }

BEGIN {
    # List version-specific constants here.
    # Easiest way to keep this code portable between version looks to
    # be to fake up a dummy constant that will never actually be true.
    foreach (qw(OPpSORT_INPLACE OPpSORT_DESCEND OPpITER_REVERSED
                OPpCONST_NOVER OPpPAD_STATE PMf_SKIPWHITE RXf_SKIPWHITE
		RXf_PMf_CHARSET RXf_PMf_KEEPCOPY
		CVf_LOCKED OPpREVERSE_INPLACE OPpSUBSTR_REPL_FIRST
		PMf_NONDESTRUCT OPpCONST_ARYBASE OPpEVAL_BYTES)) {
	eval { import B $_ };
	no strict 'refs';
	*{$_} = sub () {0} unless *{$_}{CODE};
    }
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{'cuddle'} = " ";   #\n%| is another alternative
    $self->{'curcop'} = undef;
    $self->{'curstash'} = "main";
    $self->{'ex_const'} = "'?unrecoverable constant?'";
    $self->{'expand'} = 0;
    $self->{'files'} = {};

    # How many spaces per indent nesting?
    $self->{'indent_size'} = 4;

    $self->{'opaddr'} = 0;
    $self->{'linenums'} = 0;
    $self->{'parens'} = 0;
    $self->{'subs_todo'} = [];
    $self->{'unquote'} = 0;
    $self->{'use_dumper'} = 0;

    # Compress spaces with tabs? 1 tab = 8 spaces
    $self->{'use_tabs'} = 0;

    # Indentation level
    $self->{'level'} = 0;

    $self->{'ambient_arybase'} = 0;
    $self->{'ambient_warnings'} = undef; # Assume no lexical warnings
    $self->{'ambient_hints'} = 0;
    $self->{'ambient_hinthash'} = undef;

    # Given an opcode address, get the accumulated OP tree
    # OP for that. FIXME: remove this
    $self->{optree} = {};

    # Extra opcode information: parent_op
    $self->{ops} = {};

    # For B::DeparseTree::Node's that are created and don't have real OPs associated
    # with them, we assign a fake address;
    $self->{'last_fake_addr'} = 0;

    $self->init();

    while (my $arg = shift @_) {
	if ($arg eq "-d") {
	    $self->{'use_dumper'} = 1;
	    require Data::Dumper;
	} elsif ($arg =~ /^-f(.*)/) {
	    $self->{'files'}{$1} = 1;
	} elsif ($arg eq "-l") {
	    $self->{'linenums'} = 1;
	} elsif ($arg eq "-a") {
	    $self->{'linenums'} = 1;
	    $self->{'opaddr'} = 1;
	} elsif ($arg eq "-p") {
	    $self->{'parens'} = 1;
	} elsif ($arg eq "-P") {
	    $self->{'noproto'} = 1;
	} elsif ($arg eq "-q") {
	    $self->{'unquote'} = 1;
	} elsif (substr($arg, 0, 2) eq "-s") {
	    $self->style_opts(substr $arg, 2);
	} elsif ($arg =~ /^-x(\d)$/) {
	    $self->{'expand'} = $1;
	}
    }
    return $self;
}

{
    # Mask out the bits that L<warnings::register> uses
    my $WARN_MASK;
    BEGIN {
	$WARN_MASK = $warnings::Bits{all} | $warnings::DeadBits{all};
    }
    sub WARN_MASK () {
	return $WARN_MASK;
    }
}

# Initialize the contextual information, either from
# defaults provided with the ambient_pragmas method,
# or from Perl's own defaults otherwise.
sub init {
    my $self = shift;

    $self->{'arybase'}  = $self->{'ambient_arybase'};
    $self->{'warnings'} = defined ($self->{'ambient_warnings'})
				? $self->{'ambient_warnings'} & WARN_MASK
				: undef;
    $self->{'hints'}    = $self->{'ambient_hints'};
    $self->{'hints'} &= 0xFF if $] < 5.009;
    $self->{'hinthash'} = $self->{'ambient_hinthash'};

    # also a convenient place to clear out subs_declared
    delete $self->{'subs_declared'};
}

BEGIN { for (qw[ pushmark ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

sub main2info
{
    my $self = shift;
    $self->{'curcv'} = B::main_cv;
    $self->pessimise(B::main_root, B::main_start);
    return $self->deparse_root(B::main_root);
}

sub coderef2info
{
    my ($self, $coderef, $start_op) = @_;
    croak "Usage: ->coderef2info(CODEREF)" unless UNIVERSAL::isa($coderef, "CODE");
    $self->init();
    return $self->deparse_sub(svref_2object($coderef), $start_op);
}

sub coderef2text
{
    my ($self, $func) = @_;
    croak "Usage: ->coderef2text(CODEREF)" unless UNIVERSAL::isa($func, "CODE");

    $self->init();
    my $info = $self->coderef2info($func);
    return $self->info2str($info);
}

sub const {
    my $self = shift;
    my($sv, $cx) = @_;
    if ($self->{'use_dumper'}) {
	return $self->const_dumper($sv, $cx);
    }
    if (class($sv) eq "SPECIAL") {
	# sv_undef, sv_yes, sv_no
	my $text = ('undef', '1', $self->maybe_parens("!1", $cx, 21))[$$sv-1];
	return info_from_text($sv, $self, $text, 'const_special', {});
    }
    if (class($sv) eq "NULL") {
	return info_from_text($sv, $self, 'undef', 'const_NULL', {});
    }
    # convert a version object into the "v1.2.3" string in its V magic
    if ($sv->FLAGS & SVs_RMG) {
	for (my $mg = $sv->MAGIC; $mg; $mg = $mg->MOREMAGIC) {
	    if ($mg->TYPE eq 'V') {
		return info_from_text($sv, $self, $mg->PTR, 'const_magic', {});
	    }
	}
    }

    if ($sv->FLAGS & SVf_IOK) {
	my $str = $sv->int_value;
	$str = $self->maybe_parens($str, $cx, 21) if $str < 0;
	return $self->info_from_string("integer constant $str", $sv, $str);
    } elsif ($sv->FLAGS & SVf_NOK) {
	my $nv = $sv->NV;
	if ($nv == 0) {
	    if (pack("F", $nv) eq pack("F", 0)) {
		# positive zero
		return info_from_text($sv, $self, "0", 'constant float positive 0', {});
	    } else {
		# negative zero
		return info_from_text($sv, $self, $self->maybe_parens("-.0", $cx, 21),
				 'constant float negative 0', {});
	    }
	} elsif (1/$nv == 0) {
	    if ($nv > 0) {
		# positive infinity
		return info_from_text($sv, $self, $self->maybe_parens("9**9**9", $cx, 22),
				 'constant float +infinity', {});
	    } else {
		# negative infinity
		return info_from_text($sv, $self, $self->maybe_parens("-9**9**9", $cx, 21),
				 'constant float -infinity', {});
	    }
	} elsif ($nv != $nv) {
	    # NaN
	    if (pack("F", $nv) eq pack("F", sin(9**9**9))) {
		# the normal kind
		return info_from_text($sv, $self, "sin(9**9**9)", 'const_Nan', {});
	    } elsif (pack("F", $nv) eq pack("F", -sin(9**9**9))) {
		# the inverted kind
		return info_from_text($sv, $self, $self->maybe_parens("-sin(9**9**9)", $cx, 21),
				 'constant float Nan invert', {});
	    } else {
		# some other kind
		my $hex = unpack("h*", pack("F", $nv));
		return info_from_text($sv, $self, qq'unpack("F", pack("h*", "$hex"))',
				 'constant Na na na', {});
	    }
	}
	# first, try the default stringification
	my $str = "$nv";
	if ($str != $nv) {
	    # failing that, try using more precision
	    $str = sprintf("%.${max_prec}g", $nv);
	    # if (pack("F", $str) ne pack("F", $nv)) {
	    if ($str != $nv) {
		# not representable in decimal with whatever sprintf()
		# and atof() Perl is using here.
		my($mant, $exp) = split_float($nv);
		return info_from_text($sv, $self, $self->maybe_parens("$mant * 2**$exp", $cx, 19),
				 'constant float not-sprintf/atof-able', {});
	    }
	}
	$str = $self->maybe_parens($str, $cx, 21) if $nv < 0;
	return info_from_text($sv, $self, $str, 'constant nv', {});
    } elsif ($sv->FLAGS & SVf_ROK && $sv->can("RV")) {
	my $ref = $sv->RV;
	if (class($ref) eq "AV") {
	    my $list_info = $self->list_const($sv, 2, $ref->ARRAY);
	    return info_from_list($sv, $self, ['[', $list_info->{text}, ']'], '', 'const_av',
		{body => [$list_info]});
	} elsif (class($ref) eq "HV") {
	    my %hash = $ref->ARRAY;
	    my @elts;
	    for my $k (sort keys %hash) {
		push @elts, "$k => " . $self->const($hash{$k}, 6);
	    }
	    return info_from_list($sv, $self, ["{", join(", ", @elts), "}"], '',
				  'constant hash value', {});
	} elsif (class($ref) eq "CV") {
	    BEGIN {
		if ($] > 5.0150051) {
		    require overloading;
		    unimport overloading;
		}
	    }
	    if ($] > 5.0150051 && $self->{curcv} &&
		$self->{curcv}->object_2svref == $ref->object_2svref) {
		return $self->info_from_string('sub __SUB__', $sv,
					       $self->keyword("__SUB__"));
	    }
	    my $sub_info = $self->deparse_sub($ref);
	    return info_from_list($sub_info->{op}, $self, ["sub ", $sub_info->{text}], '',
				  'constant sub 2',
				  {body => [$sub_info]});
	}
	if ($ref->FLAGS & SVs_SMG) {
	    for (my $mg = $ref->MAGIC; $mg; $mg = $mg->MOREMAGIC) {
		if ($mg->TYPE eq 'r') {
		    my $re = B::Deparse::re_uninterp(B::Deparse::escape_str(B::Deparse::re_unback($mg->precomp)));
		    return $self->single_delim($sv, "qr", "", $re);
		}
	    }
	}

	my $const = $self->const($ref, 20);
	if ($self->{in_subst_repl} && $const =~ /^[0-9]/) {
	    $const = "($const)";
	}
	my @texts = ("\\", $const);
	return info_from_list($sv, $self, \@texts, '', 'const_rv',
				     {maybe_parens => [$self, $cx, 20]});

    } elsif ($sv->FLAGS & SVf_POK) {
	my $str = $sv->PV;
	if ($str =~ /[[:^print:]]/) {
	    return $self->single_delim($sv, "qq", '"',
				       B::Deparse::uninterp B::Deparse::escape_str B::Deparse::unback $str);
	} else {
	    return $self->single_delim($sv, "q", "'", B::Deparse::unback $str);
	}
    } else {
	return info_from_text($sv, $self, "undef", 'constant undef', {});
    }
}

sub const_dumper
{
    my $self = shift;
    my($sv, $cx) = @_;
    my $ref = $sv->object_2svref();
    my $dumper = Data::Dumper->new([$$ref], ['$v']);
    $dumper->Purity(1)->Terse(1)->Deparse(1)->Indent(0)->Useqq(1)->Sortkeys(1);
    my $str = $dumper->Dump();
    if ($str =~ /^\$v/) {
        return info_from_text($sv, $self, ['${my', $str, '\$v}'], 'const_dumper_my', {});
    } else {
        return info_from_text($sv, $self, $str, 'constant dumper', {});
    }
}

# This is a special case of scopeop and lineseq, for the case of the
# main_root.
sub deparse_root {
    my $self = shift;
    my($op) = @_;
    local(@$self{qw'curstash warnings hints hinthash'})
      = @$self{qw'curstash warnings hints hinthash'};
    my @ops;
    return if B::Deparse::null $op->first; # Can happen, e.g., for Bytecode without -k
    for (my $kid = $op->first->sibling; !B::Deparse::null($kid); $kid = $kid->sibling) {
	push @ops, $kid;
    }
    my $fn = sub {
	my ($exprs, $i, $info, $parent) = @_;
	my $text = $info->{text};
	my $op = $ops[$i];
	$text =~ s/\f//;
	$text =~ s/\n$//;
	$text =~ s/;\n?\z//;
	$text =~ s/^\((.+)\)$/$1/;
	$info->{type} = $op->name;
	$info->{op} = $op;

	# FIXME: this is going away...
	$self->{optree}{$$op} = $info;
	# in favor of...
	$self->{ops}{$$op}{info} = $info;

	$info->{text} = $text;
	$info->{parent} = $$parent if $parent;
	push @$exprs, $info;
    };
    my $info = $self->walk_lineseq($op, \@ops, $fn);
    my @skipped_ops;
    if (exists $info->{other_ops}) {
	@skipped_ops = @{$info->{other_ops}};
	push @skipped_ops, $op->first;
    } else {
	@skipped_ops = ($op->first);
    }
    $info->{other_ops} = \@skipped_ops;
    return $info;

}

sub update_node($$$$)
{
    my ($self, $node, $prev_expr, $op) = @_;
    $node->{prev_expr} = $prev_expr;
    $self->{optree}{$$op} = $node if $op;
    $self->{ops}{$$op}{info} = $node if $op;
}

sub walk_lineseq
{
    my ($self, $op, $kids, $callback) = @_;
    my @kids = @$kids;
    my @body = (); # Accumulated node structures
    my $expr;
    my $prev_expr = undef;
    my $fix_cop = undef;
    for (my $i = 0; $i < @kids; $i++) {
	if (B::Deparse::is_state $kids[$i]) {
	    $expr = ($self->deparse($kids[$i], 0, $op));
	    $callback->(\@body, $i, $expr, $op);
	    $self->update_node($expr, $prev_expr, $op);
	    $prev_expr = $expr;
	    if ($fix_cop) {
		$fix_cop->{text} = $expr->{text};
	    }

	    $i++;
	    if ($i > $#kids) {
		last;
	    }
	}
	if (B::Deparse::is_for_loop($kids[$i])) {
	    my $loop_expr = $self->for_loop($kids[$i], 0);
	    $callback->(\@body,
			$i += $kids[$i]->sibling->name eq "unstack" ? 2 : 1,
			$loop_expr);
	    $self->update_node($expr, $prev_expr, $op);
	    $prev_expr = $expr;
	    next;
	}
	$expr = $self->deparse($kids[$i], (@kids != 1)/2, $op);

	# Perform semantic action on $expr accumulating the result
	# in @body. $op is the parent, and $i is the child position
	$callback->(\@body, $i, $expr, $op);
	$self->update_node($expr, $prev_expr, $op);
	$prev_expr = $expr;
	if ($fix_cop) {
	    $fix_cop->{text} = $expr->{text};
	}

	# If the text portion of a COP is empty, set up to fill it in
	# from the text portion of the next node.
	if (B::class($op) eq "COP" && !$expr->{text}) {
	    $fix_cop = $op;
	} else {
	    $fix_cop = undef;
	}
    }

    # Add semicolons between statements. Don't null statements
    # (which can happen for nexstate which doesn't have source code
    # associated with it.
    $expr = $self->info_from_template("statements", $op, "%;", [], \@body);
    $self->update_node($expr, $prev_expr, $op);
    return $expr;
}

# $root should be the op which represents the root of whatever
# we're sequencing here. If it's undefined, then we don't append
# any subroutine declarations to the deparsed ops, otherwise we
# append appropriate declarations.
sub lineseq {
    my($self, $root, $cx, @ops) = @_;

    my $out_cop = $self->{'curcop'};
    my $out_seq = defined($out_cop) ? $out_cop->cop_seq : undef;
    my $limit_seq;
    if (defined $root) {
	$limit_seq = $out_seq;
	my $nseq;
	$nseq = $self->find_scope_st($root->sibling) if ${$root->sibling};
	$limit_seq = $nseq if !defined($limit_seq)
			   or defined($nseq) && $nseq < $limit_seq;
    }
    $limit_seq = $self->{'limit_seq'}
	if defined($self->{'limit_seq'})
	&& (!defined($limit_seq) || $self->{'limit_seq'} < $limit_seq);
    local $self->{'limit_seq'} = $limit_seq;

    my $fn = sub {
	my ($exprs, $i, $info, $parent) = @_;
	my $op = $ops[$i];
	$info->{type} = $op->name unless $info->{type};
	$info->{child_pos} = $i;
	$info->{op} = $op;
	if ($parent) {
	    Carp::confess("nonref parent, op: $op->name") if !ref($parent);
	    $info->{parent} = $$parent ;
	}

	# FIXME: remove optree?
	$self->{optree}{$$op} = $info;
	$self->{ops}{$$op}{info} = $info;

	push @$exprs, $info;
    };
    return $self->walk_lineseq($root, \@ops, $fn);
}

sub todo
{
    my $self = shift;
    my($cv, $is_form, $name) = @_;
    my $cvfile = $cv->FILE//'';
    return unless ($cvfile eq $0 || exists $self->{files}{$cvfile});
    my $seq;
    if ($cv->OUTSIDE_SEQ) {
	$seq = $cv->OUTSIDE_SEQ;
    } elsif (!B::Deparse::null($cv->START) and B::Deparse::is_state($cv->START)) {
	$seq = $cv->START->cop_seq;
    } else {
	$seq = 0;
    }
    push @{$self->{'subs_todo'}}, [$seq, $cv, $is_form, $name];
}

# _pessimise_walk(): recursively walk the optree of a sub,
# possibly undoing optimisations along the way.
# walk tree in root-to-branch order
# We add parent pointers in the process.

sub _pessimise_walk {
    my ($self, $startop) = @_;

    return unless $$startop;
    my ($op, $parent_op);

    for ($op = $startop; $$op; $op = $op->sibling) {
	my $ppname = $op->name;

	$self->{ops}{$$op} ||= {};
	$self->{ops}{$$op}{op} = $op;
	$self->{ops}{$$op}{parent_op} = $startop;

	# pessimisations start here

	if ($ppname eq "padrange") {
	    # remove PADRANGE:
	    # the original optimisation either (1) changed this:
	    #    pushmark -> (various pad and list and null ops) -> the_rest
	    # or (2), for the = @_ case, changed this:
	    #    pushmark -> gv[_] -> rv2av -> (pad stuff)       -> the_rest
	    # into this:
	    #    padrange ----------------------------------------> the_rest
	    # so we just need to convert the padrange back into a
	    # pushmark, and in case (1), set its op_next to op_sibling,
	    # which is the head of the original chain of optimised-away
	    # pad ops, or for (2), set it to sibling->first, which is
	    # the original gv[_].

	    $B::overlay->{$$op} = {
		    type => OP_PUSHMARK,
		    name => 'pushmark',
		    private => ($op->private & OPpLVAL_INTRO),
	    };
	}

	# pessimisations end here

	if (class($op) eq 'PMOP'
	    && ref($op->pmreplroot)
	    && ${$op->pmreplroot}
	    && $op->pmreplroot->isa( 'B::OP' ))
	{
	    $self-> _pessimise_walk($op->pmreplroot);
	}

	if ($op->flags & OPf_KIDS) {
	    $self-> _pessimise_walk($op->first);
	}

    }
}


# _pessimise_walk_exe(): recursively walk the op_next chain of a sub,
# possibly undoing optimisations along the way.
# walk tree in execution order

sub _pessimise_walk_exe {
    my ($self, $startop, $visited) = @_;

    return unless $$startop;
    return if $visited->{$$startop};
    my $op;
    for ($op = $startop; $$op; $op = $op->next) {
	last if $visited->{$$op};
	$visited->{$$op} = 1;

	$self->{ops}{$$op} ||= {};
	$self->{ops}{$$op}{op} = $op;

	my $ppname = $op->name;
	if ($ppname =~
	    /^((and|d?or)(assign)?|(map|grep)while|range|cond_expr|once)$/
	    # entertry is also a logop, but its op_other invariably points
	    # into the same chain as the main execution path, so we skip it
	) {
	    $self->_pessimise_walk_exe($op->other, $visited);
	}
	elsif ($ppname eq "subst") {
	    $self->_pessimise_walk_exe($op->pmreplstart, $visited);
	}
	elsif ($ppname =~ /^(enter(loop|iter))$/) {
	    # redoop and nextop will already be covered by the main block
	    # of the loop
	    $self->_pessimise_walk_exe($op->lastop, $visited);
	}

	# pessimisations start here
    }
}

# Go through an optree and "remove" some optimisations by using an
# overlay to selectively modify or un-null some ops. Deparsing in the
# absence of those optimisations is then easier.
#
# Note that older optimisations are not removed, as Deparse was already
# written to recognise them before the pessimise/overlay system was added.

sub pessimise {
    my ($self, $root, $start) = @_;

    no warnings 'recursion';
    # walk tree in root-to-branch order
    $self->_pessimise_walk($root);

    my %visited;
    # walk tree in execution order
    $self->_pessimise_walk_exe($start, \%visited);
}

sub print_protos {
    my $self = shift;
    my $ar;
    my @ret;
    foreach $ar (@{$self->{'protos_todo'}}) {
	my $proto = defined $ar->[1]
		? ref $ar->[1]
		    ? " () {\n    " . $self->const($ar->[1]->RV,0) . ";\n}"
		    : " (". $ar->[1] . ");"
		: ";";
	push @ret, "sub " . $ar->[0] .  "$proto\n";
    }
    delete $self->{'protos_todo'};
    return @ret;
}

sub style_opts
{
    my ($self, $opts) = @_;
    my $opt;
    while (length($opt = substr($opts, 0, 1))) {
	if ($opt eq "C") {
	    $self->{'cuddle'} = " ";
	    $opts = substr($opts, 1);
	} elsif ($opt eq "i") {
	    $opts =~ s/^i(\d+)//;
	    $self->{'indent_size'} = $1;
	} elsif ($opt eq "T") {
	    $self->{'use_tabs'} = 1;
	    $opts = substr($opts, 1);
	} elsif ($opt eq "v") {
	    $opts =~ s/^v([^.]*)(.|$)//;
	    $self->{'ex_const'} = $1;
	}
    }
}

# This gets called automatically when option:
#   -MO="DeparseTree,sC" is added
# Running this prints out the program text.
sub compile {
    my(@args) = @_;
    return sub {
	my $self = B::DeparseTree->new(@args);
	# First deparse command-line args
	if (defined $^I) { # deparse -i
	    print q(BEGIN { $^I = ).perlstring($^I).qq(; }\n);
	}
	if ($^W) { # deparse -w
	    print qq(BEGIN { \$^W = $^W; }\n);
	}
	if ($/ ne "\n" or defined $O::savebackslash) { # deparse -l and -0
	    my $fs = perlstring($/) || 'undef';
	    my $bs = perlstring($O::savebackslash) || 'undef';
	    print qq(BEGIN { \$/ = $fs; \$\\ = $bs; }\n);
	}
	my @BEGINs  = B::begin_av->isa("B::AV") ? B::begin_av->ARRAY : ();
	my @UNITCHECKs = B::unitcheck_av->isa("B::AV")
	    ? B::unitcheck_av->ARRAY
	    : ();
	my @CHECKs  = B::check_av->isa("B::AV") ? B::check_av->ARRAY : ();
	my @INITs   = B::init_av->isa("B::AV") ? B::init_av->ARRAY : ();
	my @ENDs    = B::end_av->isa("B::AV") ? B::end_av->ARRAY : ();
	if ($] < 5.020) {
	    for my $block (@BEGINs, @UNITCHECKs, @CHECKs, @INITs, @ENDs) {
		$self->todo($block, 0);
	    }
	} else {
	    my @names = qw(BEGIN UNITCHECK CHECK INIT END);
	    my @blocks = (\@BEGINs, \@UNITCHECKs, \@CHECKs, \@INITs, \@ENDs);
	    while (@names) {
		my ($name, $blocks) = (shift @names, shift @blocks);
		for my $block (@$blocks) {
		    $self->todo($block, 0, $name);
		}
	    }
        }
	$self->stash_subs();
	local($SIG{"__DIE__"}) =
	    sub {
		if ($self->{'curcop'}) {
		    my $cop = $self->{'curcop'};
		    my($line, $file) = ($cop->line, $cop->file);
		    print STDERR "While deparsing $file near line $line,\n";
		}
		use Data::Printer;
		my @bt = caller(1);
		p @bt;
	    };
	$self->{'curcv'} = main_cv;
	$self->{'curcvlex'} = undef;
	print $self->print_protos;
	@{$self->{'subs_todo'}} =
	  sort {$a->[0] <=> $b->[0]} @{$self->{'subs_todo'}};
	my $root = main_root;
        local $B::overlay = {};

	if ($] < 5.021) {
	    unless (B::Deparse::null $root) {
		$self->pessimise($root, main_start);
		# Print deparsed program
		print $self->deparse_root($root)->{text}, "\n";
	    }
	} else {
	    unless (B::Deparse::null $root) {
		$self->B::Deparse::pad_subs($self->{'curcv'});
		# Check for a stub-followed-by-ex-cop, resulting from a program
		# consisting solely of sub declarations.  For backward-compati-
		# bility (and sane output) we don’t want to emit the stub.
		#   leave
		#     enter
		#     stub
		#     ex-nextstate (or ex-dbstate)
		my $kid;
		if ( $root->name eq 'leave'
		     and ($kid = $root->first)->name eq 'enter'
		     and !B::Deparse::null($kid = $kid->sibling) and $kid->name eq 'stub'
		     and !B::Deparse::null($kid = $kid->sibling) and $kid->name eq 'null'
		     and class($kid) eq 'COP' and B::Deparse::null $kid->sibling )
		{
		    # ignore deparsing routine
		} else {
		    $self->pessimise($root, main_start);
		    # Print deparsed program
		    my $root_tree = $self->deparse_root($root);
		    print $root_tree->{text}, "\n";
		}
	    }
	}
	my @text;
        while (scalar(@{$self->{'subs_todo'}})) {
	    push @text, $self->next_todo->{text};
	}
	print join("", @text), "\n" if @text;

	# Print __DATA__ section, if necessary
	no strict 'refs';
	my $laststash = defined $self->{'curcop'}
	    ? $self->{'curcop'}->stash->NAME : $self->{'curstash'};
	if (defined *{$laststash."::DATA"}{IO}) {
	    print $self->keyword("package") . " $laststash;\n"
		unless $laststash eq $self->{'curstash'};
	    print $self->keyword("__DATA__") . "\n";
	    print readline(*{$laststash."::DATA"});
	}
    }
}

# "deparse()" is the main function to call to produces a depare tree
# for a give B::OP. This method is the inner loop.

# Rocky's comment with respect to:
#   so try to keep it simple
#
# Most normal Perl programs really aren't that big. Yeah, I know there
# are a couple of big pigs like the B::Deparse code itself. The perl5
# debugger comes to mind too. But what's the likelihood of anyone wanting
# to decompile all of this?
#
# On the other hand, error checking is too valuable to throw out here.
# Also, in trying to use and modularize this code, I see there is
# a lot of repetition in subroutine parsing routines. That's
# why I added the above PP_MAPFNS table. I'm not going to trade off
# table lookup and interpetation for a huge amount of subroutine
# bloat.

# That said it is useful to note that this is inner-most loop
# interpeter loop as it is called for each node in the B::OP tree.
#
sub deparse
{
    my($self, $op, $cx, $parent) = @_;

    Carp::confess("deparse called on an invalid op $op")
	unless $op->can('name');

    my $name = $op->name;
    print "YYY $name\n" if $ENV{'DEBUG_DEPARSETREE'};
    my ($info, $meth);

    if (exists($PP_MAPFNS{$name})) {
	# Interpret method calls for our PP_MAPFNS table
	if (ref($PP_MAPFNS{$name}) eq 'ARRAY') {
	    my @args = @{$PP_MAPFNS{$name}};
	    $meth = shift @args;
	    if ($meth eq 'maybe_targmy') {
		# FIXME: This is an inline version of targmy.
		# Can we dedup it? do we want to?
		$meth = shift @args;
		unshift @args, $name unless @args;
		if ($op->private & OPpTARGET_MY) {
		    my $var = $self->padname($op->targ);
		    my $val = $self->$meth($op, 7, @args);
		    my @texts = ($var, '=', $val);
		    $info = $self->info_from_template("my", $op,
						      "%c = %c", [0, 1],
						      [$var, $val],
						      {maybe_parens => [$self, $cx, 7]});
		} else {
		    $info = $self->$meth($op, $cx, @args);
		}
	    } else {
		$info = $self->$meth($op, $cx, @args);
	    }
	} else {
	    # Simple case: one simple call of the
	    # the method in the table. Call this
	    # passing arguments $op, $cx, and $name.
	    # Some functions might not use these,
	    # but that's okay.
	    $meth = $PP_MAPFNS{$name};
	    $info = $self->$meth($op, $cx, $name);
	}
    } else {
	# Tried and true fallback method:
	# a method has been defined for this pp_op special.
	# call that.
	$meth = "pp_" . $name;
	$info = $self->$meth($op, $cx);
    }

    Carp::confess("nonref return for $meth deparse: $info") if !ref($info);
    Carp::confess("not B::DeparseTree:Node returned for $meth: $info")
	if !$info->isa("B::DeparseTree::Node");
    $info->{parent} = $$parent if $parent;
    $info->{cop} = $self->{'curcop'};
    my $got_op = $info->{op};
    if ($got_op) {
	if ($got_op != $op) {
	    # Do something here?
	    # printf("XX final op 0x%x is not requested 0x%x\n",
	    # 	   $$op, $$got_op);
	}
    } else {
	$info->{op} = $op;
    }
    $self->{optree}{$$op} = $info;
    if ($info->{other_ops}) {
	foreach my $other (@{$info->{other_ops}}) {
	    if (!ref $other) {
		Carp::confess "$meth returns invalid other $other";
	    } elsif ($other->isa("B::DeparseTree::Node")) {
		# "$other" has been set up to mark a particular portion
		# of the info.
		$self->{optree}{$other->{addr}} = $other;
		$other->{parent} = $$op;
	    } else {
		# "$other" is just the OP. Have it mark everything
		# or "info".
		$self->{optree}{$$other} = $info;
	    }
	}
    }
    return $info;
}

# Deparse a subroutine
sub deparse_sub($$$$)
{
    my ($self, $cv, $start_op) = @_;

    # Sanity checks..
    Carp::confess("NULL in deparse_sub") if !defined($cv) || $cv->isa("B::NULL");
    Carp::confess("SPECIAL in deparse_sub") if $cv->isa("B::SPECIAL");

    # First get protype and sub attribute information
    local $self->{'curcop'} = $self->{'curcop'};
    my $proto = '';
    if ($cv->FLAGS & SVf_POK) {
	$proto .= "(". $cv->PV . ")";
    }
    if ($cv->CvFLAGS & (CVf_METHOD|CVf_LOCKED|CVf_LVALUE)) {
        $proto .= ":";
        $proto .= " lvalue" if $cv->CvFLAGS & CVf_LVALUE;
        $proto .= " locked" if $cv->CvFLAGS & CVf_LOCKED;
        $proto .= " method" if $cv->CvFLAGS & CVf_METHOD;
    }

    local($self->{'curcv'}) = $cv;
    local($self->{'curcvlex'});
    local(@$self{qw'curstash warnings hints hinthash'})
	= @$self{qw'curstash warnings hints hinthash'};

    # Now deparse subroutine body

    my $root = $cv->ROOT;
    my ($body, $node);

    local $B::overlay = {};
    if (not B::Deparse::null $root) {
	$self->pessimise($root, $cv->START);
	my $lineseq = $root->first;
	if ($lineseq->name eq "lineseq") {
	    my @ops;
	    for(my $o=$lineseq->first; $$o; $o=$o->sibling) {
		push @ops, $o;
	    }
	    $body = $self->lineseq($root, 0, @ops);
	    my $scope_en = $self->find_scope_en($lineseq);
	}
	elsif ($start_op) {
	    $body = $self->deparse($start_op, 0, $root);
	} else {
	    $body = $self->deparse($root->first, 0, $root);
	}

	my $fn_name = $cv->GV->NAME;
	$node = $self->info_from_template("sub $fn_name$proto",
					  $root,
					  "$proto\n%|{\n%+%c\n%-}",
					  [0], [$body]);

	$self->{optree}{$$lineseq} = $node;

    } else {
	my $sv = $cv->const_sv;
	if ($$sv) {
	    # uh-oh. inlinable sub... format it differently
	    $node = $self->info_from_template('inline sub', $sv,
					      "$proto\n%|{\n%+%c\n%-}",
					      [0], [$self->const($sv, 0)]);
	} else {
	    # XSUB? (or just a declaration)
	    $node = $self->info_from_string("XSUB or sub declaration", $proto);
	}
    }


    # Add additional DeparseTree tracking info
    if ($start_op) {
	$node->{op} = $start_op;
	$self->{'optree'}{$$start_op} = $node;
    }
    $node->{cop} = undef;
    $node->{'parent'}  = $cv;
    return $node;
}

# We have a TODO list of things that must be handled
# at the top level. There are things like
# format statements, "BEGIN" and "use" statements.
# Here we handle the next one.
sub next_todo
{
    my ($self, $parent) = @_;
    my $ent = shift @{$self->{'subs_todo'}};
    my $cv = $ent->[1];
    my $gv = $cv->GV;
    my $name = $self->gv_name($gv);
    if ($ent->[2]) {
	my $node = $self->deparse_format($ent->[1], $cv);
	return $self->info_from_template("format $name",
					 "format $name = %c",
					 undef, [$node])
    } else {
	my ($fmt, $type);
	$self->{'subs_declared'}{$name} = 1;
	if ($name eq "BEGIN") {
	    my $use_dec = $self->begin_is_use($cv);
	    if (defined ($use_dec) and $self->{'expand'} < 5) {
		if (0 == length($use_dec)) {
		    $self->info_from_string('BEGIN', $cv, '');
		} else {
		    $self->info_from_string('use', $cv, $use_dec);
		}
	    }
	}
	my $l = '';
	if ($self->{'linenums'}) {
	    my $line = $gv->LINE;
	    my $file = $gv->FILE;
	    $l = "\n# line $line \"$file\"\n";
	}
	if (class($cv->STASH) ne "SPECIAL") {
	    my $stash = $cv->STASH->NAME;
	    if ($stash ne $self->{'curstash'}) {
		$fmt = "package $stash;\n";
		$type = "package $stash";
		$name = "$self->{'curstash'}::$name" unless $name =~ /::/;
		$self->{'curstash'} = $stash;
	    }
	    $name =~ s/^\Q$stash\E::(?!\z|.*::)//;
	    $fmt .= "sub $name";
	    $type .= "sub $name";
	}
	my $node = $self->deparse_sub($cv, $parent);
	$fmt .= '%c';
	return $self->info_from_template($type, $cv, $fmt, [0], [$node]);
    }
}

# Deparse a subroutine by name
sub deparse_subname($$)
{
    my ($self, $funcname) = @_;
    my $cv = svref_2object(\&$funcname);
    my $info = $self->deparse_sub($cv);
    return $self->info_from_template("sub $funcname", $cv, "sub $funcname %c",
				 undef, [$info]);
}

# Return a list of info nodes for "use" and "no" pragmas.
sub declare_hints
{
    my ($self, $from, $to) = @_;
    my $use = $to   & ~$from;
    my $no  = $from & ~$to;

    my @decls = ();
    for my $pragma (B::Deparse::hint_pragmas($use)) {
	my $type = $self->keyword("use") . " $pragma";
	push @decls, $self->info_from_template($type, undef, "$type", [], []);
    }
    for my $pragma (B::Deparse::hint_pragmas($no)) {
	my $type = $self->keyword("no") . " $pragma";
	push @decls, $self->info_from_template($type, undef, "$type", [], []);
    }
    return @decls;
}

# Internal implementation hints that the core sets automatically, so don't need
# (or want) to be passed back to the user
my %ignored_hints = (
    'open<' => 1,
    'open>' => 1,
    ':'     => 1,
    'strict/refs' => 1,
    'strict/subs' => 1,
    'strict/vars' => 1,
);

my %rev_feature;

sub declare_hinthash {
    my ($self, $from, $to, $indent, $hints) = @_;
    my $doing_features =
	($hints & $feature::hint_mask) == $feature::hint_mask;
    my @decls;
    my @features;
    my @unfeatures; # bugs?
    for my $key (sort keys %$to) {
	next if $ignored_hints{$key};
	my $is_feature = $key =~ /^feature_/ && $^V ge 5.15.6;
	next if $is_feature and not $doing_features;
	if (!exists $from->{$key} or $from->{$key} ne $to->{$key}) {
	    push(@features, $key), next if $is_feature;
	    push @decls,
		qq(\$^H{) . single_delim($self, "q", "'", $key, "'") . qq(} = )
	      . (
		   defined $to->{$key}
			? single_delim($self, "q", "'", $to->{$key}, "'")
			: 'undef'
		)
	      . qq(;);
	}
    }
    for my $key (sort keys %$from) {
	next if $ignored_hints{$key};
	my $is_feature = $key =~ /^feature_/ && $^V ge 5.15.6;
	next if $is_feature and not $doing_features;
	if (!exists $to->{$key}) {
	    push(@unfeatures, $key), next if $is_feature;
	    push @decls, qq(delete \$^H{'$key'};);
	}
    }
    my @ret;
    if (@features || @unfeatures) {
	if (!%rev_feature) { %rev_feature = reverse %feature::feature }
    }
    if (@features) {
    	push @ret, $self->keyword("use") . " feature "
    		 . join(", ", map "'$rev_feature{$_}'", @features) . ";\n";
    }
    if (@unfeatures) {
	push @ret, $self->keyword("no") . " feature "
		 . join(", ", map "'$rev_feature{$_}'", @unfeatures)
		 . ";\n";
    }
    @decls and
	push @ret,
	     join("\n" . (" " x $indent), "BEGIN {", @decls) . "\n}\n";
    return @ret;
}

# generate any pragmas, 'package foo' etc needed to synchronise
# with the given cop

sub pragmata {
    my $self = shift;
    my($op) = @_;

    my @text;

    my $stash = $op->stashpv;
    if ($stash ne $self->{'curstash'}) {
	push @text, $self->keyword("package") . " $stash;\n";
	$self->{'curstash'} = $stash;
    }

    if (OPpCONST_ARYBASE && $self->{'arybase'} != $op->arybase) {
	push @text, '$[ = '. $op->arybase .";\n";
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
	push @text,
	    $self->declare_warnings($self->{'warnings'}, $warning_bits);
	$self->{'warnings'} = $warning_bits;
    }

    my $hints = $] < 5.008009 ? $op->private : $op->hints;
    my $old_hints = $self->{'hints'};
    if ($self->{'hints'} != $hints) {
	push @text, $self->declare_hints($self->{'hints'}, $hints);
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
		push @text,
		    $self->keyword("no") . " feature ':all';\n",
		    $self->keyword("use") . " feature ':$bundle';\n";
	    }
	}
    }

    if ($] > 5.009) {
	push @text, $self->declare_hinthash(
	    $self->{'hinthash'}, $newhh,
	    $self->{indent_size}, $self->{hints},
	);
	$self->{'hinthash'} = $newhh;
    }

    return join("", @text);
}


# Create a "use", "no", or "BEGIN" block to set warnings.
sub declare_warnings
{
    my ($self, $from, $to) = @_;
    if (($to & WARN_MASK) eq (warnings::bits("all") & WARN_MASK)) {
	my $type = $self->keyword("use") . " warnings";
	return $self->info_from_template($type, undef, "$type;\n",
					 [], []);
    }
    elsif (($to & WARN_MASK) eq ("\0"x length($to) & WARN_MASK)) {
	my $type = $self->keyword("no") . " warnings";
	return $self->info_from_template($type, undef, "$type;\n",
					 [], []);
    }
    my $bit_expr = join('', map { sprintf("\\x%02x", ord $_) } split "", $to);
    my $str = "BEGIN {\n%+\${^WARNING_BITS} = \"$bit_expr;\n%-";
    return $self->info_from_template('warning bits begin', undef,
				     "%|$str\n", [], [], {omit_next_semicolon=>1});
}

# Iterate over $self->{subs_todo} picking up the
# text of of $self->next_todo.
# We return an array of strings. The calling
# routine will join these together
sub seq_subs {
    my ($self, $seq) = @_;
    my @texts;

    return () if !defined $seq;
    my @pending;
    while (scalar(@{$self->{'subs_todo'}})
	   and $seq > $self->{'subs_todo'}[0][0]) {
	my $cv = $self->{'subs_todo'}[0][1];
	# Skip the OUTSIDE check for lexical subs.  We may be deparsing a
	# cloned anon sub with lexical subs declared in it, in which case
	# the OUTSIDE pointer points to the anon protosub.
	my $lexical = ref $self->{'subs_todo'}[0][3];
	my $outside = !$lexical && $cv && $cv->OUTSIDE;
	if (!$lexical and $cv
	 and ${$cv->OUTSIDE || \0} != ${$self->{'curcv'}})
	{
	    # rocky: What do we do with @pending?
	    push @pending, shift @{$self->{'subs_todo'}};
	    next;
	}
	push @texts, $self->next_todo;
    }
    return @texts;
}

# FIXME: this code has to be here. Find out why and fix.
# Truncate is special because OPf_SPECIAL makes a bareword first arg
# be a filehandle. This could probably be better fixed in the core
# by moving the GV lookup into ck_truc.

# Demo code
unless(caller) {
    my @texts = ('a', 'b', 'c');
    my $deparse = __PACKAGE__->new();
    my $info = info_from_list('op', $deparse, \@texts, ', ', 'test', {});

    use Data::Printer;
    my $str = $deparse->template_engine("%c", [0], ["16"]);
    p $str;
    my $str2 = $deparse->template_engine("%F", [[0, sub {'0x' . sprintf "%x", shift}]], [$str]);
    p $str2;

    # print $deparse->template_engine("100%% "), "\n";
    # print $deparse->template_engine("%c,\n%+%c\n%|%c %c!",
    # 				    [1, 0, 2, 3],
    # 				    ["is", "now", "the", "time"]), "\n";

    # $info = $deparse->info_from_template("demo", undef, "%C",
    # 					 [[0, 1, ";\n%|"]],
    # 					 ['$x=1', '$y=2']);

    # @texts = ("use warnings;", "use strict", "my(\$a)");
    # $info = $deparse->info_from_template("demo", undef, "%;", [], \@texts);

    # $info = $deparse->info_from_template("list", undef,
    # 					 "%C", [[0, $#texts, ', ']],
    # 					 \@texts);

    # p $info;


    # @texts = (['a', 1], ['b', 2], 'c');
    # $info = info_from_list('op', $deparse, \@texts, ', ', 'test', {});
    # p $info;
}

1;
