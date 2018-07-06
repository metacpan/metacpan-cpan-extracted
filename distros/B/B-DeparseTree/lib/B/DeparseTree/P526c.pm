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

package B::DeparseTree::P526c;
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
    OPf_MOD OPf_PARENS
    OPf_REF
    OPf_SPECIAL
    OPf_STACKED
    OPpCONST_BARE
    OPpENTERSUB_AMPER
    OPpLVAL_INTRO
    OPpMULTIDEREF_DELETE
    OPpMULTIDEREF_EXISTS
    OPpOUR_INTRO
    OPpPADRANGE_COUNTSHIFT
    OPpSIGNATURE_FAKE
    OPpSLICE
    OPpSPLIT_ASSIGN
    OPpSPLIT_LEX
    OPpTRANS_COMPLEMENT
    OPpTRANS_DELETE
    OPpTRANS_SQUASH
    PMf_CONTINUE
    PMf_EVAL PMf_ONCE
    PMf_EXTENDED_MORE
    PMf_FOLD PMf_EXTENDED
    PMf_KEEP PMf_GLOBAL
    PMf_MULTILINE
    PMf_SINGLELINE
    SIGNATURE_ACTION_MASK
    SIGNATURE_FLAG_skip
    SIGNATURE_MASK
    SIGNATURE_SHIFT
    SIGNATURE_arg
    SIGNATURE_arg_default_0
    SIGNATURE_arg_default_1
    SIGNATURE_arg_default_const
    SIGNATURE_arg_default_gvsv
    SIGNATURE_arg_default_iv
    SIGNATURE_arg_default_none
    SIGNATURE_arg_default_op
    SIGNATURE_arg_default_padsv
    SIGNATURE_arg_default_undef
    SIGNATURE_array
    SIGNATURE_end
    SIGNATURE_hash
    SIGNATURE_padintro
    SIGNATURE_reload
    SVf_FAKE SVs_RMG
    SVf_ROK SVpad_OUR
    SVpad_TYPED
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
*populate_curcvlex = *B::Deparse::populate_curcvlex;
*re_flags = *B::Deparse::re_flags;
*rv2gv_or_string = *B::Deparse::rv2gv_or_string;
*stash_variable = *B::Deparse::stash_variable;
*stash_variable_name = *B::Deparse::stash_variable_name;
*tr_chr = *B::Deparse::tr_chr;

use strict;
use vars qw/$AUTOLOAD @ISA @EXPORT/;
use warnings ();
require feature;
use types;

our $VERSION = '3.2.0';

our @ISA = qw(Exporter);

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

# The following OPs don't have functions:

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

sub list_const {
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

# placeholder; signatures are handled specially in deparse_sub()
sub pp_signature {
    my($self, $op, $cx) = @_;
    return $self->info_from_string("signature", $op, '');
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

sub retscalar {
    my $name = $_[0]->name;
    # XXX There has to be a better way of doing this scalar-op check.
    #     Currently PL_opargs is not exposed.
    if ($name eq 'null') {
        $name = substr B::ppname($_[0]->targ), 3
    }
    $name =~ /^(?:scalar|pushmark|wantarray|const|gvsv|gv|padsv|rv2gv
                 |rv2sv|av2arylen|anoncode|prototype|srefgen|ref|bless
                 |regcmaybe|regcreset|regcomp|qr|subst|substcont|trans
                 |transr|sassign|chop|schop|chomp|schomp|defined|undef
                 |study|pos|preinc|i_preinc|predec|i_predec|postinc
                 |i_postinc|postdec|i_postdec|pow|multiply|i_multiply
                 |divide|i_divide|modulo|i_modulo|add|i_add|subtract
                 |i_subtract|concat|stringify|left_shift|right_shift|lt
                 |i_lt|gt|i_gt|le|i_le|ge|i_ge|eq|i_eq|ne|i_ne|n_cmp|i_cmp
                 |s_lt|s_gt|s_le|s_ge|s_eq|s_ne|s_cmp|([isn]_)?bit_(?:and|x?or)|negate
                 |i_negate|not|([isn]_)?complement|smartmatch|atan2|sin|cos
                 |rand|srand|exp|log|sqrt|int|hex|oct|abs|length|substr
                 |vec|index|rindex|sprintf|formline|ord|chr|crypt|ucfirst
                 |lcfirst|uc|lc|quotemeta|aelemfast|aelem|exists|helem
                 |pack|join|anonlist|anonhash|push|pop|shift|unshift|xor
                 |andassign|orassign|dorassign|warn|die|reset|nextstate
                 |dbstate|unstack|last|next|redo|dump|goto|exit|open|close
                 |pipe_op|fileno|umask|binmode|tie|untie|tied|dbmopen
                 |dbmclose|select|getc|read|enterwrite|prtf|print|say
                 |sysopen|sysseek|sysread|syswrite|eof|tell|seek|truncate
                 |fcntl|ioctl|flock|send|recv|socket|sockpair|bind|connect
                 |listen|accept|shutdown|gsockopt|ssockopt|getsockname
                 |getpeername|ftrread|ftrwrite|ftrexec|fteread|ftewrite
                 |fteexec|ftis|ftsize|ftmtime|ftatime|ftctime|ftrowned
                 |fteowned|ftzero|ftsock|ftchr|ftblk|ftfile|ftdir|ftpipe
                 |ftsuid|ftsgid|ftsvtx|ftlink|fttty|fttext|ftbinary|chdir
                 |chown|chroot|unlink|chmod|utime|rename|link|symlink
                 |readlink|mkdir|rmdir|open_dir|telldir|seekdir|rewinddir
                 |closedir|fork|wait|waitpid|system|exec|kill|getppid
                 |getpgrp|setpgrp|getpriority|setpriority|time|alarm|sleep
                 |shmget|shmctl|shmread|shmwrite|msgget|msgctl|msgsnd
                 |msgrcv|semop|semget|semctl|hintseval|shostent|snetent
                 |sprotoent|sservent|ehostent|enetent|eprotoent|eservent
                 |spwent|epwent|sgrent|egrent|getlogin|syscall|lock|runcv
                 |i_aelem|n_aelem|s_aelem|aelem_u|i_aelem_u|n_aelem_u|s_aelem_u
                 |u_add|u_multiply|u_subtract
                 |fc)\z/x
}

sub pp_enterxssub { goto &pp_entersub; }

# FIXME: go over
# sub pp_entersub {
#     my $self = shift;
#     my($op, $cx) = @_;
#     return $self->e_method($self->_method($op, $cx))
#         unless null $op->first->sibling;
#     my $prefix = "";
#     my $amper = "";
#     my($kid, @exprs);
#     if ($op->flags & OPf_SPECIAL && !($op->flags & OPf_MOD)) {
# 	$prefix = "do ";
#     } elsif ($op->private & OPpENTERSUB_AMPER) {
# 	$amper = "&";
#     }
#     $kid = $op->first;
#     $kid = $kid->first->sibling; # skip ex-list, pushmark
#     for (; not null $kid->sibling; $kid = $kid->sibling) {
# 	push @exprs, $kid;
#     }
#     my $simple = 0;
#     my $proto = undef;
#     my $lexical;
#     if (is_scope($kid)) {
# 	$amper = "&";
# 	$kid = "{" . $self->deparse($kid, 0) . "}";
#     } elsif ($kid->first->name eq "gv") {
# 	my $gv = $self->gv_or_padgv($kid->first);
# 	my $cv;
# 	if (class($gv) eq 'GV' && class($cv = $gv->CV) ne "SPECIAL"
# 	 || $gv->FLAGS & SVf_ROK && class($cv = $gv->RV) eq 'CV') {
# 	    $proto = $cv->PV if $cv->FLAGS & SVf_POK;
# 	}
# 	$simple = 1; # only calls of named functions can be prototyped
# 	$kid = $self->deparse($kid, 24);
# 	my $fq;
# 	# Fully qualify any sub name that conflicts with a lexical.
# 	if ($self->lex_in_scope("&$kid")
# 	 || $self->lex_in_scope("&$kid", 1))
# 	{
# 	    $fq++;
# 	} elsif (!$amper) {
# 	    if ($kid eq 'main::') {
# 		$kid = '::';
# 	    }
# 	    else {
# 	      if ($kid !~ /::/ && $kid ne 'x') {
# 		# Fully qualify any sub name that is also a keyword.  While
# 		# we could check the import flag, we cannot guarantee that
# 		# the code deparsed so far would set that flag, so we qual-
# 		# ify the names regardless of importation.
# 		if (exists $feature_keywords{$kid}) {
# 		    $fq++ if $self->feature_enabled($kid);
# 		} elsif (do { local $@; local $SIG{__DIE__};
# 			      eval { () = prototype "CORE::$kid"; 1 } }) {
# 		    $fq++
# 		}
# 	      }
# 	      if ($kid !~ /^(?:\w|::)(?:[\w\d]|::(?!\z))*\z/) {
# 		$kid = single_delim("q", "'", $kid, $self) . '->';
# 	      }
# 	    }
# 	}
# 	$fq and substr $kid, 0, 0, = $self->{'curstash'}.'::';
#     } elsif (is_scalar ($kid->first) && $kid->first->name ne 'rv2cv') {
# 	$amper = "&";
# 	$kid = $self->deparse($kid, 24);
#     } else {
# 	$prefix = "";
# 	my $grandkid = $kid->first;
# 	my $arrow = ($lexical = $grandkid->name eq "padcv")
# 		 || B::Deparse::is_subscriptable($grandkid)
# 		    ? ""
# 		    : "->";
# 	$kid = $self->deparse($kid, 24) . $arrow;
# 	if ($lexical) {
# 	    my $padlist = $self->{'curcv'}->PADLIST;
# 	    my $padoff = $grandkid->targ;
# 	    my $padname = $padlist->ARRAYelt(0)->ARRAYelt($padoff);
# 	    my $protocv = $padname->FLAGS & SVpad_STATE
# 		? $padlist->ARRAYelt(1)->ARRAYelt($padoff)
# 		: $padname->PROTOCV;
# 	    if ($protocv->FLAGS & SVf_POK) {
# 		$proto = $protocv->PV
# 	    }
# 	    $simple = 1;
# 	}
#     }

#     # Doesn't matter how many prototypes there are, if
#     # they haven't happened yet!
#     my $declared = $lexical || exists $self->{'subs_declared'}{$kid};
#     if (not $declared and $self->{'in_coderef2text'}) {
# 	no strict 'refs';
# 	no warnings 'uninitialized';
# 	$declared =
# 	       (
# 		 defined &{ ${$self->{'curstash'}."::"}{$kid} }
# 		 && !exists
# 		     $self->{'subs_deparsed'}{$self->{'curstash'}."::".$kid}
# 		 && defined prototype $self->{'curstash'}."::".$kid
# 	       );
#     }
#     if (!$declared && defined($proto)) {
# 	# Avoid "too early to check prototype" warning
# 	($amper, $proto) = ('&');
#     }

#     my $args;
#     my $listargs = 1;
#     if ($declared and defined $proto and not $amper) {
# 	($amper, $args) = $self->check_proto($proto, @exprs);
# 	$listargs = $amper;
#     }
#     if ($listargs) {
# 	$args = join(", ", map(
# 		    ($_->flags & OPf_WANT) == OPf_WANT_SCALAR
# 		 && !retscalar($_)
# 			? $self->maybe_parens_unop('scalar', $_, 6)
# 			: $self->deparse($_, 6),
# 		    @exprs
# 		));
#     }
#     if ($prefix or $amper) {
# 	if ($kid eq '&') { $kid = "{$kid}" } # &{&} cannot be written as &&
# 	if ($op->flags & OPf_STACKED) {
# 	    return $prefix . $amper . $kid . "(" . $args . ")";
# 	} else {
# 	    return $prefix . $amper. $kid;
# 	}
#     } else {
# 	# It's a syntax error to call CORE::GLOBAL::foo with a prefix,
# 	# so it must have been translated from a keyword call. Translate
# 	# it back.
# 	$kid =~ s/^CORE::GLOBAL:://;

# 	my $dproto = defined($proto) ? $proto : "undefined";
# 	my $scalar_proto = $dproto =~ /^;*(?:[\$*_+]|\\.|\\\[[^]]\])\z/;
#         if (!$declared) {
# 	    return "$kid(" . $args . ")";
# 	} elsif ($dproto =~ /^\s*\z/) {
# 	    return $kid;
# 	} elsif ($scalar_proto and is_scalar($exprs[0])) {
# 	    # is_scalar is an excessively conservative test here:
# 	    # really, we should be comparing to the precedence of the
# 	    # top operator of $exprs[0] (ala unop()), but that would
# 	    # take some major code restructuring to do right.
# 	    return $self->maybe_parens_func($kid, $args, $cx, 16);
# 	} elsif (not $scalar_proto and defined($proto) || $simple) { #'
# 	    return $self->maybe_parens_func($kid, $args, $cx, 5);
# 	} else {
# 	    return "$kid(" . $args . ")";
# 	}
#     }
# }

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
	substr($expr0b0->{text}, 1, 0) = ' ';
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

# sub pp_subst
# {
#     my($self, $op, $cx) = @_;
#     my $kid = $op->first;
#     my($binop, $var, $re, @other_ops) = ("", "", "", ());
#     my @body = ();
#     my ($repl, $repl_info);

#     if ($op->flags & OPf_STACKED) {
# 	$binop = 1;
# 	$var = $self->deparse($kid, 20, $op);
# 	$kid = $kid->sibling;
#     }
#     elsif (my $targ = $op->targ) {
# 	$binop = 1;
# 	$var = $self->padname($targ);
#     }
#     my $flags = "";
#     my $pmflags = $op->pmflags;
#     if (B::Deparse::null($op->pmreplroot)) {
# 	$repl = $kid;
# 	$kid = $kid->sibling;
#     } else {
# 	push @other_ops, $op->pmreplroot;
# 	$repl = $op->pmreplroot->first; # skip substcont
#     }
#     while ($repl->name eq "entereval") {
# 	push @other_ops, $repl;
# 	$repl = $repl->first;
# 	    $flags .= "e";
#     }
#     {
# 	local $self->{in_subst_repl} = 1;
# 	if ($pmflags & PMf_EVAL) {
# 	    $repl_info = $self->deparse($repl->first, 0, $repl);
# 	} else {
# 	    $repl_info = $self->dq($repl);
# 	}
#     }
#     my $extended = ($pmflags & PMf_EXTENDED);
#     if (B::Deparse::null $kid) {
# 	my $unbacked = B::Deparse::re_unback($op->precomp);
# 	if ($extended) {
# 	    $re = B::Deparse::re_uninterp_extended(B::Deparse::escape_extended_re($unbacked));
# 	}
# 	else {
# 	    $re = B::Deparse::re_uninterp(B::Deparse::escape_str($unbacked));
# 	}
#     } else {
# 	my ($re_info, $junk) = $self->regcomp($kid, 1, $extended);
# 	push @body, $re_info;
# 	$re = $re_info->{text};
#     }
#     $flags .= "r" if $pmflags & PMf_NONDESTRUCT;
#     $flags .= "e" if $pmflags & PMf_EVAL;
#     $flags .= $self->re_flags($op);
#     $flags = join '', sort split //, $flags;
#     $flags = $substwords{$flags} if $substwords{$flags};
#     my $core_s = $self->keyword("s"); # maybe CORE::s
#     my $info;
#     push @body, $repl_info;
#     my $repl_text = $repl_info->{text};
#     my $opts = {body => \@body};
#     my $opts->{other_ops} = \@other_ops if @other_ops;
#     my $find_replace_re = double_delim($re, $repl_text);
#     my $args = [$var, $find_replace_re];
#     my $args_spec = [0, 1];
#     if ($binop) {
# 	my $fmt = "%c =~ $core_s%c$flags";
# 	return $self->info_from_template("=~ s///", $op, $fmt, $args_spec, $args,
# 					 {maybe_parens => [$self, $cx, 20]});
#     } else {
# 	my $fmt = "$core_s%c$flags";
# 	return $self->info_from_template("s///", $op, $fmt, $args_spec, $args, {});
#     }
#     Carp::confess("unhandled condition in pp_subst");
# }

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

1;
