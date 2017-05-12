# Copyright (c) 2015 Rocky Bernstein
use strict; use warnings;

package B::DeparseTree::Common;

use B qw(class
         main_cv main_root main_start
         opnumber OPpLVAL_INTRO OPf_SPECIAL OPf_KIDS SVf_ROK
         SVf_POK CVf_LVALUE CVf_METHOD
         OPf_STACKED OPpCONST_BARE OPpSORT_NUMERIC OPpSORT_INTEGER
         OPpSORT_REVERSE OPpTARGET_MY svref_2object perlstring);
use Carp;

our($VERSION, @EXPORT, @ISA);
$VERSION = '1.1.0';
@ISA = qw(Exporter);
@EXPORT = qw(maybe_parens info_from_list info_from_text null new WARN_MASK
            indent_list indent indent_info parens_test print_protos
            style_opts scopeop declare_hints hint_pragmas
            is_miniwhile is_lexical_subs %strict_bits
            %rev_feature declare_hinthash declare_warnings %ignored_hints
            _features_from_bundle ambiant_pragmas maybe_qualify
            %globalnames gv_name is_scope logop maybe_targmy is_state
            POSTFIX baseop mapop pfixop indirop
            deparse_sub deparse_subname next_todo
            );

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

our %strict_bits = do {
    local $^H;
    map +($_ => strict::bits($_)), qw/refs subs vars/
};

BEGIN { for (qw[ pushmark ]) {
    eval "sub OP_\U$_ () { " . opnumber($_) . "}"
}}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
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

# Initialize the contextual information, either from
# defaults provided with the ambient_pragmas method,
# or from perl's own defaults otherwise.
sub init($)
{
    my $self = shift;

    $self->{'arybase'}  = $self->{'ambient_arybase'};
    $self->{'warnings'} = defined ($self->{'ambient_warnings'})
				? $self->{'ambient_warnings'} & WARN_MASK
				: undef;
    $self->{'hints'}    = $self->{'ambient_hints'};
    $self->{'hinthash'} = $self->{'ambient_hinthash'};

    # also a convenient place to clear out subs_declared
    delete $self->{'subs_declared'};
}

sub main2info($)
{
    my $self = shift;
    $self->{'curcv'} = B::main_cv;
    $self->pessimize(B::main_root, B::main_start);
    return $self->deparse_root(B::main_root);
}

sub coderef2info($$)
{
    my ($self, $coderef) = @_;
    croak "Usage: ->coderef2info(CODEREF)" unless UNIVERSAL::isa($coderef, "CODE");
    $self->init();
    return $self->deparse_sub(svref_2object($coderef));
}

sub coderef2text($$)
{
    my ($self, $func) = @_;
    croak "Usage: ->coderef2text(CODEREF)" unless UNIVERSAL::isa($func, "CODE");

    $self->init();
    my $info = $self->coderef2info($func);
    return $self->indent($info->{text});
}

sub print_protos($)
{
    my $self = shift;
    my $ar;
    my @ret;
    foreach $ar (@{$self->{'protos_todo'}}) {
	my $proto = (defined $ar->[1] ? " (". $ar->[1] . ")" : "");
	push @ret, "sub " . $ar->[0] .  "$proto;\n";
    }
    delete $self->{'protos_todo'};
    return @ret;
}

sub style_opts($$)
{
    my ($self, $opts) = @_;
    my $opt;
    while (length($opt = substr($opts, 0, 1))) {
	if ($opt eq "T") {
	    $self->{'use_tabs'} = 1;
	    $opts = substr($opts, 1);
	} elsif ($opt eq "v") {
	    $opts =~ s/^v([^.]*)(.|$)//;
	    $self->{'ex_const'} = $1;
	} else {
	    $opts = substr($opts, 1);
	}
    }
}

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
sub info_from_list($$$$)
{
    my ($texts, $sep, $type, $opts) = @_;
    my $text = join($sep, @$texts);
    my $info = {
	text => $text,
	texts => $texts,
	type => $type,
	sep => $sep,
    };
    foreach my $optname (qw(body other_ops)) {
	$info->{$optname} = $opts->{$optname} if $opts->{$optname};
    }
    if ($opts->{maybe_parens}) {
	my ($self, $cx, $prec) = @{$opts->{maybe_parens}};
	$info->{text} = $self->maybe_parens($info->{text}, $cx, $prec);
	$info->{maybe_parens} = {context => $cx , precidence => $prec};
    }
    return $info
}

# Create an info structure from a single string
sub info_from_text($$$)
{
    my ($text, $type, $opts) = @_;
    return info_from_list([$text], '', $type, $opts)
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
    my @texts = map { $_->{text} =~ /(?:\n#)|^\s*$/ ?
			  $_->{text} : $_->{text} . ';' } @body;
    my $info = info_from_list(\@texts, "\n", 'lineseq',
			      {op => $op, body => \@body});
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
	if ($info->{body}) {
	    foreach my $bod (@{$info->{body}}) {
		if (!ref($bod)) {
		    Carp::carp(sprintf "nonref body: %s, op: %s", $bod, $op->name)
		} else {
		    $bod->{parent} = $$op;
		}
	    }
	}
	$self->{optree}{$$op} = $info;
	$info->{text} = $text;
	push @$exprs, $info;
    };
    return $self->walk_lineseq($root, \@ops, $fn);
}

sub maybe_targmy
{
    my($self, $op, $cx, $func, @args) = @_;
    if ($op->private & OPpTARGET_MY) {
	my $var = $self->padname($op->targ);
	my $val = $func->($self, $op, 7, @args);
	return info_from_list([$var, '=', $val->{text}],
			      ' ', 'maybe_targmy',
			      {maybe_parens => [$self, $cx, 7]});
    } else {
	return $func->($self, $op, $cx, @args);
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

# _pessimize_walk(): recursively walk the optree of a sub,
# possibly undoing optimisations along the way.

sub _pessimize_walk($$)
{
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
		    next    => ($op->flags & OPf_SPECIAL)
				    ? $op->sibling->first
				    : $op->sibling,
	    };
	}

	# pessimizations end here

	if (class($op) eq 'PMOP'
	    && ref($op->pmreplroot)
	    && ${$op->pmreplroot}
	    && $op->pmreplroot->isa( 'B::OP' ))
	{
	    $self-> _pessimize_walk($op->pmreplroot);
	}

	if ($op->flags & OPf_KIDS) {
	    $self-> _pessimize_walk($op->first);
	}

    }
}


# _pessimise_walk_exe(): recursively walk the op_next chain of a sub,
# possibly undoing optimisations along the way.

sub _pessimize_walk_exe
{
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
	    $self->_pessimize_walk_exe($op->other, $visited);
	}
	elsif ($ppname eq "subst") {
	    $self->_pessimize_walk_exe($op->pmreplstart, $visited);
	}
	elsif ($ppname =~ /^(enter(loop|iter))$/) {
	    # redoop and nextop will already be covered by the main block
	    # of the loop
	    $self->_pessimize_walk_exe($op->lastop, $visited);
	}

	# pessimizations start here
    }
}

# Go through an optree and "remove" some optimisations by using an
# overlay to selectively modify or un-null some ops. Deparsing in the
# absence of those optimizations is then easier.
#
# Note that older optimizations are not removed, as Deparse was already
# written to recognise them before the pessimize/overlay system was added.

sub pessimize {
    my ($self, $root, $start) = @_;

    # walk tree in root-to-branch order
    $self->_pessimize_walk($root);

    my %visited;
    # walk tree in execution order
    $self->_pessimize_walk_exe($start, \%visited);
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
	my $class = class($val);
	if ($class eq "PV") {
	    # Just a prototype. As an ugly but fairly effective way
	    # to find out if it belongs here is to see if the AUTOLOAD
	    # (if any) for the stash was defined in one of our files.
	    my $A = $stash{"AUTOLOAD"};
	    if (defined ($A) && class($A) eq "GV" && defined($A->CV)
		&& class($A->CV) eq "CV") {
		my $AF = $A->FILE;
		next unless $AF eq $0 || exists $self->{'files'}{$AF};
	    }
	    push @{$self->{'protos_todo'}}, [$pack . $key, $val->PV];
	} elsif ($class eq "IV" && !($val->FLAGS & SVf_ROK)) {
	    # Just a name. As above.
	    # But skip proxy constant subroutines, as some form of perl-space
	    # visible code must have created them, be it a use statement, or
	    # some direct symbol-table manipulation code that we will Deparse
	    my $A = $stash{"AUTOLOAD"};
	    if (defined ($A) && class($A) eq "GV" && defined($A->CV)
		&& class($A->CV) eq "CV") {
		my $AF = $A->FILE;
		next unless $AF eq $0 || exists $self->{'files'}{$AF};
	    }
	    push @{$self->{'protos_todo'}}, [$pack . $key, undef];
	} elsif ($class eq "GV") {
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
	for my $block (@BEGINs, @UNITCHECKs, @CHECKs, @INITs, @ENDs) {
	    $self->todo($block, 0);
	}
	$self->stash_subs();
	local($SIG{"__DIE__"}) =
	  sub {
	      if ($self->{'curcop'}) {
		  my $cop = $self->{'curcop'};
		  my($line, $file) = ($cop->line, $cop->file);
		  print STDERR "While deparsing $file near line $line,\n";
	      }
	    };
	$self->{'curcv'} = main_cv;
	$self->{'curcvlex'} = undef;
	print $self->print_protos;
	@{$self->{'subs_todo'}} =
	  sort {$a->[0] <=> $b->[0]} @{$self->{'subs_todo'}};
	my $root = main_root;
	local $B::overlay = {};
	unless (null $root) {
	    $self->pessimize($root, main_start);
	    my $deparsed = $self->deparse_root($root);
	    print $self->indent_info($deparsed), "\n";
	}
	my @texts;
	while (scalar(@{$self->{'subs_todo'}})) {
	    push @texts, $self->next_todo;
	}
	print $self->indent(join("", @texts)), "\n" if @texts;

	# Print __DATA__ section, if necessary
	no strict 'refs';
	my $laststash = defined $self->{'curcop'}
	    ? $self->{'curcop'}->stash->NAME : $self->{'curstash'};
	if (defined *{$laststash."::DATA"}{IO}) {
	    print "package $laststash;\n"
		unless $laststash eq $self->{'curstash'};
	    print "__DATA__\n";
	    print readline(*{$laststash."::DATA"});
	}
    }
}

# This method is the inner loop, so try to keep it simple
sub deparse($$$$)
{
    my($self, $op, $cx, $parent) = @_;

    Carp::confess("Null op in deparse") if !defined($op)
					|| class($op) eq "NULL";
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
	$self->pessimize($root, $cv->START);
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
	my @texts = ("{\n\t", $body->{text}, "\n\b}");
	unshift @texts, $proto if $proto;
	$info = info_from_list(\@texts, '', 'sub',
			       {body =>[$body],
			        other_ops =>[$lineseq]});
	$self->{optree}{$$lineseq} = $info;

    } else {
	my $sv = $cv->const_sv;
	if ($$sv) {
	    # uh-oh. inlinable sub... format it differently
	    my @texts = ("{", $self->const($sv, 0)->{text}, "}");
	    unshift @texts, $proto if $proto;
	    $info = info_from_list \@texts, '', 'sub_const', {};
	} else { # XSUB? (or just a declaration)
	    my @texts = ();
	    @texts = push @texts, $proto if $proto;
	    $info = info_from_list \@texts, ' ', 'sub_decl', {};
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
		return { text => '', type => 'begin_todo' } if 0 == length($use_dec);
		return { text => $use_dec, type => 'begin_todo' };
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
	push @texts, $info->{text};
	return info_from_list(\@texts, ' ', 'sub_todo', {body=>[$info]})
    }
}

# Deparse a subroutine by name
sub deparse_subname($$$)
{
    my ($self, $funcname, $parent) = @_;
    my $cv = svref_2object(\&$funcname);
    my $info = $self->deparse_sub($cv, $parent);
    return info_from_list(['sub', $funcname, $info->{text}], ' ',
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
		$name = "while";
	    } elsif ($name eq "or") {
		$name = "until";
	    } else { # no conditional -> while 1 or until 0
		my $body = [$self->deparse($top->first, 1, $top)];
		return info_from_list([$body->{text}, 'while', '1'],
				      ' ', 'while_1', {body =>$body});
	    }
	    my $cond = $top->first;
	    my $other_ops = [$cond->sibling];
	    my $body = $cond->sibling->first; # skip lineseq
	    my $cond_info = $self->deparse($cond, 1, $top);
	    my $body_info = $self->deparse($body, 1, $top);
	    my @texts = ($body_info->{text}, $name, $cond_info->{text});
	    my $text = join(' ', @texts);
	    return {
		type => 'scopeop_block',
		body => [$cond_info, $body_info],
		texts => \@texts,
		text => $text,
		other_ops => $other_ops,
	    };
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
	unless (is_lexical_subs(@kids)) {
	    @texts = ('do ', "{\n\t", @texts, "\n\b}");
	};
	return {
	    type => 'scope_expr',
	    text => join('', @texts),
	    texts => \@texts,
	};
    } else {
	my $ls = $self->lineseq($op, $cx, @kids);
	my $text = $ls->{text};
	return info_from_text($text, 'scopeop', {});
    }
}

sub hint_pragmas($)
{
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

sub declare_hints($$)
{
    my ($from, $to) = @_;
    my $use = $to   & ~$from;
    my $no  = $from & ~$to;
    my $decls = "";
    for my $pragma (hint_pragmas($use)) {
	$decls .= "use $pragma;\n";
    }
    for my $pragma (hint_pragmas($no)) {
        $decls .= "no $pragma;\n";
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

sub declare_hinthash
{
    my ($from, $to, $indent, $hints) = @_;
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
		qq(\$^H{) . single_delim("q", "'", $key) . qq(} = )
	      . (
		   defined $to->{$key}
			? single_delim("q", "'", $to->{$key})
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
	push @ret, "use feature "
		 . join(", ", map "'$rev_feature{$_}'", @features) . ";\n";
    }
    if (@unfeatures) {
	push @ret, "no feature "
		 . join(", ", map "'$rev_feature{$_}'", @unfeatures)
		 . ";\n";
    }
    @decls and
	push @ret,
	     join("\n" . (" " x $indent), "BEGIN {", @decls) . "\n}\n";
    return @ret;
}

sub _features_from_bundle
{
    my ($hints, $hh) = @_;
    foreach (@{$feature::feature_bundle{@feature::hint_bundles[$hints >> $feature::hint_shift]}}) {
	$hh->{$feature::feature{$_}} = 1;
    }
    return $hh;
}

sub declare_warnings
{
    my ($from, $to) = @_;
    if (($to & WARN_MASK) eq (warnings::bits("all") & WARN_MASK)) {
	return "use warnings;\n";
    }
    elsif (($to & WARN_MASK) eq ("\0"x length($to) & WARN_MASK)) {
	return "no warnings;\n";
    }
    return "BEGIN {\${^WARNING_BITS} = ".perlstring($to)."}\n";
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
	my @texts = ($exprs[0]->{text}, '=', $name2, $indir, $exprs[0]->{text});
	return info_from_list(\@texts, '', 'sort_inplace', $opts);
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
    return info_from_list(\@texts, '', $type, $opts);
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
	$texts = [$blockname, ' ', '(', $lhs->{text}, ')', ' ',
		  "{\n\t", $rhs->{text}, "\n\b}\cK"];
    } elsif ($cx < 1 and $blockname and not $self->{'parens'}
	     and $self->{'expand'} < 7) { # $b if $a
	$lhs = $self->deparse($left, 1, $op);
	$rhs = $self->deparse($right, 1, $op);
	$texts = [$rhs->{text}, $blockname, $lhs->{text}];
	$sep = ' ';
	$text = join(' ', @$texts);
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
    return info_from_list($texts, $sep, $type, $opts);
}

sub baseop
{
    my($self, $op, $cx, $name) = @_;
    return info_from_text($self->keyword($name), 'baseop', {});
}

sub POSTFIX () { 1 }

# I couldn't think of a good short name, but this is the category of
# symbolic unary operators with interesting precedence

sub pfixop
{
    my $self = shift;
    my($op, $cx, $name, $prec, $flags) = (@_, 0);
    my $kid = $op->first;
    $kid = $self->deparse($kid, $prec, $op);
    my $type = 'pfixop';
    my @texts;
    if ($flags & POSTFIX) {
	@texts = ($kid->{text}, $name);
	$type = 'pfixop_postfix';
    } elsif ($name eq '-' && $kid =~ /^[a-zA-Z](?!\w)/) {
	# avoid confusion with filetests
	$type = 'pfixop_minus';
	@texts = ($kid->{text}, '(', $name, ')');
    } else {
	@texts = ($name, $kid->{text});
    }

    return info_from_list(\@texts, '', $type,
			  {maybe_parens => [$self, $cx, $prec]});
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
    return info_from_list(\@texts, '', 'mapop', $opts)
}

1;
