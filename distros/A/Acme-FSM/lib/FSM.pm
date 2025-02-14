# Original Author:      Dale M. Amon
# $Id: FSM.pm 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;

package Acme::FSM;
use version 0.77; our $VERSION = version->declare( v2.3.6 );

use Carp qw| croak |;

# TODO:202212202012:whynot: L<|/Linter>

=head1 NAME

Acme::FSM - pseudo Finite State Machine.

=cut

=head1 SYNOPSIS

    my $bb = Acme::FSM->connect( { %options }, { %fst } );
    $bb->process;
    exit 0;

=cut

=head1 DESCRIPTION

B<(disclaimer)>
B<Acme::FSM> is currently in proof-of-concept state.
There's a plan to accompany it with B<Acme::FSM::Simple> with all diagnostics
avoided and run time checks in place.
And then with B<Acme::FSM::Tiny> with run time checks stripped.
Also, see L<B<BUGS AND CAVEATS> later in this POD|/BUGS AND CAVEATS>.

=head2 Concerning Inheritance

Through out code only methods are used to access internal state.
Supposedly, that will enable scaling some day later.
The only exception is L<B<connect()>|/connect()> for obvious reasons.

Through out code neither internal state nor FST records are cached ever.
The only one seamingly inconsistent fragment is inside main loop when next
I<$state> is already found but not yet entered.
I<$action> is processed when the next I<$state> is set
(though, in some sense, not yet entered).
(If it doesn't make sense it's fine, refer to
L<B<process()> method|/process()> description later in this POD.)

This notice seems to be useles.
Instead, it might come handy someday.

=cut

=head2 Terminology

There're some weird loaded words in this POD,
most probably, poorly choosen
(but those are going to stay anyway).
So here comes disambiguation list.

=over

=item I<$action>

Special flag associated with next I<{state}> in a I<[turn]>
(covered in details in L<B<process()>|/process()> method description).
B<(note)> It may be applied to a I<[turn]> of I<{fst}> or I<{state}>.

=item blackboard

Shamelesly stolen from B<DMA::FSM>.
Originally, it meant some opaque HASH passed around in B<DMA::FSM::FSM()>
where
user-code could store it's own ideas and such.
Now it's an object blessed into B<Acme::FSM>
(for user-code still, I<{fsm}> has nothing to do with it).

=item entry

Layout of state records (see below) isn't particularly complicated.
However it's far from being uniform.
I<entry> is a placeholder name for any component of (unspecified) state record
when any semantics is irrelevant.
See also I<[turn]> and B<switch()> below.

=item Finite State Machine

B<Acme::FSM>.

=item Finite State Table

=item I<{fst}>

Collection of state records.

=item FSM

Acronym for I<Finite State Machine>.
See above.

=item FST

Acronym for I<Finite State Table>.
See above.

=item internal state

=item I<{fsm}>

Some open-ended set of parameters dictating FSM's behaviour.

=item item

=item I<$item>

Something that makes sense for user-code.
B<Acme::FSM> treats it as scalar with no internals
(mostly;
one exception is covered in L<B<diag()> method|/diag()> description).

=item I<$namespace>

B<A::F> uses elaborate schema to reach various callbacks
(three of them, at the time of writing).
This optional parameter is in use by this schema.
L<B<query()> method|/query()> has more.

=item I<$rule>

A scalar identifing a I<[turn]>.
One of opaque scalars returned by B<switch()> callback
(the other is processed (modified or not) I<$item>).
L<B<process()> method|/process()> description has more.

=item B<source()>

Special piece of user-code
(it's required at construction (L<B<connect()> method|/connect()>),
L<B<query_source()> method|/query_source()> describes how FSM reaches it).
Whatever it returns (in explicit scalar context) becomes I<$item>.

=item I<$state>

A scalar identifing a I<{state}> (see below) or parameter of I<{fsm}> (see
above).

=item state flow

Just like control flow but for I<$state>s.

=item state record

=item I<{state}>

One record in I<{fst}>.
The record consists of entries (see above).
L<B<process()>|/process()> method description has more.
Should be noted, in most cases "I<{state}>" should be read as
"I<$state> I<{state}>" instead,
but that starts to smell bufallo.

=item B<switch()>

A mandatory callback associated with every I<{state}>.
L<B<process()> method|/process()> and
L<B<query_switch()> method|/query_switch()>
descriptions have more.

=item I<$turn>

No such thing.
It's I<$rule> instead (see above).

=item I<[turn]>

Specially crafted entry in I<{state}>
(covered in details in L<B<process()> method|/process()> description).
Such entry describes what next I<$state> should be picked in state flow
and what to do with I<$item>.

=item turn map

This idiom is used in place of "C<turns> I<$rule> of I<[turn]>".

=back

=cut

=head1 B<connect()>

    $bb1 = Acme::FSM->connect( { %options1 }, %fst1 );
    $bb2 = Acme::FSM->connect( { %options2 }, { %fst2 } );
    $bb3 = $bb2->connect( { %options3 } );

Creates a blackboard object.
Blackboard isa HASH, it's free to use except special C<_> key;
that key is for I<{fsm}> exclusively.
First parameter isa I<%$options>, it's required
(pass empty HASH if nothing to say).
Defined keys are:

=over

=item I<diag_level>

(positive integer)
Sets a diagnostic threshold.
It's meaning is covered in L<B<diag()> method|/diag()> documentation.
If C<undef> then set to C<1> (C<0> is B<defined>).

=item I<dumper>

(scalar or C<CODE>)
B<A::F> operates on arbitrary items and there's a diagnostic service that
sometimes insists on somehow showing those arbitrary items.
It's up to user's code to process that arbitrary data and yield some scalar
represantation.
Refer to L<B<query_dumper()> method|/query_dumper()> documentation for
details.
Optional.
Simple stringifier is provided by L<B<query_dumper()> method|/query_dumper()>
itself.

=item I<namespace>

(scalar or object(!) B<ref>)
Sets a context for various parts of I<{fsm}> and services would be resolved.
No defaults.
Refer to L<B<query()> method|/query()> documentation for details.

=item I<source>

(scalar or C<CODE>)
Sets a source of items to process to be queried.
Required.
Refer to L<B<query_source()> method|/query_source()> documentation for
details.

=back

Second is FST (Finite State Table).
It's required for class construction and ignored (if any) for object
construction.
Difference between list and HASH is the former is copied into HASH internally;
the latter HASH is just saved as reference.
The FST is just borrowed from source object during object construction.
Thus, in the synopsis, I<$bb3> and I<$bb2> use references to HASH
I<%$fst2>.
An idea behind this is to minimize memory footprint.
OTOH, maninpulations with one HASH are effectevely manipulations with FST of
any other copy-object that borrowed that FST.

IOW, anything behind FST HASH of class construction or options HASH of object
construction isa trailer and B<carp>ed.
Obviously, there's no trailer in class construction with list FST.

=cut

my @options = qw| diag_level namespace source dumper |;
sub connect     {
    my( $self, $opts ) = ( shift @_, shift @_ );
    ref $opts eq q|HASH|                                      or croak sprintf
      q|[connect]: {options} HASH is required, got (%s) instead|, ref $opts;
    my( $trailer, $leader );
    if( ref $self eq '' )           {
        $trailer = ref $_[0] eq q|HASH|;
        $self = bless { _ => { fst => $trailer ? shift @_ : { @_ }}}, $self;
        $leader = q|clean init with| }
    else                            {
        $trailer = @_;
        $self = bless { _ => { %{$self->{_}} }}, ref $self;
        $leader = q|stealing|        }
    $self->{_}{$_} = delete $opts->{$_} // $self->{_}{$_}    foreach @options;
    $self->{_}{diag_level} //= 1;
    $self->diag( 3, q|%s (%i) items in FST|,
      $leader, scalar keys %{$self->{_}{fst}} );

    $self->carp( qq|($_): unknown option, ignored| )      foreach keys %$opts;
    $self->carp( q|(source): unset| )       unless defined $self->{_}{source};
    $trailer = ref $_[0] eq q|HASH| ? keys %{$_[0]} : @_          if $trailer;
    $self->carp( qq|ignoring ($trailer) FST items in trailer| )   if $trailer;
    $self->carp( q|FST has no {START} state| )                          unless
      exists $self->{_}{fst}{START};
    $self->carp( q|FST has no {STOP} state| )                           unless
      exists $self->{_}{fst}{STOP};
    @{$self->{_}}{qw| state action |} = qw| START VOID |;
    return $self }

=head1 B<process()>

    $bb = Acme::FSM->connect( { }, \%fst );
    $rc = $bb->process;

This is heart, brains, liver, and so on of B<Acme::FSM>.
B<process()> is what does actual state flow.
That state flow is steered by records in I<%fst>.
Each record consists of:

=over

=item B<switch()> callback

This is some user supplied code that
always consumes whatever B<source()> callback returns (at some point in past),
(optionally) regurgitates said input,
and decides what I<[turn]> to go next.
Except when in special I<{state}> (see below) it's supplied with one argument:
I<$item>.
In special states I<$item> is missing.
B<switch()> returns two controls:  I<$rule> and processed I<$item>.
What to do with returned I<$item> is determined by I<$action> (see below).

=item various I<[turn]>s

Each I<[turn]> spec is an ARRAY with two elements (trailing elements are
ignored).
First element is I<$state> to change to.
Second is I<$action> that sets what to do with I<$item> upon changing to named
I<$state>.
Here are known I<[turn]>s in order of logical treating decreasing.

=over

=item C<eturn>

That I<[turn]> will be choosen by FSM itself when I<$item> at hands is
C<undef>
(as returned by B<source()>).
I<switch()> isn't invoked -- I<$item> is void, there's nothing to call
I<switch()> with.
However, I<$action> may change I<$item>.

=item C<uturn>

That I<[turn]> will be choosen by FSM if I<$rule> is C<undef>
(as returned by B<switch()>).
Idea behind this is to give an FST an option to bailout.
In original B<DMA::FSM> that's not possible (except B<croak>ing, you know).
Also, see L<B<BUGS AND CAVEATS>|/Perl FALSE, undef, and uturn>.

=item C<tturn> and/or C<fturn>

If any (hence 'or') is present then I<$rule> returned by B<switch()> is
treated as Perl boolean, except C<undef> it's handled by C<uturn>.
That's how it is in original B<DMA::FSM>.
If B<switch()> always returns TRUE (or FALSE) then C<fturn> (or C<tturn>) can
be missing.
Also, see L<B<BUGS AND CAVEATS>|/tturn, fturn, and switch()>.

=item C<turns>

If neither C<tturn> nor C<fturn> is present then whatever I<$rule> would be
returned by B<switch()> is treated as string.
That string is supposed to be a key in I<%$turns>.
I<$rule> returned is forced to be string (so if you dare to return objects,
such objects should have C<""> overloaded).
Also, see L<B<BUGS AND CAEATS>|/Default For Turn Map>.

=back

I<$state> is treated as a key in FST hash, except when that's a special state.
Special states (in alphabetical order):

=over

=item C<BREAK>

Basically, it's just like C<STOP> I<$state>.
All comments there (see below) apply.
It's added to enable break out from loop, do something, then get back in loop.
I<$state> is changed to C<CONTINUE> just before returning to caller
(I<switch()> is called in C<BREAK> state).
The choice where to implicitly change state to C<CONTINUE> has been completely
arbitrary;
probably wrong.

=item C<CONTINUE>

Just like C<START> state (see below, all comments apply).
While C<BREAK> is turned to C<CONTINUE> implicitly no other handling is made.

=item C<START>

It's I<$state> set by B<connect()>.
I<$action> (it's also set by B<connect()>) is ignored
(if I<$action> is C<undef> then silently replaces with empty string),
B<switch()> is invoked with no arguments
(there's not anything to process yet).
Whatever I<$item> could be returned is ignored.
I<$rule> is followed.
Thus C<eturn> can't be followed.
See also L<B<BUGS AND CAVEATS>|/Special handling of START and CONTINUE>.

=item C<STOP>

It's last state in the state flow.
I<$action> is retained
(that's what B<process()> will return)
(however, because it's processed before C<STOP> state is acknowledged it must
not be C<undef>)
but otherwise ignored.
B<switch()> is invoked with no arguments
(B<switch()> of previous I<{state}> should have took care).
Whatever I<$item> could be returned is ignored.
Whatever I<$rule> could be returned is reported (at I<(basic trace)> level)
but otherwise ignored.
Then I<$action> is returned and state flow terminates.

=back

Supported I<$action>s (in alphabetical order):

=over

=item C<NEXT>

Drop whatever I<$item> at hands.
Request another.

If FST has such record:

    somestate => { eturn => [ somestate => 'NEXT' ] }

then FSM will stay in C<somestate> as long as I<source()> callback returns
C<undef>.
Thus consuming all resources available.
No options provided to limit that consumption.

=item C<SAME>

Retains I<$item> uncoditionally.
That is, even if I<$item> isn't B<defined> it's kept anyway.

B<Beware>, if FST has such record:

    somestate => { eturn => [ somestate => 'SAME' ] }

then FSM will cycle here forever.
That is, since I<source()> isn't queried for other I<$item>
(what's the purpose of this action is anyway)
there's no way to get out.

=item C<TSTL>

Check if I<$item> is B<defined>, then go as with C<SAME> or C<NEXT> otherwise.
That actually makes sense.

I<(note)> This action name is legacy of B<DMA::Misc::FSM>;
Possibly, that's C<TeST> something;
Someone can just speculate what C<L> could mean.

=back

=back

=cut

sub process             {
    my $self = shift @_;
    my( $branch, $turn );

# XXX:202201072033:whynot: C<START> and C<CONTINUE> being handled specially is a side-effect of this extra sequence.  Should be moved in the main loop with special handling.  This results in there-be-dragons uncertainty.
    $self->diag( 3, q|{%s}(%s): entering|, $self->state, $self->action );
    $branch = $self->query_switch;
    $turn = $self->turn( $self->state, $branch );
    $self->diag( 5, q|{%s}(%s): switch returned: (%s)|, @$turn, $branch );
    $self->state( $turn->[0] );
    $self->action( $turn->[1] );

    my( $item, $dump ) = $self->query_source;
    $self->diag( 3, q|{%s}(%s): %s: going with|, @$turn, $dump );

# No one gets out of this loop without the state tables permission!
    while ( 1 )                                                     {
# We should never see an undefined state unless we've made a mistake.
# NOTE:202201072131:whynot: As a matter of fact, we don't now.
        $self->verify( $self->fst( $self->state ),
          $self->state, '', q|record|, q|HASH| );

        ( $branch, $item ) = $self->query_switch( $item );
        $self->diag( 5, q|{%s}(%s): switch returned: (%s)|, @$turn, $branch );
        $dump = $self->query_dumper( $item );
        $turn = $self->turn( $self->state, $branch );
        $self->diag( 3, q|{%s}(%s): %s: turning with|,
          $turn->[0], $branch, $dump );
        $self->state( $turn->[0] );
        $self->action( $turn->[1] );

        $self->diag( 5, q|{%s}(%s): going for|, @$turn );
        $turn->[0] eq q|STOP|                                        and last; 
        $turn->[0] eq q|BREAK|                                       and last;
        $turn->[1] eq q|SAME|                                        and redo;
        $turn->[1] eq q|NEXT|                                        and next;
        $turn->[1] eq q|TSTL| && defined $item                       and redo;
        $turn->[1] eq q|TSTL|                                        and next;
        croak sprintf q|[process]: {%s}(%s): unknown action|, @$turn }
    continue                                                        {
        ( $item, $dump ) = $self->query_source;
        $self->diag( 5, q|{%s}(%s): %s: going with|, @$turn, $dump ) }

    $self->diag( 3, q|{%s}(%s): leaving|, @$turn );
# XXX:20121231215139:whynot: Nothing to B<verify()>, leaving anyway.
    $branch = $self->query_switch;
    $self->diag( 5, q|{%s}(%s): switch returned: (%s)|, @$turn, $branch );
    $self->diag( 3, q|{%s}(%s): changing state: (CONTINUE)|, @$turn )
    ->state( q|CONTINUE| )                          if $turn->[0] eq q|BREAK|;
    return $self->action }


=head1 METHODS AND STUFF

Access and utility methods to deal with various moves while doing The State
Flow.
These aren't forbidden for use from outside,
while being quite internal nevertheles.

=over

=cut

=item B<verify()>

    $rc = $self->query_rc( @args );
    $rc = $self->verify( $rc, $state, $tag, $subject, $test );

Here comes rationale.
Writing (or should I say "composing"?) correct {fst} B<A::F> style is hard
(I know what I'm talking about, I've made a dozen already).
The purpose of B<verify()> is to check if the I<{fst}> at hands isn't fubar.
Nothing more, nothing less.
B<query_rc()> is a placeholder for one of B<query_.*()> methods,
I<$test> will be matched against C<ref $rc>.
Other arguments are to fill diagnostic output (if any).
I<$state> hints from what I<{state}> I<$rc> has been queried.
I<$subject> and I<$tag> are short descriptive name and actual value of I<$rc>.
Yup, dealing with B<verify()> might be fubar too.

I<$rc> is passed through (or not).
This B<croak>s if I<$rc> isn't B<defined> or C<ref $rc> doesn't match
I<$test>.

=cut

# TODO:202202150137:whynot: Replace C<return udnef> with B<croak()>, plz.
sub verify       {
    my $self = shift @_;
# XXX:202202092101:whynot: Nope, needs I<$state> because sometimes I<{state}> isn't entered yet.
    my( $entry, $state, $what, $manifest, $test ) = @_;
    defined $entry    or croak sprintf q|[verify]: {%s}(%s): %s !isa defined|,
      $state, $what, $manifest;
    ref $entry eq $test                                       or croak sprintf
      q|[verify]: {%s}(%s): %s isa (%s), should be (%s)|,
      $state, $what, $manifest, ref $entry, $test;
    return $entry }

=item B<state()>

    $bb->state eq 'something' and die;
    $state = $bb->state( $new_state );

Queries and sets state of B<A::F> instance.
Modes:

=over

=item no argument

Returns state of instance.
Note, Perl FALSE B<isa> parameter.

=item lone scalar

Sets I<$state> of instance.
Returns previous I<$state>.

=back

=cut

sub state                        {
    my $self = shift @_;
    unless( @_ )                {
        return $self->{_}{state} }
    elsif( 1 == @_ )            {
        my $backup = $self->state;
        $self->diag( 5, q|changing state: (%s) (%s)|, $backup, $_[0] );
        $self->{_}{state} = shift @_;
        return $backup           }
    else                        {
        $self->carp( sprintf q|too many args (%i)|, scalar @_ );
        return undef             }}

=item B<fst()>

    %state = %{ $bb->fst( $state ) };
    %state = %{ $bb->fst( $state => \%new_state ) };
    $value = $bb->fst( $state => $entry );
    $value = $bb->fst( $state => $entry => $new_value );

Queries and sets records and entries in I<{fst}>.
That is, not only entire I<{state}>s
but components of I<{state}> are reachable too.
Modes:

=over

=item query specific I<{state}> of specific I<$state>

Executed if one scalar is passed in.
Returns a I<{state}> reference with whatever entries are set.
Silently returns C<undef> if I<$state> is missing from I<{fst}>.

=item set I<{state}> of specific I<$state>

Executed if one scalar and HASH are passed in.
Sets a I<{state}> with key/value pairs from HASH,
creating one if necessary.
Created record isa copy of HASH, not a reference
(not a true deep copy though)
(empty I<\%new_state> is fine too)
(copying isn't by design, it's implementation's quirk).
Returns record as it was before setting
(C<undef> is returned if there were no such I<$state> before).

=item query specific I<$entry> of specific I<$state>

Executed if two scalars are passed in.
Returns an entry from named state record.

=item set specific I<$entry> of specific I<$state>

Executed if two scalars and anything else are passed in
(no implicit intelligence about third parameter).
Sets an entry in named state record,
creating one (entry) if necessary.
State record must exist beforehand.
Entry isa exact value of least argument, not a copy.
Returns whatever value I<$entry> just had
(C<undef> is returned if there were none such I<$entry> before).

=back

None checks are made, except record must exist (for two latter uses).

=cut

sub fst                                            {
    my $self = shift @_;
    unless( @_ )                                  {
        $self->carp( q|no args| );
        return undef                               }
    elsif( 2 == @_ && ref $_[1] eq q|HASH| )      {
        my $backup = $self->fst( $_[0] );
        $self->diag( 3, q|%s {%s} record|,
        ( $backup ? q|updating| : q|creating| ), $_[0] );
# XXX:202202150056:whynot: Copy is a side-effect instead.
        $self->{_}{fst}{shift @_} = {%{ pop @_ }};
        return $backup                             }
    elsif( !exists $self->{_}{fst}{$_[0]} )       {
        $self->carp( qq|($_[0]): no such {fst} record| );
        return undef                               }
    elsif( 1 == @_ )                              {
        return $self->{_}{fst}{shift @_}           }
    elsif( 2 == @_ )                              {
        return $self->{_}{fst}{shift @_}{shift @_} }
    elsif( 3 == @_ )                              {
        my $backup = $self->fst( $_[0] => $_[1] );
        $self->diag( 3, q|%s {%s}{%s} entry|,
        ( $backup ? q|updating| : q|creating| ), @_[0,1] );
        $self->{_}{fst}{shift @_}{shift @_} = pop @_;
        return $backup                             }
    else                                          {
        $self->carp( sprintf q|too many args (%i)|, scalar @_ );
        return undef                               }}

=item B<turn()>

    $bb->turn( $state ) eq '' or die;
    $bb->turn( $state => 'uturn' )->[1] eq 'NEXT' or die;

Queries I<[turn]>s of arbitrary I<{state}>s.
B<turn()> doesn't manipulate entries, use L<B<fst()> method|/fst()> instead
L<if you can|/turn() and fst()>.
Modes:

=over

=item query expected behaviour

This mode is entered if there is lone scalar.
Such scalar is believed to be I<$state>.
Returns something that describes what kind of least special states are
present.
Namely:

=over

=item *

C<undef> is returned if I<$state> isn't present in the I<{fst}>
(also B<carp>s).
Also see below.

=item *

Empty string is returned if there're I<tturn> and/or I<fturn> turns.
I<turns> hash is ignored in that case.

=item *

C<HASH> is returned if there's turn map
(and neither I<tturn> nor I<fturn> is present).
B<(note)> In that case, B<turn()> checks for I<turns> is indeed a HASH,
nothing more
(however B<croaks> if that's not the case);
It may as well be empty;
Design legacy.

=item *

Returns C<HASH> for C<STOP> and C<BREAK> I<$state>s without any further
processing
(For those I<$state>s any I<$rule> is ignored and C<HASH> enables I<switch()>
callbacks to give more informative logs
(while that information is mangled anyway);
Probably bad idea).

=item *

C<undef> is returned if there's nothing to say --
neither I<tturn>, nor I<fturn>, nor turn map --
this record is kind of void.
The record should be studied to find out why.
B<carp>s in that case.

=back

=item query specific I<[turn]>

Two scalars are I<$state> and specially encoded I<$rule>
(refer to L<B<query_switch()> method|/query_switch()> about encoding).
If I<$rule> can't be decoded then B<croak>s.
Returns (after verification) requested I<$rule> as ARRAY.
While straightforward I<[turn]>s (such as C<tturn>, C<fturn>, and such) could
be in fact queried through L<B<fst()> method|/fst()> turn map needs bit more
sophisticated handling;
and that's what B<turn()> does;
in fact asking for C<turns> will result in B<croak>.
I<$action> of C<START> and C<CONTINUE> special states suffer implicit
defaulting to empty string.

=item anything else

No arguments or more then two is an non-fatal error.
Returns C<undef> (with B<carp>).

=back

=cut

# TODO:202202172011:whynot: As soon as supported perl is young enough change it to smartmatch, plz.
my %special_turns = map { $_ => 1 } qw| eturn uturn tturn fturn |;
# TODO:202202162030:whynot: Consider more elaborate (informative) returns.
sub turn {
    my $self = shift @_;
    unless( @_                                       ) {
        $self->carp( q|no args| );         return undef }
    elsif( 1 == @_ && !exists $self->{_}{fst}{$_[0]} ) {
        $self->carp( qq|($_[0]): no such {fst} record| );
                                           return undef }
    elsif( 1 == @_                                   ) {
        my $state = shift @_;
        my $entry = $self->verify(
          $self->{_}{fst}{$state}, $state, '', q|entry|, q|HASH| );
# WORKAROUND:201305070051:whynot: Otherwise there will be spurious B<carp>s about anyway useless turns in those entries.
        $state eq q|STOP| || $state eq q|BREAK|            and return q|HASH|;
        exists $entry->{tturn} || exists $entry->{fturn}        and return '';
        unless( exists $entry->{turns} ) {
# XXX:201305071531:whynot: Should just B<croak> instead, probably.
            $self->carp( qq|{$state}: none supported turn| );
                             return undef }
        $self->verify( $entry->{turns}, $state, q|turns|, q|turn|, q|HASH| ); 
                                         return q|HASH| }
    elsif( 2 == @_                                   ) {
        my( $state, $turn ) = @_;
        my $entry;
        $self->verify( $turn, $state, $turn, q|turn|, '' );
        if( exists $special_turns{$turn} )                                {
                                   $entry = $self->{_}{fst}{$state}{$turn} }
        elsif( !index $turn, q|turn%|    )                                {
                  $entry = $self->{_}{fst}{$state}{turns}{substr $turn, 5} }
        else                                                              {
            croak sprintf q|[turn]: {%s}(%s): unknown turn|, $state, $turn }
        $self->verify( $entry, $state, $turn, q|turn|, q|ARRAY| );
        $self->verify( $entry->[0], $state, $turn, q|state|, '' );
# XXX:20121230140241:whynot: {START}{turn}{action} is ignored anyway.
# XXX:201305072006:whynot: {CONTINUE}{turn}{action} is ignored too.
        $entry->[1] //= ''     if $state eq q|START| || $state eq q|CONTINUE|;
        $self->verify( $entry->[1], $state, $turn, q|action|, '' );
                                          return $entry }
    else                                               {
        $self->carp( sprintf q|too many args (%i)|, scalar @_ );
                                           return undef }
}

=item B<action()>

    $bb->action eq $action and die;
    $action = $bb->action( $new_action );

Queries and sets I<$action> of B<A::F> instance.
Modes:

=over

=item query I<$action>

No arguments -- returns current I<$action> of the instance.
Note, Perl FALSE B<isa> parameter.

=item set I<$action>

One scalar -- sets action of the instance.
Returns previous I<$action>.

=back

=cut

sub action                        {
    my $self = shift @_;
    unless( @_ )                 {
        return $self->{_}{action} }
    elsif( 1 == @_ )             {
        my $backup = $self->action;
        $self->diag( 5, q|changing action: (%s) (%s)|, $backup, $_[0] );
        $self->{_}{action} = shift @_;
        return $backup            }
    else                         {
        $self->carp( sprintf q|too many args (%i)|, scalar @_ );
        return undef              }}

=item B<query()>

    ( $alpha, $bravo ) = $self->query( $what, $name, @items );

Internal method, then it becomes complicated.
Resolves I<$what> (some callback, there multiple of them) against
I<$namespace>, if necessary.
Then invokes resolved code appropriately passing I<@items> in, if any;
Product of the callback over I<@items> is returned back to the caller.
I<$name> is used for disgnostics only.
Trust me, it all makes perfect sense.

I<$what> must be either CODE or scalar, or else.

Strategy is like this

=over

=item I<$what> isa CODE

I<$what> is invoked with I<$self> and I<@items> as arguments.
Important, in this case I<$self> is passed as first argument,
OO isn't involved like at all.

=item I<$namespace> is empty string

Trade I<$namespace> for I<$self> (see below) and continue.

=item I<$namespace> is scalar

Treat I<$what> as a name of function in I<$namespace> namespace.

=item I<$namespace> is object reference

Treat I<$name> as a name of method of object referred by I<$namespace>.

=back

It really works.

=cut

sub query                      {
    my( $self, $topic, $manifest ) = ( shift @_, shift @_, shift @_ );
    my $caller = ( split m{::}, ( caller 1 )[3] )[-1];
    defined $topic                  or croak sprintf q|[%s]: %s !isa defined|,
      $caller, $manifest, $self->state;
    $self->diag( 5, q|[%s]: %s isa (%s)|, $caller, $manifest, ref $topic );
    ref $topic eq q|CODE|                    and return $topic->( $self, @_ );
    ref $topic eq ''                                          or croak sprintf
     q|[%s]: %s isa (%s): no way to resolve this|,
     $caller, $manifest, ref $topic;
    defined $self->{_}{namespace}                                     or croak
     qq|[$caller]: {namespace} !isa defined|;
    my $anchor = $self->{_}{namespace};
    my $backup = $topic;
    if( ref $anchor eq '' && $anchor eq '' ) {
        $self->diag( 5, q|[%s]: defaulting %s to $self|, $caller, $manifest );
        $anchor = $self                       }
    $self->diag( 5, q|[%s]: {namespace} isa (%s)|, $caller, ref $anchor );
    unless( ref $anchor eq '' )     {
        $self->diag( 5, q|[%s]: going for <%s>->[%s]|,
          $caller, ref $anchor, $topic );
        $topic = $anchor->can( $topic );
        $topic     or croak sprintf q|[%s]: object of <%s> can't [%s] method|,
         $caller, ref $anchor, $backup;
        return $anchor->$topic( @_ ) }
    else                            {
        $self->diag( 5, q|[%s]: going for <%s>::[%s]|,
          $caller, $anchor, $topic );
        $topic = UNIVERSAL::can( $anchor, $topic );
        $topic   or croak sprintf q|[%s]: <%s> package can't [%s] subroutine|,
         $caller, $anchor, $backup;
        return $topic->( $self, @_ ) }}

=item B<query_switch()>

    ( $rule, $item ) = $self->query_switch( $item );

Internal multitool.
That's the point where decisions about turns are made.
B<(note)>
B<query_switch()> converts I<$rule> (as returned by B<switch()>) to specially
encoded scalar;
it's caller's responcibility pick correct I<[turn]> later.
Strategy:

=over

=item no arguments

Special-state mode:
invoke B<switch()> with no arguments;
ignore whatever I<$item> has been possibly returned;
return I<$rule> alone.

=item I<$item> is C<undef>

EOF mode:
ignore B<switch()> completely;
return C<eturn> and C<undef>.

=item I<$item> is not C<undef>

King-size mode: 
invoke B<switch()>, pass I<$item> as single argument.
return I<$rule> and I<$item>
(whatever it became after going through B<switch()>).

=back

I<$rule>, as it was returned by B<switch()>, is encoded like this:

=over

=item I<$rule> is C<undef>

Return C<uturn>.
B<(note)>
Don't verify if C<uturn> I<[turn]> exists.

=item I<$rule> is Perl TRUE and C<tturn> and/or C<fturn> are present

Return C<tturn> 
B<(note)>
Don't verify if C<tturn> I<[turn]> exists.

=item I<$rule> is Perl FALSE and C<tturn> and/or C<fturn> are present

Return C<fturn>
B<(note)>
Don't verify if C<fturn> I<[turn]> exists.

=item neither C<tturn> or C<fturn> are present

Encode I<$rule> like this C<'turn%' . $rule> and return that.
B((note)>
Don't verify if turn map exists.
B<(note)>
Don't verify if C<"turn%$rule"> exists in turn map.

=back

B<switch()> is always invoked in list context even if I<$item> would be
ignored.
If I<$rule> shouldn't be paired with I<$item> it won't be
(it's safe to call B<query_switch()> in scalar context then and
there won't be any trailing C<undef>s).

=cut

sub query_switch                {
    my $self = shift @_;
    my @turn;
# WORKAROUND:20121229000801:whynot: No B<verify()>, B<query()> does its checks by itself.
    @turn = $self->query(
      $self->fst( $self->state, q|switch| ),
      sprintf( q|{%s}{switch}|, $self->state ),
      @_ )                                            if !@_ || defined $_[0];
    my $kind = $self->turn( $self->state );
    $turn[0] =
      @_ && !defined $_[0] ? q|eturn|          :
# TODO:202201071700:whynot: Make C<undef> special only when C<uturn> is present, plz.
      !defined $turn[0]    ? q|uturn|          :
# FIXME:201304230145:whynot: Defaulting to basics here looks as bad as B<croak>ing.
# TODO:202212202039:whynot: L<Default For Turn Map>.
      $kind                ? qq|turn%$turn[0]| :
      $turn[0]             ? q|tturn|          : q|fturn|;
    return @_ ? @turn : $turn[0] }

=item B<query_source()>

    ( $item, $dump ) = $self->query_source;

Seeks B<source()> callback and acquires whatever it returns.
The callback is called in scalar context.
As useful feature, also feeds I<$item> to L<dumper callback|/query_dumper()>.
L<B<query()> method|/query()> has detailed description how B<source()>
callback is acquired.
Returns I<$item> and result of L<I<dumper> callback|/dumper>.

=cut

sub query_source                              {
    my $self = shift @_;
# WORKAROUND:20121229001530:whynot: No B<verify()>, I<{source}> can return anything.
    my $item = $self->query( $self->{_}{source}, q|{source}|, @_ );
    return $item, $self->query_dumper( $item ) }

=item B<query_dumper()>

    $dump = $self->query_dumper( $item );

Seeks I<dumper> callback (L<configured at construction time|/dumper>).
If the callback wasn't configured uses simple hopefully informative and
C<undef> proof substitution.
Whatever the callback returns is checked to be B<defined>
(C<undef> is changed to C<"(unclear)">)
and then returned.

=cut

sub query_dumper                             {
    my $self = shift @_;
    return $self->verify(
      $self->query(
# TODO:202202210258:whynot: This is inefficient, defaulting should happen in B<connect()> instead.
        $self->{_}{dumper} // sub { sprintf q|(%s)|, $_[1] // q|undef| },
        q|{dumper}|,     @_ ) // q|(unclear)|,
# XXX:202202210304:whynot: 'source' looks like remnants of refactoring.  Should investigate it deeper.
      $self->state, qw| source source |, '' ) }

=item B<diag()>

    $bb->diag( 3, 'going to die at %i.', __LINE__ );

Internal.
Provides unified and single-point-of-failure way to output diagnostics.
Intensity is under control of
L<I<diag_level> configuration parameter|/diag_level>.
Each object has it's own,
however it's inherited when objects are copied.

Defined levels are:

=over

=item C<0>

Nothing at all.
Even error reporting is suppressed.

=item C<1>

Default.
Errors of here-be-dragons type.

=item C<2>

Basic diagnostics for callbacks.

=item C<3>

Basic trace.
Construction, starting and leaving runs.

=item C<4>

Extended diagnostics for callbacks.

=item C<5>

Deep trace.
By the way diagnostics of I<switch> entry resolving.

=back

=cut

sub diag        {
    my $self = shift @_;
    $self->{_}{diag_level} >= shift @_                        or return $self;
# TODO:202212222141:whynot: Since something this B<sprintf> might emit warnings.  And maybe it's appropriate.
    printf STDERR sprintf( qq|[%s]: %s\n|,
    ( split m{::}, ( caller 1 )[3])[-1], shift @_ ),
      map $_ // q|(undef)|, @_;
    return $self }

=item B<carp()>

    $bb->carp( 'something wrong...' );

Internal.
B<carp>s consistently if I<{_}{diag_level}> is B<gt> C<0>.

=back

=cut

sub carp        {
    my $self = shift @_;
    $self->{_}{diag_level} >= 1                                     or return;
    unshift @_, sprintf q|[%s]: |, ( split m{::}, ( caller 1 )[3])[-1];
    &Carp::carp  }

=head1 BUGS AND CAVEATS

=over

=item Default For Turn Map

B<(missing feature)>
It's not hard to imagine application of rather limited turn map that should
default on anything else deemed irrelevant.
Right now to achieve logic like this such defaulting ought to be merged into
B<switch()>.
That's insane.

=item Diagnostics

B<(misdesign)>
Mechanics behind diagnostics isa failure.
It's messy, fragile, misguided, and (honestly) premature.
At the moment it's useless.

=item Hash vs HASH vs Acme::FSM Ref Constructors

B<(messy, probably bug)>
L<B<connect()> method description|/connect()> _declares_ that list is copied.
Of course, it's not true deep copy
({fst} might contain CODE, it's not clear how to copy it).
It's possible, one day list trailer variant of initialization may be put to
sleep.
See also L<linter below|/Linter>.

=item Linter

B<(missing feature)>
It might be hard to imagine,
but FST might get out of hands
(ie check F<t/process/quadratic.t>).
Indeed, some kind of (limited!) linter would be much desired.
It's missing.

=item Perl FALSE, C<undef>, and C<uturn>

B<(caveat)>
Back then B<DMA::FSM> treated C<undef> as any other Perl FALSE.
C<uturn> I<$rule> mech has made C<undef> special
(if B<switch()> returns C<undef> and C<uturn> I<{turn}> isn't present then
it's a B<croak>).
Thus, at the moment, C<undef> isn't FALSE (for B<A::F>).
This is counter-intuitive, actually.

=item Returning C<undef> for misuse

B<(bug)>
Why B<A::F> screws with caller,
in case of API violations (by returning C<undef>),
is beyond my understanding now.

=item B<source()> and I<$state>

B<(bug)> (also see L<B<switch()> and I<$item>|/switch() and $item>)
By design and legacy,
there is single point of input -- B<source()>.
IRL, multiple sources are normal.
Implementation wise that leads to B<source()> that on the fly figures out
current I<$state> and then somehow branches (sometimes branches out).
Such B<source()>s look horrible because they are.

=item Special handling of C<START> and C<CONTINUE>

B<(bug)>
In contrary with C<STOP> and C<BREAK> special states,
special treatement of C<START> and C<CONTINUE> is a side effect of
L<B<process()> method|/process()> entry sequence.
That's why routinely enter C<START> or C<CONTINUE> by state flow is of
there-be-dragons type.
Totally should be rewritten.

=item B<switch()> and I<$item>

B<(bug)>
It might be surprising, but, from experience,
the state flow mostly doesn't care about I<$item>.
Mostly, I<{state}> entered with I<$action> C<NEXT> processes input
and just wonders ahead.
Still those pesky I<$item>s *must* be passed around (by design).
Still every B<switch()> *must* return I<$item> too
(even if it's just a placeholder).
Something must be done about it.

=item C<tturn>, C<fturn>, and B<switch()>

B<(misdesign)>
First, by design and legacy B<switch()> must report what turn the control flow
must make
(that's why it *must* return I<$rule>).
OTOH, there's some value in keeping B<switch()>es as simple as possible what
results in I<{state}> with alone C<tturn> I<{turn}> and B<switch()> that
always returns TRUE.
Changes are coming.

=item B<turn()> and B<fst()>

B<(misdesign)>
Encoding (so to speak) in use by B<turn()> (in prediction mode) is plain
stupid.
C<undef> signals two distinct conditions
(granted, both are manifest of broken I<{fst}>).
Empty string doesn't distinguish safe (both C<tturn> and C<fturn> are present)
and risky (C<tturn> or C<fturn> is missing) I<{state}>.
C<HASH> doesn't say if there's anything in turn map.
All that needs loads of workout.

=back

=cut

=head1 DIAGNOSTICS

=over

=item C<[action]: changing action: (%s) (%s)>

B<(deep trace)>, L<B<action()> method|/action()>.
Exposes change of I<$action> from previous (former I<%s>)
to current (latter I<%s>).

=item C<[action]: too many args (%i)>

B<(warning)>, L<B<action()> method|/action()>.
Obvious.
None or one argument is supposed.

=item C<[connect]: (%s): unknow option, ignored>

B<(warning)>, L<B<connect()> method|/connect()>.
Each option that's not known to B<A::F> is ignored and B<carp>ed.
There're no means for child class to force B<A::F> (as a parent class) to
accept something.
Child classes should process their options by itself.

=item C<[connect]: clean init with (%i) items in FST>

B<(basic trace)>, L<B<connect()> method|/connect()>.
During class construction FST has been found.
That FST consists of I<%i> items.
Those items are number of I<$state>s and not I<$state>s plus I<{state}>s.

=item C<[connect]: FST has no {START} state>

B<(warning)>, L<B<connect()> method|/connect()>.
I<START> I<{state}> is required.
It's missing.
This situation will definetely result in devastating failure later.

=item C<[connect]: FST has no {STOP} state>

B<(warning)>, L<B<connect()> method|/connect()>.
I<STOP> I<{state}> is required.
It's missing.
If FST is such that I<STOP> I<$state> can't be reached
(for whatever reasons)
this may be cosmetic.

=item C<[connect]: ignoring (%i) FST items in trailer>

B<(warning)>, L<B<connect()> method|/connect()>.
A trailer has been found and was ignored.
Beware, I<%i> could be misleading.
For HASH in trailer that HASH is considered and key number is reported.
For list in trailer an B<item> number in list is reported, even if it's twice
as many in FST (what isa hash).
Just because.

=item C<[connect]: (source): unset>

B<(warning)>, L<B<connect()> method|/connect()>.
I<$source> option isa unset, it should be.
There's no other way to feed items in.
This situation will definetely result in devastating failure later.

=item C<[connect]: stealing (%i) items in FST>

B<(basic trace)>, L<B<connect()> method|/connect()>.
During object construction FST has been found.
That FST consists of I<%i> items.
Those items are I<{state}>s, not I<$state>s plus I<{state}>s.

=item C<[fst]: creating {%s} record>

B<(basic trace)>, L<B<fst()> method|/fst()>.
New state record has been created, named I<%s>.

=item C<[fst]: creating {%s}{%s} entry>

B<(basic trace)>, L<B<fst()> method|/fst()>.
New entry named I<%s> (the latter) has been created in record named I<%s> (the
former).

=item C<[fst]: no args>

B<(warning)>, L<B<fst()> method|/fst()>.
No arguments, it's an error.
However, instead of promptly dieing, C<undef> is returned
in blind hope this will be devastating enough.

=item C<[fst]: (%s): no such {fst} record>

B<(warning)>, L<B<fst()> method|/fst()>.
Requested entry I<%s> is missing.
State record ought to exist beforehand for any usecase except
L<record creation|/set {state} of specific $state>.

=item C<[fst]: too many args (%i)>

B<(warning)>, L<B<fst()> method|/fst()>.
Too many args have been passed in.
And again, instead of prompt dieing C<undef> is returned.

=item C<[fst]: updating {%s} record>

B<(basic trace)>, L<B<fst()> method|/fst()>.
Named record (I<%s>) has been updated.

=item C<[fst]: updating {%s}{%s} entry>

B<(basic trace)>, L<B<fst()> method|/fst()>.
Named entry (I<%s>, the latter) in record I<%s> (the former) has been updated.

=item C<[process]: {%s}(%s): changing state: (CONTINUE)>

B<(basic trace)>, L<B<process()> method|/process()>.
Implicit change of state from C<BREAK> to C<CONTINUE> is about to happen.

=item C<[process]: {%s}(%s): entering>

B<(basic trace)>, L<B<process()> method|/process()>.
Entering state flow from I<$state> I<%s> (the former) with I<$action> I<%s>
(the latter).

=item C<[process]: {%s}(%s): going for>

B<(deep trace)>, L<B<process()> method|/process()>.
Trying to enter I<$state> I<%s> (the former) with I<$action> I<%s> (the
latter).

=item C<[process]: {%s}(%s): %s: going with>

B<(basic trace)>, L<B<process()> method|/process()>.
While in I<$state> I<%s> (1st) doing I<$action> I<%s> (2nd) the I<$item>
happens to be I<%s> (3rd).
C<undef> will look like this: C<((undef))>.

=item C<[process]: {%s}(%s): %s: turning with>

B<(basic trace)>, L<B<process()> method|/process()>.
B<switch()> (of I<$state> I<%s>, the 1st) has returned I<$rule> I<%s> (2nd)
and I<$item> I<%s>.
Now dealing with this.

=item C<[process]: {%s}(%s): leaving>

B<(basic trace)>, L<B<process()> method|/process()>.
Leaving state flow with I<$state> I<%s> (the former) and I<$action> I<%s> (the
latter).

=item C<[process]: {%s}(%s): switch returned: (%s)>

B<(basic trace)>, L<B<process()> method|/process()>.
B<switch()> (of I<$state> I<%s>, the 1st, with I<$action> I<%s>, the 2nd) has
been invoked and returned something that was interpreted as I<$rule> I<%s>,
the 3rd.

=item C<[process]: {%s}(%s): unknown action>

B<(croak)>, L<B<process()> method|/process()>.
Attempt to enter I<$state> I<%s> (the former) has been made.
However, it has failed because I<$action> I<%s> (the latter) isn't known.

=item C<< [query]: [$caller]: <%s> package can't [%s] subroutine >>

B<(croak)>, L<B<query()> method|/query()>.
I<$namespace> and I<$what> has been resolved as package I<%s> (the former)
and subroutine I<%s> (the latter).
However, the package can't do such subroutine.

=item C<[query]: [query_dumper]: %s !isa defined>

=item C<[query]: [query_source]: %s !isa defined>

=item C<[query]: [query_switch]: %s !isa defined>

B<(croak)>, L<B<query()> method|/query()>.
I<$what> (I<%s> is I<$name>) should have some meaningful value.
It doesn't.

=item C<[query]: [query_dumper]: %s isa (%s): no way to resolve this>

=item C<[query]: [query_source]: %s isa (%s): no way to resolve this>

=item C<[query]: [query_switch]: %s isa (%s): no way to resolve this>

B<(croak)>, L<B<query()> method|/query()>.
C<ref $what> (the former I<%s>) is I<%s> (the latter).
I<$what> is neither CODE nor scalar.

=item C<[query]: [query_dumper]: %s isa (%s)>

=item C<[query]: [query_source]: %s isa (%s)>

=item C<[query]: [query_switch]: %s isa (%s)>

B<(deep trace)>, L<B<query()> method|/query()>.
C<ref $what> (the former I<%s>) is I<%s> (the latter).

=item C<[query]: [query_dumper]: {namespace} !isa defined>

=item C<[query]: [query_source]: {namespace} !isa defined>

=item C<[query]: [query_switch]: {namespace} !isa defined>

B<(croak)>, L<B<query()> method|/query()>.
I<$what> isn't CODE, now to resolve it I<$namespace> is required.
Apparently, it was missing all along.

=item C<[query]: [query_dumper]: {namespace} isa (%s)>

=item C<[query]: [query_source]: {namespace} isa (%s)>

=item C<[query]: [query_switch]: {namespace} isa (%s)>

B<(deep trace)>, L<B<query()> method|/query()>.
C<ref $namespace> is I<%s>.

=item C<[query]: [query_dumper]: defaulting %s to $self>

=item C<[query]: [query_source]: defaulting %s to $self>

=item C<[query]: [query_switch]: defaulting %s to $self>

B<(deep trace)>, L<B<query()> method|/query()>.
I<$namespace> is an empty string.
The blackboard object will be used to resolve the callback.

=item C<< [query]: [query_dumper]: going for <%s>->[%s] >>

=item C<< [query]: [query_source]: going for <%s>->[%s] >>

=item C<< [query]: [query_switch]: going for <%s>->[%s] >>

B<(deep trace)>, L<B<query()> method|/query()>.
Attempting to call I<%s> (the latter) method on object of I<%s> (the former)
class.

=item C<< [query]: [query_dumper]: going for <%s>::[%s] >>

=item C<< [query]: [query_source]: going for <%s>::[%s] >>

=item C<< [query]: [query_switch]: going for <%s>::[%s] >>

B<(deep trace)>, L<B<query()> method|/query()>.
Attempting to call I<%s> (the latter) subrouting of package I<%s> (the
former).

=item C<< [query]: [query_dumper]: object of <%s> can't [%s] method >>

=item C<< [query]: [query_source]: object of <%s> can't [%s] method >>

=item C<< [query]: [query_switch]: object of <%s> can't [%s] method >>

B<(croak)>, L<B<query()> method|/query()>.
The object of I<%s> (the former) class can't do I<%s> (the latter) method.

=item C<[state]: changing state: (%s) (%s)>

B<(deep trace)>, L<B<state()> method|/state()>.
Exposes change of state from previous (former I<%s>)
to current (latter I<%s>).

=item C<[state]: too many args (%i)>

B<(warning)>, L<B<state()> method|/state()>.
Obvious.
None or one argument is supposed.
B<state()> has returned C<undef> in this case,
most probably will bring havoc in a moment.

=item C<[turn]: (%s): no such {fst} record>

B<(warning)>, L<B<turn()> method|/turn()>.
Peeking for I<[turn]>s of I<%s> I<$state> yeilds nothing, there's no such
state.

=item C<[turn]: {%s}: none supported turn>

B<(warning)>, L<B<turn()> method|/turn()>.
Whatever content of I<%s> entry is FSM doesn't know how to handle it.

=item C<[turn]: {%s}(%s): unknown turn>

B<(croak)>, L<B<turn()> method|/turn()>.
There was request for I<[turn]> I<%s> (the latter) of I<$state> I<%s> (the
former).
While I<{state}> record has been found and is OK,
there is no such I<$rule>.

=item C<[turn]: no args>

B<(warning)>, L<B<turn()> method|/turn()>.
No argumets, it's an error.

=item C<[turn]: too many args (%i)>

B<(warning)>, L<B<turn()> method|/turn()>.
There's no way to handle that many (namely: I<%i>) arguments.

=item C<[verify]: {%s}{%s}: %s !isa defined>

B<(croak)>, L<B<verify()> method|/verify()>.
I<$rc> queried
from something in I<{fst}> related to I<%s> (3rd)
(value of which is I<%s> (2nd))
while in I<$state> I<%s> (1st)
isn't defined.

=item C<[verify]: {%s}{%s}: %s isa (%s), should be (%s)>

B<(croak)>, L<B<verify()> method|/verify()>.
B<ref> of I<$rc> queried
from something in I<{fst}> related to I<%s> (3rd)
(value of which is I<%s> (2nd))
while in I<$state> I<%s> (1st) is I<%s> (4th).
While it should be I<%s> (5th)
(the last one is literally I<$test>).

=back

=cut

=head1 EXAMPLES

Here are example records.
Whole I<{fst}>, honestly, might become enormous,
thus are skipped for brewity.

    alpha =>
    {
        switch => sub {
            shift % 42, ''
        },
        tturn   => [ qw/ alpha NEXT / ],
        fturn   => [ qw/ STOP horay! / ]
    }

B<source()> supposedly produces some numbers.
Then,
if I<$item> doesn't devide C<mod 42> then go for another number.
If I<$item> devides then break out.
Also, please note, C<STOP> (and C<BREAK>) is special --
it needs B<defined> I<$action> but it can be literally anything.

    bravo =>
    {
        switch => sub {
            my $item = shift;
            $item % 15 ? 'charlie' :
            $item % 5 ? 'delta' :
            $item % 3 ? 'echo' :
            undef, $item
        },
        uturn => [ qw/ bravo NEXT / ],
        turns =>
        {
            charlie => [ qw/ charlie SAME / ],
            delta => [ qw/ delta SAME / ],
            echo => [ qw/ echo SAME / ]
        }
    }

Again, B<source()> supposedly produces some numbers.
Then some kind of FizBuzz happens.
Also, returning C<undef> as default raises questions.
However, it's acceptable for example.

Now, quick demonstration, that's how this FizzBuzz would look
using B<DMA::FSM> capabilities (and B<A::F> of I<v2.2.7> syntax).

    bravo_foo =>
    {
        switch => sub {
            my $item = shift;
            $item % 15 ? !0 : !1, $item
        },
        tturn => [ qw/ charlie SAME / ],
        fturn => [ qw/ bravo_bar SAME / ]
    },
    bravo_bar =>
    {
        switch => sub {
            my $item = shift;
            $item % 5 ? !0 : !1, $item
        },
        tturn => [ qw/ delta SAME / ],
        fturn => [ qw/ bravo_baz SAME / ]
    },
    bravo_baz =>
    {
        switch => sub {
            my $item = shift;
            $item % 3 ? !0 : !1, $item
        },
        tturn => [ qw/ echo SAME / ],
        fturn => [ qw/ bravo NEXT / ]
    }

World of a difference.
Furthermore, if you dare, take a look at
F<t/process/quadratic.t> and F<t/process/sort.t>.
But better don't, those are horrible.

Now, illustration what I<$namespace> configuration parameter opens.

Classics:

    my $bb = Acme::FSM->connect(
        { },
        alpha => {
            switch => sub {
                shift % 42, ''
            }
        }
    );

Illustrations below are heavily stripped for brevity
(Perlwise and B<A::F>wise).

Separate namespace:

    package Secret::Namespace;

    sub bravo_sn {
        shift;
        shift % 42, ''
    }

    package Regular::Namespace;
    use Acme::FSM;

    my $bb = Acme::FSM->connect(
        { namespace => 'Secret::Namespace' },
        alpha => {
            switch => 'bravo_sn'
        }
    );

Separate class:

    package Secret::Class;

    sub new { bless { }, shift }
    sub bravo_sc {
        shift;
        shift % 42, ''
    }

    package Regular::Class;
    use Secret::Class;
    use Acme::FSM;
    
    my $not_bb = Secret::Class->new;
    my $bb = Acme::FSM->connect(
        { namespace => $not_bb },
        alpha => {
            switch => 'bravo_sc'
        }
    );

And, finally, B<A::F> implodes upon itself:

    package Secret::FSM;
    use parent qw/ Acme::FSM /;

    sub connect {
        my $class = shift;
        my $bb = $class->SUPER::connect( @_ );
    } # or just skip constructor, if not needed
    sub bravo_sf {
        shift;
        shift % 42, ''
    }

    package main;

    my $bb = Secret::FSM->connect(
        { namespace => '' },
        alpha => {
            switch => 'bravo_sf'
        }
    );

=cut

=head1 COPYRIGHT AND LICENSE

    Original Copyright: 2008 Dale M Amon. All rights reserved.

    Original License: 

        LGPL-2.1
        Artistic
        BSD

    Original Code Acquired from:

    http://www.cpan.org/authors/id/D/DA/DALEAMON/DMAMisc-1.01-3.tar.gz

    Copyright 2012, 2013, 2022 Eric Pozharski <whynto@pozharski.name>
    Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>

    GNU LGPLv3

    AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

=cut

1
