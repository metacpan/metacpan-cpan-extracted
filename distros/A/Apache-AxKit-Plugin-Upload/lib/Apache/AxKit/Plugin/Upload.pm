package Apache::AxKit::Plugin::Upload;
use strict;

use Apache::Constants qw(:common);
use Number::Format;
use Fcntl qw(LOCK_EX LOCK_NB O_RDWR O_CREAT);
use IO::Handle;

BEGIN {
    our $VERSION = 0.2;
}

eval {
  require Time::HiRes;
};
if (!$@) {
  use Time::HiRes;
}

my ($start, $sizetotal, $file, $location, $nf, $custom, $running, $lock);

sub print_html {
    my ($now, $sizedone) = @_;
    my $elapsed = $now-$start;

    my $todo = 0;
    $todo = ($sizetotal - $sizedone) * $elapsed / $sizedone if $sizedone > 0;

    my $percent = 0;
    $percent = int($sizedone*100/$sizetotal) if $sizetotal > 0;
    my $showpercent = ($percent?$percent:1);
    #warn("printing: $percent");

    my $speed = 0;
    $speed = $nf->format_bytes($sizedone / $elapsed,1) if $elapsed > 0;

    $sizedone = $nf->format_bytes($sizedone,1);
    my $sizetotal = $nf->format_bytes($sizetotal,1);
    $elapsed = sprintf("%i:%02i",int($elapsed/60),$elapsed%60);
    $todo = sprintf("%i:%02i",int($todo/60),$todo%60);

    local(*FH);
    open(FH, ">$file.tmp") || warn("could not open $file.tmp: $!");

    if (!$custom && $percent == 100) {
        print FH << "EOF";
<html>
  <head>
    <title>Upload Status</title>
  </head>
  <body bgcolor="#ffffff" text="#000000">
    <table border="0" width="264" cellspacing="0" cellpadding="1" style="table-layout: fixed;">
      <tr>
        <td width="40" height="24"><font face="sans-serif">$percent\%</font></td>
        <td width="224" height="24" bgcolor="#000000"><table border="0" width="222" cellspacing="0" cellpadding="1" style="table-layout: fixed;" bgcolor="#ffffff">
          <tr>
            <td height="22"><table border="0" width="$showpercent\%" cellspacing="0" cellpadding="0" style="table-layout: fixed;">
              <tr><td height="20" bgcolor="#000080"><font size="-7">&nbsp;</font></td></tr>
            </table></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td align="center"><font face="sans-serif" size="-1">$sizedone / $sizetotal, ${speed}b/s, $todo</font></td>
      </tr>
    </table>
    <font color="#ffffff"><script language="javascript">window.close()</script></font>
  </body>
</html>
EOF
    } else {
        print FH << "EOF";
<html>
  <head>
    <title>Upload Status</title>
    <meta http-equiv="Refresh" CONTENT="1; URL=$location" />
  </head>
  <body bgcolor="#ffffff" text="#000000">
    <table border="0" width="264" cellspacing="0" cellpadding="1" style="table-layout: fixed;">
      <tr>
        <td width="40" height="24"><font face="sans-serif">$percent\%</font></td>
        <td width="224" height="24" bgcolor="#000000"><table border="0" width="222" cellspacing="0" cellpadding="1" style="table-layout: fixed;" bgcolor="#ffffff">
          <tr>
            <td height="22"><table border="0" width="$showpercent\%" cellspacing="0" cellpadding="0" style="table-layout: fixed;">
              <tr><td height="20" bgcolor="#000080"><font size="-7">&nbsp;</font></td></tr>
            </table></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td align="center"><font face="sans-serif" size="-1">$sizedone / $sizetotal, ${speed}b/s, $todo</font></td>
      </tr>
    </table>
  </body>
</html>
EOF
    }
    rename("$file.tmp",$file);
}

sub init {
    my ($r,$upload_id) = @_;
    my $destdir = $r->dir_config('AxUploadStatusDir') || return 0;
    $destdir = $r->document_root.'/'.$destdir if substr($destdir,0,1) ne '/';
    my $destloc = $r->dir_config('AxUploadStatusLocation') || return 0;
    my $format = lc($r->dir_config('AxUploadFormat')) || 'html';
    $location = "$destloc/$upload_id.$format";
    $file = "$destdir/$upload_id.$format";
    local(*FH);
    open(FH, ">$file.tmp") || warn("could not open $file.tmp: $!");
    print FH << "EOF";
<html>
  <head>
    <title>Upload Status</title>
    <meta http-equiv="Refresh" CONTENT="1; URL=$location" />
  </head>
  <body bgcolor="#ffffff" text="#ffffff">
    &nbsp;
  </body>
</html>
EOF
    close(FH);
    rename("$file.tmp",$file);
}

sub progress {
    my ($done, $total, $message) = @_;
    my $now = time();
    my $elapsed = $now-$start;

    my $todo = 0;
    $todo = ($total - $done) * $elapsed / $done if $done > 0;
    
    my $percent = 0;
    $percent = int($done*100/$total) if $total > 0;
    my $showpercent = ($percent?$percent:1);
    
    $todo = sprintf("%i:%02i",int($todo/60),$todo%60);
    
    local(*FH);
    open(FH, ">$file.tmp") || warn("could not open $file.tmp: $!");
    if ($percent == 100) {
        print FH << "EOF";
<html>
  <head>
    <title>Upload Status</title>
  </head>
  <body bgcolor="#ffffff" text="#000000">
    <table border="0" width="264" cellspacing="0" cellpadding="1" style="table-layout: fixed;">
      <tr>
        <td width="40" height="24"><font face="sans-serif" size="-1">$percent\%</font></td>
        <td width="224" height="24" bgcolor="#000000"><table border="0" width="222" cellspacing="0" cellpadding="1" style="table-layout: fixed;" bgcolor="#ffffff">
          <tr>
            <td height="22"><table border="0" width="$showpercent\%" cellspacing="0" cellpadding="0" style="table-layout: fixed;">
              <tr><td height="20" bgcolor="#000080"><font size="-7">&nbsp;</font></td></tr>
            </table></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td align="center"><font face="sans-serif" size="-1">$message</font></td>
      </tr>
    </table>
    <font color="#ffffff"><script language="javascript">window.close()</script></font>
  </body>
</html>
EOF
        close($lock);
    } else {
        print FH << "EOF";
<html>
  <head>
    <title>Upload Status</title>
    <meta http-equiv="Refresh" CONTENT="1; URL=$location" />
  </head>
  <body bgcolor="#ffffff" text="#000000">
    <table border="0" width="264" cellspacing="0" cellpadding="1" style="table-layout: fixed;">
      <tr>
        <td width="40" height="24"><font face="sans-serif" size="-1">$percent\%</font></td>
        <td width="224" height="24" bgcolor="#000000"><table border="0" width="222" cellspacing="0" cellpadding="1" style="table-layout: fixed;" bgcolor="#ffffff">
          <tr>
            <td height="22"><table border="0" width="$showpercent\%" cellspacing="0" cellpadding="0" style="table-layout: fixed;">
              <tr><td height="20" bgcolor="#000080"><font size="-7">&nbsp;</font></td></tr>
            </table></td>
          </tr>
        </table></td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td align="center"><font face="sans-serif" size="-1">$message</font></td>
      </tr>
    </table>
  </body>
</html>
EOF
    }
    close(FH);
    rename("$file.tmp",$file);
}

sub is_running {
    my ($r,$upload_id) = @_;
    return 0 if ($running eq $upload_id);
    my $destdir = $r->dir_config('AxUploadStatusDir') || return 0;
    $destdir = $r->document_root.'/'.$destdir if substr($destdir,0,1) ne '/';
    my $format = lc($r->dir_config('AxUploadFormat')) || 'html';
    $file = $destdir."/".$upload_id.".".$format;
    local (*FH);
    sysopen(FH,$file.".lck",O_RDWR) || return undef;
    my $unlocked = flock(FH,LOCK_EX|LOCK_NB);
    close(FH);
    return !$unlocked;
}

sub upload_handler_html {
    my ($upload, $buf, $len, $hook_data) = @_;
    my ($sizedone, $lasttime) = @$hook_data;
    my $now = time();

    $sizedone += $len;
    $$hook_data[0] = $sizedone;

    #warn("now: $now, done: $sizedone, last: $lasttime");
    return if (int($now) == $lasttime);
    $$hook_data[1] = int($now);

    print_html($now, $sizedone);
}

sub handler {
    my ($r) = @_;

    my %args = $r->args;
    my $upload_id = $args{'axkit_upload_id'};
    $running = '';

    my $destdir = $r->dir_config('AxUploadStatusDir') || return OK;
    $destdir = $r->document_root.'/'.$destdir if substr($destdir,0,1) ne '/';
    my $destloc = $r->dir_config('AxUploadStatusLocation') || return OK;
    my $format = lc($r->dir_config('AxUploadFormat')) || 'html';
    $custom = $r->dir_config('AxUploadCustom');
    $file = "$destdir/$upload_id.$format";
    $location = "$destloc/$upload_id.$format";
    return OK unless $upload_id;
    return OK unless $r->method eq 'POST';
    $lock = new IO::Handle;
    sysopen($lock,$file.".lck",O_RDWR|O_CREAT) || return OK;
    my $unlocked = flock($lock,LOCK_EX|LOCK_NB);
    return OK if !$unlocked;

    $running = $upload_id;
    # from Apache::RequestNotes
    my $maxsize   = $r->dir_config('MaxPostSize') || 1024;
    my $uploads   = $r->dir_config('DisableUploads') =~ m/Off/i ? 0 : 1;

    $nf = new Number::Format(split(/ /,$r->dir_config('AxUploadNumberFormat')));

    $sizetotal = $r->header_in('Content-Length');
    $start = time();
    AxKit::Debug(3,"[Upload] managing upload: $sizetotal bytes, status in $destdir/$upload_id.$format");

    print_html($start, 0);

    my $apr = Apache::Request->instance($r,
        POST_MAX => $maxsize,
        DISABLE_UPLOADS => $uploads,
        HOOK_DATA => [ $file, $location, $nf, $sizetotal, 0, $start, -1 ],
        UPLOAD_HOOK => \&upload_handler_html,
    );
    $apr->parse;

    print_html(time(), $sizetotal);

    $start = time();
    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::Upload - upload tracking for AxKit

=head1 SYNOPSIS

In .htaccess:

  AxAddPlugin Apache::AxKit::Plugin::Upload
  PerlSetVar AxUploadStatusDir data/upload
  PerlSetVar AxUploadStatusLocation /data/upload
  PerlSetVar DisableUploads Off
  PerlSetVar MaxPostSize 30485760
  LimitRequestBody 30485760

Put this code on the form: (example using XSP)

  <form enctype="multipart/form-data" action="process.xsp?axkit_upload_id={$r->connection->user|"
      onsubmit="window.open('http://'+location.hostname+'{$r->dir_config('AxUploadStatusLocation').'/'.$r->connection->user}.html','axkit_upload','height=80,width=320,height=80')">
      ...
  </form>

=head1 DESCRIPTION

This plugin allows you to show a progress bar while uploading big files. This works
by opening a small window via JavaScript. That window is directed to a self-refreshing
HTML page which is continuously updated by this plugin.

Usually, three URLs are involved: The page starting the upload, the page receiving the
upload, and the status page. The receiving page I<must> have "axkit_upload_id=..." in
the I<query string>. That ID is used to identify the specific upload. Use a username or
a session ID or even a random number. You cannot have more than one upload for one ID.
The status page is named <AxUploadStatusDir>/<ID>.html

Set AxUploadStatusDir to where the files should be stored. Relative paths get
$r->document_root prepended. Set AxUploadStatusLocation to where the client can get
the files in AxUploadStatusDir.

=head2 Advanced Configuration

If you want to process the received data and the processing is slow, you can extend the
progress bar to include your custom status. To do so, set

  PerlSetVar AxUploadCustom On

and call:

  Apache::AxKit::Plugin::Upload::progress($done,$total,"Processing... ($done/$total)");

regularly to update the progress bar. The window will automatically close when
$done == $total.

To see if an upload is already running, call:

  Apache::AxKit::Plugin::Upload::is_running($r,$id)

In some constellations, the upload progress bar won't appear or shows a 404. This
highly depends on your file layout. To fix that problem, create a tiny script that does:

  Apache::AxKit::Plugin::Upload::init($r,$id)
      if (!Apache::AxKit::Plugin::Upload::is_running($r,$id));

and then redirects to <AxUploadStatusLocation>/<ID>.html. Call this script instead of
<AxUploadStatusLocation>/<ID>.html.

=head1 AUTHOR and LICENSE

Copyright (C) 2004, Jörg Walter.

This plugin is licensed under either the GNU GPL Version 2, or the Perl Artistic
License.

=cut

