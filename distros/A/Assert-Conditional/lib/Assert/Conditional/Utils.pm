package Assert::Conditional::Utils;

use v5.12;
use utf8;
use strict;
use warnings;

use B::Deparse;
use Carp                qw(carp cluck croak confess shortmess longmess);
use Cwd                 qw(cwd abs_path);
use Exporter            qw(import);
use File::Basename      qw(basename dirname);
use File::Spec;

#################################################################

sub  botch                   (  $  ) ;
sub  botch_argc              (  $$ ) ;
sub  botch_array_length      (  $$ ) ;
sub  botch_false             (     ) ;
sub  botch_have_thing_wanted (  @  ) ;
sub  botch_undef             (     ) ;
sub  code_of_coderef         (  $  ) ;
sub  commify_and                     ;
sub  commify_but                     ;
sub  commify_nor                     ;
sub  commify_or                      ;
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
sub  quotify_and                     ;
sub  quotify_but                     ;
sub  quotify_nor                     ;
sub  quotify_or                      ;
sub  serialize_conjunction   (  $@ ) ;
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

use Attribute::Handlers;

# The following attribute handler handler for subs saves
# us a lot of bookkeeping trouble by letting us declare
# which export tag groups a particular assert belongs to
# at the point of declaration where it belongs, and so
# that it is all handled automatically.

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

# Yes, you can actually export these that way too.
our($Assert_Debug, $Assert_Always, $Assert_Carp, $Assert_Never, $Allow_Handlers)
    :Export( qw[vars] );

our $Pod_Generation;

# Let's not talk about these ones.
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

sub botch_false()
    :Export( qw[botch] )
{
    panic "value should not be false";
}

sub botch_undef()
    :Export( qw[botch] )
{
    panic "value should not be undef";
}

#################################################################
#
# A few stray utility functions that are a bit too intimate with
# the assertions in this file to deserve being made public

sub botch_argc($$)
    :Export( qw[botch] )
{
    my($have, $want) = @_;
    botch_have_thing_wanted(HAVE => $have, THING => "argument", WANTED => $want);
}

sub botch_array_length($$)
    :Export( qw[botch] )
{
    my($have, $want) = @_;
    botch_have_thing_wanted(HAVE => $have, THING => "array element", WANTED => $want);
}

sub botch_have_thing_wanted(@)
    :Export( qw[botch] )
{
    my(%param) = @_;
    my $have   = $param{HAVE}   // botch_undef;
    my $thing  = $param{THING}  // botch_undef;
    my $wanted = $param{WANTED} // botch_undef;
    botch "have $N_PLURAL{$thing => $have} but wanted $wanted";
}

#################################################################

sub panic($)
    :Export( qw[lint botch] )
{
    my($msg) = @_;
    local @SIG{<__{DIE,WARN}__>} unless $Allow_Handlers;
    Carp::confess("Panicking on internal error: $msg");
}

sub FIXME()
    :Export( qw[lint] )
{
    panic "Unimplemented code reached; you forgot to code up a TODO section";
}

sub NOT_REACHED()
    :Export( qw[lint] )
{
    panic "Logically unreachable code somehow reached";
}

#################################################################

# Find the highest assert_ on the stack so that we don't misreport
# failures. For example this next one illustrated below should be
# reporting that assert_hash_keys_required botched because that's the
# one we called; it shouldn't say that it was assert_min_keys or
# assert_hashref_keys_required that botched, even thought the nearest
# assert that called botch was actually assert_min_keys.

## perl -Ilib -MAssert::Conditional=:all -e 'assert_hash_keys_required %ENV, "snap"'
## -e[92241]: botched assertion assert_hash_keys_required: Key 'snap' missing from hash, bailing out at -e line 1.
##
##    Beginning stack dump from failed assert_hash_keys_required at lib/Assert/Conditional/Utils.pm line 391.
## 	Assert::Conditional::Utils::botch("key 'snap' missing from hash") called at lib/Assert/Conditional.pm line 1169
## 	Assert::Conditional::assert_min_keys(REF(0x7fe6196ec3f0), "snap") called at lib/Assert/Conditional.pm line 1135
## 	Assert::Conditional::assert_hashref_keys_required called at lib/Assert/Conditional.pm line 1104
## 	Assert::Conditional::assert_hash_keys_required(HASH(0x7fe619028f70), "snap") called at -e line 1

# But if we can't find as assert_\w+ on the stack, just use the name of the
# the thing that called the thing that called us, so presumably whatever
# called botch.
sub his_assert()
    :Export( qw[frame] )
{
    my $assert_rx = qr/::assert_\w+\z/x;
    my $i;
    my $sub = q();
    for ($i = 1; $sub !~ $assert_rx; $i++)  {
        $sub = his_sub($i) // last;
    }
    $sub //= his_sub(2); # in case we couldn't find an assert_\w+ sub
    while ((his_sub($i+1) // "") =~ $assert_rx) {
        $sub = his_sub(++$i);
    }
    $sub =~ s/.*:://;
    return $sub;
}

sub his_args(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    do { package DB; () = caller($frames+2); };
    return @DB::args;
}

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

sub his_package(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_PACKAGE]
}

sub his_filename(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_FILENAME]
}

sub his_line(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_LINE]
}

sub his_subroutine(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_SUBROUTINE]
}

sub his_sub(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    his_subroutine($frames + 1);
}

sub his_context(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_WANTARRAY]
}

sub his_is_require(;$)
    :Export( qw[frame] )
{
    my $frames = @_ && $_[0];
    (his_frame($frames+1))[CALLER_IS_REQUIRE]
}

#################################################################

my ($hint_bits, $warning_bits);
BEGIN {($hint_bits, $warning_bits) = ($^H, ${^WARNING_BITS})}

sub code_of_coderef($)
    :Export( qw[code] )
{
    my($coderef) = @_;

    my $deparse = B::Deparse->new(
        "-P",
        "-sC",
       #"-x9",
       #"-q",
       #"-q",
    );
    $deparse->ambient_pragmas(
       warnings => 'all',
       strict => 'all',
       hint_bits => $hint_bits,
       warning_bits => $warning_bits,
    ) if 0;
    my $body = $deparse->coderef2text($coderef);

    #return $body;

    for ($body) {
        s/^\h+(?:use|no) (?:strict|warnings|feature|integer|utf8|bytes|re)\b[^\n]*\n//gm;
        s/^\h+package [^\n]*;\n//gm;
        s/\A\{\n\h+([^\n;]*);\n\}\z/{ $1 }/;
    }

    return $body;

}

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

sub serialize_conjunction($@) {
    my $conj = shift;
    (@_ == 0) ? ''                                      :
    (@_ == 1) ? $_[0]                                   :
    (@_ == 2) ? join(" $conj ", @_)                     :
                join(", ", @_[0 .. ($#_-1)], "$conj $_[-1]");
}

sub commify_series
    :Export( qw[list] )
{
    &commify_and;
}

sub commify_and
    :Export( qw[list] )
{
    serialize_conjunction and => @_;
}

sub commify_or
    :Export( qw[list] )
{
    serialize_conjunction or => @_;
}

sub commify_but
    :Export( qw[list] )
{
    serialize_conjunction but => @_;
}

sub commify_nor
    :Export( qw[list] )
{
    serialize_conjunction nor => @_;
}

sub quotify_and
    :Export( qw[list] )
{
    commify_and map { "'$_'" } @_;
}

sub quotify_or
    :Export( qw[list] )
{
    commify_or map { "'$_'" } @_;
}

sub quotify_nor
    :Export( qw[list] )
{
    commify_nor map { "'$_'" } @_;
}

sub quotify_but
    :Export( qw[list] )
{
    commify_but map { "'$_'" } @_;
}

sub dump_exports(@)
    :Export( qw[exports] )
{
    my $caller_package = caller;
    dump_package_exports($caller_package, @_);
}

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
            print "=item C<:$tag>\n\n", commify_series(map { "L</$_>" } uca_sort @$aref), ".\n\n";
        }
        else {
            print "Conditional export tag :$tag exports ", commify_series(uca_sort @$aref), ".\n";
        }
    }
    print "=back\n\n" if $Pod_Generation;
    return $errors == 0;
}

#################################################################

sub UCA (_)             :Export( qw[unicode] );
sub UCA1(_)             :Export( qw[unicode] );
sub UCA2(_)             :Export( qw[unicode] );
sub UCA3(_)             :Export( qw[unicode] );
sub UCA4(_)             :Export( qw[unicode] );
sub uca_cmp ($$)        :Export( qw[unicode] );
sub uca1_cmp($$)        :Export( qw[unicode] );
sub uca2_cmp($$)        :Export( qw[unicode] );
sub uca3_cmp($$)        :Export( qw[unicode] );
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

    sub sig_num2name($)
        :Export( sigmappers )
    {
        my($num) = @_;
        $num =~ /^\d+$/                 || botch "$num doesn't look like a signal number";
        return $_Map_num2name{$num}     // botch_undef;
    }

    sub sig_num2longname($)
        :Export( sigmappers )
    {
        return q(SIG) . &sig_num2name;
    }

    sub sig_name2num($)
        :Export( sigmappers )
    {
        my($name) = @_;
        $name =~ /^\p{upper}+$/         || botch "$name doesn't look like a signal name";
        $name =~ s/^SIG//;
        return $_Map_name2num{$name}    // botch_undef;
    }

}

#################################################################

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

__END__

=encoding utf8

=head1 NAME

Assert::Conditional::Utils - Utility functions for conditionally-compiled assertions

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

=for reproduction
ASSERT_CONDITIONAL_BUILD_POD=1 perl -Ilib -MAssert::Conditional -e 'Assert::Conditional::Utils->dump_package_exports' | fmt

=head2 Export Tags

Available exports are grouped by the following tags:

=over

=item C<:all>

L</$Allow_Handlers>, L</$Assert_Always>, L</$Assert_Carp>,
L</$Assert_Debug>, L</$Assert_Never>, L</botch>, L</botch_argc>,
L</botch_array_length>, L</botch_false>, L</botch_have_thing_wanted>,
L</botch_undef>, L</CALLER_BITMASK>, L</CALLER_EVALTEXT>,
L</CALLER_FILENAME>, L</CALLER_HASARGS>, L</CALLER_HINTHASH>,
L</CALLER_HINTS>, L</CALLER_IS_REQUIRE>, L</CALLER_LINE>,
L</CALLER_PACKAGE>, L</CALLER_SUBROUTINE>, L</CALLER_WANTARRAY>,
L</code_of_coderef>, L</commify_and>, L</commify_but>, L</commify_nor>,
L</commify_or>, L</commify_series>, L</dump_exports>,
L</dump_package_exports>, L</FIXME>, L</his_args>, L</his_assert>,
L</his_context>, L</his_filename>, L</his_frame>, L</his_is_require>,
L</his_line>, L</his_package>, L</his_sub>, L</his_subroutine>,
L</name_of_coderef>, L</NOT_REACHED>, L</%N_PLURAL>, L</panic>,
L</%PLURAL>, L</quotify_and>, L</quotify_but>, L</quotify_nor>,
L</quotify_or>, L</sig_name2num>, L</sig_num2longname>, L</sig_num2name>,
L</subname_or_code>, L</UCA>, L</UCA1>, L</uca1_cmp>, L</UCA2>,
L</uca2_cmp>, L</UCA3>, L</uca3_cmp>, L</UCA4>, L</uca4_cmp>,
L</uca_cmp>, and L</uca_sort>.

=item C<:acme_plurals>

L</%N_PLURAL> and L</%PLURAL>.

=item C<:botch>

L</botch>, L</botch_argc>, L</botch_array_length>, L</botch_false>,
L</botch_have_thing_wanted>, L</botch_undef>, and L</panic>.

=item C<:CALLER>

L</CALLER_BITMASK>, L</CALLER_EVALTEXT>, L</CALLER_FILENAME>,
L</CALLER_HASARGS>, L</CALLER_HINTHASH>, L</CALLER_HINTS>,
L</CALLER_IS_REQUIRE>, L</CALLER_LINE>, L</CALLER_PACKAGE>,
L</CALLER_SUBROUTINE>, and L</CALLER_WANTARRAY>.

=item C<:code>

L</code_of_coderef>, L</name_of_coderef>, and L</subname_or_code>.

=item C<:exports>

L</dump_exports> and L</dump_package_exports>.

=item C<:frame>

L</CALLER_BITMASK>, L</CALLER_EVALTEXT>, L</CALLER_FILENAME>,
L</CALLER_HASARGS>, L</CALLER_HINTHASH>, L</CALLER_HINTS>,
L</CALLER_IS_REQUIRE>, L</CALLER_LINE>, L</CALLER_PACKAGE>,
L</CALLER_SUBROUTINE>, L</CALLER_WANTARRAY>, L</his_args>,
L</his_assert>, L</his_context>, L</his_filename>, L</his_frame>,
L</his_is_require>, L</his_line>, L</his_package>, L</his_sub>, and
L</his_subroutine>.

=item C<:lint>

L</FIXME>, L</NOT_REACHED>, and L</panic>.

=item C<:list>

L</commify_and>, L</commify_but>, L</commify_nor>, L</commify_or>,
L</commify_series>, L</quotify_and>, L</quotify_but>, L</quotify_nor>,
L</quotify_or>, and L</uca_sort>.

=item C<:sigmappers>

L</sig_name2num>, L</sig_num2longname>, and L</sig_num2name>.

=item C<:unicode>

L</UCA>, L</UCA1>, L</uca1_cmp>, L</UCA2>, L</uca2_cmp>, L</UCA3>,
L</uca3_cmp>, L</UCA4>, L</uca4_cmp>, L</uca_cmp>, and L</uca_sort>.

=item C<:vars>

L</$Allow_Handlers>, L</$Assert_Always>, L</$Assert_Carp>,
L</$Assert_Debug>, and L</$Assert_Never>.

=back

=head2 Exported Functions

About the only thing here that's "public" is L</botch>
and the C<sig*> name-to-number mapping functions.
The rest are internal and shouldn't be relied on.

=over

=item C<botch($)>

The main way that assertions fail.  Normally it raises an exception
by calling C<Carp::confess>, but this can be controlled using the
C<ASSERT_CONDITIONAL> environment variable or its associated package
variables as previously described.

We crawl up the stack to find the I<highest> function named C<assert_*> to
use for the message. That way when an assertion calls another assertion and that
second one fails, the reported message uses the name of the first one.

=item C<botch_false()>

A way to panic if something is false but shouldn't be.

=item C<botch_undef()>

A way to panic if something is undef but shouldn't be.

=item C<botch_argc($$)>

=item C<botch_array_length($$)>

=item C<botch_have_thing_wanted(@)>

=item C<panic(I<MESSAGE>)>

This function is used for internal errors that should never happen.
It calls C<Carp::confess> with a prefix indicating that it is an
internal error.

=item C<FIXME>

Code you haven't gotten to yet.

=item C<NOT_REACHED>

Put this in places that you think you can never reach in your code.

=item C<his_assert()>

=item C<his_args(;$)>

=item C<his_frame(;$)>

=item C<his_package(;$)>

=item C<his_filename(;$)>

=item C<his_line(;$)>

=item C<his_subroutine(;$)>

=item C<his_sub(;$)>

=item C<his_context(;$)>

=item C<his_is_require(;$)>

=item C<code_of_coderef(I<CODEREF>)>

Return the code but not the name of the code reference passed.

=item C<name_of_coderef(I<CODEREF>)>

Return the name of the code reference passed.

=item C<subname_or_code(I<CODEREF>)>

Return the name of the code reference passed if it is not anonymous;
otherwise return its code.

=item C<commify_series>

=item C<dump_exports(@)>

=item C<dump_package_exports($@)>

=item C<UCA(_)>

=item C<UCA1(_)>

=item C<UCA2(_)>

=item C<UCA3(_)>

=item C<UCA4(_)>

=item C<uca_cmp($$)>

=item C<uca1_cmp($$)>

=item C<uca2_cmp($$)>

=item C<uca3_cmp($$)>

=item C<uca4_cmp($$)>

=item C<uca_sort(@)>

Return its argument list sorted alphabetically.

=item C<sig_num2name(I<NUMBER>)>

Returns the name of the signal number, like C<HUP>, C<INT>, etc.

=item C<sig_num2longname($)>

Returns the long name of the signal number, like C<SIGHUP>, C<SIGINT>, etc.

=item sub C<sig_name2num(I<NAME>)>

Returns the signal number corresponding to the passed in name.

=back

=head1 ENVIRONMENT

The C<ASSERT_CONDITIONAL> variable controls the behavior
of the C<botch> function, and also of the the conditional
importing itself.

The C<ASSERT_CONDITIONAL_BUILD_POD> variable is used internally.

=head1 SEE ALSO

The L<Assert::Conditional> module that uses these utilities
and
the L<Exporter::ConditionalSubs> module which that module is based on.

=head1 BUGS AND LIMITATIONS

Probably many.  This is an beta release.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015-2018 Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
