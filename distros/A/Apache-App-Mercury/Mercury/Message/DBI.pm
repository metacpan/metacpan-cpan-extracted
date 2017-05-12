package Apache::App::Mercury::Message::DBI;

require 5.004;
use strict;

use DBI;
use Apache::App::Mercury::Config;

# database persistence methods

sub store {
    my ($self) = @_;

    my $is_memo = $self->{'sent_to'} eq $self->{'sender'};

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("INSERT INTO ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." SET recipient=?,sent_to=?,sender=?,timestamp=?,subject=?,body=?,status_sender=?,code=?,trans=?,security=?");
	my $sth2 = $dbh->prepare_cached("SELECT LAST_INSERT_ID()");

	my $after_first = 0;

	foreach (split(';', $self->{'sent_to'})) {
	    $sth->execute
	      ($_, $self->{'sent_to'}, $self->{'sender'}, undef,
	       $self->{'subject'}, $self->{'body'},
	       ($is_memo || $self->{'nocopy'} || $after_first
		? 'deleted' : 'unread'),
	       ($self->{'transcode'} ? $self->{'transcode'} : ''),
	       ($self->{'transcode'} && !$after_first
		? ($self->{'display_trans'} ? $self->{'display_trans'} :'show')
		: 'hide'),
	       ($self->{'security'} ? $self->{'security'} : 'medium'));

	    $sth2->execute;
	    my $msgid;
	    $sth2->bind_columns(\$msgid);
	    $sth2->fetchrow_arrayref;
	    $sth2->finish;

	    $self->{'MessageIDs'}->{$msgid} = 1;
	    $after_first = 1;
	}

	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return undef;
    }

    # store all attachments
    if (ref $self->{'Attachments'} eq "ARRAY") {
	foreach my $a (@{$self->{'Attachments'}}) {
	    # make sure each attachment references all msg ids in this store
	    foreach my $mid (keys %{$self->{'MessageIDs'}}) {
		# if this attachment has already been stored but needs updating
		if ($a->stored and !$a->{'MessageIDs'}->{$mid}) {
		    $a->{'MessageIDs'}->{$mid} = 1;
		    $a->{'needs_update'} = 1;
		}
	    }
	    if ($a->{'needs_update'}) {
		# if attachment already exists but needs update, update it
		return undef unless $a->update_messages_containing;
	    } else {
		next if $a->stored;
		# otherwise store the new attachment
		$a->{'MessageIDs'} = $self->{'MessageIDs'};
		return undef unless $a->store;
	    }
	}

	return undef unless $self->log_attachments;
    }

    return 1;
}

sub log_attachments {
    my ($self) = @_;

    my @msgids = keys %{$self->{'MessageIDs'}};
    my $placeholders = join(', ', map {'?'} @msgids);
    my $attachment_ids =
      join(' ', map { $_->{'AttachmentID'} } @{$self->{'Attachments'}});

    eval {
	my $dbh = DBI->connect(Apache::App::Mercury::Config::DBI_CONNECT_STR(),
			       Apache::App::Mercury::Config::DBI_LOGIN(),
			       Apache::App::Mercury::Config::DBI_PASS(),
			       {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("UPDATE ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." SET attachments=?,timestamp=timestamp WHERE id IN($placeholders)");
	$sth->execute($attachment_ids, @msgids);
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return undef;
    }
    return 1;
}


1;
