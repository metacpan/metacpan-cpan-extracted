#
# Copyright (C) 2002  Wim Kerkhoff <kerw@cpan.org>
# Copyright (C) 2001  Jonas Öberg <jonas@gnu.org>
#
# All rights reserved.
#
# You may distribute under the terms of either the GNU
# General Public License (see License.GPL) or the Artistic License
# (see License.Artistic).

package Apache::MiniWiki;

use 5.006;
use strict;

use Apache::Constants;
use Apache::Htpasswd;
use Carp;
use CGI qw(:cgi);
use Date::Manip;
use File::stat;
use HTML::Entities;
use HTML::FromText;
use HTML::LinkExtor;
use HTML::Template;
use Rcs 1.04;

our ($VERSION, $datadir, $vroot, $authen, $template, $timediff, @templates, $uploads, $precaching);

$VERSION = 0.92;

# Global variables:
# $datadir:       # Directory where we store Wiki pages (full path)
# $vroot:         # The virtual root we're using (eg /wiki)
# $authen:        # Set to filename when using basic authentification
# $template:      # HTML::Template object
# $timediff:      # delta from GMT, eg:  -8 for PST, +4.5 for IST
# @templates:     # list of templates to use for other entry pages

# Global variables containing the recognized file extensions
# for images and binary files.
our @imgfmts = qw ( jpg jpeg gif png );
our @binfmts = ( @imgfmts, qw ( pdf doc ps gz zip bz2 tar ) );

# global variables to set thumbnail cutoff
our ($max_width, $max_height) = (600,400);

# This sets the directory where Rcs can find the rcs binaries.
# Set this to something more sensible if they are located elsewhere.
Rcs->bindir('/usr/bin');


# The function fatal_error is called most commonly when the Apache virtual
# host has not had the correlt PerlVar's configured.
sub fatal_error {
  my ($r, $text) = @_;

  my $uri = $r->uri;

  $r->log_error($text);

  print <<__EOT__;
<html>
 <body>
  <p id="title">Error in Apache::MiniWiki</p>
  <hr/>
  $text
  <hr/>
  While viewing: $uri
  <hr/>
  This should never have occurred. Please notify the administrator responsible for this site.
 </body>
</html>
__EOT__
  return OK;
}

## The function pretty_error is called most commonly when the the user
## has done something correctly, and needs to be informed. In this situation,
## we assume that things like a template and so forth are available.
sub pretty_error {
  my ($r, $text, $return) = @_;

  $return ||= OK;

  my $uri = $r->uri;

  my $newtext = <<TEXT;
Error

*NOTE:* $text

Please hit the *back* button in your browser, and try again.
TEXT
  $newtext = &prettify($newtext);
    
  $template->param('vroot', $vroot || "no vroot");
  $template->param('title', $uri);
  $template->param('body', $newtext);
  $template->param('editlink', "$vroot/\(edit\)\/$uri");
  $template->param('loglink', "$vroot/\(log\)\/$uri");
  $template->param('pageurl', "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}");
  
  my $output = $template->output;
  
  $r->send_http_header('text/html');
  print $output;

  return $return;
}
   
# This converts the text into HTML with the help of HTML::FromText.
# See the POD information for HTML::FromText for an explanation of
# these settings.
sub prettify {
  my ($text) = @_;

  return text2html( $text, 
    urls => 1, email => 0, bold => 1,
    underline =>1, paras => 1, bullets => 1, numbers=> 1,
    headings => 1, blockcode => 1, tables => 1,
    title => 1, code => 1
  );
}  
  
sub strip_virtual { $_[0] =~ s/^${vroot}\///i; $_[0] }

# This is the main request handler. It begins by finding out its
# configuration, if it has not before, loads templates and then calls
# the appropriate function depending upon the URI we received from
# the user.
sub handler {
  my $r = shift;

  # Load configuration directives.
  $datadir = $r->dir_config('datadir') or
      return fatal_error($r, "PerlVar datadir must be set.");
  $vroot = $r->dir_config('vroot') or
      return fatal_error($r, "PerlVar vroot must be set.");
  $authen = $r->dir_config('authen') || -1;
  $timediff = $r->dir_config('timediff') || -8;
  @templates = $r->dir_config->get('templates');
  $uploads = $r->dir_config('uploads') || 'yes';
  $precaching = $r->dir_config('precaching') || 'no';

  # First strip the virtual root from the URI
  my $uri = &strip_virtual($r->uri);

  # trailing / away
  $datadir =~ s/(\/)$//g;

  # Load the template for this Wiki
  $template = &get_template($r);

  # We currently do not allow the clients browser to cache the document.
  # This means that Opera, for example, has a better chance of actually
  # showing up-to-date content to the user.
  $r->no_cache(1);

  # We call the appropriate functions to perform a task if the
  # URI that the user sent contains "(function)" as an element,
  # otherwise, call the default, view_function.
  my $function = "view_function";
  $uri =~ m{^\(([a-z]*)\)/?(.*)} and $function = "$1_function";

  my %args = $r->args;
  my $revision = $args{rev};
  my $page = $2 || $uri;

  # all dot files are hidden and forbidden
  if ($page =~ /^\./) {
    return &pretty_error($r, "All dot files are hidden", FORBIDDEN);
  }

  my $retval;
  eval {
    no strict 'refs';
    $retval = &$function($r, $page || "index", $revision);
  };

  if ($@) { return fatal_error($r, "Unknown function $function called: $@"); }
  else { return $retval; }
}

# This function converts an URI to a filename. It does this by simply
# replacing all forward slashes with an underscore. This means that all
# files, regardless of URI, finds themselves in the same directory.
# If you don't want this, you can always modify this function.
sub uri_to_filename {
    my ($uri) = @_;

	$uri =~ s/(\/)$//g;
    $uri =~ tr/\//_/;
    return $uri;
}


# this function creates an instance of an Rcs object using the
# provided page name. It handles file names with spaces. The new
# Rcs object is returned, ready to be used for rcsdiff, etc.
# locking must be handled by the calling function.
sub rcs_open {
  my ($r, $file) = @_;
  	
  delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};

  if ($file =~ /^([0-9a-zA-Z\ \_\:\.\-]+)$/) {
    $file = $1;
  } else {
    die "Bad page name: $file!";
  }

  my $obj = Rcs->new;
  $obj->rcsdir($datadir);
  $obj->workdir($datadir);
  $obj->file($file);

  return $obj;
}

# This function allows the user to change his or her password, if
# the perl variable "authen" is configured in the Apache configuration
# and points to a valid htpasswd file which is writeable by the user
# executing MiniWiki.
sub newpassword_function {
  my ($r, $uri) = @_;

  if ($authen eq -1) {
    return &pretty_error($r, "Authentication has been disabled in Apache::MiniWiki.");
  }

  my $q = new CGI;
  my $text;

  if ($q->param() && ($q->param('password1') eq $q->param('password2'))) {
    my $pass1 = $q->param('password1');
    $pass1 =~ s/\r//g;
    eval {
      my $htp = new Apache::Htpasswd($authen);
      $htp->htpasswd($r->connection->user, $pass1, 1);
    };
    if ($@) {
      return fatal_error($r, "$@");
    }
    $text = "Password changed.\n";
  } elsif ($q->param() && ($q->param('password1') ne $q->param('password2'))) {
    $text = "The passwords doen't match each other.\n";
  } else {
    $text = <<END;
<form method="post" action="${vroot}/(newpassword)">
<fieldset>
 New password: <input type="password" name="password1"><br/>
 Again: <input type="password" name="password2"><p>
 <input type="submit" name="Change">
 </fieldset>
</form>
END
  }
  
  $template->param('vroot', $vroot);
  $template->param('title', 'New Password');
  $template->param('body', $text);
  
  $r->send_http_header('text/html');
  print $template->output;

  return OK;
}

# This function saves a page submitted by the user into an RCS file.
sub save_function {
  my ($r, $uri) = @_;
  my $fileuri = uri_to_filename($uri);
  
  if ($r->method() ne "POST") {
    return fatal_error($r, "Invalid save, POST required.");
  }

  my $q = new CGI;

  my $text;
  # is this an uploaded binary file? If so, shlurp the data from
  # the file handle provided by CGI.pm.
  if (my $fh = $q->upload('text')) {
    local undef $/;
    $text = <$fh>;
  } else {
    $text = $q->param('text');
    $text =~ s/\r//g;
  }

  if ($q->param("Save") =~ /preview/i) {
    return &edit_function($r, $uri, $text);
  }

  my $comment = $q->param('comment');
  my $user = $r->connection->user || "anonymous";

  chomp ($comment);
  $comment =~ s/^\s*//g if $comment;
  $comment =~ s/\s*$//g if $comment;

  if (length($text) < 5) {
    return &pretty_error($r, "Not enough page text was provided.");
  }

  if (length($comment) < 3) {
    return &pretty_error($r, "A longer comment is required.");
  }

  my $file = &rcs_open($r, $fileuri);

  if (-f "${datadir}/${fileuri},v" && $file->lock) {
    # previous locks exist, removing.  Is this a good idea?
    eval { $file->ci('-u', '-w'.$user) or confess $!; };
    if ($@) {
      my $locker = $file->lock;
      return fatal_error ($r, "($locker) Could not unlock $fileuri: $@");
    }
  }

  if (-f "${datadir}/${fileuri},v") {
    $file->co('-l') or confess $!;
  } else {
    my @opts = ('-i');
    if (!(-f "${datadir}/${fileuri},v") and is_binary($fileuri)) {
      push (@opts, '-kb');
    }
    $file->rcs(@opts) or confess $!;
  }

  open(OUT, '>', "${datadir}/${fileuri}");
  print OUT $text;
  close OUT;

  $file->ci('-u', "-w$user", "-m$comment") or confess $!;

  $uri = "index" if ($uri and $uri eq 'template');

  if (not &is_img($uri) and &is_binary($uri)) {
    return &edit_function($r, $uri, undef);
  } else { 
    return &view_function($r, $uri);
  }
}

# This function reverts a page back to the specified version if possible.
sub revert_function {
  my ($r, $uri, $revision) = @_;

  my $fileuri = uri_to_filename($uri);
  
  my $user = $r->connection->user || "anonymous";

  my $q = new CGI();

  # force someone to manually (via POST) submit a form
  # makes it a step or two harder for spiders/bots to automatically
  # trigger. Another method could be to use mod_rewrite to check for the referrer.
  if (!$q->param("doit")) {
    return &revert_form($r, $uri, $revision);
  }
  
  my $file = &rcs_open($r, $fileuri);

  if (! -f "${datadir}/${fileuri},v") {
    return fatal_error($r, "Page $fileuri,v is not a readable file");
  }

  # remove working copies, in case they are bad
  unlink("$datadir/$fileuri");

  chdir ($datadir);
  eval { $file->co('-l'); };
  if ($@) {
    return fatal_error($r, "Error retriving latest page, check revision: $@");
  }

  # calculate the latest version, needed to undo.
  my $head_revision = ($file->revisions)[0];
 
  eval { 
    chdir ($datadir);
    $file->rcsmerge("-r$head_revision", "-r$revision"); 
  };
  if ($@) {
    return fatal_error($r, "Error merging: $!, $?, $@");
  }

  eval { $file->ci('-u', '-w'.$user); } if $file->lock;
  if ($@) {
    return fatal_error($r, "Error reverting: $@");
  }

  my $newtext = "The page has been reverted to revision $revision.<p>";
  $newtext .= qq([<a href="${vroot}/${uri}">Return</a>]<p>);

  $template->param('vroot', $vroot);
  $template->param('title', $uri);
  $template->param('body', $newtext);
  $template->param('editlink', "$vroot/\(edit\)\/$uri");
  $template->param('loglink', "$vroot/\(log\)\/$uri");
  $template->param("lastmod", &get_lastmod("${datadir}/${fileuri},v"));

  $r->send_http_header('text/html');
  print $template->output;

  return OK;
}

sub revert_form {
	my ($r, $uri, $revision) = @_;
  
 	my $fileuri = uri_to_filename($uri);

    my $formhtml = qq(
		<form method=post action="${vroot}/(revert)${uri}?rev=$revision">
		<fieldset>
		 <input type=hidden name="doit" value=1>
		 Really revert the page <b>$uri</b> to revision <b>$revision</b>?<br/>
		 <br/>
		 <input type=submit value=" Yes " name="submit_button">
		</fieldset>
		</form>
	);
  
	$template->param('vroot', $vroot);
	$template->param('title', $uri);
	$template->param('body', $formhtml);
	$template->param('editlink', "$vroot/\(edit\)\/$uri");
	$template->param('loglink', "$vroot/\(log\)\/$uri");
	$template->param("lastmod", &get_lastmod("${datadir}/${fileuri},v"));

	my $output = $template->output;
	$output =~ s/\n(\s*)\n(\s*)\n/\n\n/g;

	$r->send_http_header('text/html');
	print $output;

	return OK;
}

# The edit function checks out a page from RCS and provides a text
# area for the user where he or she can edit the content.
sub edit_function {
  my ($r, $uri, $preview_wikitext) = @_;

  my $fileuri = uri_to_filename($uri);
  
  my $q = new CGI;

  my $comment = $q->param("comment") || "";


  if (-f "${datadir}/${fileuri},v") {
    my $file = &rcs_open($r, $fileuri);
    eval { $file->co; };
    if ($@) {
      return fatal_error($r, "Error while retrieving $fileuri: $@");
    }
  }

  my $text = "";

  if ($preview_wikitext) {
    $text .= qq(<div class="previewborder">);
	$text .= &render(&prettify("PREVIEW of " . $preview_wikitext));
	$text .= qq(</div>);
  }

  $text .= &prettify("Edit: $fileuri");
  $text .= "<form method=\"post\" action=\"${vroot}/(save)${uri}\" enctype=\"multipart/form-data\"><fieldset>\n";

  
  if (is_binary($fileuri)) {
    $text .= "<input type=\"file\" name=\"text\">\n";
  } else {
    $text .= "<textarea rows=20 cols=80 class='areas' name=\"text\" wrap=virtual>\n";
	if ($preview_wikitext) {
	  $text .= $preview_wikitext;
	} elsif (-f "${datadir}/${fileuri},v") {
      open (IN, '<', "${datadir}/${fileuri}")
	  	|| return fatal_error($r, "Couldn't read ${fileuri}");
      $text .= encode_entities(join('', <IN>));
      close (IN);
    }
    $text .= "</textarea>"
  }
  
  $text .= qq(<p>Comment: <input type=text size=30 maxlength=60 name=comment value="$comment">&nbsp;);
  $text .= qq(<input type="submit" name="Save" value="Preview">\n);
  $text .= qq(<input type="submit" name="Save" value="Save"></fieldset></form>);

  $template->param('vroot', $vroot);
  $template->param('title', $uri);
  $template->param('body', $text);
  $template->param('editlink', "$vroot/\(edit\)\/$uri");
  $template->param('loglink', "$vroot/\(log\)\/$uri");
  $template->param("lastmod", &get_lastmod("${datadir}/${fileuri},v"));

  my $output = $template->output;
  $output =~ s/\n(\s*)\n(\s*)\n/\n\n/g;

  $r->send_http_header('text/html');
  print $output;

  return OK;
}


## This function determines when a given file was last changed
## and returns a string about that.
sub get_lastmod {
  my ($filename) = @_;

  my $lastmod = "never";
  if (-f $filename) {
    my $mtime = stat($filename)->mtime;
    my $date = &ParseDateString("epoch $mtime");
    $lastmod = &UnixDate($date, "%B %d, %Y  %i:%M %p");
  }

  return "$lastmod";
}


# This function is the standard viewer. It loads a file and displays it
# to the user.
sub view_function {
  my ($r, $uri, $revision) = @_;
  my $mvtime;

  if (not $revision) {
    $revision = '';
  }
  elsif ($revision =~ /^([\d\.]+)$/) {
  	$revision = $1;
  }
  else {
    return &pretty_error($r, "Invalid revision");
  }
  
  my $fileuri = uri_to_filename($uri);

  # If the file doesn't exist as an RCS file,
  # then we return NOT_FOUND to Apache.
  if (! (-f "${datadir}/${fileuri},v" and -r "${datadir}/${fileuri},v")) {
	return NOT_FOUND;
  }

  # If we don't have a checked out file, check it out. Can't really do caching here,
  # as we also deal with multiple revisions of the files. If there is a performance
  # bottleneck here, in the future we may need to look at other means of caching.
  my $file;
  eval { 
    $file = &rcs_open($r, $fileuri);
    $file->co("-r$revision"); 
  };
  if ($@) {
    return fatal_error($r, "Error retriving $fileuri, check revision: $@");
  }

  if (is_binary($fileuri)) {
    # If we're running under mod_perl, we can use its interface
    # to Apache's I/O routines to send binary files more efficiently.
	my ($img_ext) = &is_img($fileuri);
    if (exists $ENV{MOD_PERL}) {
	  return send_file($r, "${datadir}/${fileuri}");
    } else {
		if ($img_ext) {
		  $r->send_http_header("image/$img_ext");
		} else {
		  $r->send_http_header("application/octet-stream");
		}
      my $file;
      open (FILE, "${datadir}/${fileuri}");
      { local undef $/; $file = <FILE>; }
      print $file;
    }
	return OK;
  } else {
    open(IN, '<', "${datadir}/${fileuri}");
    my $text = join("", <IN>);
    close IN;

	my $newtext = &render(&prettify($text));
  
    my %dispatch = (
      list => \&get_list,
      listchanges => \&get_listchanges,
	  listlinks => \&get_listlinks
    );
    
    if ($dispatch{$uri}) {
	  my $cachefile = "${datadir}/.${uri}";
	  if ($uri eq "listchanges") {
	    # this bit of code is ugly, but I can't think of a nicer flexible way of doing it
        my %args = $r->args;
        if ($args{maxpages} !~ /^([\d]+)$/) {
          $args{maxpages} = 0;
        }
        if ($args{maxdays} !~ /^([\d]+)$/) {
          $args{maxdays} = 0;
        }
	    $cachefile .= ".$args{maxdays}.$args{maxpages}";
	  }

      # precaching is when we rely on a cronjob to periodically
	  # refresh these dispatched pages
	  # if precaching is on, just show the previously cached version if it's there
	  # All caching is done to the hidden dot files.
      if ($precaching =~ /^y/i) {
        if (-f $cachefile) {
		  $newtext .= &get_file($cachefile);
		} else {
		  return &pretty_error($r, "Cache file not found :-(", NOT_FOUND);
		}
	  } else {
	    my $lastchange_mtime = &get_mtime(&get_lastchanged);
	    my $cache_mtime = &get_mtime("." . $uri);
		my $pagedata = "";
	    if (! -f $cachefile || $cache_mtime < $lastchange_mtime) {
		  # cache is old, refresh it
          $pagedata = $dispatch{$uri}($r);
		  &put_file("$cachefile", $pagedata);
		} else {
		  $pagedata = &get_file($cachefile);
		}
		$newtext .= $pagedata;
      }
    }
  
    $template->param('vroot', $vroot || "no vroot");
    $template->param('title', $uri);
    $template->param('body', $newtext);
    $template->param('editlink', "$vroot/\(edit\)\/$uri");
    $template->param('loglink', "$vroot/\(log\)\/$uri");
    $template->param('pageurl', "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}");
    $template->param("lastmod", &get_lastmod("${datadir}/${fileuri},v"));
  
    my $output = $template->output;
    $output =~ s/\n(\s*)\n(\s*)\n/\n\n/g;
  
    $r->send_http_header('text/html');
    print $output;
  }

  return OK;
}

# returns a string containing the contents of the given filename
sub get_file($) {
	my ($filename) = @_;

	my $data = "";
	
	open (FILE, "$filename") || die "$filename - $!";
	while (<FILE>) {
		$data .= $_;
	}
	close (FILE);

	return $data;
}

# write the given data to the given filename
sub put_file($$) {
  my ($filename, $data) = @_;

  open (OUT, "> $filename") || die $!;
  print OUT $data;
  close(OUT);
}

# returns the name of the last page that was editted in the wiki
sub get_lastchanged {
  open (CMD, "cd ${datadir}; /bin/ls -1at *,v | head -1 |") || die $!;
  my $filename = <CMD>;
  close (CMD);
	$filename =~ s/\t|\r|\n//g;
	$filename =~ s/ $//g;
	$filename =~ s/^ //g;
  return $filename;
}

# returns the timestamp of the given filename in the datadir
sub get_mtime($) {
  my ($filename) = @_;
  if (-f "$datadir/$filename") {
    my $mtime = stat("$datadir/$filename")->mtime;
  }
}

sub render($) {
    my ($newtext) = @_;
  
    # While the text contains Wiki-style links, we go through each one and
    # change them into proper HTML links.
    while ($newtext =~ /\[\[([^\]|]*)\|?([^\]]*)\]\]/) {
    my $rawname = $1;
    my $revision;
    if ($rawname =~ /\//) {
      ($rawname, $revision) = split (/\//, $rawname);
    }
    my $desc = $2 || $rawname;
    my $tmplink;
  
    my $tmppath = uri_to_filename($rawname);
    $tmppath =~ s/^_//;

    if (-f "${datadir}/$tmppath,v") {
      my $link;
      if (is_img($rawname)) {
        $link = qq{<a href="$vroot/$rawname"><img src="$vroot/(thumb)$rawname" alt="$desc"></a>};
	  }
      else {
        $link = qq{<a href="$vroot/$rawname">$desc</a>};
      }
      if (is_binary($rawname) || is_img($rawname)) {
        $link .= qq { <sup><a href="$vroot/(edit)$rawname">[E]</a></sup>};
      }
      $newtext =~ s/\[\[[^\]]*\]\]/$link/;
    } else {
      $tmplink = "$desc <a href=\"${vroot}\/(edit)/${rawname}\"><sup>?<\/sup><\/a>";
      $newtext =~ s/\[\[[^\]]*\]\]/$tmplink/;
    }
    }
    $newtext =~ s/\\\[\\\[/\[\[/g;
  
    $newtext =~ s/-{3,}/<hr\/>/g;

    return $newtext;
}

# this function gets the diff for a file and displays it to the user
# in a semi-nice format.
sub diff_function {
  my ($r, $uri) = @_;

  my %args = $r->args;

  my (@rev) = grep { defined } @args{qw(rev1 rev2)};
  for (@rev) {
    if (/^([0-9\.]+)$/) {
	  $_ = $1;
	} else {
	  &pretty_error($r, "Invalid revision, must be a digit.");
	}
  }

  if (@rev < 1 or @rev > 2) {
    return &pretty_error($r, "Must supply one or two revisions.");
  }

  my $diffformat = $args{m} || 'u';
  if ($diffformat =~ /^(c|u)$/) {
    $diffformat = $1;
  } else {
    return &pretty_error($r, "Diff format must be Context or Normal. $diffformat");
  }

  my $rcs = &rcs_open($r, $uri);
  push (@rev, ($rcs->revisions)[0]) if (1 == @rev);
  
  @rev = map {'-r' . $_ } @rev;

  my $diffbody;
  eval {
    $diffbody = join ('', $rcs->rcsdiff("-$diffformat", @rev));
  };
  if ($@) {
    return fatal_error($r, "Diff failed for $uri: $@");
  }
  $diffbody = "<p id='title'>Differences</p>" 
  			 . text2html($diffbody, lines=>1);
  
  $diffbody .= &diff_form($uri);

  $template->param('vroot', $vroot);
  $template->param('title', $uri);
  $template->param('body', $diffbody);
  $template->param('editlink', "$vroot/\(edit\)\/$uri");
  $template->param('loglink', "$vroot/\(log\)\/$uri");
  $template->param("lastmod", &get_lastmod("${datadir}/${uri},v"));

  $r->send_http_header('text/html');
  print $template->output;

  return OK;
}

# This function dumps out the log list for the file, so that the user can view
# any past version of the file, including options to view the differences
# and undo all the changes between that version and the current version.
sub log_function {
  my ($r, $uri) = @_;
  
  my $fileuri = uri_to_filename($uri);

  my $obj = &rcs_open($r, $fileuri, 1);
  my $head_revision = ($obj->revisions)[0];
  my @rlog_complete;
  eval { @rlog_complete = $obj->rlog(); };
  if ($@) {
    return fatal_error($r, "Error generating log for $fileuri : $@");
  }

  my $logbody = "History for $uri\n\n";

  $logbody = &prettify($logbody);

  $logbody .= qq|<a href="#diff_form">Compare revisions</a><br/><br/>\n|;

  my $server = $r->server->server_hostname;

  foreach my $line (@rlog_complete) {
    if ($line =~ /Initial checkin|empty log message|=============/) {
      next;
    } elsif ($line !~ /:/ && $line !~ /----/ && $line !~ /revision|date/i) {
      chomp($line);
      $line = "&nbsp;" x 5 . "<i>$line</i><br/>\n" if $line;
    } elsif ($line !~ /^(revision |date: )/) {
      next;
    } elsif ($line =~ /^revision /) {
      my ($word, $revision) = split (' ', $line);
      $line = qq|<a href="${vroot}/$uri?rev=$revision">View</a> or |;
      $line .= qq|<a href="${vroot}/(diff)/$uri?rev1=$revision">Diff</a> or |;
      $line .= qq|<a href="${vroot}/(revert)/$uri?rev=$revision">Revert</a>  |;
      $line .= qq|revision $revision:<br/>\n|;
      $line .= "&nbsp;" x 5;
    } elsif ($line =~ /date:/ and $line =~ /state:/) {
      $line =~ s/\n|\t//g;
      $line .= "<br/>\n";
    } else {
      $line .= "<br/>";
    }
    $logbody .= "$line";
  }

  $logbody .= &diff_form($uri);

  $template->param('vroot', $vroot);
  $template->param('title', $uri);
  $template->param('body', $logbody);
  $template->param('editlink', "$vroot/\(edit\)\/$uri");
  $template->param('loglink', "$vroot/\(log\)\/$uri");
  $template->param("lastmod", &get_lastmod("${datadir}/${fileuri},v"));

  $r->send_http_header('text/html');
  print $template->output;

  return OK;
}

# this function creates a thumbnail on the fly for the given uri.
# if the image is bigger then the cutoff, it gets resized. If not, it 
# is left alone.
sub thumb_function {
	my ($r, $uri, $revision) = @_;

	my $fileuri = $datadir . "/" . uri_to_filename($uri);
	my $thumburi = $datadir . "/THUMB_" . uri_to_filename($uri);
	
	my $file_mtime = stat($fileuri)->mtime;
		
	my ($subtype) = &is_img($uri);
	#$r->send_http_header("image/$subtype");

	if (-f $thumburi && stat($thumburi)->mtime > $file_mtime) {
		# if the thumbnail is newer then the big image,
		# then obviously a new one hasn't been uploaded. 
		# Don't call ImageMagick to check the size.
		# Use the existing thumb.
		return send_file($r, $thumburi);
	}

	use Image::Magick;
	my $image = Image::Magick->new;

	my ($width, $height, $size, $format) = $image->Ping($fileuri);

	if ($width < $max_width && $height < $max_height) {
		# don't scale it down
		return send_file($r, $fileuri);
	}
	else {
		if (!-f $thumburi || stat($thumburi)->mtime < $file_mtime) {
			my $resize_ratio;
			if ($width > $height) {
				# eg. .2 = 1200 / 240
				$resize_ratio = $width / $max_width;
			} else {
				$resize_ratio = $height / $max_height;
			}
			$width /= $resize_ratio;
			$height /= $resize_ratio;
			$image->Read($fileuri);
			$image->Resize("${width}x${height}");
			$image->Write($thumburi);
		}
		return send_file($r, $thumburi);
	}
}

## let mod_perl efficiently take care of sending a file to the browser
sub send_file {
	my ($r, $filename) = @_;

	my $subr = $r->lookup_file($filename);
	$r->headers_out(%{$subr->headers_out});
	$r->send_http_header($subr->content_type);
	return $subr->run;
}

# this function returns the HTML for a form that allows the
# user to specify two revisions to compare, in either unidiff or context
# formats. It is called by the log and diff viewing functions, 
# diff_function and log_function.
sub diff_form($) {
  my ($uri) = @_;

  my $form .= <<END;
<hr/>
<a name="#diff_form">
<form method=get action="$vroot/(diff)/$uri">
1st revision: <input type=text size=5 name=rev1> 
2nd revision: <input type=text size=5 name=rev2>
Format: <select name=m>
<option value=>Normal</c>
<option value=c>Context</c>
</select>
<input type=submit value=" Compare "><br/>
<i>(Leave 2nd revision field blank to compare against latest)</i>
</form>
END
  $form;
}

# This function loads the template, if one exists. If there is no template,
# then a default template consisting of just a plain body is used.
sub get_template {
  my ($r) = @_;

  if (!( -f "${datadir}/template,v" and -r "${datadir}/template,v")) {
    $r->log_error("${datadir}/template,v is not a readable file! Using default.");

    my $template_text = <<END_TEMPLATE;
<html>
<head><title>Default Wiki: <TMPL_VAR NAME=title></title></head>
<body>
<TMPL_VAR NAME=BODY>
<p>
<hr/>
<i>This is a default template. For a full example of wiki pages, 
use those provided in the Apache::MiniWiki distribution.</i>
<hr/>
[<a href="<TMPL_VAR NAME=editlink>">Edit</a> | 
<a href="<TMPL_VAR NAME=loglink>">Archive</a> |
<a href="<TMPL_VAR NAME=vroot>/">Home</a> ]
<br/><br/>
Last Modified: <TMPL_VAR NAME="lastmod">
</body></html>
END_TEMPLATE
  
    return HTML::Template->new(
      scalarref => \$template_text, die_on_bad_params => 0
    );
  }

  my $template = "template";
  foreach my $temp (@templates) {
    if ($temp && $r->uri =~ /$temp/i) {
	  $temp = "template-$temp";
	  next if not -f "$datadir/$temp,v";
      $template = $temp;
	  last;
	}
  }
    
  eval { &rcs_open($r, $template)->co(); };
  return fatal_error($r, "Error retrieving template: $@") if ($@);
  
  return HTML::Template->new(
    filename => "$datadir/$template",
    cache => 1,
	die_on_bad_params => 0
  );
}

# This function lists all files in the data directory
# and returns an HTML formatted list of links.
# Pages templates are never displayed (when the pagename is 'template' 
# or begins with 'template-')
sub get_list {
  my ($r, $do_externals) = @_;

  my $linklist = "";

  chdir ($datadir);

  # get the list of files...
  my @files = <*,v>;

  # sort them 
  my @sorted_files = sort {uc($a) cmp uc($b)} @files;

  my $parser = HTML::LinkExtor->new();

  my ($total_in, $total_out, $total_bytes) = (0,0,0);

  if ($do_externals) {
	$linklist .= qq|
		Links: <a href="javascript:showAllLinks()">Expand All</a>, 
		<a href="javascript:hideAllLinks()">Collapse All</a>
		<br/><br/>
		|;
  }

  foreach my $rawname (@sorted_files) {
    $rawname =~ s/,v$//;
    $rawname = &uri_to_filename($rawname);
    next if ($rawname eq "template" or $rawname =~ /^template-/i);
	my $title;
	if (&is_binary($rawname)) {
		$title = $rawname;
	} else {
		$title = &get_page_title($rawname);
	}
	my $a_id = "aa" . encode_entities($rawname); # must start with a letter
	$a_id =~ s/(\.| )//g; # could result in some dups but that's ok, we need good Id's
	$title = encode_entities($title);
    $linklist .= qq|<a id="$a_id">$title</a>: <a href="$vroot/$rawname">view page</a>|;
	if ($do_externals && !&is_binary($rawname)) {
		open(IN, '<', "${datadir}/${rawname}");
		my $text = join("", <IN>);
		close IN;

		# $r->log_error("doing $rawname");

		my $htmltext = &prettify($text);
		my $newtext = &render($htmltext);

		my $spanhtml = "";
		my $spanlinks = 0;

		$parser->parse($newtext);
		$total_bytes += length($newtext);

		my (@links) = $parser->links;
		my $ul_id = "links_${rawname}";
		$ul_id =~ s/(\.| )//g; 
		$spanhtml .= qq|<ul id="$ul_id" style="display:none">\n|;
		foreach my $link (@links) {
			my $href = $link->[2];
			next if ($href =~ /\(edit\)|template-/i or $href eq "${vroot}/template");
			next if ($href eq "http://"); # not real
			if ($href =~ /^${vroot}/) {
				next if (!-f &strip_virtual($href));
				$href = "#" . &strip_virtual($href);
				$total_in++;
			} else {
				# encode ?, &, etc for XHTML1.1 validator
				$href = &encode_entities($href);
				$total_out++;
			}
			$spanlinks++;
			my $display = $href;
			if (length($display) > 80) {
				$display = substr($display, 0, 80) . "...";
			}
			$spanhtml .= qq|<li><a onClick="checkInLink(this)" href="$href">$display</a></li>\n|;
		}
		$spanhtml .= qq|</ul>|;

		$linklist .= qq|,&nbsp;<a name="expand_link" href="javascript:void(0)" onClick="expand(this, '$ul_id')">view links ($spanlinks)</a><br/>\n|;
		$linklist .= $spanhtml;
		$parser->eof();
	} else {
		$linklist .= "<br/>\n";
	}

  }

  if ($do_externals) {
	$linklist .= "<br/><hr/>$total_in inside links, $total_out outside links, for a total of $total_bytes bytes of rendered body html.<br/>";
	$linklist .= qq|
		Links: <a href="javascript:showAllLinks()">Expand All</a>, 
		<a href="javascript:hideAllLinks()">Collapse All</a>
		|;
  }
  
  return $linklist;
}

# This function lists all the external http links on the site, 
# grouped by page title
sub get_listlinks {
  my ($r) = @_;

  return &get_list($r, 1);
}

# obtain the title of the page, which should be the
# first line of the page normally.
# Only do this if it is a text file. For binary files,
# the filename will be used.
sub get_page_title {
	my ($page) = @_;

	my $title;
	if (-T $page and !is_binary($page)) {
		open (FILE, "< $datadir/$page") || return $page;
		while ($title = (<FILE>)) {
			last if ($title);
		}
		close (FILE);
	}

	$title || $page;
}

# This function does up a pretty list of all the changes in the
# Wiki, and returns the HTML for it.
# Does checks for ?maxdays=x&maxpages=y
sub get_listchanges {
	my $r = shift;

	my %args = $r->args;

	$args{maxpages} ||= 0;
	$args{maxdays} ||= 0;

	if ($args{maxpages} !~ /^([\d]+)$/) {
		$args{maxpages} = 0;
	}
	if ($args{maxdays} !~ /^([\d]+)$/) {
		$args{maxdays} = 0;
	}

	my $changes = "";

	chdir($datadir);

	# all the page changes get stored in a big hash
	# by year, then month, then day. This allows us much better
	# control when laying it out.
	my $records = {};
	
	open (LS, "cd $datadir; /bin/ls -1at *,v | grep -v template |")
	 || return fatal_error($r, "Could not get a listing: $!");
	
	my $day_counter = 0;
	my $page_counter = 0;
  
	while (my $page = (<LS>)) {
		chomp ($page);
		$page =~ s/(,v)$//g;

		my $pagelink = $page;
		$pagelink =~ s/ /%20/g;

		my $obj = &rcs_open($r, $page);

		my $incomment = 0;

		# parse the meta information
		my ($revision, $datestamp, $comment, $lines, $title); 
		foreach my $line ($obj->rlog("-r")) {
			chomp ($line);

			if ($line =~ /------------/) {
				$incomment = 1;
			}
			elsif ($line =~ /============/) {
				$incomment = 0;
			}
			elsif ($incomment) {
				if ($line =~ /^date: /) {
					my @fields = split ('; ', $line);
					$datestamp = (split(': ', $fields[0]))[1] if $fields[0];
					$lines = (split(': ', $fields[3]))[1] if $fields[3];
					$lines ||= '?';
				}
				elsif ($line =~ /^revision 1/) {
					$revision = $line;
					$revision =~ s/^revision 1//g;
				}
				elsif ($line !~ /empty log message/) {
					$comment .= $line;
				}
			}
		}

		$title = &get_page_title($page);

		# no wiki words
		$title =~ s/\[|\]//g;

		$lines =~ s/ /\//;

		$comment = ucfirst($comment);

		# convert from RCS's GMT timestamps to PST.
		my $fixedtime = &ParseDateString($datestamp);
		my $delta = &ParseDateDelta("$timediff hours");
		$fixedtime = &DateCalc($fixedtime, $delta);
		my $nicetime = &UnixDate($fixedtime, "%i:%M %p");
		$fixedtime = &UnixDate($fixedtime, "%Y/%m/%d %H:%M:%S");

		my ($date, $time) = split (/\ /, $fixedtime);
		my ($year, $month, $day) = split (/\//, $date);

		$records->{$year}->{$month}->{$day}->{"$time"} = {
			page => $pagelink,
			title => encode_entities($title),
			comment => encode_entities($comment),
			lines => encode_entities($lines),
			nicetime => encode_entities($nicetime)
		};
		$page_counter++;
		if ($args{maxpages} && ($page_counter >= $args{maxpages})) {
			goto close_LS;
		}
	}

	close_LS:
	
	close (LS);

	$day_counter = 0;
	$page_counter = 0;

	foreach my $year (reverse sort keys %{$records}) {
		foreach my $month (reverse sort keys %{$records->{$year}}) {
			foreach my $day (reverse sort keys %{$records->{$year}->{$month}}) {
				my $date = &ParseDateString("$year$month$day");
				$date = &UnixDate($date, "%B %d, %Y");
				$changes .= "&nbsp;&nbsp;<b><i>$date</i></b><br/>\n";
				foreach my $time (reverse sort keys %{$records->{$year}->{$month}->{$day}}) {
					my $record = $records->{$year}->{$month}->{$day}->{$time};
					my $nicetime = $record->{nicetime};
					$changes .= qq|
&nbsp;&nbsp;&nbsp;
$nicetime <a href="$vroot/$record->{page}">$record->{title}</a>
					|;
					$changes .= qq| - $record->{comment}. | if $record->{comment};
					$changes .= qq|Changes:
						<a href="${vroot}/(log)/$record->{page}">$record->{lines}</a>
						| if $record->{lines};
					$changes .= qq|<br/>\n|;
					$page_counter++;
					if ($args{maxpages} && ($page_counter >= $args{maxpages})) {
						goto finish;
					}
				}
				$changes .= "<br/>\n";
				$day_counter++;
				if ($args{maxdays} && ($day_counter >= $args{maxdays})) {
					goto finish;
				}
			}
			$changes .= "\n<hr/>\n";
		}
	}

	finish:

	$changes .= "<br/>\n";
	$changes .= "Current date: <b>" . `/bin/date` . "</b><br/>\n";

	return $changes;
}

# If enabled as a PerlAccessHandler, allows public viewing of
# a Wiki, but leaves existing authentication in place for editing
# content.
sub access_handler {
  my $r = shift;

  return OK unless $r->some_auth_required;

  my $uri = $r->uri;
  unless ($uri =~ /\((edit|save|revert)\)/) {
    $r->set_handlers(PerlAuthenHandler => [\&OK]);
    $r->set_handlers(PerlAuthzHandler => [\&OK])
      if grep { lc($_->{requirement}) ne 'valid-user' } @{$r->requires};
  }

  return OK;
}

## is the link a binary upload?
## are file uploads enabled?
sub is_binary {
  my $uri = shift;
  return 0 if $uploads =~ /^n/i;
  return ($uri =~ /\.(.+)$/ && grep /$1/i, @binfmts);
}

## is the link really an inline image?
## are file uploads enabled?
sub is_img {
  my $uri = shift;
  return 0 if $uploads =~ /^n/i;
  return ($uri =~ /\.(.+)$/ && grep /$1/i, @imgfmts);
}

1;

__END__

=head1 NAME

Apache::MiniWiki - Miniature Wiki for Apache

=head1 DESCRIPTION

Apache::MiniWiki is a simplistic Wiki for Apache. It doesn't have 
much uses besides very simple installations where hardly any features
are needed. What is does support though is:

  - storage of Wiki pages in RCS
  - templates through HTML::Template
  - text to HTML conversion with HTML::FromText
  - basic authentication password changes
  - uploading of binary (pdf, doc, gz, zip, ps)
  - uploading of images (jpg, jpeg, gif, png)
  - automatic thumbnailing of large using ImageMagick
  - sub directories
  - view any revision of a page
  - revert back to any revision of the page
  - basic checks to keep search engine spiders from deleting 
    all the pages in the Wiki

=head1 DEPENDENCIES

This module requires these other modules:

  Apache::Htpasswd
  Apache::Constants
  CGI
  Date::Manip
  Image::Magick (Optional)
  HTML::FromText
  HTML::Template
  Rcs

=head1 SYNOPSIS

Add this to httpd.conf:

  <Location /wiki>
     PerlAddVar datadir "/home/foo/db/wiki/"
     PerlAddVar vroot "/wiki"
     SetHandler perl-script
     PerlHandler Apache::MiniWiki
  </Location>

=head1 AUTHENTICATION EXAMPLES

  Require a password to read/write any page:
  
  <Location /wiki>
     PerlAddVar datadir "/home/foo/db/wiki/"
     PerlAddVar vroot "/wiki"
     PerlAddVar authen "/home/foo/db/htpasswd"
     SetHandler perl-script
     PerlHandler Apache::MiniWiki

     AuthType Basic
     AuthName "Sample Wiki"
     AuthUserFile /home/foo/db/htpasswd 
     Require valid-user
  </Location>

  Public can read, but need password to edit/save/revert a page:
  
  <Location /wiki>
     PerlAddVar datadir "/home/foo/db/wiki/"
     PerlAddVar vroot "/wiki"
     PerlAddVar authen "/home/foo/db/htpasswd"
     SetHandler perl-script
     PerlHandler Apache::MiniWiki

     Require valid-user # or group foo or whatever you want
     PerlAccessHandler Apache::MiniWiki::access_handler

     AuthType Basic
     AuthName "Sample Wiki"
     AuthUserFile /home/foo/db/htpasswd 
     Require valid-user
  </Location>

=head1 USE AS A CGI SCRIPT

Apache::MiniWiki can also be called by an Apache::Registry CGI script. By 
running it in this manner, absolutely no changes need to be made to the
web server's httpd.conf, as long as Apache has mod_perl built in, and the 
Apache::Registry (or a module that emulates it) is available.

Copy the example wiki.cgi into your CGI directory and assign it the 
appropriate permissions. Edit wiki.cgi and add the required options, such as
the datadir and vroot variables:

 $r->dir_config->add(datadir => '/home/foo/db/wiki/');
 $r->dir_config->add(vroot => '/perlcgi/wiki.cgi');

Note #1: This may be a great way of integrating Apache::MiniWiki into
an existing site that already has it's own header/footer template system.

Note #2: This method assumes that the site administrator is already
using Apache::Registry to speed up CGI's on the site. If they aren't,
have them set up mod_perl as it was meant to be. See the mod_perl guide,
or try this:

  ScriptAlias /perlcgi /path/to/your/cgi-bin/
  <Location /perlcgi>
    SetHandler perl-script
    PerlHandler Apache::Registry
    Options ExecCGI
  </Location>

=head1 CONFIGURATION

If you want to use your own template for MiniWiki, you should place the
template in the RCS file template,v in the C<datadir>. Upon execution,
MiniWiki will check out this template and use it. If you make any
modifications to the RCS file, a new version will be checked out.

You can modify the template from within MiniWiki by visiting the URL
http://your.server.name/your-wiki-vroot/(edit)/template

If you don't install a template, a default one will be used.

The C<datadir> variable defines where in the filesystem that the RCS
files that MiniWiki uses should be stored. This is also where MiniWiki
looks for a template to use.

The C<vroot> should match the virtual directory that MiniWiki runs under.

If this variable is set, it should point to a standard htpasswd file
which MiniWiki has write access to. The function to change a users password
is then enabled.
  
(Optional) The default timezone is GMT-8 (PST). To change to a different timezone, 
use the C<timediff> variable. Eg, to change to Amsterdam / Rome:

  PerlAddVar timediff 1

(Optional) By default, only the template called template is used. This becomes 
the default template for every page. Use the C<templates> variable to specify
more then one template:
  
  PerlAddVar templates fvlug linux

By doing this, pages that contain those words will use the matching template.
For example, the /your-wiki-vroot/LinuxDatabases page will then use the template-linux page,
instead of template. You will need to create the template by going to
/wiki/your-wiki-vroot/(edit)/template-<the_template> first.

(Optional) To disable file uploads such as binary attachments and inline images,
set uploads to no. By default it is yes. Note that inline images requires the
Image::Magick module to be installed for generating thumbnails.

  PerlAddVar uploads no

(Optional) Pre-caching can be done by a periodic (eg every 5 minutes) cronjob
to refresh the cached version of the .list* pages (see below) in the background,
rather then when Apache::Miniki discovers that the cache is old when a request is
done. To eanble:

  PerlAddVar precaching yes

If you create the pages 'list' or 'listchanges' or 'listlinks', the following will
automatically get appended to them:

 - list:        A simple line deliminated list of 
                all the pages in the system

 - listchanges: Ordered by date, gives a list of all pages 
                including the last comment, the number of lines 
                added or removed, and the date of the last change

 - listlinks:   Creates a list of all the inner/outer HTML links on the site,
                grouped by page name. By using CSS and some JavaScript in your
				template, it can become very easy to navigate around this way.

The master 'template' page does not show up in any of these three page
listings.

=head1 MULTIPLE WIKIS

Multiple wiki sites can easily be run on the same server. This can be done
by setting up multiple <Location> sections in the httpd.conf, with the
appropriate settings.

For an example of automating this using perl, see conf/httpd-perl-startup.pl 
in the MiniWiki distribution for a sample mod_perl startup file.

=head1 TEMPLATE VARIABLES

These variables are passed by Apache::MiniWiki to HTML::Template:

  vroot:
    virtual root of the wiki installation. E.g.
	  /wiki
  title:
    the title of a page. Comes from the first line of text.
  body:
    HTMLified version of a wiki page
  editlink:
    Link to the edit page. E.g.:
	  http://www.nyetwork.org/wiki/(edit)/MiniWiki
  loglink:
    Link to the Archive page. e.g.:
	  http://www.nyetwork.org/wiki/(log)/MiniWiki
  pageurl:
    Fully qualified link to the page based on the last request, e.g.:
	  http://nyetwork.org:80/wiki/MiniWiki
  lastmod:
    date the page was last changed, e.g.:
	  March 18, 2003 4:25 PM

=head1 SEARCH ENGINES

Spiders for search engines (Google, OpenFind, etc) love the 
bounty of links found in a Wiki. Unfortunely, they also follow
the Archive, Changes, View, and Revert links. This not only
adds to the load on your webserver, but there is a very high
chance that pages will get rolled back as the spider
goes in circles following links. This has happened! Add
these links to your robots.txt so that robots can
only view the actual current pages:

Disallow: /wiki/(edit)/
Disallow: /wiki/(log)/
Disallow: /wiki/(revert)/
Disallow: /wiki/(save)/
Disallow: /wiki/(view)/
Disallow: /wiki/lastchanges

See http://www.nyetwork.org/wiki for an example of 
this module in active use.

=head1 HOME PAGE

http://www.nyetwork.org/wiki/MiniWiki

=head1 AUTHORS

Jonas Oberg, E<lt>jonas@gnu.orgE<gt>

Wim Kerkhoff, E<lt>kerw@cpan.orgE<gt>

James Farrell, E<lt>jfarrell@telesterion.orgE<gt>

=head1 CONTRIBUTORS

Brian Lauer, E<lt>fozbaca@yahoo.comE<gt>

=head1 SEE ALSO

L<perl>, L<Apache::Registry>, L<HTML::FromText>, L<HTML::LinkExtor>, L<HTML::Template>, L<Rcs>, L<CGI>, L<Date::Manip>, L<Image::Magick>.

=cut

