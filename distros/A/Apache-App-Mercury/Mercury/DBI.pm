package Apache::App::Mercury::DBI;

require 5.004;
use strict;

use DBI;
use Apache::App::Mercury::Config;

# message table methods

sub dbi_count_unread {
    my ($self, $user) = @_;
    my $unread;

    if (!$user) {
	$self->log_error("->count_unread: must specify user name!");
	return undef;
    }
    eval {
	my $dbh = DBI->connect
	  (Apache::App::Mercury::Config::DBI_CONNECT_STR,
	   Apache::App::Mercury::Config::DBI_LOGIN,
	   Apache::App::Mercury::Config::DBI_PASS,
	   {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	  ("SELECT count(*) FROM ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." WHERE recipient=? AND status=? AND recipient!=sender");
	$sth->execute($user, 'unread');
	$sth->bind_col(1, \$unread);
	$sth->fetchrow_arrayref;
	$sth->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return undef;
    }
    return $unread;
}

sub change_status {
    my ($self, $sent, $new_status, $all_in_this_box, @ids) = @_;
    my $status_col = ($sent ? "status_sender" : "status");

    $new_status = 'read' 
	if !grep($new_status, ('unread','read','replied','forwarded','deleted'));

    if (!($all_in_this_box or @ids)) {
	$self->log_error("->change_status: must specify msg id or box to act on!");
	return 0;
    } elsif (!grep($new_status, ('unread','read','replied','forwarded','deleted'))) {
	$self->log_error("->change_status: new_status must be one of 'unread','read','replied','forwarded','deleted' - not $new_status");
	return 0;
    }

    my ($where_clause, @bind_params);
    if ($all_in_this_box) {
	$where_clause = "WHERE box=?";
	push(@bind_params, $all_in_this_box);
    } else {
	my $placeholders = join(", ", map {'?'} @ids);
	$where_clause = "WHERE id IN($placeholders)";
	@bind_params = @ids;
    }
    eval {
	my $dbh = DBI->connect
	  (Apache::App::Mercury::Config::DBI_CONNECT_STR,
	   Apache::App::Mercury::Config::DBI_LOGIN,
	   Apache::App::Mercury::Config::DBI_PASS,
	   {'RaiseError' => 1});
	# mark message(s) as $new_status
	my $sth = $dbh->prepare_cached
	  ("UPDATE ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." SET $status_col=?,timestamp=timestamp $where_clause");
	$sth->execute($new_status, @bind_params);
	$sth->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return 0;
    }

    $self->warn("->change_status: set ".(@ids ? join(', ', @ids) : "all in $all_in_this_box")." to $new_status");

    return ($#ids + 1);
}

sub change_box {
    my ($self, $to_box, $all_in_this_box, @ids) = @_;

    if (!$to_box and !(@ids and $all_in_this_box)) {
	$self->log_error("->change_box: must specify new mailbox and msg id or box to move all from!");
	return 0;
    }

    my ($where_clause, @bind_params);
    if ($all_in_this_box) {
	$where_clause = "WHERE box=?";
	push(@bind_params, $all_in_this_box);
    } else {
	my $placeholders = join(", ", map {'?'} @ids);
	$where_clause = "WHERE id IN($placeholders)";
	@bind_params = @ids;
    }

    eval {
	my $dbh = DBI->connect
	  (Apache::App::Mercury::Config::DBI_CONNECT_STR,
	   Apache::App::Mercury::Config::DBI_LOGIN,
	   Apache::App::Mercury::Config::DBI_PASS,
	   {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	    ("UPDATE ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." SET box=?,timestamp=timestamp $where_clause");
	$sth->execute($to_box, @bind_params);
	$sth->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return 0;
    }

    $self->warn("->change_box: moved ".(@ids ? join(', ', @ids) : "all in $all_in_this_box")." to $to_box");

    return ($#ids + 1);
}

# returns a hash of Message objects
sub get_messages {
    my ($self, $box, $trans_code, $ids, $smtp_status, $no_attachments) = @_;
    my (@index, %msgs);

    my $user = $self->{user_manager}->userprofile('user');

    unless (($box and $user) or $trans_code or ref $ids eq 'ARRAY' or $smtp_status) {
	$self->log_error("->get_messages: must send mailbox name and user, or transaction code, or a ref to an id list, or a status_smtp value!");
	return {};
    }

    my $sorter = (($box and $self->{$box}->{'sortby'} and
		   $self->{$box}->{'sortby'} ne 'time')
		  ? $self->{$box}->{'sortby'} : 'timestamp');

    my $sort_direction = (($box and $self->{$box}->{'sortdir'} and
			   $self->{$box}->{'sortdir'} eq 'up')
			  ? 'ASC' : 'DESC');

    my ($where_clause, @bind_params);

    if ($box) {
	$where_clause = ($box eq 'outbox'
			 ? "WHERE sender=? AND status_sender!='deleted'"
			 : "WHERE recipient=? AND status!='deleted'");
	push(@bind_params, $user);
	if ($box eq 'inbox') {
	    $where_clause .= " AND (box='' OR box='inbox')";
	} elsif ($box ne 'outbox') {
	    $where_clause .= " AND box=?";
	    push(@bind_params, $box);
	}
	$self->{$box}->{'index'} = [];
    } elsif ($smtp_status) {
	$where_clause = "WHERE status_smtp=?";
	push(@bind_params, $smtp_status);
    } else {
	if (ref $ids eq 'ARRAY') {
	    my $placeholders = join(", ", map {'?'} @$ids);
	    $where_clause = "WHERE id IN($placeholders)";
	    @bind_params = @$ids;
	}
	if ($trans_code) {
	    $where_clause .=
		($where_clause ? " AND" : "WHERE")." code=? AND trans=?";
	    push(@bind_params, $trans_code, 'show');
	}
    }

    eval {
	my $dbh = DBI->connect
	  (Apache::App::Mercury::Config::DBI_CONNECT_STR,
	   Apache::App::Mercury::Config::DBI_LOGIN,
	   Apache::App::Mercury::Config::DBI_PASS,
	   {'RaiseError' => 1});
	my $sth = $dbh->prepare_cached
	    ("SELECT id,recipient,sent_to,sender,timestamp,DATE_FORMAT(timestamp, '%a %b %d %r %Y'),subject,body,attachments,status,status_smtp,code,trans,security,box FROM ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." $where_clause ORDER BY $sorter $sort_direction");
	$sth->execute(@bind_params);
	my ($id, $recip, $sent_to, $sender, $timestamp, $time_recvd, $subj,
	    $body, $attach, $status, $smtp_status, $code, $display_trans,
	    $security, $thebox);
	$sth->bind_columns
	  (\ ($id, $recip, $sent_to, $sender, $timestamp, $time_recvd, $subj,
	      $body, $attach, $status, $smtp_status, $code, $display_trans,
	      $security, $thebox) );
	while ($sth->fetchrow_arrayref) {
	    $msgs{$id} = Apache::App::Mercury::Message->new
	      ({ 'id' => $id,
		 'recipient' => $recip,
		 'sent_to' => $sent_to,
		 'sender' => $sender,
		 'time' => $timestamp,
		 'time_formatted' => $time_recvd,
		 'subject' => $subj,
		 'body' => $body,
		 'status' => $status,
		 'status_smtp' => $smtp_status,
		 'transcode' => $code,
		 'display_trans' => $display_trans,
		 'security' => $security,
		 'box' => $thebox });
	    $msgs{$id}->initialize($self);
	    $msgs{$id}->{'security_fixed'} = 1 if $security eq 'high';
	    $msgs{$id}->{'Attachments'} =
	      [ map {
		  Apache::App::Mercury::Message::Attachment->new
		      ({ 'AttachmentID' => $_ })->retrieve;
	      } grep($_ ne '', split(/\s+/, $attach)) ]
		if $attach && !$no_attachments;
	    push(@index, $id);
	}
	$sth->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return {};
    }
    $self->{$box}->{'index'} = \@index if $box;
    return { %msgs };
}


sub check_if_messages {
    my ($self, $code) = @_;
    my $rowref;

    eval {
	my $dbh = DBI->connect
	  (Apache::App::Mercury::Config::DBI_CONNECT_STR,
	   Apache::App::Mercury::Config::DBI_LOGIN,
	   Apache::App::Mercury::Config::DBI_PASS,
	   {'RaiseError' => 1});
	# retrieve message(s) contents
	my $sth = $dbh->prepare_cached
	  ("SELECT id FROM ".Apache::App::Mercury::Config::DBI_SQL_MSG_TABLE()." WHERE code=? AND trans=? LIMIT 1");
	$sth->execute($code, 'show');
	$rowref = $sth->fetchrow_arrayref;
	$sth->finish;
	$dbh->disconnect;
    };
    if ($@) {
	$self->log_error;
	return {};
    }
    return $rowref;
}


1;
