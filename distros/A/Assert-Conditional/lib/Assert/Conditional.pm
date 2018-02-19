#!/usr/bin/env perl
package Assert::Conditional;

=encoding utf8

=head1 NAME

Assert::Conditional - conditionally compile assertions

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

        assert_can($self, "cross_product", *cross_tees");

        ...

        assert_happy_code { $i > $j };

        ...
    }

=head1 DESCRIPTION

C programmers have always had F<assert.h> to conditionally compile assertions
into their programs, but options available for Perl programmers are
not so convenient.  Several assertion modules related to assertions exist on CPAN,
but none works quite like this one does, probably due to differing design goals.

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

Require no complicated framework setup to use: no hierarchy 
of types, no strange magic at a distant, and no 450-module toolchain
from CPAN to get up and running.

=item *

Make it obvious what went wrong.  Don't obfuscate.  Don't generate 100-line
stack dumps filled mostly with anonymous functions and values that make you
think you've accidentally started programming in Java instead of Perl.

=item * 

Keep the implementation of each assertion as short and simple as possible.
This documentation is much longer than the code itself.

=item * 

Use nothing but Standard Perl unless at great need.

=item * 

Compatible to Perl version 5.10 whenever possible.

=back

This initial alpha release is considered completely experimental, but evne
so all these goals have been met.  The only module required that is not
part of the standard Perl release is the underlying
L<Exporter::ConditionalSubs> which this module inherits its import method
from.  That module is where (most of) the magic happens to make assertions 
get compiled out of your program.  You should look at that module for 
how the "conditional importing" works.

=head2 Runtime Control

No matter what assertions you conditionally use, there may be times
when you have a running piece of software that you want to change
the assertion behavior of without changing the source code.

For that, the C<ASSERT_CONDITONAL> environment variable is used
to override the current defaults.  It has three possible values:

Here is the list of the support global variables, available for import,
which are normally controlled by the C<ASSERT_CONDITIONAL> environment 
variable. These may be combined for stacked effects, but "never" cancels
all of them. For example:

    ASSERT_CONDITIONAL="carp,always"
    ASSERT_CONDITIONAL="carp,handlers"
    ASSERT_CONDITIONAL="carp,always,handlers"

=over

=item never

Assertions are never imported, and even if you somehow manage to import
them, they will never never make a peep nor raise an exception.

=item always

Assertions are always imported, and even if you somehow manage to avoid importing
them, they will still raise an exception on error. This is the default.

=item carp

Assertions are always imported but they do not raise an exception if they fail;
instead they old carp at you.  This is true even if you manage to call an assertion
you haven't imported.

Note that if combined, you can get both effects:

    ASSERT_CONDITIONAL="carp,always"

=item handlers

Only usable in conjunction with another of the previous three, as in 

    ASSERT_CONDITIONAL="always,handlers"

Unless this option is specified, C<$SIG{__WARN__}> and C<$SIG{__DIE__}>
handlers will be suppressed if the assertion fails and therefore a C<carp>
or C<confess> is needed.

=back

=cut

use v5.10;
use utf8;
use strict;
use warnings;

# this module is our own helper module:
use Assert::Conditional::Utils qw< :all >;

# This next one is a CPAN module:
use parent              qw< Exporter::ConditionalSubs >;

# But these are not:
use Carp;
use POSIX               qw< :sys_wait_h >;
use Scalar::Util        qw< reftype blessed looks_like_number openhandle >;
use Attribute::Handlers;
use Unicode::Normalize    < {check,}NF{,K}{C,D} >;

our $VERSION = 0.004;
our(@EXPORT, @EXPORT_OK, %EXPORT_TAGS);

sub  Assert                                ;

sub  assert_ainta                (  $@   ) ;
sub  assert_alnum                (  $    ) ;
sub  assert_alphabetic           (  $    ) ;
sub  assert_anyref               (  $    ) ;
sub  assert_argc                 ( ;$    ) ;
sub  assert_argc_max             (  $    ) ;
sub  assert_argc_min             (  $    ) ;
sub  assert_argc_minmax          (  $$   ) ;
sub  assert_array_length         ( \@ ;$ ) ;
sub  assert_array_length_max     ( \@ $  ) ;
sub  assert_array_length_min     ( \@ $  ) ;
sub  assert_array_length_minmax  ( \@ $$ ) ;
sub  assert_array_nonempty       ( \@    ) ;
sub  assert_arrayref             (  $    ) ;
sub  assert_arrayref_nonempty    (  $    ) ;
sub  assert_ascii                (  $    ) ;
sub  assert_ascii_ident          (  $    ) ;
sub  assert_astral               (  $    ) ;
sub  assert_blank                (  $    ) ;
sub  assert_bmp                  (  $    ) ;
sub  assert_box_number           (  $    ) ;
sub  assert_bytes                (  $    ) ;
sub  assert_can                  (  $@   ) ;
sub  assert_cant                 (  $@   ) ;
sub  assert_class_method         (       ) ;
sub  assert_coderef              (  $    ) ;
sub  assert_defined              (  $    ) ;
sub  assert_defined_value        (  $    ) ;
sub  assert_defined_variable     ( \$    ) ;
sub  assert_digits               (  $    ) ;
sub  assert_directory            (  $    ) ;
sub  assert_does                 (  $@   ) ;
sub  assert_doesnt               (  $@   ) ;
sub  assert_dumped_core          ( ;$    ) ;
sub  assert_empty                (  $    ) ;
sub  assert_eq                   (  $$   ) ;
sub  assert_eq_letters           (  $$   ) ;
sub  assert_even_number          (  $    ) ;
sub  assert_exited               ( ;$    ) ;
sub  assert_false                (  $    ) ;
sub  assert_fractional           (  $    ) ;
sub  assert_full_perl_ident      (  $    ) ;
sub  assert_globref              (  $    ) ;
sub  assert_happy_code           (  &    ) ;
sub  assert_happy_exit           ( ;$    ) ;
sub  assert_hash_keys            ( \% @  ) ;
sub  assert_hash_keys_allowed    ( \%@   ) ;
sub  assert_hash_keys_required   ( \%@   ) ;
sub  assert_hash_nonempty        ( \%    ) ;
sub  assert_hashref              (  $    ) ;
sub  assert_hashref_keys         (  $@   ) ;
sub  assert_hashref_keys_allowed (  $@   ) ;
sub  assert_hashref_keys_required (  $@   ) ;
sub  assert_hashref_nonempty     (  $    ) ;
sub  assert_hex_number           (  $    ) ;
sub  assert_in_list              (  $@   ) ;
sub  assert_in_numeric_range     (  $$$  ) ;
sub  assert_integer              (  $    ) ;
sub  assert_ioref                (  $    ) ;
sub  assert_is                   (  $$   ) ;
sub  assert_isa                  (  $@   ) ;
sub  assert_isnt                 (  $$   ) ;
sub  assert_known_package        (  $    ) ;
sub  assert_latin1               (  $    ) ;
sub  assert_latinish             (  $    ) ;
sub  assert_legal_exit_status    ( ;$    ) ;
sub  assert_like                 (  $$   ) ;
sub  assert_list_context         (       ) ;
sub  assert_list_nonempty        (  @    ) ;
sub  assert_lowercased           (  $    ) ;
sub  assert_method               (       ) ;
sub  assert_multi_line           (  $    ) ;
sub  assert_natural_number       (  $    ) ;
sub  assert_negative             (  $    ) ;
sub  assert_negative_integer     (  $    ) ;
sub  assert_nfc                  (  $    ) ;
sub  assert_nfd                  (  $    ) ;
sub  assert_nfkc                 (  $    ) ;
sub  assert_nfkd                 (  $    ) ;
sub  assert_no_coredump          ( ;$    ) ;
sub  assert_nonalphabetic        (  $    ) ;
sub  assert_nonascii             (  $    ) ;
sub  assert_nonastral            (  $    ) ;
sub  assert_nonblank             (  $    ) ;
sub  assert_nonbytes             (  $    ) ;
sub  assert_nonempty             (  $    ) ;
sub  assert_nonlist_context      (       ) ;
sub  assert_nonnegative          (  $    ) ;
sub  assert_nonnegative_integer  (  $    ) ;
sub  assert_nonnumeric           (  $    ) ;
sub  assert_nonobject            (  $    ) ;
sub  assert_nonpositive          (  $    ) ;
sub  assert_nonpositive_integer  (  $    ) ;
sub  assert_nonref               (  $    ) ;
sub  assert_nonvoid_context      (       ) ;
sub  assert_nonzero              (  $    ) ;
sub  assert_not_in_list          (  $@   ) ;
sub  assert_numeric              (  $    ) ;
sub  assert_object               (  $    ) ;
sub  assert_object_method        (       ) ;
sub  assert_odd_number           (  $    ) ;
sub  assert_open_handle          (  $    ) ;
sub  assert_positive             (  $    ) ;
sub  assert_positive_integer     (  $    ) ;
sub  assert_private_method       (       ) ;
sub  assert_public_method        (       ) ;
sub  assert_qualified_ident      (  $    ) ;
sub  assert_refref               (  $    ) ;
sub  assert_reftype              (  $$   ) ;
sub  assert_regex                (  $    ) ;
sub  assert_regular_file         (  $    ) ;
sub  assert_sad_exit             ( ;$    ) ;
sub  assert_scalar_context       (       ) ;
sub  assert_scalarref            (  $    ) ;
sub  assert_signalled            ( ;$    ) ;
sub  assert_signed_number        (  $    ) ;
sub  assert_simple_perl_ident    (  $    ) ;
sub  assert_single_line          (  $    ) ;
sub  assert_single_paragraph     (  $    ) ;
sub  assert_text_file            (  $    ) ;
sub  assert_true                 (  $    ) ;
sub  assert_undefined            (  $    ) ;
sub  assert_unhappy_code         (  &    ) ;
sub  assert_unicode_ident        (  $    ) ;
sub  assert_unlike               (  $$   ) ;
sub  assert_unsignalled          ( ;$    ) ;
sub  assert_uppercased           (  $    ) ;
sub  assert_void_context         (       ) ;
sub  assert_whole_number         (  $    ) ;
sub  assert_wide_characters      (  $    ) ;
sub  assert_zero                 (  $    ) ;

sub  check                                 ;
sub  check_args                            ;
sub _coredump_message            ( ;$    ) ;
sub  export_to_level                       ;
sub _get_invocant_type           (  $    ) ;
sub  import                                ;
sub _reimport_nulled_code_protos           ;
sub _run_code_test               (  $$   ) ;
sub _signum_message              (  $    ) ;
sub  some_method                           ;
sub _strip_import_conditions               ;
sub _WIFCORED                    ( ;$    ) ;

=pod

=head2 Assert Inventory

Here in alphabetical order is the list of all assertions with their prototypes.
Following this is a list of assertions grouped by category, and finally
a description of what each one does.

 assert_ainta                (  $@   ) ;
 assert_alnum                (  $    ) ;
 assert_alphabetic           (  $    ) ;
 assert_anyref               (  $    ) ;
 assert_argc                 ( ;$    ) ;
 assert_argc_max             (  $    ) ;
 assert_argc_min             (  $    ) ;
 assert_argc_minmax          (  $$   ) ;
 assert_array_length         ( \@ ;$ ) ;
 assert_array_length_max     ( \@ $  ) ;
 assert_array_length_min     ( \@ $  ) ;
 assert_array_length_minmax  ( \@ $$ ) ;
 assert_array_nonempty       ( \@    ) ;
 assert_arrayref             (  $    ) ;
 assert_arrayref_nonempty    (  $    ) ;
 assert_ascii                (  $    ) ;
 assert_ascii_ident          (  $    ) ;
 assert_astral               (  $    ) ;
 assert_blank                (  $    ) ;
 assert_bmp                  (  $    ) ;
 assert_box_number           (  $    ) ;
 assert_bytes                (  $    ) ;
 assert_can                  (  $@   ) ;
 assert_cant                 (  $@   ) ;
 assert_class_method         (       ) ;
 assert_coderef              (  $    ) ;
 assert_defined              (  $    ) ;
 assert_defined_value        (  $    ) ;
 assert_defined_variable     ( \$    ) ;
 assert_digits               (  $    ) ;
 assert_directory            (  $    ) ;
 assert_does                 (  $@   ) ;
 assert_doesnt               (  $@   ) ;
 assert_dumped_core          ( ;$    ) ;
 assert_empty                (  $    ) ;
 assert_eq                   (  $$   ) ;
 assert_eq_letters           (  $$   ) ;
 assert_even_number          (  $    ) ;
 assert_exited               ( ;$    ) ;
 assert_false                (  $    ) ;
 assert_fractional           (  $    ) ;
 assert_full_perl_ident      (  $    ) ;
 assert_globref              (  $    ) ;
 assert_happy_code           (  &    ) ;
 assert_happy_exit           ( ;$    ) ;
 assert_hash_keys            ( \% @  ) ;
 assert_hash_keys_allowed    ( \%@   ) ;
 assert_hash_keys_required   ( \%@   ) ;
 assert_hash_nonempty        ( \%    ) ;
 assert_hashref              (  $    ) ;
 assert_hashref_keys         (  $@   ) ;
 assert_hashref_keys_allowed (  $@   ) ;
 assert_hashref_keys_required (  $@   ) ;
 assert_hashref_nonempty     (  $    ) ;
 assert_hex_number           (  $    ) ;
 assert_in_list              (  $@   ) ;
 assert_in_numeric_range     (  $$$  ) ;
 assert_integer              (  $    ) ;
 assert_ioref                (  $    ) ;
 assert_is                   (  $$   ) ;
 assert_isa                  (  $@   ) ;
 assert_isnt                 (  $$   ) ;
 assert_known_package        (  $    ) ;
 assert_latin1               (  $    ) ;
 assert_latinish             (  $    ) ;
 assert_legal_exit_status    ( ;$    ) ;
 assert_like                 (  $$   ) ;
 assert_list_context         (       ) ;
 assert_list_nonempty        (  @    ) ;
 assert_lowercased           (  $    ) ;
 assert_method               (       ) ;
 assert_multi_line           (  $    ) ;
 assert_natural_number       (  $    ) ;
 assert_negative             (  $    ) ;
 assert_negative_integer     (  $    ) ;
 assert_nfc                  (  $    ) ;
 assert_nfd                  (  $    ) ;
 assert_nfkc                 (  $    ) ;
 assert_nfkd                 (  $    ) ;
 assert_no_coredump          ( ;$    ) ;
 assert_nonalphabetic        (  $    ) ;
 assert_nonascii             (  $    ) ;
 assert_nonastral            (  $    ) ;
 assert_nonblank             (  $    ) ;
 assert_nonbytes             (  $    ) ;
 assert_nonempty             (  $    ) ;
 assert_nonlist_context      (       ) ;
 assert_nonnegative          (  $    ) ;
 assert_nonnegative_integer  (  $    ) ;
 assert_nonnumeric           (  $    ) ;
 assert_nonobject            (  $    ) ;
 assert_nonpositive          (  $    ) ;
 assert_nonpositive_integer  (  $    ) ;
 assert_nonref               (  $    ) ;
 assert_nonvoid_context      (       ) ;
 assert_nonzero              (  $    ) ;
 assert_not_in_list          (  $@   ) ;
 assert_numeric              (  $    ) ;
 assert_object               (  $    ) ;
 assert_object_method        (       ) ;
 assert_odd_number           (  $    ) ;
 assert_open_handle          (  $    ) ;
 assert_positive             (  $    ) ;
 assert_positive_integer     (  $    ) ;
 assert_private_method       (       ) ;
 assert_public_method        (       ) ;
 assert_qualified_ident      (  $    ) ;
 assert_refref               (  $    ) ;
 assert_reftype              (  $$   ) ;
 assert_regex                (  $    ) ;
 assert_regular_file         (  $    ) ;
 assert_sad_exit             ( ;$    ) ;
 assert_scalar_context       (       ) ;
 assert_scalarref            (  $    ) ;
 assert_signalled            ( ;$    ) ;
 assert_signed_number        (  $    ) ;
 assert_simple_perl_ident    (  $    ) ;
 assert_single_line          (  $    ) ;
 assert_single_paragraph     (  $    ) ;
 assert_text_file            (  $    ) ;
 assert_true                 (  $    ) ;
 assert_undefined            (  $    ) ;
 assert_unhappy_code         (  &    ) ;
 assert_unicode_ident        (  $    ) ;
 assert_unlike               (  $$   ) ;
 assert_unsignalled          ( ;$    ) ;
 assert_uppercased           (  $    ) ;
 assert_void_context         (       ) ;
 assert_whole_number         (  $    ) ;
 assert_wide_characters      (  $    ) ;
 assert_zero                 (  $    ) ;

All assertions have function prototypes; this helps you use them correctly.

=head2 Export Tags

You may import all assertions or just some of them.  When importing only
some of them, you may wish to use an export tag to import a set of related
assertions.  Here is what each tag imports:

=over

=item C<:all> or C<:asserts>

C<assert_ainta>, C<assert_alnum>, C<assert_alphabetic>, C<assert_anyref>, C<assert_argc>, C<assert_argc_max>, C<assert_argc_min>, C<assert_argc_minmax>, C<assert_array_length>, C<assert_array_length_max>, C<assert_array_length_min>, C<assert_array_length_minmax>, C<assert_array_nonempty>, C<assert_arrayref>, C<assert_arrayref_nonempty>, C<assert_ascii>, C<assert_ascii_ident>, C<assert_astral>, C<assert_blank>, C<assert_bmp>, C<assert_box_number>, C<assert_bytes>, C<assert_can>, C<assert_cant>, C<assert_class_method>, C<assert_coderef>, C<assert_defined>, C<assert_defined_value>, C<assert_defined_variable>, C<assert_digits>, C<assert_directory>, C<assert_does>, C<assert_doesnt>, C<assert_dumped_core>, C<assert_empty>, C<assert_eq>, C<assert_eq_letters>, C<assert_even_number>, C<assert_exited>, C<assert_false>, C<assert_fractional>, C<assert_full_perl_ident>, C<assert_globref>, C<assert_happy_code>, C<assert_happy_exit>, C<assert_hash_keys>, C<assert_hash_nonempty>, C<assert_hashref>, C<assert_hashref_keys>, C<assert_hashref_nonempty>, C<assert_hex_number>, C<assert_in_list>, C<assert_in_numeric_range>, C<assert_integer>, C<assert_ioref>, C<assert_is>, C<assert_isa>, C<assert_isnt>, C<assert_known_package>, C<assert_latin1>, C<assert_latinish>, C<assert_legal_exit_status>, C<assert_like>, C<assert_list_context>, C<assert_list_nonempty>, C<assert_lowercased>, C<assert_method>, C<assert_multi_line>, C<assert_natural_number>, C<assert_negative>, C<assert_negative_integer>, C<assert_nfc>, C<assert_nfd>, C<assert_nfkc>, C<assert_nfkd>, C<assert_no_coredump>, C<assert_nonalphabetic>, C<assert_nonascii>, C<assert_nonastral>, C<assert_nonblank>, C<assert_nonbytes>, C<assert_nonempty>, C<assert_nonlist_context>, C<assert_nonnegative>, C<assert_nonnegative_integer>, C<assert_nonnumeric>, C<assert_nonobject>, C<assert_nonpositive>, C<assert_nonpositive_integer>, C<assert_nonref>, C<assert_nonvoid_context>, C<assert_nonzero>, C<assert_not_in_list>, C<assert_numeric>, C<assert_object>, C<assert_object_method>, C<assert_odd_number>, C<assert_open_handle>, C<assert_positive>, C<assert_positive_integer>, C<assert_private_method>, C<assert_public_method>, C<assert_qualified_ident>, C<assert_reftype>, C<assert_regex>, C<assert_regular_file>, C<assert_sad_exit>, C<assert_scalar_context>, C<assert_scalarref>, C<assert_signalled>, C<assert_signed_number>, C<assert_simple_perl_ident>, C<assert_single_line>, C<assert_single_paragraph>, C<assert_text_file>, C<assert_true>, C<assert_undefined>, C<assert_unhappy_code>, C<assert_unicode_ident>, C<assert_unlike>, C<assert_unsignalled>, C<assert_uppercased>, C<assert_void_context>, C<assert_whole_number>, C<assert_wide_characters>, and C<assert_zero>.

=item C<:argc>

C<assert_argc>, C<assert_argc_max>, C<assert_argc_min>, and C<assert_argc_minmax>.

=item C<:array>

C<assert_array_length>, C<assert_array_length_max>, C<assert_array_length_min>, C<assert_array_length_minmax>, C<assert_array_nonempty>, C<assert_arrayref>, C<assert_arrayref_nonempty>, and C<assert_list_nonempty>.

=item C<:boolean>

C<assert_false>, C<assert_happy_code>, C<assert_true>, and C<assert_unhappy_code>.

=item C<:case>

C<assert_lowercased> and C<assert_uppercased>.

=item C<:code>

C<assert_coderef>, C<assert_happy_code>, and C<assert_unhappy_code>.

=item C<:context>

C<assert_list_context>, C<assert_nonlist_context>, C<assert_nonvoid_context>, C<assert_scalar_context>, and C<assert_void_context>.

=item C<:file>

C<assert_directory>, C<assert_open_handle>, C<assert_regular_file>, and C<assert_text_file>.

=item C<:glob>

C<assert_globref>.

=item C<:hash>

C<assert_hash_keys>,
C<assert_hash_keys_allowed>,
C<assert_hash_keys_required>,
C<assert_hash_nonempty>,
C<assert_hashref>,
C<assert_hashref_keys>,
C<assert_hashref_keys_allowed>,
C<assert_hashref_keys_required>,
and 
C<assert_hashref_nonempty>.

=item C<:ident>

C<assert_ascii_ident>, C<assert_full_perl_ident>, C<assert_known_package>, C<assert_qualified_ident>, and C<assert_simple_perl_ident>.

=item C<:io>

C<assert_ioref> and C<assert_open_handle>.

=item C<:list>

C<assert_in_list>, C<assert_list_nonempty>, and C<assert_not_in_list>.

=item C<:number>

C<assert_box_number>, C<assert_digits>, C<assert_even_number>, C<assert_fractional>, C<assert_hex_number>, C<assert_in_numeric_range>, C<assert_integer>, C<assert_natural_number>, C<assert_negative>, C<assert_negative_integer>, C<assert_nonnegative>, C<assert_nonnegative_integer>, C<assert_nonnumeric>, C<assert_nonpositive>, C<assert_nonpositive_integer>, C<assert_nonzero>, C<assert_numeric>, C<assert_odd_number>, C<assert_positive>, C<assert_positive_integer>, C<assert_signed_number>, C<assert_whole_number>, and C<assert_zero>.

=item C<:object>

C<assert_ainta>, C<assert_can>, C<assert_cant>, C<assert_class_method>, C<assert_does>, C<assert_doesnt>, C<assert_isa>, C<assert_known_package>, C<assert_method>, C<assert_nonobject>, C<assert_object>, C<assert_object_method>, C<assert_private_method>, C<assert_public_method>, and C<assert_reftype>.

=item C<:process>

C<assert_dumped_core>, C<assert_exited>, C<assert_happy_exit>, C<assert_legal_exit_status>, C<assert_no_coredump>, C<assert_sad_exit>, C<assert_signalled>, and C<assert_unsignalled>.

=item C<:ref>

C<assert_anyref>, C<assert_arrayref>, C<assert_coderef>, C<assert_globref>, C<assert_hashref>, C<assert_ioref>, C<assert_nonref>, C<assert_refref>, C<assert_reftype>, and C<assert_scalarref>.

=item C<:regex>

C<assert_alnum>, C<assert_alphabetic>, C<assert_ascii>, C<assert_ascii_ident>, C<assert_blank>, C<assert_digits>, C<assert_full_perl_ident>, C<assert_hex_number>, C<assert_like>, C<assert_lowercased>, C<assert_multi_line>, C<assert_nonalphabetic>, C<assert_nonascii>, C<assert_nonblank>, C<assert_qualified_ident>, C<assert_regex>, C<assert_simple_perl_ident>, C<assert_single_line>, C<assert_single_paragraph>, C<assert_unicode_ident>, C<assert_unlike>, and C<assert_uppercased>.

=item C<:scalar>

C<assert_defined>, C<assert_defined_value>, C<assert_defined_variable>, C<assert_false>, C<assert_scalarref>, C<assert_true>, and C<assert_undefined>.

=item C<:string>

C<assert_alphabetic>, C<assert_ascii>, C<assert_blank>, C<assert_bytes>, C<assert_empty>, C<assert_eq>, C<assert_eq_letters>, C<assert_is>, C<assert_isnt>, C<assert_latin1>, C<assert_multi_line>, C<assert_nonalphabetic>, C<assert_nonascii>, C<assert_nonblank>, C<assert_nonbytes>, C<assert_nonempty>, C<assert_single_line>, C<assert_single_paragraph>, and C<assert_wide_characters>.

=item C<:unicode>

C<assert_astral>, C<assert_bmp>, C<assert_eq>, C<assert_eq_letters>, C<assert_latin1>, C<assert_latinish>, C<assert_nfc>, C<assert_nfd>, C<assert_nfkc>, C<assert_nfkd>, and C<assert_nonastral>.

=back


=cut

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
        } || die;
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

#
# The following attribute handler handler for subs saves
# us a lot of bookkeeping trouble by letting us declare
# which export tag groups a particular assert belongs to
# at the point of declaration where it belongs, and so
# that it is all handled automatically.
#
sub Assert : ATTR(CODE,BEGIN)
{
    my($package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum) = @_;
    no strict "refs";
    my($subname, $tagref) = (*{$symbol}{NAME}, $data);
    $subname =~ /^assert_/
        || panic "$subname is not an assertion";
    my $his_export_ok = $package . "::EXPORT_OK";
    push @$his_export_ok, $subname;
    $Assert_Debug && print STDERR "Assert: adding $subname to \@$his_export_ok\n";
    if (defined($tagref) && !ref($tagref)) {
        $tagref = [ $tagref ];
    }
    my $his_export_tags = $package . "::EXPORT_TAGS";
    for my $tag (@$tagref, qw(all asserts)) {
        $Assert_Debug && print STDERR "Assert: adding $subname to \$$his_export_tags\{$tag} arrayref\n";
        push @{ $his_export_tags->{$tag} }, $subname;
    }
}

########    Below this line should be only assertions    ########

=head2 Assertions about Calling Context

=over

=item C<assert_list_context()>

Current function was called in list context.

=cut

sub assert_list_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    $wantarray                  || botch "wanted to be called in list context";
}

=item C<assert_nonlist_context()>

Current function was not called in list context.

=cut

sub assert_nonlist_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    !$wantarray                 || botch "wanted to be called in nonlist context";
}

=item C<assert_scalar_context()>

Current function was called in scalar context.

=cut

sub assert_scalar_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    defined($wantarray) && !$wantarray
        || botch "wanted to be called in scalar context";
}

=item C<assert_void_context()>

Current function was called in void context.

=cut

sub assert_void_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    !defined($wantarray)        || botch "wanted to be called in void context";
}

=item C<assert_nonvoid_context()>

Current function was not called in void context.

=cut

sub assert_nonvoid_context()
    :Assert( qw[context] )
{
    my $wantarray = his_context;
    defined($wantarray)        || botch "wanted to be called in nonvoid context";
}

=back

=head2 Assertions about Scalars

=over

=item C<assert_true(I<SCALAR>)>

Scalar argument is true according
to Perl's sense of Boolean logic, the sort
of thing you would put in an C<if>) 
condition to have its block run.

Consider using C<assert_happy_code> instead for
more descriptive error messages.

=cut

sub assert_true($)
    :Assert( qw[scalar boolean] )
{
    my($arg) = @_;
    $arg                        || botch "expected true argument";
}

=item C<assert_false(I<SCALAR>)>

Scalar argument is false according
to Perl's sense of Boolean logic, the sort
of thing you would put in an C<unless>) 
condition to have its block run.

False values in Perl are the undefined value,
both kinds of empty string (C<q()> and C<!1>),
the string of length one whose only character
is an ASCII C<DIGIT ZERO>, and those numbers
which evaluate to zero.  Strings that evaulate
to numeric zero other than the previously stated
exemption are not false, such as the notorious
value C<"0 but true">,

Consider using C<assert_sad_code> instead for
more descriptive error messags.

=cut

sub assert_false($)
    :Assert( qw[scalar boolean] )
{
    my($arg) = @_;
    $arg                        && botch "expected true argument";

}

=item C<assert_defined(I<ARG>)>

The scalar argument is defined.  Consider using
one of either C<assert_defined_variable> or 
C<assert_defined_value> to better document your intention.

=cut

sub assert_defined($)
    :Assert( qw[scalar] )
{
    my($value) = @_;
    defined($value)            || botch "expected defined value as argument";
}

=item C<assert_undefined(I<ARG>)>

The scalar argument is not defined.

=cut

sub assert_undefined($)
    :Assert( qw[scalar] )
{
    my($scalar) = @_;
    defined($scalar) && botch "expected undefined argument";
}

=item C<assert_defined_variable(I<SCALAR>)>

The scalar B<variable> is defined.  This is safer to 
call than C<assert_defined_value> because it requires
an actual scalar variable with a leading dollar sign,
so generates a compiler error if you try to pass it
other sigils.

=cut

sub assert_defined_variable(\$)
    :Assert( qw[scalar] )
{
    &assert_scalarref;
    my($sref) = @_;
    defined($$sref)            || botch "expected defined scalar variable as argument";
}

=item C<assert_defined_value(I<VALUE>)>

The scalar B<value> is defined.

=cut

sub assert_defined_value($)
    :Assert( qw[scalar] )
{
    my($value) = @_;
    defined($value)            || botch "expected defined value as argument";
}

=item C<assert_is(I<THIS>, I<THAT>)>

The two non-ref arguments test true for string equality with the C<eq>
operator.  See also C<assert_eq> to compare normalized strings and
C<assert_eq_letters> to compare only the letters.

=cut

sub assert_is($$)
    :Assert( qw[string] )
{
    my($this, $that) = @_;
    assert_defined($_) for $this, $that;
    assert_nonref($_) for $this, $that;
    $this eq $that              || botch "string '$this' should be '$that'";
}

=item C<assert_isnt(I<THIS>, I<THAT>)>

The two non-ref arguments test false for string equality with the C<ne> operator.

=cut

sub assert_isnt($$)
    :Assert( qw[string] )
{
    my($this, $that) = @_;
    assert_defined($_) for $this, $that;
    assert_nonref($_) for $this, $that;
    $this ne $that              || botch "string '$this' should not be '$that'";
}

=back

=head2 Assertions about Numbers

=over

=item C<assert_numeric(I<ARG>)>

Non-ref argument looks like a number suitable for implicit conversion.

=cut

sub assert_numeric($)
    :Assert( qw[number] )
{
    &assert_defined;
    &assert_nonref;
    my($n) = @_;
    looks_like_number($n)       || botch "'$n' doesn't look like a number";
}

=item C<assert_nonnumeric(I<ARG>)>

Non-ref argument doesn't look like a number suitable for implicit conversion.

=cut

sub assert_nonnumeric($)
    :Assert( qw[number] )
{
    &assert_nonref;
    my($n) = @_;
   !looks_like_number($n)       || botch "'$n' looks like a number";
}

=item C<assert_positive(I<ARG>)>

Non-ref argument is numerically greater than zero.

=cut

sub assert_positive($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n > 0                     || botch "$n should be positive";
}

=item C<assert_nonpositive(I<ARG>)>

Non-ref argument is numerically less than or equal to zero.

=cut

sub assert_nonpositive($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n <= 0                    || botch "$n should not be positive";
}

=item C<assert_negative(I<ARG>)>

Non-ref argument is numerically less than zero.

=cut

sub assert_negative($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n < 0                     || botch "$n should be negative";
}

=item C<assert_nonnegative(I<ARG>)>

Non-ref argument is numerically greater than or equal to numeric zero.

=cut

sub assert_nonnegative($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n >= 0                     || botch "$n should not be negative";
}

=item C<assert_zero(I<ARG>)>

Non-ref argument is numerically equal to numeric zero.

=cut

sub assert_zero($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n == 0                     || botch "$n should be zero";
}

=item C<assert_nonzero(I<ARG>)>

Non-ref argument is not numerically equal to numeric zero.

=cut

sub assert_nonzero($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n != 0                     || botch "$n should not be zero";
}

=item C<assert_integer(I<ARG>)>

Non-ref numeric argument has no fractional part.

=cut

sub assert_integer($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($int) = @_;
    $int == int($int)              || botch "expected integer, not $int";
}

=item C<assert_fractional(I<ARG>)>

Non-ref numeric argument has a fractional part.

=cut

sub assert_fractional($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($float) = @_;
    $float != int($float)          || botch "expected fractional part, not $float";
}

=item C<assert_signed_number(I<ARG>)>

Non-ref numeric argument has a leading sign, ASCII C<-> or C<+>.
A Unicode C<MINUS SIGN> does not currently count because Perl
will not respect it for implicit string-to-number conversions.

=cut

sub assert_signed_number($)
    :Assert( qw[number] )
{
    &assert_numeric;
    my($n) = @_;
    $n =~ /^ [-+] /x             || botch "expected signed number, not $n";
}

=item C<assert_natural_number(I<N>)>

One of the counting numbers: 1, 2, 3, . . .

=cut

sub assert_natural_number($)
    :Assert( qw[number] )
{
    &assert_positive_integer;
    my($int) = @_;
}

=item C<assert_whole_number(I<ARG>)>

A natural number or zero.

=cut

sub assert_whole_number($)
    :Assert( qw[number] )
{
    &assert_nonnegative_integer;
    my($int) = @_;
}

=item C<assert_positive_integer(I<ARG>)>

An integer greater than zero.

=cut

sub assert_positive_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_positive;
}

=item C<assert_nonpositive_integer(I<ARG>)>

An integer not greater than zero.

=cut

sub assert_nonpositive_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_nonpositive;
}

=item C<assert_negative_integer(I<ARG>)>

An integer less than zero.

=cut

sub assert_negative_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_negative;
}

=item C<assert_nonnegative_integer(I<ARG>)>

An integer that's zero or below.

=cut

sub assert_nonnegative_integer($)
    :Assert( qw[number] )
{
    &assert_integer;
    &assert_nonnegative;
}

=item C<assert_hex_number(I<ARG>)>

Beyond an optional leading C<0x>, argument contains only ASCII hex digits,
making it suitable for feeding to the C<hex> function.

=cut

sub assert_hex_number($)
    :Assert( qw[regex number] )
{
    local($_) = @_;
    /^ (?:0x)? \p{ahex}+ \z/ix    || botch "expected only ASCII hex digits in string '$_'";
}

=item C<assert_box_number(I<ARG>)>

A string suitable for feeding to Perl's
C<oct> function, so a non-negative integer
with an optional leading C<0b>, C<0o>, or C<0x>.

=cut

sub assert_box_number($)
    :Assert( qw[number] )
{
    local($_) = @_;
    &assert_defined;
    /^ (?: 0b ) [0-1]+ \z /ix   ||
    /^ (?: 0o )? [0-7]+ \z /ix  ||
    /^ (?: 0x ) [0-9a-f]+ \z /ix 
        || botch "I wouldn't feed '$_' to oct() if I were you";
}

=item C<assert_even_number(I<N>)>

An integer that is an even multiple of two.

=cut

sub assert_even_number($)
    :Assert( qw[number] )
{
    &assert_integer;
    my($n) = @_;
    $n % 2 == 0                 || botch "$n should be even";
}

=item C<assert_odd_number(I<N>)>

An integer that is not an even multiple of two.

=cut

sub assert_odd_number($)
    :Assert( qw[number] )
{
    &assert_integer;
    my($n) = @_;
    $n % 2 == 1                 || botch "$n should be odd";
}

=item C<assert_in_numeric_range(I<NUMBER>, I<LOW>, I<HIGH>)>

A number that falls between the numeric
range specified in the next two arguments; 
that is, it must be at least as great as
the low end of the range but no higher than 
the high end of the range.

=cut

sub assert_in_numeric_range($$$)
    :Assert( qw[number] )
{
    assert_numeric($_) for my($n, $low, $high) = @_;
    $n >= $low && $n <= $high   || botch "expected $low <= $n <= $high";
}

=back

=head2 Assertions about Strings

=over

=item C<assert_empty(I<ARG>)>

Defined non-ref argument is of zero length.

=cut

sub assert_empty($)
    :Assert( qw[string] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    length($string) == 0        || botch "expected zero-length string";
}

=item C<assert_nonempty(I<ARG>)>

Defined non-ref argument is not of zero length.

=cut

sub assert_nonempty($)
    :Assert( qw[string] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    length($string) != 0        || botch "expected non-zero-length string";
}

=item C<assert_blank(I<ARG>)>

Defined non-ref argument has at most only whitespace 
characters in it.   It may be length zero.

=cut

sub assert_blank($)
    :Assert( qw[string regex] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    $string =~ /^ \p{whitespace}* \z/x     || botch "found non-whitespace in string '$string'"
}

=item C<assert_nonblank(I<ARG>)>

Defined non-ref argument has at least one non-whitespace 
character in it.

=cut

sub assert_nonblank($)
    :Assert( qw[string regex] )
{
    &assert_defined;
    &assert_nonref;
    my($string) = @_;
    $string =~ / \P{whitespace}/x       || botch "found no non-whitespace in string '$string'"
}

=item C<assert_single_line(I<ARG>)>

Non-empty string argument has at most one optional linebreak grapheme
(C<\R>, so a CRLF or vertical whitespace line newline, carriage return, and
formfeed) at the very end.  It is disqualified if it has a linebreak
anywhere shy of the end, or more than one of them at the end.

=cut

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

=item C<assert_multi_line(I<ARG>)>

Non-empty string argument has at most one optional linebreak grapheme
(C<\R>, so a CRLF or vertical whitespace line newline, carriage return, and
formfeed) at the very end.  It is disqualified if it has a linebreak
anywhere shy of the end, or more than one of them at the end.

=cut

sub assert_multi_line($)
    :Assert( qw[string regex] )
{
    &assert_nonempty;
    my($string) = @_;
    $string !~ $_single_line_rx         || botch "expected more than one linebreak";
}

=item C<assert_single_paragraph(I<ARG>)>

Non-empty string argument has at any number of linebreak graphemes
at the very end only.  It is disqualified if it has linebreaks
anywhere shy of the end, but does not care how many are there.

=cut

sub assert_single_paragraph($)
    :Assert( qw[string regex] )
{
    &assert_nonempty;
    my($string) = @_;
    $string =~ / \A ( (?! \R ) \X )+ \R* \z /x
                                        || botch "expected at most a single linebreak at the end";
}

=item C<assert_bytes(I<ARG>)>

Argument contains only code points between 0x00 and 0xFF.
Such data is suitable for writing out as binary bytes.

=cut

sub assert_bytes($)
    :Assert( qw[string] )
{
    local($_) = @_;
    /^ [\x00-\xFF] + \z/x      || botch "unexpected wide characters in byte string";
}

=item C<assert_nonbytes(I<ARG>)>

Argument contains code points greater than 0xFF.
Such data must first be encoded when written.

=cut

sub assert_nonbytes($)
    :Assert( qw[string] )
{
    &assert_wide_characters;
}

=item C<assert_wide_characters(I<ARG>)>

The same thing as saying that it contains non-bytes.

=cut

sub assert_wide_characters($)
    :Assert( qw[string] )
{
    local($_) = @_;
    /[^\x00-\xFF]/x             || botch "expected some wide characters in string";
}

=back

=head2 Assertions about Regexes

=over

=item C<assert_nonascii(I<ARG>)>

Argument contains at least one code point larger that 127.

=cut

sub assert_nonascii($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /\P{ascii}/x                || botch "expected non-ASCII in string";
}

=item C<assert_ascii(I<ARG>)>

Argument contains only code points less than 128.

=cut

sub assert_ascii($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \p{ASCII} + \z/x        || botch "expected only ASCII in string";
}

=item C<assert_alphabetic(I<ARG>)>

Argument contains only alphabetic code points,
but not necessarily ASCII ones.

=cut

sub assert_alphabetic($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \p{alphabetic} + \z/x        || botch "expected only alphabetics in string";
}

=item C<assert_nonalphabetic(I<ARG>)>

Argument contains only non-alphabetic code points,
but not necessarily ASCII ones.

=cut

sub assert_nonalphabetic($)
    :Assert( qw[string regex] )
{
    local($_) = @_;
    /^ \P{alphabetic} + \z/x        || botch "expected only non-alphabetics in string";
}

=item C<assert_alnum(I<ARG>)>

Argument contains only alphabetic or numeric code points,
but not necessarily ASCII ones.

=cut

sub assert_alnum($)
    :Assert( qw[regex] )
{
    local($_) = @_;
    /^ \p{alnum} + \z/x        || botch "expected only alphanumerics in string";
}

=item C<assert_digits(I<ARG>)>

Argument contains only ASCII digits.

=cut

sub assert_digits($)
    :Assert( qw[regex number] )
{
    local($_) = @_;
    /^ [0-9] + \z/x           || botch "expected only ASCII digits in string";
}

=item C<assert_uppercased(I<ARG>)>

Argument will not change if uppercased.

=cut

sub assert_uppercased($)
    :Assert( qw[case regex] )
{
    local($_) = @_;
    ($] >= 5.014 
        ?  ! /\p{Changes_When_Uppercased}/
        :  $_ eq uc )                 || botch "changes case when uppercased";
}

=item C<assert_lowercased(I<ARG>)>

Argument will not change if lowercased.

=cut

sub assert_lowercased($)
    :Assert( qw[case regex] )
{
    local($_) = @_;
    ($] >= 5.014 
        ?  ! /\p{Changes_When_Lowercased}/
        :  $_ eq lc )                 || botch "changes case when lowercased";
}

=item C<assert_unicode_ident(I<ARG>)>

Argument is a legal Unicode identifier, so one beginning with an (X)ID Start
code point and having any number of (X)ID Continue code points following.
Note that Perl identifiers are somewhat different from this.

=cut

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

=item C<assert_simple_perl_ident(I<ARG>)>

Like a Unicode identifier but which may also start
with connector punctuation like underscores.  No package
separators are allowed, however.  Sigils do not count.

Also, special variables like C<$.> or C<${^PREMATCH}>
will not work either, since C<.> and C<{> and C<^> are
all behind the pale.

=cut

sub assert_simple_perl_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ $perl_simple_ident_rx \z/x
                                || botch "invalid simple perl identifier $_";
}

=item C<assert_full_perl_ident(I<ARG>)>

Like a simple Perl identifier but which also 
allows for optional package separators, 
either C<::> or C<'>.

=cut

sub assert_full_perl_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ $perl_qualified_ident_rx \z/x
                                || botch "invalid qualified perl identifier $_";
}

=item C<assert_qualified_ident(I<ARG>)>

Like a full Perl identifier but with
mandatory package separators, either C<::> or C<'>.

=cut

sub assert_qualified_ident($)
    :Assert( qw[regex ident] )
{
    &assert_full_perl_ident;
    local($_) = @_;
    /(?: ' | :: ) /x           || botch "no package separators in $_";
}

=item C<assert_ascii_ident(I<ARG>)>

What most people think of as an identifier,
one with only ASCII letter, digits, and underscores,
and which cannot begin with a digit.

=cut

sub assert_ascii_ident($)
    :Assert( qw[regex ident] )
{
    local($_) = @_;
    /^ (?= \p{ASCII}+ \z) (?! \d) \w+ \z/x
                                || botch q(expected only ASCII \\w characters in string);
}

=item C<assert_regex(I<ARG>)>

The argument is a compile Regexp object.

=cut

sub assert_regex($)
    :Assert( qw[regex] )
{
    my($pattern) = @_;
    assert_isa($pattern, "Regexp");
}

=item C<assert_like(I<STRING>, I<PATTERN>)>

The string, which must be a defined non-reference,
matches the pattern, which must be a compiled Regexp object.

=cut

sub assert_like($$)
    :Assert( qw[regex] )
{
    my($string, $pattern) = @_;
    assert_defined($string);
    assert_nonref($string);
    assert_regex($pattern);
    $string =~ $pattern         || botch "'$string' did not match $pattern";
}

=item C<assert_unlike(I<STRING>, I<PATTERN>)>

The string, which must be a defined non-reference,
cannot match the pattern, which must be a compiled Regexp object.

=cut

sub assert_unlike($$)
    :Assert( qw[regex] )
{
    my($string, $pattern) = @_;
    assert_defined($string);
    assert_nonref($string);
    assert_regex($pattern);
    $string !~ $pattern         || botch "'$string' should not match $pattern";
}

=back

=head2 Assertions about Unicode

=over

=item C<assert_latin1(I<ARG>)>

Argument contains only code points
from U+0000 through U+00FF.

=cut

sub assert_latin1($)
    :Assert( qw[string unicode] )
{
    &assert_bytes;
}

=item C<assert_latinish(I<ARG>)>

Argument contains only characters from the
Latin, Common, or Inherited scripts.

=cut

sub assert_latinish($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    /^[\p{Latin}\p{Common}\p{Inherited}]+/
                                    || botch "expected only Latinish characters in string";
}

=item C<assert_astral(I<ARG>)>

Argument contains at least one code point larger
than U+FFFF, so those above Plane 0.

=cut

sub assert_astral($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    no warnings "utf8";  # early versions of perl complain of illegal for interchange on FFFF
    /[^\x00-\x{FFFF}]/x            || botch "expected non-BMP characters in string";
}

=item C<assert_nonastral(I<ARG>)>

Argument contains only code points
from U+0000 through U+FFFF.

=cut

sub assert_nonastral($)
    :Assert( qw[unicode] )
{
    local($_) = @_;
    no warnings "utf8";  # early versions of perl complain of illegal for interchange on FFFF
    /^ [\x00-\x{FFFF}] * \z/x      || botch "unexpected non-BMP characters in string";
}

=item C<assert_bmp(I<ARG>)>

Arugment contains only code points in the 
Basic Multilingual Plain; that is, in Plane 0.

=cut

sub assert_bmp($)
    :Assert( qw[unicode] )
{
    &assert_nonastral;
}

=item C<assert_nfc(I<ARG>)>

The argument is in Unicode Normalization Form C, 
formed by canonical decomposition followed by
canonical composition.

=cut

sub assert_nfc($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFC($str) // $str eq NFC($str)           
                                || botch "string not in NFC form";
}

=item C<assert_nfkc(I<ARG>)>

The argument is in Unicode Normalization Form KC, 
formed by compatible decomposition followed by
compatible composition.

=cut

sub assert_nfkc($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFKC($str) // $str eq NFKC($str)           
                                || botch "string not in NFKC form";
}

=item C<assert_nfd(I<ARG>)>

The argument is in Unicode Normalization Form D, 
formed by canonical decomposition.

=cut

sub assert_nfd($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFD($str)              || botch "string not in NFD form";
}

=item C<assert_nfkd(I<ARG>)>

The argument is in Unicode Normalization Form KD, 
formed by compatible decomposition.

=cut

sub assert_nfkd($)
    :Assert( qw[unicode] )
{
    my($str) = @_;
    checkNFKD($str)              || botch "string not in NFKD form";
}

=item C<assert_eq(I<THIS>, I<THAT>)>

The two strings have the same NFC forms using the C<eq>
operator.  This means that default ignorable code points
will throw of the equality check.

=cut

sub assert_eq($$)
    :Assert( qw[string unicode] )
{
    my($this, $that) = @_;
    NFC($this) eq NFC($that)    || botch "not equivalent strings";
}

=item C<assert_eq_letters(I<THIS>, I<THAT>)>

The two strings test equal when considered 
only at the primary strength (letters only) using Unicode Collation
Algorithm.  That means that case, non-letters, and combining
marks are ignored, as are other default ignorable code points.

=cut

sub assert_eq_letters($$)
    :Assert( qw[string unicode] )
{
    my($this, $that) = @_;
    UCA1($this) eq UCA1($that)  || botch "not equivalent letters"
}

=back

=head2 Assertions about Lists

=over

=item C<assert_in_list(I<STRING>, I<LIST>)>

The first argument must occur in the list following it.

=cut

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

=item C<assert_not_in_list(I<STRING>, I<LIST>)>

The first argument must not occur in the list following it.

=cut

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

=item C<assert_list_nonempty(I<LIST>)>

The list must not have zero elements.

=cut

sub assert_list_nonempty( @ )
    :Assert( qw[list array] )
{
    @_                          || botch "list is empty";
}

=back

=head2 Assertions about Arrays

=over

=item C<assert_array_nonempty( I<ARRAY> )>

The array must not have zero elements.

=cut

sub assert_array_nonempty( \@ )
    :Assert( qw[array] )
{
    &assert_arrayref_nonempty;
}

=item C<assert_arrayref_nonempty( I<ARRAYREF> )>

The array reference must refer to an existing array with 
more than zero elements.

=cut

sub assert_arrayref_nonempty( $ )
    :Assert( qw[array] )
{
    &assert_array_length;
    my($aref) = @_;
    assert_arrayref($aref);
    my $count = @$aref;
    $count > 0  || botch("array $count should not be empty");
}

=item C<assert_array_length( I<ARRAY>, [ I<LENGTH> ])>

The array must have the number of elements specified
in the optional second argument.  If the second
argument is omitted, any non-zero length will do.

=cut

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

=item C<assert_array_length_min( I<ARRAY>, I<MIN_ELEMENTS> )>

The array must have at least as many elements as specified
in the  second argument.  

=cut

sub assert_array_length_min( \@ $ )
    :Assert( qw[array] )
{
    my($aref, $want) = @_;
    assert_arrayref($aref);
    assert_whole_number($want);
    my $have = @$aref;
    $have >= $want            || botch_array_length($have, "$want or more");
}

=item C<assert_array_length_max( I<ARRAY>, I<MAX_ELEMENTS> )>

The array must have no more elements than specified
in the second argument.  

=cut

sub assert_array_length_max( \@ $ )
    :Assert( qw[array] )
{
    my($aref, $want) = @_;
    assert_arrayref($aref);
    assert_whole_number($want);
    my $have = @$aref;
    $have <= $want            || botch_array_length($have, "$want or fewer");
}

=item C<assert_array_length_minmax(I<ARRAY>, I<MIN_ELEMENTS>, I<MAX_ELEMENTS>)>

The array must have at least as many elements as
the second element, but no more than the third.

=cut

sub assert_array_length_minmax( \@ $$)
    :Assert( qw[array] )
{
    my($aref, $low, $high) = @_;
    my $have = @$aref;
    assert_whole_number($_) for $low, $high;
    $have >= $low && $have <= $high
                                || botch_array_length($have, "between $low and $high");
}

=back

=head2 Assertions about Argument Counts

=over

=item C<assert_argc(;$)>

The function must have been passed the number of arguments specified
in the optional assert argument.  If the assert
argument is omitted, any non-zero number of arguments will do.

=cut

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

=item C<assert_argc_min(I<ARG>)>

The function must have been passed at least as many arguments as specified
in the assert argument.  

=cut

sub assert_argc_min($)
    :Assert( qw[argc] )
{
    &assert_whole_number;
    my($want) = @_;
    my $have = his_args;
    $have >= $want              || botch_argc($have, "$want or more");
}

=item C<assert_argc_max(I<ARG>)>

The function must have been passed no more arguments than specified
in the assert argument.  

=cut

sub assert_argc_max($)
    :Assert( qw[argc] )
{
    &assert_whole_number;
    my($want) = @_;
    my $have = his_args;
    $have <= $want             || botch_argc($have, "$want or fewer");
}

=item C<assert_argc_minmax(I<MIN>, I<MAX>)>

The function must have been passed at least as many arguments as
specified by the first assert element, but no more than the second.

=cut

sub assert_argc_minmax($$)
    :Assert( qw[argc] )
{
    assert_whole_number($_) for my($low, $high) = @_;
    my $have = his_args;
    $have >= $low && $have <= $high
        || botch_argc($have, "between $low and $high");
}

=back

=head2 Assertions about Hashes

=over

=item C<assert_hash_nonempty(I<HASH>)>

The hash must have at least one key.

=cut

sub assert_hash_nonempty(\%)
    :Assert( qw[hash] )
{
    &assert_hashref_nonempty;
}

=item C<assert_hashref_nonempty(I<HASHREF>)>

The hashref's referent must have at least one key.

=cut

sub assert_hashref_nonempty($)
    :Assert( qw[hash] )
{
    &assert_hashref;
    my($href) = @_;
    %$href                      || botch "hash should not be empty";
}

=item C<assert_hash_keys(I<HASH>, I<KEYLIST>)>

Each key specified in the key list must exist in the hash.

=cut

sub assert_hash_keys(\% @)
    :Assert( qw[hash] )
{
    &assert_hashref_keys;
}

=item C<assert_hash_keys_required(I<HASH>, I<KEYLIST>)>

Each key specified in the key list must exist in the hash,
but it's ok if there are other non-required keys.

=cut

sub assert_hash_keys_required(\%@)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_required;
}

=item C<assert_hash_keys_allowed(I<HASH>, I<KEYLIST>)>

Only keys in the given keylist are allowed in the hash.

=cut

sub assert_hash_keys_allowed(\%@)
    :Assert( qw[hash] )
{
    &assert_hashref_keys_allowed;
}

=item C<assert_hashref_keys(I<HASHREF>, I<KEYLIST>)>

Each key specified in the key list must exist in the hashref's referent.

=cut

sub assert_hashref_keys($@)
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    assert_hashref($hashref);
    @keylist                            || botch "no keys given";
    for my $key (@keylist) {
        exists $hashref->{$key}         || botch "key '$key' missing from hash";
    }

}

=item C<assert_hashref_keys_required(I<HASHREF>, I<KEYLIST>)>

Each key specified in the key list must exist in the hashref's referent,
but it's ok if there are other non-required keys.

=cut

sub assert_hashref_keys_required($@)
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    assert_hashref($hashref);
    @keylist                            || botch "no keys given";
    for my $key (@keylist) {
        exists $hashref->{$key}         || botch "key '$key' missing from hash";
    }
}

=item C<assert_hashref_keys_allowed(I<HASHREF>, I<KEYLIST>)>

Only keys in the given keylist are allowed in the referenced hash.

=cut

sub assert_hashref_keys_allowed($@)
    :Assert( qw[hash] )
{
    my($hashref, @keylist) = @_;
    assert_hashref($hashref);
    @keylist                || botch "no keys given";
    my %ok = map { $_ => 1 } @keylist;
    for my $key (keys %$hashref) {
        $ok{$key}           || botch "hash key '$key' forbidden";
    }
}

=back

=head2 Assertions about References

=over

=item C<assert_anyref(I<ARG>)>

Argument must be a reference.

=cut

sub assert_anyref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
    ref($arg)                   || botch "expected reference argument";
}

=item C<assert_nonref(I<ARG>)>

Argument must not be a reference.

=cut

sub assert_nonref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
   !ref($arg)                   || botch "expected nonreference argument";
}

=item C<assert_reftype(I<TYPE>, I<REF>)>

The basic type of the reference must match the one specified.

=cut

sub assert_reftype($$)
    :Assert( qw[object ref] )
{
    my($type, $arg) = @_;
    (reftype($arg)//q()) eq $type      || botch "expected reftype of $type";
}

=item C<assert_globref(I<ARG>)>

Argument must be a GLOB ref.

=cut

sub assert_globref($)
    :Assert( qw[glob ref] )
{
    my($arg) = @_;
    assert_reftype(GLOB => $arg);
}

=item C<assert_ioref(I<ARG>)>

Argument must be a IO ref.  You probably don't
want this; you probably want C<assert_open_handle>.

=cut

sub assert_ioref($)
    :Assert( qw[io ref] )
{
    my($arg) = @_;
    assert_reftype(IO => $arg);
}

=item C<assert_coderef(I<ARG>)>

Argument must be a CODE ref.

=cut

sub assert_coderef($)
    :Assert( qw[code ref] )
{
    my($arg) = @_;
    assert_reftype(CODE => $arg);
}

=item C<assert_hashref(I<ARG>)>

Argument must be a HASH ref.

=cut

sub assert_hashref($)
    :Assert( qw[hash ref] )
{
    my($arg) = @_;
    assert_reftype(HASH => $arg);
}

=item C<assert_arrayref(I<ARG>)>

Argument must be an ARRAY ref.

=cut

sub assert_arrayref($)
    :Assert( qw[array ref] )
{
    my($arg) = @_;
    assert_reftype(ARRAY => $arg);
}

=item C<assert_scalarref(I<ARG>)>

Argument must be a SCALAR ref.

=cut

sub assert_refref($)
    :Assert( qw[ref] )
{
    my($arg) = @_;
    assert_reftype(REF => $arg);
}

=item C<assert_refref(I<ARG>)>

Argument must be a REF ref.

=cut

sub assert_scalarref($)
    :Assert( qw[scalar ref] )
{
    my($arg) = @_;
    assert_reftype(SCALAR => $arg);
}

=back

=head2 Assertions about Objects

=over

=item C<assert_method()>

Function must have at least one argument.

=cut

sub assert_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "no invocant found in method invoked as subroutine";
}

=item C<assert_object_method()>

First argument to function must be blessed.

=cut

sub assert_object_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "no invocant found";
    my($self) = his_args;
    blessed($self)              || botch "object method invoked as class method";
}

=item C<assert_class_method()>

First argument to function must not be blessed.

=cut

sub assert_class_method()
    :Assert( qw[object] )
{
    my $argc = his_args;
    $argc >= 1                  || botch "no invocant found";
    my($class) = his_args;
   !blessed($class)             || botch "class method invoked as object method";
}

=item C<assert_private_method()>

Must have been called by a function of the same file and package.

=cut

sub assert_private_method()
    :Assert( qw[object] )
{
    my @from = caller(1);
    my @to   = caller(0);
    (
        $from[CALLER_PACKAGE]  eq $to[CALLER_PACKAGE]
      &&
        $from[CALLER_FILENAME] eq $to[CALLER_FILENAME]
    )                           || botch "private sub invoked inappropriately";
}

=item C<assert_public_method()>

Does nothing.

=cut

sub assert_public_method()
    :Assert( qw[object] )
{
    return;
}

=item C<assert_known_package(I<ARG>)>

The specified argument's package symbol table 
is not empty.

=cut

sub assert_known_package($)
    :Assert( qw[object ident] )
{
    &assert_nonempty;
    my($arg) = @_;
    my $stash = do { no strict "refs"; \%{ $arg . "::" } };
    no overloading;
    %$stash                     || botch "unknown package $arg";
}

=item C<assert_object(I<ARG>)>

Argument must be an object.

=cut

sub assert_object($)
    :Assert( qw[object] )
{
    &assert_anyref;
    my($arg) = @_;
    blessed($arg)               || botch "expected blessed referent";
}

=item C<assert_nonobject(I<ARG>)>

Argument must not be an object.

=cut

sub assert_nonobject($)
    :Assert( qw[object] )
{
    my($arg) = @_;
   !blessed($arg)               || botch "expected unblessed referent";
}

=item C<assert_can(I<INVOCANT>, C<METHOD>)>

The invocant can invoke the method.

=cut

sub _get_invocant_type($) {
    my($invocant) = @_;
    my $type;
    if (blessed $invocant) {
        $type = "object";
    } else {
        $type = "package";
        #assert_known_package($invocant);
    }
    return $type;
}

sub assert_can($@)
    :Assert( qw[object] )
{
    my($invocant, @methods) = @_;
    @methods                            || botch "need one or more methods to check against";
    my $type = _get_invocant_type $invocant;
    for my $method (@methods) {
        no overloading;
        $invocant->can($method)         || botch "cannot invoke $method method on $type $invocant";
    }
}

=item C<assert_cant(I<INVOCANT>, C<METHOD>)>

The invocant cannot invoke the method.

=cut

sub assert_cant($@)
    :Assert( qw[object] )
{
    my($invocant, @methods) = @_;
    @methods                            || botch "need one or more methods to check against";
    my $type = _get_invocant_type $invocant;
    for my $method (@methods) {
        no overloading;
       !$invocant->can($method)         || botch "method $method should not be invocable on $type $invocant";
    }
}

=item C<assert_isa(I<INVOCANT>, I<CLASS_LIST>)>

The invocant must be a subclass of each class in the class list.

=cut

sub assert_isa($@)
    :Assert( qw[object] )
{
    my($subclass, @superclasses) = @_;
    @superclasses                       || botch "needs one or more superclasses to check against";
    my $type = _get_invocant_type $subclass;
    for my $superclass (@superclasses) {
        no overloading;
        $subclass->isa($superclass)     || botch "your $subclass $type should be a subclass of $superclass";
    }
}

=item C<assert_ainta(I<INVOCANT>, I<CLASS_LIST>)>

The invocant cannot be a subclass of any class in the class list.

=cut

sub assert_ainta($@)
    :Assert( qw[object] )
{
    my($subclass, @superclasses) = @_;
    @superclasses                       || botch "needs one or more superclasses to check against";
    my $type = _get_invocant_type $subclass;
    for my $superclass (@superclasses) {
        no overloading;
       !$subclass->isa($superclass)     || botch "your $subclass $type should not be a subclass of $superclass";
    }
}

=item C<assert_does(I<INVOCANT>, I<CLASS_LIST>)>

The invocant must be able to C<< ->DOES >> each class in the class list.

=cut

sub assert_does($@)
    :Assert( qw[object] )
{
    my($invocant, @roles) = @_;
    @roles                              || botch "needs one or more roles to check against";
    my $type = _get_invocant_type $invocant;
    for my $role (@roles) {
        no overloading;
        $invocant->DOES($role)          || botch "your $invocant $type does not have role $role";
    }
}

=item C<assert_doesnt(I<INVOCANT>, I<CLASS_LIST>)>

The invocant must not be able to C<< ->DOES >> any class in the class list.

=cut

sub assert_doesnt($@)
    :Assert( qw[object] )
{
    my($invocant, @roles) = @_;
    @roles                              || botch "needs one or more roles to check against";
    my $type = _get_invocant_type $invocant;
    for my $role (@roles) {
        no overloading;
       !$invocant->DOES($role)          || botch "your $invocant $type should not have role $role";
    }
}

=back

=head2 Assertions about Code

=over

=cut

sub _run_code_test($$) {
    my($code, $joy) = @_;
    assert_coderef($code);
    return if !!&$code() == !!$joy;
    botch sprintf "%s test %s is sadly %s",
        $joy ? "happy" : "unhappy",
        subname_or_code($code),
        $joy ? "false" : "true";
}

=item C<assert_happy_code(C<CODE_BLOCK>)>

The supplied code block returns true.

This one and the next give nice error messages, but are not
wholly removed from your program's parse tree at compile time
is assertions are off.  The argument is not called, but an empty
function is.

=cut

sub assert_happy_code(&)
    :Assert( qw[boolean code] )
{
    my($cref) = @_;
    _run_code_test($cref => 1);
}

=item C<assert_unhappy_code(C<CODE_BLOCK>)>

The supplied code block returns false.

=cut

sub assert_unhappy_code(&)
    :Assert( qw[boolean code] )
{
    my($cref) = @_;
    _run_code_test($cref => 0);
}

=back

=head2 Assertions about Files

=over

=item C<assert_open_handle(I<ARG>)>

The argument represents an open filehandle.

=cut

sub assert_open_handle($)
    :Assert( qw[io file] )
{
    my($arg) = @_;
    assert_defined($arg);
    defined(openhandle($arg))   || botch "handle $arg is not an open handle";
}

=item C<assert_regular_file(I<ARG>)>

The argument is a regular file.

=cut

sub assert_regular_file($)
    :Assert( qw[file] )
{
    my($arg) = @_;
    assert_defined($arg);
    -f $arg                    || botch "appears that $arg is not a plainfile"
                                      . " nor a symlink to a plainfile";
}

=item C<assert_text_file(I<ARG>)>

The argument is a regular file and a text file.

=cut

sub assert_text_file($)
    :Assert( qw[file] )
{
    &assert_regular_file;
    my($arg) = @_;
    -T $arg                    || botch "appears that $arg does not contain text";
}

=item C<assert_directory(I<ARG>)>

The argument is a directory.

=cut

sub assert_directory($)
    :Assert( qw[file] )
{
    my($arg) = @_;
    -d $arg                    || botch "appears that $arg is not a directory"
                                      . " nor a symlink to a directory";
}

=back

=head2 Assertions about Processes

All these assertions take an optional status argument
as would be found in the C<$?> variable.  If not status
argument is passed, the C<$?> is used by default.

=over

=cut

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

=item C<assert_legal_exit_status( [ I<STATUS> ])>

The numeric value fits in 16 bits.

=cut

sub assert_legal_exit_status(;$)
    :Assert( qw[process] )
{
    my($wstat) = @_ ? $_[0] : $?;
    assert_whole_number($wstat);
    $wstat < 2**16              || botch "exit value $wstat over 16 bits";
}

=item C<assert_signalled( [ I<STATUS> ])>

The process was signalled.

=cut

sub assert_signalled(;$)
    :Assert( qw[process] )
{
    &assert_legal_exit_status;
    my($wstat) = @_ ? $_[0] : $?;
    WIFSIGNALED($wstat)         || botch "exit value $wstat indicates no signal";
}

=item C<assert_unsignalled( [ I<STATUS> ])>

The process was not signalled.

=cut

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

=item C<assert_dumped_core( [ I<STATUS> ])>

The process dumped core.

=cut

sub assert_dumped_core(;$)
    :Assert( qw[process] )
{
    &assert_signalled;
    my($wstat) = @_ ? $_[0] : $?;
    my $signo = WTERMSIG($wstat);
    my $sigmsg = _signum_message($signo);
    _WIFCORED($wstat)           || botch "exit value $wstat indicates signal $sigmsg but no core dump";
}

=item C<assert_no_coredump( [ I<STATUS> ])>

The process did not dump core.

=cut

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

=item C<assert_exited( [ I<STATUS> ])>

The process was not signalled, but rather exited
either explicitly or implicitly.

=cut

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

=item C<assert_happy_exit( [ I<STATUS> ])>

The process was not signalled and exited with an exit status of zero.

=cut

sub assert_happy_exit(;$)
    :Assert( qw[process] )
{
    &assert_exited;
    my($wstat) = @_ ? $_[0] : $?;
    my $exit = WEXITSTATUS($wstat);
    $exit == 0                  || botch "exit status $exit is not a happy exit";
}

=item C<assert_sad_exit( [ I<STATUS> ])>

The process was not signalled but exited with a non-zero exit status.

=back

=cut

sub assert_sad_exit(;$)
    :Assert( qw[process] )
{
    &assert_exited;
    my($wstat) = @_ ? $_[0] : $?;
    my $exit = WEXITSTATUS($wstat);
    $exit != 0                  || botch "exit status 0 is an unexpectedly happy exit";
}

{ exit !dump_exports(@ARGV) unless his_is_require(-1) }

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
    test-assert[19009]: botched assertion assert_happy_code: Happy test $i > $j is sadly false, bailing out at tests/test-assert line 27.
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
assertions either passed (C<assert_nonlist_context>, C<assert_open_handle>)
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
    test-assert[19129]: botched assertion assert_happy_code: Happy test $i > $j is sadly false at tests/test-assert line 27.
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test $i < $j is sadly true at tests/test-assert line 28.
    checking args for oddity
    test-assert[19129]: botched assertion assert_odd_number: 4 should be odd at tests/test-assert line 49.
    test-assert[19129]: botched assertion assert_array_length: Have 2 array elements but wanted 11 at tests/test-assert line 32.
    test-assert[19129]: botched assertion assert_nonnegative: -54 should not be negative at tests/test-assert line 33.
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test $i < $j is sadly true at tests/test-assert line 34.
    test-assert[19129]: botched assertion assert_array_length_min: Have 2 array elements but wanted 20 or more at tests/test-assert line 35.
    test-assert[19129]: botched assertion assert_void_context: Wanted to be called in void context at tests/test-assert line 37.
    test-assert[19129]: botched assertion assert_list_context: Wanted to be called in list context at tests/test-assert line 38.
    checking args for oddity
    test-assert[19129]: botched assertion assert_unhappy_code: Unhappy test Anything::But::Main::Just::To::See::If::It::Works::check_args() is sadly true at tests/test-assert line 43.

Notice how even though those assertions botch, they don't bail out of your program.


=head1 ENVIRONMENT

The C<ASSERT_CONDITIONAL> variable controls the behavior of the underlying
C<botch> function from L<Assert::Conditional::Utils>, and also of the the
conditional importing itself.

=head1 SEE ALSO

The L<Exporter::ConditionalSubs> module which this module is based on.

The L<Assert::Conditional::Utils> module provides some semi-standalone utility
functions.

=head1 CAVEATS AND PROVISOS

This is an alpha release. Everything is subject to change.

=head1 BUGS AND LIMITATIONS

Under versions of Perl previous to v5.12.1, Attribute::Handlers
blows up with an internal error about a symbol going missing.
This bug is under investigation.

=head1 HISTORY

 0.001    6 June 2015 23:28 MDT 
          Initial alpha release

 0.002    J June 2015 22:35 MDT 
          MONGOLIAN VOWEL SEPARATOR is no longer whitespace 
          in Unicode, so removed from test.

 0.003    Tue Jun 30 05:47:16 MDT 2015
          Added assert_hash_keys_required and assert_hash_keys_allowed.
          Fixed some tests.
          Added bug report about Attribute::Handlers bug prior to 5.12.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

Thanks to Larry Leszczynski at Grant Street Group for making this module
possible.  Without it, my programs would be much slower, since before I
added his module to my old and pre-existing assertion system, the
assertions alone were taking up far too much CPU time.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

1;

__DATA__
