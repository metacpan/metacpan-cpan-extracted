# $Id: TestSuite.pm 564 2025-02-13 21:33:15Z whynot $
# Copyright 2012, 2013, 2022 Eric Pozharski <whynot@pozharski.name>
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL
# qmdP Wc1x TJXv nTKr MbJk korM rYp3 zo57 DSKU kGG4 YES1 YgDi N1Xl wzqw 3HbC Y5xM Mn2s 6iIU fYQc UYWm nUF2 t1OM S675 6fg6 XOki d2hO |

use strict;
use warnings;

package t::TestSuite;
use version 0.77; our $VERSION = version->declare( v2.3.4 );

use base qw| Exporter |;
# XXX:202212222241:whynot: B<&AFSMTS_dump> isn't in use by unit-tests.  Also has cookoo dependency omitted from I<build_requires>.  Hmm.
our %EXPORT_TAGS =
( diag     => [qw| &AFSMTS_diag  &AFSMTS_dump  &AFSMTS_croakson |],
  utils    => [qw| &AFSMTS_smartmatch              &AFSMTS_grep |],
  run      =>
[qw| &AFSMTS_wrap &AFSMTS_croakson &AFSMTS_deeply &AFSMTS_shift |],
  wraps    =>
[qw| &AFSMTS_class_wrap &AFSMTS_object_wrap &AFSMTS_method_wrap |],
  switches =>
[qw| &AFSMTS_U &AFSMTS_Uk &AFSMTS_F &AFSMTS_FK &AFSMTS_T
     &AFSMTS_TK &AFSMTS_t &AFSMTS_tK &AFSMTS_D &AFSMTS_E
                                              &AFSMTS_EK        |] );
our @EXPORT_OK = ( map @$_, values %EXPORT_TAGS );

use Module::Build;

use Carp qw| croak |;

=head1 NAME

TestSuite.pm - service routines of Acme::FSM build

=head1 ACCESSORIES

=over

=item I<$t::TestSuite::build>

    $t::TestSuite::build->notes( 'should_i_die' ) and die;

Provides access to current build.

=cut

our $build = Module::Build->current;

=item I<$t::TestSuite::NO_TRIM>

    $t::TestSuite::NO_TRIM = 1;

Forbids trimming I<$main::stderr>.

=cut

our $NO_TRIM;

=back

=cut

=head1 FUNCTIONS

=over

=item B<AFSMTS_diag()>

    use t::TestSuite qw/ :diag /;
    AFSMTS_diag $@

Outputs through B<Test::More::diag()>.
Void if I<STDOUT> isa not terminal, I<$ENV{QUIET}> is TRUE, I<@_> is empty, or
I<@_> consists of FALSEs.

=cut

sub AFSMTS_diag ( @ )     {
    -t STDOUT && !$ENV{QUIET} && @_ && grep $_, @_                  or return;
    Test::More::diag( @_ ) }

=item B<AFSMTS_dump()>

    use t::TestSuite qw/ :diag /;
    AFSMTS_dump $@

Dumpts through B<Data::Dumper::Dump()> (wrapped in B<Test::More::diag()>).
Void if I<STDOUT> isa not terminal, I<$ENV{QUIET}> is TRUE, I<@_> is empty, or
I<@_> consists of FALSEs.

=cut

sub AFSMTS_dump ( $ )                                  {
    -t STDOUT && !$ENV{QUIET} && @_ && $_[0]                        or return;
    require Data::Dumper;
    Test::More::diag( Data::Dumper->Dump([ shift @_ ])) }

=item B<AFSMTS_deeply()>

    use t::TestSuite qw/ :run /;
    our( $rc, $bb );
    AFSMTS_wrap;
    AFSMTS_deeply @{[[qw/ items left /], { status => 'S0' }]}, 'description';

Wrapper around B<Test::More::deeply()>.
Parameters (for B<T::M::d()>, namely) are ARRAY of two items:

=over

=item I<$main::rc>

ARRAY of items FSM has just left behind (contents of I<$main::rc>);

=item I<\%blackboard>

A blackboard snapshot after FSM has been run;
That snapshotting means:

=over

=item *

all keys of I<$main::bb>, except special I<_> key, are copied;

=item *

all keys of I<$main::bb{_}>, exccept I<fst> key, are copied.

=back

That is, everything, except filtered goes in one HASH.

=back

If B<Test::More::is_deeply()> fails then a line in a test-unit where it
happened is hinted with B<AFSMTS_diag()>.

=cut

sub AFSMTS_deeply ( \@$ )                      {
    my( $expected, $descr ) = @_;
    my $got = { };
    $got->{$_} = $main::bb->{$_}     foreach grep $_ ne q|_|, keys %$main::bb;
    $got->{$_} = $main::bb->{_}{$_}                                    foreach
      grep $_ ne q|fst|, keys %{$main::bb->{_}};
    unless( Test::More::is_deeply(
    [ $main::rc, $got ], $expected, $descr )) {
        AFSMTS_diag sprintf qq|   at %s line %i.|, ( caller )[1,2];
        AFSMTS_dump [ $main::rc ];
        AFSMTS_dump [ $got      ]              }}

=item B<AFSMTS_wrap()>

    use t::TestSuite qw/ :run /;
    our( $rc, %st, $bb, %opts );
    our( $stdout, $stderr );

    AFSMTS_wrap;
    AFSMTS_deeply @{[ ]}, 'again!';

    TODO: {
        local TODO = 'oops, not yet';
        AFSMTS_wrap;
        isnt $rc, "ALRM\n", 'success!';
    }

Wraps B<connect()> and B<process()>.
Everything is got from I<main>.
Those are:

=over

=item I<$rc>

ARRAY;
storage for FSM return;

=item I<%st>

Status table;

=item I<$bb>

B<Acme::FSM> object;
An object is reZ<>B<connect>ed;
I<$bb{queue}> is created and set to empty ARRAY.

=item I<%opts>

A hash of options, those will be passed to constructor.

=back

I<STDOUT> and I<STDERR> are backed up in scalars;
those are saved in I<$main::stdout> and I<$main::stderr>.
I<STDERR> is output with B<AFSMTS_diag()> anyway.
However, it's trimmed to first 1024 bytes
(unless I<$t::TestSuite::NO_TRIM> is TRUE)
(it's not clear yet if those are 1024 bytes or characters).

Also, there's a timeout feature.
That timeout should be protected with TODO of B<Test::More>.
I<STDERR> is dumped too.

That timeout is implemented with B<alarm>ed B<eval>.
That B<eval> protects against B<die>s too.

=cut

sub AFSMTS_wrap ( )   {
    open my $stdout_bak, q|>&|, \*STDOUT;
    open my $stderr_bak, q|>&|, \*STDERR;

    close STDOUT; open STDOUT, q|>|, \$main::stdout;
    close STDERR; open STDERR, q|>|, \$main::stderr;
    local $SIG{__DIE__} = sub          {
        alarm 0;
        close STDOUT; open STDOUT, q|>&|, $stdout_bak;
        close STDERR;
        open STDERR, q|>&|, $stderr_bak };

    do                                                               {
        no warnings qw| once |;
        $main::bb = Acme::FSM->connect( { %main::opts }, \%main::st ) };
    $main::bb->{queue} = [ ];
    my $rc = [ eval {
        local $SIG{ALRM} = sub { die qq|ALRM\n| };
        alarm 3;
        $main::rc = [ $main::bb->process ];
        alarm 0;
        1            } ];
    unless( @$rc )        {
# TODO:20121120224141:whynot: Make sure it's 1024 characters not bytes.
        $main::stderr = substr $main::stderr || '', 0, 1024   unless $NO_TRIM;
        $main::rc = [ $@ ] }
    close STDERR; open STDERR, q|>&|, $stderr_bak;
    close STDOUT; open STDOUT, q|>&|, $stdout_bak;

    AFSMTS_diag $main::stderr  }

=item B<AFSMTS_class_wrap()>

    use t::Test::Suite qw/ :wraps /;
    our( $rc, %st, $bb );
    our( $stdout, $stderr );
    AFSMTS_class_wrap @list;

Complete analogy of B<AFSMTS_wrap()> except B<process()> isn't called and
there's no timeout protection.
Also, there's I<$t::TestSuite::class_cheat>, what, if B<defined> is supposed
to be class name of B<A::F> descandant.

=cut

our $class_cheat;
sub AFSMTS_class_wrap ( @ ) {
    open my $stdout_bak, q|>&|, \*STDOUT;
    open my $stderr_bak, q|>&|, \*STDERR;

    close STDOUT; open STDOUT, q|>|, \$main::stdout;
    close STDERR; open STDERR, q|>|, \$main::stderr;
    local $SIG{__DIE__} = sub {
        close STDOUT; open STDOUT, q|>&|, $stdout_bak;
        close STDERR; open STDERR, q|>&|, $stderr_bak;
        AFSMTS_diag $main::stderr    };
    $main::bb = $class_cheat                        ?
      eval qq|${class_cheat}->connect( \@_ )| :
      Acme::FSM->connect( @_ );
    close STDERR; open STDERR, q|>&|, $stderr_bak;
    close STDOUT; open STDOUT, q|>&|, $stdout_bak;

    AFSMTS_diag $main::stderr }

=item B<AFSMTS_object_wrap()>

    use t::TestSuite qw/ :wraps /;
    our( $rc, %st, $bb );
    our( $stdout, $stderr );
    AFSMTS_object_wrap $childof_A_F, @list;

Complete analogy of B<AFSMTS_wrap()> except B<process()> isn't called and
there's no timeout protection.
It's different from B<AFSMTS_class_wrap> that it goes with
object-construction.
That object goes as a first parameter, then comes list of items to process.

=cut

sub AFSMTS_object_wrap ( $@ ) {
    my $obj = shift @_;
    open my $stdout_bak, q|>&|, \*STDOUT;
    open my $stderr_bak, q|>&|, \*STDERR;

    close STDOUT; open STDOUT, q|>|, \$main::stdout;
    close STDERR; open STDERR, q|>|, \$main::stderr;
    local $SIG{__DIE__} = sub {
        close STDOUT; open STDOUT, q|>&|, $stdout_bak;
        close STDERR; open STDERR, q|>&|, $stderr_bak;
        AFSMTS_diag $main::stderr    };
    $main::bb = $obj->connect( @_ );
    close STDERR; open STDERR, q|>&|, $stderr_bak;
    close STDOUT; open STDOUT, q|>&|, $stdout_bak;

    AFSMTS_diag $main::stderr }

=item B<AFSMTS_method_wrap()>

    use t::TestSuite qw/ :wraps /;
    our( $rc, %st, $bb );
    our( $stdout, $stderr );
    AFSMTS_method_wrap 'some_method', @list;

Complete analogy of B<AFSMTS_wrap()> except instead of B<process()> some
requested I<$method> is B<can>ed first, than invoked with I<@list> over
I<$main::bb> in list context.
What is returned is placed in I<$main::rc> wrapped in ARRAY.
If I<$method> returned one element then ARRAY is replaced with scalar.

=cut

sub AFSMTS_method_wrap ( $@ ) {
    open my $stdout_bak, q|>&|, \*STDOUT;
    open my $stderr_bak, q|>&|, \*STDERR;

    close STDOUT; open STDOUT, q|>|, \$main::stdout;
    close STDERR; open STDERR, q|>|, \$main::stderr;
    my $method = $main::bb->can( shift @_ );
    my $rc = [ eval {
        local $SIG{ALRM} = sub { die qq|ALRM\n| };
        alarm 3;
        $main::rc  = [ $main::bb->$method( @_ ) ];
        alarm 0;
        1 } ];
    alarm 0;
    unless( @$rc )        {
        $main::stderr = substr $main::stderr // '', 0, 1024   unless $NO_TRIM;
        $main::rc = [ $@ ] }
    $main::rc  = $main::rc->[0]                            if 1 == @$main::rc;
    close STDERR; open STDERR, q|>&|, $stderr_bak;
    close STDOUT; open STDOUT, q|>&|, $stdout_bak;

    AFSMTS_diag $main::stderr  }

=item B<AFSMTS_croakson> 'actual description'

    use t::TestSuite qw/ :diag /;
    $rc = eval { die 'as expected'; 1 };
    is !$rc, 0, AFSMTS_croakson 'surprise';

That will add I<$@> (with newlines replaced with spaces) to otherwise dumb
description, like this:

    ok 1 - croaks on (surprise) (as expected at test-unit.t line 12 )

=cut

sub AFSMTS_croakson ( $ )                                     {
    my $eval_msg = $@;
    $eval_msg =~ tr{\n}{ };
    return sprintf q|croaks on (%s) (%s)|, shift @_, $eval_msg }

=item B<AFSMTS_shift()>

    our %opts;
    our @inbase = ( qw/ a b c /, undef );
    our @input = @inbase;
    $opts{source} = \&AFSMTS_shift;
    AFSMTS_wrap;

Quiet generic implementation of I<{source}> code.
Uses script globals:

=over

=item I<@inbase>

Read-only.
When I<@input> runs empty it will be reset from I<@inbase>.

=item I<@input>

Supposed items will be B<shift>ed from this array.

=back

=cut

sub AFSMTS_shift ( )         {
    do                {
        no warnings qw| once |;
        @main::input = @main::inbase                                    unless
          @main::input };
    return shift @main::input }

=item B<AFSMTS_U()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_U, "", "", qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns C<undef> and consumes an item.

=cut

sub AFSMTS_U  { push @{$_[0]{queue}}, $_[1]; ( undef, undef ) }

=item B<AFSMTS_UK()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_UK, "", "", qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns C<undef> and an item unaltered.

=cut

sub AFSMTS_UK { push @{$_[0]{queue}}, $_[1]; ( undef, $_[1] ) }

=item B<AFSMTS_F()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_F, "", "", qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns FALSE but C<undef> and consumes an item.

=cut

sub AFSMTS_F  { push @{$_[0]{queue}}, $_[1]; ( !1, undef ) }

=item B<AFSMTS_FK()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_FK, "", "", qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns FALSE but C<undef> and an item unaltered.

=cut

sub AFSMTS_FK { push @{$_[0]{queue}}, $_[1]; ( !1, $_[1] ) }

=item B<AFSMTS_T()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_T, qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns TRUE and consumes an item.

=cut

sub AFSMTS_T  { push @{$_[0]{queue}}, $_[1]; ( !0, undef ) }

=item B<AFSMTS_TK()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_TK, qw/ S0 NEXT /]);

Convinience switch.
An item is saved in I<@{$bb->{queue}>.
Returns TRUE and an item unaltered.

=cut

sub AFSMTS_TK { push @{$_[0]{queue}}, $_[1]; ( !0, $_[1] ) }

=item B<AFSMTS_t()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_t, qw/ S0 NEXT /]);

Convinience switch.
Returns TRUE and consumes an item.

=cut

sub AFSMTS_t  { ( !0, undef ) }

=item B<AFSMTS_tK()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => [qw/ S0 DONE /, \&AFSMTS_tK, qw/ S0 NEXT /]);

Convinience switch.
Returns TRUE and an item unaltered.

=cut

sub AFSMTS_tK { ( !0, $_[1] ) }

=item B<AFSMTS_D()>

    use t::TestSuite qw/ :switches /;
    %st = ( S0 => ["", "", \&AFSMTS_D]);

Convinience switch.
Just dies with C<die switch> message.

=cut

sub AFSMTS_D  { die qq|die switch| }

=item B<AFSMTS_smartmatch()>

    use t::TestSuite qw/ :utils /;
    fail 'assert' unless AFSMTS_smartmatch @result, @target;

(B<v2.3.6>)
I<rationale: on>
Since B<v5.41.5> L<B<smartmatch>|perlop/Smartmatch Operator> is less then before
(C<use 5.10> fails to compile double-tilde now).
Unfortunately, testsuite used B<smartmatch> to compare two arrays
and it can't.
I<rationale: off>

The sub-name is misleading -- this one isn't close to be drop in replacement for L<B<smartmatch>|perlop/Smartmatch Operator>
(but it has potential nevertheless).

Two B<ARRAY>s are compared for equality.

=over

=item *

If sizes of arrays differ returns C<undef>

=item *

If any two elements mismatch then returns Perl's B<FALSE>

=item *

Otherwise returns Perl's B<TRUE>

=item *

Values are treated as plain scalars (it's too early for recursion)

=back

=cut

sub AFSMTS_smartmatch ( \@\@ )                                 {
    my( $jkCX1Y, $jlVW4H ) = @_;
    @$jkCX1Y == @$jlVW4H                                      or return undef;
    not grep $jkCX1Y->[$_] ne $jlVW4H->[$_], ( 0 .. $#$jkCX1Y ) }

=item B<AFSMTS_grep()>

    use t::TestSuite qw/ :utils /;
    AFSTMTS_grep $item, @mass or next;

(B<v2.3.6>)
This should be in L<B<AFSMTS_smartmatch>|/AFSMTS_smartmatch()>.
But that would be too much work for testsuite support.
So it isn't.

Verifies if I<$item> is present in I<@mass>

=over

=item *

Returns Perl's B<TRUE> if I<$item> is present

=item *

Returns Perl's B<FALSE> otherwise

=back

=cut

sub AFSMTS_grep ( $@ )                 {
    my( $bnabT2, @ikHNm4 ) = @_;
    not not grep $bnabT2 eq $_, @ikHNm4 }

=back

=cut

1;
