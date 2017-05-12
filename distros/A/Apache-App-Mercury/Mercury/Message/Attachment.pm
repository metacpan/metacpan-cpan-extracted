package Apache::App::Mercury::Message::Attachment;

require 5.004;
use strict;

use base qw(Apache::App::Mercury::Base);
use Apache::App::Mercury::Config;
use Apache::App::Mercury::DBI;

use DBI;

use constant SQL_ATTACHMENT_TABLE =>
  Apache::App::Mercury::Config::DBI_MSG_ATTACHMENT_TABLE;
use constant FILESYS_BASE =>
  Apache::App::Mercury::Config::ATTACHMENT_FILESYS_BASE;


sub store_to_filesystem {
    my ($self) = @_;

    unless ($self->{'Name'} and $self->{'Data'}) {
	$self->log_error("->store_to_filesystem: failed.  object must contain Name and Data");
	return undef;
    }

    # decide on a logical place on the filesystem to put file
    my $date = join('', $self->get_date);

    # set initial filename
    $self->{'Filename'} = $self->{'Name'};

    # if that already exists on fs, prepend N_ for N=1,2,3.. until it doesn't
    while (-e FILESYS_BASE.$date."/".$self->{'Filename'}) {
	if ($self->{'Filename'} =~ m/^\d+_/) {
	    $self->{'Filename'} =~ s/^(\d+)_/sprintf("%03d", $1+1)."_"/e;
	} else {
	    $self->{'Filename'} = "001_" . $self->{'Filename'};
	}
    }

    # make directory
    mkdir(FILESYS_BASE.$date, 0700)
      unless -d FILESYS_BASE.$date;
    $self->{'Filename'} = $date."/".$self->{'Filename'};

    # write data to file
    open(FILE, "> ".FILESYS_BASE.$self->{'Filename'});
    syswrite(FILE, $self->{'Data'});
    close FILE;

    return 1;
}

sub store {
    my ($self) = @_;

    if ($self->stored) {
	$self->log_error("->store: attachment already stored!");
	return 0;
    }
    unless (ref $self->{'MessageIDs'} eq "HASH") {
	$self->log_error("->store: no MessageIDs of messages containing this attachment!");
	return 0;
    }
    unless ($self->store_to_filesystem) {
	$self->log_error("->store: filesystem store failed.");
	return 0;
    }

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("INSERT INTO ".SQL_ATTACHMENT_TABLE." SET filesys=?, attachment=?, msg_ids=?");
	$sth->execute($self->{'Filename'}, $self->{'Name'},
		      join(' ', sort {$a<=>$b} keys %{$self->{'MessageIDs'}}));
	$sth->finish;

	my $sth2 = $dbh->prepare_cached("SELECT LAST_INSERT_ID()");
	$sth2->execute;
	$self->{'AttachmentID'} = '';
	$sth2->bind_columns(\$self->{'AttachmentID'});
	$sth2->fetchrow_arrayref;
	$sth2->finish;

	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return 0;
    }
    return 1;
}

sub stored {
    return exists $_[0]->{'AttachmentID'};
}

sub retrieve {
    my ($self) = @_;

    unless (defined $self->{'AttachmentID'} or defined $self->{'Filename'}) {
	$self->log_error("->retrieve: an AttachmentID or Filename is required for retrieval");
	return undef;
    }

    my ($where_clause, @bind_params);
    if (defined $self->{'AttachmentID'}) {
	$where_clause = 'aid=?';
	push(@bind_params, $self->{'AttachmentID'});
    } else {
	$where_clause = 'filesys=?';
	push(@bind_params, $self->{'Filename'});
    }

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth2 = $dbh->prepare_cached
	  ("SELECT aid,filesys,attachment,msg_ids FROM ".SQL_ATTACHMENT_TABLE." WHERE $where_clause");
	$sth2->execute(@bind_params);

	$self->{'AttachmentID'} = '';
	$self->{'Name'} = '';
	$self->{'Filename'} = '';
	my $msg_ids;
	$sth2->bind_columns(\ ($self->{'AttachmentID'}, $self->{'Filename'},
			       $self->{'Name'}, $msg_ids) );
	$sth2->fetchrow_arrayref;
	$self->{'MessageIDs'} = { map { $_ => 1 } split(/\s+/, $msg_ids) };

	$sth2->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error($@);
	return undef;
    }
    return $self;
}

sub update_messages_containing {
    my ($self) = @_;

    unless (defined $self->{'AttachmentID'} and
	    ref $self->{'MessageIDs'} eq "HASH") {
	$self->log_error("->update_messages_containing: an AttachmentID or Filename is required for retrieval");
	return undef;
    }

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("UPDATE ".SQL_ATTACHMENT_TABLE." SET msg_ids=? WHERE aid=?");
	$sth->execute(join(' ', sort {$a<=>$b} keys %{$self->{'MessageIDs'}}),
		      $self->{'AttachmentID'});
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return undef;
    }
    return 1;
}


1;
