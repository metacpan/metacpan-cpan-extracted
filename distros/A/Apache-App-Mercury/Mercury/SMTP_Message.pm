package Apache::App::Mercury::SMTP_Message;

require 5.004;
use strict;

use Apache::App::Mercury::Config;
# SMTP_Message subclasses Message, and simply adds a few e-mail sending methods
use Apache::App::Mercury::Message;
use base qw(Apache::App::Mercury::Message);

use MIME::Lite;
use POSIX qw(mktime);

use constant SMTP_SERVER  => Apache::App::Mercury::Config::SMTP_SERVER;
use constant SMTP_HELLO   => Apache::App::Mercury::Config::SMTP_HELLO;
use constant SMTP_TIMEOUT => Apache::App::Mercury::Config::SMTP_TIMEOUT;
use constant SMTP_DEBUG   => Apache::App::Mercury::Config::SMTP_DEBUG;
use constant MIME_NOTIFY_HDR => Apache::App::Mercury::Config::MIME_NOTIFY_HDR;
use constant MIME_NOTIFY_MSG => Apache::App::Mercury::Config::MIME_NOTIFY_MSG;
use constant MIME_FOOTER  => Apache::App::Mercury::Config::MIME_FOOTER;


sub new {
    my ($this, $self) = @_;
    my $class = ref($this) || $this;
    unless (ref $self eq "HASH" or
	    ref $self eq "Apache::App::Mercury::Message") { $self = {} }
    bless $self, $class;
    return $self;
}

# database persistence methods

sub set_smtp_status {
    my ($self, $sent) = @_;

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("UPDATE ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." SET status_smtp=?,timestamp=timestamp WHERE id=?");
	$sth->execute($sent ? 'sent' : 'checked', $self->{'id'});
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return 0;
    }
    return 1;
}


# MIME e-mail connectivity methods and helpers

# returns the number of e-mails sent
sub send_by_e_mail {
    my ($self) = @_;
    my $messaging = $self->{messaging};
    my $usermgr = $messaging->{user_manager};
    $usermgr->{user} = $self->{'recipient'};

    my %autoforw =
      ( 'low' => $usermgr->auto_forward('low'),
	'medium' => $usermgr->auto_forward('medium'),
	'high' => $usermgr->auto_forward('high') );

    $self->{'address'} =
      ($usermgr->get_userinfo($self->{'recipient'}))[0]->{e_mail};

    $self->warn("->send_by_e_mail: attempting send of msgid='".$self->{'id'}."', user='".$self->{'recipient'}."', address='".$self->{'address'}."', msg_security='".$self->{'security'}."', autofwd='".$autoforw{$self->{'security'}}."'");

    # verify recipient has a valid e-mail address registered
    unless ($self->{'address'} =~ m/\@/) {
	$self->set_smtp_status;
	return 0;
    }

    # check recipient's auto-forward settings
    if ($autoforw{$self->{'security'}} eq 'message') {
	my $msg = $self->to_mime($self->{'address'});
	$self->warn("->send_by_e_mail: sending full message to <".$self->{'address'}.">:");
	eval {
	    $msg->send_by_smtp(SMTP_SERVER, Hello => SMTP_HELLO,
			       Timeout => SMTP_TIMEOUT, Debug => SMTP_DEBUG);
	};
	if ($@) {
	    $self->log_error("->send_by_e_mail: $@");
	    return 0;
	}
	return $self->set_smtp_status('sent');

    } elsif ($autoforw{$self->{'security'}} eq 'notify') {
	my $msg = $self->mime_notify($self->{'address'});
	$self->warn("->send_by_e_mail: sending notify message to <".$self->{'address'}.">:");
	eval {
	    $msg->send_by_smtp(SMTP_SERVER, Hello => SMTP_HELLO,
			       Timeout => SMTP_TIMEOUT, Debug => SMTP_DEBUG);
	};
	if ($@) {
	    $self->log_error("->send_by_e_mail: $@");
	    return 0;
	}
	return $self->set_smtp_status('sent');
    }

    $self->set_smtp_status;
    return 0;
}

sub datestamp {
    my ($self) = @_;

    # read message's timestamp and convert to MIME Date: header format
    my ($y, $m, $d, $hr, $min, $sec) =
      ( $self->{'time'} =~ m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ );
    my ($u_wdy, $u_mon, $u_mdy, $u_time, $u_y4) =
      split(/\s+/, gmtime(mktime($sec, $min, $hr, $d, $m-1, $y-1900)));
    return "$u_wdy, $u_mdy $u_mon $u_y4 $u_time UT";
}

sub mime_notify {
    my ($self, @to) = @_;

    return MIME::Lite->new
      (From    => 'postmaster@'.SMTP_HELLO,
       To      => join(', ', @to),
       Subject => MIME_NOTIFY_HDR,
       Date    => $self->datestamp,

       Data    => MIME_NOTIFY_MSG . MIME_FOOTER,
       Type    => "text/plain",
      );
}

sub to_mime {
    my ($self, @to) = @_;

    my $msg = MIME::Lite->new
      (From    => $self->{'sender'}.'@'.SMTP_HELLO,
       To      => join(', ', @to),
       Subject => $self->{'subject'},
       Date    => $self->datestamp,

       Data    => $self->{'body'} . MIME_FOOTER,
       Type    => "text/plain",
      );

    if (ref $self->{'Attachments'} eq "ARRAY") {
	foreach my $a (@{$self->{'Attachments'}}) {
	    $msg->attach
	      (Path     => (Apache::App::Mercury::Config::ATTACHMENT_FILESYS_BASE() .
			    $a->{'Filename'}),
	       Filename => $a->{'Name'},
	       Type     => $self->autotype_by_ext($a->{'Filename'}),
	      );
	}
    }

    return $msg;
}

sub autotype_by_ext {
    my ($self, $filesys) = @_;

    if ($filesys =~ m/\.gif$/i) {
	return "image/gif";
    } elsif ($filesys =~ m/\.(?:jpg|jpeg)$/i) {
	return "image/jpeg";
    } elsif ($filesys =~ m/\.(?:html|htm)$/i) {
	return "text/html";
    } elsif ($filesys =~ m/\.xml$/i) {
	return "text/xml";
    } else {
	return "text/plain";
    }
}


1;
