#
# bibliography package for Perl
#
# HTML routines
#
# Dana Jacobsen (dana@acm.org)
# 2 July 1995
#
#	This is a first stab at these.  We really need a more complicated
#	mechanism for describing output styles that can be shared by the
#	formats that use an output style.
#

require "bp-p-output.pl";

package bp_html;

$version = "html (dj 27 nov 95)";

######

# provide headers and trailers
$opt_full_document = 1;

######

# This keeps track of whether we're writing a header or not.  It has three
# values:
#    -1 means don't output headers or trailers
#     0 means it's open but nothing written yet
#     1 means we've written the header already
%file_modes = ();

######

&bib'reg_format(
  'html',	# name
  'htm',	# short name
  'bp_html',	# package name
  'html',	# default character set
  'suffix is html',
# functions
  'options is standard',
  'open',
  'close',
  'read is unsupported',
  'write',
  'clear is standard',
  'explode is unsupported',
  'implode',
  'tocanon is unsupported',
  'fromcanon',
);

######

sub implode {
  local(%entry) = @_;
  local($emchars, $url);
  local($title) = undef;
  local($ent);

  $ent = "<P>\n";

  # Use the predefined output routines.  We just need to tell it what
  # our emphasis characters are.

  $emchars = join($bib'cs_sep, '<EM>', '</EM>', '<B>', '</B>',
                               "\n<BLOCKQUOTE>", "</BLOCKQUOTE>");

  # We would like the title to be a link to the url, if one exists.
  if (defined $entry{'Source'}) {
    $url = $entry{'Source'};
    $url =~ s/<(.*)>/$1/;
    $url =~ s/^url:(.*)/$1/i;
    if ($url =~ /^\w+:\/\//) {
      $title = $entry{'Title'};
      $entry{'Title'} = '<A href="' . $url . '">' . $entry{'Title'} . '</A>';
    }
  }
  $ent .= &bp_util'output($emchars, %entry);

  # set this back since we shouldn't disturb %entry.
  # $entry{'Title'} = $title if defined $title;

  $ent =~ s/$bib'cs_sep/ /go;
  $ent;
}

sub fromcanon {
  # just hand back what we took in.  We really don't have any broken out
  # format, so this is as good as any.  All the real work is done in implode.
  @_;
}

######


$headstr =<<"EOH";
<HTML><HEAD>
<LINK REV="made" HREF="http://www.ecst.csuchico.edu/~jacobsd/bib/bp/index.html">
<!-- Created by bp $bib'glb_version -->
<TITLE>Bibliography: =name=</TITLE>
</HEAD>

<BODY><H1 align=center>Bibliography: =name=</H1>

EOH

$tailstr =<<"EOT";
<HR>
<ADDRESS>
<I>Created automatically by bp $bib'glb_version
using module $version</I>
</ADDRESS>
</BODY></HTML>
EOT

###

sub open {
  local($file) = @_;
  local($name, $mode);

  &panic("html format open called with no arguments") unless defined $file;

  # get the name and mode
  if ($file =~ /^>>(.*)/) {
    $mode = 'append';  $name = $1;
    # XXXXX we assume that we're in the middle of a list already.
    #       We also assume we don't want any trailers written.
    #       I think this is correct.
    $file_modes{$name} = -1  unless defined $file_modes{$name};
  } elsif ($file =~ /^>(.*)/) {
    $mode = 'write';   $name = $1;
    # XXXXX Added a close if we were already open
#print STDERR "name: $file";
#print STDERR ", oldmode: $file_modes{$name}" if defined $file_modes{$name};
    &close($file) if defined $file_modes{$name};
    $file_modes{$name} = 0;
#print STDERR ", mode: $file_modes{$name}\n";
  } else {
    $mode = 'read';    $name = $file;
    $file_modes{$name} = -1  unless defined $file_modes{$name};
  }
  $file_modes{$name} = -1  unless $opt_full_document;

  if ($mode eq 'write') {
    &bib'debugs("html write", 128, 'module');
    return &bib'goterror("Can't open file $file")
           unless open($bib'glb_current_fh, $file);
    return $bib'glb_current_fmt;
  } elsif ($mode eq 'append') {
    &bib'debugs("html append", 128, 'module');
    return &bib'goterror("Can't open file $file")
           unless open($bib'glb_current_fh, $file);
    # XXXXX What should we do here?
    return $bib'glb_current_fmt;
  } else {
    &bib'debugs("html read", 128, 'module');
    # XXXXX read through HTML headers?
    return $bib'glb_current_fmt  if open($bib'glb_current_fh, $file);
    &bib'goterror("Can't open file $file");
  }
}

sub close {
  local($file) = @_;

  &panic("html format close called with no arguments")  unless defined $file;

  if ($opt_full_document && ($file_modes{$file} == 1) ) {
    print $bib'glb_current_fh $tailstr;
  }

  &bib'clear($file);

  close($bib'glb_current_fh);
}

sub write {
  local($file, $out) = @_;

  &panic("write_stdbib called with no arguments")  unless defined $file;
  &panic("write_stdbib called with no output")     unless defined $out;

  &bib'debugs("writing $file<html>", 32);

  if ($file_modes{$file} == 0) {
    $file_modes{$file} = 1;
    local($outstr, $bibname);
    $outstr = $headstr;
    if (defined $bib'glb_Ifilename) {
      $bibname = $bib'glb_Ifilename;
    } else {
      $bibname = '';
    }
    # get the first two occurances of this.
    $outstr =~ s/Bibliography: =name=/Bibliography: $bibname/;
    $outstr =~ s/Bibliography: =name=/Bibliography: $bibname/;
    print $bib'glb_current_fh $outstr;
  }
  print $bib'glb_current_fh ($out, "\n\n");
}

sub clear {
  local($file) = @_;

  undef $file_modes{$file};
  1;
}
