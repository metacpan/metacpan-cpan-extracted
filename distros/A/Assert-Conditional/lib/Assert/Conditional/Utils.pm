package Assert::Conditional::Utils;

=encoding utf8

=head1 NAME

Assert::Conditional::Utils - Utility functions for conditionally compiling assertions

=head1 SYNOPSIS

    use Assert::Conditional::Utils qw(panic NOT_REACHED);

    $big > $little
        || panic("Impossible for $big > $little");

    chdir("/")  
        || panic("Your root filesystem is corrupt: $!");

    if    ($x) { ...  }
    elsif ($y) { ...  }
    elsif ($z) { ...  } 
    else       { NOT_REACHED }

=head1 DESCRIPTION

This module is used by the L<Assert::Conditional> module for most of the
non-assert functions it needs.  Because this module is still in alpha 
release, the two examples above should be the only guaranteed serviceable
parts.

It is possible (but in alpha release, not necessarily advised) to use the
C<botch> function to write your own assertions that work like those in
L<Assert::Conditional>.

The C<panic> function is for internal errors that should never 
happen.  Unlike its cousin C<botch>, it is not controllable through
the C<ASSERT_CONDITIONAL> variable.

Use C<NOT_REACHED> for some case that can "never" happen.

=cut


use v5.10;
use utf8;
use strict;
use warnings;

use parent 'Exporter';

use Carp qw(carp cluck croak confess shortmess longmess);
use File::Spec;
use File::Basename qw(basename dirname);
use Cwd qw(cwd abs_path);

#################################################################

sub  botch                   (  $  ) ;
sub  botch_argc              (  $$ ) ;
sub  botch_array_length      (  $$ ) ;
sub  botch_false             (     ) ;
sub  botch_have_thing_wanted (  @  ) ;
sub  botch_undef             (     ) ;
sub  code_of_coderef         (  $  ) ;
sub  commify_series                  ;
sub  dump_exports            (  @  ) ;
sub  dump_package_exports    (  $@ ) ;
sub  Export                          ;
sub  FIXME                   (     ) ;
sub _get_comparitor          (  $  ) ;
sub  his_args                ( ;$  ) ;
sub  his_assert              (     ) ;
sub  his_context             ( ;$  ) ;
sub  his_filename            ( ;$  ) ;
sub  his_frame               ( ;$  ) ;
sub  his_is_require          ( ;$  ) ;
sub  his_line                ( ;$  ) ;
sub  his_package             ( ;$  ) ;
sub  his_sub                 ( ;$  ) ;
sub  his_subroutine          ( ;$  ) ;
sub _init_envariables        (     ) ;
sub _init_public_vars        (     ) ;
sub  name_of_coderef         (  $  ) ;
sub  NOT_REACHED             (     ) ;
sub  panic                   (  $  ) ;
sub  sig_name2num            (  $  ) ;
sub  sig_num2longname        (  $  ) ;
sub  sig_num2name            (  $  ) ;
sub  subname_or_code         (  $  ) ;
sub  UCA                     (  _  ) ;
sub  UCA1                    (  _  ) ;
sub  uca1_cmp                (  $$ ) ;
sub  UCA2                    (  _  ) ;
sub  uca2_cmp                (  $$ ) ;
sub  UCA3                    (  _  ) ;
sub  uca3_cmp                (  $$ ) ;
sub  UCA4                    (  _  ) ;
sub  uca4_cmp                (  $$ ) ;
sub  uca_cmp                 (  $$ ) ;
sub  uca_sort                (  @  ) ;
sub _uniq                            ;

#################################################################

our $VERSION = 0.001_000;

our %EXPORT_TAGS;


push our @EXPORT_OK, do {
    my %seen;
    grep { !$seen{$_}++ } map { @$_ } values %EXPORT_TAGS;
};

our @CARP_NOT = qw(
    Assert::Conditional::Utils
    Assert::Conditional
    Attribute::Handlers
);

$EXPORT_TAGS{all} = \@EXPORT_OK;

#################################################################

# The following attribute handler handler for subs saves
# us a lot of bookkeeping trouble by letting us declare
# which export tag groups a particular assert belongs to
# at the point of declaration where it belongs, and so
# that it is all handled automatically.
#
use Attribute::Handlers;

sub Export : ATTR(BEGIN)
{
    our $Assert_Debug;
    my($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;

    state $glyph_map = {
        CODE    =>  '&',
        SCALAR  =>  '$',
        ARRAY   =>  '@',
        HASH    =>  '%',
    };

    my $glyph = $glyph_map->{ ref($referent) } || botch_undef;

    no strict "refs";

    my $exportee = *{$symbol}{NAME};
    $exportee =~ s/^/$glyph/ unless $glyph eq $glyph_map->{CODE};

    my $tagref = $data;
    if (defined($tagref) && !ref($tagref)) {
        $tagref = [ $tagref ];
    }

    my    $his_export_ok = $package . "::EXPORT_OK";
    push @$his_export_ok, $exportee;
    carp "Adding $exportee to EXPORT_OK in $package" if $Exporter::Verbose;

    if ($tagref) {
        my $his_export_tags = $package . "::EXPORT_TAGS";
        for my $tag (@$tagref, qw(all)) {
            carp "Adding $exportee to EXPORT_TAG :$tag in $package" if $Exporter::Verbose;
            push @{ $his_export_tags->{$tag} }, $exportee;
        }
    }
}

our($Assert_Debug, $Assert_Always, $Assert_Carp, $Assert_Never, $Allow_Handlers)
    :Export( qw[vars] );

our $Pod_Generation;

our(%PLURAL, %N_PLURAL)
    :Export( qw[acme_plurals] );

sub _init_envariables() {

    use Env qw(
        ASSERT_CONDITIONAL
        ASSERT_CONDITIONAL_BUILD_POD
        ASSERT_CONDITIONAL_DEBUG
        ASSERT_CONDITIONAL_ALLOW_HANDLERS
    );

    $Pod_Generation //= $ASSERT_CONDITIONAL_BUILD_POD      || 0;
    $Allow_Handlers //= $ASSERT_CONDITIONAL_ALLOW_HANDLERS || 0;
    $Assert_Debug   //= $ASSERT_CONDITIONAL_DEBUG          || 0;

    if ($ASSERT_CONDITIONAL) {
        for ($ASSERT_CONDITIONAL) {
            unless (/\b(?: carp | always | never )\b/x) {
                warn("Ignoring unknown value '$_' of ASSERT_CONDITIONAL envariable");
                next;
            }
            if ( /\b carp     \b/x ) { $Assert_Carp    ||= 1 }
            if ( /\b always   \b/x ) { $Assert_Always  ||= 1 }
            if ( /\b never    \b/x ) { $Assert_Never   ||= 1 }
            if ( /\b handlers \b/x ) { $Allow_Handlers ||= 1 }
        }
    } 

    $Assert_Always ||= 1 unless $Assert_Carp || $Assert_Never;

    if ($Assert_Never) {
        warn q(Ignoring $Assert_Always because $Assert_Never is true) if $Assert_Always;
        warn q(Ignoring $Assert_Carp because $Assert_Never is true)   if $Assert_Carp;
        $Assert_Always = $Assert_Carp = 0;
    }

}

sub _init_public_vars() {
    Acme::Plural->import();
}

BEGIN     { _init_envariables() }
UNITCHECK { _init_public_vars() }


=pod

=head2 Exported Variables

Here is the list of the support global variables, available for import,
which are normally controlled by the C<ASSERT_CONDITIONAL> environment 
variable.

=over

=item C<$Assert_Never>

Set by default under C<ASSERT_CONDITIONAL=never>.

Assertions are never imported, and even if you somehow manage to import
them, they will never never make a peep nor raise an exception.

=item C<$Assert_Always>

Set by default under C<ASSERT_CONDITIONAL=always>.

Assertions are always imported, and even if you somehow manage to avoid importing
them, they will still raise an exception on error.

=item C<$Assert_Carp>

Set by default under C<ASSERT_CONDITIONAL=carp>.

Assertions are always imported but they do not raise an exception if they fail;
instead they old carp at you.  This is true even if you manage to call an assertion
you haven't imported.

=back

A few others exist, but you should probably not pay attention to them.

=head2 Exported Functions

Here is the list of all exported functions with their prototypes:

 botch                   (  $  ) ;
 botch_argc              (  $$ ) ;
 botch_array_length      (  $$ ) ;
 botch_false             (     ) ;
 botch_have_thing_wanted (  @  ) ;
 botch_undef             (     ) ;
 code_of_coderef         (  $  ) ;
 commify_series                  ;
 dump_exports            (  @  ) ;
 dump_package_exports    (  $@ ) ;
 Export                          ;
 FIXME                   (     ) ;
 his_args                ( ;$  ) ;
 his_assert              (     ) ;
 his_context             ( ;$  ) ;
 his_filename            ( ;$  ) ;
 his_frame               ( ;$  ) ;
 his_is_require          ( ;$  ) ;
 his_line                ( ;$  ) ;
 his_package             ( ;$  ) ;
 his_sub                 ( ;$  ) ;
 his_subroutine          ( ;$  ) ;
 name_of_coderef         (  $  ) ;
 NOT_REACHED             (     ) ;
 panic                   (  $  ) ;
 sig_name2num            (  $  ) ;
 sig_num2longname        (  $  ) ;
 sig_num2name            (  $  ) ;
 subname_or_code         (  $  ) ;
 UCA                     (  _  ) ;
 UCA1                    (  _  ) ;
 uca1_cmp                (  $$ ) ;
 UCA2                    (  _  ) ;
 uca2_cmp                (  $$ ) ;
 UCA3                    (  _  ) ;
 uca3_cmp                (  $$ ) ;
 UCA4                    (  _  ) ;
 uca4_cmp                (  $$ ) ;
 uca_cmp                 (  $$ ) ;
 uca_sort                (  @  ) ;

=head2 Export Tags

Available exports are grouped by the following tags:

=over

=item C<:all>

C<%N_PLURAL>, C<%PLURAL>, C<$Assert_Always>, C<$Assert_Carp>, C<$Assert_Debug>, C<$Assert_Never>, C<botch>, C<botch_argc>, C<botch_array_length>, C<botch_false>, C<botch_have_thing_wanted>, C<botch_undef>, C<CALLER_BITMASK>, C<CALLER_EVALTEXT>, C<CALLER_FILENAME>, C<CALLER_HASARGS>, C<CALLER_HINTHASH>, C<CALLER_HINTS>, C<CALLER_IS_REQUIRE>, C<CALLER_LINE>, C<CALLER_PACKAGE>, C<CALLER_SUBROUTINE>, C<CALLER_WANTARRAY>, C<code_of_coderef>, C<commify_series>, C<dump_exports>, C<dump_package_exports>, C<FIXME>, C<his_args>, C<his_assert>, C<his_context>, C<his_filename>, C<his_frame>, C<his_is_require>, C<his_line>, C<his_package>, C<his_sub>, C<his_subroutine>, C<name_of_coderef>, C<NOT_REACHED>, C<panic>, C<sig_name2num>, C<sig_num2longname>, C<sig_num2name>, C<subname_or_code>, C<UCA>, C<uca_cmp>, C<uca_sort>, C<UCA1>, C<uca1_cmp>, C<UCA2>, C<uca2_cmp>, C<UCA3>, C<uca3_cmp>, C<UCA4>, and C<uca4_cmp>.

=item C<:acme_plurals>

C<%N_PLURAL> and C<%PLURAL>.

=item C<:botch>

C<botch>, C<botch_argc>, C<botch_array_length>, C<botch_false>, C<botch_have_thing_wanted>, C<botch_undef>, and C<panic>.

=item C<:CALLER>

C<CALLER_BITMASK>, C<CALLER_EVALTEXT>, C<CALLER_FILENAME>, C<CALLER_HASARGS>, C<CALLER_HINTHASH>, C<CALLER_HINTS>, C<CALLER_IS_REQUIRE>, C<CALLER_LINE>, C<CALLER_PACKAGE>, C<CALLER_SUBROUTINE>, and C<CALLER_WANTARRAY>.

=item C<:code>

C<code_of_coderef>, C<name_of_coderef>, and C<subname_or_code>.

=item C<:exports>

C<dump_exports> and C<dump_package_exports>.

=item C<:frame>

C<CALLER_BITMASK>, C<CALLER_EVALTEXT>, C<CALLER_FILENAME>, C<CALLER_HASARGS>, C<CALLER_HINTHASH>, C<CALLER_HINTS>, C<CALLER_IS_REQUIRE>, C<CALLER_LINE>, C<CALLER_PACKAGE>, C<CALLER_SUBROUTINE>, C<CALLER_WANTARRAY>, C<his_args>, C<his_assert>, C<his_context>, C<his_filename>, C<his_frame>, C<his_is_require>, C<his_line>, C<his_package>, C<his_sub>, and C<his_subroutine>.

=item C<:lint>

C<FIXME>, C<NOT_REACHED>, and C<panic>.

=item C<:list>

C<commify_series> and C<uca_sort>.

=item C<:sigmappers>

C<sig_name2num>, C<sig_num2longname>, and C<sig_num2name>.

=item C<:unicode>

C<UCA>, C<uca_cmp>, C<uca_sort>, C<UCA1>, C<uca1_cmp>, C<UCA2>, C<uca2_cmp>, C<UCA3>, C<uca3_cmp>, C<UCA4>, and C<uca4_cmp>.

=item C<:vars>

C<$Assert_Always>, C<$Assert_Carp>, C<$Assert_Debug>, and C<$Assert_Never>.

=back

=head2 Exported Functions

=over

=item C<botch($)>

The main way that assertions fail.  Normally it raises an exception
by calling C<Carp::confess>, but this can be controlled using the
C<ASSERT_CONDITIONAL> environment variable or its associated package
variables as previously described.


=cut

sub botch($)
    :Export( qw[botch] )
{
    return if $Assert_Never;

    my($msg) = @_;
    my $sub = his_assert;

    local @SIG{<__{DIE,WARN}__>} unless $Allow_Handlers;

    my $botch = "$0\[$$]: botched assertion $sub: \u$msg";

    if ($Assert_Carp) { 
        Carp::carp($botch) 
    }

    if ($Assert_Always) {
        $botch = shortmess("$botch, bailing out");
        Carp::confess("$botch\n   Beginning stack dump from failed $sub");
    }
}

=item C<botch_false()>

A way to panic if something is false but shouldn't be.

=cut

sub botch_false()
    :Export( qw[botch] )
{
    panic "value should not be false";
}

=item C<botch_undef()>

A way to panic if something is undef but shouldn't be.

=cut

sub botch_undef()
    :Export( qw[botch] )
{
    panic "value should not be undef";
}


#################################################################
#
# A few stray utility functions that are a bit too intimate with
# the assertions in this file to deserve being made public

=item C<botch_argc($$)>

=cut

sub botch_argc($$)
    :Export( qw[botch] )
{
    my($have, $want) = @_;
    botch_have_thing_wanted(HAVE => $have, THING => "argument", WANTED => $want);
}

=item C<botch_array_length($$)>

=cut

sub botch_array_length($$)
    :Export( qw[botch] )
{
    my($have, $want) = @_;
    botch_have_thing_wanted(HAVE => $have, THING => "array element", WANTED => $want);
}

=item C<botch_have_thing_wanted(@)>

=cut

sub botch_have_thing_wanted(@)
    :Export( qw[botch] )
{
    my(%param) = @_;
    my $have   = $param{HAVE}  // botch_undef;
    my $thing  = $param{THING}  // botch_undef;
    my $wanted = $param{WANTED} // botch_undef;
    botch "have $N_PLURAL{$thing => $have} but wanted $wanted";
}


#################################################################

=item C<panic(I<MESSAGE>)>

This function is used for internal errors that should never happen.
It calls C<Carp::confess> with a prefix indicating that it is an
internal error.

=cut

sub panic($)
    :Export( qw[lint botch] )
{
    my($msg) = @_;
    local @SIG{<__{DIE,WARN}__>} unless $Allow_Handlers;
    Carp::confess("Panicking on internal error: $msg");
}

=item C<FIXME>

Code you haven't gotten to yet.

=cut

sub FIXME()
    :Export( qw[lint] )
{
    panic "Unimplemented code reached; you forgot to code up a TODO section";
}

=item C<NOT_REACHED>

Put this in places that you think you can never reach in your code.

=cut

sub NOT_REACHED()
    :Export( qw[lint] )
{
    panic "Logically unreachable code somehow reached";
}

#################################################################

=item C<his_assert()>

=cut

sub his_assert()
    :Export( qw[frame] )
{
    my $sub = q();
    for (my $i = 1; $sub !~ /\b_*assert/; $i++)  {
        $sub = his_sub($i) // last;
    }
    $sub //= his_sub(2);
    $sub =~ s/.*:://;
    return $sub;
}

=item C<his_args(;$)>

=cut

sub his_args(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    do { package DB; () = caller($frames+2); };
    return @DB::args;
}

=item C<his_frame(;$)>

=cut

sub his_frame(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    return caller($frames+2);
}

BEGIN {

    # Stealing lovely "iota" magic from the
    # Go language construct of the same name.
    my      $iota;
    BEGIN { $iota = 0 }
    use constant {
        CALLER_PACKAGE     =>  $iota++,
        CALLER_FILENAME    =>  $iota++,
        CALLER_LINE        =>  $iota++,
        CALLER_SUBROUTINE  =>  $iota++,
        CALLER_HASARGS     =>  $iota++,
        CALLER_WANTARRAY   =>  $iota++,
        CALLER_EVALTEXT    =>  $iota++,
        CALLER_IS_REQUIRE  =>  $iota++,
        CALLER_HINTS       =>  $iota++,
        CALLER_BITMASK     =>  $iota++,
        CALLER_HINTHASH    =>  $iota++,
    };

    my @caller_consts = qw(
        CALLER_PACKAGE
        CALLER_FILENAME
        CALLER_LINE
        CALLER_SUBROUTINE
        CALLER_HASARGS
        CALLER_WANTARRAY
        CALLER_EVALTEXT
        CALLER_IS_REQUIRE
        CALLER_HINTS
        CALLER_BITMASK
        CALLER_HINTHASH
    );

    push @{ $EXPORT_TAGS{CALLER} }, @caller_consts;

    push @{ $EXPORT_TAGS{frame}  },
         @{ $EXPORT_TAGS{CALLER} };

}

=item C<his_package(;$)>

=cut

sub his_package(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_PACKAGE]
}

=item C<his_filename(;$)>

=cut

sub his_filename(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_FILENAME]
}

=item C<his_line(;$)>

=cut

sub his_line(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_LINE]
}

=item C<his_subroutine(;$)>

=cut

sub his_subroutine(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_SUBROUTINE]
}

=item C<his_sub(;$)>

=cut

sub his_sub(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    his_subroutine($frames + 1);
}

=item C<his_context(;$)>

=cut

sub his_context(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_WANTARRAY]
}

=item C<his_is_require(;$)>

=cut

sub his_is_require(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_IS_REQUIRE]
}

#################################################################

=item C<code_of_coderef(I<CODEREF>)>

Return the code but not the name of the code reference passed.

=cut

sub code_of_coderef($)
    :Export( qw[code] )
{
    require Data::Dumper;
    my($coderef) = @_;
    my $dobj = Data::Dumper->new([$coderef])->Deparse(1)->Terse(1);
    my $block = $dobj->Dump();
    for ($block) {
        s/^sub.*?(?=\{)//;
        s/^\s+use (?:strict|warnings);\n//gm;
        s/^\s+package .*?;\n//gm;
        s/\A\{\n    (.*);\n\}\n\z/$1/s;

        chomp;
    }
    return $block;
}

=item C<name_of_coderef(I<CODEREF>)>

Return the name of the code reference passed.

=cut

sub name_of_coderef($)
    :Export( qw[code] )
{
    require B;
    my($coderef) = @_;
    my $cv = B::svref_2object($coderef);
    return unless $cv->isa("B::CV");
    my $gv = $cv->GV;
    return if $gv->isa("B::SPECIAL");
    my $subname  = $gv->NAME;
    my $packname = $gv->STASH->NAME;
    return $packname . "::" . $subname;
}

=item C<subname_or_code(I<CODEREF>)>

Return the name of the code reference passed if it is not anonymous;
otherwise return its code.

=cut

sub subname_or_code($)
    :Export( qw[code] )
{
    my($coderef) = @_;
    my $name = name_of_coderef($coderef);
    if ($name =~ /__ANON__/) {
        return code_of_coderef($coderef);
    } else {
        return "$name()";
    }
}

#################################################################

=item C<commify_series>

=cut

sub commify_series
    :Export( qw[list] )
{
    (@_ == 0) ? ''                                      :
    (@_ == 1) ? $_[0]                                   :
    (@_ == 2) ? join(" and ", @_)                       :
                join(", ", @_[0 .. ($#_-1)], "and $_[-1]");
}

=item C<dump_exports(@)>

=cut

sub dump_exports(@)
    :Export( qw[exports] )
{
    my $caller_package = caller;
    dump_package_exports($caller_package, @_);
}

=item C<dump_package_exports($@)>

=cut

sub dump_package_exports($@)
    :Export( qw[exports] )
{
    my($pkg, @exports) = @_;
    my %tag2aref = do { no strict 'refs'; %{$pkg . "::EXPORT_TAGS"} };
    delete $tag2aref{asserts};
    my %seen; # for the all repetition
    my @taglist = @exports ? @exports : ('all', uca_sort(keys %tag2aref));
    my $errors = 0;
    print "=head2 Export Tags\n\n=over\n\n" if $Pod_Generation;
    for my $tag (@taglist)  {
        next if $seen{$tag}++;
        my $aref = $tag2aref{$tag};
        unless ($aref) {
            print STDERR ":$tag is not an export tag in $pkg.\n";
            $errors++;
            next;
        }
        if ($Pod_Generation) {
            print "=item C<:$tag>\n\n", commify_series(map { "C<$_>" } uca_sort @$aref), ".\n\n";
        }
        else {
            print "Conditional export tag :$tag exports ", commify_series(uca_sort @$aref), ".\n";
        }
    }
    print "=back\n\n" if $Pod_Generation;
    return $errors == 0;
}


#################################################################

=item C<UCA(_)>

=cut

sub UCA (_)             :Export( qw[unicode] );

=item C<UCA1(_)>

=cut

sub UCA1(_)             :Export( qw[unicode] );

=item C<UCA2(_)>

=cut

sub UCA2(_)             :Export( qw[unicode] );

=item C<UCA3(_)>

=cut

sub UCA3(_)             :Export( qw[unicode] );

=item C<UCA4(_)>

=cut

sub UCA4(_)             :Export( qw[unicode] );

=item C<uca_cmp($$)>

=cut

sub uca_cmp ($$)        :Export( qw[unicode] );

=item C<uca1_cmp($$)>

=cut

sub uca1_cmp($$)        :Export( qw[unicode] );

=item C<uca2_cmp($$)>

=cut

sub uca2_cmp($$)        :Export( qw[unicode] );

=item C<uca3_cmp($$)>

=cut

sub uca3_cmp($$)        :Export( qw[unicode] );

=item C<uca4_cmp($$)>

=cut

sub uca4_cmp($$)        :Export( qw[unicode] );

{

    my @Comparitor;

    sub _get_comparitor($) {
        my($level) = @_;
        panic "invalid level $level" unless $level =~ /^[1-4]$/;
        return $Comparitor[$level] if $Comparitor[$level];

        require Unicode::Collate;
        my $class = Unicode::Collate:: ;
        # need to discount the other ones altogether 
        my @args = (level => $level); #, variable => "Non-Ignorable");
    #   if ($Opt{locale}) {
    #       require Unicode::Collate::Locale;
    #       $class = Unicode::Collate::Locale:: ;
    #       push @args, locale => $Opt{locale};
    #   }
        my $coll = $class->new(@args);
        $Comparitor[$level] = $coll;
    }

    for my $strength ( 1 .. 4 ) {
        no strict "refs";
        *{ "UCA$strength" } = sub(_) {
            state $coll = _get_comparitor($strength);
            return $coll->getSortKey($_[0]);
        };

        *{ "uca${strength}_cmp" } = sub($$) {
            my($this, $that) = @_;
            "UCA$strength"->($this)
                cmp
            "UCA$strength"->($that)

        };
    }

    no warnings "once";
    *UCA     = \&UCA1;
    *uca_cmp = \&uca1_cmp;
}

=item C<uca_sort(@)>

Return its argument list sorted alphabetically.

=cut

sub uca_sort(@)
    :Export( qw[unicode list] )
{
     state $collator = _get_comparitor(4);
     return $collator->sort(@_);
}

{
    sub _uniq {
        my %seen;
        my @out;
        for (@_) { push @out, $_ unless $seen{$_}++ }
        return @out;
    }

    @EXPORT_OK = _uniq(@EXPORT_OK);
    for my $tag (keys %EXPORT_TAGS) {
        my @exports = _uniq @{ $EXPORT_TAGS{$tag} };
        $EXPORT_TAGS{$tag} = [@exports];
    }
}


#################################################################

{   # Private scope for sig mappers

    our %Config;  # constrains in-file lexical visibility
    use  Config;

    my $sig_count      = $Config{sig_size}     || botch_undef;
    my $sig_name_list  = $Config{sig_name}     || botch_undef;
    my $sig_num_list   = $Config{sig_num}      || botch_undef;

    my @sig_nums       = split " ", $sig_num_list;
    my @sig_names      = split " ", $sig_name_list;

    my $have;
    $have =  @sig_nums;
    $have == $sig_count                 || panic "expected $sig_count signums, not $have";

    $have =  @sig_names;
    $have == $sig_count                 || panic "expected $sig_count signames, not $have";

    my(%_Map_num2name, %_Map_name2num);

    @_Map_num2name {@sig_nums } = @sig_names;
    @_Map_name2num {@sig_names} = @sig_nums;

=item C<sig_num2name(I<NUMBER>)>

Returns the name of the signal number, like C<HUP>, C<INT>, etc.

=cut

    sub sig_num2name($)
        :Export( sigmappers )
    {
        my($num) = @_;
        $num =~ /^\d+$/                 || botch "$num doesn't look like a signal number";
        return $_Map_num2name{$num}     // botch_undef;
    }

=item C<sig_num2longname($)>

Returns the long name of the signal number, like C<SIGHUP>, C<SIGINT>, etc.

=cut

    sub sig_num2longname($)
        :Export( sigmappers )
    {
        return q(SIG) . &sig_num2name;
    }

=item sub C<sig_name2num(I<NAME>)>

Returns the signal number corresponding to the passed in name.

=cut

    sub sig_name2num($)
        :Export( sigmappers )
    {
        my($name) = @_;
        $name =~ /^\p{upper}+$/         || botch "$name doesn't look like a signal name";
        $name =~ s/^SIG//;
        return $_Map_name2num{$name}    // botch_undef;
    }

}

=back

=cut


#################################################################

=for tricking the declarator
__END__

=cut

# You really don't want to be looking here.

BEGIN {
    package # so PAUSE doesn't index this
        Acme::Plural::pl_simple;
    require Tie::Hash;
    our @ISA = qw(Acme::Plural Tie::StdHash);

    sub TIEHASH {
        my($class, @args) = @_;
        my $self = { };
        bless $self, $class;
        return $self;
    }

    sub FETCH {
        my($self, $key) = @_;
        my($noun, $count) = (split($; => $key), 2);
        return $noun if $count eq '1';
        $self->{$noun} ||= $self->_lame_plural($noun);
    }

}

BEGIN {
    package  # so PAUSE doesn't index this
        Acme::Plural::pl_count;
    our @ISA = 'Acme::Plural::pl_simple';

    sub FETCH {
        my($self, $key) = @_;
        my $several = $self->SUPER::FETCH($key);
        my($noun, $count) = (split($; => $key), 2);
        return "$count $several";
    }

}

BEGIN {
    package # so PAUSE doesn't index this
        Acme::Plural;

    use Exporter 'import';

    our @EXPORT = qw(
        %PLURAL
        %N_PLURAL
    );

    # TODO: replace with the Lingua::EN::Inflect
    sub _lame_plural($$) {
        my($self, $str) = @_;
        return $str if $str =~ s/(?<! [aeiou] ) y  $/ies/x;
        return $str if $str =~ s/ (?: [szx] | [sc]h ) \K $/es/x;
        return $str . "s";
    }

    tie our %PLURAL    => "Acme::Plural::pl_simple";
    tie our %N_PLURAL  => "Acme::Plural::pl_count";
}

1;

=head1 ENVIRONMENT

The C<ASSERT_CONDITIONAL> variable controls the behavior
of the C<botch> function, and also of the the conditional
importing itself.

=head1 SEE ALSO

The L<Assert::Conditional> module that uses these utilities
and 
the L<Exporter::ConditionalSubs> module which that module is based on.

=head1 BUGS AND LIMITATIONS

Probably many.  This is an alpha release.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


__DATA__
