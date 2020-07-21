#!/usr/bin/env perl
# ^^^^^^ !!!!!! ^^^^^^^
# Yes, this module really is supposed to have a #!
# line and be an executable script. See the end of the file
# for why!

package Assert::Conditional;

use v5.12;
use utf8;
use strict;
use warnings;

use version 0.77;
our $VERSION = version->declare("0.010");

use parent "Exporter::ConditionalSubs";  # inherits from Exporter

use namespace::autoclean;

use Attribute::Handlers;
use Assert::Conditional::Utils ":all";
use Carp qw(carp croak cluck confess);
use POSIX ":sys_wait_h";

use Scalar::Util qw{
    blessed
    looks_like_number
    openhandle
    refaddr
    reftype
};

use Unicode::Normalize qw{
    NFC    checkNFC
    NFD    checkNFD
    NFKC   checkNFKC
    NFKD   checkNFKD
};

# But these are private internal functions that we
# choose not to expose even if fully qualified,
# and so declaring them here in front of the
# imminent namespace::clean will make sure of that.

 sub _coredump_message    ( ;$  ) ;
 sub _get_invocant_type   (  $  ) ;
 sub _promote_to_arrayref (  $  ) ;
 sub _promote_to_hashref  (  $  ) ;
 sub _promote_to_typeref  (  $$ ) ;
 sub _run_code_test       (  $$ ) ;
 sub _signum_message      (  $  ) ;
 sub _WIFCORED            ( ;$  ) ;

# Need to be able to measure coverage with Devel::Cover
# of stuff we would normally get rid of.
use if !$ENV{HARNESS_ACTIVE}, "namespace::clean";

#######################################################################

# First declare our Exporter vars:
our(@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

# Then thanks to this little guy....
sub  Assert;

# Now those have by now all been fully populated *during compilation*,
# so it only remains to re-collate them into pleasant alphabetic order:
@$_ = uca_sort @$_ for \@EXPORT_OK, values %EXPORT_TAGS;

sub  assert_ainta                             (  $@               ) ;
sub  assert_alnum                             (  $                ) ;
sub  assert_alphabetic                        (  $                ) ;
sub  assert_anyref                            (  $                ) ;
sub  assert_argc                              ( ;$                ) ;
sub  assert_argc_max                          (  $                ) ;
sub  assert_argc_min                          (  $                ) ;
sub  assert_argc_minmax                       (  $$               ) ;
sub  assert_array_length                      ( \@ ;$             ) ;
sub  assert_array_length_max                  ( \@ $              ) ;
sub  assert_array_length_min                  ( \@ $              ) ;
sub  assert_array_length_minmax               ( \@ $$             ) ;
sub  assert_array_nonempty                    ( \@                ) ;
sub  assert_arrayref                          (  $                ) ;
sub  assert_arrayref_nonempty                 (  $                ) ;
sub  assert_ascii                             (  $                ) ;
sub  assert_ascii_ident                       (  $                ) ;
sub  assert_astral                            (  $                ) ;
sub  assert_blank                             (  $                ) ;
sub  assert_bmp                               (  $                ) ;
sub  assert_box_number                        (  $                ) ;
sub  assert_bytes                             (  $                ) ;
sub  assert_can                               (  $@               ) ;
sub  assert_cant                              (  $@               ) ;
sub  assert_class_ainta                       (  $@               ) ;
sub  assert_class_can                         (  $@               ) ;
sub  assert_class_cant                        (  $@               ) ;
sub  assert_class_isa                         (  $@               ) ;
sub  assert_class_method                      (                   ) ;
sub  assert_coderef                           (  $                ) ;
sub  assert_defined                           (  $                ) ;
sub  assert_defined_value                     (  $                ) ;
sub  assert_defined_variable                  ( \$                ) ;
sub  assert_digits                            (  $                ) ;
sub  assert_directory                         (  $                ) ;
sub  assert_does                              (  $@               ) ;
sub  assert_doesnt                            (  $@               ) ;
sub  assert_dumped_core                       ( ;$                ) ;
sub  assert_empty                             (  $                ) ;
sub  assert_eq                                (  $$               ) ;
sub  assert_eq_letters                        (  $$               ) ;
sub  assert_even_number                       (  $                ) ;
sub  assert_exited                            ( ;$                ) ;
sub  assert_false                             (  $                ) ;
sub  assert_fractional                        (  $                ) ;
sub  assert_full_perl_ident                   (  $                ) ;
sub  assert_globref                           (  $                ) ;
sub  assert_happy_code                        (  &                ) ;
sub  assert_happy_exit                        ( ;$                ) ;
sub  assert_hash_keys                         ( \% @              ) ;
sub  assert_hash_keys_allowed                 ( \% @              ) ;
sub  assert_hash_keys_allowed_and_required    ( \% $ $            ) ;
sub  assert_hash_keys_required                ( \% @              ) ;
sub  assert_hash_keys_required_and_allowed    ( \% $ $            ) ;
sub  assert_hash_nonempty                     ( \%                ) ;
sub  assert_hashref                           (  $                ) ;
sub  assert_hashref_keys                      (  $@               ) ;
sub  assert_hashref_keys_allowed              (  $@               ) ;
sub  assert_hashref_keys_allowed_and_required (  $$$              ) ;
sub  assert_hashref_keys_required             (  $@               ) ;
sub  assert_hashref_keys_required_and_allowed (  $$$              ) ;
sub  assert_hashref_nonempty                  (  $                ) ;
sub  assert_hex_number                        (  $                ) ;
sub  assert_in_list                           (  $@               ) ;
sub  assert_in_numeric_range                  (  $$$              ) ;
sub  assert_integer                           (  $                ) ;
sub  assert_ioref                             (  $                ) ;
sub  assert_is                                (  $$               ) ;
sub  assert_isa                               (  $@               ) ;
sub  assert_isnt                              (  $$               ) ;
sub  assert_keys                              ( \[%$] @           ) ;
sub  assert_known_package                     (  $                ) ;
sub  assert_latin1                            (  $                ) ;
sub  assert_latinish                          (  $                ) ;
sub  assert_legal_exit_status                 ( ;$                ) ;
sub  assert_like                              (  $$               ) ;
sub  assert_list_context                      (                   ) ;
sub  assert_list_nonempty                     (  @                ) ;
sub  assert_locked                            ( \[%$] @           ) ;
sub  assert_lowercased                        (  $                ) ;
sub  assert_max_keys                          ( \[%$] @           ) ;
sub  assert_method                            (                   ) ;
sub  assert_min_keys                          ( \[%$] @           ) ;
sub  assert_minmax_keys                       ( \[%$] \[@$] \[@$] ) ;
sub  assert_multi_line                        (  $                ) ;
sub  assert_natural_number                    (  $                ) ;
sub  assert_negative                          (  $                ) ;
sub  assert_negative_integer                  (  $                ) ;
sub  assert_nfc                               (  $                ) ;
sub  assert_nfd                               (  $                ) ;
sub  assert_nfkc                              (  $                ) ;
sub  assert_nfkd                              (  $                ) ;
sub  assert_no_coredump                       ( ;$                ) ;
sub  assert_nonalphabetic                     (  $                ) ;
sub  assert_nonascii                          (  $                ) ;
sub  assert_nonastral                         (  $                ) ;
sub  assert_nonblank                          (  $                ) ;
sub  assert_nonbytes                          (  $                ) ;
sub  assert_nonempty                          (  $                ) ;
sub  assert_nonlist_context                   (                   ) ;
sub  assert_nonnegative                       (  $                ) ;
sub  assert_nonnegative_integer               (  $                ) ;
sub  assert_nonnumeric                        (  $                ) ;
sub  assert_nonobject                         (  $                ) ;
sub  assert_nonpositive                       (  $                ) ;
sub  assert_nonpositive_integer               (  $                ) ;
sub  assert_nonref                            (  $                ) ;
sub  assert_nonvoid_context                   (                   ) ;
sub  assert_nonzero                           (  $                ) ;
sub  assert_not_in_list                       (  $@               ) ;
sub  assert_numeric                           (  $                ) ;
sub  assert_object                            (  $                ) ;
sub  assert_object_ainta                      (  $@               ) ;
sub  assert_object_boolifies                  (  $                ) ;
sub  assert_object_can                        (  $@               ) ;
sub  assert_object_cant                       (  $@               ) ;
sub  assert_object_isa                        (  $@               ) ;
sub  assert_object_method                     (                   ) ;
sub  assert_object_nummifies                  (  $                ) ;
sub  assert_object_overloads                  (  $@               ) ;
sub  assert_object_stringifies                (  $                ) ;
sub  assert_odd_number                        (  $                ) ;
sub  assert_open_handle                       (  $                ) ;
sub  assert_positive                          (  $                ) ;
sub  assert_positive_integer                  (  $                ) ;
sub  assert_private_method                    (                   ) ;
sub  assert_protected_method                  (                   ) ;
sub  assert_public_method                     (                   ) ;
sub  assert_qualified_ident                   (  $                ) ;
sub  assert_refref                            (  $                ) ;
sub  assert_reftype                           (  $$               ) ;
sub  assert_regex                             (  $                ) ;
sub  assert_regular_file                      (  $                ) ;
sub  assert_sad_exit                          ( ;$                ) ;
sub  assert_scalar_context                    (                   ) ;
sub  assert_scalarref                         (  $                ) ;
sub  assert_signalled                         ( ;$                ) ;
sub  assert_signed_number                     (  $                ) ;
sub  assert_simple_perl_ident                 (  $                ) ;
sub  assert_single_line                       (  $                ) ;
sub  assert_single_paragraph                  (  $                ) ;
sub  assert_text_file                         (  $                ) ;
sub  assert_tied                              ( \[$@%*]           ) ;
sub  assert_tied_array                        ( \@                ) ;
sub  assert_tied_arrayref                     (  $                ) ;
sub  assert_tied_glob                         ( \*                ) ;
sub  assert_tied_globref                      (  $                ) ;
sub  assert_tied_hash                         ( \%                ) ;
sub  assert_tied_hashref                      (  $                ) ;
sub  assert_tied_referent                     (  $                ) ;
sub  assert_tied_scalar                       ( \$                ) ;
sub  assert_tied_scalarref                    (  $                ) ;
sub  assert_true                              (  $                ) ;
sub  assert_unblessed_ref                     (  $                ) ;
sub  assert_undefined                         (  $                ) ;
sub  assert_unhappy_code                      (  &                ) ;
sub  assert_unicode_ident                     (  $                ) ;
sub  assert_unlike                            (  $$               ) ;
sub  assert_unlocked                          ( \[%$] @           ) ;
sub  assert_unsignalled                       ( ;$                ) ;
sub  assert_untied                            ( \[$@%*]           ) ;
sub  assert_untied_array                      ( \@                ) ;
sub  assert_untied_arrayref                   (  $                ) ;
sub  assert_untied_glob                       ( \*                ) ;
sub  assert_untied_globref                    (  $                ) ;
sub  assert_untied_hash                       ( \%                ) ;
sub  assert_untied_hashref                    (  $                ) ;
sub  assert_untied_referent                   (  $                ) ;
sub  assert_untied_scalar                     ( \$                ) ;
sub  assert_untied_scalarref                  (  $                ) ;
sub  assert_uppercased                        (  $                ) ;
sub  assert_void_context                      (                   ) ;
sub  assert_whole_number                      (  $                ) ;
sub  assert_wide_characters                   (  $                ) ;
sub  assert_zero                              (  $                ) ;
############################################################

sub import {
    my ($package, @conditional_imports) = @_;
    my @normal_imports = $package->_strip_import_conditions(@conditional_imports);
    if    ($Assert_Never)  { $package->SUPER::import(@normal_imports, -if => 0) }
    elsif ($Assert_Always) { $package->SUPER::import(@normal_imports, -if => 1) }
    else                   { $package->SUPER::import(@conditional_imports     ) }
    $package->_reimport_nulled_code_protos();
}

# This is just pretty extreme, but it's also about the only way to
# make the Exporter shut up about things we sometimes need to do in
# this module.
#
# Well, not quite the only way: there's always local *SIG. :)
#
# Otherwise it dribbles all over your screen when you try more than one
# import, like importing a set and then reneging on a few of them.
# 
# Newer versions of Carp appear not to need these heroics.

sub export_to_level {
    my($package, $level, @export_args) = @_;

    state $old_carp = \&Carp::carp;
    state $filters = [
        qr/^Constant subroutine \S+ redefined/,
        qr/^Subroutine \S+ redefined/,
        qr/^Prototype mismatch:/,
    ];

    no warnings "redefine";
    local *Carp::carp = sub {
        my($text) = @_;
        $text =~ $_ && return for @$filters;
        local $Carp::CarpInternal{"Exporter::Heavy"} = 1;
        $old_carp->($text);
    };
    $package->SUPER::export_to_level($level+2, @export_args);
}

# You have to do this if you have asserts that take a code
# ref as their first argument and people want to use those
# without parentheses. That's because the constant subroutine
# that gets installed necessarily no longer has the prototype
# needed to support a code ref in the dative slot syntactically.
sub _reimport_nulled_code_protos {
    my($my_pack) = @_;
    my $his_pack = caller(1);

    no strict "refs";

    for my $export (@{$my_pack . "::EXPORT_OK"}) {
        my $real_proto = prototype($my_pack . "::$export");
        $real_proto && $real_proto =~ /^\s*&/           || next;
        my $his_func = $his_pack . "::$export";
        defined &$his_func                              || next;
        prototype($his_func)                            && next;
        eval qq{
            no warnings qw(prototype redefine);
            package $his_pack;
            sub $export ($real_proto) { 0 }
            1;
        } || panic "eval failed";
    }
}

# Remove the trailing -if/-unless from the conditional
# import list.
sub _strip_import_conditions {
    my($package, @args) = @_;
    my @export_args;
    while (@args && ($args[0] || '') !~ /^-(?:if|unless)$/) {
        push @export_args, shift @args;
    }
    return @export_args;
}

################################################################
# The following attribute handler handler for subs saves
# us a lot of bookkeeping trouble by letting us declare
# which export tag groups a particular assert belongs to
# at the point of declaration where it belongs, and so
# that it is all handled automatically.
################################################################
sub Assert : ATTR(CODE,BEGIN)
{
    my($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    no strict "refs";
    my($subname, $tagref) = (*{$symbol}{NAME}, $data);
    $subname =~ /^assert_/
        || panic "$subname is not an assertion";

    my $his_export_ok = $package . "::EXPORT_OK";
    push @$his_export_ok, $subname;

    my $debugging = $Exporter::Verbose || $Assert_Debug;

    carp "Adding $subname to EXPORT_OK in $package at ",__FILE__," line ",__LINE__ if $debugging;

    if (defined($tagref) && !ref($tagref)) {
        $tagref = [ $tagref ];
    }
    my $his_export_tags = $package . "::EXPORT_TAGS";
    for my $tag (@$tagref, qw(all asserts)) {
        push @{ $his_export_tags->{$tag} }, $subname;
        carp "Adding $subname to EXPORT_TAG :$tag in $package at ",__FILE__," line ",__LINE__ if $debugging;
    }
}

################################################################

# Subs below are grouped by related type. Their documentation is
# in the sub <DATA> pod.

sub assert_list_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    $wantarray                  || botch "wanted to be called in list context";
}

sub assert_nonlist_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    !$wantarray                 || botch "wanted to be called in nonlist context";
}

sub assert_scalar_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    defined($wantarray) && !$wantarray
        || botch "wanted to be called in scalar context";
}

sub assert_void_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    !defined($wantarray)        || botch "wanted to be called in void context";
}

sub assert_nonvoid_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    defined($wantarray)        || botch "wanted to be called in nonvoid context";
}

sub assert_true($)
    :Assert( qw[scalar boolean] )
{
    my($arg) = @_;
    $arg                        || botch "expected true argument";
}

sub assert_false($)
    :Assert( qw[scalar boolean] )
{
    my($arg) = @_;
    $arg                        && botch "expected true argument";

}

sub assert_defined($)
    :Assert( qw[scalar] )
{
    my($value) = @_;
    defined($value)            || botch "expected defined value as argument";
}

sub assert_undefined($)
    :Assert( qw[scalar] )
{
    my($scalar) = @_;
    defined($scalar) && botch "expected undefined argument";
}

sub assert_defined_variable(\$)
    :Assert( qw[scalar] )
{
    &assert_scalarref;
    my($sref) = @_;
    defined($$sref)            || botch "expected defined scalar variable as argument";
}

sub assert_defined_value($)
    :Assert( qw[scalar] )
{
    my($value) = @_;
    defined($value)            || botch "expected defined value as argument";
}

sub assert_is($$)
    :Assert( qw[string] )
{
    my($this, $that) = @_;
    assert_defined($_) for $this, $that;
    assert_nonref($_)  for $this, $that;
    $this eq $that              || botch "string '$this' should be '$that'";
}

sub assert_isnt($$)
    :Assert( qw[string] )
{
    my($this, $that) = @_;
    assert_defined($_) for $this, $that;
    assert_nonref($_) for $this, $that;
    $this ne $that              || botch "string '$this' should not be '$that'";
}

sub assert_numeric($)
    :Assert( qw[number] )
{
    &assert_defined;
    &assert_nonref;
    my($n) = @_;
    looks_like_number($n)       || botch "'$n' doesn't look like a number";
}

sub assert_nonnumeric($)
    :Assert( qw[number] )
{
    &assert_nonref;
    my($n) = @_;
   !looks_like_number($n)       || botch "'$n' looks like a number";
}

sub assert_positive($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n > 0                     || botch "$n should be positive";
}

sub assert_nonpositive($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n <= 0                    || botch "$n should not be positive";
}

sub assert_negative($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n < 0                     || botch "$n should be negative";
}

sub assert_nonnegative($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n >= 0                     || botch "$n should not be negative";
}

sub assert_zero($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n == 0                     || botch "$n should be zero";
}

sub assert_nonzero($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n != 0                     || botch "$n should not be zero";
}

sub assert_integer($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($int) = @_;
    $int == int($int)              || botch "expected integer, not $int";
}

sub assert_fractional($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($float) = @_;
    $float != int($float)          || botch "expected fractional part, not $float";
}

sub assert_signed_number($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n =~ /^ [-+] /x             || botch "expected signed number, not $n";
}

sub assert_natural_number($)
    :Assert( qw[number] )
{
    &assert_positive_integer;
    my($int) = @_;
}

sub assert_whole_number($)
    :Assert( qw[number] )
{
    &assert_nonnegative_integer;
    my($int) = @_;
}

sub assert_positive_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_positive;
}

sub assert_nonpositive_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_nonpositive;
}

sub assert_negative_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_negative;
}

sub assert_nonnegative_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_nonnegative;
}

sub assert_hex_number($)
    :Assert( qw[regex number] )
{
    local($_) = @_;
    /^ (?:0x)? \p{ahex}+ \z/ix    || botch "expected only ASCII hex digits in string '$_'";
}

sub assert_box_number($)
    :Assert( qw[number] )
{
    local($_) = @_;
    &assert_defined;
    /^ (?: 0b )     [0-1]+       \z /x  ||
    /^ (?: 0o | 0)? [0-7]+       \z /x  ||
    /^ (?: 0x )     [0-9a-fA-F]+ \z /x
        || botch "I wouldn't feed '$_' to oct() if I were you";
}

sub assert_even_number($)
    :Assert( qw[number] )
{
    &assert_integer;
    my($n) = @_;
    $n % 2 == 0                 || botch "$n should be even";
}

sub assert_odd_number($)
    :Assert( qw[number] )
{
    &assert_integer;
    my($n) = @_;
    $n % 2 == 1                 || botch "$n should be odd";
}

sub assert_in_numeric_range($$$)
    :Assert( qw[number] )
{
    assert_numeric($_) for my($n, $low, $high) = @_;
    $n >= $low && $n <= $high   || botch "expected $low <= $n <= $high";
}

sub assert_empty($)
    :Assert( qw[string] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    length($string) == 0        || botch "expected zero-length string";
}

sub assert_nonempty($)
    :Assert( qw[string] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    length($string) != 0        || botch "expected non-zero-length string";
}

sub assert_blank($)
    :Assert( qw[string regex] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    $string =~ /^ \p{whitespace}* \z/x     || botch "found non-whitespace in string '$string'"
}

sub assert_nonblank($)
    :Assert( qw[string regex] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    $string =~ / \P{whitespace}/x       || botch "found no non-whitespace in string '$string'"
}

my $_single_line_rx = qr{
    \A
    ( (?! \R ) \X )+
    \R ?
    \z
}x;

sub assert_single_line($)
    :Assert( qw[string regex] )
{
    &assert_nonempty;
    my($string) = @_;
    $string =~ $_single_line_rx         || botch "expected at most a single linebreak at the end";
}

sub assert_multi_line($)
    :Assert( qw[string regex] )
{
    &assert_nonempty;
    my($string) = @_;
    $string !~ $_single_line_rx         || botch "expected more than one linebreak";
}

sub assert_single_paragraph($)
    :Assert( qw[string regex] )
{
    &assert_nonempty;
    my($string) = @_;
    $string =~ / \A ( (?! \R ) \X )+ \R* \z /x
                                        || botch "expected at most a single linebreak at the end";
}

sub assert_bytes($)
    :Assert( qw[string] )
{
    local($_) = @_;
    /^ [\x00-\xFF] + \z/x      || botch "unexpected wide characters in byte string";
}

sub assert_nonbytes($)
    :Assert( qw[string] )
{
    &assert_wide_characters;
}

sub assert_wide_characters($)
    :Assert( qw[string] )
{
    local($_) = @_;
    /[^\x00-\xFF]/x             || botch "expected some wide characters in string";
}

sub assert_nonascii($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /\P{ascii}/x                || botch "expected non-ASCII in string";
}

sub assert_ascii($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \p{ASCII} + \z/x        || botch "expected only ASCII in string";
}

sub assert_alphabetic($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \p{alphabetic} + \z/x        || botch "expected only alphabetics in string";
}

sub assert_nonalphabetic($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \P{alphabetic} + \z/x        || botch "expected only non-alphabetics in string";
}

sub assert_alnum($)
    :Assert( qw[regex] )
{
    local($_) = @_;
    /^ \p{alnum} + \z/x        || botch "expected only alphanumerics in string";
}

sub assert_digits($)
    :Assert( qw[regex number] )
{
    local($_) = @_;
    /^ [0-9] + \z/x           || botch "expected only ASCII digits in string";
}

sub assert_uppercased($)
    :Assert( qw[case regex] )
{
    local($_) = @_;
    ($] >= 5.014
        ?  ! /\p{Changes_When_Uppercased}/
        :  $_ eq uc )                 || botch "changes case when uppercased";
}

sub assert_lowercased($)
    :Assert( qw[case regex] )
{
    local($_) = @_;
    ($] >= 5.014
        ?  ! /\p{Changes_When_Lowercased}/
        :  $_ eq lc )                 || botch "changes case when lowercased";
}

sub assert_unicode_ident($)
    :Assert( qw[regex] )
{
    local($_) = @_;
    /^ \p{XID_Start} \p{XID_Continue}* \z/x
                               || botch "invalid identifier $_";
}

# This is a lie.
my $perl_simple_ident_rx = qr{
    \b
    [\p{gc=Connector_Punctuation}\p{XID_Start}]
    \p{XID_Continue} *+
    \b
}x;

my $perl_qualified_ident_rx = qr{
    (?: $perl_simple_ident_rx
      | (?: :: | ' )
    ) +
}x;

sub assert_simple_perl_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ $perl_simple_ident_rx \z/x
                                || botch "invalid simple perl identifier $_";
}

sub assert_full_perl_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ $perl_qualified_ident_rx \z/x
                                || botch "invalid qualified perl identifier $_";
}

sub assert_qualified_ident($)
    :Assert( qw[regex ident] )
{
    &assert_full_perl_ident;
    local($_) = @_;
    /(?: ' | :: ) /x           || botch "no package separators in $_";
}

sub assert_ascii_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ (?= \p{ASCII}+ \z) (?! \d) \w+ \z/x
                                || botch q(expected only ASCII \\w characters in string);
}

sub assert_regex($)
    :Assert( qw[regex] )
{
    my($pattern) = @_;
    assert_isa($pattern, "Regexp");
}

sub assert_like($$)
    :Assert( qw[regex] )
{
    my($string, $pattern) = @_;
    assert_defined($string);
    assert_nonref($string);
    assert_regex($pattern);
    $string =~ $pattern         || botch "'$string' did not match $pattern";
}

sub assert_unlike($$)
    :Assert( qw[regex] )
{
    my($string, $pattern) = @_;
    assert_defined($string);
    assert_nonref($string);
    assert_regex($pattern);
    $string !~ $pattern         || botch "'$string' should not match $pattern";
}

sub assert_latin1($)
    :Assert( qw[string unicode] )
{
    &assert_bytes;
}

sub assert_latinish($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    /^[\p{Latin}\p{Common}\p{Inherited}]+/
                                    || botch "expected only Latinish characters in string";
}

sub assert_astral($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    no warnings "utf8";  # early versions of perl complain of illegal for interchange on FFFF
    /[^\x00-\x{FFFF}]/x            || botch "expected non-BMP characters in string";
}

sub assert_nonastral($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    no warnings "utf8";  # early versions of perl complain of illegal for interchange on FFFF
    /^ [\x00-\x{FFFF}] * \z/x      || botch "unexpected non-BMP characters in string";
}

sub assert_bmp($)
    :Assert( qw[unicode] )
{
    &assert_nonastral;
}

sub assert_nfc($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFC($str) // $str eq NFC($str)
                                || botch "string not in NFC form";
}

sub assert_nfkc($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFKC($str) // $str eq NFKC($str)
                                || botch "string not in NFKC form";
}

sub assert_nfd($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFD($str)              || botch "string not in NFD form";
}

sub assert_nfkd($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFKD($str)              || botch "string not in NFKD form";
}

sub assert_eq($$)
    :Assert( qw[string unicode] )
{
    my($this, $that) = @_;
    NFC($this) eq NFC($that)    || botch "'$this' and '$that' are not equivalent Unicode strings";
}

sub assert_eq_letters($$)
    :Assert( qw[string unicode] )
{
    my($this, $that) = @_;
    UCA1($this) eq UCA1($that)  || botch "'$this' and '$that' do not equivalent letters"
}

sub assert_in_list($@)
    :Assert( qw[list] )
{
    my($needle, @haystack) = @_;
    #assert_nonref($needle);
    my $undef_needle = !defined($needle);
    for my $straw (@haystack) {
        #assert_nonref($straw);
        return if $undef_needle
            ? !defined($straw)
            : ("$needle" eq (defined($straw) && "$straw"))
    }
    $needle = "undef" unless defined $needle;
    botch "couldn't find $needle in " . join(", " => map { defined() ? $_ : "undef" } @haystack);
}

sub assert_not_in_list($@)
    :Assert( qw[list] )
{
    my($needle, @haystack) = @_;
    my $found = 0;
    for my $straw (@haystack) {
        if (defined $needle) {
            next if !defined $straw;
            if ("$needle" eq "$straw") {
                $found = 1;
                last;
            }
        } else {
            next if defined $straw;
            $found = 1;
            last;
        }
    }
    return unless $found;
    $needle = "undef" unless defined $needle;
    botch "found $needle in forbidden list";
}

sub assert_list_nonempty( @ )
    :Assert( qw[list array] )
{
    @_                          || botch "list is empty";
}

sub assert_array_nonempty( \@ )
    :Assert( qw[array] )
{
    &assert_arrayref_nonempty;
}

sub assert_arrayref_nonempty( $ )
    :Assert( qw[array] )
{
    &assert_array_length;
    my($aref) = @_;
    assert_arrayref($aref);
    my $count = @$aref;
    $count > 0  || botch("array is empty");
}

sub assert_array_length( \@ ;$ )
    :Assert( qw[array] )
{
    if (@_ == 1) {
        assert_array_length_min(@{$_[0]} => 1);
        return;
    }
    my($aref, $want) = @_;
    assert_arrayref($aref);
    assert_whole_number($want);
    my $have  = @$aref;
    $have == $want            || botch_array_length($have, $want);
}

sub assert_array_length_min( \@ $ )
    :Assert( qw[array] )
{
    my($aref, $want) = @_;
    assert_arrayref($aref);
    assert_whole_number($want);
    my $have = @$aref;
    $have >= $want            || botch_array_length($have, "$want or more");
}

sub assert_array_length_max( \@ $ )
    :Assert( qw[array] )
{
    my($aref, $want) = @_;
    assert_arrayref($aref);
    assert_whole_number($want);
    my $have = @$aref;
    $have <= $want            || botch_array_length($have, "$want or fewer");
}

sub assert_array_length_minmax( \@ $$)
    :Assert( qw[array] )
{
    my($aref, $low, $high) = @_;
    my $have = @$aref;
    assert_whole_number($_) for $low, $high;
    $have >= $low && $have <= $high
                                || botch_array_length($have, "between $low and $high");
}

sub assert_argc(;$)
    :Assert( qw[argc] )
{
    unless (@_) {
        his_args                || botch_argc(0, "at least 1");
        return;
    }
    &assert_whole_number;
    my($want) = @_;
    my $have = his_args;
    $have == $want              || botch_argc($have, $want);
}

sub assert_argc_min($)
    :Assert( qw[argc] )
{
    &assert_whole_number;
    my($want) = @_;
    my $have = his_args;
    $have >= $want              || botch_argc($have, "$want or more");
}

sub assert_argc_max($)
    :Assert( qw[argc] )
{
    &assert_whole_number;
    my($want) = @_;
    my $have = his_args;
    $have <= $want             || botch_argc($have, "$want or fewer");
}

sub assert_argc_minmax($$)
    :Assert( qw[argc] )
{
    assert_whole_number($_) for my($low, $high) = @_;
    my $have = his_args;
    $have >= $low && $have <= $high
        || botch_argc($have, "between $low and $high");
}

sub assert_hash_nonempty(\%)
    :Assert( qw[hash] )
{
    &assert_hashref_nonempty;
}

sub assert_hashref_nonempty($)
    :Assert( qw[hash] )
{
    &assert_hashref;
    my($href) = @_;
    %$href                      || botch "hash is empty";
}

sub assert_hash_keys(\% @)
    :Assert( qw[hash] )
{
    &assert_hashref_keys;
}

sub assert_hash_keys_required(\% @)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_required;
}

sub assert_hash_keys_allowed(\% @)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_allowed;
}

sub assert_hash_keys_required_and_allowed(\% $ $)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_required_and_allowed;
}

sub assert_hash_keys_allowed_and_required(\% $ $)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_allowed_and_required;
}

sub assert_hashref_keys($@)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_required;
}

sub assert_hashref_keys_required($@)
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    assert_min_keys($hashref, @keylist);
}

sub assert_hashref_keys_allowed($@)
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    assert_max_keys($hashref, @keylist);
}

sub _promote_to_typeref($$) {
    my(undef, $type) = @_;
    &assert_anyref;
    $_[0] = ${ $_[0] } if (reftype($_[0]) // "") =~ /^ (?: SCALAR | REF ) \z/x;
    assert_reftype($type, $_[0]);
}

sub _promote_to_hashref ($) { _promote_to_typeref($_[0], "HASH")  }
sub _promote_to_arrayref($) { _promote_to_typeref($_[0], "ARRAY") }

sub assert_min_keys( \[%$] @ )
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    _promote_to_hashref($hashref);
    @keylist                            || botch "no min keys given";

    my @missing = grep { !exists $hashref->{$_} } @keylist;
    return unless @missing;

    my $message = "key" . (@missing > 1 && "s") . " "
                . quotify_and(uca_sort @missing)
                . " missing from hash";

    botch $message;
}

sub assert_max_keys( \[%$] @ )
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    _promote_to_hashref($hashref);
    my %allowed = map { $_ => 1 } @keylist;
    my @forbidden;
    for my $key (keys %$hashref) {
        delete $allowed{$key} || push @forbidden, $key;
    }
    return unless @forbidden;

    my $message = "key" . (@forbidden > 1 && "s") . " "
                        . quotify_and(uca_sort @forbidden)
                        . " forbidden in hash";

    botch $message;
}

sub assert_minmax_keys( \[%$] \[@$] \[@$] )
    :Assert( qw[hash] )
{
    my($hashref, $minkeys, $maxkeys) = @_;
    _promote_to_hashref($hashref);
    _promote_to_arrayref($minkeys);
    @$minkeys || botch "no min keys given";
    _promote_to_arrayref($maxkeys);
    @$maxkeys || botch "no max keys given";

    my @forbidden;
    my %required = map { $_ => 1 } @$minkeys;
    my %allowed  = map { $_ => 1 } @$maxkeys;

    for my $key (keys %$hashref) {
        delete $required{$key};
        delete $allowed{$key} || push @forbidden, $key;
    }
    my @missing = keys %required;

    return unless @missing || @forbidden;

    my $missing_msg = !@missing ? "" :
        "key" . (@missing > 1 && "s") . " "
              . quotify_and(uca_sort @missing)
              . " missing from hash";

    my $forbidden_msg = !@forbidden ? "" :
        "key" . (@forbidden > 1 && "s") . " "
              . quotify_and(uca_sort @forbidden)
              . " forbidden in hash";

    my $message = commify_and grep { length } $missing_msg, $forbidden_msg;
    botch $message;
}

sub assert_keys( \[%$] @ )
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    _promote_to_hashref($hashref);
    assert_minmax_keys($hashref, @keylist, @keylist);
}

sub assert_hashref_keys_required_and_allowed($$$)
    :Assert( qw[hash] )
{
    my($hashref, $required, $allowed) = @_;
    assert_minmax_keys($hashref, $required, $allowed);
}

sub assert_hashref_keys_allowed_and_required($$$)
    :Assert( qw[hash] )
{
    my($hashref, $allowed, $required) = @_;
    assert_minmax_keys($hashref, $required, $allowed);
}


# From perl5180delta, you couldn't actually get any use of
# the predicates to check whether a hash or hashref was
# locked because even though they were exported those
# function did not exist before.!
##
## * Hash::Util has been upgraded to 0.15.
##
##   "hash_unlocked" and "hashref_unlocked" now returns true if the hash
##   is unlocked, instead of always returning false [perl #112126].
##
##   "hash_unlocked", "hashref_unlocked", "lock_hash_recurse" and
##   "unlock_hash_recurse" are now exportable [perl #112126].
##
##   Two new functions, "hash_locked" and "hashref_locked", have been
##   added. Oddly enough, these two functions were already exported,
##   even though they did not exist [perl #112126].

BEGIN {
    use Hash::Util qw{hash_locked};

    my $want_version = 0.15;
    my $have_version = Hash::Util->VERSION;
    my $huv          = "v$have_version of Hash::Util and we need";
    my $compiling    = "compiling assert_lock and assert_unlocked because your perl $^V has";
    my $debugging    = $Exporter::Verbose || $Assert_Debug;

    if ($have_version < $want_version) {
        carp "Not $compiling only $huv v$want_version at ", __FILE__, " line ", __LINE__ if $debugging;
    } else {
        carp   "\u$compiling $huv only v$want_version at ", __FILE__, " line ", __LINE__ if $debugging;

        confess "compilation eval blew up: $@" unless eval <<'END_OF_LOCK_STUFF';

            sub assert_locked( \[%$] @ )
                :Assert( qw[hash] )
            {
                my($hashref) = @_;
                _promote_to_hashref($hashref);
                hash_locked(%$hashref)    || botch "hash is locked";
            }

            sub assert_unlocked( \[%$] @ )
                :Assert( qw[hash] )
            {
                my($hashref) = @_;
                _promote_to_hashref($hashref);
               !hash_locked(%$hashref)    || botch "hash is not locked";
            }

            1;

END_OF_LOCK_STUFF
    }
}

sub assert_anyref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
    ref($arg)                   || botch "expected reference argument";
}

sub assert_nonref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
   !ref($arg)                   || botch "expected nonreference argument";
}

sub assert_reftype($$)
    :Assert( qw[object ref] )
{
    my($want_type, $arg) = @_;
    my $have_type = reftype($arg) // "non-reference";
    $have_type eq $want_type      || botch "expected reftype of $want_type not $have_type";
}

sub assert_globref($)
    :Assert( qw[glob ref] )
{
    my($arg) = @_;
    assert_reftype(GLOB => $arg);
}

sub assert_ioref($)
    :Assert( qw[io ref] )
{
    my($arg) = @_;
    assert_reftype(IO => $arg);
}

sub assert_coderef($)
    :Assert( qw[code ref] )
{
    my($arg) = @_;
    assert_reftype(CODE => $arg);
}

sub assert_hashref($)
    :Assert( qw[hash ref] )
{
    my($arg) = @_;
    assert_reftype(HASH => $arg);
}

sub assert_arrayref($)
    :Assert( qw[array ref] )
{
    my($arg) = @_;
    assert_reftype(ARRAY => $arg);
}

sub assert_refref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
    assert_reftype(REF => $arg);
}

sub assert_scalarref($)
    :Assert( qw[scalar ref] )
{
    my($arg) = @_;
    assert_reftype(SCALAR => $arg);
}

sub assert_unblessed_ref($)
    :Assert( qw[ref object] )
{
    &assert_anyref;
    &assert_nonobject;
}

sub assert_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "invocant missing from method invoked as subroutine";
}

sub assert_object_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "no invocant found";
    my($self) = his_args;
    blessed($self)              || botch "object method invoked as class method";
}

sub assert_class_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "no invocant found";
    my($class) = his_args;
   !blessed($class)             || botch "class method invoked as object method";
}

# This one is a no-op!
sub assert_public_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "invocant missing from public method invoked as subroutine";
}

my %skip_caller = map { $_ => 1 } qw(
    Class::MOP::Method::Wrapped
    Moose::Meta::Method::Augmented
);

# And this one isn't *all* that hard... relatively speaking.
sub assert_private_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "invocant missing from private method invoked as subroutine";

    my $frame = 0;
    my @to    = caller $frame++;

    my @from = caller $frame++;
    while (@from && $skip_caller{ $from[CALLER_PACKAGE] }) {
        @from = caller $frame++;
    }

    my $msg = "private sub &$from[CALLER_SUBROUTINE] called from";
    @from || botch "ran out of stack while inspecting $msg";

    my @botches;

    $from[CALLER_PACKAGE]  eq $to[CALLER_PACKAGE]
        || push @botches, "alien package $from[CALLER_PACKAGE]" ;

    $from[CALLER_FILENAME]  eq $to[CALLER_FILENAME]
        || push @botches, "alien file $from[CALLER_FILENAME] line $from[CALLER_LINE]";

    @botches == 0
        || botch "$msg " . join(" at " => @botches);

}

# But this one? This one is RIDICULOUS. O Moose how we hates you
# foreverz for ruining perl's simple inheritance model and its export
# model and its import model and its package model till the end of time!
sub assert_protected_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "invocant missing from protected method invoked as subroutine";

    my $self;  # sic, no assignment
    my $frame = 0;

    my $next_frame = sub {
        package DB;
        our @args;
        my @frame = caller(1 + $frame++);
        $self = $args[0] // "undef";
        $self = "undef" if ref $self && !Scalar::Util::blessed($self);
        return @frame;
    };

    my @to   = $next_frame->();
    my @from = $next_frame->();
    while (@from && $skip_caller{ $from[CALLER_PACKAGE] }) {
        @from = $next_frame->();
    }

    my $msg = "protected sub &$from[CALLER_SUBROUTINE]";
    @from || botch "ran out of stack while inspecting $msg";

    (
                        $from[CALLER_PACKAGE]
                   ->isa( $to[CALLER_PACKAGE] )
        || $self->DOES( $from[CALLER_PACKAGE] )
    )   || botch join " " => ($msg,
               "called from unfriendly package"
                     => $from[CALLER_PACKAGE],
                at   => $from[CALLER_FILENAME],
                line => $from[CALLER_LINE]
           );

}

sub assert_known_package($)
    :Assert( qw[object ident] )
{
    &assert_nonempty;
    my($arg) = @_;
    my $stash = do { no strict "refs"; \%{ $arg . "::" } };
    no overloading;
    %$stash                     || botch "unknown package $arg";
}

sub assert_object($)
    :Assert( qw[object] )
{
    no overloading;
    &assert_anyref;
    my($arg) = @_;
    blessed($arg)               || botch "expected blessed referent not $arg";
}

sub assert_nonobject($)
    :Assert( qw[object] )
{
    no overloading;
    my($arg) = @_;
   !blessed($arg)               || botch "expected unblessed referent not $arg";
}

sub _get_invocant_type($) {
    my($invocant) = @_;
    my $type;
    if (blessed $invocant) {
        $type = "object";
    } else {
        $type = "package";
    }
    return $type;
}

sub assert_can($@)
    :Assert( qw[object] )
{
    no overloading;
    my($invocant, @methods) = @_;
    @methods                            || botch "need one or more methods to check against";
    my $type = _get_invocant_type $invocant;
    my @cant = grep { !$invocant->can($_) } @methods;
    return unless @cant;

    my $message = "cannot invoke method"
                . (@cant > 1 && "s") . " "
                . quotify_or(uca_sort @cant)
                . " on $type $invocant";

    botch $message;
}

sub assert_cant($@)
    :Assert( qw[object] )
{
    no overloading;
    my($invocant, @methods) = @_;
    @methods                            || botch "need one or more methods to check against";
    my $type = _get_invocant_type $invocant;
    my @can = grep { $invocant->can($_) } @methods;
    return unless @can;

    my $message = "should not be able to invoke method"
                . (@can > 1 && "s") . " "
                . quotify_or(uca_sort @can)
                . " on $type $invocant";

    botch $message;
}

sub assert_object_can($@)
    :Assert( qw[object] )
{
    my($instance, @methods) = @_;
    assert_object($instance);
    assert_can($instance, @methods);
}

sub assert_object_cant($@)
    :Assert( qw[object] )
{
    my($instance, @methods) = @_;
    assert_object($instance);
    assert_cant($instance, @methods);
}

sub assert_class_can($@)
    :Assert( qw[object] )
{
    my($class, @methods) = @_;
    assert_known_package($class);
    assert_can($class, @methods);
}

sub assert_class_cant($@)
    :Assert( qw[object] )
{
    my($class, @methods) = @_;
    assert_known_package($class);
    assert_cant($class, @methods);
}

sub assert_isa($@)
    :Assert( qw[object] )
{
    my($subclass, @superclasses) = @_;
    @superclasses                       || botch "needs one or more superclasses to check against";
    my $type = _get_invocant_type $subclass;
    my @ainta = grep { !$subclass->isa($_) } @superclasses;
    !@ainta || botch "your $subclass $type should be a subclass of " . commify_and(uca_sort @ainta);
}

sub assert_ainta($@)
    :Assert( qw[object] )
{
    no overloading;

    my($subclass, @superclasses) = @_;
    @superclasses                       || botch "needs one or more superclasses to check against";
    my $type = _get_invocant_type $subclass;
    my @isa = grep { $subclass->isa($_) } @superclasses;
    !@isa || botch "your $subclass $type should not be a subclass of " . commify_or(uca_sort @isa);
}

sub assert_object_isa($@)
    :Assert( qw[object] )
{
    my($instance, @superclasses) = @_;
    assert_object($instance);
    assert_isa($instance, @superclasses);
}

sub assert_object_ainta($@)
    :Assert( qw[object] )
{
    my($instance, @superclasses) = @_;
    assert_object($instance);
    assert_ainta($instance, @superclasses);
}

sub assert_class_isa($@)
    :Assert( qw[object] )
{
    my($class, @superclasses) = @_;
    assert_known_package($class);
    assert_isa($class, @superclasses);
}

sub assert_class_ainta($@)
    :Assert( qw[object] )
{
    my($class, @superclasses) = @_;
    assert_known_package($class);
    assert_ainta($class, @superclasses);
}

sub assert_does($@)
    :Assert( qw[object] )
{
    no overloading;
    my($invocant, @roles) = @_;
    @roles                              || botch "needs one or more roles to check against";
    my $type = _get_invocant_type $invocant;
    my @doesnt = grep { !$invocant->DOES($_) } @roles;
    !@doesnt || botch "your $type $invocant does not have role"
                    .  (@doesnt > 1 && "s") . " "
                    .  commify_or(uca_sort @doesnt);
}

sub assert_doesnt($@)
    :Assert( qw[object] )
{
    no overloading;
    my($invocant, @roles) = @_;
    @roles                              || botch "needs one or more roles to check against";
    my $type = _get_invocant_type $invocant;
    my @does = grep { $invocant->DOES($_) } @roles;
    !@does || botch "your $type $invocant does not have role"
                    .  (@does > 1 && "s") . " "
                    .  commify_or(uca_sort @does);
}

sub assert_object_overloads($@)
    :Assert( qw[object overload] )
{
    no overloading;
    &assert_object;
    my($object, @operators) = @_;
    overload::Overloaded($object)       || botch "your $object isn't overloaded";
    my @missing = grep { !overload::Method($object, $_) } @operators;
    !@missing || botch "your $object does not overload the operator"
                    .  (@missing > 1 && "s") . " "
                    . quotify_or(@missing);
}

sub assert_object_stringifies($)
    :Assert( qw[object overload] )
{
    my($object) = @_;
    assert_object_overloads $object, q{""};
}

sub assert_object_nummifies($)
    :Assert( qw[object overload] )
{
    my($object) = @_;
    assert_object_overloads $object, q{0+};
}

sub assert_object_boolifies($)
    :Assert( qw[object overload] )
{
    my($object) = @_;
    assert_object_overloads $object, q{bool};
}

#########################################

# Some of these can trigger unwanted overloads.
{
    no overloading;

    sub assert_tied(\[$@%*])
        :Assert( qw[tie] )
    {
        &assert_tied_referent;
    }

    sub assert_untied(\[$@%*])
        :Assert( qw[tie] )
    {
        &assert_untied_referent;
    }

    sub assert_tied_referent($)
        :Assert( qw[tie ref] )
    {
        &assert_anyref;
        my($ref) = @_;
        my $type = reftype $ref;

        # eg: SCALAR => \&assert_tied_scalarref,
        state $assert_by_type = {
            map {
                $_ => do { no strict "refs"; \&{ "assert_tied_" . lc . "ref" } }
            } qw(SCALAR ARRAY HASH GLOB)
        };

        my $assertion = $$assert_by_type{$type};
        $assertion && defined &$assertion
                || botch "invalid reftype to check for ties: '$type'";
        &$assertion($ref);
    }

    sub assert_untied_referent($)
        :Assert( qw[tie ref] )
    {
        &assert_anyref;
        my($ref) = @_;
        my $type = reftype $ref;

        # eg: SCALAR => \&assert_untied_scalarref,
        state $assert_by_type = {
            map {
                $_ => do { no strict "refs"; \&{ "assert_untied_" . lc . "ref" } },
            } qw(SCALAR ARRAY HASH GLOB),
        };

        my $assertion = $$assert_by_type{$type};
        $assertion && defined &$assertion
                || botch "invalid reftype to check for ties: '$type'";
        &$assertion($ref);

    }

    sub assert_tied_scalar(\$)
        :Assert( qw[tie scalar] )
    {
        &assert_tied_scalarref;
    }

    sub assert_untied_scalar(\$)
        :Assert( qw[tie scalar] )
    {
        &assert_untied_scalarref;
    }

    sub assert_tied_scalarref($)
        :Assert( qw[tie scalar ref] )
    {
        &assert_scalarref;
        my($scalarref) = @_;
        tied($$scalarref)    || botch "scalar is not tied";
    }

    sub assert_untied_scalarref($)
        :Assert( qw[tie scalar ref] )
    {
        &assert_scalarref;
        my($scalarref) = @_;
       !tied($$scalarref)    || botch "scalar is tied";
    }

    sub assert_tied_array(\@)
        :Assert( qw[tie array] )
    {
        &assert_tied_arrayref;
    }

    sub assert_untied_array(\@)
        :Assert( qw[tie array] )
    {
        &assert_untied_arrayref;
    }

    sub assert_tied_arrayref($)
        :Assert( qw[tie array ref] )
    {
        &assert_arrayref;
        my($arrayref) = @_;
        tied(@$arrayref)    || botch "array is not tied";
    }

    sub assert_untied_arrayref($)
        :Assert( qw[tie array ref] )
    {
        &assert_arrayref;
        my($arrayref) = @_;
       !tied(@$arrayref)    || botch "array is tied";
    }

    sub assert_tied_hash(\%)
        :Assert( qw[tie hash] )
    {
        &assert_tied_hashref;
    }

    sub assert_untied_hash(\%)
        :Assert( qw[tie hash] )
    {
        &assert_untied_hashref;
    }

    sub assert_tied_hashref($)
        :Assert( qw[tie hash ref] )
    {
        &assert_hashref;
        my($hashref) = @_;
        tied(%$hashref)    || botch "hash is not tied";
    }

    sub assert_untied_hashref($)
        :Assert( qw[tie hash ref] )
    {
        &assert_hashref;
        my($hashref) = @_;
       !tied(%$hashref)    || botch "hash is tied";
    }

    sub assert_tied_glob(\*)
        :Assert( qw[tie glob] )
    {
        &assert_tied_globref;
    }

    sub assert_untied_glob(\*)
        :Assert( qw[tie glob] )
    {
        &assert_untied_globref;
    }

    sub assert_tied_globref($)
        :Assert( qw[tie glob ref] )
    {
        &assert_globref;
        my($globref) = @_;
        tied(*$globref)    || botch "glob is not tied";
    }

    sub assert_untied_globref($)
        :Assert( qw[tie glob ref] )
    {
        &assert_globref;
        my($globref) = @_;
       !tied(*$globref)    || botch "glob is tied";
    }

} # scope for no overloading

# Common subroutine for the two happy/unhappy code tests.
sub _run_code_test($$) {
    my($code, $joy) = @_;
    assert_coderef($code);
    return if !!&$code() == !!$joy;
    botch sprintf "%s assertion %s is sadly %s",
        $joy ? "happy" : "unhappy",
        subname_or_code($code),
        $joy ? "false" : "true";
}

sub assert_happy_code(&)
    :Assert( qw[boolean code] )
{
    my($cref) = @_;
    _run_code_test($cref => 1);
}

sub assert_unhappy_code(&)
    :Assert( qw[boolean code] )
{
    my($cref) = @_;
    _run_code_test($cref => 0);
}

sub assert_open_handle($)
    :Assert( qw[io file] )
{
    my($arg) = @_;
    assert_defined($arg);
    defined(openhandle($arg))   || botch "handle $arg is not an open handle";
}

sub assert_regular_file($)
    :Assert( qw[file] )
{
    my($arg) = @_;
    assert_defined($arg);
    -f $arg                    || botch "appears that $arg is not a plainfile"
                                      . " nor a symlink to a plainfile";
}

sub assert_text_file($)
    :Assert( qw[file] )
{
    &assert_regular_file;
    my($arg) = @_;
    -T $arg                    || botch "appears that $arg does not contain text";
}

sub assert_directory($)
    :Assert( qw[file] )
{
    my($arg) = @_;
    -d $arg                    || botch "appears that $arg is not a directory"
                                      . " nor a symlink to a directory";
}

sub _WIFCORED(;$) {
    my($wstat) = @_ ? $_[0] : $?;
    # non-standard but nearly ubiquitous; too hard to fish from real sys/wait.h
    return WIFSIGNALED($wstat) && !!($wstat & 128);
}

sub _coredump_message(;$) {
    my($wstat) = @_ ? $_[0] : $?;
    return _WIFCORED($wstat) && " (core dumped)";
}

sub _signum_message($) {
    my($number) = @_;
    my $name = sig_num2longname($number);
    return "$name(#$number)";
}

sub assert_legal_exit_status(;$)
    :Assert( qw[process] )
{
    my($wstat) = @_ ? $_[0] : $?;
    assert_whole_number($wstat);
    $wstat < 2**16              || botch "exit value $wstat over 16 bits";
}

sub assert_signalled(;$)
    :Assert( qw[process] )
{
    &assert_legal_exit_status;
    my($wstat) = @_ ? $_[0] : $?;
    WIFSIGNALED($wstat)         || botch "exit value $wstat indicates no signal";
}

sub assert_unsignalled(;$)
    :Assert( qw[process] )
{
    &assert_legal_exit_status;
    my($wstat) = @_ ? $_[0] : $?;
    WIFEXITED($wstat)           && return;
    my $signo  = WTERMSIG($wstat);
    my $sigmsg = _signum_message($signo);
    my $cored  = _coredump_message($wstat);
    botch "exit value $wstat indicates process died from signal $sigmsg$cored";
}

sub assert_dumped_core(;$)
    :Assert( qw[process] )
{
    &assert_signalled;
    my($wstat) = @_ ? $_[0] : $?;
    my $signo = WTERMSIG($wstat);
    my $sigmsg = _signum_message($signo);
    _WIFCORED($wstat)           || botch "exit value $wstat indicates signal $sigmsg but no core dump";
}

sub assert_no_coredump(;$)
    :Assert( qw[process] )
{
    my($wstat) = @_ ? $_[0] : $?;
    my $cored = $wstat & 128;   # not standard; too hard to fish from real sys/wait.h
    return unless _WIFCORED($wstat);
    return unless $cored;
    my $signo  = WTERMSIG($wstat);
    my $sigmsg = _signum_message($signo);
    botch "exit value $wstat shows process died of a $sigmsg and dumped core";
}

sub assert_exited(;$)
    :Assert( qw[process] )
{
    &assert_legal_exit_status;
    my($wstat) = @_ ? $_[0] : $?;
    return if WIFEXITED($wstat);
    &assert_signalled;
    my $signo  = WTERMSIG($wstat);
    my $sigmsg = _signum_message($signo);
    my $cored  = _coredump_message($wstat);
    botch "exit value $wstat shows process did not exit but rather died of $sigmsg$cored";
}

sub assert_happy_exit(;$)
    :Assert( qw[process] )
{
    &assert_exited;
    my($wstat) = @_ ? $_[0] : $?;
    my $exit = WEXITSTATUS($wstat);
    $exit == 0                  || botch "exit status $exit is not a happy exit";
}

sub assert_sad_exit(;$)
    :Assert( qw[process] )
{
    &assert_exited;
    my($wstat) = @_ ? $_[0] : $?;
    my $exit = WEXITSTATUS($wstat);
    $exit != 0                  || botch "exit status 0 is an unexpectedly happy exit";
}

# If you actually *execute*(!) this module as though it were a perl
# script rather than merely require or compile it, it dumps out its
# export table like the pmexp tool from the pmtools distribution does.
# If moreover the ASSERT_CONDITIONAL_BUILD_POD envariable is true, then
# this actually generates pod you can use directly. This is used by the
# etc/generate-exporter-pod script from the source directory; this
# script is not installed, and is just a helper.

exit !dump_exports(@ARGV) unless his_is_require(-1);

# This can't execute at the "normal" time or else
# namespace::autoclean's call Sub::Identify freaks:
UNITCHECK { close(DATA) if defined fileno(DATA) }

1;


# This has to be __DATA__ not __END__ for the self-executing
# trick to work right.
__DATA__

=encoding utf8

=head1 NAME

Assert::Conditional - conditionally-compiled code assertions

=head1 SYNOPSIS

    # use them all unconditionally
    use Assert::Conditional qw(:all -if 1);

    # Use them based on some external conditional available
    # at compile time.
    use Assert::Conditional qw(:all)
        => -if => ( $ENV{DEBUG} && ! $ENV{NDEBUG} );

    # Use them based on some external conditional available
    # at compile time.
    use Assert::Conditional qw(:all)
        => -unless => $ENV{RUNTIME} eq "production";

    # Method that should be called in list context with two array refs
    # as arguments, and which should have both a "cross_product" and
    # a "cross_tees" method available to it.

    sub some_method {
        assert_list_context();
        assert_object_method();

        assert_argc(3);
        my($self, $left, $right) = @_;

        assert_arrayref($left);
        assert_arrayref($right);

        assert_can($self, "cross_product", "cross_tees");

        ...

        assert_happy_code { $i > $j };

        ...
    }

=head1 DESCRIPTION

C programmers have always had F<assert.h> to conditionally compile
assertions into their programs, but options available for Perl programmers
are not so convenient.

Several assertion modules related to assertions exist on CPAN, but none
works quite like this one does, probably due to differing design goals.
There was nothing that allowed you to say what C programmers could say:

    assert(colors > 10)

And then have the "colors > 10" bit included in the failure message if it
didn't work, thanks to the C preprocessor.  See L</assert_happy_code>
for a way to do that very same thing.

=head2 Runtime Control of Assertions

No matter what assertions you conditionally use, there may be times
when you have a running piece of software that you want to change
the assertion behavior of without changing the source code.

For that, the C<ASSERT_CONDITIONAL> environment variable is used to override
the current defaults.

=over

=item never

Assertions are never imported, and even if you somehow manage to import
them, they will never never make a peep nor raise an exception.

=item always

Assertions are always imported, and even if you somehow manage to avoid importing
them, they will still raise an exception on error. This is the default.

=item carp

Assertions are always imported but they do not raise an exception if they
fail; instead they all carp at you.  This is true even if you somehow
manage to call an assertion you haven't imported.

Note that if combined, you can get both effects:

    ASSERT_CONDITIONAL="carp,always"

=item handlers

Only usable in conjunction with another of the previous three, as in

    ASSERT_CONDITIONAL="always,handlers"

Unless this option is specified, C<$SIG{__WARN__}> and C<$SIG{__DIE__}>
handlers will be suppressed if the assertion fails while the ensuing a
C<confess> or C<carp> is needed.

=back

These may be combined for stacked effects, but "never" cancels
all of them. For example:

    ASSERT_CONDITIONAL="carp,always"
    ASSERT_CONDITIONAL="carp,handlers"
    ASSERT_CONDITIONAL="carp,always,handlers"

=head2 Inventory of Assertions

Here in alphabetical order is the list of all assertions with their prototypes.
Following this is a list of assertions grouped by category, and finally
a description of what each one does.

 assert_ainta                             (  $@  ) ;
 assert_alnum                             (  $   ) ;
 assert_alphabetic                        (  $   ) ;
 assert_anyref                            (  $   ) ;
 assert_argc                              ( ;$   ) ;
 assert_argc_max                          (  $   ) ;
 assert_argc_min                          (  $   ) ;
 assert_argc_minmax                       (  $$  ) ;
 assert_array_length                      ( \@ ;$) ;
 assert_array_length_max                  ( \@ $ ) ;
 assert_array_length_min                  ( \@ $ ) ;
 assert_array_length_minmax               ( \@ $$) ;
 assert_array_nonempty                    ( \@   ) ;
 assert_arrayref                          (  $   ) ;
 assert_arrayref_nonempty                 (  $   ) ;
 assert_ascii                             (  $   ) ;
 assert_ascii_ident                       (  $   ) ;
 assert_astral                            (  $   ) ;
 assert_blank                             (  $   ) ;
 assert_bmp                               (  $   ) ;
 assert_box_number                        (  $   ) ;
 assert_bytes                             (  $   ) ;
 assert_can                               (  $@  ) ;
 assert_cant                              (  $@  ) ;
 assert_class_ainta                       (  $@  ) ;
 assert_class_can                         (  $@  ) ;
 assert_class_cant                        (  $@  ) ;
 assert_class_isa                         (  $@  ) ;
 assert_class_method                      (      ) ;
 assert_coderef                           (  $   ) ;
 assert_defined                           (  $   ) ;
 assert_defined_value                     (  $   ) ;
 assert_defined_variable                  ( \$   ) ;
 assert_digits                            (  $   ) ;
 assert_directory                         (  $   ) ;
 assert_does                              (  $@  ) ;
 assert_doesnt                            (  $@  ) ;
 assert_dumped_core                       ( ;$   ) ;
 assert_empty                             (  $   ) ;
 assert_eq                                (  $$  ) ;
 assert_eq_letters                        (  $$  ) ;
 assert_even_number                       (  $   ) ;
 assert_exited                            ( ;$   ) ;
 assert_false                             (  $   ) ;
 assert_fractional                        (  $   ) ;
 assert_full_perl_ident                   (  $   ) ;
 assert_globref                           (  $   ) ;
 assert_happy_code                        (  &   ) ;
 assert_happy_exit                        ( ;$   ) ;
 assert_hash_keys                         ( \% @    ) ;
 assert_hash_keys_allowed                 ( \% @    ) ;
 assert_hash_keys_allowed_and_required    ( \% $ $  ) ;
 assert_hash_keys_required                ( \% @    ) ;
 assert_hash_keys_required_and_allowed    ( \% $ $  ) ;
 assert_hash_nonempty                     ( \%      ) ;
 assert_hashref                           (  $      ) ;
 assert_hashref_keys                      (  $@     ) ;
 assert_hashref_keys_allowed              (  $@     ) ;
 assert_hashref_keys_allowed_and_required (  $$$    ) ;
 assert_hashref_keys_required             (  $@     ) ;
 assert_hashref_keys_required_and_allowed (  $$$    ) ;
 assert_hashref_nonempty                  (  $      ) ;
 assert_hex_number                        (  $      ) ;
 assert_in_list                           (  $@     ) ;
 assert_in_numeric_range                  (  $$$    ) ;
 assert_integer                           (  $      ) ;
 assert_ioref                             (  $      ) ;
 assert_is                                (  $$     ) ;
 assert_isa                               (  $@     ) ;
 assert_isnt                              (  $$     ) ;
 assert_keys                              ( \[%$] @ ) ;
 assert_known_package                     (  $      ) ;
 assert_latin1                            (  $      ) ;
 assert_latinish                          (  $      ) ;
 assert_legal_exit_status                 ( ;$      ) ;
 assert_like                              (  $$     ) ;
 assert_list_context                      (         ) ;
 assert_list_nonempty                     (  @      ) ;
 assert_locked                            ( \[%$] @ ) ;
 assert_lowercased                        (  $      ) ;
 assert_max_keys                          ( \[%$] @ ) ;
 assert_method                            (         ) ;
 assert_min_keys                          ( \[%$] @ ) ;
 assert_minmax_keys                       ( \[%$] \[@$] \[@$] ) ;
 assert_multi_line                        (  $   ) ;
 assert_natural_number                    (  $   ) ;
 assert_negative                          (  $   ) ;
 assert_negative_integer                  (  $   ) ;
 assert_nfc                               (  $   ) ;
 assert_nfd                               (  $   ) ;
 assert_nfkc                              (  $   ) ;
 assert_nfkd                              (  $   ) ;
 assert_no_coredump                       ( ;$   ) ;
 assert_nonalphabetic                     (  $   ) ;
 assert_nonascii                          (  $   ) ;
 assert_nonastral                         (  $   ) ;
 assert_nonblank                          (  $   ) ;
 assert_nonbytes                          (  $   ) ;
 assert_nonempty                          (  $   ) ;
 assert_nonlist_context                   (      ) ;
 assert_nonnegative                       (  $   ) ;
 assert_nonnegative_integer               (  $   ) ;
 assert_nonnumeric                        (  $   ) ;
 assert_nonobject                         (  $   ) ;
 assert_nonpositive                       (  $   ) ;
 assert_nonpositive_integer               (  $   ) ;
 assert_nonref                            (  $   ) ;
 assert_nonvoid_context                   (      ) ;
 assert_nonzero                           (  $   ) ;
 assert_not_in_list                       (  $@  ) ;
 assert_numeric                           (  $   ) ;
 assert_object                            (  $   ) ;
 assert_object_ainta                      (  $@  ) ;
 assert_object_boolifies                  (  $   ) ;
 assert_object_can                        (  $@  ) ;
 assert_object_cant                       (  $@  ) ;
 assert_object_isa                        (  $@  ) ;
 assert_object_method                     (      ) ;
 assert_object_nummifies                  (  $   ) ;
 assert_object_overloads                  (  $@  ) ;
 assert_object_stringifies                (  $   ) ;
 assert_odd_number                        (  $   ) ;
 assert_open_handle                       (  $   ) ;
 assert_positive                          (  $   ) ;
 assert_positive_integer                  (  $   ) ;
 assert_private_method                    (      ) ;
 assert_protected_method                  (      ) ;
 assert_public_method                     (      ) ;
 assert_qualified_ident                   (  $   ) ;
 assert_refref                            (  $   ) ;
 assert_reftype                           (  $$  ) ;
 assert_regex                             (  $   ) ;
 assert_regular_file                      (  $   ) ;
 assert_sad_exit                          ( ;$   ) ;
 assert_scalar_context                    (      ) ;
 assert_scalarref                         (  $   ) ;
 assert_signalled                         ( ;$   ) ;
 assert_signed_number                     (  $   ) ;
 assert_simple_perl_ident                 (  $   ) ;
 assert_single_line                       (  $   ) ;
 assert_single_paragraph                  (  $   ) ;
 assert_text_file                         (  $   ) ;
 assert_tied                              ( \[$@*]  ) ;
 assert_tied_array                        ( \@  ) ;
 assert_tied_arrayref                     (  $  ) ;
 assert_tied_glob                         ( \*  ) ;
 assert_tied_globref                      (  $  ) ;
 assert_tied_hash                         ( \%  ) ;
 assert_tied_hashref                      (  $  ) ;
 assert_tied_referent                     (  $  ) ;
 assert_tied_scalar                       ( \$  ) ;
 assert_tied_scalarref                    (  $  ) ;
 assert_true                              (  $  ) ;
 assert_unblessed_ref                     (  $  ) ;
 assert_undefined                         (  $  ) ;
 assert_unhappy_code                      (  &  ) ;
 assert_unicode_ident                     (  $  ) ;
 assert_unlike                            (  $$ ) ;
 assert_unlocked                          ( \[%$] @  ) ;
 assert_unsignalled                       ( ;$       ) ;
 assert_untied                            ( \[$@%*]  ) ;
 assert_untied_array                      ( \@  ) ;
 assert_untied_arrayref                   (  $  ) ;
 assert_untied_glob                       ( \*  ) ;
 assert_untied_globref                    (  $  ) ;
 assert_untied_hash                       ( \%  ) ;
 assert_untied_hashref                    (  $  ) ;
 assert_untied_referent                   (  $  ) ;
 assert_untied_scalar                     ( \$  ) ;
 assert_untied_scalarref                  (  $  ) ;
 assert_uppercased                        (  $  ) ;
 assert_void_context                      (     ) ;
 assert_whole_number                      (  $  ) ;
 assert_wide_characters                   (  $  ) ;
 assert_zero                              (  $  ) ;

All assertions have function prototypes; this helps you use them correctly,
and in some cases casts the argument into scalar context, adds backslashes
to pass things by reference, so you don't have to.

=head2 Export Tags

You may import all assertions or just some of them.  When importing only
some of them, you may wish to use an export tag to import a set of related
assertions.  Here is what each tag imports:

=over

=item C<:all>

L</assert_ainta>, L</assert_alnum>, L</assert_alphabetic>,
L</assert_anyref>, L</assert_argc>, L</assert_argc_max>,
L</assert_argc_min>, L</assert_argc_minmax>, L</assert_array_length>,
L</assert_array_length_max>, L</assert_array_length_min>,
L</assert_array_length_minmax>, L</assert_array_nonempty>,
L</assert_arrayref>, L</assert_arrayref_nonempty>, L</assert_ascii>,
L</assert_ascii_ident>, L</assert_astral>, L</assert_blank>,
L</assert_bmp>, L</assert_box_number>, L</assert_bytes>, L</assert_can>,
L</assert_cant>, L</assert_class_ainta>, L</assert_class_can>,
L</assert_class_cant>, L</assert_class_isa>, L</assert_class_method>,
L</assert_coderef>, L</assert_defined>, L</assert_defined_value>,
L</assert_defined_variable>, L</assert_digits>, L</assert_directory>,
L</assert_does>, L</assert_doesnt>, L</assert_dumped_core>,
L</assert_empty>, L</assert_eq>, L</assert_eq_letters>,
L</assert_even_number>, L</assert_exited>, L</assert_false>,
L</assert_fractional>, L</assert_full_perl_ident>, L</assert_globref>,
L</assert_happy_code>, L</assert_happy_exit>, L</assert_hash_keys>,
L</assert_hash_keys_allowed>, L</assert_hash_keys_allowed_and_required>,
L</assert_hash_keys_required>, L</assert_hash_keys_required_and_allowed>,
L</assert_hash_nonempty>, L</assert_hashref>, L</assert_hashref_keys>,
L</assert_hashref_keys_allowed>,
L</assert_hashref_keys_allowed_and_required>,
L</assert_hashref_keys_required>,
L</assert_hashref_keys_required_and_allowed>, L</assert_hashref_nonempty>,
L</assert_hex_number>, L</assert_in_list>, L</assert_in_numeric_range>,
L</assert_integer>, L</assert_ioref>, L</assert_is>, L</assert_isa>,
L</assert_isnt>, L</assert_keys>, L</assert_known_package>,
L</assert_latin1>, L</assert_latinish>, L</assert_legal_exit_status>,
L</assert_like>, L</assert_list_context>, L</assert_list_nonempty>,
L</assert_locked>, L</assert_lowercased>, L</assert_max_keys>,
L</assert_method>, L</assert_min_keys>, L</assert_minmax_keys>,
L</assert_multi_line>, L</assert_natural_number>, L</assert_negative>,
L</assert_negative_integer>, L</assert_nfc>, L</assert_nfd>,
L</assert_nfkc>, L</assert_nfkd>, L</assert_no_coredump>,
L</assert_nonalphabetic>, L</assert_nonascii>, L</assert_nonastral>,
L</assert_nonblank>, L</assert_nonbytes>, L</assert_nonempty>,
L</assert_nonlist_context>, L</assert_nonnegative>,
L</assert_nonnegative_integer>, L</assert_nonnumeric>,
L</assert_nonobject>, L</assert_nonpositive>,
L</assert_nonpositive_integer>, L</assert_nonref>,
L</assert_nonvoid_context>, L</assert_nonzero>, L</assert_not_in_list>,
L</assert_numeric>, L</assert_object>, L</assert_object_ainta>,
L</assert_object_boolifies>, L</assert_object_can>, L</assert_object_cant>,
L</assert_object_isa>, L</assert_object_method>,
L</assert_object_nummifies>, L</assert_object_overloads>,
L</assert_object_stringifies>, L</assert_odd_number>,
L</assert_open_handle>, L</assert_positive>, L</assert_positive_integer>,
L</assert_private_method>, L</assert_protected_method>,
L</assert_public_method>, L</assert_qualified_ident>, L</assert_refref>,
L</assert_reftype>, L</assert_regex>, L</assert_regular_file>,
L</assert_sad_exit>, L</assert_scalar_context>, L</assert_scalarref>,
L</assert_signalled>, L</assert_signed_number>,
L</assert_simple_perl_ident>, L</assert_single_line>,
L</assert_single_paragraph>, L</assert_text_file>, L</assert_tied>,
L</assert_tied_array>, L</assert_tied_arrayref>, L</assert_tied_glob>,
L</assert_tied_globref>, L</assert_tied_hash>, L</assert_tied_hashref>,
L</assert_tied_referent>, L</assert_tied_scalar>,
L</assert_tied_scalarref>, L</assert_true>, L</assert_unblessed_ref>,
L</assert_undefined>, L</assert_unhappy_code>, L</assert_unicode_ident>,
L</assert_unlike>, L</assert_unlocked>, L</assert_unsignalled>,
L</assert_untied>, L</assert_untied_array>, L</assert_untied_arrayref>,
L</assert_untied_glob>, L</assert_untied_globref>, L</assert_untied_hash>,
L</assert_untied_hashref>, L</assert_untied_referent>,
L</assert_untied_scalar>, L</assert_untied_scalarref>,
L</assert_uppercased>, L</assert_void_context>, L</assert_whole_number>,
L</assert_wide_characters>, and L</assert_zero>.

=item C<:argc>

L</assert_argc>, L</assert_argc_max>, L</assert_argc_min>, and
L</assert_argc_minmax>.

=item C<:array>

L</assert_array_length>, L</assert_array_length_max>,
L</assert_array_length_min>, L</assert_array_length_minmax>,
L</assert_array_nonempty>, L</assert_arrayref>,
L</assert_arrayref_nonempty>, L</assert_list_nonempty>,
L</assert_tied_array>, L</assert_tied_arrayref>, L</assert_untied_array>,
and L</assert_untied_arrayref>.

=item C<:boolean>

L</assert_false>, L</assert_happy_code>, L</assert_true>, and
L</assert_unhappy_code>.

=item C<:case>

L</assert_lowercased> and L</assert_uppercased>.

=item C<:code>

L</assert_coderef>, L</assert_happy_code>, and L</assert_unhappy_code>.

=item C<:context>

L</assert_list_context>, L</assert_nonlist_context>,
L</assert_nonvoid_context>, L</assert_scalar_context>, and
L</assert_void_context>.

=item C<:file>

L</assert_directory>, L</assert_open_handle>, L</assert_regular_file>,
and L</assert_text_file>.

=item C<:glob>

L</assert_globref>, L</assert_tied_glob>, L</assert_tied_globref>,
L</assert_untied_glob>, and L</assert_untied_globref>.

=item C<:hash>

L</assert_hash_keys>, L</assert_hash_keys_allowed>,
L</assert_hash_keys_allowed_and_required>, L</assert_hash_keys_required>,
L</assert_hash_keys_required_and_allowed>, L</assert_hash_nonempty>,
L</assert_hashref>, L</assert_hashref_keys>,
L</assert_hashref_keys_allowed>,
L</assert_hashref_keys_allowed_and_required>,
L</assert_hashref_keys_required>,
L</assert_hashref_keys_required_and_allowed>, L</assert_hashref_nonempty>,
L</assert_keys>, L</assert_locked>, L</assert_max_keys>,
L</assert_min_keys>, L</assert_minmax_keys>, L</assert_tied_hash>,
L</assert_tied_hashref>, L</assert_unlocked>, L</assert_untied_hash>,
and L</assert_untied_hashref>.

=item C<:ident>

L</assert_ascii_ident>, L</assert_full_perl_ident>,
L</assert_known_package>, L</assert_qualified_ident>, and
L</assert_simple_perl_ident>.

=item C<:io>

L</assert_ioref> and L</assert_open_handle>.

=item C<:list>

L</assert_in_list>, L</assert_list_nonempty>, and L</assert_not_in_list>.

=item C<:number>

L</assert_box_number>, L</assert_digits>, L</assert_even_number>,
L</assert_fractional>, L</assert_hex_number>, L</assert_in_numeric_range>,
L</assert_integer>, L</assert_natural_number>, L</assert_negative>,
L</assert_negative_integer>, L</assert_nonnegative>,
L</assert_nonnegative_integer>, L</assert_nonnumeric>,
L</assert_nonpositive>, L</assert_nonpositive_integer>, L</assert_nonzero>,
L</assert_numeric>, L</assert_odd_number>, L</assert_positive>,
L</assert_positive_integer>, L</assert_signed_number>,
L</assert_whole_number>, and L</assert_zero>.

=item C<:object>

L</assert_ainta>, L</assert_can>, L</assert_cant>, L</assert_class_ainta>,
L</assert_class_can>, L</assert_class_cant>, L</assert_class_isa>,
L</assert_class_method>, L</assert_does>, L</assert_doesnt>,
L</assert_isa>, L</assert_known_package>, L</assert_method>,
L</assert_nonobject>, L</assert_object>, L</assert_object_ainta>,
L</assert_object_boolifies>, L</assert_object_can>, L</assert_object_cant>,
L</assert_object_isa>, L</assert_object_method>,
L</assert_object_nummifies>, L</assert_object_overloads>,
L</assert_object_stringifies>, L</assert_private_method>,
L</assert_protected_method>, L</assert_public_method>, L</assert_reftype>,
and L</assert_unblessed_ref>.

=item C<:overload>

L</assert_object_boolifies>, L</assert_object_nummifies>,
L</assert_object_overloads>, and L</assert_object_stringifies>.

=item C<:process>

L</assert_dumped_core>, L</assert_exited>, L</assert_happy_exit>,
L</assert_legal_exit_status>, L</assert_no_coredump>, L</assert_sad_exit>,
L</assert_signalled>, and L</assert_unsignalled>.

=item C<:ref>

L</assert_anyref>, L</assert_arrayref>, L</assert_coderef>,
L</assert_globref>, L</assert_hashref>, L</assert_ioref>,
L</assert_nonref>, L</assert_refref>, L</assert_reftype>,
L</assert_scalarref>, L</assert_tied_arrayref>, L</assert_tied_globref>,
L</assert_tied_hashref>, L</assert_tied_referent>,
L</assert_tied_scalarref>, L</assert_unblessed_ref>,
L</assert_untied_arrayref>, L</assert_untied_globref>,
L</assert_untied_hashref>, L</assert_untied_referent>, and
L</assert_untied_scalarref>.

=item C<:regex>

L</assert_alnum>, L</assert_alphabetic>, L</assert_ascii>,
L</assert_ascii_ident>, L</assert_blank>, L</assert_digits>,
L</assert_full_perl_ident>, L</assert_hex_number>, L</assert_like>,
L</assert_lowercased>, L</assert_multi_line>, L</assert_nonalphabetic>,
L</assert_nonascii>, L</assert_nonblank>, L</assert_qualified_ident>,
L</assert_regex>, L</assert_simple_perl_ident>, L</assert_single_line>,
L</assert_single_paragraph>, L</assert_unicode_ident>, L</assert_unlike>,
and L</assert_uppercased>.

=item C<:scalar>

L</assert_defined>, L</assert_defined_value>, L</assert_defined_variable>,
L</assert_false>, L</assert_scalarref>, L</assert_tied_scalar>,
L</assert_tied_scalarref>, L</assert_true>, L</assert_undefined>,
L</assert_untied_scalar>, and L</assert_untied_scalarref>.

=item C<:string>

L</assert_alphabetic>, L</assert_ascii>, L</assert_blank>,
L</assert_bytes>, L</assert_empty>, L</assert_eq>, L</assert_eq_letters>,
L</assert_is>, L</assert_isnt>, L</assert_latin1>, L</assert_multi_line>,
L</assert_nonalphabetic>, L</assert_nonascii>, L</assert_nonblank>,
L</assert_nonbytes>, L</assert_nonempty>, L</assert_single_line>,
L</assert_single_paragraph>, and L</assert_wide_characters>.

=item C<:tie>

L</assert_tied>, L</assert_tied_array>, L</assert_tied_arrayref>,
L</assert_tied_glob>, L</assert_tied_globref>, L</assert_tied_hash>,
L</assert_tied_hashref>, L</assert_tied_referent>, L</assert_tied_scalar>,
L</assert_tied_scalarref>, L</assert_untied>, L</assert_untied_array>,
L</assert_untied_arrayref>, L</assert_untied_glob>,
L</assert_untied_globref>, L</assert_untied_hash>,
L</assert_untied_hashref>, L</assert_untied_referent>,
L</assert_untied_scalar>, and L</assert_untied_scalarref>.

=item C<:unicode>

L</assert_astral>, L</assert_bmp>, L</assert_eq>, L</assert_eq_letters>,
L</assert_latin1>, L</assert_latinish>, L</assert_nfc>, L</assert_nfd>,
L</assert_nfkc>, L</assert_nfkd>, and L</assert_nonastral>.

=back

=head2 Assertions about Calling Context

These assertions inspect their immediate caller’s C<wantarray>.

=over

=item assert_list_context()

Current function was called in list context.

=item assert_nonlist_context()

Current function was I<not> called in list context.

=item assert_scalar_context()

Current function was called in scalar context.

=item assert_void_context()

Current function was called in void context.

=item assert_nonvoid_context()

Current function was I<not> called in void context.

=back

=head2 Assertions about Scalars

These assertions don't pay any special attention to objects, so the normal
effects of evaluating an object where a regular scalar is expected apply.

=over

=item assert_true(I<EXPR>)

The scalar expression I<EXPR> is true according to Perl's sense of Boolean
logic, the sort of thing you would put in an C<if (...)> condition to have
its block run.

If this assertion fails, it will not report the original expression.  You
should therefore strongly consider using L</assert_happy_code> instead for
more descriptive error messages because L</assert_happy_code> will show the
literal expression that was expected to be true but which unexpectedly
evaluated to false.

=item assert_false(I<EXPR>)

The scalar expression I<EXPR> is true according to Perl's sense of Boolean
logic, the sort of thing you would put in an C<unless>) condition to have
its block run.

If this assertion fails, it will not report the original expression.  You
should therefore strongly consider using L</assert_unhappy_code> instead
for more descriptive error messages, because  L</assert_unhappy_code> will
display the literal expression that was expected to be false but which
unexpectedly evaluated to true.

False values in Perl are the undefined value, both kinds of empty string
(C<q()> and C<!1>), the string of length one whose only character is an
ASCII C<DIGIT ZERO>, and those numbers which evaluate to zero.  Strings
that evaluate to numeric zero other than the previously stated exemption
are not false, such as the notorious value C<"0 but true"> sometimes
returned by the C<ioctl>, C<fcntl>, and C<syscall> system calls.

=item assert_defined(I<EXPR>)

The scalar I<EXPR> argument is defined.  Consider using one of either
L</assert_defined_variable> or L</assert_defined_value> to better
document your intention.

=item assert_undefined(I<EXPR>)

The scalar I<EXPR> argument is not defined.

=item assert_defined_variable(I<SCALAR>)

The scalar B<variable> argument I<SCALAR> is defined.  This is safer to
call than L</assert_defined_value> because it requires an actual scalar
variable with a leading dollar sign, so generates a compiler error if you
try to pass it other sigils.

=item assert_defined_value(I<EXPR>)

The scalar I<EXPR> is defined.

=item assert_is(I<THIS>, I<THAT>)

The two defined non-ref arguments test true for "string equality", codepoint
by codepoint, using the built-in C<eq> operator.  

When called on objects with operator overloads, their C<eq> overload or if
necessary their stringification overloads will thereofre be honored but
this test is not otherwise in any fashion recursive or object-aware.

This is not the same as equivalent Unicode strings. For that, use
L</assert_eq> to compare normalized Unicode strings, and use
L</assert_eq_letters> to compare only their letters but disregard the rest.

=item assert_isnt(I<THIS>, I<THAT>)

The two defined non-ref arguments test false for string equality with the
C<ne> operator.  The expected overloads are therefore honored, but this
test is not otherwise in any fashion recursive or object-aware.

=back

=head2 Assertions about Numbers

Most of the assertions in this section treat their arguments as numbers.
When called on objects with operator overloads, their evaluation will
therefore trigger a C<0+> nummification overload in preference to a C<"">
stringification overload if the former exists. Otherwise normal fallback
rules apply as documented in the L<overload> pragma.

=over 

=item assert_numeric(I<EXPR>)

The defined non-ref argument looks like a number suitable for implicit
conversion according to the builtin L<Scalar::Util/looks_like_number>
predicate.

=item assert_nonnumeric(I<EXPR>)

The defined non-ref argument does I<not> look like a number suitable for
implicit conversion, again per L<Scalar::Util/looks_like_number>.

=item assert_positive(I<EXPR>)

The defined non-ref argument is numerically greater than zero.

=item assert_nonpositive(I<EXPR>)

The defined non-ref argument is numerically less than or equal to zero.

=item assert_negative(I<EXPR>)

The defined non-ref argument is numerically less than zero.

=item assert_nonnegative(I<EXPR>)

The defined non-ref argument is numerically greater than or equal to
numeric zero.

=item assert_zero(I<EXPR>)

The defined non-ref argument is numerically equal to numeric zero.

=item assert_nonzero(I<EXPR>)

The defined non-ref argument is not numerically equal to numeric zero.

=item assert_integer(I<EXPR>)

The defined non-ref numeric argument has no fractional part.

=item assert_fractional(I<EXPR>)

The defined non-ref numeric argument has a fractional part.

=item assert_signed_number(I<EXPR>)

The defined non-ref numeric argument has a leading sign, ASCII C<-> or
C<+>.  A Unicode C<MINUS SIGN> does not currently count because Perl will
not respect it for implicit string-to-number conversions.

=item assert_natural_number(I<EXPR>)

One of the counting numbers: 1, 2, 3, . . .

=item assert_whole_number(I<EXPR>)

A natural number or zero.

=item assert_positive_integer(I<EXPR>)

An integer greater than zero.

=item assert_nonpositive_integer(I<EXPR>)

An integer not greater than zero.

=item assert_negative_integer(I<EXPR>)

An integer less than zero.

=item assert_nonnegative_integer(I<EXPR>)

An integer that's zero or below.

=item assert_hex_number(I<EXPR>)

Beyond an optional leading C<0x>, the argument contains only ASCII hex
digits, making it suitable for feeding to the C<hex> function.

=item assert_box_number(I<EXPR>)

The argument treated as a I<string> is suitable for feeding to Perl's
C<oct> function, so a non-negative integer with an optional leading C<0b>
for binary, C<0o> or C<0> for octal, or C<0x> for hex.

Mnemonic: "I<box> numbers" are B<b>inary, B<o>ctal, or heB<x> numbers.

=item assert_even_number(I<EXPR>)

The defined non-ref integer expression must be an even multiple of two.

=item assert_odd_number(I<EXPR>)

The defined non-ref integer expression must I<not> be an even multiple of two.

=item assert_in_numeric_range(I<NUMBER>, I<LOW>, I<HIGH>)

The scalar I<NUMBER> argument falls between the numeric range specified in
the next two scalar arguments; that is, it must be at least as great as the
I<LOW> end of the range but no higher than the I<HIGH> end of the range.

It's like writing either of these:

    assert_happy_code { $number >= $low && $number <= $high };

    assert_true($number >= $low && $number <= $high);

=back

=head2 Assertions about Strings

=over

=item assert_empty(I<EXPR>)

The defined non-ref argument is of zero length.

=item assert_nonempty(I<EXPR>)

The defined non-ref argument is not of zero length.

=item assert_blank(I<EXPR>)

The defined non-ref argument has at most only whitespace
characters in it.   It may be length zero.

=item assert_nonblank(I<EXPR>)

The defined non-ref argument has at least one non-whitespace
character in it.

=item assert_single_line(I<EXPR>)

The defined non-empty string argument has at most one optional linebreak grapheme
(C<\R>, so a CRLF or vertical whitespace line newline, carriage return, and
form feed) at the very end.  It is disqualified if it has a linebreak
anywhere shy of the end, or more than one of them at the end.

=item assert_multi_line(I<EXPR>)

Non-empty string argument has at most one optional linebreak grapheme
(C<\R>, so a CRLF or vertical whitespace line newline, carriage return, and
form feed) at the very end.  It is disqualified if it has a linebreak
anywhere shy of the end, or more than one of them at the end.

=item assert_single_paragraph(I<EXPR>)

Non-empty string argument has at any number of linebreak graphemes
at the very end only.  It is disqualified if it has linebreaks
anywhere shy of the end, but does not care how many are there.

=item assert_bytes(I<EXPR>)

Argument contains only code points between 0x00 and 0xFF.
Such data is suitable for writing out as binary bytes.

=item assert_nonbytes(I<EXPR>)

Argument contains code points greater than 0xFF.
Such data must first be encoded when written.

=item assert_wide_characters(I<EXPR>)

The same thing as saying that it contains non-bytes.

=back

=head2 Assertions about Regexes

=over

=item assert_nonascii(I<EXPR>)

Argument contains at least one code point larger that 127.

=item assert_ascii(I<EXPR>)

Argument contains only code points less than 128.

=item assert_alphabetic(I<EXPR>)

Argument contains only alphabetic code points,
but not necessarily ASCII ones.

=item assert_nonalphabetic(I<EXPR>)

Argument contains only non-alphabetic code points,
but not necessarily ASCII ones.

=item assert_alnum(I<EXPR>)

Argument contains only alphabetic or numeric code points,
but not necessarily ASCII ones.

=item assert_digits(I<EXPR>)

Argument contains only ASCII digits.

=item assert_uppercased(I<EXPR>)

Argument will not change if uppercased.

=item assert_lowercased(I<EXPR>)

Argument will not change if lowercased.

=item assert_unicode_ident(I<EXPR>)

Argument is a legal Unicode identifier, so one beginning with an (X)ID Start
code point and having any number of (X)ID Continue code points following.
Note that Perl identifiers are somewhat different from this.

=item assert_simple_perl_ident(I<EXPR>)

Like a Unicode identifier but which may also start
with connector punctuation like underscores.  No package
separators are allowed, however.  Sigils do not count.

Also, special variables like C<$.> or C<${^PREMATCH}>
will not work either, since passing this function
strings like C<.> and C<{> and C<^> are
all beyond the pale.

=item assert_full_perl_ident(I<EXPR>)

Like a simple Perl identifier but which also
allows for optional package separators,
either C<::> or C<'>.

=item assert_qualified_ident(I<EXPR>)

Like a full Perl identifier but with
mandatory package separators, either C<::> or C<'>.

=item assert_ascii_ident(I<EXPR>)

What most people think of as an identifier,
one with only ASCII letter, digits, and underscores,
and which cannot begin with a digit.

=item assert_regex(I<ARG>)

The argument must be a compile Regexp object.

=item assert_like(I<STRING>, I<REGEX>)

The string, which must be a defined non-reference,
matches the pattern, which must be a compiled Regexp object
produces by the C<qr> operator.

=item assert_unlike(I<STRING>, I<REGEX>)

The string, which must be a defined non-reference,
cannot match the pattern, which must be a compiled Regexp object
produces by the C<qr> operator.

=back

=head2 Assertions about Unicode

=over

=item assert_latin1(I<ARG>)

The argument contains only code points
from U+0000 through U+00FF.

=item assert_latinish(I<ARG>)

The argument contains only characters from the
Latin, Common, or Inherited scripts.

=item assert_astral(I<ARG>)

The argument contains at least one code point larger
than U+FFFF, so those above Plane 0.

=item assert_nonastral(I<ARG>)

Argument contains only code points
from U+0000 through U+FFFF.

=item assert_bmp(I<ARG>)

An alias for L</assert_nonastral>.

The argument contains only code points in the
Basic Multilingual Plain; that is, in Plane 0.

=item assert_nfc(I<ARG>)

The argument is in Unicode Normalization Form C,
formed by canonical I<B<de>composition> followed by
canonical composition.

=item assert_nfkc(I<ARG>)

The argument is in Unicode Normalization Form KC,
formed by compatible I<B<de>composition> followed by
compatible composition.

=item assert_nfd(I<ARG>)

The argument is in Unicode Normalization Form D,
formed by canonical I<B<de>composition>.

=item assert_nfkd(I<ARG>)

The argument is in Unicode Normalization Form KD,
formed by compatible I<B<de>composition>.

=item assert_eq(I<THIS>, I<THAT>)

The two strings have the same NFC forms using the C<eq>
operator.  This means that default ignorable code points
will throw of the equality check.

This is not the same as L</assert_is>.  You may well
want the next assertion instead.

=item assert_eq_letters(I<THIS>, I<THAT>)

The two strings test equal when considered only at the primary strength
(letters only) using the Unicode Collation Algorithm.  That means that case
(whether upper-, lower-, or titecase), non-letters, and combining marks are
ignored, as are other default ignorable code points.

=back

=head2 Assertions about Lists

=over

=item assert_in_list(I<STRING>, I<LIST>)

The first argument must occur in the list following it.

=item assert_not_in_list(I<STRING>, I<LIST>)

The first argument must not occur in the list following it.

=item assert_list_nonempty(I<LIST>)

The list must have at least one element, although that
element does not have to nonblank or even defined.

=back

=head2 Assertions about Arrays

=over

=item assert_array_nonempty( I<ARRAY> )

The array must at least one element.

=item assert_arrayref_nonempty( I<ARRAYREF> )

The array reference must refer to an existing array with
at least one element.

=item assert_array_length(I<ARRAY>, [ I<LENGTH> ])

The array must have the number of elements specified
in the optional second argument.  If the second
argument is omitted, any non-zero length will do.

=item assert_array_length_min(I<ARRAY>, I<MIN_ELEMENTS>)

The array must have at least as many elements as specified
by the number in the second argument.

=item assert_array_length_max(I<ARRAY>, I<MAX_ELEMENTS>)

The array must have no more elements than the number specified
in the second argument.

=item assert_array_length_minmax(I<ARRAY>, I<MIN_ELEMENTS>, I<MAX_ELEMENTS>)

The array must have at least as many elements as the number given in the
second element, but no more than the one in the third.

=back

=head2 Assertions about Argument Counts

B<WARNING:> These assertions are incompatible with L<Test::Exception> because
they inspect their C<caller>'s args via C<@DB::args>, and that module wipes
those out from visibility.

=over

=item assert_argc()

=item assert_argc(I<COUNT>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    assert_argc(3);  # must be exactly 3 args
    assert_argc( );  # must be at least 1 arg

The function must have been passed the number of arguments specified in the
optional I<COUNT> argument.  When called without a I<COUNT> argument, any
non-zero number of arguments will do.

Does not work under L<Test::Exception>.

=item assert_argc_min(I<COUNT>)

The function must have been passed at I<least> as many arguments as
specified in the I<COUNT> argument.

Does not work under L<Test::Exception>.

=item assert_argc_max(I<COUNT>)

The function must have been passed at I<most> as arguments as specified in
the I<COUNT> argument.

Does not work under L<Test::Exception>.

Does not work under L<Test::Exception>.

=item assert_argc_minmax(I<MIN>, I<MAX>)

The function must have been passed at least as many arguments as
specified by the I<MIN>, but no more than specified in the I<MAX>.

Does not work under L<Test::Exception>.

=back

=head2 Assertions about Hashes

=over

=item assert_hash_nonempty(I<HASH>)

The hash must have at least one key.

=item assert_hashref_nonempty(I<HASHREF>)

The hashref's referent must have at least one key.

=item assert_keys(I<HASH> | I<HASHREF>, I<KEY_LIST>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    my @exact_keys = qw[larry moe curly];
    assert_keys(%some_hash, @exact_keys);

The I<HASH> must have all keys in the non-empty I<KEY_LIST> but no others.

This is especially useful when you've got a hash that you're treating as a
"fixed record" data-type, as though it were a C C<struct>: all fields are
guaranteed to be present and nothing else.

This assertion also accepts a I<HASHREF> argument instead, but it still
must be an actual variable.

That is, if instead of a I<HASH> variable is passed as the first argument,
a scalar variable holding a hashref is passed, then the hash referenced is
subject to this constraint. In other words, you get a single level of
auto-dereference to get to the hash, but the price of that is that this
must be an lvalue not an rvalue: it must be an actual variable. For
example:

    my @exact_keys = qw[larry moe curly];

    assert_keys($some_hashref,                 @exact_keys);
    assert_keys($hash_of_hashes{SOME_FIELD},   @exact_keys);
    assert_keys($array_of_hashes[42],          @exact_keys);

Perl enforces this at compile-time by making you use either
a C<%> or C<$> sigil on the first argument to this assertion.

For many uses of exact hashes like this, you would be well
advised to lock the hash keys once you've validated them.

    use Hash::Util qw(lock_keys);
    my @exact_keys = qw[larry moe curly];
    assert_keys(%some_hash, @exact_keys);
    lock_keys(%some_hash);

or

    use Hash::Util qw(lock_ref_keys);

    my @exact_keys = qw[larry moe curly];
    assert_keys($some_hashref, @exact_keys);
    lock_ref_keys($some_hashref);

Now the I<keys> are locked down to keep your honest, although
the I<values> can be still be changed. See L<Hash::Util>.

=item assert_min_keys(I<HASH> | I<HASHREF>, I<KEY_LIST>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    assert_min_keys(%hash,    qw[blue green red]);
    assert_min_keys($hashref, qw[blue green red]);

Asserts that the hash or hashref argument contains at I<least> the keys
mentioned in the non-empty key list.

=item assert_max_keys(I<HASH> | I<HASHREF>, I<KEY_LIST>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    assert_max_keys(%hash,    qw[violet indigo blue cyan green yellow orange red]);
    assert_max_keys($hashref, qw[violet indigo blue cyan green yellow orange red]);

Asserts that the hash or hashref argument contains at I<most> the keys
mentioned in the non-empty key list. Consider locking your hash instead of just
checking for unwanted keys. The locking will make sure that no other keys
than these can be added to the hash:

    lock_keys(%hash,        qw[violet indigo blue cyan green yellow orange red]);
    lock_keys_ref($hashref, qw[violet indigo blue cyan green yellow orange red]);

Now you don't have to call L</assert_max_keys> at all.

=item assert_minmax_keys(I<HASH> | I<HASHREF>, I<MIN_ARRAY> | I<MIN_ARRAYREF>, I<MAX_ARRAY> | I<MAX_ARRAYREF>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    @minkeys = qw[red blue green];
    @maxkeys = (@minkeys, qw[orange yellow cyan indigo]);

    assert_minmax_keys(%hash,    @minkeys, @maxkeys);
    assert_minmax_keys($hashref, @minkeys, @maxkeys);

Asserts that the hash or hashref argument contains no other keys than the
maximum allowed ones specified, and that all of those from the minimum
required set exist.  The arguments must be actual variables (lvalues),
not merely anonymous values.

You can also pass the two pairs of minimum and maximum keys as scalar
variables holding arrayrefs instead:

    $minkeyref = \@minkeys;
    $maxkeyref = \@maxkeys;

    assert_minmax_keys(%hash,    $minkeyref, $maxkeyref);
    assert_minmax_keys($hashref, $minkeyref, $maxkeyref);

    @minmax = ($minkeyref, $maxkeyref);

    assert_minmax_keys(%hash,    $minmax[0], $minmax[1]);
    assert_minmax_keys($hashref, $minmax[0], $minmax[1]);

If you're careful to pass three refs of the right sorts in, you can
actually use this if you circumvent prototype checking:

    &assert_minmax_keys(\%hash,    @minmax);
    &assert_minmax_keys( $hashref, @minmax);

=item assert_locked(I<HASH> | I<HASHREF>)

=for comment
This is a workaround to create a "blank" line.

Z<>

B<WARNING>: Only available under version 0.15 and greater of L<Hash::Util,> first found in perl v5.17.

    assert_locked(%hash);
    assert_locked($hashref);

    assert_locked($array_of_hashes[0]);
    assert_locked($arrayref_of_hashes->[0]);

    assert_locked($hash_of_hashes{FIELD});
    assert_locked($hashref_of_hashes->{FIELD});

The argument, which must be either a hash variable or else a scalar
variable holding a hashref, must have locked keys.

=item assert_unlocked(I<HASH> | I<HASHREF>)

=for comment
This is a workaround to create a "blank" line.

Z<>

B<WARNING>: Only available under version 0.15 and greater of L<Hash::Util>, first found in perl v5.17.

    assert_unlocked(%hash);
    assert_unlocked($hashref);

    assert_unlocked($array_of_hashes[0]);
    assert_unlocked($arrayref_of_hashes->[0]);

    assert_unlocked($hash_of_hashes{FIELD});
    assert_unlocked($hashref_of_hashes->{FIELD});

The argument, which must be either a hash variable or else a scalar
variable holding a hashref, must not have locked keys.

=back

=head2 Legacy Assertions about Hashes

You should usually prefer L</assert_keys>, L</assert_min_keys>,
L</assert_max_keys>, and L</assert_minmax_keys> over the assertions in this
section, since those have better names and aren't so finicky about their
first argument. The following assertions are retained for backwards
compatibility, but internally they all turn into one of those four.

The thing to remember with these is that "required" keys really means I<at
B<least> these keys>, while "allowed" keys really means I<at B<most> these
keys>. If you need those to be the same set, then just use L</assert_keys>
directly.

=over

=item assert_hash_keys(I<HASH>, I<KEY_LIST>)

B<WARNING>: This does not mean what you think it means. Don't use it.

This function is misnamed; it is the deprecated, confusing, legacy version
of L</assert_min_keys>.  It really means L</assert_hash_keys_required>,
which in turn means "has at B<most> these keys". It does not mean has these
exact keys and nothing else.

For that, you want L</assert_keys>.

=item assert_hash_keys_required(I<HASH>, I<KEY_LIST>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    assert_hash_keys_required(%hash, qw[name rank serno]);

This is the legacy version of L</assert_min_keys>.
Means "has at B<most> these keys".

Each key specified in the key list must exist in the hash,
but it's ok if there are other non-required keys.

If immediately after you validate the required keys from the I<KEY_LIST>,
you intend to validate the allowed keys using that same I<KEY_LIST> because
you're required to have all your allowed keys:

    my @keys = qw[name rank serno];
    assert_hash_keys_required(%hash, @keys);
    assert_hash_keys_allowed (%hash, @keys);

Then it would be faster to just call L</assert_keys> in the first place.

    my @keys = qw[name rank serno];
    assert_keys(%hash, @keys);

However, if you plan to lock the hash when you're done validating it, then
you can let the key-locker do the "allowed" step implicitly:

    use Hash::Util qw(lock_keys);
    my @required = qw[name rank serno];
    my @allowed  = (@required, qw[spouse]);
    assert_hash_keys_required(%hash, @required);
    lock_keys(%hash, @allowed);

=item assert_hash_keys_allowed(I<HASH>, I<KEY_LIST>)

This is the legacy version of L</assert_max_keys>.
Means "has at B<least> these keys".

Only keys in the non-empty I<KEY_LIST> are allowed in the I<HASH>,
bit if some of those aren't there yet, that's ok.

For many applications of a hash, once you've validated that its keys are
all allowed, you would be well-advised to lock its keys afterwards so that
you know it can't ever get any stray keys added later that aren't in your
I<KEY_LIST>.  For example:

    use Hash::Util qw(lock_keys);
    my @possible_keys = qw[fee fie foe fum];
    assert_hash_keys_allowed(%some_hash, @possible_keys);
    lock_keys(%some_hash, @possible_keys);

If you're going to do that, you should skip the assertion and let the core
C code do all your checking for you, since it's much quicker that way.

    use Hash::Util qw(lock_keys);
    my @possible_keys = qw[fee fie foe fum];
    lock_keys(%some_hash, @possible_keys);

If the hash contains keys other than those listed, you'll still die
at that point.

=item assert_hash_keys_required_and_allowed(I<HASH>, I<MIN_ARRAYREF>, I<MAX_ARRAYREF>)

This is the legacy version of L</assert_minmax_keys>, but it does allow you
to pass the min and max arrayrefs as expressions rather than as named
variables.

 assert_hash_keys_required_and_allowed(%hash, [qw<fie fie foe>], [qw<fee foe foe fum]);

This lets you specify the minimal required keys and the maximum allowed
keys in the same assertion. You must pass the required and allowed keys by
arrayref so that they don't run together.

If you have them in arrays already, this is equivalent and is easier to
understand:

    @minkeys = qw(fee fie foe);
    @maxkeys = (@minkeys, "fum");
    assert_minmax_keys(%hash, @minkeys, @maxkeys);

=item assert_hash_keys_allowed_and_required(I<HASH>, I<MAX_ARRAYREF>, I<MIN_ARRAYREF>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

 assert_hash_keys_allowed_and_required(%hash, [qw<fee foe foe fum], [qw<fie fie foe>]);

This one flips the arguments, putting the maximum allowed keys before the
minimum required keys. It does not required named variables as all three
arguments the way L</assert_minmax_keys> does.

=item assert_hashref_keys(I<HASHREF>, I<KEY_LIST>)

B<WARNING>: This does not mean what you think it means. Don't use it.

This function is misnamed; it is the deprecated, confusing, legacy version
of L</assert_min_keys>.  It really means L</assert_hashref_keys_required>,
which in turn means "has at B<most> these keys". It does not mean has these
exact keys and nothing else.

For that, you want L</assert_keys>.

=item assert_hashref_keys_required(I<HASHREF>, I<KEY_LIST>)

This is the legacy version of L</assert_min_keys>.

Means "has at B<least> these keys".

Each key specified in the non-empty I<KEY_LIST> must exist in the
I<HASHREF>'s referent, but it's ok if there are other non-required keys.

See also the equivalent L</assert_min_keys> which works on both hashes and
hashrefs.

=item assert_hashref_keys_allowed(I<HASHREF>, I<KEY_LIST>)

This is the legacy version of L</assert_max_keys>.

Means "has at B<most> these keys".

Only keys in the non-empty I<KEY_LIST> are allowed in the hash by I<HASHREF>,
but no checks are done to make sure that those in particular are there yet.

For many applications of a hashref, once you've validated that its keys are
all allowed, you would be well-advised to lock its keys afterwards to that
you know it can't get any strays added later that aren't in your
I<KEY_LIST>.  For example:

    use Hash::Util qw(lock_ref_keys);

    my @allowed_keys = qw[fee fie foe fum];

    assert_hashref_keys_allowed($hashref, @allowed_keys);
    lock_ref_keys($hashref, @allowed_keys);

See also the equivalent L</assert_max_keys> which works on both hashes and hashrefs.

=item assert_hashref_keys_required_and_allowed(I<HASH>, I<MIN_ARRAYREF>, I<MAX_ARRAYREF>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

 assert_hashref_keys_required_and_allowed(%hash, [qw<fie fie foe>], [qw<fee foe foe fum]);

This is the reference version of L</assert_hash_keys_required_and_allowed>.

See also L</assert_minmax_keys>, which allowed both hashes and hashrefs as
the first argument, but requires either arrays or scalar variables holding
arrayrefs in the other two arguments.

=item assert_hashref_keys_allowed_and_required(I<HASH>, I<MAX_ARRAYREF>, I<MIN_ARRAYREF>)

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

 assert_hash_keys_allowed_and_required(%hash, [qw<fee foe foe fum], [qw<fie fie foe>]);

This is the legacy version of L</assert_minmax_keys>, but it does allow you
to pass the min and max arrayrefs as expressions rather than as named
variables.  The L<assert_minmax_keys> assertion requires either array
variables or scalar variables holding arrayrefs in the other two arguments.

This is the reference version of L</assert_hash_keys_allowed_and_required>.

=back

=head2 Assertions about References

=over

=item assert_anyref(I<ARG>)

Argument must be a reference.

=item assert_nonref(I<ARG>)

Argument must not be a reference.

=item assert_reftype(I<TYPE>, I<REF>)

The basic type of the reference must match the one specified.

=item assert_globref(I<ARG>)

Argument must be a GLOB ref.

=item assert_ioref(I<ARG>)

Argument must be a IO ref.  You probably don't
want this; you probably want L</assert_open_handle>.

=item assert_coderef(I<ARG>)

Argument must be a CODE ref.

=item assert_hashref(I<ARG>)

Argument must be a HASH ref.

=item assert_arrayref(I<ARG>)

Argument must be an ARRAY ref.

=item assert_scalarref(I<ARG>)

Argument must be a SCALAR ref.

=item assert_refref(I<ARG>)

Argument must be a REF ref.

=item assert_unblessed_ref(I<ARG>)

Scalar argument must be a ref of any sort but not a blessed one.

=back

=head2 Assertions about Objects

=over

=item assert_method()

Function must have at least one argument.

=item assert_object_method()

First argument to function must be blessed.

=item assert_class_method()

First argument to function must not be blessed.

=item assert_public_method()

Just like L</assert_method>. In other words, it makes sure that there's an
invocant, but beyond that does nothing other than add a bit of declarative
syntax to help document your intent.

Does not work under L<Test::Exception>.

=item assert_private_method()

Must have been called by a sub compiled from the same file and package.

Now, you would think this would be a trivial check, and it should be, but
the fluid-programming folks have decided they love to wrap and rewrap and
unwrap and rerewrap functions so that their stacks are a lie.  There are
uncountably many ways to "wrap" subroutines in perl, all of which introduce
extra frames that "shouldn't" be there and which cause this assertion to
suddenly fail.  As a sop to one of the more common ways, frames whose
calling package is L<Class::MOP::Method::Wrapped> are deliberately exempt
from this check, and are skipped over.

Moose roles do not have access to private methods, only to protected ones.
See next.

Does not work under L<Test::Exception>.

=item assert_protected_method()

The current sub must have been called by this package or from
that of one its subclasses.

Or...

Or...

Or...

Or something about Moose roles, whatever those are. If you use them, then
use this assertion at your own risk, but it I<seems> to work.

Maybe.

The protection racket is a terrible business model. Strongly consider
forbidding all access. A simpler life is a better life.

See also L<MooseX::Privacy>.

Does not work under L<Test::Exception>.

=item assert_known_package(I<ARG>)

The specified argument's package symbol table
is not empty.

=item assert_object(I<ARG>)

Argument must be an object.

=item assert_nonobject(I<ARG>)

Argument must not be an object.

=item assert_can(I<INVOCANT>, I<METHOD_LIST>)

The invocant, which can be a package name or an object but not an unblessed
reference, can invoke all the methods listed.

=item assert_cant(I<INVOCANT>, I<METHOD_LIST>)

The invocant, which can be a package name or an object but not an unblessed
reference, cannot invoke any of the methods listed.

=item assert_object_can(I<OBJECT>, I<METHOD_LIST>)

The object can invoke all of the methods listed.

=item assert_object_cant(I<OBJECT>, I<METHOD_LIST>)

The object cannot invoke any of the methods listed.

=item assert_class_can(I<CLASS>, I<METHOD_LIST>)

The known class can invoke all the methods listed.

=item assert_class_cant(I<CLASS>, I<METHOD_LIST>)

The known class cannot invoke any of the methods listed.

=item assert_isa(I<INVOCANT>, I<CLASS_LIST>)

The invocant, which can be a package name or an object but not an unblessed
reference, must be a subclass of each class listed.

=item assert_ainta(I<INVOCANT>, I<CLASS_LIST>)

The invocant cannot be a subclass of any class listed.

=item assert_object_isa(I<OBJECT>, I<CLASS_LIST>)

The object must be a subclass of each class listed.

=item assert_object_ainta

The object cannot be a subclass of any class listed.

=item assert_class_isa(I<CLASS>, I<CLASS_LIST>)

The known class must be a subclass of each class listed.

=item assert_class_ainta(I<CLASS>, I<CLASS_LIST>)

The known class cannot be a subclass of any class listed.

=item assert_does(I<INVOCANT>, I<CLASS_LIST>)

The invocant must C<< ->DOES >> each class in the class list.

=item assert_doesnt(I<INVOCANT>, I<CLASS_LIST>)

The invocant must not C<< ->DOES >> any class in the class list.

=item assert_object_overloads(I<OBJECT> [, I<OP_LIST> ])

=for comment
This is a workaround to create a "blank" line so that the code sample is distinct.

Z<>

    assert_object_overloads($some_object);

    assert_object_overloads($some_object, qw(+ += ++));

The I<OBJECT> argument must have overloaded operators.

If any operators are given in the I<OP_LIST>, then each of these
must also have an overload method.

See L<overload>.

=item assert_object_stringifies(I<OBJECT>)

The I<OBJECT> argument must have an overloaded stringification operator.

=item assert_object_nummifies(I<OBJECT>)

The I<OBJECT> argument must have an overloaded nummification operator.

(And yes, I meant to spell it this way: I<nummify> rhymes with I<mummify> and
I<dummify>, not with I<humify> and I<fumify>. We aren't talking about
making an object I<numinous>, which is something else entirely.)

=item assert_object_boolifies(I<OBJECT>)

The I<OBJECT> argument must have an overloaded boolification operator.

=item assert_tied(I<VARIABLE)>)

The I<VARIABLE> argument must be a tied C<$scalar>,
C<@array>, C<%hash>, or C<*glob>.

=item assert_untied(I<VARIABLE>)

The I<VARIABLE> argument must not be a tied C<$scalar>,
C<@array>, C<%hash>, or C<*glob>.

=item assert_tied_referent(I<REF>)

The I<REF> argument must be a reference to a tied C<$scalar>,
C<@array>, C<%hash>, or C<*glob>.

Consider that have this arrangement:

    tie my %hash, "DB_File", "/some/path";
    my $hashref = \%hash;

You could use

    assert_tied(%hash);

or you could use

    assert_tied_referent($hashref);

But you could not use

    assert_tied($hashref);

Because that would ask whether C<$hashref> itself has been tied,
not whether the thing it's referring to has been. For that, you
would use

    assert_tied_hashref($hashref);

=item assert_untied_referent(I<REF>)

The I<REF> argument must not be a reference to a tied C<$scalar>,
C<@array>, C<%hash>, or C<*glob>.

=item assert_tied_scalar(I<SCALAR>)

The I<SCALAR> argument must be tied to a class.

=item assert_untied_scalar(I<SCALAR>)

The I<SCALAR> argument must not be tied to a class.

=item assert_tied_scalarref(I<SCALARREF>)

The scalar referenced by I<SCALARREf> must be tied to a class.

=item assert_untied_scalarref(I<SCALARREF>)

The scalar referenced by I<SCALARREf> must not be tied to a class.

=item assert_tied_array(I<ARRAY>)

The I<ARRAY> argument must be tied to a class.

=item assert_untied_array(I<ARRAY>)

The I<ARRAY> argument must not be tied to a class.

=item assert_tied_arrayref(I<ARRAYREF>)

The array referenced by I<ARRAYREf> must be tied to a class.

=item assert_untied_arrayref(I<ARRAYREF>)

The array referenced by I<ARRAYREf> must not be tied to a class.

=item assert_tied_hash(I<HASH>)

The I<HASH> argument must be tied to a class.

=item assert_untied_hash(I<HASH>)

The I<HASH> argument must not be tied to a class.

=item assert_tied_hashref(I<HASHREF>)

The hash referenced by I<HASHREf> must be tied to a class.

=item assert_untied_hashref(I<HASHREF>)

The hash referenced by I<HASHREf> must not be tied to a class.

=item assert_tied_glob(I<GLOB>)

The I<GLOB> argument must be tied to a class.

=item assert_untied_glob(I<GLOB>)

The I<GLOB> argument must not be tied to a class.

=item assert_tied_globref(I<GLOBREF>)

The typeglob referenced by I<GLOBREf> must be tied to a class.

=item assert_untied_globref(I<GLOBREF>)

The typeglob referenced by I<GLOBREf> must not be tied to a class.

=back

=head2 Assertions about Code

=over

=item assert_happy_code(I<CODE_BLOCK>)

The supplied code block returns true.

This one and the next give nice error messages, but are not
wholly removed from your program's parse tree at compile time
is assertions are off: the argument is not called, but an empty
function is.

For example, if you want to assert that you have more than 10 elements
in your @colors array, you would write:

    assert_happy_code { @colors > 10 };

If the return value of that code block is false, then you'll see something like this:

  happy-test[96620]: botched assertion assert_happy_code: Happy test { @colors > 10 } is sadly false, bailing out at happy-test[96620] line 38.

When there is more than one statement, then the block is presented with newlines. For example:

    assert_happy_code {
        if (@colors < 10) {
            @allowed > 5;
        } else {
            @required > 5;
        }
    };

would indicate its failure this way:

  happy-test[96620]: botched assertion assert_happy_code: Happy test {
      if (@colors < 10) {
          @allowed > 5;
      } else {
          @required > 5;
      }
  } is sadly false, bailing out at happy-test line 38.

Notice how you can't tell which bit failed there, so it's best to use
simple "boolean" expressions.

=item assert_unhappy_code(I<CODE_BLOCK>)

The supplied code block returns false.  For example:

    assert_unhappy_code { @colors < 100 };

would say something like this if the assert fails:

  unhappy-test[96692]: botched assertion assert_unhappy_code: Unhappy assertion { @colors < 100 } is sadly true, bailing out at unhappy-test line 42.

=back

=head2 Assertions about Files

=over

=item assert_open_handle(I<ARG>)

The argument represents an open filehandle.

=item assert_regular_file(I<ARG>)

The argument is a regular file.

=item assert_text_file(I<ARG>)

The argument is a regular file and a text file.

=item assert_directory(I<ARG>)

The argument is a directory.

=back

=head2 Assertions about Processes

All these assertions take an optional status argument
as would be found in the C<$?> variable.  If not status
argument is passed, the C<$?> is used by default.

=over

=item assert_legal_exit_status( [ I<STATUS> ])

The numeric value fits in 16 bits.

=item assert_signalled( [ I<STATUS> ])

The process was signalled.

=item assert_unsignalled( [ I<STATUS> ])

The process was not signalled.

=item assert_dumped_core( [ I<STATUS> ])

The process dumped core.

=item assert_no_coredump( [ I<STATUS> ])

The process did not dump core.

=item assert_exited( [ I<STATUS> ])

The process was not signalled, but rather exited
either explicitly or implicitly.

=item assert_happy_exit( [ I<STATUS> ])

The process was not signalled and exited with an exit status of zero.

=item assert_sad_exit( [ I<STATUS> ])

The process was not signalled but exited with a non-zero exit status.

=back

=head1 EXAMPLES

Suppose your team has decided that assertions should be governed by an
environment variable called C<RUNTIME_MODE>.  You want assertions enabled
unless that variable is set to the string "production", or if there is an
C<NDEBUG> variable set.  And you want all the assertions except for those
related to files or processes; that is, you don't want those two classes
of assertions to be fatal in non-production, but the others you do.

You could call the module this way:

    use Env qw(RUNTIME_MODE NDEBUG);

    use Assert::Conditional ":all",
        -unless => ($RUNTIME_MODE eq "production" || $DEBUG);

    use Assert::Conditional qw(:file :process"), -if => 0;

On the other hand, you don't want everybody to have to
remember to type that in exactly the same way in every
module that uses it.  So you want to create a simpler
interface where the whole team just says

    use MyAsserts;

and it does the rest. Here's one way to do that:

    package MyAsserts;

    use v5.10;
    use strict;
    use warnings;

    use Env qw(RUNTIME_MODE NDEBUG);

    use Assert::Conditional ":all",
        -unless => ($RUNTIME_MODE eq "production" || $NDEBUG);

    use Assert::Conditional qw(:file :process),
        -if => 0;

    our @ISA = 'Exporter';
    our @EXPORT       = @Assert::Conditional::EXPORT_OK;
    our %EXPORT_TAGS  = %Assert::Conditional::EXPORT_TAGS;

Notice the module you wrote is just a regular exporter, not a fancier
conditional one. You've hidden the conditional part inside your module so
that everyone using it will get the same rules.

Imagine a program that enables all assertions except those related to
argument counts, and then runs through a bunch of them before hitting a
failed assertion, at which point you get a stack dump about the failure:

    $ perl -Ilib tests/test-assert
    check function called with 1 2 3
    test-assert[19009]: botched assertion assert_happy_code: Happy test { $i > $j } is sadly false, bailing out at tests/test-assert line 27.
       Beginning stack dump in Assert::Conditional::Utils::botch at lib/Assert/Conditional/Utils.pm line 413, <DATA> line 1.
            Assert::Conditional::Utils::botch('happy test $i > $j is sadly false') called at lib/Assert/Conditional.pm line 2558
            Assert::Conditional::_run_code_test('CODE(0x7f965a0025a0)', 1) called at lib/Assert/Conditional.pm line 2579
            Assert::Conditional::assert_happy_code('CODE(0x7f965a0025a0)') called at tests/test-assert line 27
            Anything::But::Main::Just::To::See::If::It::Works::check(1, 2, 3) called at tests/test-assert line 15

Here is that F<tests/test-assert> program:

    #!/usr/bin/env perl
    package Anything::But::Main::Just::To::See::If::It::Works;

    use strict;
    use warnings;

    use Assert::Conditional qw(:all)   => -if => 1;
    use Assert::Conditional qw(:argc)  => -if => 0;

    my $data = <DATA>;
    assert_bytes($data);
    my ($i, $j) = (25, 624);
    assert_numeric($_) for $i, $j;
    my $a = check(1 .. 1+int(rand 3));
    exit(0);

    sub check {
        assert_nonlist_context();
        assert_argc();
        assert_argc(37);
        assert_argc_min(37);
        my @args = @_;
        print "check function called with @args\n";
        assert_open_handle(*DATA);
        assert_happy_code   {$i < $j};
        assert_happy_code   {$i > $j};
        assert_unhappy_code {$i < $j};
        assert_unhappy_code {$i > $j};
        check_args(4, 2);
        assert_array_length(@_);
        assert_array_length(@_, 11);
        assert_argc_minmax(-54, 10);
        assert_unhappy_code(sub {$i < $j});
        assert_array_length_min(@_ => 20);
        assert_class_method();
        assert_void_context();
        assert_list_context();
        assert_nonlist_context();
        assert_scalar_context();
        assert_nonvoid_context();
        assert_in_numeric_range($i, 10, 30);
        assert_unhappy_code(\&check_args);
        return undef;
    }

    sub check_args {
        print "checking args for oddity\n";
        assert_odd_number(int(rand(10)));
    }

    __DATA__
    stuff

The reason the first failure is C<< $i > $j >> one is because the earlier
assertions either passed (L</assert_nonlist_context>, L</assert_open_handle>)
or were skipped because argc assertions were explicitly disabled.

However, if you instead ran the program this way, you would override that skipping of argc checked,
and so it would blow up right away there:

    $ ASSERT_CONDITIONAL=always perl -I lib tests/test-assert
    test-assert[19107]: botched assertion assert_argc: Have 3 arguments but wanted 37, bailing out at tests/test-assert line 21.
       Beginning stack dump in Assert::Conditional::Utils::botch at lib/Assert/Conditional/Utils.pm line 413, <DATA> line 1.
            Assert::Conditional::Utils::botch('have 3 arguments but wanted 37') called at lib/Assert/Conditional/Utils.pm line 480
            Assert::Conditional::Utils::botch_have_thing_wanted('HAVE', 3, 'THING', 'argument', 'WANTED', 37) called at lib/Assert/Conditional/Utils.pm line 455
            Assert::Conditional::Utils::botch_argc(3, 37) called at lib/Assert/Conditional.pm line 2119
            Assert::Conditional::assert_argc(37) called at tests/test-assert line 21
            Anything::But::Main::Just::To::See::If::It::Works::check(1, 2, 3) called at tests/test-assert line 15

You can also disable all assertions completely, no matter the import was doing. Then they aren't ever called at all:

    $ ASSERT_CONDITIONAL=never perl -I lib tests/test-assert
    check function called with 1
    checking args for oddity

Finally, you can run with assertions in carp mode.  This runs them all, but they never raise an exception.
Here's what an entire run would look like:

    $ ASSERT_CONDITIONAL=carp perl -I lib tests/test-assert
    test-assert[19129]: botched assertion assert_argc: Have 2 arguments but wanted 37 at tests/test-assert line 21.
    test-assert[19129]: botched assertion assert_argc_min: Have 2 arguments but wanted 37 or more at tests/test-assert line 22.
    check function called with 1 2
    test-assert[19129]: botched assertion assert_happy_code: Happy test { $i > $j } is sadly false at tests/test-assert line 27.
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test { $i < $j } is sadly true at tests/test-assert line 28.
    checking args for oddity
    test-assert[19129]: botched assertion assert_odd_number: 4 should be odd at tests/test-assert line 49.
    test-assert[19129]: botched assertion assert_array_length: Have 2 array elements but wanted 11 at tests/test-assert line 32.
    test-assert[19129]: botched assertion assert_nonnegative: -54 should not be negative at tests/test-assert line 33.
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test { $i < $j } is sadly true at tests/test-assert line 34.
    test-assert[19129]: botched assertion assert_array_length_min: Have 2 array elements but wanted 20 or more at tests/test-assert line 35.
    test-assert[19129]: botched assertion assert_void_context: Wanted to be called in void context at tests/test-assert line 37.
    test-assert[19129]: botched assertion assert_list_context: Wanted to be called in list context at tests/test-assert line 38.
    checking args for oddity
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test { Anything::But::Main::Just::To::See::If::It::Works::check_args() } is sadly true at tests/test-assert line 43.

Notice how even though those assertions botch, they don't bail out of your program.

=head1 ENVIRONMENT

=head2 ASSERT_CONDITIONAL

The C<ASSERT_CONDITIONAL> variable controls the behavior of the underlying
C<botch> function from L<Assert::Conditional::Utils>, and also of the the
conditional importing itself. If unset, assertions are on.

Its allowable values are:

=over

=item ASSERT_CONDITIONAL=never

Assertions are never imported, and even if you somehow manage to import
them, they will never never make a peep nor raise an exception.

=item ASSERT_CONDITIONAL=always

Assertions are always imported, and even if you somehow manage to avoid importing
them, they will still raise an exception on error.

=item ASSERT_CONDITIONAL=carp

Assertions are always imported but they do not raise an exception if they fail;
instead they all carp at you.  This is true even if you manage to call an assertion
you haven't imported.

=back

=head2 ASSERT_CONDITIONAL_ALLOW_HANDLERS

Normally, any user-registered pseudo-signal handlers in C<$SIG{__WARN__}>
or C<$SIG{__DIE__}> are locally ignored when a failed assertion needs to
generate a C<confess> (or under C<ASSERT_CONDITIONAL=carp>, a C<carp>).

Enabling this option from the environment leaves those handlers active
instead, which for example means that if you have a C<$SIG{__WARN__}>
handler that promotes a warning into a dying, even a carped assertion
failure will kill you.

=head2 ASSERT_CONDITIONAL_BUILD_POD

This is used internally by the build tools to construct the pod for the
exporter tag groups.  See the F<etc/generate-exporter-pod> script in the
module source directory, which sets that variable and then runs this very
module as an executable program instead of requiring it. Sneaky, I know.

=head2 ASSERT_CONDITIONAL_DEBUG

This adds some debugging used when for debugging the assertions themselves,
and in their import/export handling; These are also triggered by
C<$Exporter::Verbose>.

Currently this is used only in the attribute handlers that register exports
during compile time.

=head1 BACKGROUND NOTES

Here are the design goals for C<Assert::Conditional>:

=over

=item *

Make easy things easy: by making assertions so easy to write and so cheap
to use, no one will have any reason not to use them.

=item *

Pass as few arguments as you can to each assertion, and don't require
an easily forgotten C<... if DEBUG()> to disable them.

=item *

Create a rich set of assertions related to Perl code to check things
such as calling context, argument numbers and times, and various other
assumptions about the code or the data.

These not only provide sanity checks while running, they also help make the
code more readable.  If a boolean test were all that one ever needed, there
would only ever be a C<test_ok> function.  Richer function names are
better.

=item *

Provide descriptive failure messages that help pinpoint the exact
error, not just "assertion failed".

=item *

Make assertions that can be made to disappear from your program
without any runtime cost if needed, yet which can also be re-enabled
through a runtime mechanism without touching the code.

=item *

Provide a way for assertions to be run and checked, but which
are not fatal to the program.  (Raise no exception.)

=item *

Allow assertions to be enabled or disabled either I<en masse> or piecemeal,
picking and choosing from sets of related assertions to enable or disable.
In other words, make them work a bit like lexical warnings where you can
say give me all of this group, except for these ones.

=item *

Require no complicated framework setup to use.

=item *

Make it obvious what went wrong.

=item *

Keep the implementation of each assertion as short and simple as possible.
This documentation is much longer than the code itself.

=item *

Use nothing but Standard Perl save at great need.

=item *

Compatible to Perl version 5.10 whenever possible. (This didn't pan out; it needs 5.12.)

=back

The initial alpha release was considered completely experimental, but even
so all these goals were met.  The only module required that is not part of
the standard Perl release is the underlying L<Exporter::ConditionalSubs>
which this module inherits its import method from.  That module is where
(most of) the magic happens to make assertions get compiled out of your
program.  You should look at that module for how the "conditional
importing" works.

=head1 SEE ALSO

=over

=item *

The L<Exporter::ConditionalSubs> module which this module is based on.

=item *

The L<Assert::Conditional::Utils> module provides some semi-standalone utility
functions.

=back

=head1 CAVEATS AND PROVISOS

This is a beta release.

=head1 BUGS AND LIMITATIONS

Under versions of Perl previous to v5.12.1, Attribute::Handlers
blows up with an internal error about a symbol going missing.

=head1 HISTORY

 0.001    6 June 2015 23:28 MDT
        - Initial alpha release

 0.002    J June 2015 22:35 MDT
        - MONGOLIAN VOWEL SEPARATOR is no longer whitespace in Unicode, so removed from test.

 0.003    Tue Jun 30 05:47:16 MDT 2015
        - Added assert_hash_keys_required and assert_hash_keys_allowed.
        - Fixed some tests.
        - Added bug report about Attribute::Handlers bug prior to 5.12.

 0.004    11 Feb 2018 11:18 MST
        - Suppress overloading in botch messages for object-related assertions (but not others).
        - Don't carp if we're throwing an exception and exceptions are trapped.
        - Support more than one word in ASSERT_CONDITIONAL (eg: "carp,always").
        - If ASSERT_CONDITIONAL contains "handlers", don't block @SIG{__{WARN,DIE}__}.
        - Don't let assert_isa die prematurely on an unblessed ref.

 0.005   Sun May 20 20:40:25 CDT 2018
       - Initial beta release.
       - Reworked the hash key checkers into a simpler set: assert_keys, assert_min_keys, assert_max_keys, assert_minmax_keys.
       - Added invocant-specific assertions: assert_{object,class}_{isa,ainta,can,cant}.
       - Added assertions for ties, overloads, and locked hashes.
       - Made assert_private_method work despite Moose wrappers.
       - Added assert_protected_method that works despite Moose wrappers and roles.
       - Improved the looks of the uncompiled code for assert_happy_code.
       - Fixed botch() to identify the most distant stack frame not the nearest for the name of the failed assertion.
       - Improved the reporting of some assertion failures.

 0.006   Mon May 21 07:45:43 CDT 2018
       - Use hash_{,un}locked not hashref_{,un}locked to support pre-5.16 perls.
       - Unhid assert_unblessed_ref swallowed up by stray pod.

 0.007   Mon May 21 19:13:58 CDT 2018
       - Add missing Hash::Util version requirement for old perls to get hashref_unlock imported.

 0.008   Tue May 22 11:51:37 CDT 2018
       - Rewrite hash_unlocked missing till 5.16 as !hash_locked
       - Add omitted etc/generate-exporter-pod to MANIFEST

 0.009   Tue Aug 21 06:29:56 MDT 2018
       - Delay slow calls to uca_sort till you really need them, credit Larry Leszczynski.

 0.010   Sun Jul 19 13:52:00 MDT 2020
       - Fix coredump in perl 5.12 by replacing UNITCHECK in Assert::Conditional::Util with normal execution at botton.
       - Make perls below 5.18 work again by setting Hash::Util prereq in Makefile.PL to 0 because it's in the core only, never cpan.
       - Only provide assert_locked and assert_unlocked if core Hash::Util v0.15 is there (starting perl v5.17).
       - Bump version req of parent class Exporter::ConditionalSubs to v1.11.1 so we don't break Devel::Cover.
       - Normalize Export sub attribute tracing so either $Exporter::Verbose=1 or env ASSERT_CONDITIONAL_DEBUG=1 work for both Assert::Conditional{,::Utils}.
       - Mentioned $Exporter::Verbose support.

=head1 AUTHOR

Tom Christiansen C<< <tchrist53147@gmail.com> >>

Thanks to Larry Leszczynski at Grant Street Group for making this module
possible.  Without it, my programs would be much slower, since before I
added his module to my old and pre-existing assertion system, the
assertions alone were taking up far too much CPU time.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015-2018, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
