#!/usr/local/bin/perl

package Apache::UploadSvr;

use Apache::Constants qw(DECLINED OK SERVER_ERROR);
use CGI;
warn sprintf "%s", $INC{"CGI.pm"};
use Cwd;
use DirHandle;
use ExtUtils::Manifest;
use File::Basename qw(basename dirname);
use File::Find;
use File::Path ();
use HTML::FormatText ();
use HTML::Parse 'parse_html';
use HTTP::Date;
use IO::File;
use Mail::Send;
use URI::URL;
use Apache::UploadSvr::Dictionary;

use strict;
use vars qw( @Legalactions %Legalactions $VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.24 $ =~ /(\d+)\.(\d+)/;

@Legalactions = qw/publish unzip lowercase linkcheck delete/;
%Legalactions = (
		 'delete'    => "D002",
		 'publish'   => "D003",
		 'unzip'     => "D004",
		 'lowercase' => "D005",
		 'linkcheck' => "D006",
		);

sub time {
  my($self) = @_;
  $self->{TIME} ||= sprintf "%010d", time;
}

sub new {
  my($class,%arg) = @_;
  bless {%arg}, $class;
}

sub dict {
  my($self,$code,@arg) = @_;
  my $lang = $self->language;
  Apache::UploadSvr::Dictionary->fetch($lang,$code,@arg);
}

sub language {
  my($self) = @_;
  return $self->{LANGUAGE} if exists $self->{LANGUAGE};

  my(%lang_wanted,$lang_match);
  my($default_weight) = 1;
  foreach my $e ( split /,/, $self->{R}->header_in('Accept-Language') ) { # de-DE,en,de,ja,hr 
    my($l,$v) = $e =~ / ^ \s* ([\w\-]+) \s* (.*) /x;
    my($q) = $v =~ / ^ ; \s* q \s* = \s* ([\d\.]+) /x;
    $q ||= $default_weight;
    $default_weight -= 0.0001;
    $lang_wanted{$l} = $q;
  }
  for my $l (sort {$lang_wanted{$b} <=> $lang_wanted{$a}}
	     keys %lang_wanted){
    if (Apache::UploadSvr::Dictionary->exists($l)) {
      $lang_match = $l;
    } elsif (Apache::UploadSvr::Dictionary->exists(substr($l,0,2))) {
      $lang_match = substr($l,0,2);
    } else {
      next;
    }
    last;
  }
  $lang_match ||= "de";
  $self->{LANGUAGE} = $lang_match;
}

sub handler {
  my($r) = @_;
  # local($/) = "\n";
  my $cgi = CGI->new;
  my $self = __PACKAGE__->new( 
			      CGI => $cgi,
			      R => $r,
			      USERCLASS => $r->dir_config("Apache_UploadSvr_Usermgr") || "Apache::UploadSvr::User"
			     );
  $self->dispatch;
}

sub as_string {
  my($self) = @_;
  require Data::Dumper;
  join "", "<PRE>", Data::Dumper::Dumper($self), "</PRE>\n";
}

sub dispatch {
  my($self) = @_;
  my $r = $self->{R};
  my $cgi = $self->{CGI};

  my($filename, $content,$stagedir,$stageuri,$what_we_did,
     $sectrans,$transdir);

  my $document_root = $self->document_root;
  my $time = $self->time;
  eval "require $self->{USERCLASS};"; # there are more efficient ways...
  no strict "refs";
  my $userref = $self->{USERCLASS}->new($self);
  $self->{USERREF} = $userref;
  return SERVER_ERROR unless exists $userref->{user};

  $stageuri = $r->dir_config("stageuri") || "/STAGE";
  $stagedir = "$document_root$stageuri";
  $stageuri .= "/$userref->{user}";
  $stagedir .= "/$userref->{user}";
  $self->{STAGEURI} = $stageuri;
  $self->{STAGEDIR} = $stagedir;

  $userref->{permitted} ||= [];

  if ($r->method eq "PUT") {
    my $uri = $r->uri;
    #  $uri =~ s|/STAGE||;
    # I have never tried if PUT works this way or not. Code is just a
    # placeholder
    $r->read($content, $r->header_in("Content-length"));
    $filename = $stagedir . $uri;
  } elsif ($r->method eq "POST" or $r->method eq "GET") {
    if ( $cgi->param('SUBMITup')) {
      my($handle,$targetdir);
      if ($handle = $cgi->param('HTTPUPLOAD')) {
	$targetdir = $cgi->param('TARGETDIR') || "/";
	no strict;
	local $/;
	$content = <$handle>;
	close $handle;
	$handle =~ s(.*\/)();      # no slash
	$handle =~ s(.*\\)();     # no backslash
	$handle =~ s(.*:)();      # no colon
	$filename = "$stagedir$targetdir/$handle";
	#      warn "filename[$filename]";
	$filename =~ s|/+|/|g;
      } else {
	$what_we_did = $self->dict('D007');
      }
    } elsif ($cgi->param('SUBMITaction')) {
      my $action = $cgi->param('ACTION');
      if ($action) {
	$what_we_did = "";
	my(@files,$allflag);
	my(@stagedfiles) = $cgi->param('STAGEDFILES');
	warn "stagedfiles[@stagedfiles]";
	for my $f (@stagedfiles) {
	  if ($f eq " ALL") {
	    $allflag++;
	    last;
	  }
	  push @files, $f;
	}
	if ($allflag) {
	  chdir $stagedir;
	  my $manifind = ExtUtils::Manifest::manifind();
	  @files = map { "/$_" } keys %$manifind;
	}
	if (@files) {
	  for my $f (@files) {
	    if (index($f,"../")>=0) {
	      $what_we_did .= $self->dict("D008",$f);
	      next;
	    }
	    unless (-f "$stagedir$f"){
	      $what_we_did .= $self->dict("D009",$f);
	      next;
	    }
	    if ($action eq "publish") {
	      my($done,$error) = $self->publish($f);
	      if ($done) {
		$sectrans .= $done;
	      } else {
		$what_we_did .= $error;
	      }
	    } elsif ($self->can($action)) {
	      if (exists $Legalactions{$action}) {
		$what_we_did .= $self->$action($f,\@files);
	      } else {
		$what_we_did .= $self->dict("D010",$action);
	      }
	    } else {
	      $what_we_did .= $self->dict("D058",$action);
	    }
	  } # for @files
	  $what_we_did = $self->secure_transaction($sectrans) if $sectrans;
	} else { # no files
	  $what_we_did = $self->dict("D011",$action);
	}
      } else { # no action
	$what_we_did = $self->dict("D012",$self->dict("D013"));
      }
    } elsif ($cgi->param("SUBMITtrans")) {
      $what_we_did = $self->transhandler();
    }
  }

  # warn "filename[$filename] content[$content]";
  if ($filename && $content) {
    my $tdir = dirname($filename);
    File::Path::mkpath($tdir);
    my $fh;
    $fh = IO::File->new or die "Could not open new filehandle: $!";
    unless ($fh->open(">$filename")) {
      $r->log_error("Couldn't open >$filename: $!");
      return SERVER_ERROR;
    }
    $fh->print($content);
    $fh->close;
    #  $filename =~ s|.*?/STAGE/[^/]+(.*)|/STAGE$1|;
    my $basename = basename($filename);
    my $dirname = substr(dirname($filename),length($document_root));
    $what_we_did = $self->dict("D014",$dirname,$basename,$basename,$dirname);
  }

  my($file_listing,$manifind);
  if (
      chdir $stagedir and
      $manifind = ExtUtils::Manifest::manifind() and
      %$manifind
     ) {
    my(%legalactions);
    while (my($k,$v) = each %Legalactions) {
      $legalactions{$k} = $self->dict($v);
    }
    my $actions = $cgi->
	scrolling_list(
		       -name    => 'ACTION', 
		       'values' => [@Legalactions],
		       default  => [],
		       size     => 5,
		       labels   => \%legalactions,
		      );

    my $submit = $cgi->submit(
			      -name=>'SUBMITaction',
			      value=> $self->dict("D013")
			     );

    my(@m);
    push @m, $self->dict("D015", $self->dict("D013")), $actions, $submit;
    push @m, qq{<BR> <TABLE BORDER=1 CELLPADDING=8 };
    push @m, qq{CELLSPACING=2> <TR VALIGN=BOTTOM> <TH>};
    push @m, $self->dict("D016");
    push @m, qq{</TH><TH>};
    push @m, $self->dict("D017");
    push @m, qq{</TH> <TH> </TH> <TH>};
    push @m, $self->dict("D018");
    push @m, qq{</TH><TH>};
    push @m, $self->dict("D019");
    push @m, qq{</TH> </TR>};

    my(@rows);
    for my $f (sort keys %$manifind) {
      my @stat = stat $f;
      push @rows, [
		   qq{/$f},
		   qq{$userref->{user}},
		   qq{$stat[7]},
		   time2str($stat[9]),
		  ];
    }
    unshift @rows, [" ALL"];
    my(%dirlisting,@dirlisting);
    @dirlisting = map {$_->[0]} @rows;
    @dirlisting{@dirlisting} = (" ") x @dirlisting;
    my(@chkbox) = split /<BR>/, $cgi->checkbox_group(
						     -name => 'STAGEDFILES',
						     'values' => \@dirlisting,
						     linebreak=>'true',
						     labels=> \%dirlisting
				    );

    for my $e (0..$#rows) {
      push @m, "<TR>";
      my @l = @{$rows[$e]};
      if ($l[0] eq " ALL") {
	push @m, sprintf(
			 "<TD ALIGN=RIGHT>%s</TD><TD COLSPAN=4>%s</TD>",
			 $chkbox[$e],
			 "perform above selected action on all files below"
			);
      } else {
	push @m, sprintf(
			 qq{<TD ALIGN=RIGHT>%s</TD><TD> %s </TD><TD><A HREF="/STAGE/%s%s">view</A></TD><TD ALIGN=RIGHT> %d </TD><TD> %s </TD>},
			 $chkbox[$e],
			 @l[0,1,0,2,3]
			);
      }
      push @m, qq{</TR>};
    }
  push @m, "</TABLE>";

  $file_listing = join "", @m;
} else {
  $file_listing = $self->dict("D020");
  }
    
  File::Find::finddepth( sub {
			   return unless -d $_;
			   rmdir $_; # may fail
			 }, $stagedir);

    
$r->content_type("text/html");
  $r->send_http_header;
    
  my(@m);
push @m, $cgi->start_html(
			    -title => $self->dict("D021"),
			    author => 'andreas.koenig@kulturbox.de'
			   );
if ($time - $userref->{lastlogin} > 7200) {
    push @m, $self->hello;
  }
  $userref->{lastlogin} = $time;
  if ($what_we_did) {
    unless (  $what_we_did =~ /^<TABLE/ ) {
      $what_we_did =~ s/^/<TABLE BORDER=2><TR><TD>/;
      $what_we_did =~ s|$|</TD></TR></TABLE>|;
    }
  } else {
    $what_we_did = "<HR>";
  }
  push @m, $what_we_did;
  push @m, $self->upload_form;
  push @m, qq{<HR><H4>Delete, Unzip, Publish, etc.</H4>};
  push @m, $file_listing;
  push @m, "<HR>";
  # push @m, $self->as_string;
  push @m, $cgi->endform;
  push @m, $cgi->end_html;
  $cgi->print(@m);
}

sub secure_transaction {
  my($self,$sectrans) = @_;
  my $r = $self->{R}; # attn: Directory.pm calls this with a different $self
  my($userref) = $self->{USERREF};

  my($what_we_did);
  my $script_name = $r->dir_config("Apache_UploadSvr_myuri");
  unless ($script_name) {
    # script_name may be different from this script_name
    $script_name = $r->path_info ?
	substr($r->uri, 0, length($r->uri)-length($r->path_info)) :
	    $r->uri;
  }
  my $me_url = URI::URL->new(
			     "http://" .
			     $r->server->server_hostname .
			     $script_name)->as_string;
  my $secret = 100000 + int rand 900000;
  my $secretfile;
  my $transdir = $r->dir_config('Apache_UploadSvr_transdir');
  unless ($transdir) {
    $r->log_error("No Apache_UploadSvr_transdir specified. Setting to /tmp");
    $transdir = "/tmp";
  }
  $secret++ while -f ($secretfile = "$transdir/$userref->{user}$secret");
  my $fh = IO::File->new(">$secretfile") or 
      die "Couldn't create secretfile $secretfile: $!";
  my $plural = split(/\n/, $sectrans) > 1;
  my $mailtext = join("\n",
		      $self->dict($plural ? "D025" : "D024"),
		      $sectrans,
		      $self->dict("D026"),
		      "  $me_url?SUBMITtrans=$secret",
		     );
  $fh->print($sectrans);
  $fh->close;
  my($msg) = Mail::Send
      ->new(
	    "Subject" => $self->dict("D027"),
	    "To" => qq{"$userref->{fullname}" <$userref->{email}>}
	   );
  my $from = $r->dir_config("Apache_UploadSvr_from");
  $msg->add("From",$from) if $from;
  my $sendh = $msg->open or $r->log_error("Could not open sendmail");
  $sendh->print($mailtext);
  $what_we_did = <<EOS;
<TABLE BORDER=2 CELLPADDING=5><TR><TD BGCOLOR="#ff8888">
EOS

  if ($sendh->close) {
    warn "Uploader sent mail to $userref->{email} and closed successfully";
    $what_we_did .= $self->dict("D028", $userref->{email});
  } else {
    warn "Uploader tried to send mail, but...: $!";
    $what_we_did .= $self->dict("D029", $!);
  }
  $what_we_did .= qq{</TD></TR></TABLE>};
  $what_we_did;
}

sub upload_form {
  my($self) = @_;
  my $cgi = $self->{CGI};
  my $r = $self->{R};
  my($userref) = $self->{USERREF};

  my(@m);
  push @m, $cgi->start_multipart_form(-action => $r->uri);
  push @m, "<H4>Upload</H4>\n";
  push @m, $self->dict("D030");
  push @m, "<BR>";
  push @m, $cgi->hidden('HIDDEN1',"VALUE1");
  push @m, $cgi->filefield(-name => "HTTPUPLOAD", size => 48);
  push @m, $cgi->hidden('HIDDEN2',"VALUE2"); 
  push @m, qq{<BR>\n};
  push @m, $self->dict("D031");
  push @m, join(", ", @{$userref->{permitted} || []});
  push @m, qq{ \)<BR>\n};
  push @m, $cgi->textfield(
			   -name => "TARGETDIR", 
			   size => 63,
			   maxlength => 63,
			   'default' => $userref->{permitted}[0],
			  );
  push @m, "\n<BR>";
  push @m, $cgi->submit(
			-name=>'SUBMITup',
			value=> $self->dict("D032")
		       );
  join "", @m;
}

sub hello {
  my($self) = @_;
  my($cgi) = $self->{CGI};
  my($userref) = $self->{USERREF};
  my(@m);
  my @hello = ("D033".."D037");
  my $time = $self->time;
  my @time = localtime($time);
  my $daytime = $time[2];
  if ($daytime >= 7 && $daytime < 10) {
    push @hello, "D038";
  } elsif ($daytime >= 19 || $daytime < 1) {
    push @hello, "D039";
  } elsif ($daytime >= 10) {
    push @hello, "D040";
    if ($daytime >=11 && $daytime < 14) {
      push @hello, "D042";
    }
  } else {
    push @hello, "D043";
  }

  my $hello = $self->dict($hello[rand @hello]);

  my(@m);
  push @m, qq{<H3>$hello $userref->{salut} $userref->{lastname},</H3>};
  push @m, $self->dict('D001');
  push @m, $self->dict("D044");
  push @m, qq{<P>\n};
  join "", @m;
}

sub document_root {
  my($self) = @_;
  return $self->{DOCUMENT_ROOT} if exists $self->{DOCUMENT_ROOT};
  my $document_root = $self->{R}->document_root;
  $document_root =~ s|/+$||; # trailing slashes disturb processing here
  $self->{DOCUMENT_ROOT} = $document_root;
}

sub request { shift->{R} }

sub transhandler {
  my($self) = @_;
  my($userref) = $self->{USERREF};
  my($what_we_did);
  my($cgi) = $self->{CGI};
  my($r) = $self->{R};
  my $stagedir = $self->{STAGEDIR};
  my $secret = $cgi->param("SUBMITtrans");
  my $transdir = $r->dir_config('Apache_UploadSvr_transdir');
  unless ($transdir) {
    $r->log_error("No Apache_UploadSvr_transdir specified. Setting to /tmp");
    $transdir = "/tmp";
  }
  my $trashdir = $r->dir_config('Apache_UploadSvr_trashdir');
  unless ($trashdir) {
    $r->log_error("No Apache_UploadSvr_trashdir specified. Setting to /tmp");
    $trashdir = "/tmp";
  }
  File::Path::mkpath($trashdir);
  my $dh = DirHandle->new($trashdir) or die;
  my $time = $self->time;
  for my $d ($dh->read) {
    my $old =  "$trashdir/$d";
    stat $old;
    next unless -f _;
    next unless (stat _)[9] < $time - 7 * 86400;
    unlink $old;
  }
  my $dh = DirHandle->new($transdir) or die
      "Couldn't opendir $transdir directory: $!";
  for my $dirent ($dh->read) {
    my $file = "$transdir/$dirent";
    stat $file;
    if (-f _ && (-M _ > 3)) {
      unlink $file;
    }
  }
  my $efile = "$transdir/$userref->{user}$secret";
  my $document_root = $self->document_root;
  if (-r $efile) {
    my $fh = IO::File->new($efile) or die "Couldn't open $efile: $!";
    my($doit,@done);
    while ( defined($doit = <$fh>) ) {
      chomp $doit;
      my($command,@args) = split " ", $doit;
      if ($command =~ /^\s*\#/) {
	next;
      }
      if ($command eq "publish") {
	my $f = $args[0];
	my($targetdir,$absfile,$targetfile);
	$targetfile = "$document_root$f";
	$targetdir = dirname($targetfile);
	$absfile = "$stagedir$f";
	eval {
	  File::Path::mkpath($targetdir);
	  rename($absfile, $targetfile) or die $!;
	};
	push @done, $@ ? $self->dict("D022",$doit,$@)
	    : $self->dict("D023",$f,$f);
	$r->log_error("doit[$doit]ERR[$@]targetfile[$targetfile] targetdir[$targetdir] absfile[$absfile]");
      } elsif ($command eq "unpublish") {
	my $f = $args[0];
	my($rmfile, $trashfile);
	$rmfile = "$document_root$f";
	$trashfile = $trashdir . "/" . basename($f);
	if ($self->has_perms($f)) {
	  if (-f $rmfile) {
	    if (rename $rmfile, $trashfile) {
	      push @done, qq{<B>unpublish</B> $f<BR>};
	      my $rmf = $rmfile;
	      while () {
		my $rmd = File::Basename::dirname($rmf);
		my $d = File::Basename::dirname($f);
		my $dh = DirHandle->new($rmd) or die "Couldn't diropen $d: $!";
		my @dirent = $dh->read;
		if (@dirent == 3 && -d "$rmd/.dircache") {
		  File::Path::rmtree("$rmd/.dircache");
		  pop @dirent;
		}
		if (@dirent == 2) { # empty directory
		  if ( rmdir $rmd ) {
		    push @done, qq{  };
		    push @done, $self->dict("D045",$d);
		    $f = $d;
		    $rmf = $rmd;
		  } else {
		    last;
		  }
		} else {
		  last;
		}
	      }
	    } else {
	      push @done, $self->dict("D022",$doit,$!);
	    }
	  } else {
	    push @done, $self->dict("D046",$doit);
	    $r->log_error("DEBUG: rmfile[$rmfile]");
	  }
	} else {
	  push @done, $self->dict("D047",$doit);
	  $r->log_error(qq{DEBUG:rmfile[$rmfile]trashfile[$trashfile]user[$userref->{user}]});
	}
      }
    }
    $fh->close;
    unlink $efile or die "Couldn't unlink $efile";
    $what_we_did = join("\n",
			$self->dict("D048",$secret),
			@done
		       );
  } else {
    $what_we_did = $self->dict("D049", $secret);
  }
  warn scalar(localtime) . $what_we_did;
  $what_we_did;
}

sub has_perms {
  my($self,$f) = @_;
  # warn "has_perms f[$f]";
  my $userref = $self->{USERREF};
  $userref->has_perms($f);
}

sub unzip {
  my($self,$f) = @_;
  my $stagedir = $self->{STAGEDIR};
  my $absfile = "$stagedir$f";
  my $done;
  my $fromdir = dirname($absfile);
  my $fromfile = basename($f);
  chdir $fromdir;
  my $system;
  if ($fromfile =~ /\.t(ar\.)?gz$/i){
    $system="tar xvzf $fromfile";
  } elsif ($fromfile =~ /\.zip$/i){
    $system="unzip -a $fromfile";
  } elsif ($fromfile =~ /\.gz$/i) {
    $system="gzip -dv $fromfile";
  }
  if ($system) {
    my $out = `$system 2>&1`;
    my $ret = $? >> 8;
    if ($ret == 0) {
      $done = $self->dict("D051",$system);
    } else {
      $done = join("",
		   $self->dict("D050",$system),
		   "<PRE>",
		   $out,
		   "</PRE>");
    }
  } else {
    $done = $self->dict("D052",$f);
  }
  $done;
}

sub publish {
  my($self,$f) = @_;
  my $sectrans = "";
  my $error = "";
  if ($self->has_perms($f)) {
    $sectrans = qq{  publish $f\n};
  } else {
    $error = $self->dict("D053",$f);
  }
  return($sectrans,$error);
}

sub lowercase {
  my($self,$f) = @_;
  my $stagedir = $self->{STAGEDIR};
  my $done;
  my $lc = lc $f;
  if ($lc eq $f) {
    $done = $self->dict("D054", $f);
  } else {
    my $targetfile = "$stagedir$lc";
    my $targetdir = dirname("$targetfile");
    File::Path::mkpath($targetdir);
    my $absfile = "$stagedir$f";
    my $ok = $self->dict(rename($absfile, $targetfile) ? "D055" : "D056");
    $done = $self->dict("D057", $f, $lc, $ok);
  }
  return $done;
}

sub delete {
  my($self,$f) = @_;
  my $stagedir = $self->{STAGEDIR};
  my $absfile = "$stagedir$f";
  my $ok = $self->dict(unlink($absfile) ? "D055" : "D056");
  return "<B>delete</B> $absfile [$ok]<BR>";
}

sub linkcheck { # no dictionary used in this subroutine
  my($self,$f,$files) = @_;
  my $stageuri = $self->{STAGEURI};
  my($r) = $self->{R};
  my $display_method = (@$files > 1) ? "as_line" : "as_table";
  my $document_root = $self->document_root;
  my(@done,%seen);
  my($cntf,$cntn,$cnta,$try);
  my $servername = $r->server->server_hostname,
  $display_method ||= "";
  $try = "view";
  require HTML::LinkExtor;
  my $p = HTML::LinkExtor->new;
  $p->parse_file("$document_root$stageuri$f");
  my $s_uri = URI::URL->new("http://$servername$stageuri$f");
  my $b_uri = URI::URL->new("http://$servername$f");
  for my $link ($p->links) {
    my($rlink, $slink, @comment);
    my $tag = shift @$link;
    my %attr = @$link;
    my($k,$v,@attr);
    while (($k,$v) = each %attr) {
      my $x = qq{$k="$v"};
      while ($x =~ s/(.{1,35}\b)//) {
	push @attr, $1;
      }
      push @attr, $x;
    }
    my $href;
    if ($href = $attr{href} || $attr{src} || $attr{background}) {
      if ($seen{$href}++) {
	$rlink = $slink = "-";
	push @comment, "see above";
      } else {
	my $t_uri = URI::URL->new($href);
	my $found = 0;
	my $rbase = $t_uri->abs($b_uri);
	my $sbase = $t_uri->abs($s_uri);
	if ($rbase->path =~ m|^/../|) {
	  $rlink = $slink = "bad path";
	} elsif ($rbase->scheme ne "http") {
	  my $scheme = $rbase->scheme;
	  $rlink = qq{<a href="$href">$try</A>};
	  $slink = "-";
	  push @comment, qq{protocol $scheme not tested};
	  $found++;
	  $cntn++;
	} elsif ($rbase->host ne $servername) {
	  $rlink = qq{<a href="$href">$try</A>};
	  $slink = qq{-};
	  push @comment, qq{remote host not tested};
	  $found++;
	  $cntn++;
	} else {
	  # real link, stage link
	  $rlink = $slink = "needs work";
	  my $path = $rbase->path;
	  my $subr = $r->lookup_uri($path);
	  my $file = $subr->filename;
	  stat $file;
	  if (-f _ || -d _) {
	    $found++;
	    if ($rbase->frag) {
	      my $abs = $rbase->path ."#". $rbase->frag;
	      $rlink = qq{<a href="$abs">$try</A>};
	      if ($rbase->path eq $f) {
		# anchortesten?
	      }
	      $cnta++;
	      push @comment, "Real Link anchor not tested";
	    } else {
	      my $abs = $rbase->as_string;
	      $rlink = qq{<a href="$abs">$try</A>};
	      push @comment, "Real Link OK";
	    }
	  } else {
	    # could really run a subrequest
	    my $abs = $rbase->as_string;
	    $rlink = qq{file not found, try to <a href="$abs">$try</A>};
	  }
	  $path = $sbase->path;
	  stat "$document_root$path";
	  if (-f _ || -d _) {
	    $found++;
	    if ($sbase->frag) {
	      my $abs = $sbase->path ."#". $sbase->frag;
	      $slink = qq{<a href="$abs">$try</A>};
	      $cnta++;
	      push @comment, "Stage Link anchor not tested";
	    } else {
	      my $abs = $sbase->as_string;
	      $slink = qq{<a href="$abs">$try</A>};
	      push @comment, "Stage OK";
	    }
	  } else {
	    $slink = "not found";
	  }
	}
	unless ($found) {
	  $rlink = "<B>$rlink</B>";
	  $slink = "<B>$slink</B>";
	  $cntf++;
	}
      }
    } else {
      $rlink  = $slink = "no href, no src, not tested";
    }
    my $attr = join " ", @attr;
    my $comment = join ", ", @comment;
    $attr =~ s/\"/&quot;/g;
    push @done, sprintf(<<EOS,
<TR><TD>%s %s</TD><TD ALIGN=CENTER>%s</TD><TD
ALIGN=CENTER>%s</TD><TD>%s</TD></TR>
EOS
			$tag, $attr, $rlink, $slink, $comment);
  }
  if (@done) {
    unshift(@done, <<EOS);
<TABLE><TR>
<TH>Ref</TH>
<TH><I>Real</I> Link</TH>
<TH><I>Stage</I> Link</TH>
<TH>Comment</TH></TR>
EOS
    push @done, "</TABLE>\n";
  }
  my $vreport = sprintf "%d Error", $cntf;
  $vreport .= sprintf ", %d Links not tested", $cntn if $cntn;
  $vreport .= sprintf ", %d Anchor not tested", $cnta if $cnta;
  unshift(
	  @done,
	  sprintf(
		  qq{<TABLE BORDER><TR><TH>File <A HREF="%s%s">%s%s</A> }.
		  qq{%s</TH></TR><TR><TD>},
		  $stageuri,
		  $f,
		  $stageuri,
		  $f,
		  $vreport
		 ));
  push @done, "</TABLE>\n";

  if ($display_method eq "as_line") {
    return sprintf(
		   qq{<A HREF="/perl/user/up?SUBMITaction=1&}.
		   qq{ACTION=linkcheck&STAGEDFILES=%s">%s%s</A> %s<BR>},
		   $f,
		   $stageuri,
		   $f,
		   $vreport);
  }
  return join "\n", @done;
}

1;

=head1 NAME

Apache::UploadSvr - A Lightweight Publishing System for Apache

=head1 SYNOPSIS



=head1 DESCRIPTION

This module implements a small publishing system for a web server with
authentication, simple security, preview, directory viewer and an interface
to delete files. The whole system is actually running software on
www.kulturbox.de at the time of publishing (i.e. Summer 1998).

The author is looking for somebody to take this code over for
maintainance.

=head1 CONFIGURATION

httpd.conf:

  PerlSetVar Auth_DBI_data_source dbi:mSQL:authen
  PerlSetVar Auth_DBI_pwd_table   usertable
  PerlSetVar Auth_DBI_grp_table   grouptable
  PerlSetVar Auth_DBI_uid_field   user
  PerlSetVar Auth_DBI_grp_field   group
  PerlSetVar Auth_DBI_pwd_field   password
  PerlSetVar stageuri /STAGE
  PerlSetVar Apache_UploadSvr_Usermgr "Apache::UploadSvr::User"
  PerlSetVar Apache_UploadSvr_myuri /perl/user/up
  PerlSetVar Apache_UploadSvr_transdir /usr/local/apache/trans
  PerlSetVar Apache_UploadSvr_trashdir /usr/local/apache/trash


  <Files "...">
    PerlSetVar DirCache .dircache
    SetHandler perl-script
    PerlHandler Apache::UploadSvr::Directory
    AuthName stadtplandienst
    AuthType Basic
    PerlAuthenHandler Apache::AuthenDBI
    require valid-user
  </Files>

  <Location /perl/user/up>
    PerlHandler Apache::UploadSvr
  </Location>

Change the permissions for the whole document tree to give the server
write access.

=head1 SECURITY



=head1 EXPORT



=head1 BUGS



=head1 COPYRIGHT

The application and accompanying modules are Copyright KULTURBOX, Berlin.
It is free software and can be used, copied and redistributed at the same
terms as perl itself.

=head1 AUTHOR

Andreas Koenig <koenig@kulturbox.de>

=cut
