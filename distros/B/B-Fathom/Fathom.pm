package B::Fathom;

use strict;

use B;

use vars qw($VERSION);
$VERSION = 0.07;

=head1 NAME

B::Fathom - a module to evaluate the readability of Perl code

=head1 SYNOPSIS

    perl -MO=Fathom <script>

or

    perl -MO=Fathom,-v <script>

where E<lt>scriptE<gt> is the name of the Perl program that you
want to evaluate.

C<-v> activates verbose mode, which currently reports which subs have been
skipped over because they seem to be imported.  One can also indicate C<-vN>,
where C<N> is some number greater than zero, to provide I<even more> verbose
diagnostics.  The specifics of these modes may change in future releases.  See
comments in the code for further information.

There is also an OO interface, which can be used as follows:

    my $fathom  = B::Fathom->new('-v');
    my $score   = $fathom->fathom(\&foo);

See METHODS below for a more complete explanation of the OO interface.

=head1 DESCRIPTION

C<B::Fathom> is a backend to the Perl compiler; it analyzes the syntax
of your Perl code, and estimates the readability of your program.

Currently, this module's idea of `readability' is based on methods
used for analyzing readability of English prose.  Further extensions
are intended.

=head1 METHODS

There is a simple object-oriented interface to B::Fathom.  It consists of two
methods:

=over 4

=item new(@args)

This method constructs a new compiler object.  The optional @args indicate
compiler options; see SYNOPSIS for a list.

=item fathom(@subrefs)

This method grades the subroutines referred to by @subrefs, and returns
their score as a string.

=back

=head1 CAVEATS

Because of the nature of the compiler, C<Fathom> has to do some
guessing about the syntax of your program.  See the comments in the
module for specifics.

C<Fathom> doesn't work very well on modules yet.

=head1 AUTHOR

Kurt Starsinic E<lt>F<kstar@cpan.org>E<gt>

=head1 COPYRIGHT

    Copyright (c) 1998, 1999, 2000 Kurt Starsinic.
    This module is free software; you may redistribute it
    and/or modify it under the same terms as Perl itself.

=cut


# TODO:
#   Incorporate Halstead's effort equation and McCabe's cyclomatic metric.
#   Process format statements, prototypes, and package statements.
#   Do a more accurate job when processing modules, rather than scripts.
#   Be smarter about parentheses.
#   Find a `cooler' way to dereference CV's than using symbolic refs.


my (%Taken, %Name, @Skip_sub, @Subs_queue);
my ($Tok, $Expr, $State, $Sub) = (0, 0, 0, 0);
my $Verbose = 0;
my (%Boring) = (
    pp_null         => 1,
    pp_enter        => 1,
    pp_pushmark     => 1,
    pp_unstack      => 1,
    pp_lineseq      => 1,
    pp_stub         => 1,
);


# The `compile' subroutine is the meat of any compiler backend; see
# the documentation for B.pm for details.
sub compile
{
    my (@args)  = @_;

    _parse_args(@args);

    return sub { print do_compile() }
}


# This subroutine is called by either the compiler backend mechanism
# (via -MO=Fathom) or via the OO interface (via fathom()).  If no
# parameters were passed in, this is a call from the compiler backend,
# and we fathom all of the code in main::.  If parameters _are_ passed
# in, then they're a list of references to subroutines to fathom.
sub do_compile
{
    my (@subrefs)   = @_;
    my $preamble    = "";

    %Taken = %Name = @Skip_sub = @Subs_queue = ();
    $Tok = $Expr = $State = $Sub = 0;

    if (@subrefs) {
        foreach (@subrefs) {
            return "$_ is not a subroutine ref" if ref ne 'CODE';
            push @Subs_queue, B::svref_2object($_)->ROOT;
        }
    } else {
        B::walksymtable(\%::, 'tally_symrefs', sub { 1 });
        B::walksymtable(\%::, 'queue_subs',    sub { 0 });

        push @Subs_queue, B::main_root();

        $Sub++;     # The body of the program counts as 1 subroutine.

        if ($Verbose) {
            foreach (sort keys %Taken) {
                $preamble .= "Skipping imported sub `$Name{$_}'\n"
                    if $Taken{$_} > 1;
            }
        }
    }

    foreach my $op (@Subs_queue) {
        # Call the method `tally_op' on each OP in each of the
        # optrees we're looping over:
        B::walkoptree($op, 'tally_op');
    }

    return $preamble . perline() . score_code();
}


sub score
{
    my ($tokens, $exprs, $statements, $subs) = @_;

    my $tok_expr   = $exprs      ? $tokens     / $exprs      : 0;
    my $expr_state = $statements ? $exprs      / $statements : 0;
    my $state_sub  = $subs       ? $statements / $subs       : 0;

    return ($tok_expr * .55) + ($expr_state * .28) + ($state_sub * .08);
}


sub score_code
{
    my $opinion;
    my $output  = "";

    if ($Tok   == 0) { return "No tokens; score is meaningless.\n" }
    if ($Expr  == 0) { return "No expressions; score is meaningless.\n" }
    if ($State == 0) { return "No statements; score is meaningless.\n" }
    if ($Sub   == 0) { return "No subroutines; score is meaningless.\n" }

    my $score = score($Tok, $Expr, $State, $Sub);

    if    ($score < 1) { $opinion = "trivial" }
    elsif ($score < 2) { $opinion = "easy" }
    elsif ($score < 3) { $opinion = "very readable" }
    elsif ($score < 4) { $opinion = "readable" }
    elsif ($score < 5) { $opinion = "easier than the norm" }
    elsif ($score < 6) { $opinion = "mature" }
    elsif ($score < 7) { $opinion = "complex" }
    elsif ($score < 8) { $opinion = "very difficult" }
    else               { $opinion = "obfuscated" }

    $output .= sprintf "%5d token%s\n",      $Tok,   ($Tok   == 1 ? "" : "s");
    $output .= sprintf "%5d expression%s\n", $Expr,  ($Expr  == 1 ? "" : "s");
    $output .= sprintf "%5d statement%s\n",  $State, ($State == 1 ? "" : "s");
    $output .= sprintf "%5d subroutine%s\n", $Sub,   ($Sub   == 1 ? "" : "s");

    $output .= sprintf "readability is %.2f (%s)\n", $score, $opinion;

    return $output;
}


# This method is called on each OP in the tree we're examining; see
# do_compile() above.  It examines the OP, and then increments the
# count of tokens, expressions, statements, and subroutines as
# appropriate.

my $linenum;
my (%TokPerLine, %ExprPerLine, %StatePerLine, %SubPerLine);

sub perline {
    if ($Verbose > 1 and defined $linenum) {
        my $output  = sprintf
            "%4d  %2d tokens %2d expressions %2d statements %2d subs %s\n",
            $linenum, $TokPerLine{$linenum}, $ExprPerLine{$linenum},
            $StatePerLine{$linenum}, $SubPerLine{$linenum},
            score($TokPerLine{$linenum}, $ExprPerLine{$linenum},
                $StatePerLine{$linenum}, $SubPerLine{$linenum})
        ;

        undef $linenum;

        return $output;
    }

    return "";
}


###
### The next three subs are all in package B::OBJECT; this is so
### that all OP's will inherit the subs as methods.
###


sub B::OBJECT::tally_op
{
    my ($self)  = @_;
    my $ppaddr  = $self->can('ppaddr') ? $self->ppaddr : undef;
    my $output  = "";

    # Normalize EMBED and non-EMBED ppaddr's:
    $ppaddr =~ s/^Perl_// or                                # Historic
    $ppaddr =~ s/^PL_ppaddr\[OP_(\w+)\]/'pp_' . lc $1/e;    # 5.6.0+

    if ($self->can('line')) {
       $output  = perline();
       $linenum = $self->line;
    }

    $output .= sprintf("%3d %-15s %s\n", $linenum, $ppaddr, ref($self))
        if $Verbose > 1;

    my ($TokOld, $ExprOld, $StateOld, $SubOld)  = ($Tok, $Expr, $State, $Sub);

    if      ($Boring{$ppaddr}) {
        # Do nothing; these OPs don't count
    } elsif ($ppaddr eq 'pp_nextstate' or $ppaddr eq 'pp_dbstate') {
        $Tok += 1;             $State += 1;
    } elsif ($ppaddr eq 'pp_leavesub') {    # sub name { <xxx> }
        $Tok += 4; $Expr += 1; $State += 1; $Sub += 1;
    } elsif ($ppaddr =~ /^pp_leave/) {
        # pp_leave* is already accounted for in its matching pp_enter*
    } elsif ($ppaddr eq 'pp_entertry') {    # eval { <xxx> }
        $Tok += 3; $Expr += 1;
    } elsif ($ppaddr eq 'pp_anoncode') {    # sub { <xxx> }
        $Tok += 3; $Expr += 1;
    } elsif ($ppaddr eq 'pp_scope') {       # do { <xxx> }
        $Tok += 3; $Expr += 1;
    } elsif ($ppaddr eq 'pp_entersub') {    # foo()
        $Tok += 3; $Expr += 1;
    } elsif ($self->isa('B::LOOP')) {       # for (<xxx>) { <yyy> }
        $Tok += 5; $Expr += 2;
    } elsif ($self->isa('B::LISTOP')) {     # OP(<xxx>)
        $Tok += 3; $Expr += 1;
    } elsif ($self->isa('B::BINOP')) {      # <xxx> OP <yyy>
        $Tok += 1; $Expr += 1;
    } elsif ($self->isa('B::LOGOP')) {      # <xxx> OP <yyy>
        $Tok += 1; $Expr += 1;
    } elsif ($self->isa('B::CONDOP')) {     # while (<xxx>) { <yyy> }
        $Tok += 5; $Expr += 2;
    } elsif ($self->isa('B::UNOP')) {       # OP <xxx>
        $Tok += 1; $Expr += 1;
    } else {                                # OP
        $Tok += 1;
    }

    if (defined $linenum) {
        $TokPerLine{$linenum}   += $Tok   - $TokOld;
        $ExprPerLine{$linenum}  += $Expr  - $ExprOld;
        $StatePerLine{$linenum} += $State - $StateOld;
        $SubPerLine{$linenum}   += $Sub   - $SubOld;
    }

    return $output;
}


# Keep track of the sub associated with each symbol.  If we find multiple
# symbol table entries pointing to one sub, then we'll guess (in
# do_compile()) that the sub is imported, and we'll ignore it.  Thanks
# to Mark-Jason Dominus for suggesting this strategy.
sub B::OBJECT::tally_symrefs
{
    my ($symbol)    = @_;
    my $name        = full_subname($symbol);

    # We're creating a `symbolic reference' in this block
    # (see perlref(1)), which is why we need `no strict':
    if ($name) {
        no strict;
        my $coderef = \&{"$name"};

        $Taken{$coderef}++;
        $Name{$coderef} = $name;
    }
}


# Create an array of OP's for introspection.  These are the `root' OP's
# of each sub that we're going to examine.
sub B::OBJECT::queue_subs
{
    my ($symbol)    = @_;
    my $name        = full_subname($symbol);

    # We're creating a `symbolic reference' in this block
    # (see perlref(1)), which is why we need `no strict':
    if ($name) {
        no strict;
        my $coderef = \&{"$name"};

        push @Subs_queue, $symbol->CV->ROOT unless $Taken{$coderef} > 1;
    }
}


# Given a symbol table entry $symbol, return the fully qualified subroutine
# name of the associated subroutine; if there is none, return undef.
sub full_subname
{
    my ($symbol)    = @_;

    # Build the full subname from the stashname and the symbolname:
    if ($symbol->CV->isa('B::CV')) {
        return $symbol->STASH->NAME . "::" . $symbol->NAME;
    } else {
        return undef;
    }
}


sub _parse_args
{
    my (@args)  = @_;

    foreach (@args) {
        if (/-v(.*)/) { $Verbose = length($1) ? $1 : 1 }
        else          { die "Unknown argument:  `$_'" }
    }

    return;
}


###
### OO interface (thanks to Stephen McCamant for the idea, and
### Doug MacEachern for the encouragement):
###
### Please note that, for now, one can only successfully have one
### B::Fathom object at a time, as compilation arguments are globals.
###

sub new
{
    my ($class, @args)  = @_;
    my $self            = bless {}, $class;

    _parse_args(@args);

    return $self;
}


sub fathom
{
    my ($self, @subrefs)    = @_;

    return do_compile(@subrefs);
}


1;


