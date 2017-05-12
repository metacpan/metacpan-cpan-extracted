package Apache::App::Mercury;

require 5.004;
use strict;
use vars qw($VERSION);
$Apache::App::Mercury::VERSION = '0.80';

use Apache::App::Mercury::Base;
use Apache::App::Mercury::DBI;
use base qw(Apache::App::Mercury::Base  Apache::App::Mercury::DBI);
use Apache::App::Mercury::Message;
use Apache::App::Mercury::Config;
use base Apache::App::Mercury::Config::DISPLAY_CLASS();
BEGIN {
    my $umgrclass = Apache::App::Mercury::Config::USER_MANAGER_CLASS();
    $umgrclass =~ s,::,/,g;
    $umgrclass .= '.pm';
    require $umgrclass;

    if (Apache::App::Mercury::Config::CONTROLLER_CLASS()) {
	my $ctrlrclass = Apache::App::Mercury::Config::CONTROLLER_CLASS();
	$ctrlrclass =~ s,::,/,g;
	$ctrlrclass .= '.pm';
	require $ctrlrclass;
    }
};

use Storable qw(dclone);


sub initialize {
    my ($self, $controller) = @_;
    $self->{r} = $controller->{r};
    $self->{q} = $controller->{q};
    $self->{controller} = $controller;
    $self->{user_manager} =
      Apache::App::Mercury::Config::USER_MANAGER_CLASS()->new;
    $self->{user_manager}->initialize($self)
      if $self->{user_manager}->can('initialize');

    $self->{'last_mail_check'} = 0 unless defined $self->{'last_mail_check'};
}

sub cleanup {
    my ($self) = @_;

    $self->{user_manager}->cleanup if $self->{user_manager}->can('cleanup');
    foreach (qw(q r user_manager controller)) {
	delete $self->{$_};
    }
}

# accessors
sub controller { $_[0]->{controller}; }
sub user_manager { $_[0]->{user_manager}; }

###############################################################################
# mod_perl handler
###############################################################################

sub handler {
    my $ctrlr = Apache::App::Mercury::Config::CONTROLLER_CLASS()->new;
    $ctrlr->handler(@_);
}

###############################################################################
# content handler
###############################################################################

sub content_handler {
    my ($self) = @_;
    my $q = $self->{q};
    my $controller = $self->{controller};
    my %args = $self->{r}->args;

    # set up and preparation - independent of page

    $self->get_mailboxes;

    my $box = $self->{'current_box'} = $self->get_current_mailbox;

    my $need_sort;
    if ($args{$box.'_sortby'} and
	$args{$box.'_sortby'} ne ($self->{$box}->{'sortby'} .
				  ($self->{$box}->{'sortdir'}
				   ? '__'.$self->{$box}->{'sortdir'} : ''))) {
	my ($sort, $updown) = split('__', $args{$box.'_sortby'});
	$need_sort = $self->set_sortby(undef, $sort, $updown);
    } elsif (!$self->{$box}->{'sortby'}) {
	$need_sort = $self->set_sortby;
    }

    # hit database if user wants or if more than 10 minutes has past since last
    if ($q->param('check_mail') or !$self->{'last_mail_check'} or
	$controller->get_time > $self->{'last_mail_check'}+600) {
	$self->check_mail;
	$need_sort = 0; # since mail checking automtically sorts
    }

    # cannot sort until boxes are made (by checkmail)
    # but only sort if sortby was changed and mail was not checked
    $self->sort_mailbox if $need_sort;

    # actions, non-displaying

    if ($q->param('delete')) {
	$self->delete_messages;
    } elsif ($q->param('transfer')) {
	$self->transfer_messages;
    }

    # change state if we're now trying to view messages in an empty mailbox
    $self->{'state'} = 'message_center'
      if ($self->{'state'} eq 'view_messages' and
	  $#{$self->{$box}->{'index'}} < 0);

    # outputting and page creation

    if ($q->param('cancel')) {
	$self->cancel_operation;

	$self->{'state'} = 'message_center';
	$self->show_mail_center;
	$controller->sitemark('/messaging');

    } elsif ($q->param('message_center')) {

	$self->{'state'} = 'message_center';
	$self->show_mail_center;
	$controller->sitemark('/messaging');

    } elsif ($self->{'state'} eq 'edit_settings' or $args{'edit_mail_prefs'}) {

	if ($q->param('add_box')) {
	    if ($self->verify_new_mailbox($q->param('new_box'))) {
		$self->add_new_mailbox($q->param('new_box'));
		$self->checkmail;
		$q->delete('new_box');
	    }
	} elsif ($q->param('delete_box')) {
	    $self->delete_mailbox($q->param('custom_box'),
				  $q->param('delete_mail_in_box'));
	    $self->checkmail;
	    $q->delete('custom_box');
	    $q->delete('delete_mail_in_box');
	} elsif ($q->param('commit_filter')) {
	    $self->edit_filters;
	    $self->checkmail;
#	    $q->delete('trans_filter');
	} elsif ($q->param('update_auto_forward')) {
	    $self->update_auto_forward;
	    $self->checkmail;
	}
	$self->{'state'} = 'edit_settings';
	$self->show_mail_settings;
	$controller->sitemark('/messaging.settings');

    } elsif ($self->{'state'} eq 'compose_message') {

	$self->save_compose_message_fields;
	$controller->sitemark('/messaging.compose');

	$controller->infomsg("You must take action on your existing composition before creating a transaction-related message.")
	  if ($q->param('reply_trans') or $q->param('compose_trans'));

	if ($q->param('preview')) {
	    my ($fail, $recip, $recip_desc) =
	      $self->verify_recipient($self->{compose_msg}->{'sent_to'}, 1);
	    unless ($fail) {
		$self->{compose_msg}->{'sent_to'} = $recip;
		$self->{compose_msg}->{'recipient_desc'} = $recip_desc;

		$self->{'state'} = 'preview_message';
		$self->show_mail_preview;
		$controller->sitemark('/messaging.preview');
		return;
	    }
	} elsif ($q->param('return')) {
	    $controller->infomsg("Your composition has been saved in memory.  It will be removed when you log out.");
	    $self->{'state'} = 'message_center';
	    $self->show_mail_center;
	    $controller->sitemark('/messaging');
	    return;
	} elsif ($q->param('reset')) {
	    $self->reset_compose_message;
	} elsif ($q->param('change_recip')) {
	    $self->{compose_msg}->{'action'} .= "-changed_recip";
	} elsif ($q->param('memo')) {
	    $self->{compose_msg}->{'sent_to'} = $self->{user_manager}->userprofile('user');
	    $self->{compose_msg}->{'recipient_desc'} = $self->{user_manager}->userprofile('user_desc');
	} elsif ($q->param('nonmemo')) {
	    $self->{compose_msg}->{'sent_to'} = '';
	    $self->{compose_msg}->{'recipient_desc'} = '';
	} elsif (defined (my $attach_no = $q->param('remove_attach'))) {
	    splice(@{$self->{compose_msg}->{'Attachments'}}, $attach_no, 1);
	}

	$self->show_mail_compose;

    } elsif ($self->{'state'} eq 'preview_message') {

	$self->save_compose_message_fields;
	$controller->sitemark('/messaging.preview');

	$controller->infomsg("You must take action on your existing composition before creating a transaction-related message.")
	  if ($q->param('reply_trans') or $q->param('compose_trans'));

	if ($q->param('send')) {
	    $self->{'state'} = 'message_center';
	    $self->message_send;
	    $self->check_mail;
	    $self->show_mail_center;
	    $controller->sitemark('/messaging');
	} elsif ($q->param('make_changes')) {
	    $self->{'state'} = 'compose_message';
	    $self->show_mail_compose;
	    $controller->sitemark('/messaging.compose');
	} elsif ($q->param('return')) {
	    $controller->infomsg("Your composition has been saved in memory.  It will be removed when you log out.");
	    $self->{'state'} = 'message_center';
	    $self->show_mail_center;
	    $controller->sitemark('/messaging');
	} else {
	    $self->show_mail_preview;
	}

    } elsif ($q->param('compose') or $q->param('compose_trans')) {

	if (ref $self->{compose_msg} ne "Apache::App::Mercury::Message") {
	    $self->reset_compose_message;
	    $self->{compose_msg}->{'transcode'} = $q->param('transcode')
	      if $q->param('compose_trans');
	} elsif ($q->param('compose_trans')) {
	    $controller->infomsg("You must take action on your saved composition before creating a new transaction-related message.");
	}

	$self->{'state'} = 'compose_message';
	$self->show_mail_compose;
	$controller->sitemark('/messaging.compose');

    } elsif ($args{'mailto'}) {

	if (ref $self->{compose_msg} ne "Apache::App::Mercury::Message") {
	    $self->reset_compose_message;
	    my ($fail, $recip, $recip_desc) =
	      $self->verify_recipient($args{'mailto'}, 1);
	    unless ($fail) {
		$self->{compose_msg}->{'action'} = 'mailto';
		$self->{compose_msg}->{'sent_to'} = $recip;
		$self->{compose_msg}->{'recipient_desc'} = $recip_desc;
	    }
	} else {
	    $controller->infomsg("You must take action on your saved composition before creating a new message.");
	}

	$self->{'state'} = 'compose_message';
	$self->show_mail_compose;
	$controller->sitemark('/messaging.compose');

    } elsif ($self->{'state'} eq 'view_messages' or defined $args{'read'} or
	     $q->param('reply_trans') or
	     ($self->{'cur_index'} and ($q->param('read_prev') or
					$q->param('read_next')))) {

	$self->set_current_index($args{'read'});

	$self->{'state'} = 'compose_message';
	$controller->sitemark('/messaging.compose');

	if ($q->param('print')) {
	    $self->{'state'} = 'view_messages';
	    $controller->sitemark('/messaging.print');
	    $self->show_mail_print_message;
	    $self->make_read;
	} elsif ($q->param('reply') or $q->param('reply_trans')) {
	    if (ref $self->{compose_msg} ne "Apache::App::Mercury::Message") {
		$self->reset_compose_message;
		unless ($self->set_compose_reply
			($self->retrieve_message($q->param('msg_id')))) {
		    $self->show_mail_message;
		    return;
		}
	    } else {
		$controller->infomsg("You must take action on your saved composition before creating a new message reply.");
	    }
	    $self->show_mail_compose;
	} elsif ($q->param('forward')) {
	    if (ref $self->{compose_msg} ne "Apache::App::Mercury::Message") {
		$self->reset_compose_message;
		$self->set_compose_forward
		  ($self->retrieve_message($q->param('msg_id')));
	    } else {
		$controller->infomsg("You must take action on your saved composition before creating a new message forward.");
	    }
	    $self->show_mail_compose;
	} elsif ($q->param('re-send')) {
	    if (ref $self->{compose_msg} ne "Apache::App::Mercury::Message") {
		$self->reset_compose_message;
		$self->set_compose_resend
		  ($self->retrieve_message($q->param('msg_id')));
	    } else {
		$controller->infomsg("You must take action on your saved composition before creating a new message re-send.");
	    }
	    $self->show_mail_compose;
	} else {
	    $self->{'state'} = 'view_messages';
	    $controller->sitemark('/messaging.read');
	    $self->show_mail_message;
	    $self->make_read;
	}

    } else {
	$self->{'state'} = 'message_center';
	$self->show_mail_center;
	$controller->sitemark('/messaging');
    }
}


sub get_mailboxes {
    my ($self) = @_;

    $self->{'mailboxes'} =
      [ qw(inbox outbox), $self->{user_manager}->mailboxes ];
}

sub get_current_mailbox {
    my ($self) = @_;
    my $q = $self->{q};
    my %args = $self->{r}->args;

    return $args{'mailbox'} if $args{'mailbox'};
    return $q->param('mailbox') if $q->param('mailbox');
    return $self->{'current_box'} if $self->{'current_box'};
    return $self->{'mailboxes'}->[0];
}

sub check_mail {
    my ($self) = @_;

    $self->{'last_mail_check'} = $self->{controller}->get_time;

    # build Inbox first
    if ($self->makebox('inbox')) {
	$self->makebox('inbox') if $self->filter_messages;
	foreach (@{$self->{'mailboxes'}}) {
	    undef $self->{'last_mail_check'}
	      if ($_ ne 'inbox' and !$self->makebox($_));
	}
    } else {
	undef $self->{'last_mail_check'};
    }
}

# checks the messages in the Inbox and sets the 'box' field if necessary
sub filter_messages {
    my ($self) = @_;

    my %move_msgs;
    # only do anything if there are filters
    # only one filter exists now, add the others, when created
    my $filters = { 'trans' => $self->{user_manager}->mail_trans_filter };
    if ($filters->{'trans'} and $filters->{'trans'} ne 'inbox') {

	my $transact_box = $filters->{'trans'};
	my $msgs = $self->{'inbox'}->{'msgs'};
	foreach my $id (@{$self->{'inbox'}->{'index'}}) {
	    # only filter those messages which have no 'box' field,
	    #  otherwise they must have been moved or filtered previously
	    if (!$msgs->{$id}->{'box'}) {
		# filter as a transaction message if a code exists
		# when there are more filters will need to determine precedence
		if ($msgs->{$id}->{'transcode'}) {
		    push(@{$move_msgs{$transact_box}}, $id);
		} else {
		    # if it's not going anywhere set to 'inbox' so won't
		    #  get filtered later
		    push(@{$move_msgs{'inbox'}}, $id);
		}
	    }
	}
	while (my ($box, $ar) = each %move_msgs) {
	    $self->change_box($box, undef, @$ar);
	}
	
	return 1;
    }
    return 0;
}

sub makebox {
    my ($self, $box) = @_;

    return 1 if ($self->{$box}->{'msgs'} = $self->get_messages($box));
    return 0;
}

sub delete_messages {
    my ($self, $box) = @_;
    my $q = $self->{q};

    $box = $self->{'current_box'} if !$box;

    my $sent = ($box eq 'outbox');

    if ($q->param('msg_id') and ($self->{'state'} eq 'view_messages')) {
	if ($self->change_status($sent, 'deleted', undef, $q->param('msg_id'))) {
	    $self->check_mail;
	    $self->set_current_index;
	}
    } elsif ((my @ids = $q->param('select_msgs')) and
	     ($self->{'state'} eq 'message_center')) {
	if (my $amount = $self->change_status($sent, 'deleted', undef, @ids)) {
	    $self->{controller}->infomsg($amount." message".($amount==1 ? ' has' : 's have')." been deleted.");
	    $self->check_mail;
	}
    }
    $q->delete('delete');
}

sub transfer_messages {
    my ($self) = @_;
    my $q = $self->{q};

    my $to_box = $q->param('to_mailbox');

    if ($q->param('msg_id') and ($self->{'state'} eq 'view_messages')) {
	if ($self->change_box($to_box, undef, $q->param('msg_id'))) {
	    $self->check_mail;
	    $self->set_current_index;
	}
    } elsif ((my @ids = $q->param('select_msgs')) and 
	     ($self->{'state'} eq 'message_center')) {
	if (my $amount = $self->change_box($to_box, undef, @ids)) {
	    $self->{controller}->infomsg
	      ($amount." message".($amount==1 ? ' has' : 's have') .
	       " been transfered to mailbox ".ucfirst($to_box).".");
	    $self->check_mail;
	}
    }
    $q->delete('transfer');
}

sub set_current_index {
    my ($self, $index) = @_;
    my $q = $self->{q};

    if (defined $index) {
	$self->{'cur_index'} = $index;
    } elsif ($q->param('read_prev')) {
	$self->{'cur_index'} -- if $self->{'cur_index'} > 0;
    } elsif ($q->param('read_next')) {
	$self->{'cur_index'} ++ if $self->{'cur_index'} < $#{$self->{$self->{'current_box'}}->{'index'}};
    } elsif (!defined $self->{'cur_index'}) {
	$self->{'cur_index'} = 0;
    }

    # if cur_index is greater than size of index array, fix
    $self->{'cur_index'} = $#{$self->{$self->{'current_box'}}->{'index'}} if
      $self->{'cur_index'} > $#{$self->{$self->{'current_box'}}->{'index'}};
}

sub get_sortby {
    my ($self, $box) = @_;
    $box = $self->{'current_box'} if !$box;

    return ($self->{$box}->{'sortby'}, $self->{$box}->{'sortdir'});
}

sub set_sortby {
    my ($self, $box, $sortby, $sortdir) = @_;
    $box = $self->{'current_box'} if !$box;

    $self->{$box}->{'sortby'} = ($sortby ? $sortby : 'time');
    $self->{$box}->{'sortdir'} = ($sortdir && $sortdir eq 'up' ? 'up' :'down');

    return 1;
}

sub sort_mailbox {
    my ($self, $box) = @_;
    my $q = $self->{q};

    $box = $self->{'current_box'} if !$box;

    my $sortby = $self->{$box}->{'sortby'};
    my $sortdir = $self->{$box}->{'sortdir'};
    my $index = $self->{$box}->{'index'};

    if ($sortdir eq 'down') { # sort descendingly
	$index = [ sort { uc($self->{$box}->{'msgs'}->{$b}->{$sortby}) cmp uc($self->{$box}->{'msgs'}->{$a}->{$sortby}) } @$index ];
    } else { # sort ascendingly
	$index = [ sort { uc($self->{$box}->{'msgs'}->{$a}->{$sortby}) cmp uc($self->{$box}->{'msgs'}->{$b}->{$sortby}) } @$index ];
    }
    $self->{$box}->{'index'} = $index;
}

sub make_read {
    my ($self) = @_;
    my $q = $self->{q};

    my $box = $self->{'current_box'};
    my $msg = $self->{$box}->{'index'}->[$self->{'cur_index'}];

    if ($box ne 'outbox' and
	$self->{$box}->{'msgs'}->{$msg}->{'status'} eq 'unread') {
	if ($self->change_status(undef, 'read', undef, $msg)) {
	    $self->check_mail;
	}
    }
}

sub retrieve_message {
    my ($self, $id) = @_;
    my $msgs = $self->{$self->{'current_box'}}->{'msgs'};

    return undef unless defined $id;

    # retrieve it from memory if its easily accessible
    return $msgs->{$id} if ref $msgs->{$id} eq "Apache::App::Mercury::Message";

    # otherwise get out of table (for transactions)
    return $self->get_messages(undef, undef, [ $id ])->{$id};
}

sub save_compose_message_fields {
    my ($self) = @_;
    my $q = $self->{q};

    $self->{compose_msg}->{'sent_to'} = $q->param('recipient')
      if defined $q->param('recipient');
    $self->{compose_msg}->{'subject'} = $q->param('subject')
      if defined $q->param('subject');
    $self->{compose_msg}->{'body'} = $q->param('body')
      if defined $q->param('body');
    $self->{compose_msg}->{'num_to_attach'} =
      $q->param('num_files_to_attach')
	if defined $q->param('num_files_to_attach');
    $self->{compose_msg}->{'security'} = $q->param('security')
      if defined $q->param('security');
}

sub reset_compose_message {
    my ($self) = @_;
    my $q = $self->{q};
    $self->{compose_msg} = Apache::App::Mercury::Message->new
      ({ 'sender' => $self->{user_manager}->userprofile('user') });
    $self->{compose_msg}->initialize($self);

    $self->{compose_msg}->{'action'} = 'new';
    $self->{compose_msg}->{'subject'} = '';
    $self->{compose_msg}->{'sent_to'} = '';
    $self->{compose_msg}->{'recipient_desc'} = '';
    $self->{compose_msg}->{'transcode'} = '';
    $self->{compose_msg}->{'body'} = '';
    delete $self->{compose_msg}->{'Attachments'};
}

sub set_compose_reply {
    my ($self, $origmsg) = @_;
    my $new = $self->{compose_msg};

    my ($fail, $recip, $recip_desc) =
      $self->verify_recipient($origmsg->{'sender'}, 1);
    return 0 if $fail;

    $new->{'action'} = 'reply';
    $new->{'subject'} = "Re: ".$origmsg->{'subject'};
    $new->{'sent_to'} = $recip;
    $new->{'recipient_desc'} = $recip_desc;
    $new->{'transcode'} = $origmsg->{'transcode'};
    $new->{'body'} = $origmsg->{'sender'}." wrote:\n\n".$origmsg->{'body'};
    $new->{'body'} =~ s/^/> /gm;
    $new->{'body'} = "\n\n\n".$new->{'body'};
    $new->{'security'} = $origmsg->{'security'};
    $new->{'security_fixed'} = 1 if $origmsg->{'security_fixed'};
    $new->{'Attachments'} = dclone $origmsg->{'Attachments'}
      if ref $origmsg->{'Attachments'} eq "ARRAY";

    return 1;
}

sub set_compose_forward {
    my ($self, $origmsg) = @_;
    my $new = $self->{compose_msg};

    $new->{'action'} = 'forward';
    $new->{'subject'} = "Fwd: ".$origmsg->{'subject'};
    $new->{'sent_to'} = '';
    $new->{'recipient_desc'} = '';
    $new->{'transcode'} = $origmsg->{'transcode'};
    $new->{'body'} = $origmsg->{'sender'}." wrote:\n\n".$origmsg->{'body'};
    $new->{'body'} =~ s/^/> /gm;
    $new->{'body'} = "\n\n\n".$new->{'body'};
    $new->{'security'} = $origmsg->{'security'};
    $new->{'security_fixed'} = 1 if $origmsg->{'security_fixed'};
    $new->{'Attachments'} = dclone $origmsg->{'Attachments'}
      if ref $origmsg->{'Attachments'} eq "ARRAY";
}

sub set_compose_resend {
    my ($self, $origmsg) = @_;
    my $new = $self->{compose_msg};

    $new->{'action'} = 're-send';
    $new->{'subject'} = "Rs: ".$origmsg->{'subject'};
    $new->{'sent_to'} = '';
    $new->{'recipient_desc'} = '';
    $new->{'transcode'} = $origmsg->{'transcode'};
    $new->{'body'} = $origmsg->{'body'};
    $new->{'security'} = $origmsg->{'security'};
    $new->{'security_fixed'} = 1 if $origmsg->{'security_fixed'};
    $new->{'Attachments'} = dclone $origmsg->{'Attachments'}
      if ref $origmsg->{'Attachments'} eq "ARRAY";
}


sub verify_recipient {
    my ($self, $recip, $show_fail_message) = @_;
    my $q = $self->{q};
    my $controller = $self->{controller};

    # remove all whitespace (user_names can't have any)
    $recip =~ s/\s//g;

    $self->warn("->verify_recipient: checking '$recip'.");
    if (!$recip) {
	$controller->infomsg("You must enter a recipient.") if $show_fail_message;
	return ('fail', undef, undef);
    } elsif ($recip eq $self->{user_manager}->userprofile('user')) {
	return (0, $self->{user_manager}->userprofile('user'),
		"(".$self->{user_manager}->userprofile('user_desc').")");
    } else {
	my @recps = split(';', $recip);
	my @chk_recip = $self->{user_manager}->get_userinfo(@recps);
	my ($usrs, $descript);
	unless (@chk_recip) {
	    $controller->infomsg("Unknown user id: " . $recip)
	      if $show_fail_message;
	    return ('fail', undef, undef);
	}
	my $dispclass = Apache::App::Mercury::Config::DISPLAY_CLASS();
	foreach (@chk_recip) {
	    $usrs .= ($usrs ? ';' : '') . $_->{'user'};
	    $descript .=
	      (($descript ? '; ' : '') .
	       ($dispclass->can("USER_INFO_HREF")
		? $dispclass->USER_INFO_HREF($_->{'user'}, $q)
		: '') .
	       " (" . $_->{'fname'}." ".$_->{'lname'} . ")");
	}
	$controller->infomsg("Not all user ids were valid.  You may wish to ".$q->em("make changes")." and try again.")
	  if ($show_fail_message and $#recps != $#chk_recip);
	return (0, $usrs, $descript);
    }
}

sub cancel_operation {
    my ($self) = @_;
    my $q = $self->{q};

    $self->{controller}->infomsg("The previous operation has been cancelled.");

    # delete appropriate data and params
    $q->delete('cancel');
    delete $self->{compose_msg};
}

sub message_send {
    my ($self) = @_;
    my $q = $self->{q};
    my $compose = $self->{compose_msg};

    my $is_memo = ($compose->{'sender'} eq $compose->{'sent_to'});

    # add to msg object new attachments from CGI POST data that browser sent
    $compose->read_attachments_from_cgi;

    # tell message object to store itself
    if ($compose->store) {
	$self->{controller}->infomsg(!$is_memo ? "Your message has been sent." : "Your memo has been committed.");
	delete $self->{compose_msg};
    } else {
	$self->{controller}->infomsg("There was an error ".(!$is_memo ? "sending your message" : "committing your memo").".  Please contact technical support.");
    }
}

sub verify_new_mailbox {
    my ($self, $new_box) = @_;
    my $controller = $self->{controller};

    # make sure there is a new_box
    if (!$new_box) {
	$controller->infomsg("You did not enter a name for your new mailbox!");
	return 0;
    }
    # make sure there are no commas
    if (($new_box) =~ (m/,/)) {
	$controller->infomsg("Sorry, your mailbox names cannot contain commas (,).  Please try again.");
	return 0;
    }
    # make sure this mailbox name doesn't already exist
    foreach (@{$self->{'mailboxes'}}) {
	if (ucfirst($_) eq ucfirst($new_box)) {
	    $controller->infomsg("You already have a mailbox with the name ".ucfirst($new_box).".  Please pick a different name.");
	    return 0;
	}
    }
    return 1;
}

sub add_new_mailbox {
    my ($self, $new_box) = @_;
    my $controller = $self->{controller};
    my $user = $self->{user_manager}->userprofile('user');

    my @old_boxes = $self->{user_manager}->mailboxes;

    if ($#old_boxes == 14) {
	$controller->infomsg("You already have 15 custom mailboxes, which is the maximum currently allowed.");
	return;
    }

    push(@old_boxes, $new_box);

    if ($self->{user_manager}->mailboxes($user, @old_boxes)) {
	$controller->infomsg("Mailbox ".ucfirst($new_box)." has been created.");
    }
}

sub delete_mailbox {
    my ($self, $old_box, $delete_mail_in_box) = @_;
    my $controller = $self->{controller};
    my $user = $self->{user_manager}->userprofile('user');

    my $num_displaced = $#{$self->{$old_box}->{'index'}} + 1;

    # get rid of filters, if necessary
    $self->remove_filters_for($old_box);

    # then move out the mail
    if ($delete_mail_in_box) {
	$self->change_status(undef, 'deleted', $old_box);
    } else {
	$self->change_box('inbox', $old_box);
    }

    my @boxes = $self->{user_manager}->mailboxes;
    @boxes = grep($_ ne $old_box, @boxes);

    if ($self->{user_manager}->mailboxes($user, @boxes)) {
	delete $self->{$old_box};

	# if mail has been transfered to inbox, rebuild it
	#  - doesn't seem to work otherwise . . .
	if (!$delete_mail_in_box) {
	    my ($sortby, $sortdir) = $self->get_sortby('inbox');
	    delete $self->{'inbox'};
	    $self->set_sortby('inbox', $sortby, $sortdir);
	    $self->makebox('inbox');
	}
	$self->{'current_box'} = 'inbox' if $self->{'current_box'} eq $old_box;

	$controller->infomsg(ucfirst($old_box)." has been deleted".($delete_mail_in_box ? " along with the $num_displaced messages stored there." : ".  The $num_displaced messages stored there have been moved to your Inbox."));
    }
}

sub edit_filters {
    my ($self) = @_;
    my $q = $self->{q};

    if ($q->param('trans_filter') and
	$q->param('trans_filter') ne $self->{user_manager}->mail_trans_filter) {
	$self->{user_manager}->mail_trans_filter($q->param('trans_filter'));
    }
}

sub remove_filters_for {
    my ($self, $old_box) = @_;

    # this is the only filter, add filter checks as filters are created
    if ($self->{user_manager}->mail_trans_filter eq $old_box) {
	# set transaction filter back to 'inbox'
	unless ($self->{user_manager}->mail_trans_filter('inbox')) {
	    $self->warn("->remove_filters_for($old_box) FAILED!");
	}
    }
}

sub update_auto_forward {
    my ($self) = @_;
    my $q = $self->{q};

    $self->{user_manager}->auto_forward('low', $q->param('forward_low'));
    $self->{user_manager}->auto_forward('medium', $q->param('forward_medium'));
    $self->{user_manager}->auto_forward('high', $q->param('forward_high'));
}


sub count_unread {
    my ($self, $user, $this_box, $force_db) = @_;
    my $no_need_db;

    if (!$force_db and $self->{'mailboxes'}) {
	my $cnt = 0;
	my $this_cnt = 0;
	foreach my $box (@{$self->{'mailboxes'}}) {
	    if ($box ne 'outbox' and
		ref $self->{$box}->{'msgs'} eq 'HASH' and
		ref $self->{$box}->{'index'} eq 'ARRAY') {
		$no_need_db = 1;
		foreach (@{$self->{$box}->{'index'}}) {
		    my $msg = $self->{$box}->{'msgs'}->{$_};
		    $cnt++ if ($msg->{'status'} eq 'unread' and
			       $msg->{'recipient'} ne $msg->{'sender'});
		    $this_cnt++ if ($box eq $this_box and
				    $msg->{'status'} eq 'unread' and
				    $msg->{'recipient'} ne $msg->{'sender'});
		}
	    }
	}
	if ($no_need_db) {
	    if ($this_box) {
		return ($cnt, $this_cnt);
	    } else {
		return $cnt;
	    }
	}
    }

    # only use database if forced or if there's no legitimate mailboxes
    if ($force_db or !$no_need_db) {
	$user = $self->{user_manager}->userprofile('user') if !$user;
	return $self->dbi_count_unread($user);
    }
}


1;

__END__

=head1 NAME

Apache::App::Mercury - Internal web messaging for Apache mod_perl (1.x)

=head1 SYNOPSIS

  # first, edit Apache/App/Mercury/Config.pm and set variables appropriately

  # from the mod_perl handler of your application
  #  Note: in these examples My::MVC::Controller is assumed to be a class
  #    which provides a persistence framework so object variables are kept
  #    across http requests; it also must implement some predefined methods
  #    (see below for details on these methods)
  $controller = My::MVC::Controller->new;
  $controller->handler;
  ...

  # My::MVC::Controller top-level control method (e.g. handler())
  sub handler {
    my $self = my $controller = shift;
    ...
    if ($r->uri eq Apache::App::Mercury::Config::BASE_URI()) {
      $controller->{wm} = Apache::App::Mercury->new
      $controller->{wm}->initialize($controller);
      $controller->{wm}->content_handler;
      $controller->{wm}->cleanup;
    }
    ...
    # $r is an Apache->request object
    $r->content_type("text/html");
    $r->send_http_header;
    $r->print("<HTML><HEAD><TITLE>".$controller->pagetitle."</TITLE></HEAD>".
              "<BODY>".$controller->pagebody."</BODY></HTML>");
  }

  ### === --<>-- === ###

  # to generate a message from 'sender_user' to 'recipient_user' with a
  # security-level setting of 'low' (security => 'low'), and without
  # storing a copy of the message in the sender's Outbox (nocopy => 1)
  Apache::App::Mercury::Message->new
    ({ 'sent_to' => 'recipient_user', 'sender' => 'sender_user',
       'subject' => "Subject line ...", 'nocopy' => 1, 'security' => 'low',
       'body' => "Message body\nline 2\nline 3\n...\n" })
    ->store;

=head1 MYTHOLOGY

Mercury the swift messenger of the ancient gods.

The Greek god Hermes (the Roman Mercury) was the god of translators and
interpreters. He was the most clever of the Olympian gods, and served as
messenger for all the other gods. He ruled over wealth, good fortune, commerce,
fertility, and thievery.

Among his personal favorite commercial activities was the corn trade. He was
also the god of manual arts and eloquence. As the deity of athletes, he
protected gymnasiums and stadiums.

=head1 DESCRIPTION

Apache::App::Mercury is a customizable, extensible customer to customer,
store and forward messaging application for Apache mod_perl (1.x).
It might be useful if you have a web application with many users who
login periodically, and you want to give each of them a "message box"
in which they can receive auto-generated messages, or communicate with
each other.  It uses a relational database (accessed via DBI) to store
and retrieve messages, and CGI.pm to display them in standard HTML.
It closely resembles an MVC design pattern, and it handles all message
box navigation, message composition, sending, replying, etc.

=head1 INTERACTIONS WITH OTHER CLASSES

=head2 Controller class

Apache::App::Mercury expects to be instantiated by a Controller class
which provides object persistence features (e.g. with Apache::Session).
To do its job, it also expects to have its initialize($ctlr_obj),
content_handler(), and cleanup() methods called (in that order).

Apache::App::Mercury keeps a reference to the calling Controller object,
(saved by the initialize($ctlr_obj) method call), and expects the Controller
object to implement a few predefined accessors.  They are:

=over 4

=item * infomsg()

=item * pagetitle()

=item * pagebody()

=item * get_time()

=item * sitemark()

=back

For explanations of what these accessors should access, see the
Apache::App::Mercury::Controller manpage.

The Controller object is also expected to hold the following instance
variables: (And yes, I know this is bad OO-programming practice to not
use an accessor, but oh well...)

=over 4

=item $controller->{q}

A CGI query object for the current http request.

=item $controller->{r}

An Apache->request object for the current http request.

=back

Aside from the names and functions of the above five accessors and two
instance variables, the controller class has no other restraints.
You will likely want to simply add these accessors and variables to an
existing class in your application.

Provided in this distribution is the Apache::App::Mercury::Controller
class, which is an example (almost usable) Controller class which
illustrates how your Controller should interact with Apache::App::Mercury.

=head2 Display class

Provided with this distribution is the Apache::App::Mercury::Display class,
which implements all view-specific methods for the Apache::App::Mercury
application.  If you want to change or extend the look, then you can subclass
Apache::App::Mercury::Display and add or override its methods.

=head2 UserManager class

Apache::App::Mercury needs some way to get information about the user
accounts in your application.  It does this through a user manager
class (which would be part of the data model in an MVC design).
Your user manager class should implement the following methods:

=over 4

=item * userprofile()

=item * get_userinfo()

=item * mailboxes()

=item * mail_trans_filter()

=item * auto_forward()

=back

For explanations of what these methods should do, see the
Apache::App::Mercury::UserManager manpage.

=head1 DATABASE SETUP

Currently, Apache::App::Mercury only supports MySQL for its message backing
store.  Adding support for other databases should be fairly straightforward -
I invite anyone to take the initiative of doing it.

You need to create a MySQL database, set the variable
Apache::App::Mercury::Config::DBI_CONNECT_STR, and create the following two
tables in the database you just created:

 CREATE TABLE messages (
  id          int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  recipient   varchar(16) DEFAULT '' NOT NULL,
  sent_to     varchar(255) DEFAULT '' NOT NULL,
  sender      varchar(16) DEFAULT '' NOT NULL,
  timestamp   timestamp(14),
  subject     varchar(100),
  body        text,
  attachments text NOT NULL,
  status      enum('unread','read','replied','forwarded','deleted') DEFAULT 'unread',
  status_sender enum('unread','read','replied','forwarded','deleted') DEFAULT 'unread',
  status_smtp enum('unsent','sent','checked') DEFAULT 'unsent' NOT NULL,
  code        varchar(15) DEFAULT '' NOT NULL,
  box         varchar(16) DEFAULT '' NOT NULL,
  trans       enum('hide','show') DEFAULT 'hide' NOT NULL,
  security    enum('low','medium','high') DEFAULT 'medium',
  PRIMARY KEY (id),
  KEY         recipient (recipient),
  KEY         timestamp (timestamp),
  KEY         sender (sender),
  KEY         code (code),
  KEY         box (box),
  KEY         sent_to (sent_to(34)),
  KEY         trans (trans),
  KEY         status_smtp (status_smtp)
 );

 CREATE TABLE message_attachments (
  aid         int(10) unsigned DEFAULT '0' NOT NULL auto_increment,
  filesys     char(255) DEFAULT '' NOT NULL,
  attachment  char(255) DEFAULT '' NOT NULL,
  msg_ids     char(255) DEFAULT '' NOT NULL,
  PRIMARY KEY (aid),
  UNIQUE      filesys (filesys)
 );

=head1 ACCESSORS

=over 4

=item controller()

Returns the Controller object which was originally set by the
initialize($ctrlr_obj) method.

=item user_manager()

Returns the UserManager object which was instantiated in the
initialize() method using Apache::App::Mercury::Config::USER_MANAGER_CLASS.

=back

=head1 METHODS

Not yet documented.

=head1 BUGS

Maybe a few mosquitos, some spiders, a sweat fly, and an ant colony.
In other words, probably many.  In particular, the installation procedure
might need some work.  Feel free to e-mail any problems you
encounter while trying to install/configure for your site.

=head1 AUTHORS

Adi Fairbank <adi@adiraj.org>

Thanks to Tyler Kendall <tyler@pidgeonenglish.com> for help with
implementation of the ancestor version of this software (the concept
on which this software is based).

=head1 COPYRIGHT

Copyright (c) 2003 - Adi Fairbank

This software (Apache::App::Mercury and all related Perl modules under
the Apache::App::Mercury namespace) is copyright Adi Fairbank.

=head1 COPYLEFT (LICENSE)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

  a) the GNU General Public License as published by the Free Software
     Foundation; either version 1, or (at your option) any later version,

  or

  b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See either the GNU General Public
License or the Artistic License for more details.

You should have received a copy of the Artistic License with this module,
in the file ARTISTIC; if not, the following URL references a copy of it
(as of June 8, 2003):

  http://www.perl.com/language/misc/Artistic.html

You should have received a copy of the GNU General Public License along
with this program, in the file GPL; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA;
or try the following URL which references a copy of it (as of June 8, 2003):

  http://www.fsf.org/licenses/gpl.html

=head1 LAST MODIFIED

July 19, 2003

=cut
