#
# bibliography package for Perl
#
# The main package.
#
# The bp package is written by Dana Jacobsen (dana@acm.org).
# Copyright 1992-1996 by Dana Jacobsen.
#
# Permission is given to use and distribute this package without charge.
# The author will not be liable for any damage caused by the package, nor
# are any warranties implied.
#
# 26 March 1996

package bib;

$glb_version = '0.2.97 (19 Dec 96)';

# See the file NOTES in the distribution for additional notes.

#
#
# Major functions available for users to call:
#
#
#    format();
#    format($format);
#    format($input_format, $output_format);
#
#    open($file_name);
#    open($file_name, $format);
#
#    close();
#    close($file_name);
#
#    read();
#    read($file_name);
#    read($file_name, $format);
#
#    write($file, $output_string);
#    write($file, $output_string, $format);
#
#    convert($record);
#
#    explode($record);
#    explode($record, $file_name);
#
#    implode(%record);
#    implode(%record, $file_name);
#
#    tocanon(%record);
#    tocanon(%record, $file_name);
#
#    fromcanon(%record);
#    fromcanon(%record, $file_name);
#
#    clear();
#    clear($file_name);
#
#           [ file bp-p-option ] 
#
#    stdargs(@ARGV)
#
#    options($general_opts, $converter_opts, $infmt_opts, $outfmt_opts);
#
#    doc($what);
#
#
# Functions available primarily for modules to call:
#
#
#    parse_format($format_string)
#
#           [ file bp-p-debug ]
#
#    panic($string);
#
#    debugs($statement, $level);
#    debugs($statement, $level, $module);
#
#    check_consist();
#
#    debug_dump($what_kind);
#
#    ok_print($variable);
#
#           [ file bp-p-errors ]
#
#    errors($warning_level);
#    errors($warning_level, $error_level);
#    errors($warning_level, $error_level, $header_string);
#
#    goterror($error_message);
#    goterror($error_message, $linenum);
#
#    gotwarn($warning_message);
#    gotwarn($warning_message, $linenum);
#
#           [ file bp-p-dload ]
#
#    load_format($format_name);
#
#    load_charset($charset_name);
#
#    load_converter($converter_name);
#
#    find_bp_files();
#    find_bp_files($rehash);
#
#    reg_format($long_name, $short_name, $pkg_name, $charset_name, @info);
#
#           [ file bp-p-cs ]
#
#    unicode_to_canon($unicode);
#
#    canon_to_unicode($character);
#
#    decimal_to_unicode($number);
#
#    unicode_to_decimal($unicode);
#
#    unicode_name($unicode);
#
#    meta_name($metacode);
#
#    meta_approx($metacode);
#
#    unicode_approx($unicode);
#
#    nocharset($string);
#
#           [ file bp-p-util ]
#
#    bp_util'mname_to_canon($names_string);
#    bp_util'mname_to_canon($names_string, $flag_reverse_author);
#
#    bp_util'name_to_canon($name_string);
#    bp_util'name_to_canon($name_string, $flag_reverse_author);
#
#    bp_util'canon_to_name($name_string);
#    bp_util'canon_to_name($name_string, $how_formatted);
#
#    bp_util'parsename($name_string);
#    bp_util'parsename($name_string, $how_formatted);
#
#    bp_util'parsedate($date_string);
#
#    bp_util'canon_month($month_string);
#
#    bp_util'genkey(%canon_record);
#
#    bp_util'regkey($key);
#
#
# Internal functions:
#
#
#    close_input($file_name);
#
#    close_output($file_name);
#
#           [ file bp-p-debug ]
#
#    log2($number);
#
#           [ file bp-p-option ]
#
#    parse_num_option($value);
#
#    parse_option($option);
#
#           [ file bp-p-stdbib ]
#
#    open_stdbib($file_name);
#
#    close_stdbib($file_name);
#
#    read_stdbib($file_name);
#
#    write_stdbib($file_name, $output_string);
#
#    clear_stdbib();
#
#    options_stdbib();
#
#    implode_stdbib();
#
#    explode_stdbib();
#
#    tocanon_stdbib();
#
#    fromcanon_stdbib();
#



# Global variables.  Most of these do not need to be initialized, but this
# guarantees that they are, and also lists all of them.  Anything not here is
# an error!

#
# Here are the functions we expect format modules to have
#

@glb_expfuncs = ('options', 'open', 'close', 'read', 'write',
                 'explode', 'implode', 'tocanon', 'fromcanon',
                 'clear' );
#
# The higher the number, the fewer the messages.  Generally:
#       2 -     10  multiple messages per line
#      10 -    100  one message per line
#     100 -   1000  one message per record
#    1000 -  70000  major routines
#
# debugging of 2 will print all messages, and additionally will turn on
# debug dumping of all globals each time check_consist is called.
#
# Do not use 0 or 1.  They mean false and true, respectively.

$glb_debug = 0;
$glb_moddebug = 0;
$glb_debug = $glb_moddebug = 1 if $^W;

#
# This is the prefix to use when looking for files.  Eventually this will be
# "bp/" which means we look in a subdirectory, but for development it's
# easier to leave everything at the top level.
#
$glb_bpprefix = 'bp-';

#
# informat and outformat are the arguments used to the 'format' subroutine.
# they are set only in the format routine, and used to determine the proper
# routines to call with 'options', 'open'.
#
$glb_Iformat = '';
$glb_Oformat = '';

#
# The current format in use.  This is set right before calls to module
# routines.  It is used especially by the stdbib stuff, so we can have one
# routine to support multiple formats.  It doesn't do anything different
# depending on the format, but it would like to know the name.
#
$glb_current_fmt  = undef;
$glb_current_cset = undef;

#
# The current file handle.  Since we keep input and output file handles
# seperate, it is nice to just have this available, since the calling
# function already determines it.  It is _not_ available for explode, implode,
# tocanon, fromcanon, and clear, as they should not do any I/O to any given
# file (indeed, there may be no file at all).  Obviously, this is also not
# set for open, since its job is to set it!
$glb_current_fh  = undef;

#
# rfmt is the real format of a particular file.
# rcset is the real character set of a particular file.
#
# The open routine will set these appropriately, using the information
# gleaned in the auto module to set these to the real values it determines,
# if the file is opened with 'auto' format.
#
# Since they are the real formats, they are used when calling 'explode',
# 'implode', 'tocanon', 'fromcanon', and 'clear'.
#
# The auto package only sets these to a format approved by load_format.
#
# XXXXX  clear should call auto'clear which then calls real clear.
#
%glb_Irfmt =  ();
%glb_Ircset = ();

%glb_Orfmt =  ();
%glb_Orcset = ();

#
# This maps the name of a file to the file pointer, so we can happily read
# and write files to these names.
#
%glb_Ifilemap = ();
%glb_Ofilemap = ();

#
# The current file names.
# An open, read, or write will set it, and a close will undefine it.
# These are initialized to STDIN and STDOUT.
#
#$glb_Ifilename = '-';
#$glb_Ofilename = '>>-';
# XXXXX initialize to undef, because we don't know anything yet.
$glb_Ifilename = undef;
$glb_Ofilename = undef;

#
# The map of input files and record numbers.
# XXXXX how about an output one also?
# XXXXX It would be nice to be able to return this value to the user
#
%glb_filelocmap = ();

#
# A more verbose location.  This is set by packages, which need to keep
# track of their own information, and just set this when they need to.
# the error routines will print this out.
# It will get undef'd any time filename is changed (open, read, close).
#
# This is particularly useful for pointing to the first line of a record.
# See bp-refer.pl for an example of how to use this.
#
$glb_vloc = undef;

#
# This is the variable used to map functions.  The key is the name of the
# format, a comma, then the name of the function.  For example,
#     $formats{'bibtex', "write"}
# would be set to the name of the routine that closes BibTeX files.
#
%formats = ();

#
# This variable holds information about special converters, which will get
# loaded and invoked when the 'convert' call is used.  The first time we
# try conversion with glb_cvtname defined, we try to load it.  If we can't
# find it, we undef glb_cvtname, which means we bypass the check from now
# on (at least until we call format again).
#
%special_converters = ();

#
# This handles the name we use to find a converter.  It's set in 'format'.
#
$glb_cvtname = undef;

#
# This is the list of character sets.
#
%charsets = ();

#
# We use this variable to perform indirect function calls.
# It can _never_ be counted on to contain anything or to retain its value.
#
$func = '';

#
# The error global variables
#
# The default error settings are to die immediately on an error,
# and print all warnings immediately.  Setting the level of
# errors to delay or ignore could cause a lot of headaches.
#
$glb_error_level = 3;
$glb_warn_level  = 2;
# If this is set, we also store the error/warn location in the delay string.
$glb_error_saveline = 0;
#  Variables we keep track of totals in.  &errors('clear') will flush these.
$glb_num_errors = 0;
$glb_num_warns  = 0;
$glb_str_errors = undef;
$glb_str_warns  = undef;

#
# The supported formats and character sets.
# It is used by find_bp_files to cache the information, so always call that
# function -- never use this variable!
#
$glb_supported_files = undef;

#
# Character set stuff.  We define an escape character, then some definitions
# that use this escape character.  Sort of a markup language.
#
# XXXXX Disadvantages of using non-printable escape character:
#           You can't type it into most editors.
#           It looks funny if you try to view it.
#       Advantages:
#           It saves time by not having to escape user characters very often.
#           We won't get into regex trouble by using it (cf. "$")
#
$cs_escape = "\034";
$cs_char_escape = $cs_escape . 'e';
$cs_sep         = $cs_escape . '/';
$cs_sep2        = $cs_escape . ',';
$cs_temp	= $cs_escape . 't'; # temporary character not ever in text
$cs_ext         = $cs_escape . 'n'; # (followed by the Unicode entry in hex)
                                    # (e.g.  en00A5  -->  Yen sign)
$cs_meta        = $cs_escape . 'm'; # (followed by our meta table entry in hex)
                                    # (e.g.  em00A4  -->  font change italics)

# That's all the cs stuff.  We use 8bit characters internally.


##################
#
# Options
#
##################

# 0: don't ever call cs routines, 1: call them
$opt_CSConvert = 1;

# 0: don't protect output characters, 1: protect.  e.g. in TeX '#' -> '\#'
$opt_CSProtect = 1;

# XXXXX We use a search string given by each charset.  This should handle
#       even the case where a format has a different 7 bit mapping.

# The default debugging for perl -w, or 'debugging=on'
$opt_default_debug_level = 8000;



require "${glb_bpprefix}p-debug.pl";
# loads:
# bib'assert
# bib'panic
# bib'debugs
# bib'check_consist
# bib'debug_dump
# bib'okprint

require "${glb_bpprefix}p-errors.pl";
# loads:
# bib'errors
# bib'goterror
# bib'gotwarn


######
#
# formats are in the form: "format:cset"
#
# There is a possibility that this will change, but probably just to add
# versions.  The format routine and the auto module make these strings.
# A few of the routines now just use split(/:/, $format) instead of calling
# this routine since it's much faster.
#
sub parse_format {
  local($pformat) = @_;

  &panic("parse_format called with no arguments") unless defined $pformat;

  &debugs("parse_format: $pformat", 32);

  split(/:/, $pformat);
}


######

sub format {
  local($ifmt, $ofmt) = @_;
  local($success) = 0;
  local($fmti, $fmto, $cset);

  # if called with no arguments, return our formats.
  if (  (!defined $ifmt)  &&  (!defined $ofmt)  ) {
    return ($glb_Iformat, $glb_Oformat);
  }

  $ofmt = $ifmt  unless defined $ofmt;

  # XXXXX make sure this is ok.  What is Iformat is set to 'bibtex:troff' and
  #       I then call format with 'bibtex' as my format?  Presumably I would
  #       want Iformat set to 'bibtex:tex' now, yes?

  if ( ($glb_Iformat =~ /^$ifmt:/)  &&  ($glb_Oformat =~ /^$ofmt:/)  ) {
    return 1;
  }

  &debugs("format ( $ifmt -> $ofmt )", 32768);

  $glb_cvtname = undef;   # we don't want to call some strange converter!

  # special: if ifmt or ofmt is a null string, then we want to leave
  # the current setting alone!

  if ($ifmt eq '') {
    $success++;
    ($fmti, $cset) = &parse_format($glb_Iformat);
  } elsif (  ($fmti, $cset) = &load_format($ifmt)  ) {
    # XXXXX should implement this, or at least hook into it
    return &goterror("auto charset recognition is unimplemented")
           if ( ($cset eq 'auto') && ($fmti ne 'auto') );
    $success++;
    $glb_Iformat = "$fmti:$cset";
    # XXXXX Should we open stdin here?
  }

  if ($ofmt eq '') {
    $success++;
    ($fmto, $cset) = &parse_format($glb_Oformat);
  } elsif (  ($fmto, $cset) = &load_format($ofmt)  ) {
    return &goterror("auto charset recognition is unimplemented")
           if ( ($cset eq 'auto') && ($fmto ne 'auto') );
    $success++;
    $glb_Oformat = "$fmto:$cset";
    # XXXXX open STDOUT to our format.  Right?  This is a re-open.
    #       17 Nov 95, changed to >>- from >-.
    &open('>>-') if $fmto ne "auto";
  }

  # If we have a second format and we're successful, then set converter name.
  # The name looks like "ref2btx", or "ins2mrc".  This will be set to undef
  # if we don't have a safely loaded converter, or the name of it if we do.
  # We also don't have special converters between the same format.
  if (  ($success == 2)  &&  ($fmti ne $fmto)  ) {
    $glb_cvtname = &load_converter(   $formats{$fmti, 'i_sname'} . '2'
                                    . $formats{$fmto, 'i_sname'});
  }

  &check_consist;

  ($success == 2);
}

######

require "${glb_bpprefix}p-dload.pl";
# loads:
# bib'load_format
# bib'load_charset
# bib'find_bp_files
# bib'reg_format

######

require "${glb_bpprefix}p-cs.pl";
# loads:
# variables used by the cs routines
# bib'nocharset
# bib'unicode_to_canon

######

require "${glb_bpprefix}p-option.pl";
# loads:
# bib'stdargs
# bib'options
# bib'parse_num_option
# bib'parse_option
# bib'doc

######     open("file" [,"format"] );

# Much like the normal open call, we use "foo" to open foo for read, ">foo"
# to open for write, and ">>foo" for append.
#
# Note that because of the way Perl filehandles are transferred, I can't tell
# the difference between STDOUT and 'STDOUT', so you must always use '-' for
# STDIN and '>-' (or '>>-') for STDOUT.
#
# XXXXX You can get the routines confused by giving them 'foo' and './foo'
#       which point to the same file of course, but they have different names.

sub open {
  local($file, $format) = @_;
  local($name, $mode);
  local($fmt, $cset);

  &panic("open called with no arguments") unless defined $file;

  #&check_consist;

  if ($file =~ /^>>(.*)/) {
    $mode = 'append';  $name = $1;
  } elsif ($file =~ /^>(.*)/) {
    $mode = 'write';   $name = $1;
  } else {
    $mode = 'read';    $name = $file;
  }
  # XXXXX for now, warn them about this.
  &gotwarn("Using STDIN ${mode}s to the file 'STDIN'") if $name eq 'STDIN';
  &gotwarn("Using STDOUT ${mode}s to the file 'STDOUT'") if $name eq 'STDOUT';
  &gotwarn("Using STDERR ${mode}s to the file 'STDERR'") if $name eq 'STDERR';

  # We allow '-' to be read and written to at the same time.  No others.
  # XXXXX For now, files cannot be re-opened without an explicit close.
  if ($name ne '-') {
    if ($mode eq 'read') {
      return &goterror("file $name is already opened for write")
             if defined $glb_Orfmt{$name};
      return &goterror("re-opening file $name") if defined $glb_Irfmt{$name};
    } else {
      return &goterror("file $name is already opened for read")
             if defined $glb_Irfmt{$name};
      return &goterror("re-opening file $name") if defined $glb_Orfmt{$name};
    }
  }

  $glb_vloc = undef;

  if (defined $format) {
    return undef  unless ($fmt, $cset) = &load_format($format);
  } else {
    if ($mode eq 'read') {
      ($fmt, $cset) = &parse_format($glb_Iformat);
    } else {
      ($fmt, $cset) = &parse_format($glb_Oformat);
    }
  }

  if ($mode eq 'read') {
    $glb_Ifilename = $name;
    $glb_filelocmap{$name} = 0;
    $glb_current_fh = "bib'GFMI" . $name;
    # no strict 'subs';
    $glb_current_fh = STDIN   if $name eq '-';  # magic filehandle
  } else {
    $glb_Ofilename = $name;
    $glb_current_fh = "bib'GFMO" . $name;
    # no strict 'subs';
    $glb_current_fh = STDOUT  if $name eq '-';  # magic filehandle
  }

  &debugs("opening $name<$fmt:$cset> for $mode", 4096);

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $func = $formats{$fmt, "open"};
  $fmt = &$func($file);  # pass the original argument, including the mode

  if (defined $fmt) {
    # if we don't know our cset, then open should have returned it
    if ($cset eq 'auto') {
      ($fmt, $cset) =  &parse_format($fmt);
    } else {
      ($fmt) =  &parse_format($fmt);
    }

    if ($mode eq 'read') {
      $glb_Irfmt{$name}  = $fmt;
      $glb_Ircset{$name} = $cset;
      $glb_Ifilemap{$name} = $glb_current_fh;
    } else {
      $glb_Orfmt{$name}  = $fmt;
      $glb_Orcset{$name} = $cset;
      $glb_Ofilemap{$name} = $glb_current_fh;
    }

    &debugs("opened $name<$fmt:$cset> for $mode", 1024);
  } else {
    &debugs("unable to open $name with format $format for $mode", 1024);
    # XXXXX Assume that the module gave its own error message for failure
  }

  &check_consist;

  if (wantarray) {
    ($fmt, $cset);
  } else {
    $fmt;
  }
}


######     close( ["file"] );

# XXXXX Since we don't currently allow files to be opened for read and write
#       simultaneously we know which maps to use.  If we allow this sometime,
#       then we'll be in trouble.
#
# XXXXX We DO allow '-' to be opened for read and write.
#       1) the default map is input, unless the file starts with '>'.
#       2) if a file is not found in the default map, then the other is tried.
#
#       This means that '>-' must be given to close STDOUT -- if not, you will
#       end up closing STDIN.  The other routines will _not_ strip off a '>'.
#
# With no arguments, we close the last INPUT file accessed.

sub close {
  local($file) = @_;
  local($result);

  #&check_consist;

  # a close with no arguments closes the last file read from.
  $file = $glb_Ifilename unless defined $file;
  # check for file undefined?

  # XXXXX should we allow an optional extra > here (for append)?
  if ($file =~ /^>(.*)/) {
    $result = &close_output($1);
  } else {
    # try input
    $result = &close_input($file);
    # try output if that failed.
    $result = &close_output($file) unless defined $result;
  }
  return &goterror("Closing unopened file $file") unless defined $result;

  &check_consist;

  $result;
}

sub close_input {
  local($name) = @_;
  local($result);

  return undef unless defined $glb_Irfmt{$name};

  &debugs("closing input file $name", 512);

  $glb_current_fmt  = $glb_Irfmt{$name};
  $glb_current_cset = $glb_Ircset{$name};
  $glb_current_fh   = $glb_Ifilemap{$name};
  $func = $formats{$glb_Irfmt{$name}, "close"};
  $result = &$func($name);

  delete $glb_Irfmt{$name};
  delete $glb_Ircset{$name};
  delete $glb_Ifilemap{$name};
  delete $glb_filelocmap{$file};
  if ($name eq $glb_Ifilename) {
    $glb_Ifilename = undef;
    $glb_vloc = undef;
  }
  $result;
}

sub close_output {
  local($name) = @_;
  local($result);

  return undef unless defined $glb_Orfmt{$name};

  &debugs("closing otuput file $name", 512);

  $glb_current_fmt  = $glb_Orfmt{$name};
  $glb_current_cset = $glb_Orcset{$name};
  $glb_current_fh   = $glb_Ofilemap{$name};
  $func = $formats{$glb_Orfmt{$name}, "close"};
  $result = &$func($name);
  delete $glb_Orfmt{$name};
  delete $glb_Orcset{$name};
  delete $glb_Ofilemap{$name};
  if ($name eq $glb_Ofilename) {
    $glb_Ofilename = undef;
    $glb_vloc = undef;
  }
  $result;
}


######     read( ["file", "format"] );

sub read {
  local($file, $format) = @_;
  local($fmt, $cset);

  # a read with no arguments reads from the last file read from or opened.
  $file = $glb_Ifilename unless defined $file;

  if (!defined $glb_Irfmt{$file}) {
    return &goterror("Reading from unopened file $file");
  }

  $glb_Ifilename = $file;
  $glb_vloc = undef;

  if ( (defined $format)  &&  ($format ne $glb_Irfmt{$file}) ) {
    return undef  unless ($fmt, $cset) = &load_format($format);
    &gotwarn("File '$file' <format $glb_Irfmt{$file}> read as '$format'.");
  } else {
    $fmt  = $glb_Irfmt{$file};
    $cset = $glb_Ircset{$file};
  }

  #&debugs("reading $file<$fmt>", 32);

  $glb_filelocmap{$file}++;

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $glb_current_fh   = $glb_Ifilemap{$file};
  $func = $formats{$fmt, "read"};
  &$func($file);
}

######     write( "file", "output-string", ["format"] );
#
# XXXXX We should have a way of writing to a string.  Probably with file
#       undefined, but output-string defined.  What format will we be writing?
#       <sigh> we use the file to determine our format....

sub write {
  local($file, $out, $format) = @_;
  local($fmt, $cset);

  &panic("write called with no arguments") unless defined $file;
  &panic("write called with no output")    unless defined $out;

  if (!defined $glb_Orfmt{$file}) {
    return &goterror("Writing to unopened file $file");
  }

  if ( (defined $format)  &&  ($format ne $glb_Orfmt{$file}) ) {
    return undef  unless ($fmt, $cset) = &load_format($format);
    &gotwarn("File '$file' <format $glb_Orfmt{$file}> written as '$format'.");
  } else {
    $fmt  = $glb_Orfmt{$file};
    $cset = $glb_Orcset{$file};
  }

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $glb_current_fh   = $glb_Ofilemap{$file};
  $func = $formats{$fmt, "write"};
  &$func($file, $out);
}

######
#
# convert is called when you want to convert between the informat and the
# outformat.  It's always a good idea to use convert instead of doing the
# calls to explode->tocanon->fromcanon->implode yourself.  Two reasons --
# first, if the in and out formats are the same, convert will just return,
# which will save you a lot of trouble.  Second, it searches for special
# converters that can be set up to handle conversions from one type to
# another directly.  This can not only be a lot faster, but can give you
# better results.
#
# XXXXX Test conversion or 'auto:tex' to 'auto:troff'.
#       This should convert between any format, but with TeX characters, to
#       the same format, but with troff characters.
#
######     convert( "recin" );
#
sub convert {
  local($recin) = @_;
  local($ifmt, $icset);
  local($ofmt, $ocset);

  &panic("convert called with no arguments") unless defined $recin;

  # XXXXX Should we be converting between Iformat and Oformat, or last file
  #       in and lastfile out?

  # $ifmt  = $glb_Irfmt{$glb_Ifilename};
  # $icset = $glb_Ircset{$glb_Ifilename};

  # $ofmt  = $glb_Orfmt{$glb_Ofilename};
  # $ocset = $glb_Orcset{$glb_Ofilename};

  # ($ifmt, $icset) = &parse_format($glb_Iformat)  unless defined $ifmt;
  # ($ofmt, $ocset) = &parse_format($glb_Oformat)  unless defined $ofmt;

  # XXXXX We now use the format specs, and back off to the most recent file
  #       only if we're auto formatting.

  ($ifmt, $icset) = split(/:/, $glb_Iformat);
  ($ofmt, $ocset) = split(/:/, $glb_Oformat);

  &debugs("conv1 <$ifmt:$icset> to <$ofmt:$ocset>", 512) if $glb_debug;
  if ($ifmt eq 'auto') {
    return &goterror("Convert has no input format") unless defined $glb_Ifilename;
    $ifmt  = $glb_Irfmt{$glb_Ifilename};
  }
  if ($icset eq 'auto') {
    return &goterror("Convert has no input charset") unless defined $glb_Ifilename;
    $icset = $glb_Ircset{$glb_Ifilename};
  }
  if ($ofmt eq 'auto') {
    if (defined $glb_Ofilename) {
      $ofmt  = $glb_Orfmt{$glb_Ofilename};
    } else {
      $ofmt = $ifmt;
    }
  }
  if ($ocset eq 'auto') {
    if (defined $glb_Ofilename) {
      $ocset = $glb_Orcset{$glb_Ofilename};
    } else {
      $ocset = $icset;
    }
  }
  &debugs("conv2 <$ifmt:$icset> to <$ofmt:$ocset>", 512) if $glb_debug;
     
  if ($ifmt eq $ofmt) {
    # same format, same character set
    return $recin  if ($icset eq $ocset);
    # same format, diff charset, but they don't want conversion.
    return $recin  unless $opt_CSConvert;

    # same format, different character set.  Go to canon, then from canon.
    # XXXXX XXF use the protection test here.
    $recin =~ s/$bib'cs_escape/$bib'cs_char_escape/go;
    local($reccan, $recout);
    $func = $charsets{$icset, 'tocanon'};
    $reccan = &$func($recin, $opt_CSProtect);
    $func = $charsets{$ocset, 'fromcanon'};
    $recout = &$func($reccan, $opt_CSProtect);
    $recout =~ s/$bib'cs_char_escape/$bib'cs_escape/go;
    return $recout;
  }

  # Different formats.  First check for a special converter.  cvtname is
  # safely defined in format.
  # XXXXX charsets with special converters?  Probably not.
  # Note that a special converter means no charset mapping.  The converter
  # is expected to do that.

  if (defined $glb_cvtname) {
    &debugs("calling converter '$glb_cvtname'", 128);
    $func = $special_converters{$glb_cvtname, 'convert'};
    return &$func($recin);
  }

  #if we don't have a special converter, we do it the hard way.
  &debugs("convert through canon", 128) if $glb_debug;

  # By the way, unrolling all four of these functions saves only about
  # 2 seconds off of a 53 second run (1043 records).  Really not worth it.
  &implode(&fromcanon(&tocanon(&explode($recin))));

}

######
#
#    explode ( $input_record )
#
#    explode ( $input_record , $file_name )
#
# Explode a record from it's textual form into an assosiative array which
# is returned.  In the second form, the input file name determines the
# format to use instead of the current default.
#
######

sub explode {
  local($recin, $file) = @_;
  local($fmt, $cset);

  return undef  unless defined $recin;

  if (defined $file) {
    if      (defined $glb_Irfmt{$file}) {
      $fmt  = $glb_Irfmt{$file};
      $cset = $glb_Ircset{$file};
    } elsif (defined $glb_Orfmt{$file}) {
      $fmt  = $glb_Orfmt{$file};
      $cset = $glb_Orcset{$file};
    } else {
      return &goterror("unopened file $file given to explode");
    }
    &debugs("explode $file<$fmt:$cset>", 32) if $glb_debug;
  } else {
    if (defined $glb_Ifilename) {
      $fmt  = $glb_Irfmt{$glb_Ifilename};
      $cset = $glb_Ircset{$glb_Ifilename};
    } else {
      ($fmt, $cset) = split(/:/, $glb_Iformat);
    }
    &debugs("explode <$fmt:$cset>", 32) if $glb_debug;
  }

  # Records in exploded format need to be able to use our seperator
  # character and the like.  So we protect our escape character here.
  $recin =~ s/$bib'cs_escape/$bib'cs_char_escape/go;

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $func = $formats{$fmt, 'explode'};
  &$func($recin);
}

######
#
#    implode ( %output_record )
#
#    implode ( %output_record, $file_name )
#
# Implode a record from it's associative array into it's textual form, which
# is returned.  In the second form, the input file name determines the
# format to use instead of the current default.
#
######

sub implode {
  local(%recout, $file) = @_;
  local($fmt, $cset, $recout);

  if (defined $file) {
    if      (defined $glb_Orfmt{$file}) {
      $fmt  = $glb_Orfmt{$file};
      $cset = $glb_Orcset{$file};
    } elsif (defined $glb_Irfmt{$file}) {
      $fmt  = $glb_Irfmt{$file};
      $cset = $glb_Ircset{$file};
    } else {
      return &goterror("unopened file $file given to implode");
    }
    &debugs("implode $file<$fmt:$cset>", 32) if $glb_debug;
  } else {
    if (defined $glb_Ofilename) {
      $fmt  = $glb_Orfmt{$glb_Ofilename};
      $cset = $glb_Orcset{$glb_Ofilename};
    } else {
      ($fmt, $cset) = split(/:/, $glb_Oformat);
    }
    &debugs("implode <$fmt:$cset>", 32) if $glb_debug;
  }

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $func = $formats{$fmt, 'implode'};
  $recout = &$func(%recout);

  # We need to unprotect our escape character now.  But leave canon fmt alone.
  if ( ($recout =~ /$bib'cs_escape/o) && ($fmt ne 'canon') ) {
    $recout =~ s/$bib'cs_sep/\//go  && &gotwarn("Seperator1 left in $recout");
    $recout =~ s/$bib'cs_sep2/\//go && &gotwarn("Seperator2 left in $recout");
    $recout =~ s/$bib'cs_escape[^e]//g && &gotwarn("Unknown escape found in $recout");
    $recout =~ s/$bib'cs_char_escape/$bib'cs_escape/go;
  }
  $recout;
}

######     tocanon( "%recexp" [, "file"] );

sub tocanon {
  local(%recexp, $file) = @_;
  local($fmt, $cset);
  local($field, $val);

  if (defined $file) {
    $fmt  = $glb_Irfmt{$file};
    $cset = $glb_Ircset{$file};
    if (!defined $fmt) {
      $fmt  = $glb_Orfmt{$file};
      $cset = $glb_Orcset{$file};
    }
    return &goterror("unopened file $file given to tocanon") unless defined $fmt;
    &debugs("tocanon $file<$fmt:$cset>", 32) if $glb_debug;
  } else {
    if (defined $glb_Ifilename) {
      $fmt  = $glb_Irfmt{$glb_Ifilename};
      $cset = $glb_Ircset{$glb_Ifilename};
    }
   #if ( (!defined $fmt) && (defined $glb_Ofilename) ) {
   #  $fmt  = $glb_Orfmt{$glb_Ofilename};
   #  $cset = $glb_Orcset{$glb_Ofilename};
   #}
    ($fmt, $cset) = split(/:/, $glb_Iformat) unless defined $fmt;
    &debugs("tocanon <$fmt:$cset>", 32) if $glb_debug;
  }

  # First, do character set conversion
  # XXXXX if we're protecting output, does that _always_ mean unprotect input?

  if ($opt_CSConvert) {
    $func = $charsets{$cset, 'tocanon'};
    if ( defined $charsets{$cset, 'toesc'} ) {
      local($teststr) = $charsets{$cset, 'toesc'};
      # XXXXX We may get a speedup or a slowdown (depending on the input)
      #       by putting this loop inside a test:
      #           if (join("", values %recexp) =~ /$teststr/)
      #       which if no match is found is ~3 times faster than the loop.
      #       Of course if a match _is_ found, it's wasted time.
      # XXXXX Another idea is to put this all inside an eval.  This would
      #       expand $teststr for us as well as func, and look a lot cleaner.
      #       Also, hooks would be more efficient.  But...  profiling tests
      #       have the eval idea almost twice as slow as this.  Oh well.
      while (($field, $val) = each %recexp) {
        next unless $val =~ /$teststr/;
        $recexp{$field} = &$func($val, $opt_CSProtect);
      }
    } else {
      while (($field, $val) = each %recexp) {
        $recexp{$field} = &$func($val, $opt_CSProtect);
      }
    }
  }

  # Next, do the format conversion

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $func = $formats{$fmt, 'tocanon'};
  &$func(%recexp);
}

######     fromcanon( "%reccan" [, "file"] );

sub fromcanon {
  local(%record, $file) = @_;
  local(%recexp);
  local($fmt, $cset);
  local($field, $val);

  if (defined $file) {
    $fmt  = $glb_Orfmt{$file};
    $cset = $glb_Orcset{$file};
    if (!defined $fmt) {
      $fmt  = $glb_Irfmt{$file};
      $cset = $glb_Ircset{$file};
    }
    return &goterror("unopened file $file given to fromcanon") unless defined $fmt;
    &debugs("fromcanon $file<$fmt:$cset>", 32) if $glb_debug;
  } else {
    if (defined $glb_Ofilename) {
      $fmt  = $glb_Orfmt{$glb_Ofilename};
      $cset = $glb_Orcset{$glb_Ofilename};
    }
    ($fmt, $cset) = split(/:/, $glb_Oformat) unless defined $fmt;
    &debugs("fromcanon <$fmt:$cset>", 32) if $glb_debug;
  }

  # First, the format conversion

  $glb_current_fmt  = $fmt;
  $glb_current_cset = $cset;
  $func = $formats{$fmt, "fromcanon"};
  %recexp = &$func(%record);

  # Next, the character set conversion

  if ($opt_CSConvert) {
    $func = $charsets{$cset, 'fromcanon'};
    # Pick which loop we'll run
    if ( defined $charsets{$cset, 'fromesc'} ) {
      # fast loop -- check to see if we have any specials before calling.
      local($teststr) = $charsets{$cset, 'fromesc'};
      while (($field, $val) = each %recexp) {
        next unless $val =~ /$teststr/;
        $recexp{$field} = &$func($val, $opt_CSProtect);
      }
    } else {
      # call the conversion routine for each field.
      while (($field, $val) = each %recexp) {
        $recexp{$field} = &$func($val, $opt_CSProtect);
      }
    }
  }

  %recexp;
}

######

sub clear {
  local($file) = @_;
  local($fmt);

  if (!defined $file) {
    &errors('clear');
    return 1;
  }
  if ($file =~ /^>(.*)/) {
    $fmt = $glb_Orfmt{$1};
  } else {
    $fmt = $glb_Irfmt{$file};
    $fmt = $glb_Orfmt{$file} unless defined $fmt;
  }
  return &goterror("clearing unopened file $file") unless defined $fmt;
  $func = $formats{$fmt, "clear"};
  &$func($file);
}


require "${glb_bpprefix}p-stdbib.pl";
# loads:
# bib'open_stdbib
# bib'close_stdbib
# bib'read_stdbib
# bib'write_stdbib
# bib'clear_stdbib
# bib'implode_stdbib
# bib'explode_stdbib
# bib'tocanon_stdbib
# bib'fromcanon_stdbib

######
#
# Load in various utility routines that format modules may want to call.
#
# These go into package bp_util, not bib!
#

require "${glb_bpprefix}p-utils.pl";
# loads:
# bp_util'mname_to_canon
# bp_util'name_to_canon
# bp_util'canon_to_name
# bp_util'parsedate

##################
#
# Set the default format and clear errors.
#


if (defined $main'bibpackage_do_not_load_defaults) {
  # special trickery for debugging and profiling.
  $main'bibpackage_do_not_load_defaults = 1; # stop one-use warning
  &debugs("bp package loaded without defaults", 65536);
} else {
  &format("auto") || die &goterror("Could not load default format.", "package");
  &clear;
  #&check_consist;
  &debugs("bp package loaded with defaults", 65536);
}

#######################
# end of package
#######################

1;
