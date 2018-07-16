# B::DeparseTree::P526.pm
# Copyright (c) 1998-2000, 2002, 2003, 2004, 2005, 2006 Stephen McCamant.
# Copyright (c) 2015, 2017, 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

# This is based on the module B::Deparse (for perl 5.22) by Stephen McCamant.
# It has been extended save tree structure, and is addressible
# by opcode address.

# B::Parse in turn is based on the module of the same name by Malcolm Beattie,
# but essentially none of his code remains.

use v5.26;

use rlib '../..';

package B::DeparseTree::P526;
use Carp;

use B qw(
    CVf_METHOD
    MDEREF_ACTION_MASK
    MDEREF_AV_gvav_aelem
    MDEREF_AV_gvsv_vivify_rv2av_aelem
    MDEREF_AV_padav_aelem
    MDEREF_AV_padsv_vivify_rv2av_aelem
    MDEREF_AV_pop_rv2av_aelem
    MDEREF_AV_vivify_rv2av_aelem
    MDEREF_FLAG_last
    MDEREF_HV_gvhv_helem
    MDEREF_HV_gvsv_vivify_rv2hv_helem
    MDEREF_HV_padhv_helem
    MDEREF_HV_padsv_vivify_rv2hv_helem
    MDEREF_HV_pop_rv2hv_helem
    MDEREF_HV_vivify_rv2hv_helem
    MDEREF_INDEX_MASK
    MDEREF_INDEX_const
    MDEREF_INDEX_gvsv
    MDEREF_INDEX_none
    MDEREF_INDEX_padsv
    MDEREF_MASK
    MDEREF_SHIFT
    MDEREF_reload
    OPf_KIDS
    OPf_MOD
    OPf_PARENS
    OPf_REF
    OPf_SPECIAL
    OPf_STACKED
    OPf_WANT
    OPf_WANT_LIST
    OPf_WANT_SCALAR
    OPf_WANT_VOID
    OPpCONST_BARE
    OPpENTERSUB_AMPER
    OPpEXISTS_SUB
    OPpLVAL_INTRO
    OPpMULTIDEREF_DELETE
    OPpMULTIDEREF_EXISTS
    OPpOUR_INTRO
    OPpPADRANGE_COUNTSHIFT
    OPpSLICE
    OPpSORT_INTEGER
    OPpSORT_NUMERIC
    OPpSORT_REVERSE
    OPpSPLIT_ASSIGN OPpSPLIT_LEX
    OPpTARGET_MY
    PADNAMEt_OUTER
    PMf_CONTINUE
    PMf_EVAL
    PMf_EXTENDED
    PMf_EXTENDED_MORE
    PMf_FOLD
    PMf_GLOBAL
    PMf_KEEP
    PMf_MULTILINE
    PMf_ONCE
    PMf_SINGLELINE
    SVf_FAKE
    SVf_ROK SVpad_OUR
    SVpad_TYPED
    SVs_RMG
    SVs_SMG
    class
    main_cv
    main_root
    main_start
    opnumber
    perlstring
    svref_2object
    );

use B::DeparseTree::PPfns;
use B::DeparseTree::SyntaxTree;
use B::DeparseTree::PP;
use B::Deparse;

# Copy unchanged functions from B::Deparse
*begin_is_use = *B::Deparse::begin_is_use;
*const_sv = *B::Deparse::const_sv;
*escape_re = *B::Deparse::escape_re;
*find_scope_st = *B::Deparse::find_scope_st;
*gv_name = *B::Deparse::gv_name;
*keyword = *B::Deparse::keyword;
*meth_pad_subs = *B::Deparse::pad_subs;
*meth_rclass_sv = *B::Deparse::meth_rclass_sv;
*meth_sv = *B::Deparse::meth_sv;
*padany = *B::Deparse::padany;
*padname = *B::Deparse::padname;
*padname_sv = *B::Deparse::padname_sv;
*padval = *B::Deparse::padval;
*re_flags = *B::Deparse::re_flags;
*stash_variable = *B::Deparse::stash_variable;
*stash_variable_name = *B::Deparse::stash_variable_name;
*tr_chr = *B::Deparse::tr_chr;

use strict;
use vars qw/$AUTOLOAD/;
use warnings ();
require feature;

our(@EXPORT, @ISA);
our $VERSION = '3.2.0';

@ISA = qw(B::DeparseTree::PP);

@EXPORT = qw(slice);

BEGIN {
    # List version-specific constants here.
    # Easiest way to keep this code portable between version looks to
    # be to fake up a dummy constant that will never actually be true.
    foreach (qw(OPpSORT_INPLACE OPpSORT_DESCEND OPpITER_REVERSED OPpCONST_NOVER
		OPpPAD_STATE PMf_SKIPWHITE RXf_SKIPWHITE
		PMf_CHARSET PMf_KEEPCOPY PMf_NOCAPTURE CVf_ANONCONST
		CVf_LOCKED OPpREVERSE_INPLACE OPpSUBSTR_REPL_FIRST
		PMf_NONDESTRUCT OPpCONST_ARYBASE OPpEVAL_BYTES
		OPpLVREF_TYPE OPpLVREF_SV OPpLVREF_AV OPpLVREF_HV
		OPpLVREF_CV OPpLVREF_ELEM SVpad_STATE)) {
	eval { B->import($_) };
	no strict 'refs';
	*{$_} = sub () {0} unless *{$_}{CODE};
    }
}

BEGIN { for (qw[ rv2sv aelem
		 rv2av rv2hv helem custom ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

# pp_padany -- does not exist after parsing

sub AUTOLOAD {
    if ($AUTOLOAD =~ s/^.*::pp_//) {
	warn "unexpected OP_".uc $AUTOLOAD;
	  ($_[1]->type == OP_CUSTOM ? "CUSTOM ($AUTOLOAD)" : uc $AUTOLOAD);
	return "XXX";
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

{ no strict 'refs'; *{"pp_r$_"} = *{"pp_$_"} for qw< keys each values >; }

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

my @threadsv_names = B::threadsv_names;
sub pp_threadsv {
    my $self = shift;
    my($op, $cx) = @_;
    return $self->maybe_local_str($op, $cx, "\$" .  $threadsv_names[$op->targ]);
}

sub pp_rv2sv { maybe_local_str(@_, rv2x(@_, "\$")) }
sub pp_rv2hv { maybe_local_str(@_, rv2x(@_, "%")) }
sub pp_rv2gv { maybe_local_str(@_, rv2x(@_, "*")) }

# skip rv2av
sub pp_av2arylen {
    my $self = shift;
    my($op, $cx) = @_;
    if ($op->first->name eq "padav") {
	return $self->maybe_local_str($op, $cx, '$#' . $self->padany($op->first));
    } else {
	return $self->maybe_local_str($op, $cx,
				      $self->rv2x($op->first, $cx, '$#'));
    }
}

sub pp_rv2av {
    my $self = shift;
    my($op, $cx) = @_;
    my $kid = $op->first;
    if ($kid->name eq "const") { # constant list
	my $av = $self->const_sv($kid);
	return $self->list_const($kid, $cx, $av->ARRAY);
    } else {
	return $self->maybe_local_str($op, $cx,
				      $self->rv2x($op, $cx, "\@"));
    }
 }

sub elem_or_slice_array_name
{
    my $self = shift;
    my ($array, $left, $padname, $allow_arrow) = @_;

    if ($array->name eq $padname) {
	return $self->padany($array);
    } elsif (B::Deparse::is_scope($array)) { # ${expr}[0]
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
    } elsif (!$allow_arrow || B::Deparse::is_scalar $array) {
	# $x[0], $$x[0], ...
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
	if (B::Deparse::is_subscriptable($array)) {
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
		       && (   B::Deparse::_op_is_or_was($op->first, OP_RV2AV)
			      || B::Deparse::_op_is_or_was($op->first, OP_RV2HV))
		       && ($op->first->flags & OPf_KIDS)
		       && (   B::Deparse::_op_is_or_was($op->first->first, OP_AELEM)
			      || B::Deparse::_op_is_or_was($op->first->first, OP_HELEM))
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
		    !B::Deparse::null($real = $arg->first) and
		    ($chr =~ /\$/ && B::Deparse::is_scalar($real->first)
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

# Like dq(), but different
sub re_dq {
    my $self = shift;
    my ($op) = @_;
    my ($re_dq_info, $fmt);

    my $type = $op->name;
    if ($type eq "const") {
	return '$[' if $op->private & OPpCONST_ARYBASE;
	my $unbacked = B::Deparse::re_unback($self->const_sv($op)->as_string);
	return B::Deparse::re_uninterp(escape_re($unbacked));
    } elsif ($type eq "concat") {
	my $first = $self->re_dq($op->first);
	my $last  = $self->re_dq($op->last);
	return B::Deparse::re_dq_disambiguate($first, $last);
    } elsif ($type eq "uc") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\U%c\E';
	$type .= ' uc';
    } elsif ($type eq "lc") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\L%c\E';
	$type .= ' lc';
    } elsif ($type eq "ucfirst") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\u%c';
	$type .= ' ucfirst';
    } elsif ($type eq "lcfirst") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\u%c';
	$type .= ' lcfirst';
    } elsif ($type eq "quotemeta") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\Q%c\E';
	$type .= ' quotemeta';
    } elsif ($type eq "fc") {
	$re_dq_info = $self->re_dq($op->first->sibling);
	$fmt = '\F%c\E';
	$type .= ' fc';
    } elsif ($type eq "join") {
	return $self->deparse($op->last, 26); # was join($", @ary)
    } else {
	my $ret = $self->deparse($op, 26);
	$ret =~ s/^\$([(|)])\z/\${$1}/ # $( $| $) need braces
	or $ret =~ s/^\@([-+])\z/\@{$1}/; # @- @+ need braces
	return $ret;
    }
    return $self->info_from_template($type, $op->first->sibling,
				     $fmt, [$re_dq_info], [0]);
}

sub pure_string {
    my ($self, $op) = @_;
    return 0 if B::Deparse::null $op;
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
    elsif (B::Deparse::is_scalar($op) || $type =~ /^[ah]elem$/) {
	return 1;
    }
    elsif ($type eq "null" and $op->can('first') and not B::Deparse::null $op->first and
	  ($op->first->name eq "null" and $op->first->can('first')
	   and not B::Deparse::null $op->first->first and
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
    if ($kid->name eq "null" and !B::Deparse::null($kid->first)
	and $kid->first->name eq 'pushmark') {
	my $str = '';
	push(@other_ops, $kid);
	$kid = $kid->first->sibling;
	my @body = ();
	while (!B::Deparse::null($kid)) {
	    my $first = $str;
	    my $last = $self->re_dq($kid, $extended);
	    push @body, $last;
	    push(@other_ops, $kid);
	    $str = B::Deparse::re_dq_disambiguate($first,
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

sub pp_split
{
    my($self, $op, $cx) = @_;
    my($kid, @exprs, $ary_info, $expr);
    my $stacked = $op->flags & OPf_STACKED;
    my $ary = '';
    my @body = ();
    my @other_ops = ();
    $kid = $op->first;

    $kid = $op->first;
    $kid = $kid->sibling if $kid->name eq 'regcomp';
    for (; !B::Deparse::null($kid); $kid = $kid->sibling) {
	push @exprs, $self->deparse($kid, 6, $op);
    }

    unshift @exprs, $self->matchop($op, $cx, "m", "/");

    if ($op->private & OPpSPLIT_ASSIGN) {
        # With C<@array = split(/pat/, str);>,
        #  array is stored in split's pmreplroot; either
        # as an integer index into the pad (for a lexical array)
        # or as GV for a package array (which will be a pad index
        # on threaded builds)
        # With my/our @array = split(/pat/, str), the array is instead
        # accessed via an extra padav/rv2av op at the end of the
        # split's kid ops.

        if ($stacked) {
            $ary = pop @exprs;
        }
        else {
            if ($op->private & OPpSPLIT_LEX) {
                $ary = $self->padname($op->pmreplroot);
            }
            else {
                # union with op_pmtargetoff, op_pmtargetgv
                my $gv = $op->pmreplroot;
                $gv = $self->padval($gv) if !ref($gv);
                $ary = $self->maybe_local(@_,
			      $self->stash_variable('@',
						     $self->gv_name($gv),
						     $cx))
            }
            if ($op->private & OPpLVAL_INTRO) {
                $ary = $op->private & OPpSPLIT_LEX ? "my $ary" : "local $ary";
            }
        }
    }

    push @body, @exprs;
    my $opts = {body => \@exprs};

    # handle special case of split(), and split(' ') that compiles to /\s+/
    if (($op->reflags // 0) & RXf_SKIPWHITE()) {
	my $expr0 = $exprs[0];
	my $expr0b0 = $expr0->{body}[0];
	my $bsep = $expr0b0->{sep};
	my $sep = $expr0->{sep};
	$expr0b0->{texts}[1] = ' ';
	# substr($expr0b0->{text}, 1, 0) = ' ';
	substr($expr0->{texts}[0], 1, 0) = ' ';
	substr($expr0->{text}, 1, 0) = ' ';
    }
    my @args_texts = map $_->{text}, @exprs;

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

# Not in Perl 5.20 and presumably < 5.20. No harm in adding to 5.20?
*pp_ncomplement = *pp_complement;

1;
