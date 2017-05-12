package Apache::UploadSvr::Directory;

use Apache::Constants qw(OK DECLINED AUTH_REQUIRED SERVER_ERROR);
use Apache::UploadSvr;
use CGI;
use Data::Dumper;
use DirHandle;
use File::Basename qw(basename dirname);
use File::Path;
use Image::Magick;
use IO::File;
use strict;
use vars qw( $VERSION @ISA );

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

@ISA = qw(Apache::UploadSvr); # secure_transaction, dict

sub new {
  my($class,%arg) = @_;
  bless {%arg}, $class;
}

sub handler {
  my $r = shift;
  my $cgi = CGI->new;
  # Directory not really suited well for the stage area
  my $userclass = $r->dir_config("Apache_UploadSvr_Usermgr")
      || "Apache::UploadSvr::User";
  eval "require $userclass;";
  no strict "refs";
  my $self = __PACKAGE__->new( CGI => $cgi, R => $r );
  $self->{USERREF} = $userclass->new($self);
  $self->dispatch;
}

sub dispatch {
  my($self) = @_;
  my $cgi = $self->{CGI};
  my $r = $self->{R};
  my(@m,$w,$cache,$has_changed);
  my $DirCache = $r->dir_config("DirCache") || ".dirchache";
  my $document_root = $r->document_root;
  my $directory = dirname($r->filename);
  my $stage = $r->dir_config("apache_stage_regex") ||
      q{ ^ (/STAGE/[^/]*) (.*) $ };
  return DECLINED if $r->uri =~ m| $stage |ox;
  if (basename($directory) eq $DirCache) {
    # warn "directory[$directory]DirCache[$DirCache]";
    return DECLINED;
  }
  my $userref = $self->{USERREF};
  # warn "userref[$userref]";
  return AUTH_REQUIRED unless exists $userref->{user};

  my $dir_uri = substr($directory,length($document_root)) || "";
  $dir_uri =~ s|/*$|/|;
  my $write_perm = $self->has_perms($dir_uri);
  # warn "write_perm[$write_perm]user[$userref->{user}]";
  $write_perm++ if $userref->{user} eq "admin";
  return DECLINED unless $write_perm;

  my $dh = DirHandle->new($directory);
  my $expect_missings;
  if (-f "$directory/$DirCache/$DirCache" && -r _) {
    my $fh = IO::File->new;
    if ($fh->open("$directory/$DirCache/$DirCache")) {
      local $/;
      eval <$fh>;
    }
  } else {
    eval {mkpath "$directory/$DirCache";};
    $expect_missings = 1 if $@;
  }
  my $att = $expect_missings ? " (not writeable by server)" : "";
  my(@dirlisting,%dirlisting);

  push @m, qq{<HTML><HEAD><TITLE>Directory $dir_uri</TITLE></HEAD><BODY>};

  if ($cgi->param('delete')) {
    my @delete = $cgi->param('delete');
    my @todo;
    warn "delete[@delete]";
    for my $d (@delete) {
      push @todo, "unpublish $dir_uri$d\n";
    }
    my $todo = join "", @todo;

    push @m, $self->secure_transaction($todo);
  }

  push @m, qq{<H3>Contents of Directory: $dir_uri$att</H3><FORM METHOD=POST><TABLE BORDER=2 CELLPADDING=5 CELLSPACING=5>};

  my(@rows);
  for my $dirent (sort $dh->read) {
    next if $dirent eq ".";
    next if $dirent eq $DirCache;
    next if "/$dirent/" =~ m| $stage |ox; # don't show the STAGE
    next unless -e "$directory/$dirent";
    # warn "dirent[$dirent]";
    $cache->{$dirent}{seen} = undef; # we check with exists only
    push @dirlisting, $dirent;
    my($display_as,$href,$size,$mtime,$localtime,$imgsize,$pic,$line);
#### STAT ####
    stat "$directory/$dirent";
    $mtime = (stat _)[9];
    $display_as = $dirent; # speak for yourself
    my $imq = Image::Magick->new;
    if (ref($cache) && $cache->{$dirent}{mtime} == $mtime) {
      $line = $cache->{$dirent}{line};
      # I believe, we do not need to check if the thumbnail's still there
    } else {
      if (-d _) {
	$href = "$dirent/...";
	$size = "-";
	$localtime = "-";
	$imgsize = qq{<A HREF="$href"><IMG BORDER=0 SRC="/icons/dir.gif"
 WIDTH=20 HEIGHT=22></A>};
	$pic = "";
	$display_as = "Parent Directory" if $dirent eq "..";
      } else {
	$href = $dirent;
	$size = -s _;
#### EOSTAT ####
	$localtime = localtime($mtime);
	$localtime =~ s/ (\d) / 0$1 /;
	my($imgx, $imgy, $im_size, $imgtype);
	($imgx, $imgy, $im_size, $imgtype) =
	    split(',', $imq->Ping("$directory/$dirent"))
		if $dirent =~ /(?:GIF|JPE?G|XBM|PNG|BMP)$/i;
	# warn "dirent[$dirent]imgx[$imgx]imgtype[$imgtype]";
	$imgsize = $imgtype =~ /^(?:GIF.*|JPE?G|XBM|PNG|BMP)$/ ?
	    qq{$imgx x $imgy} : "";
	if ($imgsize) {
	  my($scalex,$scaley,$scalemax,$thsrc);
	  if ($expect_missings) {
	    $thsrc = "/icons/unknown.gif";
	    $scalex = 20;
	    $scaley = 22;
	  } else {
	    $thsrc = "$DirCache/$dirent";
#### STAT ####
	    stat "$directory/$thsrc";
	    my $thmtime = (stat _)[9];
	    my $thstatsize = (stat _)[7];
#### EOSTAT ####
	    unless ($thmtime > $mtime && $thstatsize) {
	      $scalemax = 31;
	      if ($imgx > $scalemax && $imgx > $imgy) {
		$scalex = $scalemax;
		$scaley = int($imgy*$scalemax/$imgx+.5) || 1;
	      } elsif ($imgy > $scalemax) {
		$scaley = $scalemax;
		$scalex = int($imgx*$scalemax/$imgy+.5) || 1;
	      } else {
		$scalex = $imgx;
		$scaley = $imgy;
	      }
	      my $incode = "$directory/$dirent";
	      if (-r $incode){
		my $orig = $imq->Read($incode);
		$imq->Sample(width=>$scalex,height=>$scaley);
		my $err = $imq->Write(filename=>"$directory/$thsrc");
		if ($err) {
		  warn "Could not write [$err]: $!";
		  $thsrc = "/icons/unknown.gif";
		  $scalex = 20;
		  $scaley = 22;
		}
	      } else {
		warn "Could not open input [$incode]: $!";
		return SERVER_ERROR;
	      }
	    }
	  }
	  $pic = qq{<A HREF="$href"><IMG SRC="$thsrc" BORDER=0 WIDTH="$scalex" HEIGHT="$scaley"></A>};
	}
      }
      $has_changed=1;
      $line = [
	       qq{<TD>$pic</TD>},
	       qq{<TD>$imgsize</TD>},
	       qq{<TD><A HREF="$href">$display_as</A></TD>},
	       $size eq "-" ?
	       "<TD></TD>" :
	       "checkbox",
	       qq{<TD ALIGN=CENTER>$size</TD>},
	       qq{<TD ALIGN=CENTER>$localtime</TD>}
	      ];

      $cache->{$dirent}{mtime} = $mtime;
      $cache->{$dirent}{line}  = $line;
    }
    push @rows, $line;
  }
  $dh->close;
  foreach my $olddirent (keys %$cache) {
    if (exists $cache->{$olddirent}{seen}) {
      delete $cache->{$olddirent}{seen};
    } else {
      delete $cache->{$olddirent};
      $has_changed = 1;
    }
  }
  if ($has_changed) {
    my $fh = IO::File->new;
    if ($fh->open(">$directory/$DirCache/$DirCache")) {
      $fh->print(Data::Dumper->new([$cache],["cache"])->Dump);
    } else {
      warn "Could not write >$directory/$DirCache/$DirCache: $!";
    }
  }
  my(@chkbox,$columns,$red);
  if ($write_perm) {
    $columns = 6;
  } else {
    $columns = 5;
  }
  if ($write_perm) {
    @dirlisting{@dirlisting} = (" ") x @dirlisting;
    @chkbox = split /<BR>/, $cgi->checkbox_group(-name => "delete",
						 'values' => \@dirlisting,
						 'linebreak'=>'true',
						 labels => \%dirlisting
						);
    $red = "#fa8888";
    push @m, "<TR><TD colspan=3></TD>";
    push @m, qq{<TD bgcolor="$red">};
    push @m, $cgi->submit(-name => 'Delete');
    push @m, qq{</TR>};
    for my $e (0..$#rows) {
      my $l = $rows[$e];
      $l->[3] = qq{<TD ALIGN=CENTER BGCOLOR=$red>$chkbox[$e]</TD>} if
	  "$l->[3]" eq "checkbox";
    }
  } else {
    for my $e (0..$#rows) {
      my $l = $rows[$e];
      splice @$l, 3, 1;
    }
  }

  for my $e (0..$#rows) {
    my $l = $rows[$e];
    push @m, "<TR>";
    for my $c (@$l) {
      push @m, $c;
    }
    push @m, "</TR>";
  }

  push @m, "</FORM></TABLE></BODY></HTML>";

  $r->content_type("text/html");
  $r->send_http_header;

  print @m;
  OK;
}

1;
