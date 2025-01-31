###
###  Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.
###
###  Module: Advanced::Config::Reader

=head1 NAME

Advanced::Config::Reader - Reader manager for L<Advanced::Config>.

=head1 SYNOPSIS

 use Advanced::Config::Reader;
 or 
 require Advanced::Config::Reader;

=head1 DESCRIPTION

F<Advanced::Config::Reader> is a helper module to L<Advanced::Config>.  So it
should be very rare to directly call any methods defined by this module.

This module manages reading the requested config file into memory and parsing
it for use by L<Advanced::Config>.

Each config file is highly customizable.  Where you are allowed to alter the
comment char from B<#> to anything you like, such as B<;;>.  The same is true
for things like the assignment operator (B<=>), and many other character
sequences with special meaning to this module.

So to avoid confusion, when I talk about a feature, I'll talk about it's default
appearance and let it be safely assumed that the same will hold true if you've
overriden it's default character sequence with something else.  Such as when
discussing comments as 'B<#>', even though you could have overriden it as
'B<;*;>'.  See L<Advanced::Config::Options> for a list of symbols you can
overrides.

You are also allowed to surround your values with balanced quotes or leave them
off entirely.  The only time you must surround your value with quotes is when
you want to preserve leading or trailing spaces in your value.  Without balanced
quotes these spaces are trimmed off.  Also if you need a comment symbol in your
tag's value, the entire value must be surrounded by quotes! Finally, unbalanced
quotes can behave very strangly and are not stripped off.

So in general white space in your config file is basically ignored unless it's
surrounded by printible chars or quotes.

Sorry you can't use a comment symbol as part of your tag's name.

See L<Advanced::Config::Examples> for some sample config files.  You may also
find a lot of example config files in the package you downloaded from CPAN to
install this module from under I<t/config>.

=head1 FUNCTIONS

=over 4

=cut

package Advanced::Config::Reader;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Advanced::Config::Options;
use Advanced::Config;

use Fred::Fish::DBUG 2.09 qw / on_if_set  ADVANCED_CONFIG_FISH /;

use File::Basename;

$VERSION = "1.11";
@ISA = qw( Exporter );

@EXPORT = qw( read_config  source_file  make_new_section  parse_line
              expand_variables  apply_modifier  parse_for_variables
              format_section_line  format_tag_value_line format_encrypt_cmt
              encrypt_config_file_details  decrypt_config_file_details );

@EXPORT_OK = qw( );

my $skip_warns_due_to_make_test;
my %global_sections;
my $gUserName;

# ==============================================================
# NOTE: It is extreemly dangerous to reference Advanced::Config
#       internals in this code.  Avoid where possible!!!
#       Ask for copies from the module instead.
# ==============================================================
# Any other module initialization done here ...
# This block references initializations done in my other modules.
BEGIN
{
   DBUG_ENTER_FUNC ();

   # What we call our default section ...
   $global_sections{DEFAULT}  = Advanced::Config::Options::DEFAULT_SECTION_NAME;
   $global_sections{OVERRIDE} = $global_sections{DEFAULT};

   $gUserName = Advanced::Config::Options::_get_user_id ();

   # Is the code being run via "make test" environment ...
   if ( $ENV{PERL_DL_NONLAZY} ||
        $ENV{PERL_USE_UNSAFE_INC} ||
        $ENV{HARNESS_ACTIVE} ) {
      $skip_warns_due_to_make_test = 1;
   }

   DBUG_VOID_RETURN ();
}


# ==============================================================
# No fish please ... (called way too often)
# This method is called in 2 ways:
#  1) By parse_line() to determine if ${ln} is a tag/value pair.
#  2) By everyone else to parse a known tag/value pair in ${ln}.
#
# ${ln} is in one of these 3 formats if it's a tag/value pair.
#     tag = value
#     export tag = value    # Unix shell scripts
#     set tag = value       # Windows Batch files

sub _split_assign
{
   my $rOpts = shift;    # The read options ...
   my $ln    = shift;    # The value to split ...
   my $skip  = shift;    # Skip massaging the tag? 

   my ( $tag, $value );
   if ( is_assign_spaces ( $rOpts ) ) {
      ( $tag, $value ) = split ( " ", $ln, 2 );
      $skip = 1;   # This separator doesn't support the prefixes.
   } else {
      my $assign_str  = convert_to_regexp_string ($rOpts->{assign}, 1);
      ( $tag, $value ) = split ( /\s*${assign_str}\s*/, $ln, 2 );
   }

   my $export_prefix = "";

   unless ( $skip ) {
      # Check if one of the export/set variable prefixes were used!
      if ( $tag =~ m/^(export\s+)(\S.*)$/i ) {
         $tag = $2;           # Remove the leading "export" keyword ...
         $export_prefix = $1;
      } elsif ( $tag =~ m/^(set\s+)(\S.*)$/i ) {
         $tag = $2;           # Remove the leading "set" keyword ...
         $export_prefix = $1;
      }
   }

   # Did we request case insensitive tags ... ?
   my $ci_tag = ( $rOpts->{tag_case} && defined $tag ) ? lc ($tag) : $tag;

   return ( $ci_tag, $value, $export_prefix, $tag );
}


# ==============================================================

=item $sts = read_config ( $file, $config )

This method performs the reading and parsing of the given config file and puts
the results into the L<Advanced::Config> object I<$config>.  This object
provides the necessary parsing rules to use.

If a line was too badly mangled to be parsed, it will be ignored and a warning
will be written to your screen.

It returns B<1> on success and B<0> on failure.

Please note that comments are just thrown away by this process and only
tag/value pairs remain afterwards.  Everything else is just instructions to
the parser or how to group together these tag/value pairs.

If it sees something like:  export tag = value, it will export tag's value
to the %ENV hash for you just like it does in a Unix shell script!

Additional modifiers can be found in the comments after a tag/value pair
as well.

=cut

# ==============================================================
sub read_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $file = shift;     # The filename to read ...
   my $cfg  = shift;     # The Advanced::Config object ...

   my $opts = $cfg->get_cfg_settings ();   # The Read Options ...

   # Locate the parent section of the config file.
   my $pcfg = $cfg->get_section ();

   # Using a variable so that we can be recursive in reading config files.
   my $READ_CONFIG;

   DBUG_PRINT ("INFO", "Opening the config file named: %s", $file);

   unless ( open ($READ_CONFIG, "<", $file) ) {
      return DBUG_RETURN ( croak_helper ($opts,
                                        "Unable to open the config file.", 0) );
   }

   # Misuse of this option makes the config file unreadable ...
   if ( $opts->{use_utf8} ) {
      binmode ($READ_CONFIG, "encoding(UTF-8)");
      $pcfg->_allow_utf8 ();   # Tells get_date() that wide char languages are OK!
   }

   # Some common RegExp strings ... Done here to avoid asking repeatably ...
   my $decrypt_str = convert_to_regexp_string ($opts->{decrypt_lbl});
   my $encrypt_str = convert_to_regexp_string ($opts->{encrypt_lbl});
   my $hide_str    = convert_to_regexp_string ($opts->{hide_lbl});
   my $sect_str    = convert_to_regexp_string ($opts->{source_file_section_lbl});

   my $export_str  = convert_to_regexp_string ($opts->{export_lbl});
   my ($lb, $rb) = ( convert_to_regexp_string ($opts->{section_left}),
                     convert_to_regexp_string ($opts->{section_right}) );
   my $assign_str  = convert_to_regexp_string ($opts->{assign});
   my $src_str     = convert_to_regexp_string ($opts->{source});
   my ($lv, $rv) = ( convert_to_regexp_string ($opts->{variable_left}),
                     convert_to_regexp_string ($opts->{variable_right}) );

   # The label separators used when searching for option labels in a comment ...
   my $lbl_sep = '[\s.,$!()-]';

   # Initialize to the default secion ...
   my $section = make_new_section ( $cfg, "" );

   my %hide_section;

   while ( <$READ_CONFIG> ) {
      chomp;
      my $line = $_;             # Save so can use in fish logging later on.

      my ($tv, $ln, $cmt, $lq, $rq) = parse_line ( $line, $opts );

      if ( $ln eq "" ) {
         DBUG_PRINT ("READ", "READ LINE:  %s", $line);
         next;                   # Skip to the next line if only comments found.
      }

      # Check for lines with no tag/value pairs in them ...
      if ( ! $tv ) {
         DBUG_PRINT ("READ", "READ LINE:  %s", $line);

         # EX:  . ${file} --- Sourcing in ${file} ...
         if ( $ln =~ m/^${src_str}\s+(.+)$/i ) {
            my $src = $1;
            my $def_section = "";
            if ( $cmt =~ m/(^|${lbl_sep})${sect_str}(${lbl_sep}|$)/ ) {
               $def_section = $section;
            }
            my $res = source_file ( $cfg, $def_section, $src, $file );
            return DBUG_RETURN (0)  unless ( $res );
            next;
         }

         # EX:  [ ${section} ] --- Starting a new section ...
         if ( $ln =~ m/^${lb}\s*(.+?)\s*${rb}$/ ) {
            $section = make_new_section ( $cfg, $1 );

            $hide_section{$section} = 0;   # Assume not sensitive ...

            if ( $cmt =~ m/(^|${lbl_sep})${hide_str}(${lbl_sep}|$)/ ||
                 should_we_hide_sensitive_data ( $section ) ) {
               $hide_section{$section} = 1;
            }
            next;
         }

         # Don't know what the config file was thinking of ...
         # Don't bother expanding any variables encountered.
         DBUG_PRINT ("error", "<Previous line ignored.  Unknown format!>");
         next;
      }

      # ------------------------------------------------------------------
      # If you get here, you know it's a tag/value pair to parse ...
      # Don't forget that any comment can include processing instructions!
      # ------------------------------------------------------------------

      # Go to the requested section ...
      $cfg = $pcfg->get_section ( $section, 1 );

      my ($tag, $value, $prefix, $t2) = _split_assign ( $opts, $ln );

      # Don't export individually if doing a batch export ...
      # If the export option is used, invert the meaning ...
      my $export_flag = 0;    # Assume not exporting this tag to %ENV ...
      if ( $prefix ) {
         $export_flag = $opts->{export} ? 0 : 1;
      } elsif ( $cmt =~ m/(^|${lbl_sep})${export_str}(${lbl_sep}|$)/ ) {
         $export_flag = $opts->{export} ? 0 : 1;
      }

      # Is the line info sensitive & should it be hidden/masked in fish ???
      my $hide = 0;
      if ( $hide_section{$section} ||
           $cmt =~ m/(^|${lbl_sep})${encrypt_str}(${lbl_sep}|$)/ ||
           $cmt =~ m/(^|${lbl_sep})${hide_str}(${lbl_sep}|$)/    ||
           should_we_hide_sensitive_data ( $tag, 1 ) ) {
         $hide = 1   unless ( $opts->{dbug_test_use_case_hide_override} );
      }

      if ( $hide ) {
         # Some random length so we can't assume the value from the mask used!
         my $mask = "*"x8;
         if ( $value eq "" ) {
            if ( is_assign_spaces ( $opts ) ) {
               $line =~ s/^(\s*\S+\s+)/${1}${mask}  /;
            } else {
               $line =~ s/(\s*${assign_str})\s*/${1} ${mask}  /;
            }
         } else {
            my $hide_value = convert_to_regexp_string ( $value, 1 );
            if ( is_assign_spaces ( $opts ) ) {
               $line =~ s/^(\s*\S+\s+)${hide_value}/${1}${mask}/;
            } else {
               $line =~ s/(\s*${assign_str}\s*)${hide_value}/${1}${mask}/;
            }
         }

      } elsif ( $cmt =~ m/(^|${lbl_sep})${decrypt_str}(${lbl_sep}|$)/ ) {
         # Don't hide the line in fish, but hide it's value processing ...
         $hide = 1   unless ( $opts->{dbug_test_use_case_hide_override} );
      }

      DBUG_PRINT ("READ", "READ LINE:  %s", $line);

      # Remove any balanced quotes ... (must do after hide)
      $value =~ s/^${lq}(.*)${rq}$/$1/   if ( $lq );

      if ( $tag =~ m/^(shft3+)$/i ) {
         my $m = "You can't override special variable '${1}'."
               . "  Ignoring this line in the config file.\n";
         if ( $skip_warns_due_to_make_test ) {
            DBUG_PRINT ("WARN", $m);
         } else {
            warn $m;
         }
         next;
      }

      # Was the tag's value encryped??   Then we need to decrypt it ...
      my $still_encrypted = 0;
      if ( $cmt =~ m/(^|${lbl_sep})${decrypt_str}(${lbl_sep}|$)/ ) {
         $value = _reverse_escape_sequences ( $value, $opts );

         if ( $opts->{disable_decryption} ) {
            $still_encrypted = 1;     # Doesn't get decrypted.
         } else {
            $value = decrypt_value ( $value, $t2, $opts, $file );
         }
      }

      # See if we can expand variables in $value ???
      my $still_variables = 0;
      if ( $opts->{disable_variables} ) {
          $still_variables = ( $value =~ m/${lv}.+${rv}/ ) ? 1 : 0;
      } elsif ( ! $still_encrypted ) {
         ($value, $hide) = expand_variables ( $cfg, $value, $file, $hide, ($lq ? 0 : 1) );
         if ( $hide == -1 ) {
            # $still_encrypted = $still_variables = 1;
            $still_variables = 1;  # Variable(s) points to encrypted data.
         }
      }

      # Export one value to %ENV ... (once set, can't back it out again!)
      $cfg->export_tag_value_to_ENV ( $tag, $value, $hide )  if ($export_flag);

      # Add to the current section in the Advanced::Config object ...
      $cfg->_base_set ($tag, $value, $file, $hide, $still_encrypted, $still_variables);
   }   # End while reading the config file ...

   close ( $READ_CONFIG );

   DBUG_RETURN (1);
}


# ==============================================================

=item $boolean = source_file ($config, $def_sct, $new_file, $curr_file)

This is a private method called by I<read_config> to source in the requested
config file and merge the results into the current config file.

If I<$def_sct> is given, it will be the name of the current section that the
sourced in file is to use for it's default unlabeled section.  If the default
section name has been hard coded in the config file, this value overrides it.

The I<$new_file> may contain variables and after they are expanded the
source callback function is called before I<load_config()> is called.
See L<Advanced::Config::lookup_one_variable> for rules on variable expansion.

If I<$new_file> is a relative path, it's a relative path from the location
of I<$curr_file>, not the program's current directory!

If a source callback was set up, it will call it here.

This method will also handle the removal of decryption related options if new
ones weren't provided by the callback function.  See Advanced::Config::Options
for more details.

Returns B<1> if the new file successfully loaded.  Else B<0> if something went
wrong during the load!

=cut

sub source_file
{
   DBUG_ENTER_FUNC (@_);
   my $cfg            = shift;
   my $defaultSection = shift;  # The new default section if not "".
   my $new_file       = shift;  # May contain variables to expand ...
   my $old_file       = shift;  # File we're currently parsing. (has abs path)

   my $rOpts = $cfg->get_cfg_settings ();   # The Read Options ...

   local $global_sections{OVERRIDE} = $defaultSection  if ( $defaultSection );

   my $pcfg = $cfg->get_section ();  # Back to the main/default section ...

   my $file = $new_file = expand_variables ($pcfg, $new_file, undef, undef, 1);

   # Get the full name of the file we're sourcing in ...
   $file = $pcfg->_fix_path ( $file, dirname ( $old_file ) );

   unless ( -f $file && -r _ ) {
      my $msg = "No such file to source in or it's unreadable ( $file )";
      return DBUG_RETURN ( croak_helper ( $rOpts, $msg, 0 ) );
   }

   if ( $cfg->_recursion_check ( $file ) ) {
      my $msg = "Recursion detected while sourcing in file ( $new_file )";
      if ( $rOpts->{trap_recursion} ) {
         # The request is a fatal error!
         return DBUG_RETURN ( croak_helper ( $rOpts, $msg, 0 ) );
      } else {
         DBUG_PRINT ("RECURSION", $msg);
         return DBUG_RETURN ( 1 );   # Just ignore the request ...
      }
   }

   # The returned callback option(s) will be applied to the current
   # settings, not the default settings if not a compete set!
   my ($r_opts, $d_opts);
   if ( exists $rOpts->{source_cb} && ref ( $rOpts->{source_cb} ) eq "CODE" ) {
      ($r_opts, $d_opts) = $rOpts->{source_cb}->( $file, $rOpts->{source_cb_opts} );
   }

   if ( $rOpts->{inherit_pass_phase} && $rOpts->{pass_phrase} ) {
      my %empty;
      $r_opts = \%empty  unless ( defined $r_opts );
      $r_opts->{pass_phrase} = $rOpts->{pass_phrase}  unless ( $r_opts->{pass_phrase} );
   }

   my $res = $pcfg->_load_config_with_new_date_opts ( $file, $r_opts, $d_opts );

   DBUG_RETURN ( (defined $res) ? 1 : 0 );
}


# ==============================================================

=item $name = make_new_section ($config, $section)

This is a private method called by I<read_config> to create a new section
in the L<Advanced::Config> object if a section of that name doesn't already
exist.

The I<$section> name is allowed to contain variables to expand before the
string is used.  But those variables must be defined in the I<main> section.

Returns the name of the section found/created in lower case.

=cut

sub make_new_section
{
   DBUG_ENTER_FUNC (@_);
   my $config   = shift;
   my $new_name = shift;

   # Check if overriding the default section with a new name ...
   if ( $new_name eq "" || $new_name eq $global_sections{DEFAULT} ) {
      if ( $global_sections{DEFAULT} ne $global_sections{OVERRIDE} ) {
         DBUG_PRINT ("OVERRIDE", "Overriding section '%s' with section '%s'",
                     $new_name, $global_sections{OVERRIDE});
         $new_name = $global_sections{OVERRIDE};
      }
   }

   my $pcfg = $config->get_section ();    # Back to the main section ...

   my $val = expand_variables ($pcfg, $new_name, undef, undef, 1);
   $new_name = lc ( $val );

   # Check if the section name is already in use ...
   my $old = $pcfg->get_section ( $new_name );
   if ( $old ) {
      return DBUG_RETURN ( $old->section_name() );
   }

   # Create the new section now that we know it's name is unique ...
   my $scfg = $pcfg->create_section ( $new_name );

   if ( $scfg ) {
      return DBUG_RETURN ( $scfg->section_name () );
   }

   # Should never, ever happen ...
   DBUG_PRINT ("WARN", "Failed to create the new section: %s.", $new_name);

   DBUG_RETURN ("");    # This is the main/default section being returned.
}


# ==============================================================
# Allows a config file to run a random command when it's loaded into memory.
# Only allowed if explicity enabled & configured!
# Decided it's too dangerous to use, so never called outside of a POC example!
sub _execute_backquoted_cmd
{
   my $rOpts = shift;
   my $hide  = shift;
   my $tag   = shift;
   my $value = shift;

   return ( $value )  unless ( $rOpts->{enable_backquotes} );

   # Left & right backquotes ...
   my ($lbq, $rbq) = ( convert_to_regexp_string ($rOpts->{backquote_left}, 1),
                       convert_to_regexp_string ($rOpts->{backquote_right}, 1) );

   unless ( $value =~ m/^${lbq}(.*)${rbq}$/ ) {
      return ( $value );   # No balanced backquotes detected ...
   }
   my $cmd = $1;           # The command to run ...

   # DBUG_MASK_NEXT_FUNC_CALL (3)  if ( $hide );      # Never hide value (cmd to run)
   DBUG_ENTER_FUNC ($rOpts, $hide, $tag, $value, @_);
   DBUG_MASK (0)  if ( $hide );    # OK to hide the results.

   if ( $cmd =~ m/[`]/ ) {
      DBUG_PRINT ('INFO', 'Your command may not have backquotes (`) in it!');
   } elsif ( $cmd =~ m/^\s*$/ ) {
      DBUG_PRINT ('INFO', 'Your command must have a value!');

   } else {
      die ("Someone tried to run cmd: $cmd\n");
      # $value = `$cmd`;
      $value = ""  unless ( defined $value );
      chomp ($value);
   }

   DBUG_RETURN ($value);
}


# ==============================================================

=item @ret[0..4] = parse_line ( $input, \%opts )

This is a private method called by I<read_config> to parse each line of the
config file as it's read in.  It's main purpose is to strip off leading and
trailing spaces and any comments it might find on the input line.  It also
tells if the I<$input> contains a tag/value pair.

It returns 5 values:  ($tv_flg, $line, $comment, $lQuote, $rQuote)

B<$tv_flg> - True if I<$line> contains a tag/value pair in it, else false.

B<$line> - The trimmed I<$input> line minus any comments.

B<$comment> - The comment stripped out of the original input line minus the
leading comment symbol(s).

B<$lQuote> & B<rQuote> - Only set if I<$tv_flg> is true and I<$lQuote> was
the 1st char of the value and I<$rQuote> was the last char of the tag's value.
If the value wasn't surrounded by balanced quotes, both return values will be
the empty string B<"">.

If these quotes are returned, it expects the caller to remove them from the
tag's value.  The returned values for these quote chars are suitable for use as
is in a RegExpr.  The caller must do this in order to preserve potential
leading/trailing spaces.

=cut

sub parse_line
{
   DBUG_MASK_NEXT_FUNC_CALL (0);   # Masks ${line}!
   DBUG_ENTER_FUNC ( @_ );
   my $line = shift;
   my $opts = (ref ($_[0]) eq "HASH" ) ? $_[0] : {@_};

   # Mask the ${line} return value in fish ...
   # Only gets unmasked in the test scripts:  t/*.t.
   # Always pause since by the time we detect if it should be
   # hidden or not it's too late.  We've already written it to fish!
   unless ( $opts->{dbug_test_use_case_parse_override} ) {
      DBUG_MASK ( 1 );
      DBUG_PAUSE ();
   }

   # Strip of leading & trailing spaces ...
   $line =~ s/^\s+//;
   $line =~ s/\s+$//;

   my $default_quotes = using_default_quotes ( $opts );

   my $comment = convert_to_regexp_string ($opts->{comment}, 1);

   my ($tag, $value) = _split_assign ( $opts, $line, 1 );

   my ($l_quote, $r_quote, $tv_pair_flag) = ("", "", 0);
   my $var_line = $line;

   unless ( defined $tag && defined $value ) {
      $tag = $value = undef;      # It's not a tag/value pair ...

   } elsif ( $tag eq "" || $tag =~ m/${comment}/ ) {
      $tag = $value = undef;      # It's not a valid tag ...

   } else {
      # It looks like a tag/value pair to me ...
      $tv_pair_flag = 1;

      if ( $opts->{disable_quotes} ) {
         ;   # Don't do anything ...

      } elsif ( $default_quotes ) {
         if ( $value =~ m/^(['"])/ ) {
            $l_quote = $r_quote = $1;     # A ' or ".  (Never both)
         }

      # User defined quotes ...
      } else {
         my $q = convert_to_regexp_string ($opts->{quote_left}, 1);
         if ( $value =~ m/^(${q})/ ) {
            $l_quote = $q;
            $r_quote = convert_to_regexp_string ($opts->{quote_right}, 1);
         }
      }

      $var_line = $value;
   }

   # Comment still in value, but still haven't proved any quotes are balanced.
   DBUG_PRINT ("DEBUG", "Tag (%s),  Value (%s),  Proposed Left (%s),  Right (%s)",
                        $tag, $value, $l_quote, $r_quote);

   my $cmts = "";

   # Was the value in the tag/value pair starting with a left quote?
   if ( $tv_pair_flag && $l_quote ne "" ) {
      my ($q1, $val2, $q2);

      # Now check if they were balanced ...
      if ( $value =~ m/^(${l_quote})(.*)(${r_quote})(\s*${comment}.*$)/ ) {
         ($q1, $val2, $q2, $cmts) = ($1, $2, $3, $4);   # Has a comment ...
      } elsif ( $value =~ m/^(${l_quote})(.*)(${r_quote})\s*$/ ) {
         ($q1, $val2, $q2, $cmts) = ($1, $2, $3, "");   # Has no comment ...
      }

      # If balanced quotes were found ...
      if ( $q1 ) {
         # If the surrounding quotes don't have quotes inside them ...
         # IE not malformed ...
         unless ( $val2 =~ m/${l_quote}/ || $val2 =~ m/${r_quote}/ ) {
            my $cmt2 = convert_to_regexp_string ($cmts);
            $cmts =~ s/^\s*${comment}\s*//;            # Remove comment symbol ...
            $line =~ s/${cmt2}$//  if ($cmt2 ne "" );  # Remove the comments ...

            DBUG_PRINT ("LINE", "Balanced Quotes encountered for removal ...");
            return DBUG_RETURN ( $tv_pair_flag, $line, $cmts, $l_quote, $r_quote);
         }
      }
   }

   # The Quotes weren't balanced, so they can no longer be removed from
   # arround the value of what's returned!
   $l_quote = $r_quote = "";

   # ----------------------------------------------------------------------
   # If no comments in the line, just return the trimmed string ...
   # Both tests are needed due to custom comment/assign strings!
   # ----------------------------------------------------------------------
   if ( $line !~ m/${comment}/ ) {
      DBUG_PRINT ("LINE", "Simply no comments to worry about ...");
      return DBUG_RETURN ( $tv_pair_flag, $line, "", "", "" );
   }

   # Handles case where a comment char embedded in the assignment string.
   if ( $tv_pair_flag && $value !~ m/${comment}/ ) {
      DBUG_PRINT ("LINE", "Simply no comments in the value to worry about ...");
      return DBUG_RETURN ( $tv_pair_flag, $line, "", "", "" );
   }

   # ----------------------------------------------------------------------
   # If not protected by balanced quotes, verify the comment symbol detected
   # isn't actually a variable modifier.  Variables are allowed in most places
   # in the config file, not just in tag/value pairs.
   # ----------------------------------------------------------------------

   # The left & right anchor points for variable substitution ...
   my $lvar = convert_to_regexp_string ($opts->{variable_left}, 1);
   my $rvar = convert_to_regexp_string ($opts->{variable_right}, 1);

   # Determine what value to use in variable substitutions that doesn't include
   # a variable tag, or a comment tag, or a value in the $line.
   my $has_no_cmt;
   foreach ("A" .. "Z", "@") {
      $has_no_cmt = ${_}x10;
      last  unless ( $has_no_cmt =~ m/${comment}/ ||
                     $has_no_cmt =~ m/${lvar}/    ||
                     $has_no_cmt =~ m/${rvar}/    ||
                     $line       =~ m/${has_no_cmt}/ );
   }
   if ( $has_no_cmt eq "@"x10 ) {
      warn ("May be having variable substitiution issues in parse_line()!\n");
   }

   # Strip out all the variables from the value ...
   # Assumes processing variables from left to right ...
   # Need to evaluate even if variables are disabled to parse correctly ...
   my @parts = parse_for_variables ($var_line, 1, $opts);
   my $cmt_found = 0;
   my $count_var = 0;
   my @data;
   while (defined $parts[0]) {
      $cmt_found = $parts[3];
      push (@data, $var_line);
      last  if ($cmt_found);
      $var_line = $parts[0] . $has_no_cmt . $parts[2];
      @parts = parse_for_variables ($var_line, 1, $opts);
      ++$count_var;
   }
   push (@data, $var_line);

   my $unbalanced_leading_var_anchor_with_comments = 0;
   if ( $cmt_found && $parts[0] =~ m/(\s*${comment}\s*)(.*$)/ ) {
      # parts[1] is parts[7] trimmed ... so join back together with untrimmed.
      $cmts = $2 . $opts->{variable_left}  . $parts[7]
                 . $opts->{variable_right} . $parts[2];
      my $str = convert_to_regexp_string ( $1 . $cmts );
      $line =~ s/${str}$//;
      DBUG_PRINT ("LINE", "Variables encountered with variables in comment ...");
      return DBUG_RETURN ( $tv_pair_flag, $line, $cmts, "", "");
   } elsif ( $count_var ) {
      if ( $var_line =~ m/(\s*${comment}\s*)(.*)$/ ) {
         $cmts = $2;
         if ( $cmts =~ m/${has_no_cmt}/ ) {
            $unbalanced_leading_var_anchor_with_comments = 1;
         } else {
            my $cmt2 = convert_to_regexp_string ($1 . $cmts);
            $line =~ s/${cmt2}$//;
            DBUG_PRINT ("LINE", "Variables encountered with constant comment ...");
         }
      } else {
         $cmts = "";
         DBUG_PRINT ("LINE", "Variables encountered without comments ...");
      }

      unless ( $unbalanced_leading_var_anchor_with_comments ) {
         return DBUG_RETURN ( $tv_pair_flag, $line, $cmts, "", "");
      }
   }

   # ---------------------------------------------------------------------------
   # Corrupted variable definition with variables in the comments ...
   # Boy things are getting difficult to parse.  Reverse the previous variable
   # substitutions until the all variables in the comments are unexpanded again!
   # Does a greedy RegExp to grab the 1st comment string encountered.
   # ---------------------------------------------------------------------------
   if ( $unbalanced_leading_var_anchor_with_comments ) {
      $cmts = "";
      foreach my $l (reverse @data) {
         if ( $l =~ m/\s*${comment}\s*(.*)$/ ) {
            $cmts = $1;
            last  unless ( $cmts =~ m/${has_no_cmt}/ );
            $cmts = "";
         }
      }

      if ( $cmts ne "" ) {
         my $cmt2 = convert_to_regexp_string ($cmts);
         $line =~ s/\s*${comment}\s*${cmt2}$//;
         DBUG_PRINT ("LINE", "Unbalanced var def encountered with var comments ...");
         return DBUG_RETURN ( $tv_pair_flag, $line, $cmts, "", "");
      }

      # If you get here, assume it's not a tag/value pair even if it is!
      # I know I can no longer hope to parse it correctly without a test case.
      # But I really don't think it's possible to get here anymore ...
      warn ("Corrupted variable definition encountered.  Can't split out the comment with variables in it correctly!\n");
      return DBUG_RETURN ( 0, $line, "", "", "");
   }

   # ----------------------------------------------------------------------
   # No variables, no balanced quotes ...
   # But I still think there's a comment to remove!
   # ----------------------------------------------------------------------

   if ( $tv_pair_flag && $value =~ m/(\s*${comment}\s*)(.*)$/ ) {
      $cmts = $2;
      my $cmt2 = convert_to_regexp_string ($1 . $cmts);
      $line =~ s/${cmt2}$//;             # Remove the comment from the line.
      DBUG_PRINT ("LINE", "Last ditch effort to remove the comment from the value ...");
      return DBUG_RETURN ( $tv_pair_flag, $line, $cmts, "", "");
   }

   $cmts = $line;
   $line =~ s/\s*${comment}.*$//;              # Strip off any comments ....
   $cmts = substr ( $cmts, length ($line) );   # Grab the comments ...
   $cmts =~ s/^\s*${comment}\s*//;             # Remove comment symbol ...

   DBUG_PRINT ("LINE", "Last ditch effort to remove the comment from the line ...");
   DBUG_RETURN ( $tv_pair_flag, $line, $cmts, "", "");
}


# ==============================================================

=item ($v[, $h]) = expand_variables ( $config, $string[, $file[, $sensitive[, trim]]] )

This function takes the provided I<$string> and expands any embedded variables
in this string similar to how it's handled by a Unix shell script.

The optional I<$file> tells which file the string was read in from.

The optional I<$sensitive> when set to a non-zero value is used to disable
B<fish> logging when it's turned on because the I<$string> being passed contains
sensitive information.

The optional I<$trim> tells if you may trim the results before it's returned.

It returns the new value $v, once all the variable substitition(s) have occured.
And optionally a second return value $h that tells if B<fish> was paused during
the expansion of that value due to something being sensitive.  This 2nd return
value $h is meaningless in most situations, so don't ask for it.

All variables are defined as B<${>I<...>B<}>, where I<...> is the variable you
wish to substitute.  If something isn't surrounded by a B<${> + B<}> pair, it's
not a variable.

   A config file exampe:
       tmp1 = /tmp/work-1
       tmp2 = /tmp/work-2
       opt  = 1
       date = 2011-02-03
       logs = ${tmp${opt}}/log-${date}.txt
       date = 2012-12-13

   So when passed "${tmp${opt}}/log-${date}.txt", it would return:
       /tmp/work-1/log-2011-02-03.txt
   And assigned it to B<logs>.

As you can see multiple variable substitutions may be expanded in a single
string as well as nested substitutions.  And when the variable substitution is
done while reading in the config file, all the values used were defined before
the tag was referenced.

Should you call this method after the config file was loaded you get slightly
different results.  In that case the final tag value is used instead and the
2nd date in the above example would have been used in it's place.

See L<Advanced::Config::lookup_one_variable> for more details on how it
evaluates individual variables.

As a final note, if one or more of the referenced variables holds encrypted
values that haven't yet been decrypted, those variables are not resolved.  But
all variables that don't contain encrypted data are resolved.

=cut

# ==============================================================
sub expand_variables
{
   my $config    = shift;           # For the current section of config obj ...
   my $value     = shift;           # The value to parse for variables ...
   my $file      = shift || "";     # The config file the value came from ...
   my $mask_flag = shift || 0;      # Hide/mask sensitive info written to fish?
   my $trim_flag = shift || 0;      # Tells if we should trim the result or not.

   # Only mask ${value} if ${mask_flag} is true ...
   DBUG_MASK_NEXT_FUNC_CALL (1)  if ( $mask_flag );
   DBUG_ENTER_FUNC ( $config, $value, $file, $mask_flag, $trim_flag, @_);

   my $opts = $config->get_cfg_settings ();   # The Read Options ...

   my $pcfg = $config->get_section();    # Get the main/parent section to work with!

   # Don't write to Fish if we're hiding any values ...
   if ( $mask_flag ) {
      DBUG_PAUSE ();
      DBUG_MASK ( 0 );
   }

   # The 1st split of the value into it's component parts ...
   my ($left, $tag, $right, $cmt_flag, $mod_tag, $mod_opt, $mod_val, $ot) =
                               parse_for_variables ( $value, 0, $opts );

   # Any variables to substitute ???
   unless ( defined $tag ) {
      return DBUG_RETURN ( $value, $mask_flag );  # nope ...
   }

   my $output = $value;

   my %encrypt_vars;
   my $encrypt_cnt = 0;
   my $encrypt_fmt = "_"x50 . "ENCRYPT_%02d" . "-"x50;

   my ($lv, $rv) = ( convert_to_regexp_string ($opts->{variable_left}),
                     convert_to_regexp_string ($opts->{variable_right}) );

   # While there are still variables to process ...
   while ( defined $tag ) {
      my ( $val, $mask );
      my $do_mod_lookup = 0;    # Very rarely set to true ...

      # ${tag} and ${mod_tag} will never have the same value ...
      # ${mod_tag} will amost always be undefinded.
      # If both are defined, we'll almost always end up using ${mod_tag} as
      # the real variable to expand!  But we check to be sure 1st.

      ( $val, $mask ) = $config->lookup_one_variable ( $tag );

      # It's extreemly rare to have this "if statement" evalate to true ...
      if ( (! defined $val) && defined $mod_tag ) {
         ( $val, $mask ) = $config->lookup_one_variable ( $mod_tag );

         # -----------------------------------------------------------------
         # If we're using variable modifiers, it doesn't matter if the
         # varible exists or not.  The modifier gets evaluated!
         # So checking if the undefined $mod_tag needs to be masked or not ...
         # -----------------------------------------------------------------
         unless ( defined $val ) {
            $mask = should_we_hide_sensitive_data ( $mod_tag );
         }

         $do_mod_lookup = 1;    # Yes, apply the modifiers!
      }

      # Use a place holder if the variable references data that is still encrypted.
      if ( $mask == -1 ) {
         $mask_flag = -1;
         $val = sprintf ($encrypt_fmt, ++$encrypt_cnt);

         # If the place holder contains variable anchors abort the substitutions.
         last  if ( $val =~ m/${lv}/ || $val =~ m/${rv}/ );

         $encrypt_vars{$val} = $tag;
         $do_mod_lookup = 0;
      }

      # Doing some accounting to make sure any sensitive data doesn't 
      # show up in the fish logs from now on.
      if ( $mask && ! $mask_flag ) {
         $mask_flag = 1;
         DBUG_PAUSE ();
         DBUG_MASK ( 0 );
      }

      if ( $do_mod_lookup ) {
         my $m;
         ($val, $m) = apply_modifier ( $config, $val, $mod_tag, $mod_opt, $mod_val, $file );
         if ( $m == -2 ) {
            # The name of the variable changed & points to an encrypted value.
            $val = $opts->{variable_left} . ${val} . $opts->{variable_right};
         } elsif ( $m && ! $mask_flag ) {
            $mask_flag = 1;
            DBUG_PAUSE ();
            DBUG_MASK ( 0 );
         }
      }

      # Rebuild the output string so we can look for more variables ...
      if ( defined $val ) {
         $output = $left . $val . $right;
      } else {
         $output = $left . $right;
      }

      # Get the next variable to evaluate ...
      ($left, $tag, $right, $cmt_flag, $mod_tag, $mod_opt, $mod_val, $ot) =
                               parse_for_variables ( $output, 0, $opts );
   }  # End while ( defined $tag ) loop ...


   # Restore all place holders back into the output string with the
   # proper variable name.  Have to assume still sensitive even if
   # all the placeholders drop out.  Since can't tell what else may
   # have triggered it.
   if ( $mask_flag == -1 ) {
      $mask_flag = 1;     # Mark sensitive ...
      foreach ( keys %encrypt_vars ) {
         my $val = $opts->{variable_left} . $encrypt_vars{$_} . $opts->{variable_right};
         $mask_flag = -1  if ( $output =~ s/$_/$val/ );
      }
   }

   # Did the variable substitution result in the need to trim things?
   if ( $trim_flag ) {
      $output =~ s/^\s+//;
      $output =~ s/\s+$//;
   }

   DBUG_RETURN ( $output, $mask_flag );
}


# ==============================================================

=item ($v[, $s]) = apply_modifier ( $config, $value, $tag, $rule, $sub_rule, $file )

This is a helper method to F<expand_variables>.  Not for public use.

This function takes the rule specified by I<$rule> and applies it against
the I<$value> with assistance from the I<$sub_rule>.

It returns the edited I<value> and whether applying the modifier made it
I<sensitive>. (-1 means it's an encrypted value.  -2 means it's the variable
name that resolves to an encrypted value.  0 - Non-senitive, 1 - Sensitive.)

See L<https://web.archive.org/web/20200309072646/https://wiki.bash-hackers.org/syntax/pe>
for information on how this can work.  This module supports most of the
parameter expansions listed there except for those dealing with arrays.  Other
modifier rules may be added upon request.

=cut

# NOTE1: Fish has already been paused if $tag is sensitive.  Since this method
#        has no idea if the current tag is sensitive or not.

# NOTE2: But still need to mask the return value if referencing sensitive data
#        in case the original $tag wasn't sensitive.  So in most cases it will
#        return not-sensitive even if fish has already been paused!
#
# NOTE3: If sensitive/mask is -1, it's sensitive and not decrypted.  In this
#        case the returned value is the tag's name, not it's value!

sub apply_modifier
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg     = shift;
   my $value   = shift;    # The value for ${mod_tag} ...
   my $mod_tag = shift;    # The tag to apply the rule against!
   my $mod_opt = shift;    # The rule ...
   my $mod_val = shift;    # The sub-rule ...
   my $file    = shift;    # The file the tag's from.

   my $alt_val = (defined $value) ? $value : "";

   # The values to return ...
   my $output;

   # Values: 0 - Normal non-sensitive return value (99.9% of the time)
   #         1 - Sensitive return value.
   #        -1 - Return value is encrypted.
   #        -2 - Return value is variable name of encrypted value.
   my $mask = 0;

   # If looking for a default value ...
   if ( ( $mod_opt eq ":+"        && $alt_val ne "" ) ||
        ( $mod_opt =~ m/^:[-=?]$/ && $alt_val eq "" ) ||
        ( $mod_opt eq "+"         && defined $value ) ||
        ( $mod_opt =~ m/^[-=?]$/  && ! defined $value ) ) {
      $output = $mod_val;        # Now uses this value as it's default!

      if ( $mod_opt eq ":=" || $mod_opt eq "=" ) {
         # The variable either doesn't exist or it resolved to "".
         # This variant rule says to also set the variable to this value!
         $cfg->_base_set ( $mod_tag, $output, $file );

      } elsif ( $mod_opt eq ":?" || $mod_opt eq "?" ) {
         # In shell scripts, ":?" would cause your script to die with the
         # default value as the error message if your var had no value.
         # Repeating that logic here.
         my $msg = "Encounterd undefined variable ($mod_tag) using shell modifier ${mod_opt}";
         $msg .= " in config file: " . basename ($file)  if ( $file ne "" );
         DBUG_PRINT ("MOD", $msg);
         die ( basename ($0) . ": ${mod_tag}: ${output}.\n" );
      }

      DBUG_PRINT ("MOD",
           "The modifier (%s) is overriding the variable with a default value!",
           $mod_opt);

   # Sub-string removal ...
   } elsif ( $mod_opt eq "##" || $mod_opt eq "#" ||     # From beginning
             $mod_opt eq "%%" || $mod_opt eq "%" ) {    # From end
      my $greedy  = ( $mod_opt eq "##" || $mod_opt eq "%%" );
      my $leading = ( $mod_opt eq "#"  || $mod_opt eq "##" );
      my $reverse_msg = "";    # Both the message & control flag ...

      $output = $alt_val;

      # Now replace shell script wildcards with their Perl equivalents.
      # A RegExp can't do non-greedy replaces anchored to the end of string!
      # So we need the reverse logic to do so.
      my $regExpVal = convert_to_regexp_modifier ($mod_val);
      $regExpVal =~ s/[?]/./g;         # ? --> .     (any one char)
      if ( $greedy ) {
         $regExpVal =~ s/[*]/.*/g;     # * --> .*    (zero or more greedy chars)
      } elsif ( $leading ) {
         $regExpVal =~ s/[*]/(.*?)/g;  # * --> (.*?) (zero or more chars)
      } elsif ( $regExpVal =~ m/[*]/ ) {
         # Non-Greedy with one or more wild cards present ("*")!
         $leading = 1;                 # Was false before.
         $regExpVal = reverse ($regExpVal);
         $regExpVal =~ s/[*]/(.*?)/g;  # * --> (.*?) (zero or more chars)
         $output = reverse ($output);
         $reverse_msg = "  Reversed for non-greedy strip.";
      }

      if ( $leading ) {
         $regExpVal = '^' . $regExpVal;
      } else {
         # Either greedy trailing or no *'s in trailing regular expression!
         $regExpVal .= '$';
      }

      $output =~ s/${regExpVal}//;     # Strip off the matching values ...
      $output = reverse ($output)  if ( $reverse_msg ne "" );

      DBUG_PRINT ("MOD",
                  "The modifier (%s) converted \"%s\" to \"%s\".%s\nTo trim the value to: %s",
                  $mod_opt, $mod_val, $regExpVal, $reverse_msg, $output);

   } elsif ( $mod_opt eq "LENGTH" ) {
      $output = length ( $alt_val );
      DBUG_PRINT ("MOD", "Setting the length of variable \${#%s} to: %d.",
                  $mod_tag, $output);

   } elsif ( $mod_opt eq "LIST" ) {
      my @lst = $cfg->_find_variables ( $mod_val );
      $output = join (" ", @lst);
      DBUG_PRINT ("MOD", "Getting all varriables starting with %s", $mod_val);

   } elsif ( $mod_opt eq "!" ) {
      ($output, $mask) = $cfg->lookup_one_variable ( $alt_val );
      if ( $mask == -1 ) {
         $mask = -2;    # Indirect reference to encrypted value
         $output = $alt_val;  # Replace with new variable name
      } elsif ( $mask ) {
         DBUG_MASK (0);
      }
      DBUG_PRINT ("MOD", "Indirectly referencing variable %s (%s)", $alt_val, $mask);

   } elsif ( $mod_opt eq "//" ) {
      my ($ptrn, $val) = split ("/", $mod_val);
      $output = $alt_val;
      $output =~ s/${ptrn}/${val}/g;
      DBUG_PRINT ("MOD", "Global replacement in %s", $alt_val);

   } elsif ( $mod_opt eq "/" ) {
      my ($ptrn, $val) = split ("/", $mod_val);
      $output = $alt_val;
      $output =~ s/${ptrn}/${val}/;
      DBUG_PRINT ("MOD", "1st replacement in %s", $alt_val);

   } elsif ( $mod_opt eq ":" ) {
      my ($offset, $length) = split (":", $mod_val);
      if ( defined $length && $length ne "" ) {
         $output = substr ( $alt_val, $offset, $length);
      } else {
         $output = substr ( $alt_val, $offset);
      }
      DBUG_PRINT ("MOD", "Substring (%s)", $output);

   # The 6 case manipulation modifiers ...
   } elsif ( $mod_opt eq "^^" ) {
      $output = uc ($alt_val);
      DBUG_PRINT ("MOD", "Upshift string (%s)", $output);
   } elsif ( $mod_opt eq ",," ) {
      $output = lc ($alt_val);
      DBUG_PRINT ("MOD", "Downshift string (%s)", $output);
   } elsif ( $mod_opt eq "~~" ) {
      $output = $alt_val;
      $output =~ s/([A-Z])|([a-z])/defined $1 ? lc($1) : uc($2)/gex;
      DBUG_PRINT ("MOD", "Reverse case of each char in string (%s)", $output);
   } elsif ( $mod_opt eq "^" ) {
      $output = ucfirst ($alt_val);
      DBUG_PRINT ("MOD", "Upshift 1st char in string (%s)", $output);
   } elsif ( $mod_opt eq "," ) {
      $output = lcfirst ($alt_val);
      DBUG_PRINT ("MOD", "Downshift 1st char in string (%s)", $output);
   } elsif ( $mod_opt eq "~" ) {
      $output = ucfirst ($alt_val);
      $output = lcfirst ($alt_val)   if ( $alt_val eq $output );
      DBUG_PRINT ("MOD", "Reverse case of 1st char in string (%s)", $output);

   } else {
      DBUG_PRINT ("MOD",
                  "The modifier (%s) didn't affect the variable's value!",
                  $mod_opt);
      $output = $value;
   }

   DBUG_RETURN ( $output, $mask );
}


# ==============================================================

=item @ret[0..7] = parse_for_variables ( $value, $ignore_disable_flag, $rOpts )

This is a helper method to F<expand_variables> and B<parse_line>.

This method parses the I<$value> to see if any variables are defined in it
and returns the information about it.  If there is more than one variable
present in the I<$value>, only the 1st variable/tag to evaluate is returned.

By default, a variable is the tag in the I<$value> between B<${> and B<}>, which
can be overriden with other anchor patterns.  See L<Advanced::Config::Options>
for more details on this.

If you've configured the module to ignore variables, it will never find any.
Unless you also set I<$ignore_disable_flag> to a non-zero value.

Returns B<8> values. ( $left, $tag, $right, $cmt, $sub_tag, $sub_opr, $sub_val,
$otag )

All B<8> values will be I<undef> if no variables were found in I<$value>.

Otherwise it returns at least the 1st four values.  Where I<$tag> is the
variable that needs to be looked up.  And the caller can join things back
together as "B<$left . $look_up_value . $right>" after the variable substitution
is done and before this method is called again to locate additional variables in
the resulting new I<$value>.

The 4th value I<$cmt>, will be true/false based on if B<$left> has a comment
symbol in it!  This flag only has meaning to B<parse_line>.  And is terribly
misleading to other users.

Should the I<$tag> definition have one of the supported shell script variable
modifiers embedded inside it, then the I<$tag> will be parsed and the 3 B<sub_*>
return values will be calculated as well.  See
L<http://wiki.bash-hackers.org/syntax/pe> for more details.  Most of the
modifiers listed there are supported except for those dealing with arrays.
See I<apply_modifier> for applying these rules against the returned I<$tag>.
Other modifier rules may be added upon request.

These 3 B<sub_*> return values will always be I<undef> should the variable
left/right anchors be overriden with the same value.  Or if no modifiers
are detected in the tag's name.

If you've configured the module to be case insensitive (option B<tag_case>),
then both I<$tag> and I<$sub_tag> will be shifted to lower case for case
insensitive variable lookups.

Finally there is an 8th return value, I<$otag>, that contains the original
I<$tag> value before it was edited.  Needed by F<parse_line> logic.

=cut

# WARNING: If (${lvar} == ${rvar}), nested variables are not supported.
#        : And neither are variable modifiers. (The sub_* return values.)
#        : So evaluate tags left to right.
#        : If (${lvar} != ${rvar}), nested variables are supported.
#        : So evaluate inner most tags first.  And then left to right.
#
# RETURNS: 8 values. ( $left, $tag, $right, $cmt, $sub_tag, $sub_opr, $sub_val, $otag )
#        : The 3 sub_* vars are usually undef.
#        : But when set, all 3 sub_* vars are set!  And  $tag != $sub_tag.
#
# NOTE 1 : If the 3 sub_* vars are populated, you'd get something like this
#        : for the tag & sub_* vars.
#        : tag     :  "abc:-Default Value" - the ${...} was removed.
#        : sub_tag :  "abc"                - the ${...} & modifier were removed.
#        : sub_opr :  ":-"
#        : sub_val :  "Default Value"
#        : So if the "tag" exists as a variable, the sub_* values are ignored.
#        : But if "tag" doesn't exist as a variable, then we apply the
#        : sub_* rules!
#
# NOTE 2 : If the sub_* vars undef, you'd get something like this without any
#        : modifiers.
#        : tag     :  tag                  - the ${...} was removed.
#
# NOTE 3 : For some alternate variable anchors, the sub_* vars will almost
#        : always be undef.  Since the code base won't allow you to redefine
#        : these modifiers when they conflict with the variable anchors.

sub parse_for_variables
{
   DBUG_ENTER_FUNC ( @_ );
   my $value        = shift;
   my $disable_flag = shift;
   my $opts         = shift;

   my ($left, $s1, $tag, $s2, $right, $otag);
   my $cmt_flg = 0;
   my ($sub_tag, $sub_opr, $sub_val, $sub_extra);

   if ( $opts->{disable_variables} && (! $disable_flag) ) {
      DBUG_PRINT ("INFO", "Variable substitution has been disabled.");
      return DBUG_RETURN ( $left, $tag, $right, $cmt_flg,
                           $sub_tag, $sub_opr, $sub_val, $otag );
   }

   my $lvar = convert_to_regexp_string ($opts->{variable_left}, 1);
   my $rvar = convert_to_regexp_string ($opts->{variable_right}, 1);

   # Break up the value into it's component parts.  (Non-greedy RegExpr)
   if ( $value =~ m/(^.*?)(${lvar})(.*?)(${rvar})(.*$)/ ) {
      ($left, $s1, $tag, $s2, $right) = ($1, $2, $3, $4, $5);
      $otag = $tag;

      # Did a comment symbol apear before the 1st ${lvar} in the line?
      my $cmt_str = convert_to_regexp_string ($opts->{comment}, 1);
      $cmt_flg = 1   if ( $left =~ m/${cmt_str}/ );

      DBUG_PRINT ("XXXX", "%s ===> %s <=== %s -- %d",
                          $left, $tag, $right, $cmt_flg);

      # We know we found the 1st right hand anchor in the string's value.
      # But since variables may be nested, we might not be at the correct
      # left hand anchor.  But at least we know they're going to balance!

      # Check for nested variables ... (trim left side)
      while ( $tag =~ m/(^.*)${lvar}(.*?$)/ ) {
         my ($l, $t) = ($1, $2);
         $left .= $s1 . $l;
         $tag = $t;
      }

      # Strip off leading spaces from the tag's name.
      # No tag may have leading spaces in it.
      # Defering the stripping of trailing spaces until later on purpose!
      $tag =~ s/^\s+//;

      # -----------------------------------------------------------
      # We have a variable!  Now check if there are modifiers
      # in it that we are supporting ...
      # See:  http://wiki.bash-hackers.org/syntax/pe
      # -----------------------------------------------------------

      # The variable modifier tags.  Needed to avoid using the wrong rule.
      # A variable name can use anything except for what's in this list!
      my $not = "[^-:?+#%/\^,~]";

      if ( $lvar eq $rvar ) {
         ;  # No modifiers are supported if the left/right anchors are the same!
            # Since there are too many modifier/anchor pairs that no longer
            # work.  Behaving more like a Windows *.bat file now.

      } elsif ( $opts->{disable_variable_modifiers} ) {
         ;  # Explicitly told not to use this feature.

      # Rule:  :-, :=, :+, -, =, or +
      } elsif ( $tag =~ m/(^${not}+)(:?[-=+])(.+)$/) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, $2, $3);

      # Rule: :? or ?
      } elsif ( $tag =~ m/(^${not}+)(:?[?])(.*)$/) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, $2, $3);
         $sub_val = "Parameter null or not set."  if ( $sub_val eq "" );

      # Rule:  ##, %%, #, or %
      } elsif ( $tag =~ m/^(${not}+)(##)(.+)$/ ||
                $tag =~ m/^(${not}+)(%%)(.+)$/ ||
                $tag =~ m/^(${not}+)(#)(.+)$/  ||
                $tag =~ m/^(${not}+)(%)(.+)$/ ) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, $2, $3);

      # Rule: Get length of variable's value ...
      } elsif ( $tag =~ m/^#(.+)$/ ) {
         # Using LENGTH for ${#var} opt since "#" is already used above!
         ($sub_tag, $sub_opr, $sub_val) = ($1, "LENGTH", "");
         $sub_tag =~ s/^\s+//;

      # Rule: ${!var*} & ${!var@} ...
      } elsif ( $tag =~ m/^!(.+)[@*]$/ ) {
         # Using LIST for ${!var*} & ${!var@} opts since "!" has another meaning.
         ($sub_tag, $sub_opr, $sub_val) = ($1, "LIST", convert_to_regexp_string ($1));
         $sub_tag =~ s/^\s+//;

      # Rule: Indirect lookup ...
      } elsif ( $tag =~ m/^!(.+)$/ ) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, "!", "");
         $sub_tag =~ s/^\s+//;

      # Rule: Substitution logic ... ( / vs // )
      # Anchors # or % supported but no RegExp wildcards are.
      } elsif ( $tag =~ m#^(${not}+)(//?)([^/]+)/([^/]*)$# ) {
         ($sub_tag, $sub_opr, $sub_val, $sub_extra) = ($1, $2, $3, $4);
         $sub_val = convert_to_regexp_string ($sub_val);

         if ( $sub_val =~ m/^([#%])(.+)$/ ) {
            $sub_val = $2;
            $sub_val = ( $1 eq "#" ) ? "^${sub_val}/${sub_extra}" : "${sub_val}\$/${sub_extra}";
         } else {
            $sub_val = "${sub_val}/${sub_extra}";
         }
         $sub_val .= "/x";

      # Rule: Another format for the Substitution logic ... ( / vs // )
      } elsif ( $tag =~ m#^(${not}+)(//?)([^/]+)$# ) {
         ($sub_tag, $sub_opr, $sub_val, $sub_extra) = ($1, $2, $3, "");
         $sub_val = convert_to_regexp_string ($sub_val);

         if ( $sub_val =~ m/^([#%])(.+)$/ ) {
            $sub_val = $2;
            $sub_val = ( $1 eq "#" ) ? "^${sub_val}/${sub_extra}" : "${sub_val}\$/${sub_extra}";
         } else {
            $sub_val = "${sub_val}/${sub_extra}";
         }
         $sub_val .= "/x";

      # Rule: Substring expansion ... ${MSG:OFFSET}
      } elsif ( $tag =~ m#^(${not}+):([0-9]+)$# ||
                $tag =~ m#^(${not}+):\s+(-[0-9]+)$# ||
                $tag =~ m#^(${not}+):[(](-[0-9]+)[)]$# ) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, ":", $2);
         $sub_val .= ":";         # To the end of the string ...

      # Rule: Substring expansion ... ${MSG:OFFSET:LENGTH}
      } elsif ( $tag =~ m#^(${not}+):([0-9]+):(-?[0-9]+)$# ||
                $tag =~ m#^(${not}+):\s+(-[0-9]+):(-?[0-9]+)$# ||
                $tag =~ m#^(${not}+):[(](-[0-9]+)[)]:(-?[0-9]+)$# ) {
         ($sub_tag, $sub_opr, $sub_val, $sub_extra) = ($1, ":", $2, $3);
         $sub_val .= ":${sub_extra}";

      # Rule: Case manipulation ... (6 variants)
      } elsif ( $tag =~ m/^(${not}+)([\^]{1,2})$/ ||
                $tag =~ m/^(${not}+)([,]{1,2})$/  ||
                $tag =~ m/^(${not}+)([~]{1,2})$/ ) {
         ($sub_tag, $sub_opr, $sub_val) = ($1, $2, "");

      } else {
         ;   # No variable modifiers were found!
      }

      # Strip off any trailing spaces from the tag & sub-tag names ...
      $tag =~ s/\s+$//;
      $sub_tag =~ s/\s+$//  if ( defined $sub_tag );
   }    # End "if" a tag/variable was found in ${value} ...

   # Are we using case insensitive tags/variables?
   # If so, all varibles must be in lower case ...
   # Leave $otag alone.
   if ( $opts->{tag_case} ) {
      $tag     = lc ($tag)      if ( defined $tag );
      $sub_tag = lc ($sub_tag)  if ( defined $sub_tag );
   }

   DBUG_RETURN ( $left, $tag, $right, $cmt_flg, $sub_tag, $sub_opr, $sub_val,
                 $otag );
}


# ==============================================================

=item $string = format_section_line ( $name, \%rOpts )

Uses the given I<Read Options Hash> to generate a section string
from I<$name>.

=cut

sub format_section_line
{
   DBUG_ENTER_FUNC ( @_ );
   my $name  = shift;    # The name of the section ...
   my $rOpts = shift;

   DBUG_RETURN ( $rOpts->{section_left} . " ${name} " . $rOpts->{section_right} );
}


# ==============================================================

=item $string = format_tag_value_line ( $cfg, $tag, \%rOpts )

It looks up the B<tag> in the I<$cfg> object, then it uses the given
I<Read Options Hash> options to format a tag/value pair string.

=cut

sub format_tag_value_line
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg   = shift;   # An Advanced::Config object reference.
   my $tag   = shift;
   my $rOpts = shift;

   my ($value, $sensitive) = $cfg->_base_get2 ( $tag, {required => 1} );
   DBUG_MASK (0)  if ( $sensitive );

   # Determine if we're alowed to surround things with quotes ...
   my ($quote_l, $quote_r);    # Assume no!
   if (using_default_quotes ( $rOpts )) {
      if ( $value =~ m/'/ && $value =~ m/"/ ) {
         my $noop;     # No quotes allowed!
      } elsif ( $value !~ m/'/ ) {
         $quote_l = $quote_r = "'";
      } elsif ( $value !~ m/"/ ) {
         $quote_l = $quote_r = '"';
      }

   } elsif ( ! $rOpts->{disable_quotes} ) {
      my ($ql, $qr) = ( convert_to_regexp_string ($rOpts->{quote_left}, 1),
                        convert_to_regexp_string ($rOpts->{quote_right}, 1) );
      unless ( $value =~ m/${ql}/ || $value =~ m/${qr}/ ) {
         $quote_l = $rOpts->{quote_left};
         $quote_r = $rOpts->{quote_right};
      }
   }

   # Do we have to correct for having comments in the value?
   my $cmt = convert_to_regexp_string ($rOpts->{comment}, 1);
   if ( $value =~ m/${cmt}/ ) {
      my $err = "Can't do toString() due to using comments in the value of '${tag}'\n";

      if ( $rOpts->{disable_variables} ) {
         if ( $rOpts->{disable_quotes} ) {
            die ($err, "when you've also disabled both quotes & variables!\n");
         }
         unless ( $quote_l ) {
            die ($err, "when you've disabled variables while there are quotes in the value as well!\n");
         }
      }

      # Convert the comment symbols to the special variable if no quotes are allowed.
      unless ( $quote_l ) {
         my $v = $rOpts->{variable_left} . "shft3" . $rOpts->{variable_right};
         $value =~ s/${cmt}/${v}/g;
      }
   }

   # Surround the value with quotes!
   if ( $quote_l ) {
      $value = ${quote_l} . ${value} . ${quote_r};
   }

   my $line = ${tag} . " " . $rOpts->{assign} . " " . ${value};

   DBUG_RETURN ( $line );
}


# ==============================================================

=item $string = format_encrypt_cmt ( \%rOpts )

Uses the given I<Read Options Hash> to generate a comment suitable for use
in marking a tag/value pair as ready to be encrypted.

=cut

sub format_encrypt_cmt
{
   DBUG_ENTER_FUNC ( @_ );
   my $rOpts = shift;

   DBUG_RETURN ( $rOpts->{comment} . " " . $rOpts->{encrypt_lbl} );
}


# ==============================================================

=item $status = encrypt_config_file_details ( $file, $writeFile, \%rOpts )

This function encrypts all tag values inside the specified confg file that are
marked as ready for encryption and generates a new config file with everything
encrypted.  If a tag/value pair isn't marked as ready for encryption it is left
alone.  By default this label is B<ENCRYPT>.

After a tag's value has been encrypted, the label in the comment is updated
from B<ENCRYPT> to B<DECRYPT> in the new file.

If you are adding new B<ENCRYPT> tags to an existing config file that already
has B<DECRYPT> tags in it, you must use the same encryption related options in
I<%rOpts> as the last time.  Otherwise you won't be able to decrypt all
encrypted values.

This method ignores any request to source in other config files.  You must
encryt each file individually.

It writes the results of the encryption process to I<$writeFile>.

See L<Advanced::Config::Options> for some caveats about this process.

Returns:  B<1> if something was encrypted.  B<-1> if nothing was encrypted.
Otherwise B<0> on error.

=cut

sub encrypt_config_file_details
{
   DBUG_ENTER_FUNC ( @_ );
   my $file    = shift;
   my $scratch = shift;
   my $rOpts   = shift;

   unlink ( $scratch );

   # The labels to search for ...
   my $decrypt_str = convert_to_regexp_string ($rOpts->{decrypt_lbl});
   my $encrypt_str = convert_to_regexp_string ($rOpts->{encrypt_lbl});
   my $hide_str    = convert_to_regexp_string ($rOpts->{hide_lbl});

   my $assign_str  = convert_to_regexp_string ($rOpts->{assign});
   my ($lb, $rb) = ( convert_to_regexp_string ($rOpts->{section_left}),
                     convert_to_regexp_string ($rOpts->{section_right}) );

   # The label separators used when searching for option labels in a comment ...
   my $lbl_sep = '[\s.,$!-()]';

   my $mask = "*"x8;

   DBUG_PRINT ("INFO", "Opening for reading the config file named: %s", $file);

   unless ( open (ENCRYPT, "<", $file) ) {
      return DBUG_RETURN ( croak_helper ($rOpts,
                                         "Unable to open the config file.", 0) );
   }

   DBUG_PRINT ("INFO", "Creating scratch file named: %s", $scratch);
   unless ( open (NEW, ">", $scratch) ) {
      close (ENCRYPT);
      return DBUG_RETURN ( croak_helper ($rOpts,
                                "Unable to create the scratch config file.", 0) );
   }

   # Misuse of this option makes the config file unreadable ...
   if ( $rOpts->{use_utf8} ) {
      binmode (ENCRYPT, "encoding(UTF-8)");
      binmode (NEW,     "encoding(UTF-8)");
   }

   my $errMsg = "Unable to write to the scratch file.";

   my $hide_section = 0;
   my $count = 0;

   while ( <ENCRYPT> ) {
      chomp;
      my $line = $_;

      my ($tv, $ln, $cmt, $lq, $rq) = parse_line ( $line, $rOpts );

      my ($hide, $encrypt) = (0, 0);
      my ($tag,  $value,  $prefix, $t2);
      if ( $tv  ) {
         ($tag, $value, $prefix, $t2) = _split_assign ( $rOpts, $ln );

         if ( $cmt =~ m/(^|${lbl_sep})${encrypt_str}(${lbl_sep}|$)/ ) {
            ($hide, $encrypt) = (1, 1);

         # Don't hide the decrypt string ... (already unreadable)
         } elsif ( $cmt =~ m/(^|${lbl_sep})${hide_str}(${lbl_sep}|$)/ ) {
            $hide = 1;

         } else {
            if ( $hide_section || should_we_hide_sensitive_data ( $tag, 1 ) ) {
               $hide = 1;
            }
         }

      # Is it a section whose contents we need to hide???
      } elsif ( $ln =~ m/^${lb}\s*(.+?)\s*${rb}$/ ) {
         my $section = lc ($1);
         $hide_section = should_we_hide_sensitive_data ( $section, 1 ) ? 1 : 0;
      }

      unless ( $hide ) {
         DBUG_PRINT ("ENCRYPT", $line);
         unless (print NEW $line, "\n") {
            return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
         }
         next;
      }

      # ------------------------------------------------
      # Only Tag/Value pairs get this far ...
      # Either needs to be encrypted, hidden, or both.
      # ------------------------------------------------

      my $ass = ( is_assign_spaces ( $rOpts ) ) ? "" : $rOpts->{assign};
      if ( $cmt ) {
         DBUG_PRINT ("ENCRYPT", "%s%s %s %s     %s %s",
                     $prefix, $tag, $ass, $mask, $rOpts->{comment}, $cmt);
      } else {
         DBUG_PRINT ("ENCRYPT", "%s%s %s %s", $prefix, $tag, $ass, $mask);
      }

      unless ( $encrypt ) {
         unless (print NEW $line, "\n") {
            return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
         }
         next;
      }

      # --------------------------------------------
      # Now let's encrypt the Tag/Value pair ...
      # --------------------------------------------

      ++$count;

      # Save the values we need to change safe to use as RegExp strings.
      my $old_cmt   = convert_to_regexp_string ( $cmt, 1 );
      my $old_value = convert_to_regexp_string ( $value, 1 );

      # Modify the label in the comment ...
      my $lbl = $rOpts->{decrypt_lbl};
      $cmt =~ s/(^|${lbl_sep})${encrypt_str}(${lbl_sep}|$)/$1${lbl}$2/g;

      # Remove any balanced quotes from arround the value ...
      if ( $lq ) {
         $value =~ s/^${lq}//;
         $value =~ s/${rq}$//;
      }

      my ($new_value, $nlq, $nrq);
      $new_value = encrypt_value ( $value, $t2, $rOpts, $file);
      ($new_value, $nlq, $nrq) = _apply_escape_sequences ( $new_value, $rOpts );

      if ( is_assign_spaces ( $rOpts ) ) {
         $line =~ s/^(\s*\S+\s+)${old_value}/$1${nlq}${new_value}${nrq}/;
      } else {
         $line =~ s/(\s*${assign_str}\s*)${old_value}/$1${nlq}${new_value}${nrq}/;
      }
      $line =~ s/${old_cmt}$/${cmt}/;

      unless (print NEW $line, "\n") {
         return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
      }
   }  # End the while ENCRYPT loop ...

   close (ENCRYPT);
   close (NEW);

   my $status = ($count == 0) ? -1 : 1;

   DBUG_RETURN ( $status );
}


# ==============================================================

=item $status = decrypt_config_file_details ( $file, $writeFile, \%rOpts )

This function decrypts all tag values inside the specified confg file that are
marked as encrypted and generates a new file with everyting decrypted.  If a
tag/value pair isn't marked as being encrypted it is left alone.  By default
this label is B<DECRYPT>.

After a tag's value has been decrypted, the label in the comment is updated
from B<DECRYPT> to B<ENCRYPT> in the config file.

For this to work, the encryption related options in I<\%rOpts> must match what
was used in the call to I<encrypt_config_file_details> or the decryption will
fail.

This method ignores any request to source in other config files.  You must
decrypt each file individually.

It writes the results of the decryption process to I<$writeFile>.

See L<Advanced::Config::Options> for some caveats about this process.

Returns:  B<1> if something was decrypted.  B<-1> if nothing was decrypted.
Otherwise B<0> on error.

=cut

sub decrypt_config_file_details
{
   DBUG_ENTER_FUNC ( @_ );
   my $file    = shift;
   my $scratch = shift;
   my $rOpts   = shift;

   unlink ( $scratch );

   # The labels to search for ...
   my $decrypt_str = convert_to_regexp_string ($rOpts->{decrypt_lbl});
   my $encrypt_str = convert_to_regexp_string ($rOpts->{encrypt_lbl});
   my $hide_str    = convert_to_regexp_string ($rOpts->{hide_lbl});

   # The label separators used when searching for option labels in a comment ...
   my $lbl_sep = '[\s.,$!-()]';

   my $assign_str  = convert_to_regexp_string ($rOpts->{assign});
   my ($lb, $rb) = ( convert_to_regexp_string ($rOpts->{section_left}),
                     convert_to_regexp_string ($rOpts->{section_right}) );

   my $mask = "*"x8;

   DBUG_PRINT ("INFO", "Opening for reading the config file named: %s", $file);

   unless ( open (DECRYPT, "<", $file) ) {
      return DBUG_RETURN ( croak_helper ($rOpts,
                                         "Unable to open the config file.", 0) );
   }

   DBUG_PRINT ("INFO", "Creating scratch file named: %s", $scratch);
   unless ( open (NEW, ">", $scratch) ) {
      close (DECRYPT);
      return DBUG_RETURN ( croak_helper ($rOpts,
                                "Unable to create the scratch config file.", 0) );
   }

   # Misuse of this option makes the config file unreadable ...
   if ( $rOpts->{use_utf8} ) {
      binmode (DECRYPT, "encoding(UTF-8)");
      binmode (NEW,     "encoding(UTF-8)");
   }

   my $errMsg = "Unable to write to the scratch file.";

   my $hide_section = 0;
   my $count = 0;

   while ( <DECRYPT> ) {
      chomp;
      my $line = $_;

      my ($tv, $ln, $cmt, $lq, $rq) = parse_line ( $line, $rOpts );

      my ($hide, $decrypt) = (0, 0);
      my ($tag,  $value,  $prefix, $t2);
      if ( $tv ) {
         ($tag, $value, $prefix, $t2) = _split_assign ( $rOpts, $ln );

         if ( $cmt =~ m/(^|${lbl_sep})${decrypt_str}(${lbl_sep}|$)/ ) {
            ($hide, $decrypt) = (1, 1);

         } elsif ( $cmt =~ m/(^|${lbl_sep})${encrypt_str}(${lbl_sep}|$)/ ||
                   $cmt =~ m/(^|${lbl_sep})${hide_str}(${lbl_sep}|$)/ ) {
            $hide = 1;

         } else {
            if ( $hide_section || should_we_hide_sensitive_data ( $tag, 1 ) ) {
               $hide = 1;
            }
         }

      # Is it a section whose contents we need to hide???
      } elsif ( $ln =~ m/^${lb}\s*(.+?)\s*${rb}$/ ) {
         my $section = lc ($1);
         $hide_section = should_we_hide_sensitive_data ( $section, 1 ) ? 1 : 0;
      }

      unless ( $hide ) {
         DBUG_PRINT ("DECRYPT", $line);
         unless (print NEW $line, "\n") {
            return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
         }
         next;
      }

      # ------------------------------------------------
      # Only Tag/Value pairs get this far ...
      # Either needs to be decrypted, hidden, or both.
      # ------------------------------------------------

      my $ass = ( is_assign_spaces ( $rOpts ) ) ? "" : $rOpts->{assign};
      if ( $decrypt ) {
         DBUG_PRINT ("DECRYPT", $line);
      } elsif ( $cmt ) {
         DBUG_PRINT ("DECRYPT", "%s%s %s %s     %s %s",
                     $prefix, $tag, $ass, $mask, $rOpts->{comment}, $cmt);
      } else {
         DBUG_PRINT ("DECRYPT", "%s%s %s %s", $prefix, $tag, $ass, $mask);
      }

      unless ( $decrypt ) {
         unless (print NEW $line, "\n") {
            return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
         }
         next;
      }

      # --------------------------------------------
      # Now let's decrypt the tag/value pair ...
      # --------------------------------------------

      ++$count;

      # Save the values we need to change safe to use as RegExp strings.
      my $old_cmt   = convert_to_regexp_string ( $cmt, 1 );
      my $old_value = convert_to_regexp_string ( $value, 1 );

      # Modify the label in the comment ...
      my $lbl = $rOpts->{encrypt_lbl};
      $cmt =~ s/(^|${lbl_sep})${decrypt_str}(${lbl_sep}|$)/$1${lbl}$2/g;

      # Remove any balanced quotes from arround the value ...
      if ( $lq ) {
         $value =~ s/^${lq}//;
         $value =~ s/${rq}$//;
      }

      my ($new_value, $nlq, $nrq, $rlq2, $rrq2) = _reverse_escape_sequences ( $value, $rOpts );
      $new_value = decrypt_value ( $new_value, $t2, $rOpts, $file);

      if ( $nlq ) {
         if ( $new_value =~ m/${rlq2}/ || $new_value =~ m/${rrq2}/ ) {
            $nlq = $nrq = "";   # Balanced quotes are not supported for this value!
         }
      }

      if ( is_assign_spaces ( $rOpts ) ) {
         $line =~ s/^(\s*\S+\s+)${old_value}/$1${nlq}${new_value}${nrq}/;
      } else {
         $line =~ s/(\s*${assign_str}\s*)${old_value}/$1${nlq}${new_value}${nrq}/;
      }
      $line =~ s/${old_cmt}$/${cmt}/;

      unless (print NEW $line, "\n") {
         return DBUG_RETURN ( croak_helper ($rOpts, $errMsg, 0) );
      }
   }  # End the while ENCRYPT loop ...

   close (ENCRYPT);
   close (NEW);

   my $status = ($count == 0) ? -1 : 1;

   DBUG_RETURN ( $status );
}


# ==============================================================

=item $value = encrypt_value ($value, $tag, $rOpts, $file)

Takes the I<$value> and encrypts it using the other B<3> args as part of the
encryption key.  To successfully decrypt it again you must pass the same B<3>
values for these args to the I<decrypt_value()> call.

See L<Advanced::Config::Options> for some caveats about this process.

=cut

sub encrypt_value
{
   DBUG_MASK_NEXT_FUNC_CALL (0);    # Masks ${value} ...
   DBUG_ENTER_FUNC ( @_ );
   my $value = shift;     # In clear text ...
   my $tag   = shift;
   my $rOpts = shift;
   my $file  = shift;

   # Using the file or the alias?
   my $alias = basename ( ( $rOpts->{alias} ) ? $rOpts->{alias} : $file );

   # ---------------------------------------------------------------
   # Call the custom encryption call back method ...
   # ---------------------------------------------------------------
   if ( exists $rOpts->{encrypt_cb} && ref ( $rOpts->{encrypt_cb} ) eq "CODE" ) {
      $value = $rOpts->{encrypt_cb}->( 1, $tag, $value, $alias, $rOpts->{encrypt_cb_opts} );
   }

   # ---------------------------------------------------------------
   # Pad the value out to a minimum lenth ...
   # ---------------------------------------------------------------
   my $len1 = length ($value);
   my $len2 = length ($tag);
   my $len = ($len1 > $len2) ? $len1 : $len2;
   my $len3 = length ($rOpts->{pass_phrase});
   $len = ( $len > $len3) ? $len : $len3;

   # Enforce a minimum length for the value ... (will always end in spaces)
   $len = ($len < 12) ? 15 : ($len + 3);
   $value = sprintf ("%-*s", $len, $value . "|");

   # ---------------------------------------------------------------
   # Encrypt the value via this module ...
   # ---------------------------------------------------------------
   $value = _encrypt ( $value, $rOpts->{pass_phrase}, $tag, $alias, $rOpts->{encrypt_by_user} );

   DBUG_RETURN ( $value );
}

# ==============================================================

=item $value = decrypt_value ($value, $tag, $rOpts, $file)

Takes the I<$value> and decrypts it using the other B<3> args as part of the
decryption key.  To successfully decrypt it the values for these B<3> args
must match what was passed to I<encryption_value()> when the value was
originially encrypted.

See L<Advanced::Config::Options> for some caveats about this process.

=cut

sub decrypt_value
{
   DBUG_ENTER_FUNC ( @_ );
   my $value = shift;     # It's encrypted ...
   my $tag   = shift;
   my $rOpts = shift;
   my $file  = shift;

   DBUG_MASK (0);    # Mask the return value ... It's sensitive by definition!

   # Using the file or the alias?
   my $alias = basename ( ( $rOpts->{alias} ) ? $rOpts->{alias} : $file );

   # ---------------------------------------------------------------
   # Decrypt the value via this module ...
   # ---------------------------------------------------------------
   $value = _encrypt ( $value, $rOpts->{pass_phrase}, $tag, $alias, $rOpts->{encrypt_by_user} );
   $value =~ s/\|[\s\0]+$//;     # Trim any trailing spaces or NULL chars.

   # ---------------------------------------------------------------
   # Call the custom decryption call back method ...
   # ---------------------------------------------------------------
   if ( exists $rOpts->{encrypt_cb} && ref ( $rOpts->{encrypt_cb} ) eq "CODE" ) {
      $value = $rOpts->{encrypt_cb}->( 0, $tag, $value, $alias, $rOpts->{encrypt_cb_opts} );
   }

   DBUG_RETURN ( $value );
}


# ==============================================================
# Before writing an encrypted value to a config file, all problem
# character sequences must be converted into escape sequences.  So
# that when the encrypted value is read back in again it won't cause
# parsing issues.
sub _apply_escape_sequences
{
   DBUG_ENTER_FUNC ( @_ );
   my $value = shift;       # Encrypted ...
   my $rOpts = shift;

   my ( $lq, $rq ) =  _get_encryption_quotes ( $rOpts );

   # Strings to use in the regular expressions ...
   my ($l_quote, $r_quote) = ( convert_to_regexp_string ($lq, 1),
                               convert_to_regexp_string ($rq, 1) );
   my $cmt = convert_to_regexp_string ($rOpts->{comment}, 1);
   my $var = convert_to_regexp_string ($rOpts->{variable_left}, 1);

   # ---------------------------------------------------------------
   # Replace any problem char for values with escape sequences ...
   # ---------------------------------------------------------------
   $value =~ s/\\/\\z/sg;      # Done so we can use \ as an escape sequence.
   $value =~ s/\n/\\n/sg;      # Remove embedded "\n" so no mult-lines.
   $value =~ s/%/\\p/sg;       # So calls to DBUG_PRINT won't barf ...
   $value =~ s/${cmt}/\\3/sg;  # Don't want any comment chars ...
   if ( $rq ) {
      $value =~ s/${l_quote}/\\q/sg;
      $value =~ s/${r_quote}/\\Q/sg;
   }
   $value =~ s/${var}/\\v/sg;  # So nothing looks like a variable ...
   $value =~ s/\0/\\0/sg;      # So no embedded null chars ...

   DBUG_RETURN ( $value, $lq, $rq );
}


# ==============================================================
# When an encrypted value is read in from the config file, all escape
# secuences need to be removed before the value can be decrypted.
# These escape sequences were required to avoid parsing issues when
# handling encrypted values.
sub _reverse_escape_sequences
{
   DBUG_ENTER_FUNC ( @_ );
   my $value = shift;       # Encrypted with escape sequences ...
   my $rOpts = shift;

   my ( $lq, $rq ) =  _get_encryption_quotes ( $rOpts );
   my $cmt = $rOpts->{comment};
   my $var = $rOpts->{variable_left};

   # Strings to use in the regular expressions ... (by caller)
   my ($l_quote, $r_quote) = ( convert_to_regexp_string ($lq, 1),
                               convert_to_regexp_string ($rq, 1) );

   # ---------------------------------------------------------------
   # Replace the escape sequences to get back the problem chars ...
   # Done in reverse order of what was done in: _apply_escape_sequences()!
   # ---------------------------------------------------------------
   $value =~ s/\\0/\0/sg;
   $value =~ s/\\v/${var}/sg;
   if ( $rq ) {
      $value =~ s/\\Q/${rq}/sg;
      $value =~ s/\\q/${lq}/sg;
   }
   $value =~ s/\\3/${cmt}/sg;
   $value =~ s/\\p/%/sg;
   $value =~ s/\\n/\n/sg;
   $value =~ s/\\z/\\/sg;

   DBUG_RETURN ( $value, $lq, $rq, $l_quote, $r_quote );
}


# ==============================================================
sub _get_encryption_quotes
{
   my $rOpts = shift;

   my ($lq, $rq) = ("", "");
   if ( using_default_quotes ( $rOpts ) ) {
      $lq = $rq = "'";     # Chooses ' over " ...
   } elsif ( ! $rOpts->{disable_quotes} ) {
      ($lq, $rq) = (  $rOpts->{quote_left}, $rOpts->{quote_right} );
   }

   return ( $lq, $rq );
}


# ==============================================================
# USAGE:  $val = _encrypt ($value, $pass_code, $tag, $alias, $usr_flg)
#
# Both encrypts & decrypts the value ...

sub _encrypt
{
  DBUG_MASK_NEXT_FUNC_CALL (0, 1); # Masks ${val} & ${pass} ...
  DBUG_ENTER_FUNC ( @_ );
  my $val     = shift;             # Sensitive ... if not already encrypted.
  my $pass    = shift;             # Very, very sensitive ... always clear text.
  my $tag     = shift;
  my $alias   = shift;
  my $usr_flg = shift;             # 0 - no, 1 - yes
  DBUG_MASK (0);

  # Verify lengths are different to prevent repeatable patterns.
  if ( length ( $tag ) == length ( $alias ) ) {
     $tag .= "|";      # Make different lengths
  }

  my $len = length ( $val );

  my $key1 = _make_key ( $tag, $len );
  my $key2 = _make_key ( $alias, $len );
  my $res = $key1 ^ $key2;

  if ( $pass ) {
     my $key3 = _make_key ( $pass, $len );
     $res = $res ^ $key3;
  }

  if ( $usr_flg ) {
     my $key4 = _make_key ( $gUserName, $len );
     $res = $res ^ $key4;
  }

  unless ( $val =~ m/[^\x00-\xff]/ ) {
     $res = $res ^ $val;   # ascii ...
  } else {
     # Unicode version of ($res ^ $val) ...
     $res = _bitwise_exclusive_or ( $res, $val );
  }

  DBUG_RETURN ( $res );    # Sometimes encrypted and other times not!
}

# ==============================================================
sub _bitwise_exclusive_or
{
   DBUG_ENTER_FUNC ();   # Dropped @_ on purpose, always sensitive
   my $mask    = shift;
   my $unicode = shift;
   DBUG_MASK (0);

   my @m = unpack ("C*", $mask);
   my @u = unpack ("U*", $unicode);

   my @ans;
   foreach ( 0..$#u ) {
      $ans[$_] = $m[$_] ^ $u[$_];   # Exclusive or of 2 integers still supported.
   }

   DBUG_RETURN ( pack ("U*", @ans) );
}

# ==============================================================
# USAGE: $key = _make_key ($target, $len);

sub _make_key
{
   DBUG_MASK_NEXT_FUNC_CALL (0);    # Masks ${target} ...
   DBUG_ENTER_FUNC ( @_ );
   my $target = shift;     # May be ascii or unicode ...
   my $len    = shift;
   DBUG_MASK (0);

   my $phrase;
   unless ( $target =~ m/[^\x00-\xff]/ ) {
      # Normal text ... (ascii)
      $phrase = $target . pack ("C*", reverse (unpack ("C*", $target)));

   } else {
      # Unicode strings (utf8 / Wide Chars)
      # Strip off the upper byte from each unicode char ...
      my @ans = map { $_ % 0x100 } unpack ("U*", $target);
      $phrase = pack ("C*", @ans) . pack ("C*", reverse (@ans));
   }

   my $key = $phrase;
   while ( length ( $key ) < $len ) {
      $key .= $phrase;
   }

   $key = substr ( $key, 0, $len );     # Truncate it to fit ...

   DBUG_RETURN ( $key );    # Always an ascii string ...
}

# ==============================================================

=back

=head1 COPYRIGHT

Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Advanced::Config> - The main user of this module.  It defines the Config object.

L<Advanced::Config::Options> - Handles the configuration of the Config module.

L<Advanced::Config::Date> - Handles date parsing for get_date().

L<Advanced::Config::Examples> - Provides some sample config files and commentary.

=cut

# ==============================================================
#required if module is included w/ require command;
1;

