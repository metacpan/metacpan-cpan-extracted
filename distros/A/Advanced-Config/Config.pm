###
### Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.
###
### Module:  Advanced::Config

=head1 NAME

Advanced::Config - Perl module reads configuation files from various sources.

=head1 SYNOPSIS

 use Advanced::Config;
    or 
 require Advanced::Config;

=head1 DESCRIPTION

F<Advanced::Config> is an enhanced implementation of a config file manager
that allows you to manage almost any config file as a true object with a common
interface.  It allows you to configure for almost any look and feel inside your
config files.

You will need to create one object per configuration file that you wish to
manipulate.  And any updates you make to the object in memory will not make it
back into the config file itself.

It also has options for detecting if the data in the config file has been
updated since you loaded it into memory and allows you to refresh the
configuration object.  So that your long running programs never have to execute
against stale configuration data.

This module supports config file features such as variable substitution,
sourcing in other config files, comments, breaking your configuration data
up into sections, encryping/decrypting individual tag values, and even more ...

So feel free to experiment with this module on the best way to access your
data in your config files.  And never have to worry about having multiple
versions of your config files again for Production vs Development vs QA vs
different OS, etc.

=head1 NOTES ON FUNCTIONS WITH MULTIPLE RETURN VALUES

Whenever a function in this module or one if it's helper modules says it can
have multiple return values and you ask for them in scalar mode, it only returns
the first return value.  The other return values are tossed.  Not the count of
return values as some might expect.

This is because in most cases these secondary return values only have meaning
in specical cases.  So usually there's no need to grab them unless you plan on
using them.

For a list of the related helper modules see the B<SEE ALSO> section at the
end of this POD.  These helper modules are not intended for general use.

=cut 

# ---------------------------------------------------------------

package Advanced::Config;

use strict;
use warnings;

# The version of this module!
our $VERSION = "1.11";

use File::Basename;
use File::Copy;
use Sys::Hostname;
use File::Spec;
use Perl::OSType ':all';
use Cwd 'abs_path';

use Advanced::Config::Options;
use Advanced::Config::Reader;
use Fred::Fish::DBUG 2.09 qw / on_if_set  ADVANCED_CONFIG_FISH /;

# The name of the default section ... (even if no sections are defined!)
use constant DEFAULT_SECTION => Advanced::Config::Options::DEFAULT_SECTION_NAME;

# Should only be modifiable via BEGIN ...
my %begin_special_vars;
my $secret_tag;
my $fish_tag;


# This begin block initializes the special variables used
# for "rule 5" & "rule 6" in lookup_one_variable()
# and _find_variables()!
BEGIN
{
   DBUG_ENTER_FUNC ();

   # -----------------------------------------------
   # These are the "Rule 5" special perl varibles.
   # Done this way to avoid having to support
   # indirect "eval" logic.
   # -----------------------------------------------
   $begin_special_vars{'0'}  = ($0 eq "-e") ? "perl" : $0;
   $begin_special_vars{'$'}  = $$;
   $begin_special_vars{'^O'} = $^O;   # MSWin32, aix, etc ...

   # ---------------------------------------------
   # Start of the "rule 6" initialization ...
   # ---------------------------------------------
   $begin_special_vars{PID}      = $$;
   $begin_special_vars{user}     = Advanced::Config::Options::_get_user_id ();
   $begin_special_vars{hostname} = hostname ();
   $begin_special_vars{flavor}   = os_type ();  # Windows, Unix, etc...

   # ---------------------------------------------
   # Get the Parent PID if available ... (PPID)
   # ---------------------------------------------
   eval {
      $begin_special_vars{PPID} = getppid ();
   };
   if ( $@ ) {
      DBUG_PRINT ("INFO", "Cheating to get the PPID.  It may be wrong!");
      # We can't easily get the parent process id for Windows.
      # So we're going to cheat a bit.  We'll ask if any parent
      # or grandparent process used this module before and call it
      # the parent process!
      $secret_tag = "_ADVANCED_CONFIG_PPID_";

      if ( $ENV{$secret_tag} ) {
         $begin_special_vars{PPID} = $ENV{$secret_tag};
      } else {
         $begin_special_vars{PPID} = -1;    # Can't figure out the PPID.
      }
      $ENV{$secret_tag} = $$;
   }

   # -----------------------------------------------------
   # Calculate the separator used by the current OS
   # when constructing a directory tree. (sep)
   # -----------------------------------------------------
   my ($a, $b) = ("one", "two");
   my $p = File::Spec->catfile ($a, $b);
   if ( $p =~ m/^${a}(.+)${b}$/ ) {
      $begin_special_vars{sep} = $1;    # We have it!
   } else {
      warn "Unknown separator for current OS!\n";
      $begin_special_vars{sep} = "";    # Unknown value!
   }

   # -----------------------------------------------------
   # Calculate the program name minus any path info or
   # certain file extensions.
   # -----------------------------------------------------
   if ( $0 eq "-e" ) {
      $begin_special_vars{program} = "perl";    # Perl add hock script!
   } else {
      $begin_special_vars{program} = basename ($0);

      # Remove only certain file extensions from the program's name!
      if ( $begin_special_vars{program} =~ m/^(.+)[.]([^.]*)$/ ) {
         my ($f, $ext) = ($1, lc ($2));
         if ( $ext eq "" || $ext eq "pl" || $ext eq "t" ) {
            $begin_special_vars{program} = $f;
         }
      }
   }

   DBUG_VOID_RETURN ();
}

# Called automatically when this module goes out of scope ...
# At times this might be called before DESTROY ...
END
{
   DBUG_ENTER_FUNC ();
   DBUG_VOID_RETURN ();
}

# Called automatically when the current instance of module goes out of scope.
# Only called if new() was successfull!
# At times this might be called after END ...
DESTROY
{
   DBUG_ENTER_FUNC ();
   DBUG_VOID_RETURN ();
}


# ----------------------------------------------------------------------------
# Helper functions that won't appear in the POD.
# They will all start with "_" in their name.
# But they are still considered members of the object.
# These functions can appear throughout this file.
# ----------------------------------------------------------------------------

# Using Cwd's abs_path() bombs on Windows if the file doesn't exist!
# So I'm doing this conversion myself.
# This function doesn't care if the file actually exists or not!
# It just converts a relative path into an absolute path!
sub _fix_path
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;
   my $file = shift || "";
   my $dir  = shift;         # If not provided uses current directory!

   if ( $file ) {
      # Convert relative paths to absolute path names.
      # Removes internal ".", but not ".." in the path info ...
      # It also doesn't resolve symbolic links.
      unless ( File::Spec->file_name_is_absolute ( $file ) ) {
         if ( $dir ) {
            $file = File::Spec->rel2abs ( File::Spec->catfile ( $dir, $file ) );
         } else {
            $file = File::Spec->rel2abs ( $file );
         }
      }

      # Now let's remove any relative path info (..) from the new absolute path.
      # Still not resolving any symbolic links on purpose!
      # I don't agree with File::Spec->canonpath()'s reasoning for not doing it
      # that way.  So I need to resolve it myself.
      my @parts = File::Spec->splitdir ( $file );
      foreach ( 1..$#parts ) {
         if ( $parts[$_] eq ".." ) {
            $parts[$_] = $parts[$_ - 1] = "";
         }
      }

      # It's smart enough to ignore "" in the array!
      $file = File::Spec->catdir (@parts);
   }

   DBUG_RETURN ( $file );
}


# ----------------------------------------------------------------------------
# Start of the exposed methods in the module ...
# ----------------------------------------------------------------------------

=head1 CONSTRUCTORS

To use this module, you must call C<B<new>()> to create the I<Advanced::Config>
object you wish to work with.  All it does is create an empty object for you to
reference and returns the C<Advanced::Config> object created.  Once you
have this object reference you are good to go!  You can either load an existing
config file into memory or dynamically build your own virtual config file or
even do a mixure of both!

=over

=item $cfg = Advanced::Config->new( [$filename[, \%read_opts[, \%get_opts[, \%date_opts]]]] );

It takes four arguments, any of which can be omitted or B<undef> during object
creation!

F<$filename> is the optional name of the config file to read in.  It can be a
relative path.  The absolute path to it will be calcuated for you if a relative
path was given.

F<\%read_opts> is an optional hash reference that controls the default parsing
of the config file as it's being read into memory.  Feel free to leave as
B<undef> if you're satisfied with this module's default behaviour.

F<\%get_opts> is an optional hash reference that defines the default behaviour
when this module looks something up in the config file.  Feel free to leave as
B<undef> if you're satisfied with this module's default behaviour.

F<\%date_opts> is an optional hash reference that defines the default formatting
of the special date variables.  Feel free to leave as B<undef> if you're
satisfied with the default formatting rules.

See the POD under L<Advanced::Config::Options> for more details on what options
these hash references support!  Look under the S<I<The Read Options>>,
S<I<The Get Options>>, and S<I<The Date Formatting Options>> sections of the
POD.

It returns the I<Advanced::Config> object created.

Here's a few examples:

  # Sets up an empty object.
  $cfg = Advanced::Config->new();

  # Just specifies the config file to use ...
  $cfg = Advanced::Config->new("MyFile.cfg");

  # Overrides some of the default featurs of the module ...
  $cfg = Advanced::Config->new("MyFile.cfg",
                               { "assign" => ":=", "comment" => ";" },
                               { "required" => 1 },
                               { "date_language" => "German" } );

=cut

sub new
{
   DBUG_ENTER_FUNC ( @_ );
   my $prototype = shift;;
   my $filename  = shift;
   my $read_opts = shift;     # A hash ref of "read" options ...
   my $get_opts  = shift;     # Another hash ref of "get" options ...
   my $date_opts = shift;     # Another hash ref of "date" formatting options ...

   my $class = ref ( $prototype ) || $prototype;
   my $self = {};

   # Create an empty object ...
   bless ( $self, $class );

   # Creating a new object ... (The main section)
   my %control;

   # Initialize what options were selected ...
   $control{filename}  = $self->_fix_path ($filename);
   $control{read_opts} = get_read_opts ( $read_opts );
   $control{get_opts}  = get_get_opts ( $get_opts );
   $control{date_opts} = get_date_opts ( $date_opts );

   my ( %dates, %empty, %mods, %ropts, %rec, @lst );

   # Special Date Variables ...
   set_special_date_vars ($control{date_opts}, \%dates);
   $control{DATES}     = \%dates;
   $control{DATE_USED} = 0;

   # Environment variables referenced ...
   $control{ENV} = \%empty;

   # Timestamps & options used for each config file loaded into memory ...
   # Controls the refesh logic.
   $control{REFRESH_MODIFY_TIME} = \%mods;
   $control{REFRESH_READ_OPTIONS} = \%ropts;

   # Used to detect recursion ...
   $control{RECURSION} = \%rec;

   # Used to detect recursion ...
   $control{MERGE} = \@lst;

   # The count for sensitive entries ...
   $control{SENSITIVE_CNT} = sensitive_cnt ();

   # Assume not allowing utf8/Unicode/Wide Char dates ...
   # Or inside the config file itself.
   $control{ALLOW_UTF8} = 0;

   # Controls the behaviour of this module.
   # Only exists in the parent object.
   $self->{CONTROL} = \%control;

   my $key = $self->{SECTION_NAME} = DEFAULT_SECTION;

   my %sections;
   $sections{$key} = $self;
   $self->{SECTIONS} = \%sections;

   # Holds all the tag data for the main section in the config file.
   my %data;
   $self->{DATA} = \%data;

   # Is the data all sensitive?
   $self->{SENSITIVE_SECTION} = 0;   # No for the default section ...

   DBUG_RETURN ( $self );
}

# Only called by Advanced::Config::Reader::read_config() ...
# So not exposed in the POD!
# Didn't rely on read option 'use_utf8' since in many cases
# the option is misleading or just plain wrong!
sub _allow_utf8
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;

   # Tells calls to Advanced::Config::Options::apply_get_rules() that
   # it's ok to use Wide Char Languages like Greek.
   my $pcfg = $self->{PARENT} || $self;
   $pcfg->{CONTROL}->{ALLOW_UTF8} = 1;

   DBUG_VOID_RETURN ();
}

# This private method preps for a clean refresh of the objects contents.
# Kept after the consructor so I can remember to add any new hashes to
# the list below.
sub _wipe_internal_data
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;
   my $file = shift;    # The main config file

   # Wiping the main section automatically wipes everything else ...
   $self = $self->{PARENT} || $self;

   my ( %env, %mods, %rOpts, %rec, @lst, %sect, %data );

   my $key = DEFAULT_SECTION;
   $sect{$key} = $self;

   $self->{CONTROL}->{filename}             = $file;
   $self->{CONTROL}->{ENV}                  = \%env;
   $self->{CONTROL}->{REFRESH_MODIFY_TIME}  = \%mods;
   $self->{CONTROL}->{REFRESH_READ_OPTIONS} = \%rOpts;
   $self->{CONTROL}->{RECURSION}            = \%rec;
   $self->{CONTROL}->{MERGE}                = \@lst;
   $self->{CONTROL}->{SENSITIVE_CNT}        = sensitive_cnt ();
   $self->{CONTROL}->{ALLOW_UTF8}           = 0;

   $self->{SECTIONS} = \%sect;
   $self->{DATA}     = \%data;

   $self->{SENSITIVE_SECTION} = 0;    # Not a sensitive section name!

   DBUG_VOID_RETURN ();
}


#######################################

# =item $cfg = Advanced::Config->new_section ( $cfg_obj, $section );

# This special case constructor creates a new B<Advanced::Config> object and
# relates it to the given I<$cfg_obj> as a new section named I<$section>.

# It will call die if I<$cfg_obj> is not a valid B<Advanced::Config> object or
# the I<$section> is missing or already in use.

# Returns a reference to this new object.

# =cut

# Stopped exposing to public on 12/30/2019 ... but still used internally.
# In most cases 'create_section' should be called instead!
sub new_section
{
   DBUG_ENTER_FUNC ( @_ );
   my $prototype = shift;;
   my $parent    = shift;
   my $section   = shift;

   my $class = ref ( $prototype ) || $prototype;
   my $self  = {};

   # Create an empty object ...
   bless ( $self, $class );

   if ( ref ( $parent ) ne __PACKAGE__ ) {
      die ("You must provide an ", __PACKAGE__, " object as an argument!\n");
   }

   # Make sure it's really the parent object  ...
   $parent = $parent->{PARENT} || $parent;

   # Trim so we can check if unique ...
   if ( $section ) {
      $section =~ s/^\s+//;   $section =~ s/\s+$//;
      $section = lc ($section);
   }

   unless ( $section ) {
      die ("You must provide a section name to use this constructor.\n");
   }

   # Creating a new section for the parent object ...
   if ( exists $parent->{SECTIONS}->{$section} ) {
      die ("Section \"${section}\" already exists!\n");
   }

   # Links the parent & child objects together ...
   $parent->{SECTIONS}->{$section} = $self;
   $self->{SECTION_NAME} = $section;
   $self->{PARENT} = $parent;

   # Holds all the tag data for this section in the config file.
   my %data;
   $self->{DATA} = \%data;

   # Does this section have a sinsitive name?
   # If so, all tags in this section are sensitive!
   $self->{SENSITIVE_SECTION} = should_we_hide_sensitive_data ($section, 1);

   DBUG_RETURN ( $self );
}

#######################################

=back

=head1 THE METHODS

Once you have your B<Advanced::Config> object initialized, you can manipulate
your obect in many ways.  You can access individual components of your config
file, modify it's contents, refresh it's contents and even organize it in
different ways.

Here are your exposed methods to help with this manipulation.

=head2 Loading the Config file into memory.

These methods are used to initialize the contents of an B<Advanced::Config>
object.

=over 4

=item $cfg = $cfg->load_config ( [$filename[, %override_read_opts]] );

This method reads the current I<$filename> into memory and converts it into an
object so that you may refrence it's contents.  The I<$filename> must be defined
either here or in the call to B<new()>.

Each time you call this method, it wipes the contents of the object and starts
you from a clean slate again.  Making it safe to call multiple times if needed.

The I<%override_read_opts> options apply just to the current call to
I<load_config> and will be forgotten afterwards.  If you want these options
to persist between calls, set the option via the call to B<new()>.  This
argument can be passed either by value or by reference.  Either way will work.
See L<Advanced::Config::Options> for more details.

On success, it returns a reference to itself so that it can be initialized
separately or as a single unit.

Ex: $cfg = Advanced::Config->new(...)->load_config (...);

On failure it returns I<undef> or calls B<die> if option I<croak> is set!

WARNING: If basename(I<$filename>) is a symbolic link and your config file
contains encrypted data, please review the encryption options about special
considerations.

=cut

sub load_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $self      = shift;
   my $filename  = shift;
   my $read_opts = $_[0];    # Don't pop from the stack yet ...

   $self = $self->{PARENT} || $self;

   # Get the filename to read ...
   if ( $filename ) {
      $filename = $self->_fix_path ($filename);
   } else {
      $filename = $self->{CONTROL}->{filename};
   }

   # Get the read options ...
   my $new_opts;
   if ( ! defined $read_opts ) {
      my %none;
      $new_opts = \%none;
   } else {
      $read_opts = {@_}  if ( ref ($read_opts) ne "HASH" );
      $new_opts = $read_opts;
   }
   $read_opts = get_read_opts ( $read_opts, $self->{CONTROL}->{read_opts} );

   unless ( $filename ) {
      my $msg = "You must provide a file name to load!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   unless ( -f $filename ) {
      my $msg = "No such file or it's unreadable! -- $filename";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   DBUG_PRINT ("READ", "Reading a config file into memory ... %s", $filename);

   unless ( -f $filename && -r _ ) {
      my $msg = "Your config file name doesn't exist or isn't readable.";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   # Behaves diferently based on who calls us ...
   my $c = (caller(1))[3] || "";
   my $by  = __PACKAGE__ . "::merge_config";
   my $by2 = __PACKAGE__ . "::_load_config_with_new_date_opts";
   if ( $c eq $by ) {
      # Manually merging in another config file.
      push (@{$self->{CONTROL}->{MERGE}}, $filename);
   } elsif ( $c eq $by2 ) {
      # Sourcing in a file says to remove these old decryption opts.
      delete $read_opts->{alias}            unless ( $new_opts->{alias} );
      delete $read_opts->{pass_phrase}      unless ( $new_opts->{pass_phrase} );
      delete $read_opts->{encrypt_by_user}  unless ( $new_opts->{encrypt_by_user} );
   } else {
      # Loading the original file ...
      $self->_wipe_internal_data ( $filename );
   }

   # Auto add the alias if it's a symbolic link & there isn't an alias.
   # Otherwise decryption won't work!
   if ( -l $filename && ! $read_opts->{alias} ) {
      $read_opts->{alias} = abs_path( $filename );
   }

   # So refresh logic will work ...
   $self->{CONTROL}->{REFRESH_MODIFY_TIME}->{$filename}  = (stat( $filename ))[9];
   $self->{CONTROL}->{REFRESH_READ_OPTIONS}->{$filename} = get_read_opts ($read_opts);

   # So will auto-clear if die is called!
   local $self->{CONTROL}->{RECURSION}->{$filename} = 1;

   # Temp override of the default read options ...
   local $self->{CONTROL}->{read_opts} = $read_opts;

   unless ( read_config ( $filename, $self ) ) {
      my $msg = "Reading the config file had serious issues!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   DBUG_RETURN ( $self );
}

#######################################

=item $cfg = $cfg->load_string ( $string[, %override_read_opts] );

This method takes the passed I<$string> and treats it's value as the contents of
a config file.  Modifying the I<$string> afterwards will not affect things.  You
can use this as an alternative to F<load_config>.

Each time you call this method, it wipes the contents of the object and starts
you from a clean slate again.  Making it safe to call multiple times if needed.

The I<%override_read_opts> options apply just to the current call to
I<load_string> and will be forgotten afterwards.  If you want these options
to persist between calls, set the option via the call to B<new()>.  This
argument can be passed either by value or by reference.  Either way will work.
See L<Advanced::Config::Options> for more details.

If you plan on decrypting any values in the string, you must use the B<alias>
option in order for them to be successfully decrypted.

On success, it returns a reference to itself so that it can be initialized
separately or as a single unit.

=cut

sub load_string
{
   DBUG_ENTER_FUNC ( @_ );
   my $self      = shift;
   my $string    = shift;    # The string to treat as a config file's contents.
   my $read_opts = $_[0];    # Don't pop from the stack yet ...

   $self = $self->{PARENT} || $self;

   # Get the read options ...
   $read_opts = {@_}  if ( ref ($read_opts) ne "HASH" );
   $read_opts = get_read_opts ( $read_opts, $self->{CONTROL}->{read_opts} );

   unless ( $string ) {
      my $msg = "You must provide a string to use this method!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   # The filename is a reference to the string passed to this method!
   my $filename = \$string;

   # If there's no alias provided, use a default value for it ...
   # There is no filename to use for decryption purposes without it.
   $read_opts->{alias} = "STRING"   unless ( $read_opts->{alias} );

   # Dynamically correct based on type of string ...
   $read_opts->{use_utf8} = ( $string =~ m/[^\x00-\xff]/ ) ? 1 : 0;

   # Behaves diferently based on who calls us ...
   my $c = (caller(1))[3] || "";
   my $by  = __PACKAGE__ . "::merge_string";
   if ( $c eq $by ) {
      # Manually merging in another string as a config file.
      push (@{$self->{CONTROL}->{MERGE}}, $filename);
   } else {
      # Loading the original string ...
      $self->_wipe_internal_data ( $filename );
   }

   # So refresh logic will work ...
   $self->{CONTROL}->{REFRESH_MODIFY_TIME}->{$filename}  = 0;    # No timestamp!
   $self->{CONTROL}->{REFRESH_READ_OPTIONS}->{$filename} = get_read_opts ($read_opts);

   # So will auto-clear if die is called!
   local $self->{CONTROL}->{RECURSION}->{$filename} = 1;

   # Temp override of the default read options ...
   local $self->{CONTROL}->{read_opts} = $read_opts;

   unless ( read_config ( $filename, $self ) ) {
      my $msg = "Reading the config file had serious issues!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   DBUG_RETURN ( $self );
}


#######################################
# No POD on purpose ...
# For use by Advanced::Config::Reader only.
# Purpose is to allow source_file() a way to modify the date options.

sub _load_config_with_new_date_opts
{
   DBUG_ENTER_FUNC ( @_ );
   my $self      = shift;
   my $filename  = shift;
   my $read_opts = shift;
   my $date_opts = shift;

   $self = $self->{PARENT} || $self;

   my $res;
   if ( $date_opts ) {
      my %dates;
      $date_opts = get_date_opts ( $date_opts, $self->{CONTROL}->{date_opts} );
      change_special_date_vars ( $self->{CONTROL}->{DATES}->{timestamp},
                                 $date_opts, \%dates );

      # Temp override of the default date info ...
      local $self->{CONTROL}->{date_opts} = $date_opts;
      local $self->{CONTROL}->{DATES} = \%dates;

      $res = $self->load_config ( $filename, $read_opts );
   } else {
      $res = $self->load_config ( $filename, $read_opts );
   }

   DBUG_RETURN ( $res );
}

#######################################

=item $boolean = $cfg->merge_config ( $filename[, %override_read_opts] );

Provides a way to merge multiple config files into a single B<Advanced::Config>
object.  Useful when the main config file can't source in the passed config
file due to different I<%read_opts> settings, or when a shared config file
can't be modified to source in a sub-config file, or if for some reason you
can't use the I<source_cb> Read Option during the initial load.

Be aware that any tags in common with what's in this file will override the
tag/value pairs from any previous calls to I<load_config> or I<merge_config>.
You may also reference any tags in the previous loads as variables during this
load.  And if you have sections in common, it will merge each section's
tag/value pairs as well.

Just be aware that I<%override_read_opts> is overriding the default options set
during the call to B<new>, not necessarily the same options being used by
I<load_config>.  See L<Advanced::Config::Options> for more details on what
options are available.

And finally if I<$filename> is a relative path, it's relative to the current
directory, not relative to the location of the config file its being merged
into.

Returns B<1> if the config file was loaded and merged.  Else B<0>.

=cut

sub merge_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $self  = shift;
   my $file  = shift;       # Can be a relative path name if called directly ...
   # my $rOpts = shift;     # The read options to use ...

   my $res = $self->load_config ( $file, @_ );

   DBUG_RETURN ( (defined $res) ? 1 : 0 );
}


#######################################

=item $boolean = $cfg->merge_string ( $string[, %override_read_opts] );

Provides a way to merge multiple strings into a single B<Advanced::Config>
object.  Modifying the I<$string> afterwards will not affect this object.

Be aware that any tags in common with what's in this string will override the
tag/value pairs from any previous calls to load things into this object.

Just be aware that I<%override_read_opts> is overriding the default options set
during the call to B<new>, not necessarily the same options being used by
I<load_config> or I<load_string>.   See L<Advanced::Config::Options> for more
details on what options are available.

Returns B<1> if the string was merged into the object.  Else B<0>.

=cut

sub merge_string
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;
   my $string  = shift;     # The string to treat as a config file's contents.
   # my $rOpts = shift;     # The read options to use ...

   my $res = $self->load_string ( $string, @_ );

   DBUG_RETURN ( (defined $res) ? 1 : 0 );
}

#######################################

=item $boolean = $cfg->refresh_config ( %refresh_opts );

This boolean function detects if your config file or one of it's dependancies
has been updated.  If your config file sources in other config files, those
config files are checked for changes as well.

These changes could be to the config file itself or to any referenced variables
in your config file whose value has changed.

If it detects any updates, then it will reload the config file into memory,
tossing any customizations you may have added via calls to B<set_value()>.  It
will keep the current B<Read> options unchanged.

=over 4

=item Supported Refresh Options Are:

"test_only => 1" - It will skip the reloading of the config file even if it
detects something changed.  And just tell you if it detected any changes.

"force => 1" - It will assume you know better and that something was updated.
It will almost always return true (B<1>) when used.

=back

It returns true (B<1>) if any updates were detected or the B<force> option was
used.  It will return false (B<0>) otherwise.

It will also return false (B<0>) if you never called B<load_conifg()> or
B<load_string()> against this configuration object.  In which case there is
nothing to refresh.

=cut

sub refresh_config
{
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   my %opts = (ref ($_[0]) eq "HASH" ) ? %{$_[0]} : @_;

   my $updated = 0;    # Assume no updates ...
   my $skip    = 0;

   # Do a case insensitive lookup of the options hash ...
   foreach my $k ( keys %opts ) {
      next  unless ( $opts{$k} );        # Skip if set to false ...

      if ( $k =~ m/^force$/i ) {
         $updated = 1;       # Force an update ...
      } elsif ( $k =~ m/^test_only$/i ) {
         $skip = 1;          # Skip any refresh of the config file ...
      }
   }

   $self = $self->{PARENT} || $self;      # Force to the "main" section ...

   if ( $self->{CONTROL}->{SENSITIVE_CNT} != sensitive_cnt () ) {
      $updated = 1;
   }

   # If not forcing an update, try to detect any changes to the %ENV hash ...
   unless ( $updated ) {
      DBUG_PRINT ("INFO", "Checking for changes to %ENV ...");
      foreach my $k ( sort keys %{$self->{CONTROL}->{ENV}} ) {
         if ( ! defined $ENV{$k} ) {
            $updated = 1;    # Env. Var. was removed from the environment.
         } elsif ( $ENV{$k} ne $self->{CONTROL}->{ENV}->{$k} ) {
            $updated = 1;    # Env. Var. was modified ...
         }

         if ( $updated ) {
            DBUG_PRINT ("WARN", "ENV{%s} changed it's value!", $k);
            last;
         }
      }
   }

   # If any of the special date vars were referenced in the config file,
   # assume the program's been running long enough for one of them to change!
   my %dates;
   if ( $self->{CONTROL}->{DATE_USED} ) {
      DBUG_PRINT ("INFO", "Checking the special date variables for changes ...");
      my $res = set_special_date_vars ($self->{CONTROL}->{date_opts},
                                       \%dates, $self->{CONTROL}->{DATES});
      if ( $res >= $self->{CONTROL}->{DATE_USED} ) {
         DBUG_PRINT ("WARN", "A referenced special date variable's value changed!");
         $updated = 1;
      } else {
         $dates{timestamp} = $self->{CONTROL}->{DATES}->{timestamp};
      }
   }

   # Try to detect if any config files were modified ...
   unless ( $updated ) {
      DBUG_PRINT ("INFO", "Checking the file timestamps ...");
      foreach my $f ( sort keys %{$self->{CONTROL}->{REFRESH_MODIFY_TIME}} ) {
         # Can't do ref($f) since key is stored as a string here.
         my $modify_time = ( $f =~ m/^SCALAR[(]0x[0-9a-f]+[)]$/ ) ? 0 : (stat( $f ))[9];

         if ( $modify_time > $self->{CONTROL}->{REFRESH_MODIFY_TIME}->{$f} ) {
            DBUG_PRINT ("WARN", "File was modified: %s", $f);
            $updated = 1;
            last;
         }
      }
   }

   # Refresh the config file's contents in memory ...
   if ( $updated && $skip == 0 ) {
      my $f = $self->{CONTROL}->{filename};
      my @mlst = @{$self->{CONTROL}->{MERGE}};
      my $opts = $self->{CONTROL}->{REFRESH_READ_OPTIONS};

      # Update date info gathered earlier only if these vars are used.
      if ( $self->{CONTROL}->{DATE_USED} ) {
         $self->{CONTROL}->{DATES}     = \%dates;
         $self->{CONTROL}->{DATE_USED} = 0;
      }

      my $reload;
      DBUG_PRINT ("LOG", "Calling Load Function ... %s", ref ($f));
      if ( ref ( $f ) eq "SCALAR" ) {
         $reload = $self->load_string ( ${$f}, $opts->{$f} );
      } else {
         $reload = $self->load_config ( $f, $opts->{$f} );
      }
      return DBUG_RETURN ( 0 )  unless ( defined $reload );  # Load failed ???

      foreach my $m (@mlst) {
         DBUG_PRINT ("LOG", "Calling Merge Function ... %s", ref ($m));
         if ( ref ( $m ) eq "SCALAR" ) {
            $self->merge_string ( ${$m}, $opts->{$m} );
         } else {
            $self->merge_config ( $m, $opts->{$m} );
         }
      }
   }

   DBUG_RETURN ( $updated );
}

#######################################

# Private method ...
# Checks for recursion while sourcing in sub-files.
# Returns: 1 (yes) or 0 (no)

sub _recursion_check
{
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   my $file = shift;

   # Get the main/parent section to work against!
   $self = $self->{PARENT} || $self;

   DBUG_RETURN ( exists $self->{CONTROL}->{RECURSION}->{$file} ? 1 : 0 );
}

#######################################

# Private method ...
# Gets the requested tag from the current section.
# And then apply the required rules against the returned value.
# Returns:  The tag hash ... (undef if it doesn't exist)
sub _base_get
{
   my $self = shift;
   my $tag  = shift;
   my $opts = shift;

   # Get the main/parent section to work against!
   my $pcfg = $self->{PARENT} || $self;

   # Determine what the "get" options must be ...
   my $get_opts = $pcfg->{CONTROL}->{get_opts};
   $get_opts = get_get_opts ( $opts, $get_opts )  if ( $opts );

   # Check if a case insensitive lookup was requested ...
   my $t = ( $pcfg->{CONTROL}->{read_opts}->{tag_case} && $tag ) ? lc ($tag) : $tag;

   # Returns a hash reference to a local copy of the tag's data ... (or undef)
   # Handles the inherit option if used.
   return ( apply_get_rules ( $tag, $self->{SECTION_NAME},
                              $self->{DATA}->{$t}, $pcfg->{DATA}->{$t},
                              $pcfg->{CONTROL}->{ALLOW_UTF8},
                              $get_opts ) );
}


# Private method ...
# Gets the requested tag value from the current section.
# Returns: All 5 of the hash members individually ...
sub _base_get2
{
   my $self = shift;
   my $tag  = shift;
   my $opts = shift;

   my $data = $self->_base_get ( $tag, $opts );

   if ( defined $data ) {
      return ( $data->{VALUE}, $data->{MASK_IN_FISH}, $data->{FILE}, $data->{ENCRYPTED}, $data->{VARIABLE} );
   } else {
      return ( undef, 0, "", 0, 0 );    # No such tag ...
   }
}


#######################################

=back

=head2 Accessing the contents of an Advanced::Config object.

These methods allow you to access the data loaded into this object.

They all look in the current section for the B<tag> and if the B<tag> couldn't
be found in this section and the I<inherit> option was also set, it will then
look in the parent/main section for the B<tag>.  But if the I<inherit> option
wasn't set it wouldn't look there.

If the requested B<tag> couldn't be found, they return B<undef>.  But if the
I<required> option was used, it may call B<die> instead!

But normally they just return the requested B<tag>'s value.

They all use F<%override_get_opts>, passed by value or by reference, as an
optional argument that overrides the default options provided in the call
to F<new()>.  The I<inherit> and I<required> options discussed above are two
such options.  In most cases this hash argument isn't needed.  So leave it off
if you are happy with the current defaults!

See the POD under L<Advanced::Config::Options>, I<The Get Options> for more
details on what options you may override.

Only the B<L<get_value>> function was truly needed.  But the other I<get>
methods were added for a couple of reasons.  First to make it clear in your code
what type of value is being returned and provide the ability to do validation of
the B<tag>'s value without having to validate it yourself!  Another benifit was
that it drastically reduced the number of exposed I<Get Options> needed for this
module.  Making it easier to use.

Finally when these extra methods apply their validation, if the B<tag>'s value
fails the test, it treats it as a I<B<tag> not found> situation as described
above.

=over

=item $value = $cfg->get_value ( $tag[, %override_get_opts] );

This function looks up the requested B<tag>'s value and returns it.
See common details above.

=cut

sub get_value
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $opt_ref = $_[0];       # The override options ...

   $opt_ref = $self->_get_opt_args ( @_ )  if ( defined $opt_ref );

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}

#######################################
# A helper function to handle the various ways to find a hash as an argument!
# Handles all 3 cases.
#   undef          - No arguments
#   hash ref       - passed by reference
#   something else - passed by value. (array)

sub _get_opt_args
{
   my $self    = shift;      # Reference to the current section.
   my $opt_ref = $_[0];      # May be undef, a hash ref, or start of a hash ...

   # Convert the parameter array into a regular old hash reference ...
   my %opts;
   unless ( defined $opt_ref ) {
      $opt_ref = \%opts;
   } elsif ( ref ($opt_ref) ne "HASH" ) {
      %opts = @_;
      $opt_ref = \%opts;
   }

   return ( $opt_ref );    # The hash reference to use ...
}

#######################################
# Another helper function to help with evaluating which value to use ...
# Does a 4 step check.
#   1) Use the $value if provided.
#   2) If the key exists in the hash returned by _get_opt_args(), use it.
#   3) Look it up in the default "Get Options" set via call to new().
#   4) undef if all the above fail.

sub _evaluate_hash_values
{
   my $self  = shift;      # References the current section.
   my $key   = shift;      # The hash key to look up ...
   my $ghash = shift;      # A hash ref returned by _get_opt_args().
   my $value = shift;      # Use only if explicitly set ...

   unless ( defined $value ) {
      if ( defined $ghash && exists $ghash->{$key} ) {
         $value = $ghash->{$key};   # Passed via the get options hash ...
      } else {
          # Use the default from the call to new() ...
          my $pcfg = $self->{PARENT} || $self;
          if ( exists $pcfg->{CONTROL}->{get_opts}->{$key} ) {
             $value = $pcfg->{CONTROL}->{get_opts}->{$key};
          }
      }
   }

   return ( $value );    # The value to use ...
}

#######################################

=item $value = $cfg->get_integer ( $tag[, $rt_flag[, %override_get_opts]] );

This function looks up the requested B<tag>'s value and returns it if its an
integer.  If the B<tag>'s value is a floating point number (ex 3.6), then the
value is either truncated or rounded up based on the setting of the I<rt_flag>.

If I<rt_flag> is set, it will perform truncation, so 3.6 becomes B<3>.  If the
flag is B<undef> or zero, it does rounding, so 3.6 becomes B<4>.  Meaning the
default is rounding.

Otherwise if the B<tag> doesn't exist or its value is not numeric it will
return B<undef> unless it's been marked as I<required>.  In that case B<die>
may be called instead.

=cut

sub get_integer
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $rt_flag = shift;       # 1 - truncate, 0 - rounding.
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Flag if we should use truncation (2) or rounding (1) if needed ...
   local $opt_ref->{numeric} = $rt_flag ? 2 : 1;

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}


#######################################

=item $value = $cfg->get_numeric ( $tag[, %override_get_opts] );

This function looks up the requested B<tag>'s value and returns it if its
value is numeric.  Which means any valid integer or floating point number!

If the B<tag> doesn't exist or its value is not numeric it will return B<undef>
unless it's been marked as I<required>.  In that case B<die> may be called
instead.

=cut

sub get_numeric
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Asking for a floating point number ...
   local $opt_ref->{numeric} = 3;

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}


#######################################

=item $value = $cfg->get_boolean ( $tag[, %override_get_opts] );

Treats the B<tag>'s value as a boolean value and returns I<undef>,
B<0> or B<1>.

Sometimes you just want to allow for basically a true/false answer
without having to force a particualar usage in the config file.
This function converts the B<tag>'s value accoringly.

So it handles pairs like: Yes/No, True/False, Good/Bad, Y/N, T/F, G/B, 1/0,
On/Off, etc. and converts them into a boolean value.  This test is case
insensitive.  It never returns what's actually in the config file.

If it doesn't recognize something it always returns B<0>.

=cut

sub get_boolean
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Turns on the treat as a boolean option ...
   local $opt_ref->{auto_true} = 1;

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}


#######################################

=item $date = $cfg->get_date ( $tag[, $language[, %override_get_opts]] );

This function looks up the requested B<tag>'s value and returns it if its
value contains a valid date.  The returned value will always be in I<YYYY-MM-DD>
format no matter what format or language was actually used in the config file
for the date.

If the B<tag> doesn't exist or its value is not a date it will return B<undef>
unless it's been marked as I<required>.  In that case B<die> may be called
instead.

If I<$language> is undefined, it will use the default language defined in the
call to I<new> for parsing the date. (B<English> if not overriden.) Otherwise
it must be a valid language defined by B<Date::Language>.  If it's a wrong or
bad language, your date might not be recognized as valid.

Unlike most other B<get> options, when parsing the B<tag>'s value, it's not
looking to match the entire string.  It's looking for a date portion inside the
value and ignores any miscellanious information.  There was just too many
semi-valid potential surrounding data to worry about parsing that info as well.

So B<Tues "January 3rd, 2017" at 6:00 PM> returns "2017-01-03".

There are also a few date related options for I<%override_get_opts> to use that
you may find useful.

See L<Advanced::Config::Date> for more details.

=cut

sub get_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $self     = shift;       # Reference to the current section.
   my $tag      = shift;       # The tag to look up ...
   my $language = shift;       # The language the date appears in ...
   my $opt_ref  = $self->_get_opt_args ( @_ );   # The override options ...

   local $opt_ref->{date_active} = 1;
   local $opt_ref->{date_language} = $language  if ( defined $language );

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}


#######################################

=item $value = $cfg->get_filename ( $tag[, $access[, %override_get_opts]] );

Treats the B<tag>'s value as a filename.  If the referenced file doesn't exist
it returns I<undef> instead, as if the B<tag> didn't exist.

B<access> defines the minimum access required.  If that minimum access isn't
met it returns I<undef> instead, as if the B<tag> didn't exist.  B<access>
may be I<undef> to just check for existance.

The B<access> levels are B<r> for read, B<w> for write and B<x> for execute.
You may also combine them if you wish in any order.
Ex: B<rw>, B<xwr>, B<rx> ...

=cut

sub get_filename
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $access  = shift;       # undef or contains "r", "w" and/or "x" ...
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Verify that the tag's value points to an existing filename ...
   local $opt_ref->{filename} = 1;    # Existance ...
   if ( defined $access ) {
      $opt_ref->{filename} |= 2      if ( $access =~ m/[rR]/ );   # -r--
      $opt_ref->{filename} |= 4      if ( $access =~ m/[wW]/ );   # --w-
      $opt_ref->{filename} |= 2 | 8  if ( $access =~ m/[xX]/ );   # -r-x
   }

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}


#######################################

=item $value = $cfg->get_directory ( $tag[, $access[, %override_get_opts]] );

Treats the B<tag>'s value as a directory.  If the referenced directory doesn't
exist it returns I<undef> instead, as if the B<tag> didn't exist.

B<access> defines the minimum access required.  If that minimum access isn't met
it returns I<undef> instead, as if the B<tag> didn't exist.  B<access> may be
I<undef> to just check for existance.

The B<access> levels are B<r> for read and B<w> for write.  You may also combine
them if you wish in any order.  Ex: B<rw> or B<wr>.


=cut

sub get_directory
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $access  = shift;       # undef or contains "r" and/or "w" ...
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Verify that the tag's value points to an existing directory ...
   # Execute permission is always required to reference a directory's contents.
   local $opt_ref->{directory} = 1;    # Existance ...
   if ( defined $access ) {
      $opt_ref->{directory} |= 2 | 8  if ( $access =~ m/[rR]/ );  # dr-x
      $opt_ref->{directory} |= 4 | 8  if ( $access =~ m/[wW]/ );  # d-wx
   }

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );
}

#######################################

=back

=head2 Accessing the contents of an Advanced::Config object in LIST mode.

These methods allow you to access the data loaded into each B<tag> in list mode.
Splitting the B<tag>'s data up into arrays and hashes.  Otherwise these
functions behave similarly to the one's above.

Each function asks for a I<pattern> used to split the B<tag>'s value into an
array of values.  If the pattern is B<undef> it will use the default
I<split_pattern> specified during he call to F<new()>.  Otherwise it can be
either a string or a RegEx.  See Perl's I<split> function for more details.
After the value has been split, it will perform any requested validation and
most functions will return B<undef> if even one element in the list fails it's
edits.  It was added as its own arguement, instad of just relying on the
override option hash, since this option is probably the one that gets overidden
most often.

They also support the same I<inherit> and I<required> options described for the
scalar functions as well.

They also all allow F<%override_get_opts>, passed by value or by reference, as
an optional argument that overrides the default options provided in the call
to F<new()>.  If you should use both option I<split_pattern> and the I<pattern>
argument, the I<pattern> argument takes precedence.  So leave this optional
hash argument off if you are happy with the current defaults.

=over

=item $array_ref = $cfg->get_list_values ( $tag[, $pattern[, $sort[, %override_get_opts ]]] );

This function looks up the requested B<tag>'s value and then splits it up into
an array and returns a reference to it.

If I<sort> is 1 it does an ascending sort.  If I<sort> is -1, it will do a
descending sort instead.  By default it will do no sort.

See the common section above for more details.

=cut

sub get_list_values
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $sort       = shift;  # The sort order.
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   # Tells how to sort the resulting array ...
   local $opt_ref->{sort} =
                $self->_evaluate_hash_values ("sort", $opt_ref, $sort);

   my ( $value, $sensitive ) = $self->_base_get2 ( $tag, $opt_ref );
   DBUG_MASK (0)  if ( $sensitive );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $hash_ref = $cfg->get_hash_values ( $tag[, $pattern[, $value[, \%merge[, %override_get_opts]]]] );

This method is a bit more complex than L<get_list_values>.  Like that method it
splits up the B<tag>'s value into an array.  But it then converts that array
into the keys of a hash whose value for each entry is set to I<value>.

Then if the optional I<merge> hash reference was provided, and that key isn't
present in that hash, it adds the missing value to the I<merge> hash.  It never
overrides any existing entries in the I<merge> hash!

It always returns the hash reference based on the B<tag>'s split value or an
empty hash if the B<tag> doesn't exist or has no value.

=cut

sub get_hash_values
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $hash_value = shift;  # Value to assign to each hash member.
   my $merge_ref  = shift;  # A hash to merge the results into
   # my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   my $key_vals = $self->get_list_values ($tag, $split_ptrn, 0, @_);

   my %my_hash;
   if ( $key_vals ) {
      # Will we be merging the results into a different hash?
      my $m_flg = ( $merge_ref && ref ($merge_ref) eq "HASH" ) ? 1 : 0;

      # Build the hash(s) from the array ...
      foreach ( @{$key_vals} ) {
         $my_hash{$_} = $hash_value;
         if ( $m_flg && ! exists $merge_ref->{$_} ) {
            $merge_ref->{$_} = $hash_value;
         }
      }
   }

   DBUG_RETURN ( \%my_hash );
}


#######################################

=item $array_ref = $cfg->get_list_integer ( $tag[, $rt_flag[, $pattern[, $sort[, %override_get_opts]]]] );

This is the list version of F<get_integer>.  See that function for the meaning
of I<$rt_flag>.  See F<get_list_values> for the meaning of I<$pattern> and
I<$sort>.

=cut

sub get_list_integer
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $rt_flag    = shift;  # 1 - truncate, 0 - rounding.
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $sort       = shift;  # The sort order.
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   # Tells how to sort the resulting array ...
   local $opt_ref->{sort} =
                $self->_evaluate_hash_values ("sort", $opt_ref, $sort);

   my $value = $self->get_integer ( $tag, $rt_flag, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $array_ref = $cfg->get_list_numeric ( $tag[, $pattern[, $sort[, %override_get_opts]]] );

This is the list version of F<get_numeric>.  See F<get_list_values> for the
meaning of I<$pattern> and I<$sort>.

=cut

sub get_list_numeric
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $sort       = shift;  # The sort order.
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   # Tells how to sort the resulting array ...
   local $opt_ref->{sort} =
                $self->_evaluate_hash_values ("sort", $opt_ref, $sort);

   my $value = $self->get_numeric ( $tag, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $array_ref = $cfg->get_list_boolean ( $tag[, $pattern[, %override_get_opts]] );

This is the list version of F<get_boolean>.  See F<get_list_values> for the
meaning of I<$pattern>.

=cut

sub get_list_boolean
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   my $value = $self->get_boolean ( $tag, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $array_ref = $cfg->get_list_date ( $tag, $pattern[, $language[, %override_get_opts]] );

This is the list version of F<get_date>.  See F<get_list_values> for the
meaning of I<$pattern>.  In this case I<$pattern> is a required option since
dates bring unique parsing challenges and the default value usually isn't good
enough.

=cut

sub get_list_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $language   = shift;  # The languate the date appears in ...
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ... (it's required this time!)
   # So allow in either place, argument or option.
   $split_ptrn = $opt_ref->{split_pattern}  unless ( defined $split_ptrn );
   unless ( defined $split_ptrn ) {
      my $msg = "Missing required \$pattern argument in call to get_list_date()!\n";
      die ( $msg );
   }

   local $opt_ref->{split_pattern} = $split_ptrn;

   my $value = $self->get_date ( $tag, $language, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $array_ref = $cfg->get_list_filename ( $tag[, $access[, $pattern[, %override_get_opts]]] );

This is the list version of F<get_filename>.  See that function for the meaning
of I<$access>.  See F<get_list_values> for the meaning of I<$pattern>.

=cut

sub get_list_filename
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $access     = shift;  # undef or contains "r", "w" and/or "x" ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   my $value = $self->get_filename ( $tag, $access, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################

=item $array_ref = $cfg->get_list_directory ( $tag[, $access[, $pattern[, %override_get_opts]]] );

This is the list version of F<get_directory>.  See that function for the meaning
of I<$access>.  See F<get_list_values> for the meaning of I<$pattern>.

=cut

sub get_list_directory
{
   DBUG_ENTER_FUNC ( @_ );
   my $self       = shift;  # Reference to the current section.
   my $tag        = shift;  # The tag to look up ...
   my $access     = shift;  # undef or contains "r", "w" and/or "x" ...
   my $split_ptrn = shift;  # The split pattern to use to call to split().
   my $opt_ref = $self->_get_opt_args ( @_ );    # The override options ...

   # Tells us to split the tag's value up into an array ...
   local $opt_ref->{split} = 1;

   # Tells how to spit up the tag's value ...
   local $opt_ref->{split_pattern} =
          $self->_evaluate_hash_values ("split_pattern", $opt_ref, $split_ptrn);

   my $value = $self->get_directory ( $tag, $access, $opt_ref );

   DBUG_RETURN ( $value );  # An array ref or undef.
}


#######################################
# Private method ...
# Returns (Worked, Hide)
# Caller either wants both values or none of them.
# Should never write to fish ...
sub _base_set
{
   my $self            = shift;
   my $tag             = shift;
   my $value           = shift;
   my $file            = shift || "";    # The file the tag was defined in.
   my $force_sensitive = shift || 0;
   my $still_encrypted = shift || 0;
   my $has_variables   = shift || 0;

   # Get the main/parent section to work against!
   # my $pcfg = $self->get_section();
   my $pcfg = $self->{PARENT} || $self;

   # Check if case insensitive handling was requested ...
   $tag = lc ($tag)  if ( $pcfg->{CONTROL}->{read_opts}->{tag_case} );

   if ( $tag =~ m/^shft3+$/i ) {
      return ( 0, 0 );       # Set failed ... tag name not allowed.
   }

   my $hide = ($force_sensitive || $self->{SENSITIVE_SECTION}) ? 1 : 0;

   if ( exists $self->{DATA}->{$tag} ) {
      $hide = 1   if ( $self->{DATA}->{$tag}->{MASK_IN_FISH} );
   } else {
      my %data;
      $self->{DATA}->{$tag} = \%data;
      unless ( $hide ) {
         $hide = 1   if ( should_we_hide_sensitive_data ($tag, 1) );
      }
   }

   # The value must never be undefined!
   $self->{DATA}->{$tag}->{VALUE} = (defined $value) ? $value : "";

   # What file the tag was found in ...
   $self->{DATA}->{$tag}->{FILE} = $file;

   # Must it be hidden in the fish logs?
   $self->{DATA}->{$tag}->{MASK_IN_FISH} = $hide;

   # Is the value still encrypted?
   $self->{DATA}->{$tag}->{ENCRYPTED} = $still_encrypted ? 1 : 0;

   # Does the value still reference variables?
   $self->{DATA}->{$tag}->{VARIABLE} = $has_variables ? 1 : 0;

   return ( 1, $hide );
}


#######################################

=back

=head2 Manipulating the contents of an Advanced::Config object.

These methods allow you to manipulate the contents of an B<Advanced::Config>
object in many ways.  They all just update what's in memory and not the contents
of the config file itself.

So should the contents of this module get refreshed, you will loose any changes
made by these B<4> methods.

=over

=item $ok = $cfg->set_value ( $tag, $value );

Adds the requested I<$tag> and it's I<$value> to the current section in the
I<Advanced::Config> object.

If the I<$tag> already exists, it will be overriden with it's new I<$value>.

It returns B<1> on success or B<0> if your request was rejected!
It will also print a warning if it was rejected.

=cut

sub set_value
{
   my $self  = shift;   # Reference to the current section of the object.
   my $tag   = shift;   # The tag set to value ...
   my $value = shift;

   my ( $worked, $sensitive ) = $self->_base_set ($tag, $value, undef);

   DBUG_MASK_NEXT_FUNC_CALL (2)  if ( $sensitive );
   DBUG_ENTER_FUNC ( $self, $tag, $value, @_ );

   unless ( $worked ) {
      warn ("You may not use \"${tag}\" as your tag name!\n");
   }

   DBUG_RETURN ($worked);
}

#######################################

=item $bool = $cfg->rename_tag ( $old_tag, $new_tag );

Renames the tag found in the current section to it's new name.  If the
I<$new_tag> already exists it is overwritting by I<$old_tag>.  If I<$old_tag>
doesn't exist the rename fails.

Returns B<1> on success, B<0> on failure.

=cut

sub rename_tag
{
   DBUG_ENTER_FUNC (@_);
   my $self    = shift;
   my $old_tag = shift;
   my $new_tag = shift;

   unless ( defined $old_tag && defined $new_tag ) {
      warn ("All arguments to rename_tag() are required!\n");
      return DBUG_RETURN (0);
   }

   if ( $new_tag =~ m/^shft3+$/i ) {
      warn ("You may not use \"${new_tag}\" as your new tag name!\n");
      return DBUG_RETURN (0);
   }

   # Get the main/parent section to work against!
   my $pcfg = $self->{PARENT} || $self;

   # Check if a case insensitive lookup was requested ...
   if ( $pcfg->{CONTROL}->{read_opts}->{tag_case} ) {
      $old_tag = lc ($old_tag)  if ( $old_tag );
      $new_tag = lc ($new_tag)  if ( $new_tag );
   }

   if ( $old_tag eq $new_tag ) {
      warn ("The new tag name must be different from the old tag name!\n");
      return DBUG_RETURN (0);
   }

   # Was there something to rename ???
   if ( exists $self->{DATA}->{$old_tag} ) {
      $self->{DATA}->{$new_tag} = $self->{DATA}->{$old_tag};
      delete ( $self->{DATA}->{$old_tag} );
      return DBUG_RETURN (1);
   }

   DBUG_RETURN (0);
}

#######################################

=item $bool = $cfg->move_tag ( $tag, $new_section[, $new_tag] );

This function moves the tag from the current section to the specified new
section.  If I<$new_tag> was provided that will be the tag's new name in
the new section.  If the tag already exists in the new section it will be
overwritten.

If the tag or the new section doesn't exist, the move will fail!  It will also
fail if the new section is the current section.

Returns B<1> on success, B<0> on failure.

=cut

sub move_tag
{
   DBUG_ENTER_FUNC (@_);
   my $self        = shift;
   my $tag         = shift;
   my $new_section = shift;
   my $new_tag     = shift;

   $new_tag = $tag  unless ( defined $new_tag );

   unless ( defined $tag && defined $new_section ) {
      warn ("Both \$tag and \$new_section are required for move_tag()!\n");
      return DBUG_RETURN (0);
   }

   if ( $new_tag =~ m/^shft3+$/i ) {
      warn ("You may not use \"${new_tag}\" as your new tag name!\n");
      return DBUG_RETURN (0);
   }

   # Get the main/parent section to work against!
   my $pcfg = $self->{PARENT} || $self;

   # Check if a case insensitive lookup was requested ...
   $tag = lc ($tag)  if ( $pcfg->{CONTROL}->{read_opts}->{tag_case} && $tag );

   my $cfg = $self->get_section ( $new_section ) || $self;

   if ( $self ne $cfg && exists $self->{DATA}->{$tag} ) {
      $cfg->{DATA}->{$new_tag} = $self->{DATA}->{$tag};
      delete ( $self->{DATA}->{$tag} );
      return DBUG_RETURN (1);
   }

   DBUG_RETURN (0);
}

#######################################

=item $bool = $cfg->delete_tag ( $tag );

This function removes the requested I<$tag> found in the current section from
the configuration data in memory.

Returns B<1> on success, B<0> if the I<$tag> didn't exist.

=cut

sub delete_tag
{
   DBUG_ENTER_FUNC (@_);
   my $self = shift;
   my $tag  = shift;

   unless ( defined $tag ) {
      return DBUG_RETURN (0);   # Nothing to delete!
   }

   # Get the main/parent section to work against!
   my $pcfg = $self->{PARENT} || $self;

   # Check if a case insensitive lookup was requested ...
   $tag = lc ($tag)  if ( $pcfg->{CONTROL}->{read_opts}->{tag_case} && $tag );

   # Was there something to delete ???
   if ( exists $self->{DATA}->{$tag} ) {
      delete ( $self->{DATA}->{$tag} );
      return DBUG_RETURN (1);
   }

   DBUG_RETURN (0);
}

#######################################

=back

=head2 Breaking your Advanced::Config object into Sections.

Defining sections allow you to break up your configuration files into multiple
independent parts.  Or in advanced configuations using sections to override
default values defined in the main/unlabled section.

=over

=item $section = $cfg->get_section ( [$section_name[, $required]] );

Returns the I<Advanced::Config> object for the requested section in your config
file.  If the I<$section_name> doesn't exist, it will return I<undef>.  If
I<$required> is set, it will call B<die> instead.

If no I<$section_name> was provided, it returns the default I<main> section.

=cut

sub get_section
{
   DBUG_ENTER_FUNC ( @_ );
   my $self     = shift;
   my $section  = shift;
   my $required = shift || 0;

   $self = $self->{PARENT} || $self;     # Force to parent section ...

   unless ( defined $section ) {
      $section = DEFAULT_SECTION;
   } elsif ( $section =~ m/^\s*$/ ) {
      $section = DEFAULT_SECTION;
   } else {
      $section = lc ($section);
      $section =~ s/^\s+//;
      $section =~ s/\s+$//;
   }

   if ( exists $self->{SECTIONS}->{$section} ) {
      return DBUG_RETURN ( $self->{SECTIONS}->{$section} );
   }

   if ( $required ) {
      die ("Section \"$section\" doesn't exist in this ", __PACKAGE__,
           " class!\n");
   }

   DBUG_RETURN (undef);
}

#######################################

=item $name = $cfg->section_name ( );

This function returns the name of the current section I<$cfg> points to.

=cut

sub section_name
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;
   DBUG_RETURN ( $self->{SECTION_NAME} );
}

#######################################

=item $scfg = $cfg->create_section ( $name );

Creates a new section called I<$name> within the current Advanced::Config object
I<$cfg>.  It returns the I<Advanced::Config> object that it created.  If a
section of that same name already exists it will return B<undef>.

There is no such thing as sub-sections, so if I<$cfg> is already points to a
section, then it looks up the parent object and associates the new section with
the parent object instead.

=cut

sub create_section
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;
   my $name = shift;

   # This test bypasses all the die logic in the special case constructor!
   # That constructor is no longer exposed in the POD.
   if ( $self->get_section ( $name ) ) {
      return DBUG_RETURN (undef);     # Name is already in use ...
   }

   DBUG_RETURN ( $self->new_section ( $self, $name ) );
}

#######################################

=back

=head2 Searching the contents of an Advanced::Config object.

This section deals with the methods available for searching for content within
your B<Advanced::Config> object.

=over

=item @list = $cfg->find_tags ( $pattern[, $override_inherit] );

It returns a list of all tags whose name contains the passed pattern.

If the pattern is B<undef> or the empty string, it will return all tags in
the curent section.  Otherwise it does a case insensitive comparison of the
pattern against each tag to see if it should be returned or not.

If I<override_inherit> is provided it overrides the current I<inherit> option's
setting.  If B<undef> it uses the current I<inherit> setting.  If I<inherit>
evaluates to true, it looks in the current section I<and> the main section for
a match.  Otherwise it just looks in the current section.

The returned list of tags will be sorted in alphabetical order.

=cut

sub find_tags
{
   DBUG_ENTER_FUNC (@_);
   my $self    = shift;
   my $pattern = shift;
   my $inherit = shift;     # undef, 0, or 1.

   my @lst;    # The list of tags found ...

   my $pcfg = $self->{PARENT} || $self;

   $inherit = $pcfg->{CONTROL}->{get_opts}->{inherit}  unless (defined $inherit);

   foreach my $tag ( sort keys %{$self->{DATA}} ) {
      unless ( $pattern ) {
         push (@lst, $tag);
      } elsif ( $tag =~ m/${pattern}/i ) {
         push (@lst, $tag);
      }
   }

   # Are we searching the parent/main section as well?
   if ( $inherit && $pcfg != $self ) {
      DBUG_PRINT ("INFO", "Also searching the 'main' section ...");
      foreach my $tg ( sort keys %{$pcfg->{DATA}} ) {
         # Ignore tags repeated from the current section
         next  if ( exists $self->{DATA}->{$tg} );

         unless ( $pattern ) {
            push (@lst, $tg);
         } elsif ( $tg =~ m/$pattern/i ) {
            push (@lst, $tg);
         }
      }

      @lst = sort ( @lst );   # Sort the merged list.
   }

   DBUG_RETURN ( @lst );
}


#######################################
# No pod on purpose since exposing it would just cause confusion.
# It's a special case variant for find_tags().
# Just called from Advanced::Config::Reader::apply_modifier.

sub _find_variables
{
   DBUG_ENTER_FUNC (@_);
   my $self    = shift;
   my $pattern = shift;

   my %res;

   # Find all tags begining with the pattern ...
   foreach ( $self->find_tags ("^${pattern}") ) {
      $res{$_} = 1;
   } 

   # Find all environment variables starting with the given pattern ...
   foreach ( keys %ENV ) {
      # Never include these 2 special tags in any list ...
      next  if ( defined $secret_tag && $secret_tag eq $_ );
      next  if ( defined $fish_tag   && $fish_tag   eq $_ );

      $res{$_} = 4  if ( $_ =~ m/^${pattern}/ );
   }

   # Skip checking the Perl special variables we use (rule 5)
   # Since it's now part of (rule 6)

   # Check the pre-defined module variables ... (rule 6)
   foreach ( keys %begin_special_vars ) {
      $res{$_} = 6  if ( $_ =~ m/^${pattern}/ );
   }

   # The special date variables ... (rule 7)
   my $pcfg = $self->{PARENT} || $self;
   foreach ( keys %{$pcfg->{CONTROL}->{DATES}} ) {
      $res{$_} = 7  if ( $_ =~ m/^${pattern}/ );
   }

   DBUG_RETURN ( sort keys %res );
}


#######################################

=item @list = $cfg->find_values ( $pattern[, $override_inherit] );

It returns a list of all tags whose values contains the passed pattern.

If the pattern is B<undef> or the empty string, it will return all tags in
the curent section.  Otherwise it does a case insensitive comparison of the
pattern against each tag's value to see if it should be returned or not.

If I<override_inherit> is provided it overrides the current I<inherit> option's
setting.  If B<undef> it uses the current I<inherit> setting.  If I<inherit>
evaluates to true, it looks in the current section I<and> the main section for
a match.  Otherwise it just looks in the current section.

The returned list of tags will be sorted in alphabetical order.

=cut

sub find_values
{
   DBUG_ENTER_FUNC (@_);
   my $self    = shift;
   my $pattern = shift;
   my $inherit = shift;

   my @lst;     # The list of tags found ...

   my $pcfg = $self->{PARENT} || $self;

   $inherit = $pcfg->{CONTROL}->{get_opts}->{inherit}  unless (defined $inherit);

   foreach my $tag ( sort keys %{$self->{DATA}} ) {
      unless ( $pattern ) {
         push (@lst, $tag);
      } else {
         my $value = $self->{DATA}->{$tag}->{VALUE};
         if ( $value =~ m/$pattern/i ) {
            push (@lst, $tag);
         }
      }
   }

   # Are we searching the parent/main section as well?
   if ( $inherit && $pcfg != $self ) {
      DBUG_PRINT ("INFO", "Also searching the main section ...");
      foreach my $tg ( sort keys %{$pcfg->{DATA}} ) {
         # Ignore tags repeated from the current section
         next  if ( exists $self->{DATA}->{$tg} );

         unless ( $pattern ) {
            push (@lst, $tg);
         } else {
            my $value = $pcfg->{DATA}->{$tg}->{VALUE};
            if ( $value =~ m/$pattern/i ) {
               push (@lst, $tg);
            }
         }
      }

      @lst = sort (@lst);    # Sort the merged list.
   }

   DBUG_RETURN (@lst);
}

#######################################

=item @list = $cfg->find_sections ( $pattern );

It returns a list of all section names which match this pattern.

If the pattern is B<undef> or the empty string, it will return all the section
names.  Otherwise it does a case insensitive comparison of the pattern against
each section name to see if it should be returned or not.

The returned list of section names will be sorted in alphabetical order.

=cut

sub find_sections
{
   DBUG_ENTER_FUNC (@_);
   my $self    = shift;
   my $pattern = shift;

   $self = $self->{PARENT} || $self;     # Force to parent section ...

   my @lst;
   foreach my $name ( sort keys %{$self->{SECTIONS}} ) {
      unless ( $pattern ) {
         push (@lst, $name);
      } elsif ( $name =~ m/$pattern/i ) {
         push (@lst, $name);
      }
   }

   DBUG_RETURN (@lst);
}


#######################################

=back

=head2 Miscellaneous methods against Advanced::Config object.

These methods while useful don't really fall into a category of their own.  So
they are collected here in the miscellaneous section.

=over

=item $file = $cfg->filename ( );

Returns the fully qualified file name used to load the config file into memory.

=cut

sub filename
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;

   # The request only applies to the parent instance ...
   $self = $self->{PARENT} || $self;

   DBUG_RETURN( $self->{CONTROL}->{filename} );
}


#######################################

=item ($ropts, $gopts, $dopts) = $cfg->get_cfg_settings ( );

This method returns references to copies of the current options used to
manipulate the config file.  It returns copies of these hashes so feel free to
modify them without fear of affecting the behaviour of this module.

=cut

sub get_cfg_settings
{
   DBUG_ENTER_FUNC (@_);
   my $self = shift;

   # Get the main/parent section to work against!
   my $pcfg = $self->{PARENT} || $self;

   my $ctrl = $pcfg->{CONTROL};

   my (%r_opts, %g_opts, %d_opts);
   %r_opts = %{$ctrl->{read_opts}}    if ( $ctrl && $ctrl->{read_opts} );
   %g_opts = %{$ctrl->{get_opts}}     if ( $ctrl && $ctrl->{get_opts} );
   %d_opts = %{$ctrl->{date_opts}}    if ( $ctrl && $ctrl->{date_opts} );

   DBUG_RETURN ( \%r_opts, \%g_opts, \%d_opts );
}


#######################################

=item $cfg->export_tag_value_to_ENV ( $tag, $value );

Used to export the requested tag/value pair to the %ENV hash.  If it's also
marked as an %ENV tag the config file depends on, it updates internal
bookkeeping so that it won't trigger false refreshes.

Once it's been promoted to the %ENV hash the change can't be backed out again.

=cut

sub export_tag_value_to_ENV
{
   my $self  = shift;
   my $tag   = shift;
   my $value = shift;
   my $hide  = $_[0] || 0;   # Not taken from stack on purpose ...
   DBUG_ENTER_FUNC ( $self, $tag, ($hide ? "*"x8 : $value), @_ );

   $ENV{$tag} = $value;

   # Check if the change afects the refresh logic ...
   my $pcfg = $self->{PARENT} || $self;
   if ( exists $pcfg->{CONTROL}->{ENV}->{$tag} ) {
      $pcfg->{CONTROL}->{ENV}->{$tag} = $value;    # It did ...
   }

   DBUG_VOID_RETURN ();
}

#######################################

=item $sensitive = $cfg->chk_if_sensitive ( $tag[, $override_inherit] );

This function looks up the requested tag in the current section of the config
file and returns if this module thinks the existing value is senitive (B<1>)
or not (B<0>).

If the tag doesn't exist, it will always return that it isn't sensitive. (B<0>)

An existing tag references sensitive data if one of the following is true.
   1) Advanced::Config::Options::should_we_hide_sensitive_data() says it is
      or it says the section the tag was found in was sensitive.
   2) The config file marked the tag in it's comment to HIDE it.
   3) The config file marked it as being encrypted.
   4) It referenced a variable that was marked as sensitive.

If I<override_inherit> is provided it overrides the current I<inherit> option's
setting.  If B<undef> it uses the current I<inherit> setting.  If I<inherit>
evaluates to true, it looks in the current section I<and> the main section for
a match.  Otherwise it just looks in the current section for the tag.

=cut

sub chk_if_sensitive
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $inherit = shift;       # undef, 0, or 1.

   my $pcfg = $self->{PARENT} || $self;

   $inherit = $pcfg->{CONTROL}->{get_opts}->{inherit}  unless (defined $inherit);
   local $pcfg->{CONTROL}->{get_opts}->{inherit} = $inherit;

   my $sensitive = ($self->_base_get2 ( $tag ))[1];

   DBUG_RETURN ( $sensitive );
}


#######################################

=item $encrypted = $cfg->chk_if_still_encrypted ( $tag[, $override_inherit] );

This function looks up the requested tag in the current section of the config
file and returns if this module thinks the existing value is still encrypted
(B<1>) or not (B<0>).

If the tag doesn't exist, it will always return B<0>!

This module always automatically decrypts everything unless the "Read" option
B<disable_decryption> was used.  In that case this method was added to detect
which tags still needed their values decrypted before they were used.

If I<override_inherit> is provided it overrides the current I<inherit> option's
setting.  If B<undef> it uses the current I<inherit> setting.  If I<inherit>
evaluates to true, it looks in the current section I<and> the main section for
a match.  Otherwise it just looks in the current section for the tag.

=cut

sub chk_if_still_encrypted
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $inherit = shift;       # undef, 0, or 1.

   my $pcfg = $self->{PARENT} || $self;

   $inherit = $pcfg->{CONTROL}->{get_opts}->{inherit}  unless (defined $inherit);
   local $pcfg->{CONTROL}->{get_opts}->{inherit} = $inherit;

   my $encrypted = ($self->_base_get2 ( $tag ))[3];

   DBUG_RETURN ( $encrypted );
}


#######################################

=item $bool = $cfg->chk_if_still_uses_variables ( $tag[, $override_inherit] );

This function looks up the requested tag in the current section of the config
file and returns if the tag's value contained variables that failed to expand
when the config file was parsed.  (B<1> - has variable, B<0> - none.)

If the tag doesn't exist, or you called C<set_value> to create it, this function
will always return B<0> for that tag!

There are only two cases where it can ever return true (B<1>).  The first case
is when you used the B<disable_variables> option.  The second case is if you
used the B<disable_decryption> option and you had a variable that referenced
a tag that is still encrypted.  But use of those two options should be rare.

If I<override_inherit> is provided it overrides the current I<inherit> option's
setting.  If B<undef> it uses the current I<inherit> setting.  If I<inherit>
evaluates to true, it looks in the current section I<and> the main section for
a match.  Otherwise it just looks in the current section for the tag.

=cut

sub chk_if_still_uses_variables
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;       # Reference to the current section.
   my $tag     = shift;       # The tag to look up ...
   my $inherit = shift;       # undef, 0, or 1.

   my $pcfg = $self->{PARENT} || $self;

   $inherit = $pcfg->{CONTROL}->{get_opts}->{inherit}  unless (defined $inherit);
   local $pcfg->{CONTROL}->{get_opts}->{inherit} = $inherit;

   my $bool = ($self->_base_get2 ( $tag ))[4];

   DBUG_RETURN ( $bool );
}


#######################################

=item $string = $cfg->toString ( [$addEncryptFlags[, \%override_read_opts] );

This function converts the current object into a string that is the equivalant
of the config file loaded into memory without any comments.

If I<$addEncryptFlags> is set to a non-zero value, it will add the needed
comment to the end of each line saying it's waiting to be encrypted.  So that
you may later call B<encrypt_string> to encrypt it.

If you provide I<%override_read_opts> it will use the information in that hash
to format the string.  Otherwise it will use the defaults from B<new()>.

=cut

sub toString
{
   DBUG_ENTER_FUNC ( @_ );
   my $self         = shift;
   my $encrypt_flag = shift;
   my $read_opts    = $self->_get_opt_args ( @_ );    # The override options ...

   my $pcfg = $self->{PARENT} || $self;
   my $rOpts = get_read_opts ($read_opts, $pcfg->{CONTROL}->{read_opts});

   my $cmt = "";
   if ( $encrypt_flag ) {
      $cmt = "      " . format_encrypt_cmt ( $rOpts );
   }

   my $line;
   my $string = "";
   my $cnt = 0;
   foreach my $name ( $self->find_sections () ) {
      my $cfg = $self->get_section ($name);
      $line = format_section_line ($name, $rOpts);
      $string .= "\n${line}\n";

      ++$cnt  if ( should_we_hide_sensitive_data ( $name, 1 ) );

      foreach my $tag ( $cfg->find_tags (undef, 0) ) {
         ++$cnt  if ( $cfg->chk_if_sensitive ($tag, 0) );

         $line = format_tag_value_line ($cfg, $tag, $rOpts);
         $string .= "   " . ${line} . ${cmt} . "\n";
      }
   }

   # Mask the return value if anything seems sensitive.
   DBUG_MASK (0) if ( $cnt > 0 );

   DBUG_RETURN ( $string );
}


#######################################

=item $hashRef = $cfg->toHash ( [$dropIfSensitive] );

This function converts the current object into a hash reference that is the
equivalant of the config file loaded into memory.  Modifying the returned
hash reference will not modify this object's content.

If a section has no members, it will not appear in the hash.

If I<$dropIfSensitive> is set to a non-zero value, it will not export any data
to the returned hash reference that this module thinks is sensitive.

The returned hash reference has the following keys.
S<$hash_ref-E<gt>{B<section>}-E<gt>{B<tag>}>.

=cut

sub toHash
{
   DBUG_ENTER_FUNC ( @_ );
   my $self      = shift;
   my $sensitive = shift;

   my %data;

   foreach my $sect ( $self->find_sections () ) {
      # Was the section name itself sensitive ...
      next  if ( $sensitive && should_we_hide_sensitive_data ( $sect, 1 ) );

      my %section_data;
      my $cfg = $self->get_section ($sect, 1);

      my $cnt = 0;
      foreach my $tag ( $cfg->find_tags (undef, 0) ) {
         my ($val, $hide) = $cfg->_base_get2 ($tag);
         next  if ( $sensitive && $hide );
         $section_data{$tag} = $val;
         ++$cnt;
      }

      # Only add a section that has tags in it!
      $data{$sect} = \%section_data  if ( $cnt );
   }

   DBUG_RETURN ( \%data );
}


#######################################

=back

=head2 Encryption/Decryption of your config files.

The methods here deal with the encryption/decryption of your config file before
you use this module to load it into memory.  They allow you to make the contents
of your config files more secure.

=over

=item $status = $cfg->encrypt_config_file ( [$file[, $encryptFile[, \%rOpts]]] );

This function encrypts all tag values inside the specified confg file that are
marked as ready for encryption and generates a new config file with everything
encrypted.  If a tag/value pair isn't marked as ready for encryption it is left
alone.  By default this label is B<ENCRYPT>.

After a tag's value has been encrypted, the label in the comment is updated
from B<ENCRYPT> to B<DECRYPT> in the config file.

If you are adding new B<ENCRYPT> tags to an existing config file that already
has B<DECRYPT> tags in it, you must use the same encryption related options in
I<%rOpts> as the last time.  Otherwise you won't be able to decrypt all
encrypted values.

Finally if you provide argument I<$encryptFile>, it will write the encrypted
file to that new file instead of overwriting the current file.  But if you do
this, you will require the use of the I<alias> option to be able to decrypt
it again using the new name.  This file only gets created if the return status
is B<1>.

If you leave off the I<$file> and I<\%rOpts>, it will instead use the values
inherited from the call to B<new>.

This method ignores any request to source in other config files.  You must
encrypt each file individually.

It is an error if basename(I<$file>) is a symbolic link and you didn't provide
I<$encryptFile>.

Returns:  B<1> if something was encrypted.  B<-1> if nothing was encrypted.
Otherwise B<0> on error.

=cut

sub encrypt_config_file
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;
   my $file    = shift;
   my $newFile = shift;
   my $rOpts   = shift;

   my $pcfg = $self->{PARENT} || $self;

   my $msg;
   if ( $file ) {
      $file = $self->_fix_path ( $file );
   } elsif ( $pcfg->{CONTROL}->{filename} ) {
      $file = $pcfg->{CONTROL}->{filename};
   } else {
      $msg = "You must provide a file name to encrypt!";
   }

   unless ( $msg || -f $file ) {
      $msg = "No such file to encrypt or it's unreadable! -- $file";
   }

   if ( -l $file && ! $newFile ) {
      $msg = "You can't encrypt a file via it's symbolic link -- $file";
   }

   my $scratch;
   if ( $newFile ) {
      $scratch = $self->_fix_path ($newFile);
      if ( $scratch eq $file ) {
         $msg = "Args: file & encryptFile must be different!";
      }
   } else {
      $scratch = $file . ".$$.encrypted";
   }

   if ( $rOpts ) {
      $rOpts = get_read_opts ($rOpts, $pcfg->{CONTROL}->{read_opts});
   } else {
      $rOpts = $pcfg->{CONTROL}->{read_opts};
   }

   if ( $msg ) {
      return DBUG_RETURN ( croak_helper ( $rOpts, $msg, 0 ) );
   }

   my $status = encrypt_config_file_details ($file, $scratch, $rOpts);

   # Some type of error ... or nothing was encrypted ...
   if ( $status == 0 || $status == -1 ) {
      unlink ( $scratch );

   # Replacing the original file ...
   } elsif ( ! $newFile ) {
      unlink ( $file );
      move ( $scratch, $file );
   }

   DBUG_RETURN ( $status );
}


#######################################

=item $status = $cfg->decrypt_config_file ( [$file[, $decryptFile[, \%rOpts]]] );

This function decrypts all tag values inside the specified confg file that are
marked as ready for decryption and generates a new config file with everything
decrypted.  If a tag/value pair isn't marked as ready for decryption it is left
alone.  By default this label is B<DECRYPT>.

After a tag's value has been decrypted, the label in the comment is updated
from B<DECRYPT> to B<ENCRYPT> in the config file.

For this to work, the encryption related options in I<\%rOpts> must match what
was used in the call to I<encrypt_config_file> or the decryption will fail.

Finally if you provide argument I<$decryptFile>, it will write the decrypted
file to that new file instead of overwriting the current file.  This file only
gets created if the return status is B<1>.

If you leave off the I<$file> and I<\%rOpts>, it will instead use the values
inherited from the call to B<new>.

This method ignores any request to source in other config files.  You must
decrypt each file individually.

It is an error if basename(I<$file>) is a symbolic link and you didn't provide
I<$decryptFile>.

Returns:  B<1> if something was decrypted.  B<-1> if nothing was decrypted.
Otherwise B<0> on error.

=cut

sub decrypt_config_file
{
   DBUG_ENTER_FUNC ( @_ );
   my $self    = shift;
   my $file    = shift;
   my $newFile = shift;
   my $rOpts   = shift;

   my $pcfg = $self->{PARENT} || $self;

   my $msg;
   if ( $file ) {
      $file = $self->_fix_path ( $file );
   } elsif ( $pcfg->{CONTROL}->{filename} ) {
      $file = $pcfg->{CONTROL}->{filename};
   } else {
      $msg = "You must provide a file name to encrypt!";
   }

   unless ( $msg || -f $file ) {
      $msg = "No such file to decrypt or it's unreadable! -- $file";
   }

   if ( -l $file && ! $newFile ) {
      $msg = "You can't decrypt a file via it's symbolic link -- $file";
   }

   my $scratch;
   if ( $newFile ) {
      $scratch = $self->_fix_path ( $newFile );
      if ( $scratch eq $file ) {
         $msg = "Args: file & decryptFile must be different!";
      }
   } else {
      $scratch = $file . ".$$.decrypted";
   }

   if ( $rOpts ) {
      $rOpts = get_read_opts ($rOpts, $pcfg->{CONTROL}->{read_opts});
   } else {
      $rOpts = $pcfg->{CONTROL}->{read_opts};
   }

   if ( $msg ) {
      return DBUG_RETURN ( croak_helper ( $rOpts, $msg, undef ) );
   }

   my $status = decrypt_config_file_details ($file, $scratch, $rOpts);

   # Some type of error ... or nothing was decrypted ...
   if ( $status == 0 || $status == -1 ) {
      unlink ( $scratch );

   # Replacing the original file ...
   } elsif ( ! $newFile ) {
      unlink ( $file );
      move ( $scratch, $file );
   }

   DBUG_RETURN ( $status );
}


#######################################

=item $out_str = $cfg->encrypt_string ( $string, $alias[, \%rOpts] );

This method takes the passed I<$string> and treats it's value as the contents of
a config file, comments and all.  Modifying the I<$string> afterwards will not 
affect things.

Since there is no filename to work with, it requires the I<$alias> to assist
with the encryption.  And since it's required its passed as a separate argument
instead of being burried in the optional I<%rOpts> hash.

It takes the I<$string> and encrypts all tag/value pairs per the rules defined
by C<encrypt_config_file>.  Once the contents of I$<string> has been encrypted,
the encrypted string is returned as I<$out_str>.  It will return B<undef> on
failure.

You can tell if something was encrypted by comparing I<$string> to I<$out_str>.

=cut

sub encrypt_string
{
   DBUG_MASK_NEXT_FUNC_CALL ( 2 );    # mask the alias.
   DBUG_ENTER_FUNC ( @_ );

   my $self      = shift;
   my $string    = shift;    # The string to treat as a config file's contents.
   my $alias     = shift;    # The alias to use during encryption ...
   my $read_opts = $self->_get_opt_args ( @_ );    # The override options ...

   unless ( $string ) {
      my $msg = "You must provide a string to use this method!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   unless ( $alias ) {
      my $msg = "You must provide an alias to use this method!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   # The filename is a reference to the string passed to this method!
   my $scratch;
   my $src_file = \$string;
   my $dst_file = \$scratch;

   # Put the alias into the read option hash ...
   local $read_opts->{alias} = basename ($alias);

   my $pcfg = $self->{PARENT} || $self;
   my $rOpts = get_read_opts ($read_opts, $pcfg->{CONTROL}->{read_opts});

   my $status = encrypt_config_file_details ($src_file, $dst_file, $rOpts);

   $scratch = undef  if ( $status == 0 );

   DBUG_RETURN ( $scratch );
}


#######################################

=item $out_str = $cfg->decrypt_string ( $string, $alias[, \%rOpts] );

This method takes the passed I<$string> and treats it's value as the contents of
an encrypted config file, comments and all.  Modifying the I<$string> afterwards
will not affect things.

Since there is no filename to work with, it requires the I<$alias> to assist
with the decryption.  And since it's required its passed as a separate argument
instead of being burried in the optional I<%rOpts> hash.

It takes the I<$string> and decrypts all tag/value pairs per the rules defined
by C<decrypt_config_file>.  Once the contents of I$<string> has been decrypted,
the decrypted string is returned as I<$out_str>.  It will return B<undef> on
failure.

You can tell if something was decrypted by comparing I<$string> to I<$out_str>.

=cut

sub decrypt_string
{
   DBUG_MASK_NEXT_FUNC_CALL ( 2 );    # mask the alias.
   DBUG_ENTER_FUNC ( @_ );

   my $self      = shift;
   my $string    = shift;    # The string to treat as a config file's contents.
   my $alias     = shift;    # The alias to use during encryption ...
   my $read_opts = $self->_get_opt_args ( @_ );    # The override options ...

   unless ( $string ) {
      my $msg = "You must provide a string to use this method!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   unless ( $alias ) {
      my $msg = "You must provide an alias to use this method!";
      return DBUG_RETURN ( croak_helper ($read_opts, $msg, undef) );
   }

   # The filename is a reference to the string passed to this method!
   my $scratch;
   my $src_file = \$string;
   my $dst_file = \$scratch;

   # Put the alias into the read option hash ...
   local $read_opts->{alias} = basename ($alias);

   my $pcfg = $self->{PARENT} || $self;
   my $rOpts = get_read_opts ($read_opts, $pcfg->{CONTROL}->{read_opts});

   my $status = decrypt_config_file_details ($src_file, $dst_file, $rOpts);

   $scratch = undef  if ( $status == 0 );

   DBUG_RETURN ( $scratch );
}


#######################################

=back

=head2 Handling Variables in your config file.

These methods are used to resolve variables defined in your config file when
it gets loaded into memory by this module. It is not intended for general use
except as an explanation on how variables work.

=over

=item ($value, $status) = $cfg->lookup_one_variable ( $variable_name );

This method takes the given I<$variable_name> and returns it's value.

It returns I<undef> if the given variable doesn't exist.  And the optional 2nd
return value tells us about the B<status> of the 1st return value.

If the B<status> is B<-1>, the returned value is still encrypted.  If set to
B<1>, the value is considered sensitive.  In all other cases this B<status> flag
is set to B<0>.

This method is frequently called internally if you define any variables inside
your config files when they are loaded into memory.

Variables in the config file are surrounded by anchors such as B<${>nameB<}>.
But it's passed as B<name> without any anchors when this method is called.

The precedence for looking up a variable's value to return is as follows:

  0. Is it the special "shft3" variable or one of it's variants?
  1. Look for a tag of that same name previously defined in the current section.
  2. If not defined there, look for the tag in the "main" section.
  3. Special Case, see note below about periods in the variable name.
  4. If not defined there, look for a value in the %ENV hash.
  5. If not defined there, does it represent a special Perl variable?
  6. If not defined there, is it a predefined Advanced::Config variable?
  7. If not defined there, is it some predefined special date variable?
  8. If not defined there, the result is undef.

If a variable was defined in the config file, it uses the tag's value when the
line gets parsed.  But when you call this method in your code after the config
file has been loaded into memory, it uses the final value for that tag.

The special B<${>shft3B<}> variable is a way to insert comment chars into a
tag's value in the config file when you can't surround it with quotes.  This
variable is always case insensive and if you repeat the B<3> in the name, you
repeat the comment chars in the substitution.

   * a = ${shft3}    - Returns "#" for a.
   * b = ${SHFT33}   - Returns "##" for b.
   * c = ${ShFt333}  - Returns "###" for c.
   * etc ...

And since this variable has special meaning, if you try to define one of the
B<SHFT3> variants as a tag in your config file, or call C<set_value> with it,
it will be ignored and a warning will be printed to your screen!

If the variable had a period (B<.>) in it's name, and it doesn't match anything
(rules 0 to 2), it follows rule B<3> and it treats it as a reference to a tag in
another section.  So see F<rule_3_section_lookup> for details on how this works.

This module provides you special predefined variables (rules 5, 6 & 7) to help
make your config files more dynamic without the need of a ton of code on your
end.  If you want to override the special meaning for these variables, all you
have to do is define a tag in the config file of the same name to override it.
Or just don't use these variables in the 1st place.

For rule B<5>, the special Perl variables you are allowed to reference are:
B<$$>, B<$0>, and B<$^O>.  (Each must appear in the config file as: B<${$}>,
B<${0}> or B<${^O}>.)

For rule B<6>, the predefined module variables are: ${PID}, ${PPID}, ${user},
${hostname}, ${program}, ${flavor} and ${sep} (The ${flavor} is defined by
F<Perl::OSType> and ${sep} is the path separator defined by F<File::Spec>
for your OS.)  The final variable ${section} tells which section this variable
was used in.

Finally for rule B<7> it provides some special date variables.  See
B<F<Advanced::Config::Options::set_special_date_vars>> for a complete list of
what date related variables are defined.  The most useful being ${today} and
${yesterday} so that you can dynamically name your log files
F</my_path/my_log.${today}.txt> and you won't need any special date roll logic
to start a new log file.

=cut

sub lookup_one_variable
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = shift;   # Reference to the current section.
   my $var  = shift;   # The name of the variable, minus the ${...}.

   my $pcfg = $self->{PARENT} || $self;     # Get the main section ...

   # Silently disable calling "die" or "warn" on all get/set calls ...
   local $pcfg->{CONTROL}->{get_opts}->{required} = -9876;

   my $opts = $pcfg->{CONTROL}->{read_opts};

   # Did we earlier request case insensitive tag lookups?
   $var = lc ($var)  if ( $opts->{tag_case} );

   # The default return values ...
   my ( $val, $mask_flag, $file, $encrypt_flag ) = ( undef, 0, "", 0 );

   if ( $var =~ m/^shft(3+)$/i ) {
      # 0. The special comment variable ... (Can't override)
      $val = $1;
      my $c = $opts->{comment};     # Usually a "#".
      $val =~ s/3/${c}/g;

   } else {
      # 1. Look in the current section ...
      ( $val, $mask_flag, $file, $encrypt_flag ) = $self->_base_get2 ( $var );

      # 2. Look in the parent section ... (if not already there)
      if ( ! defined $val && $self != $pcfg ) {
         ( $val, $mask_flag, $file, $encrypt_flag ) = $pcfg->_base_get2 ( $var );
      }

      # 3. Look in the requested section(s) ...
      if ( ! defined $val && $var =~ m/[.]/ ) {
         ($val, $mask_flag, $encrypt_flag) = $self->rule_3_section_lookup ( $var );
      }

      # 4. Look in the %ENV hash ...
      if ( ! defined $val && defined $ENV{$var} ) {
         $val = $ENV{$var};
         $mask_flag = should_we_hide_sensitive_data ($var);

         # Record so refresh logic will work when %ENV vars change.
         $pcfg->{CONTROL}->{ENV}->{$var} = $val;
      }

      # 5. Look at the special Perl variables ... (now done as part of 6.)
      # 6. Is it one of the predefined module variables ...
      #    Variables should either be all upper case or all lower case!
      #    But allowing for mixed case.
      if ( ! defined $val ) {
         if ( exists $begin_special_vars{$var} ) {
            $val = $begin_special_vars{$var};
         } elsif ( exists $begin_special_vars{lc ($var)} ) {
            $val = $begin_special_vars{lc ($var)};
         } elsif ( exists $begin_special_vars{uc ($var)} ) {
            $val = $begin_special_vars{uc ($var)};
         } elsif ( $var eq "section" ) {
            $val = $self->section_name ();
         }
      }

      # 7. Is it one of the special date variables ...
      #    All these date vars only use lower case!
      if ( ! defined $val ) {
         my $lc_var = lc ($var);
         if ( defined $pcfg->{CONTROL}->{DATES}->{$lc_var} ) {
            $val = $pcfg->{CONTROL}->{DATES}->{$lc_var};

            # Record so refresh logic will work when the date changes.
            # Values:
            #   0 - unknown date variable.    (so refresh will ignore it.)
            #   1 - MM/DD/YYYY referenced.    (refresh on date change.)
            #   2 - MM or MM/YYYY referenced. (refresh if the month changes.)
            #   3 - YYYY referenced.          (refresh if the year changes.)
            my $rule = 0;
            if ( $lc_var =~ m/^((yesterday)|(today)|(tomorrow)|(dow)|(doy)||(dom))$/ ) {
               $rule = 1;

            } elsif ( $lc_var =~ m/^((last)|(this)|(next))_month$/ ) {
               $rule = 2;

            } elsif ( $lc_var =~ m/^((last)|(this)|(next))_period$/ ) {
               $rule = 2;

            } elsif ( $lc_var =~ m/^((last)|(this)|(next))_year$/ ) {
               $rule = 3;
            }
            # Don't record if {timestamp} used. (rule == 0)

            # Save the smallest rule referenced ...
            if ( $rule != 0 ) {
               if ( $pcfg->{CONTROL}->{DATE_USED} == 0 ) {
                  $pcfg->{CONTROL}->{DATE_USED} = $rule;
               } elsif ( $pcfg->{CONTROL}->{DATE_USED} > $rule ) {
                  $pcfg->{CONTROL}->{DATE_USED} = $rule;
               }
            }
         }
      }

      # 8. Then it must be undefined ... (IE: an unknown variable)
   }

   # Mask the return value in fish ???
   DBUG_MASK ( 0 )  if ( $mask_flag);

   # Is the return value still encryped ???
   $mask_flag = -1   if ( $encrypt_flag );

   DBUG_RETURN ( $val, $mask_flag )
}

# ==============================================================

=item ($value, $sens, $encrypt) = $cfg->rule_3_section_lookup ( $variable_name );

When a variable has a period (B<.>) in it's name, it could mean that this
variable is referencing a tag from another section of the config file.  So this
helper method to F<lookup_one_variable> exists to perform this complex check.

For example, a variable called B<${>xxx.extraB<}> would look in Section "xxx"
for tag "extra".

Here's another example with multiple B<.>'s in it's name this time.  It would
look up variable B<${>one.two.threeB<}> in Section "one.two" for tag "three".
And if it didn't find it, it would next try Section "one" for tag "two.three".

If it found such a variable, it returns it's value.  If it didn't find anything
it returns B<undef>.  The optional 2nd and 3rd values tells you more about the
returned value.

I<$sens> is a flag that tells if the data value should be considered sensitive
or not.

I<$encrypt> is a flag that tells if the value still needs to be decrypted or
not.

=cut

sub rule_3_section_lookup
{
   DBUG_ENTER_FUNC ( @_ );
   my $self     = shift;
   my $var_name = shift;        # EX: abc.efg.xyz ...

   my ( $val, $fish_mask, $f, $encrypted ) = ( undef, 0, "", 0 );

   # If the variable name isn't named correctly ...
   if ( $var_name !~ m/\./ ) {
      return DBUG_RETURN ($val, $fish_mask, $encrypted);
   }

   # Silently disable calling "die" or "warn" on all get/set calls ...
   my $pcfg = $self->{PARENT} || $self;     # Get the main section ...
   local $pcfg->{CONTROL}->{get_opts}->{required} = -9876;

   # So trailing ... in varname won't cause issues ...
   my @parts = split (/\s*[.]\s*/, $var_name . ".!");
   pop (@parts);     # Remove that pesky trailing "!" I just added!

   # Now look for the requested tag in the proper section ...
   for ( my $i = $#parts - 1;  $i >= 0;  --$i ) {
      my $section = join (".", (@parts)[0..$i]);
      my $sect = $self->get_section ( $section );
      next  unless ( defined $sect );

      my $tag = join (".", (@parts)[$i+1..$#parts]);
      ( $val, $fish_mask, $f, $encrypted ) = $sect->_base_get2 ( $tag );

      # Stop looking if we found anything ...
      if ( defined $val ) {
         DBUG_PRINT ("RULE-3", "Found Section/Tag: %s/%s", $section, $tag);
         last;
      }
   }

   # Controls if the return value needs to be masked in fish ...
   DBUG_MASK ( 0 )  if ( $fish_mask );

   DBUG_RETURN ( $val, $fish_mask, $encrypted );
}

# ======================================================================

=item $cfg->print_special_vars ( [\%date_opts] );

This function is for those individuals who don't like to read the POD too
closely, but still need a quick and dirty way to list all the special config
file variables supported by this module.

It prints to STDERR the list of these special variables and their current
values.  These values can change based on the options used in the call to new()
or what OS you are running under.  Or even what today's date is.

Please remember it is possible to override most of these variables if you first
define them in your own config file or with an environment variable of the
same name.  But this function doesn't honor any overrides.  It just provides
this list on an FYI basis.

The optional I<date_opts> hash allows you to play with the various date formats
available for the special date vars.  See B<The Special Date Variable Formatting
Options> section of the Options module for what these options are.  Used to
override what was set in the call to new().

=cut

sub print_special_vars
{
   DBUG_ENTER_FUNC ( @_ );
   my $self = $_[0];    # Will shift later if it's an object as expected!

   # Detect if called as part of the object or not.
   my $is_obj = ( defined $self && ref($self) eq __PACKAGE__ );
   if ( $is_obj ) {
      shift;      # $cfg->print_special_vars();
   } elsif ( defined $self && $self eq __PACKAGE__ ) {
      shift;      # Advanced::Config->print_special_vars();
   } else {
      # No shift, called via: Advanced::Config::print_special_vars();
   }

   my $date_opts = $_[0];     # The optional argument ...

   # If it wasn't a hash reference, assume passed by value ...
   if ( defined $date_opts && ref ($date_opts) eq "" ) {
      my %data = @_;
      $date_opts = \%data;
   }

   # -------------------------------------------------------------
   # Start of real work ...
   # -------------------------------------------------------------

   my ($pcfg, $cmt, $la, $ra, $asgn) = (undef, '#', '${', '}', '=');
   if ( $is_obj ) {
      # Get the main/parent section to work against!
      $pcfg = $self->{PARENT} || $self;

      # Look in the Read Options hash for current settings ...
      $cmt  = $pcfg->{CONTROL}->{read_opts}->{comment};
      $la   = $pcfg->{CONTROL}->{read_opts}->{variable_left};
      $ra   = $pcfg->{CONTROL}->{read_opts}->{variable_right};
      $asgn = $pcfg->{CONTROL}->{read_opts}->{assign};
   }

   print STDERR "\n";
   print STDERR "${cmt} Examples of the Special Predefined Comment Variable ... (controlled via new)\n";
   print STDERR "${cmt} You can't override these variables.\n";

   unless ( $is_obj ) {
      print STDERR "   \${shft3}   = #\n";
      print STDERR "   \${shft33}  = ##\n";
      print STDERR "   \${shft333} = ###\n";
   } else {
      # Works since Rule # 0 and can't be overriden.
      foreach ( "shft3", "shft33", "shft333" ) {
         my $v = $self->lookup_one_variable ($_);
         print STDERR "   ${la}$_${ra} ${asgn} ${v}\n";
      }
   }
   print STDERR "   ...\n\n";

   print STDERR "${cmt} Any of the variables below can be overriden by putting them\n";
   print STDERR "${cmt} into %ENV or predefining them inside your config files!\n\n";

   print STDERR "${cmt} The Special Predefined Variables ... (OS/Environment dependant)\n";
   foreach my $k ( sort keys %begin_special_vars ) {
      print STDERR "   ${la}$k${ra} ${asgn} $begin_special_vars{$k}\n";
   }

   print STDERR "\n";
   print STDERR "${cmt} The value of this variable changes based on which section of the config file\n";
   print STDERR "${cmt} it's used in!  It's value will always match the name of the current section!\n";
   my $section = $is_obj ? $self->section_name () : DEFAULT_SECTION;
   print STDERR "   ${la}section${ra} ${asgn} $section\n";

   print STDERR "\n";

   my ($opts, %dt);
   unless ( $is_obj ) {
      $opts = get_date_opts ( $date_opts );
   } else {
      $opts = get_date_opts ( $date_opts, $pcfg->{CONTROL}->{date_opts} );
   }
   my $language = $opts->{month_language};
   my $type = ( $opts->{use_gmt} ) ? "gmtime" : "localtime";

   print STDERR "${cmt} The Special Predefined Date Variables ... (in ${language})\n";
   print STDERR "${cmt} The format and language used can vary based on the date options selected.\n";
   print STDERR "${cmt} Uses ${type} to convert the current timestamp into the other values.\n";

   set_special_date_vars ( $opts, \%dt );
   foreach my $k ( sort keys %dt ) {
      print STDERR "   ${la}$k${ra} ${asgn} $dt{$k}\n";
   }

   print STDERR "\n";

   DBUG_VOID_RETURN ();
}

# ======================================================================

=back

=head1 ENVIRONMENT

Expects PERL5LIB to point to the root of the custom Module directory if not
installed in Perl's default location.

=head1 COPYRIGHT

Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Advanced::Config::Options> - Handles the configuration of the config object.

L<Advanced::Config::Date> - Handles date parsing for get_date().

L<Advanced::Config::Reader> - Handles the parsing of the config file.

L<Advanced::Config::Examples> - Provides some sample config files and commentary.

=cut

###################################################
#required if module is included w/ require command;
1;
