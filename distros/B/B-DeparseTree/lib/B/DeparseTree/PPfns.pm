# Common routines used by PP Functions
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
use strict; use warnings;

package B::DeparseTree::PPfns;
use Carp;
use B qw(
    OPf_STACKED
    OPf_SPECIAL
    OPpCONST_BARE
    OPpLVAL_INTRO
    OPpREPEAT_DOLIST
    OPpSORT_INTEGER
    OPpSORT_NUMERIC
    OPpSORT_REVERSE
    opnumber
    );

use B::Deparse;
use B::DeparseTree::OPflags;

# Copied from B/const-xs.inc. Perl 5.16 doesn't have this
use constant SVpad_STATE => 11;
use constant SVpad_TYPED => 8;

# FIXME: DRY $is_cperl
# Version specific modification are next...
use Config;
my $is_cperl = $Config::Config{usecperl};

# Copy unchanged functions from B::Deparse
*balanced_delim = *B::Deparse::balanced_delim;
*double_delim = *B::Deparse::double_delim;
*escape_extended_re = *B::Deparse::escape_extended_re;

use B::DeparseTree::SyntaxTree;

our($VERSION, @EXPORT, @ISA);
$VERSION = '3.2.0';
@ISA = qw(Exporter);
@EXPORT = qw(
    %strict_bits
    ambient_pragmas
    anon_hash_or_list
    baseop
    binop
    code_list
    concat
    cops
    dedup_func_parens
    dedup_parens_func
    deparse_binop_left
    deparse_binop_right
    deparse_format
    deparse_op_siblings
    double_delim
    dq
    dq_unop
    dquote
    e_anoncode
    e_method
    elem
    filetest
    for_loop
    func_needs_parens
    givwhen
    indirop
    is_lexical_subs
    is_list_newer
    is_list_older
    listop
    logassignop
    logop
    loop_common
    loopex
    map_texts
    mapop
    matchop
    maybe_local
    maybe_local_str
    maybe_my
    maybe_parens
    maybe_parens_func
    maybe_parens_unop
    maybe_qualify
    maybe_targmy
    _method
    null_newer
    null_older
    pfixop
    pp_padsv
    range
    repeat
    rv2x
    scopeop
    single_delim
    slice
    split
    stringify_newer
    stringify_older
    subst_newer
    subst_older
    unop
    );


# The BEGIN {} is used here because otherwise this code isn't executed
# when you run B::Deparse on itself.
my %globalnames;
BEGIN { map($globalnames{$_}++, "SIG", "STDIN", "STDOUT", "STDERR", "INC",
	    "ENV", "ARGV", "ARGVOUT", "_"); }

BEGIN {
    # List version-specific constants here.
    # Easiest way to keep this code portable between version looks to
    # be to fake up a dummy constant that will never actually be true.
    foreach (qw(
	     CVf_LOCKED
	     OPpCONST_ARYBASE
	     OPpCONST_NOVER
	     OPpEVAL_BYTES
	     OPpITER_REVERSED
	     OPpOUR_INTRO
	     OPpPAD_STATE
	     OPpREVERSE_INPLACE
	     OPpSORT_DESCEND
	     OPpSORT_INPLACE
	     OPpTARGET_MY
	     OPpSUBSTR_REPL_FIRST
	     PMf_EVAL PMf_EXTENDED
	     PMf_NONDESTRUCT
	     PMf_SKIPWHITE
	     RXf_PMf_CHARSET
	     RXf_PMf_KEEPCOPY
	     RXf_SKIPWHITE
	     )) {
	eval { import B $_ };
	no strict 'refs';
	*{$_} = sub () {0} unless *{$_}{CODE};
    }
}

my %strict_bits = do {
    local $^H;
    map +($_ => strict::bits($_)), qw/refs subs vars/
};

BEGIN { for (qw[ pushmark ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

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

my(%left, %right);

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

sub anon_hash_or_list($$$)
{
    my ($self, $op, $cx) = @_;
    my $name = $op->name;
    my($pre, $post) = @{{"anonlist" => ["[","]"],
			 "anonhash" => ["{","}"]}->{$name}};
    my($expr, @exprs);
    my $first_op = $op->first;
    $op = $first_op->sibling; # skip pushmark
    for (; !B::Deparse::null($op); $op = $op->sibling) {
	$expr = $self->deparse($op, 6, $op);
	push @exprs, $expr;
    }
    # if ($pre eq "{" and $cx < 1) {
    # 	# Disambiguate that it's not a block
    # 	$pre = "+{";
    # }

    my $node = $self->info_from_template("$name $pre $post", $op,
					 "$pre%C$post",
					 [[0, $#exprs, ', ']], \@exprs);

    # Set the skipped op as the opener of the list.
    my $position = [0, 1];
    my $first_node = $self->info_from_string($first_op->name, $first_op,
					     $node->{text},
					     {position => $position});
    $node->update_other_ops($first_node);
    return $node;

}

sub assoc_class {
    my $op = shift;
    my $name = $op->name;
    if ($name eq "concat" and $op->first->name eq "concat") {
	# avoid spurious '=' -- see comment in pp_concat
	return "concat";
    }
    if ($name eq "null" and B::class($op) eq "UNOP"
	and $op->first->name =~ /^(and|x?or)$/
	and B::Deparse::null $op->first->sibling)
    {
	# Like all conditional constructs, OP_ANDs and OP_ORs are topped
	# with a null that's used as the common end point of the two
	# flows of control. For precedence purposes, ignore it.
	# (COND_EXPRs have these too, but we don't bother with
	# their associativity).
	return assoc_class($op->first);
    }
    return $name . ($op->flags & B::OPf_STACKED ? "=" : "");
}

# routines implementing classes of ops

sub baseop
{
    my($self, $op, $cx, $name) = @_;
    return $self->info_from_string("baseop $name", $op, $self->keyword($name));
}

# Handle binary operators like +, and assignment
sub binop
{

    my ($self, $op, $cx, $opname, $prec) = @_;
    my ($flags, $type) = (0, '');
    if (scalar(@_) > 5) {
	$flags = $_[5];
	$type = $_[6] if (scalar(@_) > 6);
    }
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    if ($op->flags & B::OPf_STACKED && $flags & B::Deparse::ASSIGN) {
	$eq = "=";
	$prec = 7;
    }
    if ($flags & SWAP_CHILDREN) {
	($left, $right) = ($right, $left);
    }
    my $lhs = $self->deparse_binop_left($op, $left, $prec);
    if ($flags & LIST_CONTEXT
	&& $lhs->{text} !~ /^(my|our|local|)[\@\(]/) {
	$lhs->{maybe_parens} ||= {};
	$lhs->{maybe_parens}{force} = 'true';
	$lhs->{text} = "($lhs->{text})";
    }

    my $rhs = $self->deparse_binop_right($op, $right, $prec);
    if ($flags & SWAP_CHILDREN) {
	# Not sure why this is right
	$lhs->{prev_expr} = $rhs;
    } else {
	$rhs->{prev_expr} = $lhs;
    }

    $type = $type || 'binary operator';
    $type .= " $opname$eq";
    my $node = $self->info_from_template($type, $op, "%c $opname$eq %c",
					 undef, [$lhs, $rhs],
					 {maybe_parens => [$self, $cx, $prec]});
    $node->{prev_expr} = $rhs;
    return $node;
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
	     'bit_and' => 13, 'nbit_and' => 13, 'sbit_and' => 13,
	     'bit_or' => 12, 'bit_xor' => 12,
	     'sbit_or' => 12, 'sbit_xor' => 12,
	     'nbit_or' => 12, 'nbit_xor' => 12,
	     'and' => 3,
	     'or' => 2, 'xor' => 2,
	    );
}

sub code_list {
    my ($self, $op, $cv) = @_;

    # localise stuff relating to the current sub
    $cv and
	local($self->{'curcv'}) = $cv,
	local($self->{'curcvlex'}),
	local(@$self{qw'curstash warnings hints hinthash curcop'})
	    = @$self{qw'curstash warnings hints hinthash curcop'};

    my $re;
    for ($op = $op->first->sibling; !B::Deparse::null($op); $op = $op->sibling) {
	if ($op->name eq 'null' and $op->flags & OPf_SPECIAL) {
	    my $scope = $op->first;
	    # 0 context (last arg to scopeop) means statement context, so
	    # the contents of the block will not be wrapped in do{...}.
	    my $block = scopeop($scope->first->name eq "enter", $self,
				$scope, 0);
	    # next op is the source code of the block
	    $op = $op->sibling;
	    $re .= ($self->const_sv($op)->PV =~ m|^(\(\?\??\{)|)[0];
	    my $multiline = $block =~ /\n/;
	    $re .= $multiline ? "\n\t" : ' ';
	    $re .= $block;
	    $re .= $multiline ? "\n\b})" : " })";
	} else {
	    $re = B::Deparse::re_dq_disambiguate($re, $self->re_dq($op));
	}
    }
    $re;
}

# Concatenation or '.' is special because concats-of-concats are
# optimized to save copying by making all but the first concat
# stacked. The effect is as if the programmer had written:
#   ($a . $b) .= $c'
# but the above is illegal.

sub concat {
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
    my $rhs = $self->deparse_binop_right($op, $right, $prec);
    return $self->info_from_template(".$eq", $op,
				     "%c .$eq %c", undef, [$lhs, $rhs],
				     {maybe_parens => [$self, $cx, $prec]});
}

# Handle pp_dbstate, and pp_nextstate and COP ops.
#
# Notice how subs and formats are inserted between statements here;
# also $[ assignments and pragmas.

sub cops
{
    my ($self, $op, $cx, $name) = @_;
    $self->{'curcop'} = $op;
    my @texts = ();
    my $opts = {};
    my @args_spec = ();
    my $fmt = '%;';

    push @texts, $self->B::Deparse::cop_subs($op);

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
		    = B::Deparse::_features_from_bundle($from,
							$self->{'hinthash'});
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
	$fmt .= "%c\n";
	push @args_spec, scalar(@args_spec);
	push @texts, $op->label . ": " ;
    }

    my $node = $self->info_from_template($name, $op, $fmt,
					 \@args_spec, \@texts, $opts);
    return $node;
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
    while (not B::Deparse::null $op) {
	push @{$op->{other_ops}}, $op;
	$op = $op->sibling; # skip nextstate
	my @body;
	push @{$op->{other_ops}}, $op->first;
	$kid = $op->first->sibling; # skip a pushmark
	push @texts, "\f".$self->const_sv($kid)->PV;
	push @{$op->{other_ops}}, $kid;
	$kid = $kid->sibling;
	for (; not B::Deparse::null $kid; $kid = $kid->sibling) {
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

sub dedup_func_parens($$)
{
    my $self = shift;
    my ($args_ref) = @_;
    my @args = @$args_ref;
    return (
	scalar @args == 1 &&
	substr($args[0]->{text}, 0, 1) eq '(' &&
	substr($args[0]->{text}, 0, 1) eq ')');
}

sub dedup_parens_func($$$)
{
    my $self = shift;
    my $sub_info = shift;
    my ($args_ref) = @_;
    my @args = @$args_ref;
    if (scalar @args == 1 && substr($args[0], 0, 1) eq '(' &&
	substr($args[0], -1, 1) eq ')') {
	return ($sub_info, $self->combine(', ', \@args), );
    } else {
	return ($sub_info, '(', $self->combine(', ', \@args), ')', );
    }
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

# Iterate via sibling links a list of OP nodes starting with
# $first. Each OP is deparsed, with $op and $precedence each to get a
# node. Then the "prev" field in the node is set, and finally it is
# pushed onto the end of the $exprs reference ARRAY.
sub deparse_op_siblings($$$$$)
{
    my ($self, $exprs, $kid, $op, $precedence) = @_;
    my $prev_expr = undef;
    $prev_expr = $exprs->[-1] if scalar @{$exprs};
    for ( ; !B::Deparse::null($kid); $kid = $kid->sibling) {
	my $expr = $self->deparse($kid, $precedence, $op);
	if (defined $expr) {
	    $expr->{prev_expr} = $prev_expr;
	    $prev_expr = $expr;
	    push @$exprs, $expr;
	}
    }
}


# tr/// and s/// (and tr[][], tr[]//, tr###, etc)
# note that tr(from)/to/ is OK, but not tr/from/(to)
sub double_delim {
    my($from, $to) = @_;
    my($succeed, $delim);
    if ($from !~ m[/] and $to !~ m[/]) {
	return "/$from/$to/";
    } elsif (($succeed, $from) = B::Deparse::balanced_delim($from) and $succeed) {
	if (($succeed, $to) = B::Deparse::balanced_delim($to) and $succeed) {
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

sub dq($$$)
{
    my ($self, $op, $parent) = @_;
    my $type = $op->name;
    my $info;
    if ($type eq "const") {
	return info_from_text($op, $self, '$[', 'dq constant ary', {}) if $op->private & OPpCONST_ARYBASE;
	return info_from_text($op, $self,
			      B::Deparse::uninterp(B::Deparse::escape_str(B::Deparse::unback($self->const_sv($op)->as_string))),
			 'dq constant', {});
    } elsif ($type eq "concat") {
	my $first = $self->dq($op->first, $op);
	my $last  = $self->dq($op->last, $op);

	# FIXME: convert to newer conventions
	# Disambiguate "${foo}bar", "${foo}{bar}", "${foo}[1]", "$foo\::bar"
	($last->{text} =~ /^[A-Z\\\^\[\]_?]/ &&
	    $first->{text} =~ s/([\$@])\^$/${1}{^}/)  # "${^}W" etc
	    || ($last->{text} =~ /^[:'{\[\w_]/ && #'
		$first->{text} =~ s/([\$@])([A-Za-z_]\w*)$/${1}{$2}/);

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

# Handle unary operators that can occur as pseudo-listops inside
# double quotes
sub dq_unop
{
    my($self, $op, $cx, $name, $prec, $flags) = (@_, 0, 0);
    my $kid;
    if ($op->flags & B::OPf_KIDS) {
	my $pushmark_op = undef;
	$kid = $op->first;
	if (not B::Deparse::null $kid->sibling) {
	    # If there's more than one kid, the first is an ex-pushmark.
	    $pushmark_op = $kid;
	    $kid = $kid->sibling;
	}
	my $info = $self->maybe_parens_unop($name, $kid, $cx, $op);
	if ($pushmark_op) {
	    # For the pushmark opc we'll consider it the "name" portion
	    # of info. We examine that to get the text.
	    my $text = $info->{text};
	    my $word_end = index($text, ' ');
	    $word_end = length($text) unless $word_end > 0;
	    my $pushmark_info =
		$self->info_from_string("dq $name", $op, $text,
					{position => [0, $word_end]});
	    $info->{other_ops} = [$pushmark_info];
	    # $info->{other_ops} = [$pushmark_op];
	}
	return $info;
    } else {
	$name .= '()' if $op->flags & B::OPf_SPECIAL;
	return $self->info_from_string("dq $name", $op, $name)
    }
    Carp::confess("unhandled condition in dq_unop");
}

sub dquote
{
    my($self, $op, $cx) = @_;
    # FIXME figure out how to use this
    my $skipped_ops = [$op->first];
    my $kid = $op->first->sibling; # skip ex-stringify, pushmark
    return $self->deparse($kid, $cx, $op) if $self->{'unquote'};
    $self->maybe_targmy($kid, $cx,
			sub {$self->single_delim($kid, "qq", '"',
						 $self->info2str($self->dq($_[1], $op))
				                 )});
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

sub e_anoncode($$)
{
    my ($self, $info) = @_;
    my $sub_info = $self->deparse_sub($info->{code});
    return $self->info_from_template('sub anonymous', $sub_info->{op},
				     'sub %c', [0], [$sub_info]);
}

# Handle filetest operators -r, stat, etc.
sub filetest
{
    my($self, $op, $cx, $name) = @_;
    if (B::class($op) eq "UNOP") {
	# Genuine '-X' filetests are exempt from the LLAFR, but not
	# l?stat()
	if ($name =~ /^-/) {
	    my $kid = $self->deparse($op->first, 16, $op);
	    return $self->info_from_template("filetest $name", $op,
					     "$name %c", undef, [$kid],
					     {maybe_parens => [$self, $cx, 16]});
	}
	return $self->maybe_parens_unop($name, $op->first, $cx, $op);
    } elsif (B::class($op) =~ /^(SV|PAD)OP$/) {
	my ($fmt, $type);
	my $gv_node = $self->pp_gv($op, 1);
	if ($self->func_needs_parens($gv_node->{text}, $cx, 16)) {
	    $fmt = "$name(%c)";
	    $type = "filetest $name()";
	} else {
	    $fmt = "$name %c";
	    $type = "filetest $name";
	}
	return $self->info_from_template($type, $op, $fmt, undef, [$gv_node]);
    } else {
	# I don't think baseop filetests ever survive ck_filetest, but...
	return $self->info_from_string("filetest $name", $op, $name);
    }
}

sub for_loop($$$$) {
    my ($self, $op, $cx, $parent) = @_;
    my $init = $self->deparse($op, 1, $parent);
    my $s = $op->sibling;
    my $ll = $s->name eq "unstack" ? $s->sibling : $s->first->sibling;
    return $self->loop_common($ll, $cx, $init);
}

# Returns in function (whose name is not passed as a parameter) will
# need to surround its argements (the first argument is $first_param)
# in parenthesis. To determine this, we also pass in the operator
# precedence, $prec, and the current expression context value, $cx
sub func_needs_parens($$$$)
{
    my($self, $first_param, $cx, $prec) = @_;
    return ($prec <= $cx) || (substr($first_param, 0, 1) eq "(") || $self->{'parens'};
}

sub givwhen
{
    my($self, $op, $cx, $give_when) = @_;

    my @arg_spec = ();
    my @nodes = ();
    my $enterop = $op->first;
    my $fmt;
    my ($head, $block);
    if ($enterop->flags & B::OPf_SPECIAL) {
	$head = $self->keyword("default");
	$fmt = "$give_when ($head)\n\%+%c\n%-}\n";
	$block = $self->deparse($enterop->first, 0, $enterop, $op);
    }
    else {
	my $cond = $enterop->first;
	my $cond_node = $self->deparse($cond, 1, $enterop, $op);
	push @nodes, $cond_node;
	$fmt = "$give_when (%c)\n\%+%c\n%-}\n";
	$block = $self->deparse($cond->sibling, 0, $enterop, $op);
    }
    push @nodes, $block;

    return $self->info_from_template("{} $give_when",
				     "%c\n\%+%c\n%-}\n", [0, 1],
				     \@nodes);
}

# Handles the indirect operators, print, say(), sort()
sub indirop
{
    my($self, $op, $cx, $name) = @_;
    my($expr, @exprs);
    my $firstkid = my $kid = $op->first->sibling;
    my $indir_info = undef;
    my $type = $name;
    my $first_op = $op->first;
    my @skipped_ops = ($first_op);
    my @indir = ();
    my @args_spec;

    my $fmt = '';

    if ($op->flags & OPf_STACKED) {
	push @skipped_ops, $kid;
	my $indir_op = $kid->first; # skip rv2gv
	if (B::Deparse::is_scope($indir_op)) {
	    $indir_info = $self->deparse($indir_op, 0, $op);
	    if ($indir_info->{text} eq '') {
		$fmt = '{;}';
	    } else {
		$fmt = '{%c}';
	    }
	} elsif ($indir_op->name eq "const" && $indir_op->private & OPpCONST_BARE) {
	    $fmt = $self->const_sv($indir_op)->PV;
	} else {
	    $indir_info = $self->deparse($indir_op, 24, $op);
	    $fmt = '%c';
	}
	$fmt .= ' ';
	$kid = $kid->sibling;
    }

    if ($name eq "sort" && $op->private & (OPpSORT_NUMERIC | OPpSORT_INTEGER)) {
	$type = 'indirop sort numeric or integer';
	$fmt = ($op->private & OPpSORT_DESCEND)
	    ? '{$b <=> $a} ': '{$a <=> $b} ';
    } elsif ($name eq "sort" && $op->private & OPpSORT_DESCEND) {
	$type = 'indirop sort descend';
	$fmt = '{$b cmp $a} ';
    }

    # FIXME: turn into a function;
    my $prev_expr = $exprs[-1];
    for (; !B::Deparse::null($kid); $kid = $kid->sibling) {
	# This prevents us from using deparse_op_siblings
	my $operator_context;
	if (!$fmt && $kid == $firstkid
	    && $name eq "sort"
	    && $firstkid->name =~ /^enter(xs)?sub/) {
	    $operator_context = 16;
	} else {
	    $operator_context = 6;
	}
	$expr = $self->deparse($kid, $operator_context, $op);
	if (defined $expr) {
	    $expr->{prev_expr} = $prev_expr;
	    $prev_expr = $expr;
	    push @exprs, $expr;
	}
    }

    # Extend $name possibly by adding "reverse".
    my $name2;
    if ($name eq "sort" && $op->private & OPpSORT_REVERSE) {
	$name2 = $self->keyword('reverse') . ' ' . $self->keyword('sort');
    } else {
	$name2 = $self->keyword($name)
    }

    if ($name eq "sort" && ($op->private & OPpSORT_INPLACE)) {
	$fmt = "%c = $name2 $fmt %c";
	# FIXME: do better with skipped ops
	return $self->info_from_template("indirop sort inplace", $op, $fmt,
					 [0, 0], \@exprs,
	                                 {prev_expr => $prev_expr});
    }


    my $node;
    $prev_expr = $exprs[-1];
    if ($fmt ne "" && $name eq "sort") {
	# We don't want to say "sort(f 1, 2, 3)", since perl -w will
	# give bareword warnings in that case. Therefore if context
	# requires, we'll put parens around the outside "(sort f 1, 2,
	# 3)". Unfortunately, we'll currently think the parens are
	# necessary more often that they really are, because we don't
	# distinguish which side of an assignment we're on.
	$node = $self->info_from_template($name2, $op,
					  "$name2 %C",
					  [[0, $#exprs, ', ']],
					  \@exprs,
					 {
					     other_ops => \@skipped_ops,
					     maybe_parens => {
						 context => $cx,
						 precedence => 5},
					     prev_expr => $prev_expr
					 });

    } elsif (!$fmt && $name eq "sort"
	     && !B::Deparse::null($op->first->sibling)
	     && $op->first->sibling->name eq 'entersub' ) {
	# We cannot say sort foo(bar), as foo will be interpreted as a
	# comparison routine.  We have to say sort(...) in that case.
	$node = $self->info_from_template("indirop $name2()", $op,
					  "$name2(%C)",
					  [[0, $#exprs, ', ']],
					  \@exprs,
					  {other_ops => \@skipped_ops,
					   prev_expr => $prev_expr});

    } else {
	if (@exprs) {
	    my $type = "indirop";
	    my $args_fmt;
	    if ($self->func_needs_parens($exprs[0]->{text}, $cx, 5)) {
		$type = "indirop $name2()";
		$args_fmt = "(%C)";
	    } else {
		$type = "indirop $name2";
		$args_fmt = "%C";
	    }
	    @args_spec = ([0, $#exprs, ', ']);
	    if ($fmt) {
		$fmt = "${name2} ${fmt}${args_fmt}";
		if ($indir_info) {
		    unshift @exprs, $indir_info;
		    @args_spec = (0, [1, $#exprs, ', ']);
		}
	    } else {
		if (substr($args_fmt, 0, 1) eq '(') {
		    $fmt = "${name2}$args_fmt";
		} else {
		    $fmt = "${name2} $args_fmt";
		}
		@args_spec = [0, $#exprs, ', '];
	    }

	    $node = $self->info_from_template($type, $op, $fmt,
					      \@args_spec, \@exprs,
                                              {prev_expr => $prev_expr});
	} else {
	    $type="indirop $name2";
	    # Should this be maybe_parens()?
	    $type .= '()' if (7 < $cx);  # FIXME - do with format specifier
	    $node = $self->info_from_string($type, $op, $name2);
	}
    }

    # Handle skipped ops
    my @new_ops;
    my $position = [0, length($name2)];
    my $str = $node->{text};
    foreach my $skipped_op (@skipped_ops) {
	my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
					     {position => $position});
	push @new_ops, $new_op;
    }
    $node->{other_ops} = \@new_ops;
    return $node;
    }

# 5.16 doesn't have this so we include it, even though it's not
# going to get used?
sub is_lexical_subs {
    my (@ops) = shift;
    for my $op (@ops) {
        return 0 if $op->name !~ /\A(?:introcv|clonecv)\z/;
    }
    return 1;
}

# The version of null_op_list after 5.22
# Note: this uses "op" not "kid"
sub is_list_newer($$) {
    my ($self, $op) = @_;
    my $kid = $op->first;
    return 1 if $kid->name eq 'pushmark';
    return ($kid->name eq 'null'
	    && $kid->targ == OP_PUSHMARK
	    && B::Deparse::_op_is_or_was($op, B::Deparse::OP_LIST));
}


# The version of null_op_list before 5.22
# Note: this uses "kid", not "op"
sub is_list_older($) {
    my ($self, $kid) = @_;
    # Something may be funky where without the convesion we are getting ""
    # as a return
    return ($kid->name eq 'pushmark') ? 1 : 0;
}

# This handle logical ops: "if"/"until", "&&", "and", ...
# The one-line "while"/"until" is handled in pp_leave.
sub logop
{
    my ($self, $op, $cx, $lowop, $lowprec, $highop,
	$highprec, $blockname) = @_;
    my $left = $op->first;
    my $right = $op->first->sibling;
    my ($lhs, $rhs, $type, $opname);
    my $opts = {};
    if ($cx < 1 and B::Deparse::is_scope($right) and $blockname
	and $self->{'expand'} < 7) {
	# Is this branch used in 5.26 and above?
	# <if> ($a) {$b}
	my $if_cond_info = $self->deparse($left, 1, $op);
	my $if_body_info = $self->deparse($right, 0, $op);
	return $self->info_from_template("$blockname () {}", $op,
					 "$blockname (%c) {\n%+%c\n%-}",
					 [0, 1],
					 [$if_cond_info, $if_body_info], $opts);
    } elsif ($cx < 1 and $blockname and not $self->{'parens'}
	     and $self->{'expand'} < 7) { # $b if $a
	# Note: order of lhs and rhs is reversed
	$lhs = $self->deparse($right, 1, $op);
	$rhs = $self->deparse($left, 1, $op);
	$opname = $blockname;
	$type = "suffix $opname"
    } elsif ($cx > $lowprec and $highop) {
	# low-precedence operator like $a && $b
	$lhs = $self->deparse_binop_left($op, $left, $highprec);
	$rhs = $self->deparse_binop_right($op, $right, $highprec);
	$opname = $highop;
	$opts = {maybe_parens => [$self, $cx, $highprec]};
    } else {
	# high-precedence operator like $a and $b
	$lhs = $self->deparse_binop_left($op, $left, $lowprec);
	$rhs = $self->deparse_binop_right($op, $right, $lowprec);
	$opname = $lowop;
	$opts = {maybe_parens => [$self, $cx, $lowprec]};
    }
    $type ||= $opname;
    return $self->info_from_template($type, $op, "%c $opname %c",
				     [0, 1], [$lhs, $rhs], $opts);
}

# This handle list ops: "open", "pack", "return" ...
sub listop
{
    my($self, $op, $cx, $name, $kid, $nollafr) = @_;
    my(@exprs, @new_nodes, @skipped_ops);
    my $parens = ($cx >= 5) || $self->{'parens'};

    unless ($kid) {
	push @skipped_ops, $op->first;
	$kid = $op->first->sibling;
    }

    # If there are no arguments, add final parentheses (or parenthesize the
    # whole thing if the llafr does not apply) to account for cases like
    # (return)+1 or setpgrp()+1.  When the llafr does not apply, we use a
    # precedence of 6 (< comma), as "return, 1" does not need parentheses.
    if (B::Deparse::null $kid) {
	my $fullname = $self->keyword($name);
	my $text = $nollafr
	    ? $self->maybe_parens($fullname, $cx, 7)
	    : $fullname . '()' x (7 < $cx);
	return $self->info_from_string("listop $name", $op, $text);
    }
    my $first;
    my $fullname = $self->keyword($name);
    my $proto = prototype("CORE::$name");
    if (
	 (     (defined $proto && $proto =~ /^;?\*/)
	    || $name eq 'select' # select(F) doesn't have a proto
	 )
	 && $kid->name eq "rv2gv"
	 && !($kid->private & B::OPpLVAL_INTRO)
    ) {
	$first = $self->rv2gv_or_string($kid->first, $op);
    }
    else {
	$first = $self->deparse($kid, 6, $op);
    }
    if ($name eq "chmod" && $first->{text} =~ /^\d+$/) {
	my $transform_fn = sub {sprintf("%#o", $self->info2str(shift))};
	$first = $self->info_from_template("chmod octal", undef,
					   "%F", [[0, $transform_fn]],
					   [$first], {'relink_children' => [0]});
	push @new_nodes, $first;
    }

    # FIXME: fold this into a template
    $first->{text} = "+" + $first->{text}
	if not $parens and not $nollafr and substr($first->{text}, 0, 1) eq "(";

    push @exprs, $first;
    $kid = $kid->sibling;
    if (defined $proto && $proto =~ /^\*\*/ && $kid->name eq "rv2gv"
	&& !($kid->private & B::OPpLVAL_INTRO)) {
	$first = $self->rv2gv_or_string($kid->first, $op);
	push @exprs, $first;
	$kid = $kid->sibling;
    }

    $self->deparse_op_siblings(\@exprs, $kid, $op, 6);

    if ($name eq "reverse" && ($op->private & B::OPpREVERSE_INPLACE)) {
	my $fmt;
	my $type;
	if ($parens) {
	    $fmt = "%c = $fullname(%c)";
	    $type = "listop reverse ()"
	} else {
	    $fmt = "%c = $fullname(%c)";
	    $type = "listop reverse"
	}
	my @nodes = ($exprs[0], $exprs[0]);
	return $self->info_from_template($type, $op, $fmt, undef,
					 [$exprs[0], $exprs[0]]);
    }

    my $opts = {};
    my $type;
    my $fmt;

    if ($name =~ /^(system|exec)$/
	&& ($op->flags & B::OPf_STACKED)
	&& @exprs > 1)
    {
	# handle the "system(prog a1, a2, ...)" form
	# where there is no ', ' between the first two arguments.
	if ($parens && $nollafr) {
	    $fmt = "($fullname %c %C)";
	    $type = "listop ($fullname)";
	} elsif ($parens) {
	    $fmt = "$fullname(%c %C)";
	    $type = "listop $fullname()";
	} else {
	    $fmt = "$fullname %c %C";
	    $type = "listop $fullname";
	}
	return $self->info_from_template($type, $op, $fmt,
					 [0, [1, $#exprs, ', ']], \@exprs);

    }

    $fmt = "%c %C";
    if ($parens && $nollafr) {
	# FIXME: do with parens mechanism
	$fmt = "($fullname %C)";
	$type = "listop ($fullname)";
    } elsif ($parens) {
	$fmt = "$fullname(%C)";
	$type = "listop $fullname()";
    } else {
	$fmt = "$fullname %C";
	$type = "listop $fullname";
    }
    $opts->{synthesized_nodes} = \@new_nodes if @new_nodes;
    my $node = $self->info_from_template($type, $op, $fmt,
					 [[0, $#exprs, ', ']], \@exprs,
					 $opts);
    $node->{prev_expr} = $exprs[-1];
    if (@skipped_ops) {
	# if we have skipped ops like pushmark, we will use $full name
	# as the part it represents.
	## FIXME
	my @new_ops;
	my $position = [0, length($fullname)];
	my $str = $node->{text};
	my @skipped_nodes;
	for my $skipped_op (@skipped_ops) {
	    my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
						 {position => $position});
	    push @new_ops, $new_op;
	}
	$node->{other_ops} = \@new_ops;
    }
    return $node;
}

sub loop_common
{
    my $self = shift;
    my($op, $cx, $init) = @_;
    my $enter = $op->first;
    my $kid = $enter->sibling;

    my @skipped_ops = ($enter);
    local(@$self{qw'curstash warnings hints hinthash'})
		= @$self{qw'curstash warnings hints hinthash'};

    my ($body, @body);
    my @nodes = ();
    my ($bare, $cond_info) = (0, undef);
    my $fmt = '';
    my $var_fmt;
    my @args_spec = ();
    my $opts = {};
    my $type = 'loop';

    if ($kid->name eq "lineseq") {
	# bare or infinite loop
	$type .= ' while (1)';

	if ($kid->last->name eq "unstack") { # infinite
	    $fmt .= 'while (1)';
	} else {
	    $bare = 1;
	}
	$body = $kid;
    } elsif ($enter->name eq "enteriter") {
	# foreach
	$type .= ' foreach';

	my $ary = $enter->first->sibling; # first was pushmark
	push @skipped_ops, $enter->first, $ary->first->sibling;
	my ($ary_fmt, $var_info);
	my $var = $ary->sibling;
	if (B::Deparse::null $var) {
	    if (($enter->flags & B::OPf_SPECIAL) && ($] < 5.009)) {
		# thread special var, under 5005threads
		$var_fmt = $self->pp_threadsv($enter, 1);
	    } else { # regular my() variable
		$var_info = $self->pp_padsv($enter, 1, 1);
		push @nodes, $var_info;
		$var_fmt = '%c';
		push @args_spec, $#nodes;
	    }
	} elsif ($var->name eq "rv2gv") {
	    $var_info = $self->pp_rv2sv($var, 1);
	    push @nodes, $var_info;
	    if ($enter->private & B::OPpOUR_INTRO) {
		# "our" declarations don't have package names
		my $transform_fn = sub {$_[0] =~ s/^(.).*::/$1/};
		$var_fmt = "our %F";
		push @args_spec, [$#nodes, $transform_fn];
	    } else {
		$var_fmt = '%c';
		push @args_spec, $#nodes;
	    }
	} elsif ($var->name eq "gv") {
	    $var_info = $self->deparse($var, 1, $op);
	    push @nodes, $var_info;
	    $var_fmt = '$%c';
	    push @args_spec, $#nodes;
	}

	if ($ary->name eq 'null' and $enter->private & B::OPpITER_REVERSED) {
	    # "reverse" was optimised away
	    push @nodes, listop($self, $ary->first->sibling, 1, 'reverse');
	    $ary_fmt = "%c";
	    push @args_spec, $#nodes;
	} elsif ($enter->flags & B::OPf_STACKED
		 and not B::Deparse::null $ary->first->sibling->sibling) {
	    push @args_spec, scalar(@nodes), scalar(@nodes+1);
	    push @nodes, ($self->deparse($ary->first->sibling, 9, $op),
			 $self->deparse($ary->first->sibling->sibling, 9, $op));
	    $ary_fmt = '(%c .. %c)';

	} else {
	    push @nodes, $self->deparse($ary, 1, $op);
	    $ary_fmt = "%c";
	    push @args_spec, $#nodes;
	}

	# skip OP_AND and OP_ITER
	push @skipped_ops, $kid->first, $kid->first->first;
	$body = $kid->first->first->sibling;

	if (!B::Deparse::is_state $body->first
	    and $body->first->name !~ /^(?:stub|leave|scope)$/) {
	    # FIXME:
	   #  Carp::confess("var ne \$_") unless join('', @var_text) eq '$_';
	    push @skipped_ops, $body->first;
	    $body = $body->first;
	    my $body_info = $self->deparse($body, 2, $op);
	    push @nodes, $body_info;
	    return $self->info_from_template("foreach", $op,
					     "$var_fmt foreach ($ary_fmt)",
					     \@args_spec, \@nodes,
					     {other_ops => \@skipped_ops});
	}
	$fmt = "foreach $var_fmt $ary_fmt";
    } elsif ($kid->name eq "null") {
	# while/until

	$kid = $kid->first;
	my $name = {"and" => "while", "or" => "until"}->{$kid->name};
	$type .= " $name";
	$cond_info = $self->deparse($kid->first, 1, $op);
	$fmt = "$name (%c) ";
	push @nodes, $cond_info;
	$body = $kid->first->sibling;
	@args_spec = (0);
    } elsif ($kid->name eq "stub") {
	# bare and empty
	return info_from_text($op, $self, '{;}', 'empty loop', {});
    }

    # If there isn't a continue block, then the next pointer for the loop
    # will point to the unstack, which is kid's last child, except
    # in a bare loop, when it will point to the leaveloop. When neither of
    # these conditions hold, then the second-to-last child is the continue
    # block (or the last in a bare loop).
    my $cont_start = $enter->nextop;
    my ($cont, @cont_text, $body_info);
    my @cont = ();
    if ($$cont_start != $$op && ${$cont_start} != ${$body->last}) {
	$type .= ' continue';

	if ($bare) {
	    $cont = $body->last;
	} else {
	    $cont = $body->first;
	    while (!B::Deparse::null($cont->sibling->sibling)) {
		$cont = $cont->sibling;
	    }
	}
	my $state = $body->first;
	my $cuddle = " ";
	my @states;
	for (; $$state != $$cont; $state = $state->sibling) {
	    push @states, $state;
	}
	$body_info = $self->lineseq(undef, 0, @states);
	if (defined $cond_info
	    and not B::Deparse::is_scope($cont)
	    and $self->{'expand'} < 3) {
	    my $cont_info = $self->deparse($cont, 1, $op);
	    my $init = defined($init) ? $init : ' ';
	    @nodes = ($init, $cond_info, $cont_info);
	    # @nodes_text = ('for', '(', "$init_text;", $cont_info->{text}, ')');
	    $fmt = 'for (%c; %c; %c) ';
	    @args_spec = (0, 1, 2);
	    $opts->{'omit_next_semicolon'} = 1;
	} else {
	    my $cont_info = $self->deparse($cont, 0, $op);
	    @nodes =  ($init, $cont_info);
	    @args_spec = (0, 1);
	    $opts->{'omit_next_semicolon'} = 1;
	    @cont_text = ($cuddle, 'continue', "{\n\t",
			  $cont_info->{text} , "\n\b}");
	}
    } else {
	return info_from_text($op, $self, '', 'loop_no_body', {})
	    if !defined $body;
	if (defined $init) {
	    @nodes = ($init, $cond_info);
	    $fmt = 'for (%c; %c;) ';
	    @args_spec = (0, 1);
	}
	$opts->{'omit_next_semicolon'} = 1;
	$body_info = $self->deparse($body, 0, $op);
    }

    # (my $body_text = $body_info->{text}) =~ s/;?$/;\n/;
    # my @texts = (@nodes_text, "{\n\t", $body_text, "\b}", @cont_text);

    push @nodes, $body_info;
    push @args_spec, $#nodes;
    $fmt .= " {\n%+%c%-\n}";
    if (@cont_text) {
	push @nodes, @cont_text;
	push @args_spec, $#nodes;
	$type .= ' cont';
	$fmt .= '%c';
    }
    return $self->info_from_template($type, $op, $fmt, \@args_spec, \@nodes, $opts)
}

# loop expressions
sub loopex
{
    my ($self, $op, $cx, $name) = @_;
    my $opts = {maybe_parens => [$self, $cx, 7]};
    if (B::class($op) eq "PVOP") {
	return info_from_list($op, $self, [$name, $op->pv], ' ',
			      "loop $name $op->pv", $opts);
    } elsif (B::class($op) eq "OP") {
	# no-op
	return $self->info_from_string("loopex op $name",
				       $op, $name,  $opts);
    } elsif (B::class($op) eq "UNOP") {
	(my $kid_info = $self->deparse($op->first, 7)) =~ s/^\cS//;
	# last foo() is a syntax error. So we might surround it with parens.
	my $transform_fn = sub {
	    my $text = shift->{text};
	    $text = "($text)" if $text =~ /^(?!\d)\w/;
	    return $text;
	};
	return $self->info_from_template("loopex unop $name",
					 $op, "$name %F",
					 undef, [$kid_info], $opts);
    } else {
	return $self->info_from_string("loop $name",
				       $op, $name, "loop $name", $opts);
    }
    Carp::confess("unhandled condition in lopex");
}

# Logical assignment operations, e.g. ||= &&=, //=
sub logassignop
{
    my ($self, $op, $cx, $opname) = @_;
    my $left_op = $op->first;

    my $sassign_op = $left_op->sibling;
    my $right_op = $sassign_op->first; # skip sassign
    my $left_node = $self->deparse($left_op, 7, $op);
    my $right_node = $self->deparse($right_op, 7, $op);
    my $node = $self->info_from_template(
	"logical assign $opname", $op,
	"%c $opname %c", undef, [$left_node, $right_node],
	{other_ops => [$op->first->sibling],
	 maybe_parens => [$self, $cx, 7]});

    # Handle skipped sassign
    my $str = $node->{text};
    my $position = [length($left_node->{text})+1, length($opname)];
    my $new_op = $self->info_from_string($sassign_op->name, $sassign_op, $str,
					 {position => $position});
    $node->{other_ops} = [$new_op];
    return $node;

}

sub mapop
{
    my($self, $op, $cx, $name) = @_;
    my $kid = $op->first; # this is the (map|grep)start

    my @skipped_ops = ($kid, $kid->first);
    $kid = $kid->first->sibling; # skip a pushmark

    my $code_block = $kid->first; # skip a null

    my ($code_block_node, @nodes);
    my ($fmt, $first_arg_fmt, $is_block);
    my $type = "map $name";
    my @args_spec = ();

    if (B::Deparse::is_scope $code_block) {
	$code_block_node = $self->deparse($code_block, 0, $op);
	my $transform_fn = sub {
	    # remove first \n in block.
	    ($_[0]->{text})=~ s/^\n\s*//;
	    return $_[0]->{text};
	};
	push @args_spec, [0, $transform_fn];
	$first_arg_fmt = '{ %F }';

	## Alternate simpler form:
	# push @args_spec, 0;
	# $first_arg_fmt = '{ %c }';
	$type .= " block";
	$is_block = 1;

    } else {
	$code_block_node = $self->deparse($code_block, 24, $op);
	push @args_spec, 0;
	$first_arg_fmt = '%c';
	$type .= " expr";
	$is_block = 0;
    }
    push @nodes, $code_block_node;
    $self->{optree}{$code_block_node->{addr}} = $code_block_node;

    push @skipped_ops, $kid;
    $kid = $kid->sibling;
    $self->deparse_op_siblings(\@nodes, $kid, $op, 6);
    push @args_spec, [1, $#nodes, ', '];

    my $suffix = '';
    if ($self->func_needs_parens($nodes[0]->{text}, $cx, 5)) {
	$fmt = "$name($first_arg_fmt";
	$suffix = ')';
    } else {
	$fmt = "$name $first_arg_fmt";
    }
    if (@nodes > 1) {
	if ($is_block) {
	    $fmt .= " ";
	} else {
	    $fmt .= ", ";
	}
	$fmt .= "%C";
    }
    $fmt .= $suffix;
    my $node = $self->info_from_template($type, $op, $fmt,
					 \@args_spec, \@nodes,
					 {other_ops => \@skipped_ops});
    $code_block_node->{parent} = $node->{addr};

    # Handle skipped ops
    my @new_ops;
    my $str = $node->{text};
    my $position;
    if ($is_block) {
	# Make the position be the position of the "{".
	$position = [length($name)+1, 1];
    } else {
	# Make the position be the name portion
	$position = [0, length($name)];
    }
    my @skipped_nodes;
    for my $skipped_op (@skipped_ops) {
	my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
					     {position => $position});
	push @new_ops, $new_op;
    }
    $node->{other_ops} = \@new_ops;
    return $node;
}


# osmic acid -- see osmium tetroxide

my %matchwords;
map($matchwords{join "", sort split //, $_} = $_, 'cig', 'cog', 'cos', 'cogs',
    'cox', 'go', 'is', 'ism', 'iso', 'mig', 'mix', 'osmic', 'ox', 'sic',
    'sig', 'six', 'smog', 'so', 'soc', 'sog', 'xi');

sub matchop
{
    $] < 5.022 ? matchop_older(@_) : matchop_newer(@_);
}

# matchop for Perl 5.22 and later
sub matchop_newer
{
    my($self, $op, $cx, $name, $delim) = @_;
    my $kid = $op->first;
    my $info = {};
    my @body = ();
    my ($binop, $var_str, $re_str) = ("", "", "");
    my $var_node;
    my $re;
    if ($op->flags & B::OPf_STACKED) {
	$binop = 1;
	$var_node = $self->deparse($kid, 20, $op);
	$var_str = $var_node->{text};
	push @body, $var_node;
	$kid = $kid->sibling;
    }
    # not $name; $name will be 'm' for both match and split
    elsif ($op->name eq 'match' and my $targ = $op->targ) {
	$binop = 1;
	$var_str = $self->padname($targ);
    }
    my $quote = 1;
    my $pmflags = $op->pmflags;
    my $rhs_bound_to_defsv;
    my ($cv, $bregexp);
    my $have_kid = !B::Deparse::null $kid;
    # Check for code blocks first
    if (not B::Deparse::null my $code_list = $op->code_list) {
	$re = $self->code_list($code_list,
			       $op->name eq 'qr'
				   ? $self->padval(
				         $kid->first   # ex-list
					     ->first   #   pushmark
					     ->sibling #   entersub
					     ->first   #     ex-list
					     ->first   #       pushmark
					     ->sibling #       srefgen
					     ->first   #         ex-list
					     ->first   #           anoncode
					     ->targ
				     )
				   : undef);
    } elsif (${$bregexp = $op->pmregexp} && ${$cv = $bregexp->qr_anoncv}) {
	my $patop = $cv->ROOT      # leavesub
		       ->first     #   qr
		       ->code_list;#     list
	$re = $self->code_list($patop, $cv);
    } elsif (!$have_kid) {
	$re_str = B::Deparse::re_uninterp(B::Deparse::escape_str(B::Deparse::re_unback($op->precomp)));
    } elsif ($kid->name ne 'regcomp') {
        if ($op->name eq 'split') {
            # split has other kids, not just regcomp
            $re = re_uninterp(B::Deparse::escape_re(re_unback($op->precomp)));
        } else {
	    carp("found ".$kid->name." where regcomp expected");
	}
    } else {
	($re, $quote) = $self->regcomp($kid, 21);
	push @body, $re;
	$re_str = $re->{text};
	my $matchop = $kid->first;
	if ($matchop->name eq 'regcrest') {
	    $matchop = $matchop->first;
	}
	if ($matchop->name =~ /^(?:match|transr?|subst)\z/
	   && $matchop->flags & B::OPf_SPECIAL) {
	    $rhs_bound_to_defsv = 1;
	}
    }
    my $flags = '';
    $flags .= "c" if $pmflags & B::PMf_CONTINUE;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $matchwords{$flags} if $matchwords{$flags};

    if ($pmflags & B::PMf_ONCE) {
	# only one kind of delimiter works here
	$re_str =~ s/\?/\\?/g;
	# explicit 'm' is required
	$re_str = $self->keyword("m") . "?$re_str?";
    } elsif ($quote) {
	my $re = $self->single_delim($kid, $name, $delim, $re_str);
	push @body, $re;
	$re_str = $re->{text};
    }
    my $opts = {};
    my @texts;
    $re_str .= $flags if $quote;
    my $type;
    if ($binop) {
	# FIXME: use template string
	if ($rhs_bound_to_defsv) {
	    @texts = ($var_str, ' =~ ($_ =~ ', $re_str, ')');
	} else {
	    @texts = ($var_str, ' =~ ', $re_str);
	}
	$opts->{maybe_parens} = [$self, $cx, 20];
	$type = 'binary match ~=';
    } else {
	@texts = ($re_str);
	$type = 'unary ($_) match';
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

# matchop for Perl before 5.22
sub matchop_older
{
    my($self, $op, $cx, $name, $delim) = @_;
    my $kid = $op->first;
    my $info = {};
    my @body = ();
    my ($binop, $var, $re_str) = ("", "", "");
    my $re;
    if ($op->flags & B::OPf_STACKED) {
	$binop = 1;
	$var = $self->deparse($kid, 20, $op);
	push @body, $var;
	$kid = $kid->sibling;
    }
    my $quote = 1;
    my $pmflags = $op->pmflags;
    my $extended = ($pmflags & B::PMf_EXTENDED);
    my $rhs_bound_to_defsv;
    if (B::Deparse::null $kid) {
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
	   && $matchop->flags & B::OPf_SPECIAL) {
	    $rhs_bound_to_defsv = 1;
	}
    }
    my $flags = '';
    $flags .= "c" if $pmflags & B::PMf_CONTINUE;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $matchwords{$flags} if $matchwords{$flags};

    if ($pmflags & B::PMf_ONCE) { # only one kind of delimiter works here
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

# FIXME: remove this
sub map_texts($$)
{
    my ($self, $args) = @_;
    my @result ;
    foreach my $expr (@$args) {
	if (ref $expr eq 'ARRAY' and scalar(@$expr) == 2) {
	    # First item is hash and second item is op address.
	    push @result, [$expr->[0]{text}, $expr->[1]];
	} else {
	    push @result, [$expr->{text}, $expr->{addr}];
	}
    }
    return @result;
}

# FIXME: This is weird. Regularize var_info
sub maybe_local {
    my($self, $op, $cx, $var_info) = @_;
    $var_info->{parent} = $$op;
    return maybe_local_str($self, $op, $cx, $var_info);
}

# Handles "our", "local", "my" variables (and possibly no
# declaration of these) in scalar and array contexts.
# The complications include stripping a package name on
# "our" variables, and not including parenthesis when
# not needed, unless there's a setting to always include
# parenthesis.

sub maybe_local_str
{
    my($self, $op, $cx, $info) = @_;
    my ($text, $is_node);
    if (ref $info && $info->isa("B::DeparseTree::TreeNode")) {
	$text = $self->info2str($info);
	$is_node = 1;
    } else {
	$text = $info;
	$is_node = 0;
    }

    my $our_intro = ($op->name =~ /^(gv|rv2)[ash]v$/) ? OPpOUR_INTRO : 0;
    my ($fmt, $type);
    if ($op->private & (OPpLVAL_INTRO|$our_intro)
	and not $self->{'avoid_local'}{$$op}) {
	my $our_local = ($op->private & OPpLVAL_INTRO) ? "local" : "our";
	if( $our_local eq 'our' ) {
	    # "our" variables needs to strip off package the prefix

	    if ( $text !~ /^\W(\w+::)*\w+\z/
		 and !utf8::decode($text) || $text !~ /^\W(\w+::)*\w+\z/
		) {
		Carp::confess("Unexpected our text $text");
	    }

	    if ($] >= 5.024) {
		if ($type = $self->B::Deparse::find_our_type($text)) {
		    $our_local .= ' ' . $type;
		}
	    }

	    if (!B::Deparse::want_scalar($op)
		&& $self->func_needs_parens($text, $cx, 16)) {
		$type = "$our_local ()";
		$fmt = "$our_local(%F)";
	    } else {
		$type = "$our_local";
		$fmt = "$our_local %F";
	    }
	    my $transform_fn = sub {
		my $text = $is_node ? $_[0]->{text} : $_[0];
		# Strip possible package prefix
		$text =~ s/(\w+::)+//;
		return $text;
	    };
	    # $info could be either a string or a node, %c covers both.
	    return $self->info_from_template($type, $op, $fmt,
					     [[0, $transform_fn]], [$info]);
	}

	# Not an "our" declaration.
        if (B::Deparse::want_scalar($op)) {
	    # $info could be either a string or a node, %c covers both
	    return $self->info_from_template("scalar $our_local", $op, "$our_local %c", undef, [$info]);
	} else {
	    if (!B::Deparse::want_scalar($op)
		&& $self->func_needs_parens($text, $cx, 16)) {
		$fmt = "$our_local(%F)";
		$type = "$our_local()";
	    } else {
		$fmt = "$our_local %F";
		$type = "$our_local";
	    }
	    return $self->info_from_template($type, $op, $fmt, undef, [$info]);
	}
    } else {
	if (ref $info && $info->isa("B::DeparseTree::TreeNode")) {
	    return $info;
	} else {
	    return $self->info_from_string('not local', $op, $text);
	}
    }
}

sub maybe_my
{
    $] >= 5.026 ? goto &maybe_my_newer : goto &maybe_my_older;
}

sub maybe_my_newer
{
    my $self = shift;
    my($op, $cx, $text, $padname, $forbid_parens) = @_;
    # The @a in \(@a) isn't in ref context, but only when the
    # parens are there.
    my $need_parens = !$forbid_parens && $self->{'in_refgen'}
		   && $op->name =~ /[ah]v\z/
		   && ($op->flags & (B::OPf_PARENS|B::OPf_REF)) == B::OPf_PARENS;
    # The @a in \my @a must not have parens.
    if (!$need_parens && $self->{'in_refgen'}) {
	$forbid_parens = 1;
    }
    if ($op->private & B::OPpLVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	# Check $padname->FLAGS for statehood, rather than $op->private,
	# because enteriter ops do not carry the flag.
	unless (defined($padname)) {
	    Carp::confess("undefine padname $padname");
	}

	my $my =
	    $self->keyword($padname->FLAGS & SVpad_STATE ? "state" : "my");
	if ($padname->FLAGS & SVpad_TYPED) {
	    $my .= ' ' . $padname->SvSTASH->NAME;
	}
	if ($need_parens) {
	    return $self->info_from_string("$my()", $op, "$my($text)");
	} elsif ($forbid_parens || B::Deparse::want_scalar($op)) {
	    return $self->info_from_string("$my", $op, "$my $text");
	} elsif ($self->func_needs_parens($text, $cx, 16)) {
	    return $self->info_from_string("$my()", $op, "$my($text)");
	} else {
	    return $self->info_from_string("$my", $op, "$my $text");
	}
    } else {
	return $self->info_from_string("not my", $op, $need_parens ? "($text)" : $text);
    }
}

sub maybe_my_older
{
    my $self = shift;
    my($op, $cx, $text, $forbid_parens) = @_;
    if ($op->private & OPpLVAL_INTRO and not $self->{'avoid_local'}{$$op}) {
	my $my_str = $op->private & OPpPAD_STATE
	    ? $self->keyword("state")
	    : "my";
	if ($forbid_parens || B::Deparse::want_scalar($op)) {
	    return $self->info_from_string('my',  $op, "$my_str $text");
	} else {
	    return $self->info_from_string('my (maybe with parens)',  $op,
					   "$my_str $text",
					   {maybe_parens => [$self, $cx, 16]});
	}
    } else {
	return $self->info_from_string('not my', $op, $text);
    }
}

# Possibly add () around $text depending on precedence $prec and
# context $cx. We return a string.
sub maybe_parens($$$$)
{
    my($self, $text, $cx, $prec) = @_;
    if (B::DeparseTree::TreeNode::parens_test($self, $cx, $prec)) {
	$text = "($text)";
	# In a unop, let parent reuse our parens; see maybe_parens_unop
	# FIXME:
	$text = "\cS" . $text if $cx == 16;
	return $text;
    } else {
	return $text;
    }
}

# FIXME: go back to default B::Deparse routine and return a string.
sub maybe_parens_func($$$$$)
{
    my($self, $func, $params, $cx, $prec) = @_;
    if ($prec <= $cx or substr($params, 0, 1) eq "(" or $self->{'parens'}) {
	return ($func, '(', $params, ')');
    } else {
	return ($func, ' ', $params);
    }
}

# Sort of like maybe_parens in that we may possibly add ().  However we take
# an op rather than text, and return a tree node. Also, we get around
# the 'if it looks like a function' rule.
sub maybe_parens_unop($$$$$)
{
    my ($self, $name, $op, $cx, $parent, $opts) = @_;
    $opts = {} unless $opts;
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
	my $node = $self->info_from_template(
	    "$name()", $parent, "$name(%c)",[0], \@exprs, $opts);
	$node->{prev_expr} = $exprs[0];
	return $node;
    } else {
	# FIXME: we don't do \cS
	# if (substr($text, 0, 1) eq "\cS") {
	#     # use op's parens
	#     return info_from_list($op, $self,[$name, substr($text, 1)],
	# 			  '',  'maybe_parens_unop_cS', {body => [$info]});
	# } else
	my $node;
	if (substr($info->{text}, 0, 1) eq "(") {
	    # avoid looks-like-a-function trap with extra parens
	    # ('+' can lead to ambiguities)
	    $node = $self->info_from_template(
		"$name(()) dup remove", $parent, "$name(%c)", [0], \@exprs, $opts);
	} else {
	    $node = $self->info_from_template(
		"$name <args>", $parent, "$name %c", [0], \@exprs, $opts);
	}
	$node->{prev_expr} = $exprs[0];
	return $node;
    }
    Carp::confess("unhandled condition in maybe_parens_unop");
}

sub maybe_qualify {
    my ($self,$prefix,$name) = @_;
    my $v = ($prefix eq '$#' ? '@' : $prefix) . $name;
    return $name if !$prefix || $name =~ /::/;
    return $self->{'curstash'}.'::'. $name
	if
	    $name =~ /^(?!\d)\w/         # alphabetic
	 && $v    !~ /^\$[ab]\z/	 # not $a or $b
	 && !$globalnames{$name}         # not a global name
	 && $self->{hints} & $strict_bits{vars}  # strict vars
	 && !$self->B::Deparse::lex_in_scope($v,1)   # no "our"
      or $self->B::Deparse::lex_in_scope($v);        # conflicts with "my" variable
    return $name;
}

# FIXME: need a way to pass in skipped_ops
sub maybe_targmy
{
    my($self, $op, $cx, $func, @args) = @_;
    if ($op->private & OPpTARGET_MY) {
	my $var = $self->padname($op->targ);
	my $val = $func->($self, $op, 7, @args);
	my @texts = ($var, '=', $val);
	return $self->info_from_template("my", $op,
					 "%c = %c", [0, 1],
					 [$var, $val],
					 {maybe_parens => [$self, $cx, 7]});
    } else {
	return $self->$func($op, $cx, @args);
    }
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
	for (; not B::Deparse::null $kid; $kid = $kid->sibling) {
	    push @exprs, $kid;
	}
    } else {
	$obj = $kid;
	$kid = $kid->sibling;
	for (; !B::Deparse::null ($kid->sibling) && $kid->name!~/^method(?:_named)?\z/;
	     $kid = $kid->sibling) {
	    push @exprs, $kid
	}
	$meth = $kid;
    }

    my $method_name = undef;
    my $type = 'method';
    if ($meth->name eq "method_named") {
	if ($] < 5.018) {
	    $method_name = $self->const_sv($meth)->PV;
	} else {
	    $method_name = $self->meth_sv($meth)->PV;
	}
	$type = 'named method';
    } elsif ($meth->name eq "method_super") {
	$method_name = "SUPER::".$self->meth_sv($meth)->PV;
	$type = 'SUPER:: method';
    } elsif ($meth->name eq "method_redir") {
        $method_name = $self->meth_rclass_sv($meth)->PV.'::'.$self->meth_sv($meth)->PV;
	$type = 'method redirected ::';
    } elsif ($meth->name eq "method_redir_super") {
	$type = '::SUPER:: redirected method';
        $method_name = $self->meth_rclass_sv($meth)->PV.'::SUPER::'.
                $self->meth_sv($meth)->PV;
    } else {
	$meth = $meth->first;
	if ($meth->name eq "const") {
	    # As of 5.005_58, this case is probably obsoleted by the
	    # method_named case above
	    $method_name = $self->const_sv($meth)->PV; # needs to be bare
	    $type = 'contant method';
	}
    }

    my $meth_node = undef;
    if ($method_name) {
	$meth_node = $self->info_from_string($type,
					     $meth, $method_name,
					     {other_ops => \@other_ops});
	$self->{optree}{$$meth} = $meth_node;
	$meth_node->{parent} = $$op if $op;

    }
    return {
	method_node => $meth_node,
	method => $meth,
	object => $obj,
	args => \@exprs,
    }, $cx;
}

sub e_method {
    my ($self, $op, $minfo, $cx) = @_;
    my $obj = $self->deparse($minfo->{object}, 24, $op);
    my @body = ($obj);
    my $other_ops = $minfo->{other_ops};

    my $meth_info = $minfo->{method_node};
    unless ($minfo->{method_node}) {
	$meth_info = $self->deparse($minfo->{meth}, 1, $op);
    }
    my @args = map { $self->deparse($_, 6, $op) } @{$minfo->{args}};
    my @args_texts = map $_->{text}, @args;
    my $args = join(", ", @args_texts);

    my $opts = {other_ops => $other_ops,
                prev_expr => $meth_info};
    my $type;

    if ($minfo->{object}->name eq 'scope' && B::Deparse::want_list $minfo->{object}) {
	# method { $object }
	# This must be deparsed this way to preserve list context
	# of $object.
	# FIXME
	my @texts = ();
	my $need_paren = $cx >= 6;
	if ($need_paren) {
	    @texts = ('(', $meth_info->{text},  substr($obj,2),
		      $args, ')');
	    $type = 'e_method list ()';
	} else {
	    @texts = ($meth_info->{text},  substr($obj,2), $args);
	    $type = 'e_method list, no ()';
	}
	return info_from_list($op, $self, \@texts, '', $type, $opts);
    }

    my @nodes = ($obj, $meth_info);
    my $fmt;
    my @args_spec = (0, 1);
    if (@{$minfo->{args}}) {
	my $prev_expr = undef;
	foreach my $arg (@{$minfo->{args}}) {
	    my $expr = $self->deparse($arg, 6, $op);
	    $expr->{prev_expr} = $prev_expr;
	    push @nodes, $expr;
	}
	$fmt = "%c->%c(%C)";
	push @args_spec, [2, $#nodes, ', '];
	$type = '$obj->method()';
    } else {
	$type = '$obj->method';
	$fmt = "%c->%c";
    }
    return $self->info_from_template($type, $op, $fmt, \@args_spec, \@nodes, $opts);
}

# Perl 5.14 doesn't have this
use constant OP_GLOB => 25;

sub null_older
{
    my($self, $op, $cx) = @_;
    my $info;
    if (B::class($op) eq "OP") {
	if ($op->targ == B::Deparse::OP_CONST) {
	    # The Perl source constant value can't be recovered.
	    # We'll use the 'ex_const' value as a substitute
	    return $self->info_from_string('constant unrecoverable', $op, $self->{'ex_const'});
	} else {
	    # FIXME: look over. Is this right?
	    return $self->info_from_string('constant ""', $op, '');
	}
    } elsif (B::class ($op) eq "COP") {
	    return $self->cops($op, $cx, $op->name);
    }
    my $kid = $op->first;
    if ($self->is_list_older($kid)) {
	my $node = $self->pp_list($op, $cx);
	$node->update_other_ops($kid);
	return $node;
    } elsif ($kid->name eq "enter") {
	return $self->pp_leave($op, $cx);
    } elsif ($kid->name eq "leave") {
	return $self->pp_leave($kid, $cx);
    } elsif ($kid->name eq "scope") {
	return $self->pp_scope($kid, $cx);
    } elsif ($op->targ == B::Deparse::OP_STRINGIFY) {
	return $self->dquote($op, $cx);
    } elsif ($op->targ == OP_GLOB) {
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
    } elsif (!B::Deparse::null($kid->sibling) and
    	     $kid->sibling->name eq "readline" and
    	     $kid->sibling->flags & OPf_STACKED) {
	my $lhs = $self->deparse($kid, 7, $op);
	my $rhs = $self->deparse($kid->sibling, 7, $kid);
	return $self->info_from_template("readline = ", $op,
					 "%c = %c", undef, [$lhs, $rhs],
					 {maybe_parens => [$self, $cx, 7],
					  prev_expr => $rhs});
    } elsif (!B::Deparse::null($kid->sibling) and
    	     $kid->sibling->name eq "trans" and
    	     $kid->sibling->flags & OPf_STACKED) {
    	my $lhs = $self->deparse($kid, 20, $op);
    	my $rhs = $self->deparse($kid->sibling, 20, $op);
	return $self->info_from_template("trans =~",$op,
					 "%c =~ %c", undef, [$lhs, $rhs],
					 { maybe_parens => [$self, $cx, 7],
					   prev_expr => $rhs });
    } elsif ($op->flags & OPf_SPECIAL && $cx < 1 && !$op->targ) {
	my $kid_info = $self->deparse($kid, $cx, $op);
	return $self->info_from_template("do { }", $op,
					 "do {\n%+%c\n%-}", undef, [$kid_info]);
    } elsif (!B::Deparse::null($kid->sibling) and
	     $kid->sibling->name eq "null" and
	     B::class($kid->sibling) eq "UNOP" and
	     $kid->sibling->first->flags & OPf_STACKED and
	     $kid->sibling->first->name eq "rcatline") {
	my $lhs = $self->deparse($kid, 18, $op);
	my $rhs = $self->deparse($kid->sibling, 18, $op);
	return $self->info_from_template("rcatline =",$op,
					 "%c = %c", undef, [$lhs, $rhs],
					 { maybe_parens => [$self, $cx, 20],
					   prev_expr => $rhs });
    } else {
	return $self->deparse($kid, $cx, $op);
    }
    Carp::confess("unhandled condition in null");
}

sub pushmark_position($) {
    my ($node) = @_;
    my $l = undef;
    if ($node->{parens}) {
	return [0, 1];
    } elsif (exists $node->{fmt}) {
	# Match up to %c, %C, or %F after ( or {
	if ($node->{fmt} =~ /^(.*)%[cCF]/) {
	    $l = length($1);
	}
    } else {
	# Match up to first ( or {
	if ($node->{text} =~ /^(.*)\W/) {
	    $l = length($1);
	}
    }
    if (defined($l)) {
	$l = $l > 0 ? $l-1 : 0;
	return [$l, 1]
    }
    return undef;
}


# Note 5.26 and up
sub null_newer
{
    my($self, $op, $cx) = @_;
    my $node;

    # might be 'my $s :Foo(bar);'
    if ($] >= 5.028 && $op->targ == B::Deparse::OP_LIST) {
	Carp::confess("Can't handle var attr yet");
        # my $my_attr = maybe_var_attr($self, $op, $cx);
        # return $my_attr if defined $my_attr;
    }

    if (B::class($op) eq "OP") {
	# If the Perl source constant value can't be recovered.
	# We'll use the 'ex_const' value as a substitute
	return $self->info_from_string("null - constant_unrecoverable",$op, $self->{'ex_const'})
	    if $op->targ == B::Deparse::OP_CONST;
	return $self->dquote($op, $cx) if $op->targ == B::Deparse::OP_STRINGIFY;
    } elsif (B::class($op) eq "COP") {
	return $self->cops($op, $cx, $op->name);
    } else  {
	# All of these use $kid
	my $kid = $op->first;
	my $update_node = $kid;
	if ($self->is_list_newer($op)) {
	    $node = $self->pp_list($op, $cx);
	} elsif ($kid->name eq "enter") {
	    $node = $self->pp_leave($op, $cx);
	} elsif ($kid->name eq "leave") {
	    $node = $self->pp_leave($kid, $cx);
	} elsif ($kid->name eq "scope") {
	    $node = $self->pp_scope($kid, $cx);
	} elsif ($op->targ == B::Deparse::OP_STRINGIFY) {
	    # This case is duplicated the below "else". Can it ever happen?
	    $node =  $self->dquote($op, $cx);
	} elsif ($op->targ == OP_GLOB) {
	    my @other_ops = ($kid, $kid->first, $kid->first->first);
	    my $info = $self->pp_glob(
		$kid    # entersub
		->first    # ex-list
		->first    # pushmark
		->sibling, # glob
		$cx
		);
	    # FIXME: mark text.
	    push @{$info->{other_ops}}, @other_ops;
	    return $info;
	} elsif (!B::Deparse::null($kid->sibling) and
		 $kid->sibling->name eq "readline" and
		 $kid->sibling->flags & OPf_STACKED) {
	    my $lhs = $self->deparse($kid, 7, $op);
	    my $rhs = $self->deparse($kid->sibling, 7, $kid);
	    $node = $self->info_from_template("null: readline = ", $op,
					      "%c = %c", undef, [$lhs, $rhs],
					      {maybe_parens => [$self, $cx, 7],
					       prev_expr => $rhs});
	} elsif (!B::Deparse::null($kid->sibling) and
		 $kid->sibling->name =~ /^transr?\z/ and
		 $kid->sibling->flags & OPf_STACKED) {
	    my $lhs = $self->deparse($kid, 20, $op);
	    my $rhs = $self->deparse($kid->sibling, 20, $op);
	    $node = $self->info_from_template("null: trans =~",$op,
					      "%c =~ %c", undef, [$lhs, $rhs],
					      { maybe_parens => [$self, $cx, 7],
						prev_expr => $rhs });
	} elsif ($op->flags & OPf_SPECIAL && $cx < 1 && !$op->targ) {
	    my $kid_info = $self->deparse($kid, $cx, $op);
	    $node = $self->info_from_template("null: do { }", $op,
					     "do {\n%+%c\n%-}", undef, [$kid_info]);
	} elsif (!B::Deparse::null($kid->sibling) and
		 $kid->sibling->name eq "null" and
		 B::class($kid->sibling) eq "UNOP" and
		 $kid->sibling->first->flags & OPf_STACKED and
		 $kid->sibling->first->name eq "rcatline") {
	    my $lhs = $self->deparse($kid, 18, $op);
	    my $rhs = $self->deparse($kid->sibling, 18, $op);
	    $node = $self->info_from_template("null: rcatline =",$op,
					      "%c = %c", undef, [$lhs, $rhs],
					      { maybe_parens => [$self, $cx, 20],
						prev_expr => $rhs });
	} else {
	    my $node = $self->deparse($kid, $cx, $op);
	    my $type = "null: " . $op->name;
	    return $self->info_from_template($type, $op,
					     "%c", undef, [$node]);
	}
	my $position = pushmark_position($node);
	if ($position) {
	    $update_node =
		$self->info_from_string($kid->name, $kid,
					$node->{text},
					{position => $position});
	}
	$node->update_other_ops($update_node);
	return $node;
    }
    Carp::confess("unhandled condition in null");
}

sub pp_padsv {
    $] >= 5.026 ? goto &pp_padsv_newer : goto &pp_padsv_older;
}

sub pp_padsv_newer {
    my $self = shift;
    my($op, $cx, $forbid_parens) = @_;
    my $targ = $op->targ;
    return $self->maybe_my($op, $cx, $self->padname($targ),
			   $self->padname_sv($targ),
			   $forbid_parens);
}

sub pp_padsv_older
{
    my ($self, $op, $cx, $forbid_parens) = @_;
    return $self->maybe_my($op, $cx, $self->padname($op->targ),
			   $forbid_parens);
}

# This is the 5.26 version. It is different from earlier versions.
# Is it compatable/
#
# 'x' is weird when the left arg is a list
sub repeat {
    my $self = shift;
    my($op, $cx) = @_;
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    my $prec = 19;
    my @skipped_ops = ();
    my $left_fmt;
    my $type = "repeat";
    my @args_spec = ();
    my @exprs = ();
    if ($op->flags & OPf_STACKED) {
	$eq = "=";
	$prec = 7;
    }

    if (B::Deparse::null($right)) {
	# This branch occurs in 5.21.5 and earlier.
	# A list repeat; count is inside left-side ex-list
	$type = 'list repeat';

	my $kid = $left->first->sibling; # skip pushmark
	push @skipped_ops, $left->first, $kid;
	$self->deparse_op_siblings(\@exprs, $kid, $op, 6);
	$left_fmt = '(%C)';
	@args_spec = ([0, $#exprs, ', '], scalar(@exprs));
    } else {
	$type = 'repeat';
	my $dolist = $op->private & OPpREPEAT_DOLIST;
	push @exprs, $self->deparse_binop_left($op, $left, $dolist ? 1 : $prec);
	$left_fmt = '%c';
	if ($dolist) {
	    $left_fmt = "(%c)";
	}
	@args_spec = (0, 1);
    }
    push @exprs, $self->deparse_binop_right($op, $right, $prec);
    my $opname = "x$eq";
    my $node = $self->info_from_template("$type $opname",
					 $op, "$left_fmt $opname %c",
					 \@args_spec,
					 \@exprs,
					 {maybe_parens => [$self, $cx, $prec],
					  other_ops => \@skipped_ops});

    if (@skipped_ops) {
	# if we have skipped ops like pushmark, we will use the position
	# of the "x" as the part it represents.
	my @new_ops;
	my $str = $node->{text};
	my $right_text = "$opname " . $exprs[-1]->{text};
	my $start = rindex($str, $right_text);
	my $position;
	if ($start >= 0) {
	    $position = [$start, length($opname)];
	} else {
	    $position = [0, length($str)];
	}
	my @skipped_nodes;
	for my $skipped_op (@skipped_ops) {
	    my $new_op = $self->info_from_string($op->name, $skipped_op, $str,
						 {position => $position});
	    push @new_ops, $new_op;
	}
	$node->{other_ops} = \@new_ops;
    }

    return $node;
}

sub stringify_older {
    maybe_targmy(@_, \&dquote)
}

# OP_STRINGIFY is a listop, but it only ever has one arg
sub stringify_newer {
    my ($self, $op, $cx) = @_;
    my $kid = $op->first->sibling;
    my @other_ops = ();
    while ($kid->name eq 'null' && !B::Deparse::null($kid->first)) {
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

# FIXME 522 and 526 could probably be combined or common parts pulled out.
sub subst_older
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    my($binop, $var, $re, @other_ops) = ("", "", "", ());
    my ($repl, $repl_info);

    if ($op->flags & OPf_STACKED) {
	$binop = 1;
	$var = $self->deparse($kid, 20, $op);
	$kid = $kid->sibling;
    }
    my $flags = "";
    my $pmflags = $op->pmflags;
    if (B::Deparse::null($op->pmreplroot)) {
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
    if (B::Deparse::null $kid) {
	my $unbacked = B::Deparse::re_unback($op->precomp);
	if ($extended) {
	    $re = B::Deparse::re_uninterp_extended(escape_extended_re($unbacked));
	}
	else {
	    $re = B::Deparse::re_uninterp(B::Deparse::escape_str($unbacked));
	}
    } else {
	my ($re_info, $junk) = $self->regcomp($kid, 1, $extended);
	$re = $re_info->{text};
    }
    $flags .= "r" if $pmflags & PMf_NONDESTRUCT;
    $flags .= "e" if $pmflags & PMf_EVAL;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $substwords{$flags} if $substwords{$flags};
    my $core_s = $self->keyword("s"); # maybe CORE::s

    # FIXME: we need to attach the $repl_info someplace.
    my $repl_text = $repl_info->{text};
    my $find_replace_re = double_delim($re, $repl_text);
    my $opts = {};
    $opts->{other_ops} = \@other_ops if @other_ops;
    if ($binop) {
	return $self->info_from_template("=~ s///", $op,
					 "%c =~ ${core_s}%c$flags",
					 undef,
					 [$var, $find_replace_re],
					 {maybe_parens => [$self, $cx, 20]});
    } else {
	return $self->info_from_string("s///", $op, "${core_s}${find_replace_re}$flags");
    }
    Carp::confess("unhandled condition in pp_subst");
}

sub slice
{
    my ($self, $op, $cx, $left, $right, $regname, $padname) = @_;
    my $last;
    my(@elems, $kid, $array);
    if (B::class($op) eq "LISTOP") {
	$last = $op->last;
    } else {
	# ex-hslice inside delete()
	for ($kid = $op->first; !B::Deparse::null $kid->sibling; $kid = $kid->sibling) {
	    $last = $kid;
	}
    }
    $array = $last;
    $array = $array->first
	if $array->name eq $regname or $array->name eq "null";
    my $array_info = $self->elem_or_slice_array_name($array, $left, $padname, 0);
    $kid = $op->first->sibling; # skip pushmark

    if ($kid->name eq "list") {
	# FIXME:
	# skip list, pushmark
	$kid = $kid->first->sibling;
	for (; !B::Deparse::null $kid; $kid = $kid->sibling) {
	    push @elems, $self->deparse($kid, 6, $op);
	}
    } else {
	@elems = ($self->elem_or_slice_single_index($kid, $op));
    }
    my $lead = '@';
    $lead = '%' if $op->name =~ /^kv/i;
    my ($fmt, $args_spec);
    my (@texts, $type);
    if ($array_info) {
	unshift @elems, $array_info;
	$fmt = "${lead}%c$left%C$right";
	$args_spec = [0, [1, $#elems, ', ']];
	$type = "$lead<var>$left .. $right";
    } else {
	$fmt = "${lead}$left%C$right";
	$args_spec = [0, $#elems, ', '];
	$type = "${lead}$left .. $right";
    }
    return $self->info_from_template($type, $op, $fmt, $args_spec,
				     \@elems),
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
    for (; !B::Deparse::null($stacked ? $kid->sibling : $kid);
	 $kid = $kid->sibling) {
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

sub subst_newer
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first;
    my($binop, $var, $re, @other_ops) = ("", "", "", ());
    my ($repl, $repl_info);

    if ($op->flags & OPf_STACKED) {
	$binop = 1;
	$var = $self->deparse($kid, 20, $op);
	$kid = $kid->sibling;
    }
    elsif (my $targ = $op->targ) {
	$binop = 1;
	$var = $self->padname($targ);
    }
    my $flags = "";
    my $pmflags = $op->pmflags;
    if (B::Deparse::null($op->pmreplroot)) {
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
    if (not B::Deparse::null my $code_list = $op->code_list) {
	$re = $self->code_list($code_list);
    } elsif (B::Deparse::null $kid) {
	$re = B::Deparse::re_uninterp(B::Deparse::escape_re(B::Deparse::re_unback($op->precomp)));
    } else {
	my ($re_info, $junk) = $self->regcomp($kid, 1);
	$re = $re_info->{text};
    }
    $flags .= "r" if $pmflags & PMf_NONDESTRUCT;
    $flags .= "e" if $pmflags & PMf_EVAL;
    $flags .= $self->re_flags($op);
    $flags = join '', sort split //, $flags;
    $flags = $substwords{$flags} if $substwords{$flags};
    my $core_s = $self->keyword("s"); # maybe CORE::s

    # FIXME: we need to attach the $repl_info someplace.
    my $repl_text = $repl_info->{text};
    my $opts->{other_ops} = \@other_ops if @other_ops;
    my $find_replace_re = double_delim($re, $repl_text);

    if ($binop) {
	return $self->info_from_template("=~ s///", $op,
					 "%c =~ ${core_s}%c$flags",
					 undef,
					 [$var, $find_replace_re],
					 {maybe_parens => [$self, $cx, 20]});
    } else {
	return $self->info_from_string("s///", $op, "${core_s}${find_replace_re}$flags");
    }
    Carp::confess("unhandled condition in pp_subst");
}

# This handles the category of unary operators, e.g. alarm(), caller(),
# close()..
sub unop
{
    my($self, $op, $cx, $name, $nollafr) = @_;
    my $kid;
    my $opts = {};
    if ($op->flags & B::OPf_KIDS) {
	my $parent = $op;
	$kid = $op->first;
 	if (not $name) {
 	    # this deals with 'boolkeys' right now
	    my $kid_node = $self->deparse($kid, $cx, $parent);
	    $opts->{prev_expr} = $kid_node;
	    return $self->info_from_template("unop, see child", $op, "%c",
					     undef, [$kid_node], $opts);
 	}
	my $builtinname = $name;
	$builtinname =~ /^CORE::/ or $builtinname = "CORE::$name";
	if (defined prototype($builtinname)
	   && $builtinname ne 'CORE::readline'
	   && prototype($builtinname) =~ /^;?\*/
	    && $kid->name eq "rv2gv") {
	    my $rv2gv = $kid;
	    $parent = $rv2gv;
	    $kid = $kid->first;
	    $opts->{other_ops} = [$rv2gv];
	}

	if ($nollafr) {
	    $kid = $self->deparse($kid, 16, $parent);
	    $opts->{maybe_parens} = [$self, $cx, 16],
	    my $fullname = $self->keyword($name);
	    return $self->info_from_template("unary operator $name noallafr", $op,
					     "$fullname %c", undef, [$kid], $opts);
	}
	return $self->maybe_parens_unop($name, $kid, $cx, $parent, $opts)

    } else {
	$opts->{maybe_parens} = [$self, $cx, 16];
	my $fullname = ($self->keyword($name));
	my $fmt = "$fullname";
	$fmt .= '()' if $op->flags & B::OPf_SPECIAL;
	return $self->info_from_template("unary operator $name", $op, $fmt,
					 undef, [], $opts);
    }
}

# This handles category of symbolic prefix and postfix unary operators,
# e.g $x++, -r, +$x.
sub pfixop
{
    my $self = shift;
    my($op, $cx, $operator, $prec, $flags) = (@_, 0);
    my $operand = $self->deparse($op->first, $prec, $op);
    my ($type, $fmt);
    my @nodes;
    if ($flags & POSTFIX) {
	@nodes = ($operand, $operator);
	$type = "prefix $operator";
	$fmt = "%c%c";
    } elsif ($operator eq '-' && $operand->{text} =~ /^[a-zA-Z](?!\w)/) {
	# Add () around operator to disambiguate with filetest operator
	@nodes = ($operator, $operand);
	$type = "prefix non-filetest $operator";
	$fmt = "%c(%c)";
    } else {
	@nodes = ($operator, $operand);
	$type = "postfix $operator";
	$fmt = "%c%c";
    }

    return $self->info_from_template($type, $op, $fmt, [0, 1],
				     \@nodes,
				     {maybe_parens => [$self, $cx, $prec]}) ;
}

# Produce an node for a range (".." or "..." op)
sub range {
    my $self = shift;
    my ($op, $cx, $type) = @_;
    my $left = $op->first;
    my $right = $left->sibling;
    $left = $self->deparse($left, 9, $op);
    $right = $self->deparse($right, 9, $op);
    return $self->info_from_template("range $type", $op, "%c${type}%c",
				     undef, [$left, $right],
				     {maybe_parens => [$self, $cx, 9]});
}

sub rv2x
{
    my($self, $op, $cx, $sigil) = @_;
    if (B::class($op) eq 'NULL' || !$op->can("first")) {
	carp("Unexpected op in pp_rv2x");
	return info_from_text($op, $self, 'XXX', 'bad_rv2x', {});
    }
    my ($info, $kid_info);
    my $kid = $op->first;
    $kid_info = $self->deparse($kid, 0, $op);
    if ($kid->name eq "gv") {
	my $transform_fn = sub {$self->stash_variable($sigil, $self->info2str(shift), $cx)};
	return $self->info_from_template("rv2x $sigil", undef, "%F", [[0, $transform_fn]], [$kid_info])
    } elsif (B::Deparse::is_scalar $kid) {
	my $str = $self->info2str($kid_info);
	my $fmt = '%c';
	my @args_spec = (0);
	if ($str =~ /^\$([^\w\d])\z/) {
	    # "$$+" isn't a legal way to write the scalar dereference
	    # of $+, since the lexer can't tell you aren't trying to
	    # do something like "$$ + 1" to get one more than your
	    # PID. Either "${$+}" or "$${+}" are workable
	    # disambiguations, but if the programmer did the former,
	    # they'd be in the "else" clause below rather than here.
	    # It's not clear if this should somehow be unified with
	    # the code in dq and re_dq that also adds lexer
	    # disambiguation braces.
	    my $transform = sub { $_[0] =~ /^\$([^\w\d])\z/; '$' . "{$1}"};
	    $fmt = '%F';
	    @args_spec = (0, $transform);
	}
	return $self->info_from_template("scalar $str", $op, $fmt, undef, \@args_spec, {});
    } else {
	my $fmt = "$sigil\{%c\}";
	my $type = "rv2x: $sigil\{}";
	return $self->info_from_template($type, $op, $fmt, undef, [$kid_info]);
    }
    Carp::confess("unhandled condition in rv2x");
}

# Handle ops that can introduce blocks or scope. "while", "do", "until", and
# possibly "map", and "grep" are examples such things.
sub scopeop
{
    my($real_block, $self, $op, $cx) = @_;
    my $kid;
    my @kids;

    local(@$self{qw'curstash warnings hints hinthash'})
	= @$self{qw'curstash warnings hints hinthash'} if $real_block;
    my @other_ops = ();
    if ($real_block) {
	push @other_ops, $op->first;
	$kid = $op->first->sibling; # skip enter
	if (B::Deparse::is_miniwhile($kid)) {
	    my $top = $kid->first;
	    my $name = $top->name;
	    if ($name eq "and") {
		$name = $self->keyword("while");
	    } elsif ($name eq "or") {
		$name = $self->keyword("until");
	    } else { # no conditional -> while 1 or until 0
		my $body = $self->deparse($top->first, 1, $top);
		return $self->info_from_template("scopeop: $name 1", $op,
						 "%c while 1", undef, [$body],
						 {other_ops => \@other_ops});
	    }
	    my $cond = $top->first;
	    push @other_ops, $cond->sibling;
	    my $body = $cond->sibling->first; # skip lineseq
	    my $cond_info = $self->deparse($cond, 1, $top);
	    my $body_info = $self->deparse($body, 1, $top);
	    return $self->info_from_template("scopeop: $name",
					     $op,"%c $name %c",
					     undef, [$body_info, $cond_info],
					     {other_ops => \@other_ops});
	}
    } else {
	$kid = $op->first;
    }
    for (; !B::Deparse::null($kid); $kid = $kid->sibling) {
	push @kids, $kid;
    }
    my $node;
    if ($cx > 0) {
	# inside an expression, (a do {} while for lineseq)
	my $body = $self->lineseq($op, 0, @kids);
	my $text;
	if (is_lexical_subs(@kids)) {
	    $node = $self->info_from_template("scoped do", $op,
					     'do {\n%+%c\n%-}',
					     [0], [$body]);

	} else {
	    $node = $self->info_from_template("scoped expression", $op,
					      '%c',[0], [$body]);
	}
    } else {
	$node = $self->lineseq($op, $cx, @kids);
    }
    $node->{other_ops} = \@other_ops if @other_ops;
    return $node;
}

sub single_delim($$$$$)
{
    my($self, $op, $q, $default, $str) = @_;

    return $self->info_from_template("string $default .. $default (default)", $op,
				     "$default%c$default", [0],
				     [$str])
	if $default and index($str, $default) == -1;
    my $coreq = $self->keyword($q); # maybe CORE::q
    if ($q ne 'qr') {
	(my $succeed, $str) = balanced_delim($str);
	return $self->info_from_string("string $q", $op, "$coreq$str")
	    if $succeed;
    }
    for my $delim ('/', '"', '#') {
	$self->info_from_string("string $q $delim$delim", $op, "qr$delim$str$delim")
	    if index($str, $delim) == -1;
    }
    if ($default) {
	my $transform_fn = sub {
	    s/$_[0]/\\$_[0]/g;
	    return $_[0];
	};

	return $self->info_from_template("string $q $default$default",
					 $op, "$default%F$default",
					 [[0, $transform_fn]], [$str]);
    } else {
	my $transform_fn = sub {
	    $_[0] =~ s[/][\\/]g;
	    return $_[0];
	};
	return $self->info_from_template("string $q //",
					 $op, "$coreq/%F/",
					 [[0, $transform_fn]], [$str]);
    }
}

# Demo code
unless(caller) {
    ;
}

1;
