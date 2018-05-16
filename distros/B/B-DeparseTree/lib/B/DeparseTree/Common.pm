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

package B::DeparseTree::Common;

use B qw(class
         CVf_LVALUE
         CVf_METHOD
         OPf_KIDS
         OPf_SPECIAL
         OPf_STACKED
         OPpCONST_BARE
         OPpLVAL_INTRO
         OPpOUR_INTRO
         OPpSORT_INTEGER
         OPpSORT_NUMERIC
         OPpSORT_REVERSE
         OPpTARGET_MY
         SVf_IOK
         SVf_NOK
         SVf_POK
         SVf_ROK
         SVs_PADTMP
         SVs_RMG
         SVs_SMG
         main_cv main_root main_start
         opnumber
         perlstring
         svref_2object
         );

use Carp;
use B::Deparse;
use B::DeparseTree::Node;


our($VERSION, @EXPORT, @ISA);
$VERSION = '1.1.0';
@ISA = qw(Exporter B::Deparse);
@EXPORT = qw(
    %globalnames
    %ignored_hints
    %rev_feature
    POSTFIX baseop mapop pfixop indirop
    _features_from_bundle ambiant_pragmas maybe_qualify
    balanced_delim
    binop
    const
    declare_hinthash
    declare_hints
    declare_warnings
    dedup_parens_func
    deparse_sub
    deparse_subname
    dquote
    gv_name
    hint_pragmas
    indent
    indent_info
    indent_list
    info_from_list
    info_from_text
    is_miniwhile is_lexical_subs %strict_bits
    is_scalar
    is_scope
    is_state
    is_subscriptable
    listop
    logop
    map_texts
    maybe_parens
    maybe_qualify
    maybe_targmy
    new WARN_MASK
    next_todo
    null
    parens_test
    pragmata
    print_protos
    re_unback
    scopeop
    seq_subs
    single_delim
    stash_variable_name
    style_opts
    unback
    unop
    );

my $bal;
BEGIN {
    use re "eval";
    # Matches any string which is balanced with respect to {braces}
    $bal = qr(
      (?:
	[^\\{}]
      | \\\\
      | \\[{}]
      | \{(??{$bal})\}
      )*
    )x;
}

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
    $self->{'cuddle'} = "\n";
    $self->{'curcop'} = undef;
    $self->{'curstash'} = "main";
    $self->{'ex_const'} = "'???'";
    $self->{'expand'} = 0;
    $self->{'files'} = {};
    $self->{'indent_size'} = 4;
    $self->{'opaddr'} = 0;
    $self->{'linenums'} = 0;
    $self->{'parens'} = 0;
    $self->{'subs_todo'} = [];
    $self->{'unquote'} = 0;
    $self->{'use_dumper'} = 0;
    $self->{'use_tabs'} = 0;

    $self->{'ambient_arybase'} = 0;
    $self->{'ambient_warnings'} = undef; # Assume no lexical warnings
    $self->{'ambient_hints'} = 0;
    $self->{'ambient_hinthash'} = undef;

    # Given an opcode address, get the accumulated OP tree
    # OP for that.
    $self->{optree} = {};

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

# Initialise the contextual information, either from
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

my %strict_bits = do {
    local $^H;
    map +($_ => strict::bits($_)), qw/refs subs vars/
};

# FIXME: get from B::Deparse
sub is_scalar {
    my $op = shift;
    return ($op->name eq "rv2sv" or
	    $op->name eq "padsv" or
	    $op->name eq "gv" or # only in array/hash constructs
	    $op->flags & OPf_KIDS && !null($op->first)
	      && $op->first->name eq "gvsv");
}

# FIXME: get from B::Deparse
sub is_subscriptable {
    my $op = shift;
    if ($op->name =~ /^([ahg]elem|multideref$)/) {
	return 1;
    } elsif ($op->name eq "entersub") {
	my $kid = $op->first;
	return 0 unless null $kid->sibling;
	$kid = $kid->first;
	$kid = $kid->sibling until null $kid->sibling;
	return 0 if is_scope($kid);
	$kid = $kid->first;
	return 0 if $kid->name eq "gv" || $kid->name eq "padcv";
	return 0 if is_scalar($kid);
	return is_subscriptable($kid);
    } else {
	return 0;
    }
}

sub listop
{
    my($self, $op, $cx, $name, $kid, $nollafr) = @_;
    my(@exprs);
    my $parens = ($cx >= 5) || $self->{'parens'};

    unless ($kid) {
	$kid = $op->first->sibling;
    }

    # If there are no arguments, add final parentheses (or parenthesize the
    # whole thing if the llafr does not apply) to account for cases like
    # (return)+1 or setpgrp()+1.  When the llafr does not apply, we use a
    # precedence of 6 (< comma), as "return, 1" does not need parentheses.
    if (B::Deparse::null $kid) {
	my $text = $nollafr
	    ? $self->maybe_parens($self->keyword($name), $cx, 7)
	    : $self->keyword($name) . '()' x (7 < $cx);
	return info_from_text($op, $self, $text, 'null_listop', {});
    }
    my $first;
    my $fullname = $self->keyword($name);
    my $proto = prototype("CORE::$name");
    if (
	 (     (defined $proto && $proto =~ /^;?\*/)
	    || $name eq 'select' # select(F) doesn't have a proto
	 )
	 && $kid->name eq "rv2gv"
	 && !($kid->private & OPpLVAL_INTRO)
    ) {
	$first = $self->rv2gv_or_string($kid->first, $op);
    }
    else {
	$first = $self->deparse($kid, 6, $op);
    }
    if ($name eq "chmod" && $first->{text} =~ /^\d+$/) {
	$first = info_from_text($first->{op}, $self, sprintf("%#o", $first->{text}), 'listop_chmod', {});
    }
    $first->{text} = "+" + $first->{text}
	if not $parens and not $nollafr and substr($first->{text}, 0, 1) eq "(";
    push @exprs, $first;
    $kid = $kid->sibling;
    if (defined $proto && $proto =~ /^\*\*/ && $kid->name eq "rv2gv"
	&& !($kid->private & OPpLVAL_INTRO)) {
	$first = $self->rv2gv_or_string($kid->first, $op);
	push @exprs, $first;
	$kid = $kid->sibling;
    }
    for ( ; !null($kid); $kid = $kid->sibling) {
	my $expr = $self->deparse($kid, 6, $op);
	push @exprs, $expr;
    }

    if ($name eq "reverse" && ($op->private & OPpREVERSE_INPLACE)) {
	my $texts =  [$exprs[0->{text}], '=',
		      $fullname . ($parens ? "($exprs[0]->{text})" : " $exprs[0]->{text}")];
	return info_from_list($op, $self, $texts, ' ', 'listop_reverse', {});
    }

    my $opts = {};
    my @texts = @exprs;

    if ($name =~ /^(system|exec)$/
	&& ($op->flags & OPf_STACKED)
	&& @texts > 1)
    {
	# handle the "system(prog a1, a2, ...)" form
	# where there is no ', ' between the first two arguments.
	my $prog = shift @texts;
	my $first_arg = shift @texts;
	my @two_args = ($prog, $first_arg);
	unshift @texts, info_from_list($prog->{op}, $self, [$prog, $first_arg],
				       ' ', 'system|exec', {});
    }

    my $type;
    if ($parens && $nollafr) {
	@texts = ("($fullname ", $self->combine(', ', \@texts), ')');
	$type = 'listop_parens_noallfr';
    } elsif ($parens) {
	@texts = ("$fullname(", $self->combine(", ", \@texts), ')');
	$type = 'listop_parens';
    } else {
	@texts = ("$fullname ", $self->combine(', ', \@texts));
	$type = 'listop';
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
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

	if (!($lop->private & (OPpLVAL_INTRO|OPpOUR_INTRO)
		or $lop->name eq "undef")
	    or $lop->name =~ /^(?:entersub|exit|open|split)\z/)
	{
	    $local = ""; # or not
	    last;
	}
	if ($lop->name =~ /^pad[ash]v$/) {
	    if ($lop->private & OPpPAD_STATE) { # state()
		($local = "", last) if $local =~ /^(?:local|our|my)$/;
		$local = "state";
	    } else { # my()
		($local = "", last) if $local =~ /^(?:local|our|state)$/;
		$local = "my";
	    }
	} elsif ($lop->name =~ /^(gv|rv2)[ash]v$/
			&& $lop->private & OPpOUR_INTRO
		or $lop->name eq "null" && $lop->first->name eq "gvsv"
			&& $lop->first->private & OPpOUR_INTRO) { # our()
	    ($local = "", last) if $local =~ /^(?:my|local|state)$/;
	    $local = "our";
	} elsif ($lop->name ne "undef"
		# specifically avoid the "reverse sort" optimisation,
		# where "reverse" is nullified
		&& !($lop->name eq 'sort' && ($lop->flags & OPpSORT_REVERSE)))
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

    my $type;
    my @texts;
    my $opts = {};
    if ($local) {
	$type = 'list_local';
	@texts = ($local, '(', $self->combine(", ", \@exprs), ')');
    } else {
	$type = 'list';
	@texts = ($self->combine(", ", \@exprs));
	$opts->{maybe_parens} = [$self, $cx, 6];

    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

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
	 && !$self->lex_in_scope($v,1)   # no "our"
      or $self->lex_in_scope($v);        # conflicts with "my" variable
    return $name;
}

sub combine($$$)
{
    my ($self, $sep, $items) = @_;
    # FIXME: loop over $item, testing type.
    Carp::confess("should be a reference to a arry: is $items") unless
	ref $items eq 'ARRAY';
    my @result = ();
    foreach my $item (@$items) {
	my $add;
	if (ref $item) {
	    if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
		$add = [$item->[0], $item->[1]];
	    } elsif (eval{$item->isa("B::DeparseTree::Node")}) {
		$add = [$item->{text}, $item->{addr}];
		# First item is text and second item is op address.
	    } else {
		Carp::confess("don't know what to do with $item");
	    }
	} else {
	    $add = $item;
	}
	push @result, $sep if @result && $sep;
	push @result, $add;
    }
    return @result;
}

use Hash::Util qw[ lock_hash ];

# Nonprinting characters with special meaning:
my %SPECIAL_SEPARATORS = (
        '\cS' => 1, # steal parens (see maybe_parens_unop)
	'\n'  => 1, # newline and indent
	'\b'  => 1, # decrease indent ('outdent')
	'\f'  => 1, # flush left (no indent)
	'\cK' => 1, # kill following semicolon, if any

);
lock_hash %SPECIAL_SEPARATORS;

sub info2str($$)
{
    my ($self, $item) = @_;
    my $result = '';
    if (ref $item) {
	if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
	    # First item is text and second item is op address.
	    $result = $item->[0];
	} elsif (eval{$item->isa("B::DeparseTree::Node")}) {
	    $result = $self->combine2str($item->{sep},
					  $item->{texts});
	} else {
	    Carp::confess("Invalid ref item ref($item)");
	}
    } else {
	# FIXME: add this and remove errors
	if (index($item, '@B::DeparseTree::Node') > 0) {
		Carp::confess("\@B::DeparseTree::Node as an item is probably wrong");
	}
	$result = $item;
    }
    return $result;
}

sub combine2str($$$)
{
    my ($self, $sep, $items) = @_;
    my $result = '';
    foreach my $item (@$items) {
	if ($result) {
	    my $expanded_sep = $sep;
	    if (exists $SPECIAL_SEPARATORS{$sep}) {
		# FIXME: handle them
		$expanded_sep = $sep;
	    }
	    $result .= $expanded_sep;
	}
	if (ref $item) {
	    if (ref $item eq 'ARRAY' and scalar(@$item) == 2) {
		# First item is text and second item is op address.
		$result .= $self->info2str($item->[0]);
	    } elsif (eval{$item->isa("B::DeparseTree::Node")}) {
		$result .= $self->combine2str($item->{sep},
					     $item->{texts});
	    } else {
		Carp::confess("Invalid ref item ref($item)");
	    }
	} else {
	    # FIXME: add this and remove errors
	    if (index($item, '@B::DeparseTree::Node') > 0) {
	    	Carp::confess("\@B::DeparseTree::Node as an item is probably wrong");
	    }
	    $result .= $item;
	}
    }
    return $result;
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

# Don't do this for regexen
sub unback {
    my($str) = @_;
    $str =~ s/\\/\\\\/g;
    return $str;
}

# Remove backslashes which precede literal control characters,
# to avoid creating ambiguity when we escape the latter.
sub re_unback {
    my($str) = @_;

    # the insane complexity here is due to the behaviour of "\c\"
    $str =~ s/(^|[^\\]|\\c\\)(?<!\\c)\\(\\\\)*(?=[[:^print:]])/$1$2/g;
    return $str;
}

sub binop
{
    my ($self, $op, $cx, $opname, $prec, $flags) = (@_, 0);
    my $left = $op->first;
    my $right = $op->last;
    my $eq = "";
    if ($op->flags & OPf_STACKED && $flags & B::Deparse::ASSIGN) {
	$eq = "=";
	$prec = 7;
    }
    if ($flags & B::Deparse::SWAP_CHILDREN) {
	($left, $right) = ($right, $left);
    }
    my $lhs = $self->deparse_binop_left($op, $left, $prec);
    if ($flags & B::Deparse::LIST_CONTEXT
	&& $lhs->{text} !~ /^(my|our|local|)[\@\(]/) {
	$lhs->{text} = "($lhs->{text})";
    }

    my $rhs = $self->deparse_binop_right($op, $right, $prec);
    my @texts = ($lhs, "$opname$eq", $rhs);
    return info_from_list($op, $self, \@texts, ' ', "binary operator $opname$eq",
			  {maybe_parens_join => [$self, $cx, $prec]});
}

sub coderef2info
{
    my ($self, $coderef) = @_;
    croak "Usage: ->coderef2info(CODEREF)" unless UNIVERSAL::isa($coderef, "CODE");
    $self->init();
    return $self->deparse_sub(svref_2object($coderef));
}

sub coderef2text
{
    my ($self, $func) = @_;
    croak "Usage: ->coderef2text(CODEREF)" unless UNIVERSAL::isa($func, "CODE");

    $self->init();
    my $info = $self->coderef2info($func);
    return $self->indent($info->{text});
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
	return info_from_text($sv, $self, $str, 'integer constant', {});
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
		return info_from_text($sv, $self, $self->keyword("__SUB__"),
				      'constant sub', {});
	    }
	    my $sub_info = $self->deparse_sub($ref);
	    return info_from_list($sub_info->{op}, $self, ["sub ", $sub_info->{text}], '',
				  'constant sub 2',
				  {body => [$sub_info]});
	}
	if ($ref->FLAGS & SVs_SMG) {
	    for (my $mg = $ref->MAGIC; $mg; $mg = $mg->MOREMAGIC) {
		if ($mg->TYPE eq 'r') {
		    my $re = B::Deparse::re_uninterp(B::Deparse::escape_str(re_unback($mg->precomp)));
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
	    return $self->single_delim($sv, "q", "'", unback $str);
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

# FIXME: how can we inherit this from B::Deparse?
sub null
{
    my $op = shift;
    return class($op) eq "NULL";
}

# This is a special case of scopeop and lineseq, for the case of the
# main_root.
sub deparse_root {
    my $self = shift;
    my($op) = @_;
    local(@$self{qw'curstash warnings hints hinthash'})
      = @$self{qw'curstash warnings hints hinthash'};
    my @ops;
    return if null $op->first; # Can happen, e.g., for Bytecode without -k
    for (my $kid = $op->first->sibling; !null($kid); $kid = $kid->sibling) {
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
	$self->{optree}{$$op} = $info;
	$info->{text} = $text;
	$info->{parent} = $$parent if $parent;
	push @$exprs, $info;
    };
    my $info = $self->walk_lineseq($op, \@ops, $fn);
    my @other_ops;
    if (exists $info->{other_ops}) {
	@other_ops = @{$info->other_ops};
	push @other_ops, $op->first;
    } else {
	@other_ops = ($op->first);
    }
    $info->{other_ops} = \@other_ops;
    return $info;

}

sub is_state {
    my $name = $_[0]->name;
    return $name eq "nextstate" || $name eq "dbstate" || $name eq "setstate";
}

# Check if the op and its sibling are the initialization and the rest of a
# for (..;..;..) { ... } loop
sub is_for_loop($)
{
    my $op = shift;
    # This OP might be almost anything, though it won't be a
    # nextstate. (It's the initialization, so in the canonical case it
    # will be an sassign.) The sibling is (old style) a lineseq whose
    # first child is a nextstate and whose second is a leaveloop, or
    # (new style) an unstack whose sibling is a leaveloop.
    my $lseq = $op->sibling;
    return 0 unless !is_state($op) and !null($lseq);
    if ($lseq->name eq "lineseq") {
	if ($lseq->first && !null($lseq->first) && is_state($lseq->first)
	    && (my $sib = $lseq->first->sibling)) {
	    return (!null($sib) && $sib->name eq "leaveloop");
	}
    } elsif ($lseq->name eq "unstack" && ($lseq->flags & OPf_SPECIAL)) {
	my $sib = $lseq->sibling;
	return $sib && !null($sib) && $sib->name eq "leaveloop";
    }
    return 0;
}

# Create an info structure from a list of strings
# FIXME: $deparse (or rather $self) should be first
sub info_from_list($$$$$$)
{
    my ($op, $deparse, $texts, $sep, $type, $opts) = @_;
    my $text = '';
    my $info = B::DeparseTree::Node->new($op, $deparse, $texts, $sep, $type, $opts);
    foreach my $item (@$texts) {
	$text .= $sep if $text and $sep;
	if(ref($item) eq 'ARRAY'){
	    $text .= $item->[0];
	} elsif (eval{$item->isa("B::DeparseTree::Node")}) {
	    $text .= $item->{text};
	} else {
	    $text .= $item;
	}
    }
    $info->{text} = $text;
    if ($opts->{maybe_parens}) {
	my ($self, $cx, $prec) = @{$opts->{maybe_parens}};
	$info->{text} = $self->maybe_parens($info->{text}, $cx, $prec);
	$info->{maybe_parens} = {context => $cx , precidence => $prec};
    }
    return $info
}

# Create an info structure from a single string
# FIXME: $deparse (or rather $self) should be first
sub info_from_text($$$$$)
{
    my ($op, $deparse, $text, $type, $opts) = @_;
    return info_from_list($op, $deparse, [[$text, $$op]], '', $type, $opts)
}

sub walk_lineseq
{
    my ($self, $op, $kids, $callback) = @_;
    my @kids = @$kids;
    my @body = ();
    my $expr;
    for (my $i = 0; $i < @kids; $i++) {
	if (is_state $kids[$i]) {
	    $expr = ($self->deparse($kids[$i], 0, $op));
	    $callback->(\@body, $i, $expr);
	    $i++;
	    if ($i > $#kids) {
		last;
	    }
	}
	if (is_for_loop($kids[$i])) {
	    my $loop_expr = $self->for_loop($kids[$i], 0);
	    $loop_expr =~ s/\cK//;
	    $callback->(\@body,
			$i += $kids[$i]->sibling->name eq "unstack" ? 2 : 1,
			$loop_expr);
	    next;
	}
	$expr = $self->deparse($kids[$i], (@kids != 1)/2, $op);
	$callback->(\@body, $i, $expr, $op);
    }

    # Add semicolons between statements. Don't add them to blank lines,
    # or to comment lines, which we
    # assume will always be the last line in the text and start after a \n.
    # FIXME: not quite ideal when adding ';' because we record only the text
    # rather than the DeparseTree::Node.
    my @texts = map { $_->{text} =~ /(?:\n#)|^\s*$/ ?
			  $_ : "$_->{text};" } @body;
			  # $_ : ($_, ";") } @body;
    my $info = info_from_list($op, $self, \@texts, "\n", 'line sequence', {});
    $self->{optree}{$$op} = $info if $op;
    return $info;
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
	my $text = $info->{text};
	my $op = $ops[$i];
	$text =~ s/\f//;
	$text =~ s/\n$//;
	$text =~ s/;\n?\z//;
	$info->{type} = $op->name;
	$info->{op} = $op;
	if ($parent) {
	    Carp::confess("nonref parent, op: $op->name") if !ref($parent);
	    $info->{parent} = $$parent ;
	}
	$self->{optree}{$$op} = $info;
	$info->{text} = $text;
	push @$exprs, $info;
    };
    return $self->walk_lineseq($root, \@ops, $fn);
}

sub dquote
{
    my($self, $op, $cx) = @_;
    my $kid = $op->first->sibling; # skip ex-stringify, pushmark
    return $self->deparse($kid, $cx, $op) if $self->{'unquote'};
    $self->maybe_targmy($kid, $cx,
			sub {$self->single_delim($kid, '"', $self->dq($_[1])->{text})});
}

sub maybe_targmy
{
    my($self, $op, $cx, $func, @args) = @_;
    if ($op->private & OPpTARGET_MY) {
	my $var = $self->padname($op->targ);
	my $val = $func->($self, $op, 7, @args);
	my @texts = ($var, '=', $val);
	return info_from_list($op, $self, \@texts,
			      ' ', 'maybe_targmy',
			      {maybe_parens => [$self, $cx, 7]});
    } else {
	my $info = $func->($self, $op, $cx, @args);
	return $info;
    }
}

sub parens_test($$)
{
    my ($cx, $prec) = @_;
    return ($prec < $cx
	    # unary ops nest just fine
	    or $prec == $cx and $cx != 4 and $cx != 16 and $cx != 21)
}

# Possibly add () around $text depending on precidence $prec and
# context $cx. We return a string.
sub maybe_parens($$$$)
{
    my($self, $text, $cx, $prec) = @_;
    if (parens_test($cx, $prec) or $self->{'parens'}) {
	$text = "($text)";
	# In a unop, let parent reuse our parens; see maybe_parens_unop
	$text = "\cS" . $text if $cx == 16;
	return $text;
    } else {
	return $text;
    }
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
    } elsif (!null($cv->START) and is_state($cv->START)) {
	$seq = $cv->START->cop_seq;
    } else {
	$seq = 0;
    }
    push @{$self->{'subs_todo'}}, [$seq, $cv, $is_form, $name];
}

# _pessimise_walk(): recursively walk the optree of a sub,
# possibly undoing optimisations along the way.

sub _pessimise_walk {
    my ($self, $startop) = @_;

    return unless $$startop;
    my ($op, $prevop);
    for ($op = $startop; $$op; $prevop = $op, $op = $op->sibling) {
	my $ppname = $op->name;

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

sub _pessimise_walk_exe {
    my ($self, $startop, $visited) = @_;

    return unless $$startop;
    return if $visited->{$$startop};
    my ($op, $prevop);
    for ($op = $startop; $$op; $prevop = $op, $op = $op->next) {
	last if $visited->{$$op};
	$visited->{$$op} = 1;
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

sub stash_subs {
    my ($self, $pack, $seen) = @_;
    my (@ret, $stash);
    if (!defined $pack) {
	$pack = '';
	$stash = \%::;
    }
    else {
	$pack =~ s/(::)?$/::/;
	no strict 'refs';
	$stash = \%{"main::$pack"};
    }
    return
	if ($seen ||= {})->{
	    $INC{"overload.pm"} ? overload::StrVal($stash) : $stash
	   }++;
    my %stash = svref_2object($stash)->ARRAY;
    while (my ($key, $val) = each %stash) {
	my $flags = $val->FLAGS;
	if ($flags & SVf_ROK) {
	    # A reference.  Dump this if it is a reference to a CV.  If it
	    # is a constant acting as a proxy for a full subroutine, then
	    # we may or may not have to dump it.  If some form of perl-
	    # space visible code must have created it, be it a use
	    # statement, or some direct symbol-table manipulation code that
	    # we will deparse, then we don’t want to dump it.  If it is the
	    # result of a declaration like sub f () { 42 } then we *do*
	    # want to dump it.  The only way to distinguish these seems
	    # to be the SVs_PADTMP flag on the constant, which is admit-
	    # tedly a hack.
	    my $class = class(my $referent = $val->RV);
	    if ($class eq "CV") {
		$self->todo($referent, 0);
	    } elsif (
		$class !~ /^(AV|HV|CV|FM|IO|SPECIAL)\z/
		# A more robust way to write that would be this, but B does
		# not provide the SVt_ constants:
		# ($referent->FLAGS & B::SVTYPEMASK) < B::SVt_PVAV
		and $referent->FLAGS & SVs_PADTMP
	    ) {
		push @{$self->{'protos_todo'}}, [$pack . $key, $val];
	    }
	} elsif ($flags & (SVf_POK|SVf_IOK)) {
	    # Just a prototype. As an ugly but fairly effective way
	    # to find out if it belongs here is to see if the AUTOLOAD
	    # (if any) for the stash was defined in one of our files.
	    my $A = $stash{"AUTOLOAD"};
	    if (defined ($A) && class($A) eq "GV" && defined($A->CV)
		&& class($A->CV) eq "CV") {
		my $AF = $A->FILE;
		next unless $AF eq $0 || exists $self->{'files'}{$AF};
	    }
	    push @{$self->{'protos_todo'}},
		 [$pack . $key, $flags & SVf_POK ? $val->PV: undef];
	} elsif (class($val) eq "GV") {
	    if (class(my $cv = $val->CV) ne "SPECIAL") {
		next if $self->{'subs_done'}{$$val}++;
		next if $$val != ${$cv->GV};   # Ignore imposters
		$self->todo($cv, 0);
	    }
	    if (class(my $cv = $val->FORM) ne "SPECIAL") {
		next if $self->{'forms_done'}{$$val}++;
		next if $$val != ${$cv->GV};   # Ignore imposters
		$self->todo($cv, 1);
	    }
	    if (class($val->HV) ne "SPECIAL" && $key =~ /::$/) {
		$self->stash_subs($pack . $key, $seen);
	    }
	}
    }
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
	    unless (null $root) {
		$self->pessimise($root, main_start);
		# Print deparsed program
		print $self->indent_info($self->deparse_root($root)), "\n";
	    }
	} else {
	    unless (null $root) {
		$self->pad_subs($self->{'curcv'});
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
		     and !null($kid = $kid->sibling) and $kid->name eq 'stub'
		     and !null($kid = $kid->sibling) and $kid->name eq 'null'
		     and class($kid) eq 'COP' and null $kid->sibling )
		{
		    # ignore deparsing routine
		} else {
		    $self->pessimise($root, main_start);
		    # Print deparsed program
		    my $root_tree = $self->deparse_root($root);
		    print $self->indent_info($root_tree), "\n";
		}
	    }
	}
	my @text;
        while (scalar(@{$self->{'subs_todo'}})) {
	    push @text, $self->next_todo->{text};
	}
	print $self->indent(join("", @text)), "\n" if @text;

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

# This method is the inner loop, so try to keep it simple
sub deparse
{
    my($self, $op, $cx, $parent) = @_;

    Carp::confess("Null op in deparse") if !defined($op)
	|| class($op) eq "NULL";

    eval {
	my $meth = "pp_" . $op->name;
    };
    if ($@) {
	return;
    }
    my $meth = "pp_" . $op->name;
    # print "YYY $meth\n";
    my $info = $self->$meth($op, $cx);
    Carp::confess("nonref return for $meth deparse") if !ref($info);
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
		Carp::confess "Invalid $other";
	    }
	    $self->{optree}{$$other} = $info;
	}
    }
    return $info;
}

# Deparse a subroutine
sub deparse_sub($$$)
{
    my ($self, $cv, $parent) = @_;
    Carp::confess("NULL in deparse_sub") if !defined($cv) || $cv->isa("B::NULL");
    Carp::confess("SPECIAL in deparse_sub") if $cv->isa("B::SPECIAL");
    local $self->{'curcop'} = $self->{'curcop'};
    my $proto = '';
    if ($cv->FLAGS & SVf_POK) {
	$proto .= "(". $cv->PV . ") ";
    }
    if ($cv->CvFLAGS & (CVf_METHOD|CVf_LOCKED|CVf_LVALUE)) {
        $proto .= ": ";
        $proto .= "lvalue " if $cv->CvFLAGS & CVf_LVALUE;
        $proto .= "locked " if $cv->CvFLAGS & CVf_LOCKED;
        $proto .= "method " if $cv->CvFLAGS & CVf_METHOD;
    }

    local($self->{'curcv'}) = $cv;
    local($self->{'curcvlex'});
    local(@$self{qw'curstash warnings hints hinthash'})
		= @$self{qw'curstash warnings hints hinthash'};

    my $root = $cv->ROOT;
    my $body;

    my $info = {};

    local $B::overlay = {};
    if (not null $root) {
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
	else {
	    $body = $self->deparse($root->first, 0, $root);
	}
	my @texts = ("{\n\t", $body, "\n\b}");
	unshift @texts, $proto if $proto;
	$info = info_from_list($root, $self, \@texts, '', 'sub',
			       {other_ops =>[$lineseq]});
	$self->{optree}{$$lineseq} = $info;

    } else {
	my $sv = $cv->const_sv;
	if ($$sv) {
	    # uh-oh. inlinable sub... format it differently
	    my @texts = ("{", $self->const($sv, 0)->{text}, "}");
	    unshift @texts, $proto if $proto;
	    $info = info_from_list $sv, $self, \@texts, '', 'sub_const', {};
	} else { # XSUB? (or just a declaration)
	    my @texts = ();
	    @texts = push @texts, $proto if $proto;
	    $info = info_from_list $root, $self, \@texts, ' ', 'sub_decl', {};
	}
    }

    $info->{op} = $root;
    $info->{cop} = undef;
    $info->{parent}  = $parent if $parent;
    $self->{optree}{$$root} = $info;
    return $info;
}

sub next_todo
{
    my ($self, $parent) = @_;
    my $ent = shift @{$self->{'subs_todo'}};
    my $cv = $ent->[1];
    my $gv = $cv->GV;
    my $name = $self->gv_name($gv);
    if ($ent->[2]) {
	my $info = $self->deparse_format($ent->[1], $cv);
	my $texts = ["format $name", "=", $info->{text} + "\n"];
	return {
	    body => [$info],
	    texts => $texts,
	    type => 'format_todo',
	    text => join(" ", @$texts),
	};
    } else {
	$self->{'subs_declared'}{$name} = 1;
	if ($name eq "BEGIN") {
	    my $use_dec = $self->begin_is_use($cv);
	    if (defined ($use_dec) and $self->{'expand'} < 5) {
		if (0 == length($use_dec)) {
		    info_from_text($cv, $self, '', 'begin_todo', {});
		} else {
		    info_from_text($cv, $self, $use_dec, 'begin_todo_use', {});
		}
	    }
	}
	my $l = '';
	if ($self->{'linenums'}) {
	    my $line = $gv->LINE;
	    my $file = $gv->FILE;
	    $l = "\n# line $line \"$file\"\n";
	}
	my $p = '';
	my @texts = ();
	if (class($cv->STASH) ne "SPECIAL") {
	    my $stash = $cv->STASH->NAME;
	    if ($stash ne $self->{'curstash'}) {
		push @texts, 'package', $stash, ';\n';
		$name = "$self->{'curstash'}::$name" unless $name =~ /::/;
		$self->{'curstash'} = $stash;
	    }
	    $name =~ s/^\Q$stash\E::(?!\z|.*::)//;
	    push @texts, $name;
	}
	my $info = $self->deparse_sub($cv, $parent);
	push @texts, $info;
	return info_from_list($cv, $self, \@texts, ' ', 'sub_todo', {})
    }
}

# Deparse a subroutine by name
sub deparse_subname($$$)
{
    my ($self, $funcname, $parent) = @_;
    my $cv = svref_2object(\&$funcname);
    my $info = $self->deparse_sub($cv, $parent);
    return info_from_list($cv, $self, ['sub', $funcname, $info->{text}], ' ',
			  'deparse_subname', {body=>[$info]})
}

sub indent_list($$)
{
    my ($self, $lines_ref) = @_;
    my $leader = "";
    my $level = 0;
    for my $line (@{$lines_ref}) {
	my $cmd = substr($line, 0, 1);
	if ($cmd eq "\t" or $cmd eq "\b") {
	    $level += ($cmd eq "\t" ? 1 : -1) * $self->{'indent_size'};
	    if ($self->{'use_tabs'}) {
		$leader = "\t" x ($level / 8) . " " x ($level % 8);
	    } else {
		$leader = " " x $level;
	    }
	    $line = substr($line, 1);
	}
	if (index($line, "\f") > 0) {
		$line =~ s/\f/\n/;
	}
	if (substr($line, 0, 1) eq "\f") {
	    $line = substr($line, 1); # no indent
	} else {
	    $line = $leader . $line;
	}
	$line =~ s/\cK;?//g;
    }

    my @lines = grep $_ !~ /^\s*$/, @$lines_ref;
    return join("\n", @lines)
}

sub indent($$)
{
    my ($self, $text) = @_;
    my @lines = split(/\n/, $text);
    return $self->indent_list(\@lines);
}

# Like indent, but takes an info object and removes leading
# parenthesis.
sub indent_info($$)
{
    my ($self, $info) = @_;
    my $text = $info->{text};
    if ($info->{maybe_parens} and
	substr($text, 0, 1) eq '(' and
	substr($text, -1) eq ')' ) {
	$text = substr($text, 1, length($text) -2)
    }
    return $self->indent($text);
}

sub is_lexical_subs {
    my (@ops) = shift;
    for my $op (@ops) {
        return 0 if $op->name !~ /\A(?:introcv|clonecv)\z/;
    }
    return 1;
}

sub is_miniwhile { # check for one-line loop ('foo() while $y--')
    my $op = shift;
    return (!null($op) and null($op->sibling)
	    and $op->name eq "null" and class($op) eq "UNOP"
	    and (($op->first->name =~ /^(and|or)$/
		  and $op->first->first->sibling->name eq "lineseq")
		 or ($op->first->name eq "lineseq"
		     and not null $op->first->first->sibling
		     and $op->first->first->sibling->name eq "unstack")
		 ));
}

sub scopeop
{
    my($real_block, $self, $op, $cx) = @_;
    my $kid;
    my @kids;

    local(@$self{qw'curstash warnings hints hinthash'})
		= @$self{qw'curstash warnings hints hinthash'} if $real_block;
    if ($real_block) {
	$kid = $op->first->sibling; # skip enter
	if (is_miniwhile($kid)) {
	    my $top = $kid->first;
	    my $name = $top->name;
	    if ($name eq "and") {
		$name = $self->keyword("while");
	    } elsif ($name eq "or") {
		$name = $self->keyword("until");
	    } else { # no conditional -> while 1 or until 0
		my $body = $self->deparse($top->first, 1, $top);
		return info_from_list $op, $self, [$body, 'while', '1'],
				      ' ', "$name 1", {};
	    }
	    my $cond = $top->first;
	    my $other_ops = [$cond->sibling];
	    my $body = $cond->sibling->first; # skip lineseq
	    my $cond_info = $self->deparse($cond, 1, $top);
	    my $body_info = $self->deparse($body, 1, $top);
	    return  info_from_list($op, $self,
				   [$body_info, $name, $cond_info], ' ',
				   "$name",
				   {other_ops => $other_ops});
	}
    } else {
	$kid = $op->first;
    }
    for (; !null($kid); $kid = $kid->sibling) {
	push @kids, $kid;
    }
    if ($cx > 0) {
	# inside an expression, (a do {} while for lineseq)
	my $body = $self->lineseq($op, 0, @kids);
	my @texts = ($body->{text});
	my $text;
	my $type = 'scope expression';
	unless (is_lexical_subs(@kids)) {
	    $type = 'scope do';
	    @texts = ('do ', "{\n\t", @texts, "\n\b}");
	};
	return info_from_list($op, $self, \@texts, '', $type, {});
    } else {
	my $ls = $self->lineseq($op, $cx, @kids);
	return info_from_list($op, $self, [$ls], '', 'scope line sequence', {});
    }
}

# Return just the name, without the prefix.  It may be returned as a quoted
# string.  The second return value is a boolean indicating that.
sub stash_variable_name {
    my($self, $prefix, $gv) = @_;
    my $name = $self->gv_name($gv, 1);
    $name = $self->maybe_qualify($prefix,$name);
    if ($name =~ /^(?:\S|(?!\d)[\ca-\cz]?(?:\w|::)*|\d+)\z/) {
	$name =~ s/^([\ca-\cz])/'^' . $B::Deparse::unctrl{$1}/e;
	$name =~ /^(\^..|{)/ and $name = "{$name}";
	return $name, 0; # not quoted
    }
    else {
	$self->single_delim($gv, "q", "'", $name, $self), 1;
    }
}

sub balanced_delim
{
    my($str) = @_;
    my @str = split //, $str;
    my($ar, $open, $close, $fail, $c, $cnt, $last_bs);
    for $ar (['[',']'], ['(',')'], ['<','>'], ['{','}']) {
	($open, $close) = @$ar;
	$fail = 0; $cnt = 0; $last_bs = 0;
	for $c (@str) {
	    if ($c eq $open) {
		$fail = 1 if $last_bs;
		$cnt++;
	    } elsif ($c eq $close) {
		$fail = 1 if $last_bs;
		$cnt--;
		if ($cnt < 0) {
		    # qq()() isn't ")("
		    $fail = 1;
		    last;
		}
	    }
	    $last_bs = $c eq '\\';
	}
	$fail = 1 if $cnt != 0;
	return ($open, "$open$str$close") if not $fail;
    }
    return ("", $str);
}

sub hint_pragmas {
    my ($bits) = @_;
    my (@pragmas, @strict);
    push @pragmas, "integer" if $bits & 0x1;
    for (sort keys %strict_bits) {
	push @strict, "'$_'" if $bits & $strict_bits{$_};
    }
    if (@strict == keys %strict_bits) {
	push @pragmas, "strict";
    }
    elsif (@strict) {
	push @pragmas, "strict " . join ', ', @strict;
    }
    push @pragmas, "bytes" if $bits & 0x8;
    return @pragmas;
}

sub declare_hints
{
    my ($self, $from, $to) = @_;
    my $use = $to   & ~$from;
    my $no  = $from & ~$to;
    my $decls = "";
    for my $pragma (hint_pragmas($use)) {
	$decls .= $self->keyword("use") . " $pragma;\n";
    }
    for my $pragma (hint_pragmas($no)) {
        $decls .= $self->keyword("no") . " $pragma;\n";
    }
    return $decls;
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
	     join("\n" . (" " x $indent), "BEGIN {", @decls) . "\n}\n\cK";
    return @ret;
}

sub _features_from_bundle
{
    my ($hints, $hh) = @_;
    no warnings 'once';
    foreach (@{$feature::feature_bundle{@feature::hint_bundles[$hints >> $feature::hint_shift]}}) {
	$hh->{$feature::feature{$_}} = 1;
    }
    return $hh;
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


sub declare_warnings
{
    my ($self, $from, $to) = @_;
    if (($to & WARN_MASK) eq (warnings::bits("all") & WARN_MASK)) {
	return $self->keyword("use") . " warnings;\n";
    }
    elsif (($to & WARN_MASK) eq ("\0"x length($to) & WARN_MASK)) {
	return $self->keyword("no") . " warnings;\n";
    }
    return "BEGIN {\${^WARNING_BITS} = \""
           . join("", map { sprintf("\\x%02x", ord $_) } split "", $to)
           . "\"}\n\cK";
}

sub is_scope {
    my $op = shift;
    return $op->name eq "leave" || $op->name eq "scope"
      || $op->name eq "lineseq"
	|| ($op->name eq "null" && class($op) eq "UNOP"
	    && (is_scope($op->first) || $op->first->name eq "enter"));
}

sub indirop
{
    my($self, $op, $cx, $name) = @_;
    my($expr, @exprs);
    my $firstkid = my $kid = $op->first->sibling;
    my $indir_info;
    my @body = ();
    my $type = 'indirop';
    my @other_ops = ($op->first);
    my @indir = ();

    if ($op->flags & OPf_STACKED) {
	push @other_ops, $kid;
	my $indir_op = $kid->first; # skip rv2gv
	if (is_scope($indir_op)) {
	    $indir_info = $self->deparse($indir_op, 0, $op);
	    @indir = $indir_info->{text} eq '' ?
		("{", ';', "}") : ("{", $indir_info->{texts}, "}");

	} elsif ($indir_op->name eq "const" && $indir_op->private & OPpCONST_BARE) {
	    @indir = ($self->const_sv($indir_op)->PV);
	} else {
	    $indir_info = $self->deparse($indir_op, 24, $op);
	    @indir = @{$indir_info->{texts}};
	}
	push @body, $indir_info if $indir_info;
	$kid = $kid->sibling;
    }
    if ($name eq "sort" && $op->private & (OPpSORT_NUMERIC | OPpSORT_INTEGER)) {
	$type = 'sort_num_int';
	@indir = ($op->private & OPpSORT_DESCEND) ?
	    ('{', '$b', ' <=> ', '$a', '}' ) : ('{', '$a', ' <=> ', '$b', '}' );
    }
    elsif ($name eq "sort" && $op->private & OPpSORT_DESCEND) {
	$type = 'sort_descend';
	@indir =  ('{', '$b', ' cmp ', '$a', '}' );
    }

    for (; !null($kid); $kid = $kid->sibling) {
	my $cx = (!scalar(@indir) &&
		  $kid == $firstkid && $name eq "sort" &&
		  $firstkid->name eq "entersub")
	    ? 16 : 6;
	$expr = $self->deparse($kid, $cx, $op);
	push @exprs, $expr;
    }

    push @body, @exprs;
    my $opts = {
	body => \@body,
	other_ops => \@other_ops
    };

    my $name2;
    if ($name eq "sort" && $op->private & OPpSORT_REVERSE) {
	$type = 'sort_reverse';
	$name2 = $self->keyword('reverse') . ' ' . $self->keyword('sort');
    }  else {
	$name2 = $self->keyword($name);
    }
    my $indir = scalar @indir ? (join('', @indir) . ' ') : '';
    if ($name eq "sort" && ($op->private & OPpSORT_INPLACE)) {
	my @texts = ($exprs[0], '=', $name2, $indir, $exprs[0]);
	return info_from_list $op, $self, \@texts, '', 'sort_inplace', $opts;
    }

    my @texts;
    my $args = $indir . join(', ', map($_->{text},  @exprs));
    if ($indir ne "" && $name eq "sort") {
	# We don't want to say "sort(f 1, 2, 3)", since perl -w will
	# give bareword warnings in that case. Therefore if context
	# requires, we'll put parens around the outside "(sort f 1, 2,
	# 3)". Unfortunately, we'll currently think the parens are
	# necessary more often that they really are, because we don't
	# distinguish which side of an assignment we're on.
	if ($cx >= 5) {
	    @texts = ('(', $name2, $args, ')');
	} else {
	    @texts = ($name2, $args);
	}
	$type='sort1';
    } elsif (!$indir && $name eq "sort"
	     && !null($op->first->sibling)
	     && $op->first->sibling->name eq 'entersub' ) {
	# We cannot say sort foo(bar), as foo will be interpreted as a
	# comparison routine.  We have to say sort(...) in that case.
	@texts = ($name2, '(', $args, ')');
	$type='sort2';
    } else {
	# indir
	if (length $args) {
	    $type='indirop';
	    @texts = ($self->maybe_parens_func($name2, $args, $cx, 5))
	} else {
	    $type='indirop_noargs';
	    @texts = ($name2);
	    push(@texts, '(', ')') if (7 < $cx);
	}
    }
    return info_from_list($op, $self, \@texts, '', $type, $opts);
}

sub pp_unstack {
    my ($self, $op) = @_;
    # see also leaveloop
    return info_from_text($op, $self, '', 'unstack', {});
}

# Logical ops, if/until, &&, and
# The one-line while/until is handled in pp_leave
sub logop
{
    my ($self, $op, $cx, $lowop, $lowprec, $highop,
	$highprec, $blockname) = @_;
    my $left = $op->first;
    my $right = $op->first->sibling;
    my ($lhs, $rhs, $texts, $text);
    my $type;
    my $sep;
    my $opts = {};
    if ($cx < 1 and is_scope($right) and $blockname
	and $self->{'expand'} < 7) {
	# if ($a) {$b}
	$lhs = $self->deparse($left, 1, $op);
	$rhs = $self->deparse($right, 0, $op);
	$sep = '';
	$texts = [$blockname, ' (', $lhs->{text}, ') ',
		  "{\n\t", $rhs->{text}, "\n\b}\cK"];
    } elsif ($cx < 1 and $blockname and not $self->{'parens'}
	     and $self->{'expand'} < 7) { # $b if $a
	$lhs = $self->deparse($left, 1, $op);
	$rhs = $self->deparse($right, 1, $op);
	$texts = [$rhs->{text}, $blockname, $lhs->{text}];
	$sep = ' ';
    } elsif ($cx > $lowprec and $highop) {
	# $a && $b
	$lhs = $self->deparse_binop_left($op, $left, $highprec);
	$rhs = $self->deparse_binop_right($op, $right, $highprec);
	$texts = [$lhs->{text}, $highop, $rhs->{text}];
	$sep = ' ';
	$opts = {maybe_parens => [$self, $cx, $highprec]};
    } else {
	# $a and $b
	$lhs = $self->deparse_binop_left($op, $left, $lowprec);
	$rhs = $self->deparse_binop_right($op, $right, $lowprec);
	$texts = [$lhs->{text}, $lowop, $rhs->{text}];
	$sep = ' ';
	$opts = {maybe_parens => [$self, $cx, $lowprec]};
    }
    $opts->{block} = [$lhs, $rhs];
    return info_from_list($op, $self, $texts, $sep, $type, $opts);
}

sub baseop
{
    my($self, $op, $cx, $name) = @_;
    return info_from_text($op, $self, $self->keyword($name), 'baseop', {});
}

sub POSTFIX () { 1 }

# This is the category of symbolic prefix and postfix unary operators,
# e.g $x++, -r, +$x.
sub pfixop
{
    my $self = shift;
    my($op, $cx, $operator, $prec, $flags) = (@_, 0);
    my $operand = $self->deparse($op->first, $prec, $op);
    my $type;
    my @texts;
    if ($flags & POSTFIX) {
	@texts = ($operand, $operator);
	$type = 'prefix_op';
    } elsif ($operator eq '-' && $operand->{text} =~ /^[a-zA-Z](?!\w)/) {
	# avoid confusion with filetests
	$type = 'prefix_filetest';
	@texts = ($operand, '(', $operator, ')');
    } else {
	$type = 'postfix_op';
	@texts = ($operator, $operand);
    }

    return info_from_list $op, $self, \@texts, '', $type,
			  {maybe_parens => [$self, $cx, $prec]} ;
}

sub mapop
{
    my($self, $op, $cx, $name) = @_;
    my $kid = $op->first; # this is the (map|grep)start

    my @other_ops = ($kid, $kid->first);
    $kid = $kid->first->sibling; # skip a pushmark

    my $code = $kid->first; # skip a null

    my $code_info;

    my @block_texts = ();
    my @exprs_texts = ();
    if (is_scope $code) {
	$code_info = $self->deparse($code, 0, $op);
	(my $text = $code_info->{text})=~ s/^\n//;  # remove first \n in block.
	@block_texts = ('{', $text, '}');
    } else {
	$code_info = $self->deparse($code, 24, $op);
	@exprs_texts = ($code_info->{text});
    }
    my @body = ($code_info);

    push @other_ops, $kid;
    $kid = $kid->sibling;
    my($expr, @exprs);
    for (; !null($kid); $kid = $kid->sibling) {
	$expr = $self->deparse($kid, 6, $op);
	push @exprs, $expr if defined $expr;
    }
    push @body, @exprs;
    push @exprs_texts, map $_->{text}, @exprs;
    my $opts = {
	body => \@body,
	other_ops => \@other_ops,
    };
    my $params = join(', ', @exprs_texts);
    $params = join(" ", @block_texts) . ' ' . $params if @block_texts;
    my @texts = $self->maybe_parens_func($name, $params, $cx, 5);
    return info_from_list $op, $self, \@texts, '', 'mapop', $opts;
}


sub seq_subs {
    my ($self, $seq) = @_;
    my @text;
    # push @text, "# ($seq)\n";

    return "" if !defined $seq;
    my $sep = "\n\nsub ";
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
	    push @pending, shift @{$self->{'subs_todo'}};
	    next;
	}
	push @text, $sep if @text;
	push @text, $self->next_todo;
    }
    return @text;
}

sub single_delim($$$$$) {
    my($self, $op, $q, $default, $str) = @_;

    if (!defined($str)) {
	# FIXME: this is a workaround.
	$str = '"';
    }
    return info_from_list($op, $self, [$default, $str, $default], '',
			  "single delimiter default $default", {})
	if $default and index($str, $default) == -1;
    if ($q ne 'qr') {
	(my $succeed, $str) = balanced_delim($str);
	return info_from_list($op, $self, [$q, $str], '', "single delimiter $q", {}) if $succeed;
    }
    for my $delim ('/', '"', '#') {
	return info_from_list($op, $self, [$q, $delim, $str,
			   $delim], '', "single delimiter qr $delim", {})
	    if index($str, $delim) == -1;
    }
    if ($default) {
	$str =~ s/$default/\\$default/g;
	return info_from_list($op, $self, [$default, $str, $default], '',
	    "single delimiter qr escape $default", {});
    } else {
	$str =~ s[/][\\/]g;
	return info_from_list($op, $self, [$q, '/', $str, '/'], '',
	    "single delimiter qr /", {});
    }
}

sub unop
{
    my($self, $op, $cx, $name, $nollafr) = @_;
    my $kid;
    if ($op->flags & OPf_KIDS) {
	$kid = $op->first;
 	if (not $name) {
 	    # this deals with 'boolkeys' right now
 	    return $self->deparse($kid, $cx, $op);
 	}
	my $builtinname = $name;
	$builtinname =~ /^CORE::/ or $builtinname = "CORE::$name";
	if (defined prototype($builtinname)
	   && $builtinname ne 'CORE::readline'
	   && prototype($builtinname) =~ /^;?\*/
	   && $kid->name eq "rv2gv") {
	    $kid = $kid->first;
	}

	if ($nollafr) {
	    $kid = $self->deparse($kid, 16, $op);
	    ($kid->{text}) =~ s/^\cS//;
	    my $opts = {
		body => [$kid],
		maybe_parens => [$self, $cx, 16],
	    };
	    return info_from_list($op, $self, [($self->keyword($name), $kid->{text})],
				  ' ', 'unary operator noallafr', $opts);
	}
	return $self->maybe_parens_unop($name, $kid, $cx, $op);
    } else {
	my $opts = {maybe_parens => [$self, $cx, 16]};
	my @texts = ($self->keyword($name));
	push @texts, '()' if $op->flags & OPf_SPECIAL;
	return info_from_list($op, $self, \@texts, '', 'unary operator', $opts);
    }
}

# Demo code
unless(caller) {
    my @texts = ('a', 'b', 'c');
    my $info; # = info_from_list('op', 'deparse',\@texts, ', ', 'test', {});
    use Data::Printer;
    # p $info;
    @texts = (['a', 1], ['b', 2], 'c');
    $info = info_from_list('op', 'deparse',\@texts, ', ', 'test', {});
    p $info;
}


1;
