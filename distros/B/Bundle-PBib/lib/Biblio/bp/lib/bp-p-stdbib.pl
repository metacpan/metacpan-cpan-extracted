#
# bibliography package for Perl
#
# standard routines for functions
#
# Dana Jacobsen (dana@acm.org)
# 14 January 1995 (last modified 21 Jan 1996)

######
# Standard routines bibliography functions.  If a format doesn't register
# its own function, this is what gets used.  It could also specifically
# request one of these functions.
#
# open, close, write, and clear are pretty generic, and I expect
# that a lot of formats will just use these.
#
# read is a little bit more complicated, so may be specifically implemented
# in a lot of formats.
#
# explode, implode, tocanon, and fromcanon are empty functions that return
# an 'unsupported' error.
#
# NOTE that these functions are not meant to be exported -- i.e. you should
# not be referring to these anywhere.  They should be put in place by the
# format registry process.

# We can expect that the variable $bib'glb_current_fmt has the name of the
# format in it.  I suppose we could alternatively pass it in to every
# function, but that's pretty ugly, and a lot of routines don't need to know
# that.  After all, inside format code you should know what your own name is!
#
# We also use the variable $bib'glb_current_fh as the filehandle to use.

sub open_stdbib {
  local($file) = @_;

  &panic("open_stdbib called with no arguments")  unless defined $file;

  &debugs("opening $file<$glb_current_fmt> ($glb_current_fh)", 128, 'module');

  return $glb_current_fmt  if CORE::open($glb_current_fh, $file);

  &goterror("Can't open file $file");
}

######

sub close_stdbib {
  local($file) = @_;

  &panic("close_stdbib called with no arguments")  unless defined $file;

  &debugs("clearing format $glb_current_fmt information on $file", 128);
  $func = $formats{$glb_current_fmt, "clear"};
  &$func($file);

  &debugs("closing $file<$glb_current_fmt>", 128);

  CORE::close($glb_current_fh);
}

######

# XXXXX We ought to have another read routine that handles those formats
#       that have no well defined end-of-record.  So we read until we reach
#       the next beginning of record (regex stored in an assoc array by file)
#       and then save that for the next read (again by file).
#       This would be good to implement once so nobody is tempted to write
#       it themselves and do it wrong.

sub read_stdbib {
  local($file) = @_;

  &debugs("reading $file<$glb_current_fmt>", 32) if $glb_debug;

  # read a paragraph
  local($/) = '';
  scalar(<$glb_current_fh>);
}

######

sub write_stdbib {
  local($file, $out) = @_;
  local($chopchar);

  &panic("write_stdbib called with no arguments")  unless defined $file;
  &panic("write_stdbib called with no output")     unless defined $out;

  &debugs("writing $file<$glb_current_fmt>", 32) if $glb_debug;

  # This is kind of silly, but I want one newline after each record.
  # Note that the perl5 "chomp" command fixes this annoyance of chop.
  # XXXXX should this be while(chop($out) eq "\n") or somesuch?

  $chopchar = chop($out);
  if ($chopchar eq "\n") {
    print $glb_current_fh ($out, "\n\n");
  } else {
    print $glb_current_fh ($out, $chopchar, "\n\n");
  }
}

######

sub clear_stdbib {
  1;
}

######

sub options_stdbib {
  undef;
}

######

#
# I really wish we could define just one function and pass in an argument.
# This is a lot of clutter.
#

# These are the messages for routines not supported.

# XXXXX This message is too vague.
sub generic_unsup_stdbib {
  &bib'goterror("That function is not supported");
}

sub implode_unsup_stdbib {
  &bib'goterror("The $glb_current_fmt format does not support input parsing");
}

sub explode_unsup_stdbib {
  &bib'goterror("The $glb_current_fmt format does not support output parsing");
}

sub tocanon_unsup_stdbib {
  &bib'goterror("The $glb_current_fmt format does not support input conversion");
}

sub fromcanon_unsup_stdbib {
  &bib'goterror("The $glb_current_fmt format does not support output conversion");
}

# These are for the routines not implemented

sub generic_unimpl_stdbib {
  &bib'goterror("That function has not yet been implemented");
}

sub implode_unimpl_stdbib {
  &bib'goterror("The $glb_current_fmt format has not yet implemented input parsing");
}

sub explode_unimpl_stdbib {
  &bib'goterror("The $glb_current_fmt format has not yet implemented output parsing");
}

sub tocanon_unimpl_stdbib {
  &bib'goterror("The $glb_current_fmt format has not yet implemented input conversion");
}

sub fromcanon_unimpl_stdbib {
  &bib'goterror("The $glb_current_fmt format has not yet implemented output conversion");
}

1;