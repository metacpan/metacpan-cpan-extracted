###
###  Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.
###
###  Module: Advanced::Config::Options

=head1 NAME

Advanced::Config::Options - Options manager for L<Advanced::Config>.

=head1 SYNOPSIS

 use Advanced::Config::Options;
 or 
 require Advanced::Config::Options;

=head1 DESCRIPTION

F<Advanced::Config::Options> is a helper module to L<Advanced::Config>.  So it
should be very rare to directly call any methods defined by this module.

It's main job is to help manage the settings of the B<Read>, B<Get> and B<Date>
options hashes.  It was implemented as a separate module to make it simpler to
document the various supported options without cluttering up the POD of the main
module.  So you are not expected to ever call any of these methods yourself.
It's here mainly as an FYI.

If you don't specify the options below, this module will assume you wish to use
the default behaviour for that option.  So only override what you need to.
Also all options are in lower case.  But you may provide them in mixed case if
you wish.  This module will auto downshift them for you.

If an option is mispelled, or you don't provide a valid value, a warning will
be written to the screen and that option will be ignored.

=head1 ==================================================================

=head2 Z<>

=head1 The Read Options

In most cases the defaults should do nicely for you.  But when you share config
files between applications, you may not have any control over the config file's
format.  This may also apply if your organization requires a specific format
for its config files.

So this section deals with the options you can use to override how it parses and
interprets the config file when it is loaded into memory.  None of these options
below allows leading or trailing spaces in the option's value.  And if any are
found, they will be automatically trimmed off before their value is used.
Internal spaces are OK when non-numeric values are expected.  In most cases
values with a length of B<0> or B<undef> are not allowed.

Just be aware that some combinations of I<Read> options may result in this
module being unable to parse the config file.  If you encounter such a
combination open a CPAN ticket and I'll see what I can do about it.  But some
combinations may just be too ambiguous to handle.

Also note that some I<Read> options have B<left> and B<right> variants.  These
options are used in pairs and both must anchor the target in order for the rule
to be applied to it.  These start/end anchors can be set to the same string or
different strings.  Your choice.

=head2 Tag(s) Best Set in Call to the Constructor new().

While not required to set these options during the call to B<new>, changing
their settings later on can cause unexpected issues if you are not careful.

But it's still recommended that most I<Read> Options be set during the call to
B<new> to avoid having to keep on resetting them all the time and limit these
later changes to handle exceptions to your defaults.

=over 4

B<tag_case> - Config files are made up of tag/value pairs.  This option controls
whether the tags are case sensitive (B<0>, the default) or case insensitive
(B<1>).  IE do tags B<ABC> and B<abc> represent the same tag or not?  So if set,
all tags are assumed to be in lower case for the get/set methods!

=back

=head2 Generic Read Options

These options are also usually set during the call to B<new>, but setting them
later on doesn't produce strange behavior if you change the settings later on.

=over 4

B<croak> - This controls what happens when a function hits an unexpected error
while parsing the config file.  Set to B<0> to return an error code (default),
B<-1> to return an error code and print a warning to your screen, B<1> to call
die and terminate your program.

B<export> - Tells if we should export all tag/value pairs to perl's %ENV hash
or not.  The default is B<0> for I<No>.  Set to B<1> if you want this to happen.
But if set, it reverses the meaning of the B<export_lbl> option defined later
on.

B<use_utf8> - Defaults to B<0>.  Set to B<1> if the config file was created
using utf8 encoding.  (IE Unicode or Wide Characters.)  Guessing this
setting wrong means the file will be unusable as a config file.

B<disable_quotes> - Defaults to B<0>.  Set to B<1> if you want to disallow
the stripping of balanced quotes in your config files.

B<disable_variables> - Defaults to B<0>.  Set to B<1> if you want to disable
variable expansion in your config files when they are loaded into memory.

B<disable_variable_modifiers> - Defaults to B<0>.  Set to B<1> if you want to
disable this feature.  See L<http://wiki.bash-hackers.org/syntax/pe> for more
details.  This feature allows you to put logic into your config files via
your variable definitions.  Automtaically disabled when variables are
disabled.  Usefull when you put a lot of special chars into your variable
names.

B<disable_decryption> - Defaults to B<0>.  Set to B<1> if you want to disable
decrypting values that have been marked as encrypted.  If a variable references
an encrypted value while disable_decription is active, that variable isn't
expanded.

=cut 

# B<enable_backquotes> - Defaults to B<0>.  Set to B<1> if you want to enable
# this feature.  It's disabled by default since it can be considered a security
# hole if an unauthorized user can modify your config file or your code.

=pod

B<trap_recursion> - Defaults to B<0>.  Set to B<1> if you want to treat
recursion as a fatal error when loading a config file.  By default it just
ignores the recursion request to prevent infinite loops.

B<source_cb_opts> - A work area for holding values between calls to the
callback function.  This is expected to be a hash reference to provide any
needed configuration values needed to parse the next config file.  This way
you can avoid global varibles.  Defaults to an empty hash reference.

B<source_cb> - An optional callback routine called each time your config file
sources in another config file.  It's main use is when the I<Read Options>
and/or I<Date Format Options> required to parse each config file change between
files.  It's automatically called right before the sourced in file is opened up
for parsing.

Once the new file is sourced in, it inherits most of the options currently used
unless you override them.  The only ones not inherited deal with decryption.

Here is the callback function's expected definition:

  my ($rOpts, $dOpts) = source_callback_func ($file[, $cbOpts]);

  $file --> The file being sourced in.

  $cbOpts --> A hash reference containing values needed by your callback
              function to decide what options are required to source in the
              requested file.  You may update the contents of this hash to
              perserve info between calls.  This module will "never" examine
              the contents of this hash!

  $rOpts --> A reference to the "Read Options" hash used to parse the file
             you want to source in.  Returns "undef" if the options don't
             change.  The returned options override what's currently in use by
             "load_config" when loading the current file.

  $dOpts --> A reference to the "Date Formatting Options" hash used to tell how
             to format the special date variables.  Returns "undef" if the
             options don't change.  The returned options override what's
             currently in use by "load_config" when loading the current file.

=back

=head2 Parse Read Options

These options deal with how to parse the config file itself.  All values are
literal values.  No regular expressions are supported.  If you don't want to
allow a particular option to be supported in your config file, and there is
no disable option, feel free to set it to some unlikely long string of
characters that will never match anything in your config files.  Such as
"#"x100.  (A string of 100 #'s.)

=over 4

B<assign> - Defaults to B<=>.  You may use this option to override what string
of characters make up the assignemnt operator.  It's used to split a line
into a tag/value pair.  If you want the special case of no separator, IE the
first space separates a tag/value pair, try setting it to B<\\s> since the
interface doesn't allow whitespace as a value.

B<comment> - Defaults to B<#>.  This is the comment symbol used when parsing
your config file and everything after it is ignored in most cases.  The first
case is when it appears between balanced quotes as part of a tag's value, it's
not considered the start of a comment.  The other case is when you put one
of the labels in the comments to override default behavior.  (See next section)

B<source> - Defaults to "B<.>".  When followed by a file name, this is an
instruction to source in another config file (similar to how it works in a
I<Unix> shell script.)  Another common setting for this option is "include".

B<section_left> & B<section_right> - This pair is used to anchor breaking
your config file into multiple independant sections.  The defaults are B<[>
and B<]>.

B<variable_left> & B<variable_right> - This pair is used to anchor a variable
definition.  Any value between these anchors will be a variable name and it's
value will be used instead, unless you've disabled this expansion.  The defaults
are B<${> and B<}>.  If you override these anchors to both have the same value,
then the optional variable modifiers are not supported nor are nested variables.

B<quote_left> & B<quote_right> - This pair is used to define what balanced
quotes look like in your config file.  By default, it allows you to use either
B<"> or B<'> as a matching pair.  But if you override one of them you must
override both.  And in that case it can only be with literal values.  If the
quotes surrounding a tag's value are balanced, the quotes will be automatically
removed from the value.  If they are unbalanced the quotes will not be removed.

=cut

# B<backquote_left> & B<backquote_right> - This pair is used to surround a command
# you wish to run, just like in Perl itself.  What the command writes to STDOUT
# becomes the tag's value.  Assumes the command takes nothing from STDIN.  Due to
# security concerns you must explicitly set these values yourself before they are
# usable.  A good value is the backqoute itself (B<`>).  But use something else
# if you don't want to be so obvious about it.

=pod

=back

=head2 Modifiers in the trailing Comments for tag/value pairs.

In some cases we need to handle exceptions to the rule.  So we define labels
to tell this module that we need to apply special rules to this tag/value pair.
These labels may appear anywhere in the comment.  So when looking for "EXPORT",
it will match "B<# Please EXPORT me.>", but won't match "B<# EXPORTED>".  This
allows you to put multiple labels in a single comment if needed.

As long as the text is surrounded by white space or punctuation a match will
be found.  It is strongly recomended that you don't use punctuation in your
label when you override one with values of your own.

Here are the labels you may override.

=over 4

B<export_lbl> - Defaults to "B<EXPORT>".  Tells this module to export this
particular tag/value pair to perl's B<%ENV> hash.  If the I<export> option
was also set, it inverts the meaning of this label to mean don't export it!
You can also gain the same functionality by doing one of the following
instead:

    export tag = value    # Optional unix type shell script prefix.

    set tag = value       # Optional windows type batch file prefix.

These prefixes allow you to easily use shell/batch files as config files if
they contain no logic.

B<hide_lbl> - Defaults to "B<HIDE>".  Tells this module that this tag's value
contains sensitive information.  So when fish logging is turned on, this module
will never write it to these logs.  If the parser thinks a tag's name suggests
it's a password, it will assume that you put this label in the comment.  This
is what triggers the sensitive/mask arguments and return values that some
methods use.

B<encrypt_lbl> - Defaults to "B<ENCRYPT>".  Tells this module that you are
waiting for this tag's value to be encrypted in the config file.  It assumes
the value is still in clear text.  When present it assumes the value is
sensitive as well.

B<decrypt_lbl> - Defaults to "B<DECRYPT>".  Tells this module that this value
has already been encrypted and needs to be decrypted before it is used.  When
present it assumes that the value is sensitive as well.

B<source_file_section_lbl> - Defaults to "B<DEFAULT>".  Tells this module to
use the current section as the default/unlabeled section in the file being
source in.  This new value will be inherited should the sourced in file source
in any further files.

=back

=head2 Encryption/Decryption options.  (or Encode/Decode options.)

The following options deal with the encryption/decryption of the contents of a
config file.  Only the encryption of a tag's value is supported.  And this is
triggered by the appropriate label in the comment on the same line after the
value.

Unless you use the B<encrypt_cb> option, this module isn't using true
encryption.  It's more a complex obscuring of the tag's value making it very
difficult to retrieve a tag's value without using this module to examine the
config file's contents.  It's main use is to prevent casual browsers of your
file system from being able to examine your config files using their favorite
editor to capture sensitive data from your config files.

By default, the I<basename> of the config file's name and the tag's name are the
keys used to encode each value in the config file.  This means that each tag's
value in the config file uses a different key to obscure it.  But by using just
the defaults, anyone using this module may automatically decode everything in
the config file just by writing a perl program that uses this module.

But by using the options below, you gain additional security even without using
true encryption.  Since if you don't know the options used, you can't easily
decode each tag's value even by examining the code.  Just be aware that using
too many keys with too similar values could cancel each other out and weeken
the results.

These options are ignored if you've disabled decryption.

When you source in another file in your config files, the currrent values
for B<alias>, B<pass_phrase> and B<encrypt_by_user> are not inherited.  But the
remaining options are.  See option B<source_cb> if you need to set them in this
caes.

=over 4

B<alias> - Defaults to the empty string.  (Meaning no alias provided.)  This
option is used to override using the file's I<basename> as one of the
encrytion/decryption keys with the I<basename> of the value you provide here.

If you encrypt a file with no I<alias>, and then rename the config file, you
must set the I<alias> to the original filename to be able to decrypt anything.
If you encrypt a file with an I<alias>, you must use the same I<alias> to
decrypt things again.

If your config file is a symbolic link to another name, it will auto set this
option for you using the file's real name as the alias if you don't override
it by setting the alias yourself.

B<pass_phrase> - Defaults to the empty string.  If you used a pass phrase to
encrypt the value, then you need to use the same pass phrase again when
decrypting each tag's value.

B<inherit_pass_phrase> - Defaults to 0 (no).  Set to 1 if you want to use the
same B<pass_pharase> when you source in a sub-file in your config files.

B<encrypt_by_user> - Defaults to 0 (no).  Set to 1 if you want use the user
name you are running the program under as part of the encryption key.  So only
the user who encryted the file can decrypt it.

B<encrypt_cb_opts> - A work area for holding values between calls to the
callback function.  This is expected to be a hash reference to provide any
values needed by your encryption efforts.  So you can avoid global variables
and having to figure out the correct context of the call.  Defaults to an empty
hash reference.

B<encrypt_cb> - An optional callback function to provide hooks for B<true
encryption> or an additional layer of masking.  It defaults to no callback
function used.  This callback function is called in addition to any obscuring
work done by this module.

Here is the callback function's expected definition:

  my $new_value = encrypt_callback_func ($mode, $tag, $value, $file[, $cbOpts]);

     $mode  ==> 1 - Encrypt this value, 0 - Decrypt this value.

     $tag   ==> The name of the tag whose value is being encrypted/decrypted.

     $value ==> The value to encrypt/decrypt.

     $file  ==> The basename of the file the tag/value pair came from.  If the
                "alias" option was used, the basename of that "alias" is
                passed as "$file" instead.

     $cbOpts ==> A hash reference containing values needed by your function to
                 do it's custom encrypt/decrypt duties.  You may update the
                 contents of this hash to perserve info between calls.  This
                 module will "never" examine the contents of this hash!

=back

=head1 ==================================================================

=head2 Z<>

=head1 The Get Options

This section deals with the options you can use to override how the I<B<get>>
methods behave when you try to access the values for individual tags.  None
of the options below allows leading or trailing spaces in it's value.  If any
are found, they will be automatically trimmed off before their value is used.
Internal spaces are OK.

These options can be set as global defaults via the call to the constructor,
B<new()>, or for individual B<get_...> calls if you don't like the defaults
for individual calls.

But it is strongly recomended that the B<inherit> option only be set in the
constructor and not changed elsewhere.  Changing it's value beween calls can
cause strange behavior if you do so.  Since it globally affects how this
module locates the requested tag and affects variable lookups when the
config file is parsed.

After that, where to set the other options is more a personal choice than
anything else.

=over 4

B<inherit> - Defaults to B<0> where each section is independent, the tag either
exists or it doesn't in the section.  Set to B<1> if each section should be
considered an override for what's in the main section.  IE if tag "abc" doesn't
exist in the current section, it next looks in the main section for it.

B<required> - This controls what happens when the requested tag doesn't exist
in your I<Advanced::Config> object.  Set to B<0> to return B<undef> (default),
B<-1> to return B<undef> and write a warning to your screen, B<1> to call
die and terminate your program.

B<vcase> - Controls what case to force all values to.  Defaults to B<0> which
says to preserve the case as entered in the config file.  Use B<1> to convert
everything to upper case.  Use B<-1> to convert everything to lower case.

B<split_pattern> - Defaults to B<qr /\s+/>.  The pattern to use when splitting
a tag's value into an array via perl's C<split> function.  It can be a string
or a regular expression.  For example to split on a comma separated string
you could do:  B<qr /\s*,\s*/>.

B<date_language> - Defaults to I<English>.  Tells what language I<get_date()>
should use when converting the date into a standard format.  Can be almost any
language supported by I<Date::Language>.

B<date_language_warn> - Defaults to B<0> (no). Should I<Advanced::Config::Date>
methods print out warnings?

B<date_enable_yy> - Defaults to B<0> (no). When parsing dates, should we
enable recognizing two digit years as valid?

B<date_format> - Numeric dates are inherently ambiguous so hints are required
in order to eliminate ambiguities.  For example is 01/02/03 I<Jan 2, 2003> (USA)
or I<Feb 1, 2003> (European) or even I<Feb 3, 2001> (ISO).  To a lesser extent
this is also true when you use 4-digit years.  So this option was added for
you to provide parsing hints on the order to try out.

      0 - ISO only
      1 - USA only
      2 - European only
      3 - ISO, USA, European  (default)
      4 - ISO, European, USA
      5 - USA, European, ISO
      6 - USA, ISO, European
      7 - European, USA, ISO
      8 - European, ISO, USA
If you provide an invalid choice, it will assume the default format.

B<date_dl_conversion> - Defaults to B<0> (no).  When parsing dates, should we
be using L<Date::Language>, if it's installed, for additional parsing of dates
if nothing else works?

There are many other I<Get Options> not exposed in the POD.  They are only set
via the specialized B<get_...> functions.  So they are not documented here.

=back

=head1 ==================================================================

=head2 Z<>

=head1 The Special Date Variable Formatting Options

This module allows for special predefined date related variables for use in your
config files.  These options deal with how to format these dates when these
variables are referenced.  These formatting rules apply to all of the special
date variables.

=over 4

B<date_order> - Used to define the ordering of the parts of the dates.
0 - YMD (ISO), 1 - MDY (American), 2 - DMY (European).  The default is B<0>.

B<date_sep> - The separator to use with the date.  Defaults to "-".

B<month_type> - How to display the month variables.  0 - numeric, 1 -
abbreviate names, 2 - full names.  The default is B<0>.

B<month_language> - What language to use when using month names.  Defaults
to I<English>.

B<use_gmt> - How to calculate the date values.  0 - use localtime, 1 - use
gmtime.  The default is B<0>.

=back

=head1 ==================================================================

=head2 Z<>

=head1 FUNCTIONS

As a reminder, there is no need to directly call any of the following functions.
They are documented mostly for the benifit of the developer who uses them to
implement the internals to L<Advanced::Config>.

Most of them are too specialized to be of much use to you.

=over 4

=cut 

package Advanced::Config::Options;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

$VERSION = "1.12";
@ISA = qw( Exporter );

@EXPORT = qw( get_read_opts  get_get_opts  get_date_opts
              apply_get_rules
              is_assign_spaces
              using_default_quotes
              convert_to_regexp_string
              convert_to_regexp_modifier
              should_we_hide_sensitive_data
              make_it_sensitive
              sensitive_cnt
              croak_helper
              set_special_date_vars
              change_special_date_vars
            );

@EXPORT_OK = qw( );

use Advanced::Config::Date;
use Fred::Fish::DBUG 2.09 qw / on_if_set  ADVANCED_CONFIG_FISH /;

# The name of the default section ... (even if no sections are defined!)
use constant DEFAULT_SECTION_NAME => "main";    # Must be in lower case!

my %default_read_opts;
my %default_get_opts;
my %default_date_opts;
my @hide_from_fish;


# ==============================================================
# Get who you're currrently logged in as.
# Put here to avoid circular references between modules.
sub _get_user_id
{
   DBUG_ENTER_FUNC ( @_ );
   my $user = "??";
   eval {
      # Mostly used on unix like systms.
      $user = getpwuid ($<) || "??";
   };
   if ( $@ ) {
      # Can't use on unix due to sudo issue returns wrong user.
      $user = getlogin () || "??";
   }
   DBUG_RETURN ($user);
}

# ==============================================================
# A stub of the source callback function ...
sub _source_callback_stub
{
   DBUG_ENTER_FUNC ( @_ );
   my $file = shift;
   my $opts = shift;
   DBUG_RETURN ( undef, undef );
}


# ==============================================================
# A stub of the encryption/decryption callback function ...
sub _encryption_callback_stub
{
   DBUG_MASK_NEXT_FUNC_CALL (2);   # Mask $value!
   DBUG_ENTER_FUNC ( @_ );
   my $mode   = shift;
   my $tag    = shift;
   my $value  = shift;   # Clear text sensitive value ...
   my $file   = shift;
   my $cbOpts = shift;
   DBUG_MASK ( 0 );
   DBUG_RETURN ( $value );
}


# ==============================================================
# Initialize the global hashes with their default values ...
BEGIN
{
   DBUG_ENTER_FUNC ();

   # ---------------------------------------------------------------------
   # Make sure no hash value is undef !!!
   # ---------------------------------------------------------------------

   # You can only add to this list, you can't remove anything from it!
   # See should_we_hide_sensitive_data () on how this list is used.
   DBUG_PRINT ("INFO", "Initializing the tag patterns to hide from fish ...");
   push ( @hide_from_fish, "password" );
   push ( @hide_from_fish, "pass" );
   push ( @hide_from_fish, "pwd" );

   # ---------------------------------------------------------------------

   DBUG_PRINT ("INFO", "Initializing the READ options global hash ...");
   # Should always be set in the constructor ...
   $default_read_opts{tag_case}   = 0;         # Case sensitive tags.

   # The generic options ...
   my %src_empty;
   $default_read_opts{croak}      = 0;         # Don't croak by default.
   $default_read_opts{export}     = 0;         # Don't export any tag/val pairs.
   $default_read_opts{use_utf8}   = 0;         # Doesn't support utf8/Unicode/Wide Chars.
   $default_read_opts{disable_quotes}     = 0; # Don't disable balanced quotes.
   $default_read_opts{disable_variables}  = 0; # Don't disable variables!
   $default_read_opts{disable_variable_modifiers} = 0; # Don't disable variable modifiers!
   $default_read_opts{disable_decryption} = 0; # Don't disable decryption!
 # $default_read_opts{enable_backquotes}  = 0; # Don't allow random command execution.
   $default_read_opts{trap_recursion}     = 0; # Recursion is ignored, not fatal
   $default_read_opts{source_cb}  = __PACKAGE__->can ("_source_callback_stub");
   $default_read_opts{source_cb_opts} = \%src_empty;

   # The file parsing options ...
   $default_read_opts{assign}          = '=';   # The assignment operator
   $default_read_opts{comment}         = '#';   # The comment symbol
   $default_read_opts{source}          = '.';   # The file source symbol
   $default_read_opts{section_left}    = '[';   # The start section string
   $default_read_opts{section_right}   = ']';   # The end section string
   $default_read_opts{variable_left}   = '${';  # The start variable string
   $default_read_opts{variable_right}  = '}';   # The end variable string

   # Unlikely default values due to security concerns.
   # $default_read_opts{backquote_left}  = '`'x101;  # The start backquote string
   # $default_read_opts{backquote_right} = '`'x102;  # The end backquote string

   # The quote chars ... (Special case doesn't work for anything else.)
   # See  using_default_quotes()  if this changes ...
   $default_read_opts{quote_left} = $default_read_opts{quote_right} = "['\"]";

   # The tag/value modifiers.  These labels are found inside the comments!
   $default_read_opts{export_lbl}  = "EXPORT";    # Label for a single %ENV.
   $default_read_opts{hide_lbl}    = "HIDE";      # Mark as sensitive.
   $default_read_opts{encrypt_lbl} = "ENCRYPT";   # Pending encryption.
   $default_read_opts{decrypt_lbl} = "DECRYPT";   # Already encrypted.
   $default_read_opts{source_file_section_lbl} = "DEFAULT";  # Override default.

   # The Encrypt/Decrypt options ... (Encode/Decode)
   my %empty_encrypt;
   $default_read_opts{alias}               = "";
   $default_read_opts{pass_phrase}         = "";
   $default_read_opts{inherit_pass_phrase} = 0;
   $default_read_opts{encrypt_by_user}     = 0;
   $default_read_opts{encrypt_cb}      = __PACKAGE__->can ("_encryption_callback_stub");
   $default_read_opts{encrypt_cb_opts} = \%empty_encrypt;

   # Special undocumented test prog option for overriding fish in parse_line().
   $default_read_opts{dbug_test_use_case_parse_override} = 0;  # Always off.

   # Special undocumented test prog option for overriding fish in read_config().
   $default_read_opts{dbug_test_use_case_hide_override} = 0;   # Always off.


   # ---------------------------------------------------------------------

   DBUG_PRINT ("INFO", "Initializing the GET options global hash ...");
   # Should always be set in the constructor ...
   $default_get_opts{inherit} = 0;        # Can inherit from the parent section.

   # The generic options ... Who cares where set!
   $default_get_opts{required}  = 0;         # Return undef by default.
   $default_get_opts{vcase}     = 0;         # Case of the value. (0 = as is)
   $default_get_opts{split_pattern} = qr /\s+/;  # Space separated lists.

   # Used in parsing dates for get_date() ...
   $default_get_opts{date_language}      = "English"; # The language to use in parsing dates.
   $default_get_opts{date_language_warn} = 0;         # Disable warnings in Date.pm.
   $default_get_opts{date_dl_conversion} = 0;         # 1-Enable 0-Disable using Date::Language for parsing.
   $default_get_opts{date_enable_yy}     = 0;         # 1-Enable 0-Disable using 2 digit years in a date!
   $default_get_opts{date_format}        = 3;         # Hints are 0 to 8.

   # These special case options not to show up in the POD ...
   # All associated with special "get_*()" functions that will auto set if needed.
   $default_get_opts{numeric}     = 0;       # 0-no, 1-integer (truncate), 2-integer (round), 3-real.
   $default_get_opts{auto_true}   = 0;       # Don't return as boolean.
   $default_get_opts{filename}    = 0;       # Tag doesn't do a file test.
   $default_get_opts{directory}   = 0;       # Tag doesn't do a directory test.
   $default_get_opts{split}       = 0;       # Don't split the value.
   $default_get_opts{sort}        = 0;       # Don't sort the split value. (1 - sort, -1 - reverse sort)
   $default_get_opts{date_active} = 0;       # 0-No, 1-Yes expecing it to be a date.


   # ---------------------------------------------------------------------

   DBUG_PRINT ("INFO", "Initializing the DATE formatting options global hash ...");
   $default_date_opts{date_order}     = 0;          # 0 - YMD, 1 - MDY, 2 - DMY
   $default_date_opts{date_sep}       = "-";        # Separator to format dates with.
   $default_date_opts{month_type}     = 0;          # 0 - numeric, 1 - abbreviate, 2 - full.
   $default_date_opts{month_language} = "English";  # See Date::Language.
   $default_date_opts{use_gmt}        = 0;          # 0 - localtime, 1 - gmtime.
   # $default_date_opts{timestamp}    = ?;          # Special case can't set directly.

   # ---------------------------------------------------------------------


   DBUG_VOID_RETURN ();
}

# ==============================================================
# A private helper method ... (not exported)
sub _get_opt_base
{
   DBUG_ENTER_FUNC ( @_ );
   my $user_opts = shift;
   my $defaults  = shift;    # Which default hash to validate against ...

   # Make own copy of the defaults hash ...
   my %result = %{$defaults};

   # Must warn about invalid key values ...
   foreach ( sort keys %{$user_opts} ) {
      my $k = lc ($_);
      my $val = $user_opts->{$_};

      unless ( exists $defaults->{$k} ) {
         warn "Unknown option '$k'.  Option ignored.\n";
         next;
      }

      # -------------------------------------
      # Trim it to make sure it's valid ...
      # -------------------------------------
      my $no_spaces_allowed = 1;
      if ( defined $val ) {
         if ( $k eq "date_sep" ) {
            $no_spaces_allowed = 0;
         } else {
            $val =~ s/^\s+//;
            $val =~ s/\s+$//;
         }

      } else {
         if ( defined $defaults->{$k} ) {
            warn "Option '$k' has no defined value.  Override ignored.\n";
         } else {
            $result{$k} = undef;
         }
         next;
      }

      # Making sure never undef for easier comparisons later on ...
      my $expect = ( defined $defaults->{$k} ) ? $defaults->{$k} : "";

      # -------------------------------------
      # Is this a call back reference ...
      # -------------------------------------
      if ( ref ( $expect ) eq "CODE" ) {
         my $call;
         if ( ref ($val) eq "CODE" ) {
            $call = $val;
         } elsif ( ref ($val) eq "") {
            if ( $val =~ m/^(.*)::([^:]+)$/ ) {
               my ($pkg, $func) = ($1, $2);
               $call = $pkg->can ($func);
            } elsif ( $val ne "" ) {
               $call = "main"->can ($val);
            }
         }

         if ( $call ) {
            $result{$k} = $call;
         } else {
            warn "Option '$k' must be a callback function.  Can't reference '$val'.  Override ignored.\n";
         }
         next;
      }

      # -------------------------------------
      # Is this a regular expression?
      # Used in calls to split ...
      # -------------------------------------
      if ( ref ( $expect ) eq "Regexp" ) {
         if ( ref ( $val ) eq "Regexp" ) {
            $result{$k} = $val;
         } elsif ( ref ( $val ) eq "" && $val ) {
            $result{$k} = $val;
         } else {
            warn "Option '$k' must be a Regexp or a string, not '$val'.  Override ignored.\n";
         }
      }

      # -------------------------------------
      # Setting up a work area hash ...
      # -------------------------------------
      if ( ref ( $expect ) eq "HASH" ) {
         if ( ref ( $val ) eq "HASH" ) {
            $result{$k} = $val;
         } else {
            warn "Option '$k' must be a hash reference, not '$val'.  Override ignored.\n";
         }
         next;
      }

      # -------------------------------------
      if ( $val eq "" && $expect ne "" && $no_spaces_allowed ) {
         warn "Option '$k' can't be set to the empty string.  Override ignored.\n";
         next;
      }

      # -------------------------------------
      if ( $expect =~ m/^-?\d+$/ && $val !~ m/^-?\d+$/ ) {
         warn "Option '$k' must be numeric ($val).  Override ignored.\n";
         next;
      }

      # -------------------------------------
      if ( $expect !~ m/^-?\d+$/ && $val =~ m/^-?\d+$/ ) {
         warn "Option '$k' may not be numeric ($val).  Override ignored.\n";
         next;
      }

      $result{$k} = $val;
   }

   DBUG_RETURN ( \%result );
}

# ==============================================================

=item $ropts = get_read_opts ( [\%user_opts[, \%current_opts]] )

This method takes the I<user's> options that override the behaviour for reading
in your config file by this module and merges it into the I<current> options.
If no I<current> options hash reference is given, it will use the module's
defaults instead.

It returns a hash reference of all applicable "Read" options.

=cut

# ==============================================================
sub get_read_opts
{
   DBUG_ENTER_FUNC ( @_ );
   my $user_opts = shift;
   my $current   = shift;

   # Get the default values ...
   my %def = %default_read_opts;
   my $ref = \%def;

   $ref = _get_opt_base ( $current, $ref )    if ( defined $current );
   $ref = _get_opt_base ( $user_opts, $ref )  if ( defined $user_opts );

   # Some additional validation ...
   if ( $ref->{encrypt_lbl} eq $ref->{decrypt_lbl} ) {
      my $val = $ref->{encrypt_lbl};
      $ref->{encrypt_lbl} = $default_read_opts{encrypt_lbl};
      $ref->{decrypt_lbl} = $default_read_opts{decrypt_lbl};
      warn ("Options 'encrypt_lbl' and 'decrypt_lbl' may not be set to the same value ($val).\n",
            "Resetting both to their default settings!\n");
   }

   DBUG_RETURN ( $ref );
}

# ==============================================================

=item $gopts = get_get_opts ( [\%user_opts[, \%current_opts]] )

This method takes the I<user's> options that override the behaviour of I<get>
methods for this module and merges it into the I<current> options.  If no
I<current> options hash reference is given, it will use the module's defaults
instead.

It returns a hash reference of all applicable "Get" options.

=cut

# ==============================================================
sub get_get_opts
{
   DBUG_ENTER_FUNC ( @_ );
   my $user_opts = shift;
   my $current   = shift;

   # Get the default values ...
   my %def = %default_get_opts;
   my $ref = \%def;

   $ref = _get_opt_base ( $current, $ref )    if ( defined $current );
   $ref = _get_opt_base ( $user_opts, $ref )  if ( defined $user_opts );

   # Some additional validation ...
   unless ( 0 <= $ref->{date_format} && $ref->{date_format} <= 8 ) {
      my $val = $ref->{date_format};
      $ref->{date_format} = $default_read_opts{date_format};
      warn ("Option 'date_format' is invalid ($val).  Resetting to it's default!\n");
   }

   DBUG_RETURN ( $ref );
}

# ==============================================================

=item $dopts = get_date_opts ( [\%user_opts[, \%current_opts]] )

This method takes the I<user's> options that override the behaviour of I<date>
foramtting for this module and merges it into the I<current> options.  If no
I<current> options hash reference is given, it will use the module's defaults
instead.

It returns a hash reference of all applicable "Date" formatting options.

=cut

# ==============================================================
sub get_date_opts
{
   DBUG_ENTER_FUNC ( @_ );
   my $user_opts = shift;
   my $current   = shift;

   # Get the default values ...
   my %def = %default_date_opts;
   my $ref = \%def;

   $ref = _get_opt_base ( $current, $ref )    if ( defined $current );
   $ref = _get_opt_base ( $user_opts, $ref )  if ( defined $user_opts );

   DBUG_RETURN ( $ref );
}

# ==============================================================

=item $ref = apply_get_rules ( $tag, $section, $val1, $val2, $wide, $getOpts )

Returns an updated hash reference containing the requested data value after all
the I<$getOpts> rules have been applied.  If the I<$tag> doesn't exist then it
will return B<undef> instead or B<die> if it's I<required>.

I<$val1> is the DATA hash value from the specified section.

I<$val2> is the DATA hash value from the parent section.  This value is ignored
unless the I<inherit> option was specified via I<$getOpts>.

I<$wide> tells if UTF-8 dates are allowed.

=cut

# ==============================================================
sub apply_get_rules
{
   DBUG_ENTER_FUNC (@_);
   my $tag      = shift;     # The tag we are processing ...
   my $section  = shift;     # The name of the current section ...
   my $value1   = shift;     # The value hash from the current section ...
   my $value2   = shift;     # The value hash from the "main" section ...
   my $wide_flg = shift;     # Tells if langages like Greek are allowed ...
   my $get_opts = shift;     # The current "Get" options hash ...

   # Did we find a value to process?
   my $data = $value1;
   if ( $get_opts->{inherit} && (! defined $data) ) {
      $data = $value2;
   }
   unless ( defined $data ) {
      return DBUG_RETURN ( croak_helper ( $get_opts,
                                  "No such tag ($tag) in section ($section).",
                                  undef ) );
   }

   # Make a local copy to work with, we don't want to modify the source.
   # We're only interested in two entries from the hash:  VALUE & MASK_IN_FISH.
   # All others are ignored by this method.
   my %result = %{$data};

   # Do we split up the value?    ( Took 2 options to implement the split. )
   my @vals;
   unless ( $get_opts->{split} ) {
      push (@vals, $result{VALUE});    # Nope!

   } else {
      @vals = split ( $get_opts->{split_pattern}, $result{VALUE} );
      $result{VALUE} = \@vals;
   }

   # Only if sorting, assume everything in the list is numeric ...
   my $is_all_numbers = $get_opts->{sort} ? 1 : 0;

   # Do any validation that needs to be done against the individual parts ...
   foreach my $v ( @vals ) {
      my $old = $v;   # Save in case someone modifies $v!

      # -------------------------------------------------------------------
      # Do we need to convert to upper or lower case?
      if ( $get_opts->{vcase} > 0 ) {
         $v = uc ( $v );
      } elsif ( $get_opts->{vcase} < 0 ) {
         $v = lc ( $v );
      }

      # -------------------------------------------------------------------
      # Convert into a boolean value ??? (you never see the original value)
      if ( $get_opts->{auto_true} ) {
         $result{MASK_IN_FISH} = 0;    # Boolean values are never sensitive!

         my $numeric = 0;
         if ( $old =~ m/^[-+]?\d+([.]\d*)?$/ ||
              $old =~ m/^[-+]?[.]\d+$/ ) {
            $numeric = 1;
            $old += 0;       # Convert string to a number ...
         }

         $v = 0;           # Assume FALSE ...
         unless ( $old ) {
            ;
         } elsif ( $numeric ) {
            $v = 1;        # It's TRUE for a non-zero numeric value ...
         } elsif ( $old =~ m/(^true[.!;]?$)|(^yes[.!;]?$)|(^good[.!;]?$)|(^[TYG]$)|(^on[.!;]?$)/i ) {
            $v = 1;        # It's TRUE for certain text strings ...
         }
      }

      # -------------------------------------------------------------------
      # Are we requiring it to be a numeric value?
      # Also run if we want to test if something is numeric for the later sort!
      # 0 - Skip test.
      # 1 - integer (round).
      # 2 - integer (truncate).
      # 3 - real.
      if ( $get_opts->{numeric} || $is_all_numbers ) {
         my $fp = 0;
         my $err;
         my $run_flg = ($get_opts->{numeric} != 0);

         if ( $v =~ m/^[+-]?\d+([.]\d*)?[Ee][+-]?\d+$/ ||
              $v =~ m/^[+-]?[.]\d+[Ee][+-]?\d$/ ) {
            $fp = 1;           # In Scientific Notiation ...
            if ( $run_flg ) {
               $v += 0;        # Converts out of Scientific Notiation if possible!
            }
         } elsif ( $v =~ m/^[+-]?\d+$/ ) {
            $fp = 0;           # It was an integer ...
         } elsif ( $v =~ m/^[+-]?\d+[.]\d*$/  ||
                   $v =~ m/^[+-]?[.]\d+$/ ) {
            $fp = 1;           # A floating point numeric value ...
            $v += 0   if ( $run_flg );
         } else {
            $err = 1;          # Not a valid number!
            $is_all_numbers = 0;
         }

         # If really a floating point number & asking for an integer ...
         if ( $run_flg && $fp && $get_opts->{numeric} != 3 ) {
            if ( $get_opts->{numeric} == 1 ) {
               $v = sprintf ("%.0f", $v);     # Round it up ...
            } else {
               $v = sprintf ("%d", $v);       # Truncate it ...
            }
         }

         if ( $err && $run_flg ) {
            return DBUG_RETURN ( croak_helper ( $get_opts,
                   "Value is not numeric ($v) for tag ($tag) in section ($section).",
                   undef ) );
         }
      }

      # -------------------------------------------------------------------
      # Are we expecting to find a date someplace inside this string?
      if ( $get_opts->{date_active} ) {
          my @order = ( "1", "2", "3", "1,2,3", "1,3,2", "2,3,1", "2,1,3", "3,2,1", "3,1,2" );
          my $l = swap_language ( $get_opts->{date_language},
                                  $get_opts->{date_language_warn},
                                  $wide_flg );
          my $date = parse_date ( $v, $order[$get_opts->{date_format}],
                                  $get_opts->{date_dl_conversion},
                                  $get_opts->{date_enable_yy} );
          if ( $date ) {
             $v = $date;
          } else {
             my $l2 = $get_opts->{date_language} || $l;
             return DBUG_RETURN ( croak_helper ( $get_opts,
                    "Value is not a date ($v) for tag ($tag) in section ($section) for language ($l2).",
                    undef ) );
          }
      }

      # -------------------------------------------------------------------
      # Are we referencing a file?
      if ( $get_opts->{filename} ) {
         my $valid = 1;   # Assume it's a filename ...
         $valid = 0  unless ( -f $v );
         $valid = 0  if ( ($get_opts->{filename} & 2) && ! -r _ );
         $valid = 0  if ( ($get_opts->{filename} & 4) && ! -w _ );
         $valid = 0  if ( ($get_opts->{filename} & 8) && ! -x _ );
         unless ( $valid ) {
            return DBUG_RETURN ( croak_helper ( $get_opts,
                   "Tag ${tag} doesn't reference a valid filename or it doesn't have the requested permissions! ($v)",
                   undef ) );
         }
      }

      # -------------------------------------------------------------------
      # Are we referencing a directory?
      if ( $get_opts->{directory} ) {
         my $valid = 1;   # Assume it's a directory ...
         $valid = 0  unless ( -d $v );
         $valid = 0  if ( ($get_opts->{directory} & 2) && ! -r _ );
         $valid = 0  if ( ($get_opts->{directory} & 4) && ! -w _ );
         $valid = 0  if ( ($get_opts->{directory} & 8) && ! -x _ );
         unless ( $valid ) {
            return DBUG_RETURN ( croak_helper ( $get_opts,
                   "Tag ${tag} doesn't reference a valid directory or it doesn't have the requested permissions! ($v)",
                   undef ) );
         }
      }

      # -------------------------------------------------------------------
      # If not splitting after all, save any changes ... (keep last in loop)
      if ( (! $get_opts->{split}) && $old ne $v ) {
         $result{VALUE} = $v;
      }
   }    # End foreach @vals loop ...


   # Do we need to sort the results ???
   if ( $get_opts->{split} && $get_opts->{sort} ) {
      if ( $is_all_numbers ) {
         @{$result{VALUE}} = sort { $a <=> $b } @{$result{VALUE}};
      } else {
         @{$result{VALUE}} = sort ( @{$result{VALUE}} );
      }
      @{$result{VALUE}} = reverse ( @{$result{VALUE}} )  if ( $get_opts->{sort} < 0 );
   }

   DBUG_RETURN ( \%result );
}

# ==============================================================

=item $boolean = is_assign_spaces ( $ropts )

Tells if the assignment operator selected is the special case of using spaces
to separate the tag/value pair.  Only returns true if it's B<\\s>.

=cut

# No fish since it's called so frequently, over & over again ...
sub is_assign_spaces
{
   # Checking the ${rOpts} settings ...
   return ( exists $_[0]->{assign} && $_[0]->{assign} eq "\\s" );
}

# ==============================================================

=item $boolean = using_default_quotes ( $ropts )

This function tells if you are currently using the default quotes.  This is the
only case where there can be multiple values for the quote string anchors.  All
other cases allow only for a single value for each of the quote string anchors.

=cut

sub using_default_quotes
{
   DBUG_ENTER_FUNC ( @_ );
   my $ropts = shift;

   my $def = 0;     # Assume not using the default quotes ...

   unless ( $ropts->{disable_quotes} ) {
      if ( $ropts->{quote_left} eq $ropts->{quote_right} ) {
         if ( $ropts->{quote_left} eq  "['\"]"  ||
              $ropts->{quote_left} eq  "[\"']" ) {
            $def = 1;
         }
      }
   }

   DBUG_RETURN ( $def );
}


# ==============================================================

=item $str = convert_to_regexp_string ( $string[, $no_logs] )

Converts the passed string that may contain special chars for a Perl RegExp
into something that is a literal constant value to Perl's RegExp engine by
turning these problem chars into escape sequences.

It then returns the new string.

If I<$no_logs> is set to a non-zero value, it won't write anything to the logs.

=cut

sub convert_to_regexp_string
{
   my $no_fish = $_[1];
   DBUG_ENTER_FUNC ( @_ )  unless ( $no_fish );;
   my $str     = shift;

   # The 8 problem chars with special meaning in a RegExp ...
   # Chars:  . + ^ | $ \ * ?
   $str =~ s/([.+^|\$\\*?])/\\$1/g;  

   # As do these 3 types of brackets: (), {}, []
   $str =~ s/([(){}[\]])/\\$1/g;

   return DBUG_RETURN ( $str )  unless ( $no_fish );
   return ( $str );
}

# ==============================================================

=item $str = convert_to_regexp_modifier ( $string )

Similar to C<convert_to_regexp_string> except that it doesn't convert
all the wild card chars.

Leaves the following RegExp wild card's unescaped!
S<(B<*>, B<?>, B<[>, and B<]>)>

Used when processing variable modifier rules.

=cut

sub convert_to_regexp_modifier
{
   DBUG_ENTER_FUNC ( @_ );
   my $str     = shift;

   # The 6 problem chars with special meaning in a RegExp ...
   # Chars:  . + ^ | $ \    (Skips * ?)
   $str =~ s/([.+^|\$\\])/\\$1/g;  

   # As do these 2 of 3 types of brackets: () & {}, not []
   $str =~ s/([(){}])/\\$1/g;

   DBUG_RETURN ( $str );
}

# ==============================================================

=item $sensitive = should_we_hide_sensitive_data ( $tag )

Checks the tag against an internal list of patterns to see if there is a match.
This check is done in a case insensitive way.

If there is a match it will return true and the caller should take care about
writing anything about this tag to any log files.

If there is no match it will return false, and you can write what you please to
your logs.

See I<make_it_sensitive> to add additional patterns to the list.

=cut

sub should_we_hide_sensitive_data
{
   my $tag       = shift;
   my $skip_fish = shift;     # Undocumented ...

   my $sensitive = 0;    # Assume it's not to be hidden!

   foreach my $hide ( @hide_from_fish ) {
      if ( $tag =~ m/${hide}/i ) {
         $sensitive = 1;   # We found a match!  It's sensitive!
      }
   }

   unless ( $skip_fish ) {
      DBUG_ENTER_FUNC ( $tag, $skip_fish, @_ );
      return DBUG_RETURN ( $sensitive );
   }

   return ( $sensitive );
}

# ==============================================================

=item make_it_sensitive ( @patterns )

Add these pattern(s) to the internal list of patterns that this module considers
sensitive.  Should any tag contain this pattern, that tag's value will be
masked when written to this module's internal logs.  Leading/trailing spaces
will be ignored in the pattern.  Wild cards are not honored.

The 3 default patterns are password, pass, and pwd.

This pattern affects all L<Advanced::Config> objects loaded into memory.  Not
just the current one.

=cut

sub make_it_sensitive
{
   DBUG_ENTER_FUNC ( @_ );
   my @tags = @_;

   foreach my $tag ( @tags ) {
      if ( $tag ) {
         $tag =~ s/^\s+//;
         $tag =~ s/\s+$//;
         if ( $tag ) {
            $tag = convert_to_regexp_string ( $tag, 1 );
            push ( @hide_from_fish, $tag );
         }
      }
   }

   DBUG_VOID_RETURN ();
}

# ==============================================================

=item $cnt = sensitive_cnt ( )

Returns a count of how many sensitive patterns are being used.

=cut

sub sensitive_cnt
{
   DBUG_ENTER_FUNC ( @_ );
   DBUG_RETURN ( scalar (@hide_from_fish) );
}

# ==============================================================

=item @ret = croak_helper ($opts, $croak_message, @croak_return_vals)

This helper method helps standardises what to do on fatal errors when reading
the config file or what to do if you can't find the tag on lookups.

It knows I<\%opts> is a "Read" option hash if B<croak> is a member and it's
a "Get" option hash if B<required> is a member.  Both options use the same
logic when called.

See B<croak> and B<required> on what these options do.

Returns whatever I<@croak_return_vals> references.  It may be a single value or
an array of values.

It calls B<warn> or B<die> with the message passed.

=cut

# ==============================================================
# No ENTER/RETURN fish calls on purpose here ...

sub croak_helper
{
   my $opts  = shift;
   my $msg   = shift;
   my @ret   = @_;      # Use whatever was passed to me ...

   # Look up the needed value in the hash we'd like to test out.
   my $croak = 0;
   if ( exists $opts->{croak} ) {
      $croak = $opts->{croak};       # From the Read Opt Hash ...
   } elsif ( exists $opts->{required} ) {
      $croak = $opts->{required};    # From the Get Opt Hash ...
   }

   if ( $croak > 0 ) {
      die ($msg, "\n");

   # The -9876 value is undocumented where we don't even want the msg in fish!
   } elsif ( $croak == -9876 ) {
      ;

   } elsif ( $croak < 0 ) {
      warn ($msg, "\n");

   } else {
      DBUG_PRINT ("WARN", $msg);
   }

   return ( wantarray ? @ret : $ret[0] );
}

# ==============================================================

=item $lvl = set_special_date_vars ( $date_opts_ref, $date_hash_ref[, $old_hash_ref] )

The I<$date_opts_ref> contains the special date variable formatting options
used to control the formattiong of the data returned via I<$date_hash_ref>.
The relevant tags are: I<date_order>, I<date_sep>, I<month_type>, I<use_gmt>
and I<month_language>.  Any missing hash key and it's default is used.

This function populates the following date keys in I<$date_hash_ref> for use
by the config object using the current date/time.  These keys are also defined
as the date variables available for use by your config files.

The keys set are: (Shown using the default formats)

   today, yesterday, tomorrow -- A formatted date in YYYY-MM-DD format.
   this_month, last_month, next_month -- The Month.
   this_year, last_year, next_year -- A 4 digit year.
   this_period, last_period, next_period -- The YYYY-MM part of a date.
   dow -- The day of the week  (Sunday to Saturday or 1..7).
   doy -- The day of the year (1..365 most years, 1..366 in leap years).
   dom -- The day of the month. (1..31)
   timestamp -- The time used to generate the above variables with. [time()]

The I<$old_hash_ref> contains the values from the previous call to this
function.  If missing, assumes 1st time called.  If provided and the date
options for this call doesn't match what was used to create this hash
the return value is unreliable.

Returns the level of what changed in ${date_hash_ref}:

  0 -- Nothing changed from previous call or it's the 1st time called.
  1 -- Just the day of month changed.
  2 -- The month also changed.
  3 -- The year also changed.

=cut

# ==============================================================

sub set_special_date_vars
{
   DBUG_ENTER_FUNC (@_);
   my $opts   = shift;    # The date formatting options ...
   my $dates  = shift;    # A hash reference of dates to return ...
   my $prev   = shift;    # The previous hash reference to see what changed ...

   my %empty;
   %{$dates} = %empty  if (defined $dates);
   $prev = \%empty  unless (defined $prev);

   my ($t1, $t2, $t3) = ("month_language", "month_type", "");
   my $lang = (exists $opts->{$t1}) ? $opts->{$t1} : $default_date_opts{$t1};
   my $mtyp = (exists $opts->{$t2}) ? $opts->{$t2} : $default_date_opts{$t2};
   my ($month_ref, $week_day_ref) = init_special_date_arrays ($lang, $mtyp, 0, 0);

   # The formatting info ...
   ($t1, $t2, $t3) = ("date_order", "date_sep", "use_gmt");
   my $order = (exists $opts->{$t1}) ? $opts->{$t1} : $default_date_opts{$t1};
   my $sep   = (exists $opts->{$t2}) ? $opts->{$t2} : $default_date_opts{$t2};
   my $gmt   = (exists $opts->{$t3}) ? $opts->{$t3} : $default_date_opts{$t3};

   my $what_changed = 0;    # Nothing ...

   # -------------------------------------------------------------------------
   # Initialize the date to use properly
   # -------------------------------------------------------------------------
   my $now;
   if ( $opts->{timestamp} ) {
      # Only set by change_special_date_vars() ... (So undocumented)
      $now = $opts->{timestamp};    # Re-use a previous timestamp.
   } else {
      $now = time ();               # Start a new timestamp.
   }

   $dates->{timestamp} = $now;

   # -------------------------------------------------------------------------
   # Get the desired dates ...

   # Get today ...
   my ($yr, $mon, $day, $hr, $dow, $doy) = $gmt
                                  ? (gmtime    ($now))[5,4,3,2,6,7]
                                  : (localtime ($now))[5,4,3,2,6,7];
   $yr += 1900;
   my $month = $month_ref->[$mon];
   $dates->{today} = _fmt_date ($sep, $order, $yr, $month, $day);

   # Get yesterday's date ...
   my $sec = ($hr + 2) * 3600 + 2;     # Convert hours to seconds ...
   my ($yr2, $mon2, $day2) = $gmt ? (gmtime    ($now - $sec))[5,4,3]
                                  : (localtime ($now - $sec))[5,4,3];
   $yr2 += 1900;
   my $month2 = $month_ref->[$mon2];
   $dates->{yesterday} =  _fmt_date ($sep, $order, $yr2, $month2, $day2);

   # Get tomorrow's date ...
   $sec = (24 - $hr + 1) * 3600 + 2;   # Convert hours to seconds ...
   my ($yr3, $mon3, $day3) = $gmt ? (gmtime    ($now + $sec))[5,4,3]
                                  : (localtime ($now + $sec))[5,4,3];
   $yr3 += 1900;
   my $month3 = $month_ref->[$mon3];
   $dates->{tomorrow} =  _fmt_date ($sep, $order, $yr3, $month3, $day3);

   DBUG_PRINT ("  DATES ($day)", "LAST: %s,  NOW: %s,  NEXT: %s",
               $dates->{yesterday}, $dates->{today}, $dates->{tomorrow});

   if ( $prev->{today} && $prev->{today} ne $dates->{today} ) {
      $what_changed = 1;    # The date changed ...
   }

   # -------------------------------------------------------------------------
   # Get the desired months ... ($mon == 0..11)
   $dates->{this_month} = $month_ref->[$mon];
   $dates->{last_month} = ( $mon == 0 )  ? $month_ref->[11] : $month_ref->[$mon - 1];
   $dates->{next_month} = ( $mon == 11 ) ? $month_ref->[0]  : $month_ref->[$mon + 1];

   DBUG_PRINT (" MONTHS ($mon)", "LAST: %s,  NOW: %s,  NEXT: %s",
              $dates->{last_month}, $dates->{this_month}, $dates->{next_month});

   # -------------------------------------------------------------------------
   # Get the desired periods Year-Month ... ($mon == 0..11)
   my $lyr = ( $mon == 0 )  ? ($yr - 1) : $yr;
   my $nyr = ( $mon == 11 ) ? ($yr + 1) : $yr;
   $dates->{this_period} = _fmt_period ($sep, $order, $yr,  $dates->{this_month});
   $dates->{last_period} = _fmt_period ($sep, $order, $lyr, $dates->{last_month});
   $dates->{next_period} = _fmt_period ($sep, $order, $nyr, $dates->{next_month});

   DBUG_PRINT ("PERIODS ($mon)", "LAST: %s,  NOW: %s,  NEXT: %s",
              $dates->{last_period}, $dates->{this_period}, $dates->{next_period});

   # -------------------------------------------------------------------------

   if ( $prev->{this_month} && $prev->{this_month} ne $dates->{this_month} ) {
      $what_changed = 2;     # The month & periods changed ...
   }

   # -------------------------------------------------------------------------
   # Get the desired years ...
   $dates->{this_year} = sprintf ("%04d", $yr);
   $dates->{last_year} = sprintf ("%04d", $yr - 1);
   $dates->{next_year} = sprintf ("%04d", $yr + 1);

   DBUG_PRINT ("  YEARS", "LAST: %s,  NOW: %s,  NEXT: %s",
               $dates->{last_year}, $dates->{this_year}, $dates->{next_year});

   if ( $prev->{this_year} && $prev->{this_year} ne $dates->{this_year} ) {
      $what_changed = 3;     # The year changed ...
   }

   # -------------------------------------------------------------------------
   # Get the miscellanious vars ...
   $dates->{dow} = $week_day_ref->[$dow]; # 1..7 or spelled out.
   $dates->{doy} = $doy + 1;              # 1..365 normal, 1..366 in leap years.
   $dates->{dom} = $day;                  # 1..31, range based on month.

   DBUG_PRINT ("   MISC", " DOW: %s,  DOY: %d,  DOM: %d",
               $dates->{dow}, $dates->{doy}, $dates->{dom});

   DBUG_RETURN ($what_changed);
}

# ==============================================================

=item change_special_date_vars ( $timestamp, $date_opts_ref, $date_hash_ref )

Same as L<set_special_date_vars> except it uses the specified date/time to
convert.

=cut

sub change_special_date_vars
{
   DBUG_ENTER_FUNC (@_);
   my $timestamp = shift;
   my $date_opts = shift;
   my $dates     = shift;

   # Special flag for special handling ... (undocumented)
   local $date_opts->{timestamp} = $timestamp;

   # Forces all dates to use the specified date/time
   set_special_date_vars ($date_opts, $dates);

   DBUG_VOID_RETURN ();
}

# ==============================================================
# For formatting the full dates ...

sub _fmt_date
{
   my $sep   = shift;
   my $order = shift;
   my $year  = shift;
   my $month = shift;    # 1..12 or the name.
   my $day   = shift;    # 1..31

   my $dt;
   if ( $order == 1 ) {
      # MM-DD-YYYY format
      $dt = sprintf ("%s%s%02d%s%04d", $month, $sep, $day, $sep, $year);
   } elsif ( $order == 2 ) {
      # DD-MM-YYYY format
      $dt = sprintf ("%02d%s%s%s%04d", $day, $sep, $month, $sep, $year);
   } else {
      # YYYY-MM-DD order ...
      $dt = sprintf ("%04d%s%s%s%02d", $year, $sep, $month, $sep, $day);
   }

   return ($dt);
}

# ==============================================================
# Formatting to be "year-month" or "month-year".

sub _fmt_period
{
   my $sep   = shift;
   my $order = shift;
   my $year  = shift;
   my $month = shift;      # 1..12 or the name.

   my $dt;
   if ( $order == 1 || $order == 2 ) {
      # MM-YYYY format
      $dt = sprintf ("%s%s%04d", $month, $sep, $year);
   } else {
      # YYYY-MM format
      $dt = sprintf ("%04d%s%s", $year, $sep, $month);
   }

   return ($dt);
}

# ==============================================================

=back

=head1 COPYRIGHT

Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Advanced::Config> - The main user of this module.  It defines the Config object.

L<Advanced::Config::Date> - Handles date parsing for get_date().

L<Advanced::Config::Reader> - Handles the parsing of the config file.

L<Advanced::Config::Examples> - Provides some sample config files and commentary.

=cut

# ==============================================================
#required if module is included w/ require command;
1;

