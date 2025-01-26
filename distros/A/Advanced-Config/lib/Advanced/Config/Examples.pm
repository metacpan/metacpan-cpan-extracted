###
###  Copyright (c) 2015 - 2025 Curtis Leach.  All rights reserved.
###
###  Module: Advanced::Config::Examples

package Advanced::Config::Examples;

use strict;
use warnings;

use vars qw ( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Fred::Fish::DBUG 2.09  qw / on_if_set  ADVANCED_CONFIG_FISH /;

$VERSION   = "1.10";
@ISA       = qw ( Exporter );
@EXPORT    = qw ();
@EXPORT_OK = qw ();


# Required if module is included w/ require command;
1;

# =============================================================================
# Only POD text appears below this line!
# =============================================================================

=head1 NAME

Advanced::Config::Examples - Defines sample config files supported by this
module.  Sourcing this module in does nothing for you.

=head1 SYNOPSIS

In many cases it's just easier to show an example instead of trying
to put things into words.  So this module is just some POD text to document
what this module is expecting to load into memory as your config file.

Just be aware that it's possible to override many of the operators defined in
the config file.  So for example the B<=> operator could be B<:=> and the
B<#> operator could have been B<CMT:>.

=head1 HISTORY

This module started out as a parser of unix shell script data files so that
shell scripts and perl programs could share the same config files.  Hence the
support of shell script variables, quotes and the sourcing in of sub-files.
Allowing for limited logic in your config files.

From there it just grew to support non-unix features such as windows batch
files and more generic configuation features.  Such as being able handle various
formating of config files and the ability to obscure or encrypt values from
casual snooping.  Or the addition of sections to allow the same config file to
be used on multiple servers and OS.

So today it's a powerfull tool that turns your config files into objects your
perl code can reference and manipulate.

=head1 SURROUNDING A VALUE WITH QUOTES IN YOUR CONFIG FILE

If you surround a value with balanced quotes, those quotes are automatically
removed before that value is assigned to it's tag.  Quotes are supported mostly
for readability and as a way to allow comment symbols in your value.  Or a way
to force leading and trailing spaces to your value.  Where without quotes those
spaces are stripped off.

=head1 VARIABLE SUBSTITUTIONS

All config files support variable substitution.  A variable can be any B<tag>
that appears above it in the config file.  If not defined there, it will check
if it's defined as an environment variable in the B<%ENV> hash instead.  If
still not found it will check for several predefined special variables for this
module.  If it can't find a variable it's value is always the empty string.

By default variables are in the format of B<${>...B<}>.  Where ... is your
variable's name and the B<${> & B<}> strings are the default surrounding anchors
that define it as a variable.

For more on this see the following link on Parameter Expansion:
L<https://web.archive.org/web/20200309072646/https://wiki.bash-hackers.org/syntax/pe>
This module supports most of the parameter expansions listed in the link except
for those dealing with arrays.  Other modifier rules may be added upon request.

Things get a bit more complex evaluating variables if you've defined sections
in your config file.

See the POD for B<lookup_one_variable>() in L<Advanced::Config> for step by step
instructions on expanding a variable's name.

For a list of special variables try calling:
S<Advanced::Config-E<gt>print_special_vars();>

=head1 SOURCING IN OTHER CONFIG FILES

It's possible to source multiple config files together as if they were one big
config file.  You can either use absolute paths to each config file, or more
likely relative paths.

Sourcing in sub-config files using relative paths works a little different than
you might expect.  It's the relative path from the location of the config file
doing the sourcing, not the current directory your program is running in.

This way the writer of the config file, not the programmer, controls which
config file gets sourced in.  Of course the config file writer can give control
back to the programmer by using variables as part of the name of the config
file being sourced in.

If recursion is detected, this module silently refuses to reload the problem
config file and breaks the recursion.  But you have the option of treating it
as a fatal error instead.  Recursion is detected even if you source in a
symbolic link back to the original file.

It is always a fatal error if the requested config file doesn't exist!

=head1 CONTROLLING THE PARSING OF YOUR CONFIG FILES

See I<The Read Options> section of L<Advanced::Config::Options> for what options
are available for customizing how your configuration files gets parsed.

While I<The Get Options> section covers options for looking up the value for
a given tag generated.

=head1 ENCRYPTING VALUES IN YOUR CONFIG FILE

This module has hooks to allow the encryption/decryption of values in your
config file.  It can do it in two levels.  Simple obscuring of the tag's value
or true encryption/decryption.  See L<Advanced::Config::Options> for more
details on how to do this.

=head1 CONFIG FILE EXAMPLES

=over 4

=item A VERY SIMPLE CONFIG FILE. (simple.cfg)

   # This is a comment

   tag1 = abc       # A simple assignment.

   # The balanced quotes will automatically be removed from the value ...
      tag2="efg"    # See we put surrounding quotes arround the value.

   tag3 = 'l m n'   # The alternate quotes.

   tag4 = p q r     # See quotes are completely optional.

   tag5 = ${tag1}   # Performs variable substitution, same as: tag5 = "abc".

   tag1     =     xyz  # See I've overriden tag1's original value to "xyz".
   TAG1 = 123       # tag1 is still xyz, tags are case sensitive.

To load it into memory do:

   my $cfg = Advanced::config->new ("simple.cfg")->load_config();

=item A SLIGHTLY MORE COMPLEX CONFIG FILE.  (complex.cfg)

   # Merge in this config file.  Looks in the same directory as
   # this config file is in.  Not the program's current directory.
   . simple.cfg

   # Sourcing in another config file.  (contents not shown)
   # Offset is from the same directory this config file is in.
   # Not the program's current directory!
   . ../Alt-Config/relative.cfg

   # See I'm referencing variables defined in simple.cfg!
   tag1 = ${tag1} ${tag3} ${tag1}   # tag1 now equals: "xyz l m n xyz".

   tag 6 = abc = 7     # "tag 6" now contains:  "abc = 7".
   tag 6 = ${TAG1}     # "tag 6" is now:  123

   messy = "I have a # in my value"  # See comment symbol in the value.

   # A neat little trick ...
   # Implements:  a = $ENV{test} ? "TRUE" : "FALSE";
   a = ${test:+TRUE}   # Set to TRUE if $ENV{test} is set, else undef
   a = ${a:-FALSE}     # Set to FALSE if ${a} is undef, else set to ${a}.

   # Does variables within variables ...
   # Implements:  b = $ENV{test} ? $y : $z;
   y = YES
   z = NO
   b = ${test:+${y}}   # Set to ${y} if $ENV{test} is set, else undef
   b = ${b:-${z}}      # Set to ${z} if ${b} is undef, else set to ${b}.

   # So (a,b) = (TRUE,YES) or (FALSE,NO).

   # How about testing for a specific value for $ENV{test}?  This can be
   # done in a limited way.
   message_abc = I know my abc's.
   message_123 = I know my 123's
   message_hello = Hello World!
   msg = ${message_${test}:-Unknown Message.}

   # So if test is "abc", "123" or "hello" it will use the appropriate
   # value for tag msg.  Otherwise it will be "Unknown Message.".

   # This shows that you can put some logic in your config files so that
   # your config files can be shared across platforms without having
   # to have multiple versions of that config file or add complex platform
   # specific logic into your perl code.

To load it into memory do:

   my $cfg = Advanced::config->new ("complex.cfg")->load_config();

=item BREAKING YOUR CONFIG FILE INTO SECTIONS (section.cfg)

   abc = lmn     # Has no section, so considered in section "main".
   user = me
   pwd = nope!

   [ host 1 ]
   abc = xyz
   pwd = password1

   [host 2]
   abc=abc
   pwd = password2

   [ HOST 3 ]
   abc = 123
   pwd = password3

   [ HOST 2 ]
   efg = repeat    # Section "host 2" has 3 tags in it.  "abc", "efg" & "pwd".

   [ Host 4 ]
   user = you

Please note that section names are case insensitive and the tag abc's value
depends on what section of the config file you are currently looking at.  This
way you may repeat tags between sections and know that each section is
independant of each other.  As if each section was in it's own config file.

Or you can interpret each section as overrides to tags in the main section
using the B<inherit> option.  Where if a tag isn't defined in the current
section, it then looks in the main section for it.  Say you're on host 1 and
you want to log into your application.  You need both a user & pwd pair to do
this.  When you look up the pwd, you find it in host 1, but when you try to
look up the user, it can't find it in the current section, so it looks in the
main section for it instead.  In effect all 4 sections have all variables from
main included in each section.  With the local tags overriding what's in main.
A neet way to handle minor differences that would otherwise require you to
have multiple config files you'd need to keep in sync.

To load it into memory do:

   my $cfg = Advanced::config->new ("section.cfg")->load_config();
              or
   my $cfg = Advanced::config->new ("section.cfg", {inherit => 1})->load_config();

=item SOURCING IN FILES WITH SECTIONS (src_sect.cfg)

By default, when sourcing in another config file it's default section is
also called "B<main>".  This is true even when you are sourcing in a file
inside a named section block.  That name isn't inherited by default.

And if that config file also uses sections, those section names are preserved.

But sometimes you'd like to source in a sub-file as if any tag appearing
outside a section was defined in the original file's current section.  In
that case follow the file name with the appropriate label.  Which by default
is B<DEFAULT>.

    . simple.cfg   # All variables appear in the main section.

    [ section 1 ]
    . simple.cfg   # All varibles appear in the main section as well.

    [ section 2 ]
    . simple.cfg   # DEFAULT - all varibles from this config file will apear as members of "section 2".

    [ section 3 ]
    . section.cfg  # DEFAULT - tags abc, user & pwd are now in 'section 3', while everything else stays in it's defined section.

To load it into memory do:

   my $cfg = Advanced::config->new ("src_sect.cfg")->load_config();

=item USING STRANGE LOOKING CONFIG FILES (product-1.cfg)

Sometimes you want to look at a config file owned by another product that
doesn't follow the formatting expected by this module by default.  So this
module allows you a way to provide new rules for parsing a config file to
make these differences irrelevant.

Lets assume this config file used ";", not "#" as the comment char, "::", not
"=" as it's assignment operator, and finally used "include", not "." when
sourcing in another config file.  So you'd get something like the following:

   ; This is a comment ...
   include  product-2.cfg

   abc :: xyz      ; Tag "abc" now equals "xyz"!

The possibilities are practically endless!  You can even write your own wrapper
config file and use the "source_cb" callback option to redefine the parsing
rules for a particular config file being sourced in if the parsing rules
are different!

In fact, one of the test cases does just this!  (t/30-alt_symbols_cfg.t)

To load it into memory do:

   my $cfg = Advanced::config->new ("product-1.cfg",
                   { "assign => "::", "comment" => ";", "source" => "include" }
                                   )->load_config();


=item ENCRYPTING/DECRYPTING CONFIG FILES

Sometimes you need to protect sensitive information inside your config files.
Such as the user names and passwords that your application requires to run.
This module allows this at the individual tag/value pair level.  Not at the
file level!

The 1st example shows tags whose values are pending the encryption process.
While the 2nd example shows what happens after it's been encrypted.  You can
have config files that have both pending and encrypted tags in it.  As well
as tags whose values are never encrypted.  It is controlled by having the
appropriate label in the comment after the tag/value pair.

   # Waiting to encrypt these values ...
   my_username_1 = "anonymous"                   # ENCRYPT
   my_password_1 = "This is too much fun!"       # ENCRYPT me ...

   # They've already been encypted!
   my_username_2 = '4aka54D3eZ4aea5'             # DECRYPT
   my_password_2 = '^M^Mn1\pmeaq>n\q?Z[x537z3A'  # DECRYPT me ...

   # This value will never be encrytped/decrypted ...
   dummy = "Just some strange value that is always in clear text."

The encrypted value is automatically decrypted for you when the config file
is loaded into memory.  So it's already in clear text when C<get_value()> is
called.  See L<Advanced::Config::Options> for more details on the options
used to control the encrypt/decrypt process.  See C<encrypt_config_file()> in
L<Advanced::Config> for how to encrypt the contents of the config file itself.

You can use C<decrypt_config_file()> to reverse the process if needed.

=item PLUS MUCH, MUCH, MORE ...

I could go on and on with many more examples.  I'll add more in the future as
I consider more significant issues to cover.  In the mean time you can find
many more examples from the build under:  I<t/config/*.cfg> 

=back

=head1 COPYRIGHT

Copyright (c) 2015 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Advanced::Config::Options> - Covers the options that allow you to modify
how a config file gets parsed.  It defines the controls allowing the various
examples shown above.

L<Advanced::Config::Date> - Handles date parsing for get_date().

L<Advanced::Config::Reader> - Handles the parsing of the config file per the
options defined above.

L<Advanced::Config> - Defines the configuration object that you wish to
manipulate.

=cut

