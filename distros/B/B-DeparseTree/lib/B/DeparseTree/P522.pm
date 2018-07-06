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

use rlib '../..';

package B::DeparseTree::P522;
use Carp;
use B qw(class opnumber
    OPf_KIDS OPf_REF OPf_STACKED OPf_SPECIAL OPf_MOD OPf_PARENS
    OPpLVAL_INTRO OPpOUR_INTRO OPpENTERSUB_AMPER OPpSLICE OPpCONST_BARE
    OPpMULTIDEREF_EXISTS OPpMULTIDEREF_DELETE
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
    MDEREF_SHIFT
);

use B::DeparseTree::PPfns;
use B::DeparseTree::SyntaxTree;
use B::DeparseTree::PP;
use B::Deparse;

# Copy unchanged functions from B::Deparse
*begin_is_use = *B::Deparse::begin_is_use;
*const_sv = *B::Deparse::const_sv;
*escape_extended_re = *B::Deparse::escape_extended_re;
*find_our_type = *B::Deparse::find_our_type;
*find_scope_st = *B::Deparse::find_scope_st;
*gv_name = *B::Deparse::gv_name;
*meth_rclass_sv = *B::Deparse::meth_rclass_sv;
*meth_sv = *B::Deparse::meth_sv;
*padany = *B::Deparse::padany;
*padname = *B::Deparse::padname;
*padname_sv = *B::Deparse::padname_sv;
*padval = *B::Deparse::padval;
*populate_curcvlex = *B::Deparse::populate_curcvlex;
*re_flags = *B::Deparse::re_flags;
*rv2gv_or_string = *B::Deparse::rv2gv_or_string;
*stash_variable = *B::Deparse::stash_variable;
*stash_variable_name = *B::Deparse::stash_variable_name;
*tr_chr = *B::Deparse::tr_chr;

use strict;
use vars qw/$AUTOLOAD/;
use warnings ();
require feature;

our $VERSION = '3.2.0';

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

BEGIN { for (qw[ rv2sv aelem
		 rv2av rv2hv helem custom]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

# pp_padany -- does not exist after parsing

sub AUTOLOAD {
    if ($AUTOLOAD =~ s/^.*::pp_//) {
	warn "unexpected OP_".
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

# FIXME remove dup with 5.24 and 5.18
# NOTE: This is the deparse 5.26 routine which
# differs from 5.18 in that adds CORE:: when
# appropriate.
sub keyword {
    my $self = shift;
    my $name = shift;
    return $name if $name =~ /^CORE::/; # just in case
    if (exists $feature_keywords{$name}) {
	my $hh;
	my $hints = $self->{hints} & $feature::hint_mask;
	if ($hints && $hints != $feature::hint_mask) {
	    $hh = B::Deparse::_features_from_bundle($hints);
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

# Note: maybe_local things can't be moved to PP yet.
{ no strict 'refs'; *{"pp_r$_"} = *{"pp_$_"} for qw< keys each values >; }

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

my @threadsv_names = B::threadsv_names;
sub pp_threadsv {
    my $self = shift;
    my($op, $cx) = @_;
    return $self->maybe_local_str($op, $cx, "\$" .  $threadsv_names[$op->targ]);
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
    return info_from_list('const', $self, \@texts,  '', $type,
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
	return B::Deparse::re_dq_disambiguate($first, $last);
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

# Not in Perl 5.20 and presumeably < 5.20. No harm in adding to 5.20?
*pp_ncomplement = *pp_complement;

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
    # print $deparse->($deparse->deparse_subname('fib')->{text});
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
		   $parent_op_name, $deparse->{text});
	} else {
	    printf("0x%x %s of %s |\n",
		   $key, $value->{type},
		   $parent_op_name);
	}
	printf " ## line %s\n", $value->{cop} ? $value->{cop}->line : 'undef';
	print '-' x 30, "\n";
    }
    # use B::Deparse;
    # my $deparse_old = B::Deparse->new("-l", "-sC");
    # print $deparse_old->coderef2text(\&baz);
}

1;
