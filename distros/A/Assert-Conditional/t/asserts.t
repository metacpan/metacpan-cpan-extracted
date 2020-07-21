#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use utf8;
use charnames qw(:full);

#use Carp::Always;

use Cwd qw(abs_path);
use FindBin qw($Bin);

$| = 1;

use lib abs_path("$Bin/../lib");

use Config qw(%Config); # because it's tied
use Math::BigInt; # for overloads
use Env qw($PATH @PATH); # because they're tied

use Test::More;
use Test2::Tools::Exception qw(dies lives);

use IO::File;
use IO::Handle;
use Hash::Util qw(lock_keys unlock_keys);

use Assert::Conditional qw(:all -if 1);
use Assert::Conditional::Utils qw(:list);

my($junk, @junk) ;

my $undef;
my $zero      = 0;
my $true      = 1;
my $one       = 1;
my $two       = 2;
my $minus_two = -2;
my $float     = 3.14;
my $string    = "string";
my @empty     = ();
my %empty;
my @stuff     = ("a" .. "z");
my @ten       = (1 .. 10);
my $class     = "IO::File";
my $obj       = $class->new();

my @primary_colors    = qw(red green blue);
my @all_colors        = (@primary_colors, qw(orange yellow cyan violet));
my @not_colors        = qw(black white pink purple);
my %primary_color     = map { $_ => 1 } @primary_colors;
my $primary_color_ref = \%primary_color;

my %locked_hash       =  %primary_color;
my $locked_hashref    = \%locked_hash;
lock_keys %locked_hash;
my %unlocked_hash     =  %primary_color;
my $unlocked_hashref  = \%unlocked_hash;

my %hash_of_hashes = (
    LOCKED  => $locked_hashref,
    UNLOCKED => $unlocked_hashref,
);

my $hashref_of_hashes        =  \%hash_of_hashes;
my $ref_of_hashref_of_hashes = \\%hash_of_hashes;

my $bignum = Math::BigInt->new("1000");

my $tied_object = do { 
    no warnings "once"; 
    tie *Tied_FH, "TieOut";
};

sub  void_context     {  assert_void_context()     }
sub  nonvoid_context  {  assert_nonvoid_context()  }
sub  list_context     {  assert_list_context()     }
sub  nonlist_context  {  assert_nonlist_context()  }
sub  scalar_context   {  assert_scalar_context()   }

my @good_tests = (

    q{assert_defined(1) },
    q{assert_defined_value(1) },
    q{assert_undefined(undef) },
    q{assert_defined("string") },
    q{assert_defined_value("string") },
    q{assert_defined_variable($true) },

    q{@junk = list_context() },
    q{$junk = nonlist_context() },
    q{@junk = nonvoid_context() },
    q{nonlist_context(); 0      },
    q{void_context(); 1      },
    q{$junk = nonvoid_context() },
    q{$junk = scalar_context() },
    q{@junk = list_context() },

    q{assert_false(!1) },
    q{assert_false(0) },
    q{assert_false(q()) },
    q{assert_false(undef) },
    q{assert_true('0 but true') },
    q{assert_true(1) },

    q{assert_is($one, $one)},
    q{assert_is($float, $float)},
    q{assert_is(@stuff, @stuff)},
    q{assert_isnt($one, $two)},

    q{assert_zero($zero)},
    q{assert_zero(+0)},
    q{assert_zero("-0")},
    q{assert_zero(0.0)},

    q{assert_numeric($one)},
    q{assert_numeric($float)},
    q{assert_numeric($minus_two)},
    q{assert_nonnumeric("stuff")},
    q{assert_negative($minus_two)},
    q{assert_positive($two)},
    q{assert_nonnegative($zero)},
    q{assert_nonpositive($zero)},
    q{assert_nonzero($one)},
    q{assert_integer($one)},
    q{assert_fractional($float)},
    q{assert_signed_number("+5")},
    q{assert_signed_number("-5")},
    q{assert_signed_number("+0")},
    q{assert_signed_number("-0")},
    q{assert_natural_number($one)},
    q{assert_natural_number($two)},
    q{assert_natural_number(6.02e34)},
    q{assert_whole_number($zero)},
    q{assert_whole_number($one)},
    q{assert_whole_number($two)},
    q{assert_positive_integer($one)},
    q{assert_positive_integer(6.02e23)},
    q{assert_nonpositive_integer($zero)},
    q{assert_nonpositive_integer($minus_two)},
    q{assert_nonpositive_integer(-5*5)},
    q{assert_nonpositive_integer(-5**5)},
    q{assert_negative_integer($minus_two)},
    q{assert_negative_integer(-5)},
    q{assert_nonnegative_integer($zero)},
    q{assert_nonnegative_integer($one)},
    q{assert_nonnegative_integer($two)},

    q{assert_hex_number('0xFF')},
    q{assert_hex_number('FF')},
    q{assert_hex_number('0bFF')},  # Wicked
    q{assert_box_number('0b00')},
    q{assert_box_number('0o00')},
    q{assert_box_number('0x00')},
    q{assert_box_number('000')},
    q{assert_box_number('077')},
    q{assert_box_number('77')},
    q{assert_box_number($one)},

    q{assert_odd_number($one)},
    q{assert_even_number($two)},
    q{assert_even_number($minus_two)},

    q{assert_in_numeric_range(5,1,10)},
    q{assert_in_numeric_range(5.6,1,10)},
    q{assert_in_numeric_range(5.6,-1,10)},

    q{assert_empty("")},
    q{assert_empty(!1)},
    q{assert_nonempty(" ")},
    q{assert_nonempty("\0")},
    q{assert_blank(" ")},
    q{assert_blank("\t")},
    q{assert_blank("\n")},
    q{assert_blank("\r\n")},
    q{assert_blank("\f")},
    q{assert_blank("\xA0")},
    q{assert_blank("\cK")},
    q{assert_blank("\x{0009}")},
    q{assert_blank("\x{000A}")},
    q{assert_blank("\x{000B}")},
    q{assert_blank("\x{000C}")},
    q{assert_blank("\x{000D}")},
    q{assert_blank("\x{0020}")},
    q{assert_blank("\x{0085}")},
    q{assert_blank("\x{00A0}")},
    q{assert_blank("\x{1680}")},
    q{assert_blank("\x{2000}")},
    q{assert_blank("\x{2001}")},
    q{assert_blank("\x{2002}")},
    q{assert_blank("\x{2003}")},
    q{assert_blank("\x{2004}")},
    q{assert_blank("\x{2005}")},
    q{assert_blank("\x{2006}")},
    q{assert_blank("\x{2007}")},
    q{assert_blank("\x{2008}")},
    q{assert_blank("\x{2009}")},
    q{assert_blank("\x{200A}")},
    q{assert_blank("\x{2028}")},
    q{assert_blank("\x{2029}")},
    q{assert_blank("\x{202F}")},
    q{assert_blank("\x{205F}")},
    q{assert_blank("\x{3000}")},
    q{assert_nonblank($one)},
    q{assert_single_line(4)},
    q{assert_single_line($string)},

    q{assert_single_line("abc\x{000A}")},
    q{assert_single_line("abc\x{000B}")},
    q{assert_single_line("abc\x{000C}")},
    q{assert_single_line("abc\x{000D}")},
    q{assert_single_line("abc\x{0085}")},
    q{assert_single_line("abc\x{2028}")},
    q{assert_single_line("abc\x{2029}")},

    q{assert_single_paragraph("abc\x{000A}")},
    q{assert_single_paragraph("abc\x{000B}")},
    q{assert_single_paragraph("abc\x{000C}")},
    q{assert_single_paragraph("abc\x{000D}")},
    q{assert_single_paragraph("abc\x{0085}")},
    q{assert_single_paragraph("abc\x{2028}")},
    q{assert_single_paragraph("abc\x{2029}")},

    q{assert_multi_line("one\ntwo\n")},
    q{assert_multi_line("one\rtwo\n")},
    q{assert_multi_line("one\rtwo\f")},

    q{assert_multi_line("abc\x{000A} ")},
    q{assert_multi_line("abc\x{000B} ")},
    q{assert_multi_line("abc\x{000C} ")},
    q{assert_multi_line("abc\x{000D} ")},
    q{assert_multi_line("abc\x{0085} ")},
    q{assert_multi_line("abc\x{2028} ")},
    q{assert_multi_line("abc\x{2029} ")},

    q{assert_single_paragraph("one")},
    q{assert_single_paragraph("one\f")},
    q{assert_single_paragraph("one\r\n")},
    q{assert_single_paragraph("one\n\n\f")},

    q{assert_bytes("abc")},
    q{assert_bytes("\xA0")},
    q{assert_nonbytes("\x{223}")},
    q{assert_wide_characters("\x{223}")},
    q{assert_nonascii("\x{223}")},
    q{assert_ascii("zzz")},
    q{assert_alphabetic("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_nonalphabetic("~!")},
    q{assert_alnum("abc39sd")},
    q{assert_digits("12349120")},
    q{assert_uppercased("THIS OLD MAN!")},
    q{assert_lowercased("this old man!")},
    q{assert_unicode_ident("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_simple_perl_ident("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_full_perl_ident("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_qualified_ident("main::ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_ascii_ident("nino")},

    q{assert_regex(qr/foo/)},
    q{assert_like("foo", qr/f/)},
    q{assert_unlike("foo", qr/z/)},
    q{assert_latin1("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_latinish("Henry \N{ROMAN NUMERAL EIGHT}")},

    q{assert_astral("\x{012345}")},
    q{assert_nonastral("fred")},
    q{assert_bmp("ni\x{223}o")},
    q{assert_nfc("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_nfd("nin\x{303}o")},
    q{assert_nfkc("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_nfkd("nin\x{303}o")},
    q{assert_eq("ni\N{LATIN SMALL LETTER N WITH TILDE}o", "nin\x{303}o")},
    q{assert_eq_letters("----one, two", "ONE, TWO")},
    q{assert_eq_letters("one, two", "ONE, TWO")},
    q{assert_eq_letters("one, two", "ONE TWO")},
    q{assert_eq_letters("one two", "ONE TWO")},
    q{assert_eq_letters("one two", "ONE, TWO")},

    q{assert_in_list("red", qw(one fish two fish red fish blue fish))},
    q{assert_in_list(5, 1 .. 10)},
    q{assert_in_list(5, 1, 3, undef, [], 5, 10)},
    q{assert_in_list(\@ARGV, 1, 3, undef, \@ARGV, 5, 10)},
    q{assert_in_list(undef, 1 .. 10, undef)},
    q{assert_in_list(undef, undef)},

    q{assert_not_in_list("red", qw(one fish two fish fish blue fish))},
    q{assert_not_in_list(5, 6 .. 10)},
    q{assert_not_in_list(1, 20 .. 30)},
    q{assert_not_in_list(5, 1, 3, undef, [], 10)},
    q{assert_not_in_list(undef, 1 .. 10)},
    q{assert_not_in_list(undef)},

    q{assert_list_nonempty( 1..10 )},

    q{assert_array_nonempty( @stuff )},
    q{assert_arrayref_nonempty( \@stuff )},
    q{assert_arrayref_nonempty( [1..5] )},

    q{assert_array_length(@ten)},
    q{assert_array_length(@ten, 10)},
    q{assert_array_length_min(@ten, 5)},
    q{assert_array_length_max(@ten, 10)},
    q{assert_array_length_minmax(@ten, 5, 20)},

    q{ no warnings 'redefine'; sub fn0    {  assert_argc_min(5) }  fn0(localtime()) },
    q{ no warnings 'redefine'; sub fn1($) {  assert_argc(1) }      fn1(localtime()) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc(3) }      fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc    }      fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_max(3) }      fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_max(5) }      fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_minmax(1,5) }      fn2(1, 2, 3) },

    q{assert_hash_nonempty(%primary_color)},
    q{assert_hashref_nonempty(\%primary_color)},
    
    q{assert_hash_keys(%primary_color, qw<red blue green>)},
    q{assert_hashref_keys(\%primary_color, qw<red blue green>)},

    q{assert_hash_keys_required(%primary_color, qw<red blue green>)},
    q{assert_hash_keys_allowed(%primary_color, qw<red blue green>)},

    q{assert_hash_keys_required_and_allowed(%primary_color, ["red"], [qw<red blue green>])},
    q{assert_hashref_keys_required_and_allowed(\\%primary_color, ["red"], [qw<red blue green>])},
    q{assert_hashref_keys_required_and_allowed($primary_color_ref, ["red"], [qw<red blue green>])},
    q{assert_hash_keys_allowed_and_required(%primary_color, [qw<red blue green>], ["red"])},
    q{assert_hashref_keys_allowed_and_required(\\%primary_color, [qw<red blue green>], ["red"])},
    q{assert_hashref_keys_allowed_and_required($primary_color_ref, [qw<red blue green>], ["red"])},

    q{assert_hashref_keys_required(\\%primary_color, qw<red blue green>)},
    q{assert_hashref_keys_allowed(\\%primary_color, qw<red blue green>)},
    q{assert_hashref_keys_required($primary_color_ref, qw<red blue green>)},
    q{assert_hashref_keys_allowed($primary_color_ref, qw<red blue green>)},

    q{assert_keys(%primary_color, qw<red blue green>)},
    q{assert_keys(%primary_color, @primary_colors)},
    q{assert_keys($primary_color_ref, qw<red blue green>)},
    q{assert_keys($primary_color_ref, @primary_colors)},

    q{assert_min_keys(%primary_color, qw<red blue green>)},
    q{assert_min_keys(%primary_color, @primary_colors)},
    q{assert_min_keys($primary_color_ref, qw<red blue green>)},
    q{assert_min_keys($primary_color_ref, @primary_colors)},

    q{assert_max_keys(%primary_color, qw<red orange yellow green blue violet>)},
    q{assert_max_keys(%primary_color, @all_colors)},
    q{assert_max_keys($primary_color_ref, qw<red orange yellow green blue violet>)},
    q{assert_max_keys($primary_color_ref, @all_colors)},

    q{assert_minmax_keys(%primary_color, @primary_colors, @all_colors)},
    q{assert_minmax_keys($primary_color_ref, @primary_colors, @all_colors)},

    q{assert_anyref( \"string" )},
    q{assert_anyref( \0 )},
    q{assert_anyref( \$0 )},
    q{assert_anyref( *0{SCALAR} )},
    q{assert_anyref( \\\$0 )},
    q{assert_anyref( \@ARGV )},
    q{assert_anyref( [ ] )},
    q{assert_anyref( \%ENV )},
    q{assert_anyref( { }  )},
    q{assert_anyref( sub { }  )},
    q{assert_anyref( \&lives  )},
    q{assert_anyref( \time()  )},
    q{assert_anyref( \*ENV )},
    q{assert_anyref( *STDIN{IO} )},
    q{assert_anyref( *ARGV{ARRAY} )},
    q{assert_anyref( *{$main::{ARGV}}{ARRAY} )},

    q{assert_reftype( SCALAR  =>  \"string"                )},
    q{assert_reftype( SCALAR  =>  \0                       )},
    q{assert_reftype( SCALAR  =>  \$0                      )},
    q{assert_reftype( SCALAR  =>  *0{SCALAR}               )},
    q{assert_reftype( REF     =>  \\\$0                    )},
    q{assert_reftype( ARRAY   =>  \@ARGV                   )},
    q{assert_reftype( REF     =>  \\\\\@ARGV                 )},
    q{assert_reftype( ARRAY   =>  [ ]                      )},
    q{assert_reftype( HASH    =>  \%ENV                    )},
    q{assert_reftype( HASH    =>  {  }                     )},
    q{assert_reftype( CODE    =>  sub  {    }              )},
    q{assert_reftype( CODE    =>  \&lives               )},
    q{assert_reftype( SCALAR  =>  \time()                  )},
    q{assert_reftype( GLOB    =>  \*ENV                    )},
    q{assert_reftype( IO      =>  *STDIN{IO}               )},
    q{assert_reftype( ARRAY   =>  *ARGV{ARRAY}             )},
    q{assert_reftype( ARRAY   =>  *{$main::{ARGV}}{ARRAY}  )},

    q{assert_scalarref(  \"string"    )},
    q{assert_scalarref(  \0           )},
    q{assert_scalarref(  \$0          )},
    q{assert_scalarref(  *0{SCALAR}   )},
    q{assert_refref(     \\\$0        )},
    q{assert_refref(   \\\\\\@ARGV       )},
    q{assert_arrayref(   \@ARGV       )},
    q{assert_arrayref(   [ ]          )},
    q{assert_hashref(    \%ENV        )},
    q{assert_hashref(    { }          )},
    q{assert_coderef(    sub {    }   )},
    q{assert_coderef(    \&lives   )},
    q{assert_scalarref(  \time()      )},
    q{assert_globref(    \*ENV        )},
    q{assert_ioref(      *STDIN{IO}   )},
    q{assert_arrayref(   *ARGV{ARRAY}             )},
    q{assert_arrayref(   *{$main::{ARGV}}{ARRAY}  )},

    q{assert_unblessed_ref(  \"string"    )},
    q{assert_unblessed_ref(  \0           )},
    q{assert_unblessed_ref(  \$0          )},
    q{assert_unblessed_ref(  *0{SCALAR}   )},
    q{assert_unblessed_ref(     \\\$0        )},
    q{assert_unblessed_ref(   \\\\\\@ARGV       )},
    q{assert_unblessed_ref(   \@ARGV       )},
    q{assert_unblessed_ref(   [ ]          )},
    q{assert_unblessed_ref(    \%ENV        )},
    q{assert_unblessed_ref(    { }          )},
    q{assert_unblessed_ref(    sub {    }   )},
    q{assert_unblessed_ref(    \&lives   )},
    q{assert_unblessed_ref(  \time()      )},
    q{assert_unblessed_ref(    \*ENV        )},
    q{assert_unblessed_ref(   *ARGV{ARRAY}             )},
    q{assert_unblessed_ref(   *{$main::{ARGV}}{ARRAY}  )},

    q{assert_known_package("IO::File")},
    q{assert_known_package(IO::File::)},
    q{assert_object($obj)},
    q{assert_nonobject($class)},
    q{assert_nonobject(ref $obj)},

    q{sub { assert_class_method() }->($class) },
    q{sub { assert_object_method() }->($obj) },

    q{sub { assert_method() }->($class) },
    q{sub { assert_method() }->($obj) },

    q{assert_can($class, qw(close open))},
    q{assert_can($class, qw(isa can VERSION))},
    q{assert_can($class, qw(new))},

    q{assert_class_can($class, qw(close open))},
    q{assert_class_can($class, qw(isa can VERSION))},
    q{assert_class_can($class, qw(new))},

    q{assert_can($obj, qw(IO::Handle::new))},
    q{assert_can($obj, qw(UNIVERSAL::isa))},
    q{assert_can($obj, qw(close open))},
    q{assert_can($obj, qw(isa can VERSION))},
    q{assert_can($obj, qw(new))},

    q{assert_object_can($obj, qw(IO::Handle::new))},
    q{assert_object_can($obj, qw(UNIVERSAL::isa))},
    q{assert_object_can($obj, qw(close open))},
    q{assert_object_can($obj, qw(isa can VERSION))},
    q{assert_object_can($obj, qw(new))},

    q{assert_cant($class, "dlk s lkd l slkds" )},
    q{assert_cant($class, 23 )},
    q{assert_cant($class, 3.14 )},
    q{assert_cant($obj, "dlk s lkd l slkds" )},
    q{assert_cant($obj, 23 )},
    q{assert_cant($obj, 3.14 )},

    q{assert_ainta($class, $obj)},
    q{assert_ainta($obj, "IO")},
    q{assert_ainta($obj, "Regexp")},
    q{assert_ainta($obj, $obj)},

    q{assert_isa($class, "IO::File")},
    q{assert_isa($class, "IO::Handle")},
    q{assert_isa($class, "UNIVERSAL")},
    q{assert_isa($class, $class)},
    q{assert_isa($class, UNIVERSAL::)},
    q{assert_isa($class, qw<IO::Handle IO::File>)},

    q{assert_class_isa($class, "IO::File")},
    q{assert_class_isa($class, "IO::Handle")},
    q{assert_class_isa($class, "UNIVERSAL")},
    q{assert_class_isa($class, $class)},
    q{assert_class_isa($class, UNIVERSAL::)},
    q{assert_class_isa($class, qw<IO::Handle IO::File>)},

    q{assert_class_ainta($class, qw<IO Regexp>)},

    q{assert_object_isa($obj,  <IO::{Handle,File}>)},
    q{assert_object_isa($obj, "IO::File")},
    q{assert_object_isa($obj, "IO::Handle")},
    q{assert_object_isa($obj, "UNIVERSAL")},
    q{assert_object_isa($obj, $class)},
    q{assert_object_isa($obj, UNIVERSAL::)},
    q{assert_object_isa($obj, qw<IO::Handle IO::File> )},

    q{assert_object_isa($bignum, qw<Math::BigInt> )},

    q{assert_object_cant($bignum, qw<Math  BigInt> )},
    q{assert_object_can($bignum, qw<bround fround is_even is_odd> )},

    q{ assert_tied($PATH) },
    q{ assert_tied(%Config) },
    q{ assert_tied(@PATH) },
    q{ assert_tied(*Tied_FH) },

    q{ assert_tied_referent(\\$PATH) },
    q{ assert_tied_referent(\\%Config) },
    q{ assert_tied_referent(\\@PATH) },
    q{ assert_tied_referent(\\*Tied_FH) },

    q{ assert_tied_scalar($PATH) },
    q{ assert_tied_scalarref(\\$PATH) },

    q{ assert_tied_array(@PATH) },
    q{ assert_tied_arrayref(\\@PATH) },

    q{ assert_tied_hash(%Config) },
    q{ assert_tied_hashref(\\%Config) },

    q{ assert_tied_glob(*Tied_FH) },
    q{ assert_tied_globref(\\*Tied_FH) },

    q{assert_untied($0)},
    q{assert_untied(@ARGV)},
    q{assert_untied(%ENV)},
    q{assert_untied(*STDIN)},

    q{assert_untied_referent(\\$0)},
    q{assert_untied_referent(\\@ARGV)},
    q{assert_untied_referent(\\%ENV)},
    q{assert_untied_referent(\\*STDIN)},

    q{assert_untied_scalar($0)},
    q{assert_untied_array(@ARGV)},
    q{assert_untied_hash(%ENV)},
    q{assert_untied_glob(*STDIN)},

    q{assert_untied_scalarref(\\$0)},
    q{assert_untied_arrayref(\\@ARGV)},
    q{assert_untied_hashref(\\%ENV)},
    q{assert_untied_globref(\\*STDIN)},

    q{assert_object_overloads($bignum)},
    q{assert_object_overloads($bignum, qw[+ ++ - += * **])},

    q{assert_object_nummifies($bignum)},
    q{assert_object_stringifies($bignum)},
    q{assert_object_boolifies($bignum)},

    q{assert_object_stringifies($tied_object)},

    q[assert_happy_code { time() > 1 }],
    q[assert_unhappy_code { time() > time()+6 }],  

    q{assert_open_handle(*STDIN)},
    q{assert_open_handle(*DATA)},
    q{assert_open_handle(\*DATA)},
    q{assert_open_handle(*DATA{IO})},
    q{assert_directory("/")},


);

my $hu_version = Hash::Util->VERSION;

my %is_exported = map { $_ => 1 } (
    @Assert::Conditional::EXPORT,
    @Assert::Conditional::EXPORT_OK,
);

cmp_ok scalar keys %is_exported, ">", 50, "we exported at least 50 functions";

my @lock_assertions = qw(assert_locked assert_unlocked);
my $lock_tests = commify_and @lock_assertions;

if ($hu_version < 0.15) {
    diag "Omitting tests for $lock_tests because Hash::Util version is only v$hu_version but we need v0.15";

    for my $subname (@lock_assertions) { 
        is($is_exported{$subname}, undef, "$subname is not exported under $hu_version");
    }
}
else {
    diag "Including assert tests for $lock_tests because Hash::Util version is v$hu_version and we need only v0.15";

    for my $subname (@lock_assertions) { 
        is $is_exported{$subname}, 1, "$subname is exported under $hu_version";
    }

    push @good_tests, (
        q{assert_locked(%locked_hash)},
        q{assert_locked($locked_hashref)},
        q{assert_locked($hash_of_hashes{LOCKED})},
        q{assert_locked($hashref_of_hashes->{LOCKED})},
        q{assert_locked($$ref_of_hashref_of_hashes->{LOCKED})},

        q{assert_unlocked(%unlocked_hash)},
        q{assert_unlocked($unlocked_hashref)},
        q{assert_unlocked($$ref_of_hashref_of_hashes)},
        q{assert_unlocked($hash_of_hashes{UNLOCKED})},
        q{assert_unlocked($hashref_of_hashes->{UNLOCKED})},
        q{assert_unlocked($$ref_of_hashref_of_hashes->{UNLOCKED})},
    );

} 

my @bad_tests = (
    q{assert(1)},
    q{assert_ainta()},
    q{assert_alnum()},
    q{assert_alphabetic()},
    q{assert_anyref()},
    q{assert_argc_max()},
    q{assert_argc_min()},
    q{assert_argc_minmax()},
    q{assert_array_length()},
    q{assert_array_length_max()},
    q{assert_array_length_min()},
    q{assert_array_length_minmax()},
    q{assert_array_nonempty()},
    q{assert_arrayref()},
    q{assert_arrayref_nonempty()},
    q{assert_arrayref_nonempty([])},
    q{assert_ascii()},
    q{assert_ascii_ident()},
    q{assert_astral()},
    q{assert_blank()},
    q{assert_bmp()},
    q{assert_box_number()},
    q{assert_bytes()},
    q{assert_can()},
    q{assert_cant()},
    q{assert_coderef()},
    q{assert_defined()},
    q{assert_defined_value()},
    q{assert_defined_variable()},
    q{assert_digits()},
    q{assert_directory()},
    q{assert_does()},
    q{assert_doesnt()},
    q{assert_empty()},
    q{assert_eq()},
    q{assert_eq_letters()},
    q{assert_even_number()},
    q{assert_false()},
    q{assert_fractional()},
    q{assert_fractional($one)},
    q{assert_full_perl_ident()},
    q{assert_globref()},
    q{assert_happy_code()},
    q{assert_hash_keys()},
    q{assert_hash_nonempty()},
    q{assert_hashref()},
    q{assert_hashref_keys()},
    q{assert_hashref_nonempty()},
    q{assert_hex_number()},
    q{assert_in_list()},
    q{assert_in_numeric_range()},
    q{assert_integer()},
    q{assert_ioref()},
    q{assert_is()},
    q{assert_isa()},
    q{assert_isnt()},
    q{assert_known_package()},
    q{assert_latin1()},
    q{assert_latinish()},
    q{assert_like()},
    q{assert_list_nonempty()},
    q{assert_lowercased()},
    q{assert_multi_line()},
    q{assert_natural_number()},
    q{assert_negative()},
    q{assert_negative_integer()},
    q{assert_nfc()},
    q{assert_nfd()},
    q{assert_nfkc()},
    q{assert_nfkd()},
    q{assert_nonalphabetic()},
    q{assert_nonascii()},
    q{assert_nonastral()},
    q{assert_nonblank()},
    q{assert_nonblank(" ")},
    q{assert_nonbytes()},
    q{assert_nonempty()},
    q{assert_nonnegative()},
    q{assert_nonnegative_integer()},
    q{assert_nonnumeric()},
    q{assert_nonobject()},
    q{assert_nonpositive()},
    q{assert_nonpositive_integer()},
    q{assert_nonref()},
    q{assert_nonzero()},
    q{assert_not_in_list()},
    q{assert_numeric()},
    q{assert_object()},
    q{assert_odd_number()},
    q{assert_open_handle()},
    q{assert_positive()},
    q{assert_positive_integer()},
    q{assert_qualified_ident()},
    q{assert_reftype()},
    q{assert_regex()},
    q{assert_regular_file()},
    q{assert_scalarref()},
    q{assert_signed_number()},
    q{assert_signed_number(42)},
    q{assert_simple_perl_ident()},
    q{assert_single_line()},
    q{assert_single_paragraph()},
    q{assert_text_file()},
    q{assert_true()},
    q{assert_undefined()},
    q{assert_unhappy_code()},
    q{assert_unicode_ident()},
    q{assert_unlike()},
    q{assert_uppercased()},
    q{assert_whole_number()},
    q{assert_wide_characters()},
    q{assert_zero()},
    q{assert_is($one, $two)},
    q{assert_is($one, $undef)},
    q{assert_defined(undef) },
    q{assert_defined($undef) },
    q{assert_defined_value(undef) },
    q{assert_defined_variable($undef) },
    q{assert_undefined(1) },
    q{assert_defined_variable(!1) },
    q{assert_undefined({}) },
    q{assert_undefined_value({}) },
    q{$junk = list_context() },
    q{assert_defined($undef) },
    q{$junk = list_context() },
    q{@junk = scalar_context() },
    q{@junk = void_context() },
    q{list_context(); 1      },
    q{nonvoid_context(); 1      },
    q{scalar_context(); 1      },
    q{$junk = void_context() },
    q{@junk = nonlist_context() },
    q{assert_true(!1) },
    q{assert_true(0) },
    q{assert_true(1,1) },
    q{assert_true(q()) },
    q{assert_true(q(), 4) },
    q{assert_true(undef) },
    q{assert_true(undef, undef) },
    q{assert_false('0 but true') },
    q{assert_false(1) },
    q{assert_false(1,1) },
    q{assert_numeric($string)},
    q{assert_nonnumeric(42)},
    q{assert_nonnumeric($one)},
    q{assert_nonnumeric($float)},
    q{assert_nonnumeric($minus_two)},
    q{assert_positive($minus_two)},
    q{assert_positive($zero)},
    q{assert_positive($zero,3)},
    q{assert_negative($zero)},
    q{assert_zero($string)},
    q{assert_zero($one)},
    q{assert_zero(4,$string)},
    q{assert_zero(0,$string)},
    q{assert_nonzero($string)},
    q{assert_nonzero(0)},
    q{assert_nonnegative($minus_two)},
    q{assert_nonpositive($one)},
    q{assert_integer($float)},
    q{assert_whole_number($float)},
    q{assert_whole_number($string)},
    q{assert_whole_number(undef)},
    q{assert_positive_integer($minus_two)},
    q{assert_positive_integer($zero)},
    q{assert_positive_integer($float)},
    q{assert_positive_integer($undef)},
    q{assert_natural_number($zero)},
    q{assert_natural_number($string)},
    q{assert_nonpositive_integer($float)},
    q{assert_nonpositive_integer($string)},
    q{assert_negative_integer(5)},
    q{assert_negative_integer($one)},
    q{assert_negative_integer($float)},
    q{assert_negative_integer($float)},
    q{assert_negative_integer($string)},
    q{assert_negative_integer(undef)},
    q{assert_nonnegative_integer($string)},
    q{assert_nonnegative_integer($float)},
    q{assert_nonnegative_integer($undef)},
    q{assert_hex_number('0oFF')},
    q{assert_hex_number('FX')},
    q{assert_box_number('0r00')},
    q{assert_box_number(undef)},
    q{assert_box_number($undef)},
    q{assert_box_number($string)},
    q{assert_box_number($minus_two)},
    q{assert_box_number('87')},
    q{assert_box_number(87)},
    q{assert_even_number($one)},
    q{assert_even_number($float)},
    q{assert_even_number($string)},
    q{assert_even_number($undef)},
    q{assert_odd_number($two)},
    q{assert_odd_number($string)},
    q{assert_odd_number(undef)},
    q{assert_odd_number($undef)},
    q{assert_odd_number($undef)},
    q{assert_in_numeric_range(-5,1,10)},
    q{assert_in_numeric_range(15,1,10)},
    q{assert_in_numeric_range(5,8,10)},
    q{assert_in_numeric_range(-5,10,1)},
    q{assert_in_numeric_range(-5,$string,10)},
    q{assert_in_numeric_range(1,5,1,10)},
    q{assert_in_numeric_range($string)},
    q{assert_empty($one)},
    q{assert_empty(22)},
    q{assert_empty(undef)},
    q{assert_empty(1,2)},
    q{assert_nonempty([])},
    q{assert_nonempty()},
    q{assert_nonempty(undef)},
    q{assert_blank()},
    q{assert_blank("\0")},
    q{assert_blank($one)},
    q{assert_blank(undef)},
    q{assert_blank([])},
    q{assert_single_line("abc\x{000A} ")},
    q{assert_single_line("abc\x{000B} ")},
    q{assert_single_line("abc\x{000C} ")},
    q{assert_single_line("abc\x{000D} ")},
    q{assert_single_line("abc\x{0085} ")},
    q{assert_single_line("abc\x{2028} ")},
    q{assert_single_line("abc\x{2029} ")},
    q{assert_single_paragraph("abc\x{000A} ")},
    q{assert_single_paragraph("abc\x{000B} ")},
    q{assert_single_paragraph("abc\x{000C} ")},
    q{assert_single_paragraph("abc\x{000D} ")},
    q{assert_single_paragraph("abc\x{0085} ")},
    q{assert_single_paragraph("abc\x{2028} ")},
    q{assert_single_paragraph("abc\x{2029} ")},
    q{assert_single_line("")},
    q{assert_single_line(undef)},
    q{assert_single_line("\n\n")},
    q{assert_single_line("\r\n")},
    q{assert_multi_line("")},
    q{assert_multi_line("foo")},
    q{assert_multi_line("foo\r\n")},
    q{assert_multi_line(undef)},
    q{assert_single_paragraph("one\f" x 5)},
    q{assert_single_paragraph("one\r\n" x 5)},
    q{assert_single_paragraph("one\n\n\f" x 5)},
    q{assert_nonbytes("abc")},
    q{assert_nonbytes("\xA0")},
    q{assert_nbytes("\x{223}")},
    q{assert_wide_characters("x")},
    q{assert_nonascii("223")},
    q{assert_ascii("\xa0")},
    q{assert_nonalphabetic("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_alphabetic("~!")},
    q{assert_alnum("abc%39sd")},
    q{assert_digits("1234asbc9120")},
    q{assert_lowercased("THIS OLD MAN!")},
    q{assert_uppercased("this old man!")},
    q{assert_uppercased("BA\N{LATIN SMALL LETTER SHARP S}")},
    q{assert_unicode_ident("_ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_simple_perl_ident("ni\xa2o")},
    q{assert_full_perl_ident("ni\xa2o")},
    q{assert_qualified_ident("main::ni\xa2o")},
    q{assert_qualified_ident("main")},
    q{assert_ascii_ident("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_regex(q/foo/)},
    q{assert_like("foo", q/f/)},
    q{assert_like("foo", qr/z/)},
    q{assert_unlike("foo", qr/f/)},
    q{assert_latin1("\x{189}")},
    q{assert_latin1("Henry \x{2167}")},
    q{assert_latinish("\x{F0FF}")},
    q{assert_astral("\x{F0FF}")},
    q{assert_nonastral("\x{12345}")},
    q{assert_bmp("ni\x{12223}o")},
    q{assert_nfc("\x{212A}")}, # Singleton
    q{assert_nfd("\x{212A}")},
    q{assert_nfkc("\x{212A}")},
    q{assert_nfkd("\x{212A}")},
    q{assert_nfd("ni\N{LATIN SMALL LETTER N WITH TILDE}o")},
    q{assert_nfc("nin\x{303}o")},
    q{assert_nfkc("\x{a0}")},
    q{assert_nfkd("\x{a0}")},
    q{assert_nfkd("\x{bc}")},
    q{assert_eq("ni\N{LATIN SMALL LETTER N WITH TILDE}o", "nin\x{304}o")},
    q{assert_eq_letters("one, tow", "ONE")},

    q{assert_isnt($one, $one)},
    q{assert_isnt($bignum, $bignum)},
    q{assert_isnt($tied_object, $tied_object)},

    q{ no warnings 'redefine'; sub fn0    {  assert_argc_min(15) }      fn0(localtime()) },
    q{ no warnings 'redefine'; sub fn1($) {  assert_argc(0) }           fn1(localtime()) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc(2) }           fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc  }           fn2() },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_max(2) }       fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_max(2) }       fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_minmax(10,25) }fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_minmax(2,1) }fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_minmax(25,10) }fn2(1, 2, 3) },
    q{ no warnings 'redefine'; sub fn2    {  assert_argc_minmax(1,2) }fn2(1, 2, 3) },

    q{assert_in_list("red", qw(one fish two fish fish blue fish))},
    q{assert_in_list(5, 6 .. 10)},
    q{assert_in_list(1, 20 .. 30)},
    q{assert_in_list(5, 1, 3, undef, [], 10)},
    q{assert_in_list(undef, 1 .. 10)},
    q{assert_in_list(undef)},

    q{assert_not_in_list("red", qw(one fish two fish red fish blue fish))},
    q{assert_not_in_list(5, 1 .. 10)},
    q{assert_not_in_list(5, 1, 3, undef, [], 5, 10)},
    q{assert_not_in_list(\@ARGV, 1, 3, undef, \@ARGV, 5, 10)},
    q{assert_not_in_list(undef, 1 .. 10, undef)},
    q{assert_not_in_list(undef, undef)},

    q{assert_list_nonempty( () )},
    q{assert_array_nonempty( @some::thing )},
    q{assert_arrayref_nonempty( \@some::thing )},
    q{assert_arrayref_nonempty( [ ] )},

    q{assert_array_length(@empty)},
    q{assert_array_length(@empty, 10)},
    q{assert_array_length_min(@empty, 5)},
    q{assert_array_length_max(@primary_colors, 1)},
    q{assert_array_length_minmax(@empty, 5, 20)},
    q{assert_array_length_minmax(@empty, -5, -2)},
    q{assert_array_length_minmax(@empty, -5, 20)},
    q{assert_array_length_minmax(@empty, 25, 5)},
    q{assert_array_length_minmax(@primary_colors, 1, 2)},

    q{assert_hash_nonempty(%empty)},
    q{assert_hashref_nonempty(\%empty)},
    q{assert_hash_keys(%empty, qw<HOME PATH USER>)},
    q{assert_hashref_keys(\%empty, qw<HOME PATH USER>)},

    q{assert_hash_keys_required(@junk, qw<yellow violet cyan>)},
    q{assert_hash_keys_required(%primary_color, @empty)},
    q{assert_hash_keys_required(%primary_color, qw<yellow violet cyan>)},
    q{assert_hash_keys_required(%primary_color, qw<pink purple>)},
    q{assert_hash_keys_allowed(%primary_color, qw<yellow violet cyan>)},
    q{assert_hash_keys_allowed(%primary_color, qw<pink purple>)},
    q{assert_hash_keys_allowed(%primary_color, qw<red>)},
    q{assert_hash_keys_allowed(%primary_color, @empty)},
    q{assert_hashref_keys_required(%primary_color, qw<yellow violet cyan>)},
    q{assert_hashref_keys_allowed(%primary_color, qw<yellow violet cyan>)},
    q{assert_hashref_keys_required(\%primary_color, qw<yellow violet cyan>)},
    q{assert_hashref_keys_allowed(\%primary_color, qw<yellow violet cyan>)},

    q{assert_hash_keys_required_and_allowed(%primary_color, [qw<red blue green>], ["red"])},
    q{assert_hash_keys_required_and_allowed(%primary_color, [qw<red blue green>], [])},
    q{assert_hash_keys_required_and_allowed(%primary_color, [], [])},
    q{assert_hashref_keys_required_and_allowed(\\%primary_color, [qw<red blue green>], ["red"])},
    q{assert_hashref_keys_required_and_allowed($primary_color_ref, [qw<red blue green>], ["red"])},
    q{assert_hash_keys_allowed_and_required(%primary_color, ["red"], [qw<red blue green>])},
    q{assert_hash_keys_allowed_and_required(%primary_color, [], [qw<red blue green>])},
    q{assert_hash_keys_allowed_and_required(%primary_color, [], [])},
    q{assert_hashref_keys_allowed_and_required(\\%primary_color,, ["red"] [qw<red blue green>])},
    q{assert_hashref_keys_allowed_and_required($primary_color_ref, ["red"], [qw<red blue green>])},

    q{assert_hashref_keys_required(\\%primary_color, qw<red pink green>)},
    q{assert_hashref_keys_allowed(\\%primary_color, qw<red pink green>)},
    q{assert_hashref_keys_required($primary_color_ref, qw<red pink green>)},
    q{assert_hashref_keys_allowed($primary_color_ref, qw<red pink green>)},

    q{assert_keys(%primary_color, qw<red pink green>)},
    q{assert_keys(%primary_color, @all_colors)},
    q{assert_keys(%primary_color, @not_colors)},
    q{assert_keys(%primary_color, @empty)},
    q{assert_keys($primary_color_ref, qw<red pink green>)},
    q{assert_keys($primary_color_ref, @all_colors)},
    q{assert_keys($primary_color_ref, @not_colors)},
    q{assert_keys($primary_color_ref, @empty)},

    q{assert_min_keys(%primary_color, qw<red pink green>)},
    q{assert_min_keys(%primary_color, @empty)},
    q{assert_min_keys(%primary_color, @all_colors)},
    q{assert_min_keys(%primary_color, @not_colors)},
    q{assert_min_keys($primary_color_ref, qw<red pink green>)},
    q{assert_min_keys($primary_color_ref, @all_colors)},
    q{assert_min_keys($primary_color_ref, @not_colors)},

    q{assert_max_keys(%primary_color, qw<orange yellow violet>)},
    q{assert_max_keys(%primary_color, @not_colors)},
    q{assert_max_keys(%primary_color, @empty)},
    q{assert_max_keys($primary_color_ref, qw<orange yellow violet>)},
    q{assert_max_keys($primary_color_ref, @not_colors)},

    q{assert_minmax_keys(%primary_color, @all_colors, @primary_color)},
    q{assert_minmax_keys($primary_color_ref, @all_colors, @primary_colors)},
    q{assert_minmax_keys(%primary_color, @empty, @empty)},
    q{assert_minmax_keys($primary_color_ref, @empty, @empty)},

    q{assert_unlocked(%locked_hash)},
    q{assert_unlocked($locked_hashref)},
    q{assert_unlocked($hash_of_hashes{LOCKED})},
    q{assert_unlocked($hashref_of_hashes->{LOCKED})},
    q{assert_unlocked($$ref_of_hashref_of_hashes->{LOCKED})},

    q{assert_locked(%unlocked_hash)},
    q{assert_locked($unlocked_hashref)},
    q{assert_locked($$ref_of_hashref_of_hashes)},
    q{assert_locked($hash_of_hashes{UNLOCKED})},
    q{assert_locked($hashref_of_hashes->{UNLOCKED})},
    q{assert_locked($$ref_of_hashref_of_hashes->{UNLOCKED})},

    q{assert_anyref( "string" )},
    q{assert_anyref( 0 )},
    q{assert_anyref( $0 )},
    q{assert_anyref( *0 )},
    q{assert_anyref( @ARGV )},
    q{assert_anyref( )},
    q{assert_anyref( %ENV )},
    q{assert_anyref( defined &lives  )},
    q{assert_anyref( time()  )},
    q{assert_anyref( localtime()  )},
    q{assert_anyref( *STDIN )},
    q{assert_anyref( @{ *ARGV{ARRAY} } )},
    q{assert_anyref( @{ *{$main::{ARGV}}{ARRAY} } )},

    q{assert_reftype( ARRAY   =>  \"string"                )},
    q{assert_reftype( ARRAY   =>  \0                       )},
    q{assert_reftype( ARRAY   =>  \$0                      )},
    q{assert_reftype( ARRAY   =>  *0{SCALAR}               )},
    q{assert_reftype( REFREF  =>  \\\$0                    )},
    q{assert_reftype( SCALAR  =>  \@ARGV                   )},
    q{assert_reftype( ARRAY   =>  \\\\\@ARGV                 )},
    q{assert_reftype( STRING  =>  [ ]                      )},
    q{assert_reftype( CODE    =>  \%ENV                    )},
    q{assert_reftype( CODE    =>  {  }                     )},
    q{assert_reftype( ARRAY    =>  sub  {    }              )},
    q{assert_reftype( CODE    =>  time()               )},
    q{assert_reftype( IO  =>  \time()                  )},
    q{assert_reftype( HASH    =>  \*ENV                    )},
    q{assert_reftype( "IO::Handle"      =>  *STDIN{IO}               )},
    q{assert_reftype( GLOB   =>  *ARGV{ARRAY}             )},
    q{assert_reftype( HASH   =>  *{$main::{ARGV}}{ARRAY}  )},

    q{assert_hashref(  \"string"    )},
    q{assert_hashref(  \0           )},
    q{assert_hashref(  \$0          )},
    q{assert_hashref(  *0{SCALAR}   )},
    q{assert_scalarref(     \\\$0        )},
    q{assert_arrayref(   \\\\\\@ARGV       )},
    q{assert_hashref(   \@ARGV       )},
    q{assert_hashref(   [ ]          )},
    q{assert_arrayref(    \%ENV        )},
    q{assert_arrayref(    { }          )},
    q{assert_hashref(    sub {    }   )},
    q{assert_hashref(    \&lives   )},
    q{assert_hashref(  \time()      )},
    q{assert_refref(    \*ENV        )},
    q{assert_scalarref(      *STDIN{IO}   )},
    q{assert_globref(   *ARGV{ARRAY}             )},
    q{assert_hashref(   *{$main::{ARGV}}{ARRAY}  )},

    q{assert_unblessed_ref(      *STDIN{IO}   )},
    q{assert_unblessed_ref(      *Tied_FH   )},
    q{assert_unblessed_ref(      $bignum   )},
    q{assert_unblessed_ref(      $tied_object   )},

    q{assert_known_package("IO::Fil")},
    q{assert_known_package(IO::Fil::)},
    q{assert_object($class)},
    q{assert_object([])},
    q{assert_object(2)},
    q{assert_nonobject($obj)},
    q{assert_nonobject(bless [])},
    q{assert_can($class, @empty)},
    q{assert_can($class, qw(isa can take-off-hoser VERSION))},
    q{assert_can($class, qw(isa can take off hoser VERSION))},
    q{assert_can($obj, qw(isa take-off-hoser can VERSION))},
    q{assert_can($class, qw(parola-nuda))},
    q{assert_can($obj, qw(parola-nuda))},
    q{assert_can($obj, qw(close open-sesame))},
    q{assert_can($class, qw(close-your-face open))},
    q{assert_cant($class, qw(close) )},
    q{assert_cant($class, @empty )},
    q{assert_cant($class, qw(new) )},
    q{assert_cant($obj, qw(open) )},
    q{assert_ainta($obj, $class)},
    q{assert_ainta($obj, @empty)},
    q{assert_isa($class, $obj)},
    q{assert_isa($class, @empty)},
    q{assert_does($class, @empty)},
    q{assert_does($class, "What::Ever")},
    q{assert_does($class, "What::Ever", "You::Please")},
    q{assert_does($class, @primary_colors)},
    q{assert_doesnt($class, "IO::Handle")},
    q{assert_doesnt($class, @empty)},

    q{sub { assert_method() }->() },
    q{sub { assert_public_method() }->() },
    q{sub { assert_private_method() }->() },
    q{sub { assert_protected_method() }->() },

    q{sub { assert_class_method() }->($obj) },
    q{sub { assert_class_method() }->() },
    q{sub { assert_object_method() }->($class) },
    q{sub { assert_object_method() }->() },
    q{sub { assert_object_method() }->([ ]) },

    q{assert_isa($obj, "IO::Socket")},
    q{assert_isa($obj, "Regexp")},
    q{assert_isa($class, "x$class", "y$class")},
    q{assert_isa($obj, "$obj", $obj)},
    q{assert_isa($class, "IO::Socks")},
    q{assert_isa($obj, qw<IO::Handle IO::File IO::Socket> )},
    q{assert_isa($obj,   <IO::{Handle,File,Socket}  > )},
    q{assert_isa($class, qw<IO::Handle IO::File IO::Socket >)},
    q{assert_isa($class, "IO::Socket")},
    q{assert_ainta($obj, "IO::Handle")},
    q{assert_ainta($obj, "UNIVERSAL")},

    q{assert_object_can($class, qw(close open))},
    q{assert_object_can($class, qw(isa can VERSION))},
    q{assert_object_can($class, qw(new))},

    q{assert_object_can($bignum, qw<Math::BigInt> )},
    q{assert_object_cant($bignum, qw<bround fround is_even is_odd> )},

    q{assert_class_can($obj, qw(IO::Handle::new))},
    q{assert_class_can($obj, qw(UNIVERSAL::isa))},
    q{assert_class_can($obj, qw(close open))},
    q{assert_class_can($obj, qw(isa can VERSION))},
    q{assert_class_can($obj, qw(new))},
    q{assert_class_cant($class, qw(new) )},

    q{assert_object_isa($class, "IO::File")},
    q{assert_object_isa($class, "IO::Handle")},
    q{assert_object_isa($class, "UNIVERSAL")},
    q{assert_object_isa($class, $class)},
    q{assert_object_isa($class, UNIVERSAL::)},
    q{assert_object_isa($class, qw<IO::Handle IO::File >)},

    q{assert_object_ainta($obj,   <IO::{Handle,File}  > )},

    q{assert_class_isa($obj,   <IO::{Handle,File}  > )},
    q{assert_class_isa($obj, "IO::File")},
    q{assert_class_isa($obj, "IO::Handle")},
    q{assert_class_isa($obj, "UNIVERSAL")},
    q{assert_class_isa($obj, $class)},
    q{assert_class_isa($obj, UNIVERSAL::)},
    q{assert_class_isa($obj, qw<IO::Handle IO::File> )},

    q{assert_class_ainta($class, qw<IO::Handle IO::File> )},

    q{assert_tied(0)},
    q{assert_tied(\0)},
    q{assert_tied($0)},
    q{assert_tied(@ARGV)},
    q{assert_tied(%ENV)},
    q{assert_tied(*STDIN)},

    q{assert_tied_referent({%Config})},
    q{assert_tied_referent(\\substr($0, 5))}, # Invalid reftype to check for ties: 'LVALUE'
    q{assert_tied_referent(\\\\%Config)},

    q{assert_tied_scalar($0)},
    q{assert_tied_scalarref($0)},
    q{assert_tied_array(%Config)},
    q{assert_tied_array(@ARGV)},
    q{assert_tied_arrayref(@ARGV)},
    q{assert_tied_hash(%Env)},
    q{assert_tied_hashref(%Config)},
    q{assert_tied_glob(*STDIN)},
    q{assert_tied_globref(\*STDIN)},

    q{ assert_untied($PATH) },
    q{ assert_untied(%Config) },
    q{ assert_untied(@PATH) },
    q{ assert_untied(*Tied_FH) },

    q{ assert_untied_referent(\\$PATH) },
    q{ assert_untied_referent(\\%Config) },
    q{ assert_untied_referent(\\@PATH) },
    q{ assert_untied_referent(\\*Tied_FH) },
    q{ assert_untied_referent(\\qr/foo/) },

    q{ assert_untied_scalar($PATH) },
    q{ assert_untied_scalarref(\\$PATH) },

    q{ assert_untied_array(@PATH) },
    q{ assert_untied_arrayref(\\@PATH) },

    q{ assert_untied_hash(%Config) },
    q{ assert_untied_hashref(\\%Config) },

    q{ assert_untied_glob(*Tied_FH) },
    q{ assert_untied_globref(\\*Tied_FH) },

    q{assert_object_overloads($0)},
    q{assert_object_overloads($obj)},
    q{assert_object_overloads($obj, "+")},
    q{assert_object_nummifies($obj)},
    q{assert_object_stringifies($obj)},
    q{assert_object_boolifies($obj)},
    q{assert_object_overloads($tied_object, qw[+ ++ - += * **])},

    q{assert_object_nummifies($tied_object)},
    q{assert_object_boolifies($tied_object)},

    q[assert_happy_code { time() < 1 }],
    q[assert_unhappy_code { time() < time()+6 }],  

    q{assert_open_handle(*XYZZY)},
    q{assert_open_handle(\*XYZZY)},
    q{assert_open_handle(*DATA{XYZZY})},
    q{assert_regular_file($100)},
    q{assert_text_file($1000)},
    q{assert_directory($0)},


);

my @good_posix = (
    q{assert_legal_exit_status(0)},
    q{assert_legal_exit_status(1 << 8)},
    q{assert_legal_exit_status(1 << 8)},
    q{assert_legal_exit_status(1 << 10)},
    #q{assert_signalled(3)},
    q{assert_unsignalled(0)},
    q{assert_unsignalled(3 << 8)},
    q{assert_dumped_core(131)},
    q{$? = 131; assert_dumped_core},
    q{assert_no_coredump(0)},
    q{assert_no_coredump(9)},
    q{assert_exited(0)},
    q{assert_exited(1 << 8)},
    q{assert_exited(1 << 10)},
    q{assert_happy_exit(0)},
    q{system($^X, "-e", "exit 0"); assert_happy_exit},
    q{assert_sad_exit(1<<8)},
    q{system($^X, "-e", "exit 1"); assert_sad_exit},
);

my @bad_posix = (
    q{assert_legal_exit_status("fred")},
    q{assert_legal_exit_status(1 << 18)},
    q{assert_legal_exit_status(1 << 30)},
    q{assert_unsignalled(19)},
    q{assert_signalled(0)},
    q{assert_signalled(3 << 8)},
    q{assert_no_coredump(131)},
    q{assert_dumped_core(0)},
    q{assert_dumped_core(9)},
    q{assert_exited(131)},
    q{assert_exited(1 << 3)},
    q{assert_exited(1 << 0)},
    q{assert_happy_exit(17)},
    q{assert_happy_exit(131)},
    q{assert_happy_exit(512)},
    q{assert_sad_exit(0)},
);

require POSIX;
if (eval "POSIX::WIFEXITED(0); 1") {
    push @good_tests, @good_posix;
    push @bad_tests, @bad_posix;
}

for my $good (@good_tests) {
    use warnings qw(FATAL all);
    local $@;
    my $code = eval "sub { $good }"; 
    is($@, "", "COMPILED: $good") 
        || die "go fix your good test to compile";
    local $ENV{PATH} = "/bin:/usr/bin" if $good =~ /system/;
    ok(lives { &$code }, "lives ok: $good")
       || diag "BOTCHED: $good: $@";
}

for my $bad (@bad_tests) {
    local $@;
    # These might not compile, so don't check eval result.
    # Have a default way to die though because otherwise
    #   Use of uninitialized value in subroutine entry at t/asserts.t ....
    # coming out of Test2::Tools::Exception line 15
    my $code = eval "sub { $bad }" || sub { die "whatever" };
    local $ENV{PATH} = "/bin:/usr/bin" if $bad =~ /system/;
    ok(dies { &$code }, "dies ok: $bad")
        || diag "assertion unexpectedly lived: $bad";
}

done_testing();

{
    package TieOut;

    use Carp;

    sub never_stringifies { confess "don't stringify me" }

    use overload (
        q("") => \&never_stringifies,
        fallback => 1,
    );

    sub TIEHANDLE {
        bless(\(my $scalar), $_[0]);
    }

    sub PRINT {
        my $self = shift;
        $$self .= join '', @_;
    }

    sub WRITE {
        my ($self, $msg, $length) = @_;
        $$self .= $msg;
    }

    sub read {
        my $self = shift;
        substr($$self, 0, length($$self), '');
    }
}

__DATA__
