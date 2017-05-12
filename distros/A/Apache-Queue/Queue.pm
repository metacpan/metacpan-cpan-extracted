package Apache::Queue;
$VERSION = 0.6;
use strict;
use Apache2 ();
use Apache::Connection;
use Apache::RequestIO;
use Apache::RequestRec;
use Apache::RequestUtil;
use Apache::SubRequest;
use Apache::Const qw( :common :methods :http );
use Apache::Log;
use Fcntl;
use DB_File;
use Template;

use vars qw( @sends @queue $r $template );

sub handler {
  $r = shift;

  return DECLINED unless ($r->is_initial_req());

  my $status = OK;
  my ($found, $x, $pos );
  my $host = $r->connection->remote_ip;

  my $max_sends  = $r->dir_config("MaxSends") || 10;
  my $queue_size = $r->dir_config("QueueSize") || 300;
  my $tmpdir = $r->dir_config("QueuePath") || "/tmp";

  my $s = tie @sends, 'DB_File', "$tmpdir/apache_queue-sends", O_RDWR|O_CREAT, 0666, $DB_RECNO;
  my $q = tie @queue, 'DB_File', "$tmpdir/apache_queue-queue", O_RDWR|O_CREAT, 0666, $DB_RECNO;

  my $now = time;
  @sends = grep { $now-$_ < 300 } @sends;
  @queue = grep { $now-$_ < 300 } @queue;

  # Search the send queue to see if the visitor is already
  # downloading, or is waiting to.
  $found = $x = $pos = 0;
  foreach(@sends) {
    if(/^\d+\|\d+\|$host$/) {
      $found = 1;
      $pos = $x;
      last;
    }
    $x++;
  }

  if($found) {
    # The user is in the send queue
    my($time, $sending, $visitor) = split(/\|/, $sends[$pos]);
    if($sending < 1) {  
      # The visitor was waiting, starting download
      $sends[$pos] = "$now|1|$host";
      $s->sync();
 
      $status = send_file($r);

      splice(@sends, $pos, 1);
      $s->sync();
    } else {
      # The visitor already is downloading
      show_template("queue_sending.html");
      $status = OK;
    }
  } else {
    # The visitor was not in the send queue.  Check if there are
    # send slots open, if so send them the file, otherwise add
    # them to the queue.
    if($#sends < ($max_sends - 1) && $#queue < 0) {
      # There is an open send slot, add the visitor, and let him go.
      push @sends, "$now|0|$host";
      show_template("queue_send.html", { 'uri' => $r->uri });
      $status = OK;
    } else {
      # All send slots are full, attempt to queue the visitor.
      $found = $x = $pos = 0;
      foreach(@queue) {
        if(m/^\d+\|$host$/) {
          $found = 1;
          $pos = $x;
          last;
        }
        $x++;
      }
  
      if($found) {
        my $open = $max_sends - ($#sends + 1);
        if($pos < $open) {
          push @sends, "$now|0|$host";
          @queue = splice(@queue, $pos, 1);
          show_template("queue_send.html", { 'uri' => $r->uri });
          $status = OK;
        } else {
          $queue[$pos] = "$now|$host";
          show_template("queue_position.html", { 'url' => $r->uri, 'position' => ($pos + 1), 'queue_size' => ($#queue + 1) });
          $status = OK;    
        }
      } else {    
        if(($#queue + 1) < $queue_size) {
          $pos = push @queue, "$now|$host";
          show_template("queue_position.html", { 'url' => $r->uri, 'position' => $pos, 'queue_size' => $#queue + 1 });
          $status = OK;
        } else {
          show_template("queue_full.html", { 'queue_size' => $queue_size });
          $status = OK;
        }
      }
    }
  }
    
  untie @sends;
  untie @queue;
  return $status;
}

sub send_file {
  my $r = shift;
  my $sub = $r->lookup_uri($r->uri);
  return $sub->run();
}

sub show_template {
  my ($name, $vars) = @_;

  my $file     = Template::Provider->new(ABSOLUTE  => '1');
  my $hash     = Queue::Template::Default->new();
  $template    = Template->new( {
    OUTPUT         => $r,
    LOAD_TEMPLATES => [ $file, $hash ],
    PREFIX_MAP     => {
      file    => '0',
      hash    => '1',
      default => '1',
    },
  });

  $r->content_type("text/html");

  my $path = $r->dir_config("TemplatePath");
  if($path ne '') {
    $template->process("file:$path/$name", $vars) || warn $template->error();
  } else {
    $template->process("hash:$name", $vars) || warn $template->error();
  }
}

package Queue::Template::Default;
@Queue::Template::Default::ISA = qw(Template::Provider);

my %Defaults = (
'queue_send.html' => <<EOQSH
<html>
<head>
<meta HTTP-EQUIV="refresh" content="1; URL=[% uri %]">
</head>
<body topmargin=0 leftmargin=0 marginheight=0 marginwidth=0>
<table height=100% width=100%>
<tr><td valign=center align=center>
<font face="arial" size=2>
Click <a href="[% uri %]">here</a> if your download does not start
</font>
</td></tr></table>
</body>
</html>
EOQSH
,
'queue_full.html' => <<EOQFH
<html>
<head>
<meta HTTP-EQUIV="refresh" content="300; URL=[% uri %]">
</head>
<body topmargin=0 leftmargin=0 marginheight=0 marginwidth=0>
<table height=100% width=100%>
<tr><td valign=center align=center>
<font face="arial" size=2>
Sorry, the queue is full<BR>Keep this window open to keep trying
</font>
</td></tr></table>
</body>
</html>
EOQFH
,
'queue_position.html' => <<EOQPH
<html>
<head>
<meta HTTP-EQUIV="refresh" content="60; URL=[% uri %]">
</head>
<body topmargin=0 leftmargin=0 marginheight=0 marginwidth=0>
<table height=100% width=100%>
<tr><td valign=center align=center>
<font face="arial" size=2>
You are in position [% position %] of [% queue_size %]<BR>
Keep this window open to stay in line
</font>
</td></tr></table>
</body>
</html>
EOQPH
,
'queue_sending.html' => <<EOQS
<html>
<body topmargin=0 leftmargin=0 marginheight=0 marginwidth=0>
<table height=100% width=100%>
<tr><td valign=center align=center>
<font face="arial" size=2>
You are already downloading a file
</font>
</td></tr></table>
</body>
</html>
EOQS
);

sub new {
  my $self = {};
  bless $self;
  return $self;
}

sub fetch {
  my ($self, $name) = @_;
  my ($data, $error);
  if($Defaults{$name} ne '') {
    $data = { text => $Defaults{$name} };
    ($data, $error) = $self->_compile($data);
    $data = $data->{ data } unless $error;
    return ($data, Template::Constants::STATUS_OK);
  } else{
    return (undef, Template::Constants::STATUS_ERROR);
  }
}

sub load {
  my ($self, $name) = @_;
  if($Defaults{$name} ne '') {
    return ($Defaults{$name}, Template::Constants::STATUS_OK);
  } else{
    return (undef, Template::Constants::STATUS_ERROR);
  }
}

1;
__END__

=head1 NAME

Apache::Queue - An HTTP file queueing system.

=head1 SYNOPSIS

  #httpd.conf
  <Directory "/usr/local/apache/htdocs/files">
    SetHandler perl-script
    PerlHandler Apache::Queue
    
    # the size of the queue (default: 300)
    PerlSetVar QueueSize 300
    
    # how many simultanious file transfers
    # before queueing (default: 10)
    PerlSetVar MaxSends 10
    
    # Location of queue files (default: /tmp)
    # This path must be writable by the Apache
    # process
    PerlSetVar QueuePath /tmp
    
    # Location of customized templates if needed
    # Do not set this if you wish to use the internal templates
    # Templates are process by Template-Toolkit, see
    # http://www.template-toolkit.org for docs
    #
    # There are 4 template files needed.
    #  queue_send.html     - The "Your download should start..." page
    #  queue_sending.html  - Notifys the visitor of an existing download
    #  queue_position.html - Page used while a user is inline
    #  queue_full.html     - Tells the queue is full
    # 
    # View the defaults in the module for samples
    PerlSetVar TemplatePath /usr/local/apache/templates
    
  </Directory>

=head1 DESCRIPTION

An HTTP file queueing system.  Allow visitors to "line up" to
download files.

=head1 SEE ALSO

mod_perl(3), Apache(3)

=head1 AUTHOR

Donald Becker - psyon@psyon.org

