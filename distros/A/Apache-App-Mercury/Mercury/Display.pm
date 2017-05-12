package Apache::App::Mercury::Display;

require 5.004;
use strict;

use Apache::App::Mercury::Config;
use constant BASE_URI => Apache::App::Mercury::Config::BASE_URI;

##############################################################################
# Display Methods - Application specific
##############################################################################

sub show_mail_center {
    my ($self) = @_;

    $self->{controller}->pagetitle(Apache::App::Mercury::Config::APPLICATION_NAME());
    $self->{controller}->pagebody($self->display_center_in_table);
}

sub show_mail_compose {
    my ($self) = @_;

    $self->{controller}->pagetitle(Apache::App::Mercury::Config::APPLICATION_NAME()." - Compose Message");
    $self->{controller}->pagebody($self->display_compose_with_header);
}

sub show_mail_preview {
    my ($self) = @_;

    $self->{controller}->pagetitle(Apache::App::Mercury::Config::APPLICATION_NAME()." - Preview Message");
    $self->{controller}->pagebody($self->display_preview_with_header);
}

sub show_mail_message {
    my ($self) = @_;

    my $msg =
      $self->{$self->{'current_box'}}->{'index'}->[$self->{'cur_index'}];

    $self->{controller}->pagetitle
      (Apache::App::Mercury::Config::APPLICATION_NAME()." - Subj: ".
       ($self->{$self->{'current_box'}}->{'msgs'}->{$msg}->{'subject'}
	? $self->{$self->{'current_box'}}->{'msgs'}->{$msg}->{'subject'}
	: '(no subject)'));
    $self->{controller}->pagebody($self->display_message_with_header);
}

sub show_mail_print_message {
    my ($self) = @_;

    my $msg =
      $self->{$self->{'current_box'}}->{'index'}->[$self->{'cur_index'}];

    $self->{controller}->set_print_headers;
    $self->{controller}->pagetitle
      (Apache::App::Mercury::Config::APPLICATION_NAME()." - Subj: ".
       ($self->{$self->{'current_box'}}->{'msgs'}->{$msg}->{'subject'}
	? $self->{$self->{'current_box'}}->{'msgs'}->{$msg}->{'subject'}
	: '(no subject)'));
    $self->{controller}->pagebody($self->display_message);
}

sub show_mail_settings {
    my ($self) = @_;

    $self->{controller}->pagetitle(Apache::App::Mercury::Config::APPLICATION_NAME()." - Settings");
    $self->{controller}->pagebody($self->display_mail_settings);
}

############################ Sub Display Methods ############################

sub display_center_in_table {
    my ($self) = @_;
    my $q = $self->{q};

    return
      ($q->div({-align => 'center'}, $q->h2("Message Center")) .
       $q->hr({-width => '80%', -align => 'center'}) .
       $q->startform(-action => BASE_URI) .
       $q->table({-cellspacing => 0, -cellpadding => 2,
		  -border => 3, -width => '100%'},
		 $q->Tr($q->td({-valign => 'top', -width => '90%'},
			       $self->display_msglist) .
			$q->td({-width => 2, -bgcolor => '#999999'}, '&nbsp;').
			$q->td({-align => 'right', -valign => 'top',
				-width => '9%', -bgcolor => '#cccccc'},
			       $self->display_center_overview .
			       $self->display_center_menu))) .
       $q->endform);
}

sub display_center_overview {
    my ($self, $labels) = @_;
    my $q = $self->{q};

    $labels = { map { $_ => ucfirst($_) } @{$self->{'mailboxes'}} }
        if !$labels or ref $labels ne 'HASH';

    my $color = '#ffffff';

    return
      ($q->table
       ({-cellspacing => 1, -border => 2},
	$q->Tr
	([$q->th({-align => 'left', -bgcolor => '#cc6699'},
		 [ $q->font({-size => '-1'}, "Mailbox"),
		   $q->font({-size => '-1'}, "Msgs"),
		   $q->font({-size => '-1'}, "Unread") ]),
	  (map {
	      my $bgcol = $color;
	      $color = ($color eq '#ffffff' ? '#ffccff' : '#ffffff');
	      my ($tot_unread, $box_unread) = $self->count_unread(undef, $_);
	      ($q->td({-bgcolor => $bgcol, -nowrap},
		      $q->font({-size => '-1'},
			       ($_ eq $self->{'current_box'}
				? $q->strong('* '.$labels->{$_}.' *')
				: $q->a({-href => BASE_URI."?mailbox=".
					 $self->uri_escape_noamp($_)},
					$labels->{$_})))) .
	       $q->td({-bgcolor => $bgcol, -align => 'right'},
		      $q->font({-size => '-1'}, $#{$self->{$_}->{'index'}}+1)).
	       $q->td({-bgcolor => $bgcol, -align => 'right'},
		      $q->font({-size => '-1'},
			       ($box_unread > 0
				? $q->strong($q->span({-class => 'msgunread'},
						      $box_unread))
				: ($_ ne 'outbox' ? '0' : '-')))))
	  } @{$self->{'mailboxes'}})
	 ])
       )
      );
}

sub display_center_menu {
    my ($self, $labels) = @_;
    my $q = $self->{q};

    my $last_time = localtime($self->{'last_mail_check'});
    my $box = $self->{'current_box'};

    # only allow message transfering if more than just in and out boxes
    # never allow transfering to  or from outbox
    my (@transfer_boxes, $lbls);
    if (($#{$self->{'mailboxes'}} >= 2) and ($box ne 'outbox')) {
	foreach (@{$self->{'mailboxes'}}) {
	    if (($_ ne 'outbox') and ($_ ne $box)) {
		push(@transfer_boxes, $_);
		$lbls->{$_} = ucfirst($_);
	    }
	}
	$labels = $lbls if !$labels or ref $labels ne 'HASH';
    }

    my $msg_in_progress =
      ref $self->{compose_msg} eq "Apache::App::Mercury::Message";

    return
      ($q->table
       ({-cellspacing => 0, -cellpadding => 0,
	 -border => 0, -bgcolor => '#cccccc'},
	$q->Tr
	([$q->td({-align => 'right'},
		 $q->font({-size => '-1'},
			  $q->a({-href => BASE_URI.'?edit_mail_prefs=1'},
				"Edit mail settings"))),
	  $q->td({-align => 'right'},
		 $q->hr({-width => '50%', -align => 'right', -size => 1})),
	  $q->td({-align => 'right'},
		 $q->font({-size => '-1'},
			  $q->submit('check_mail', "Check mail"))),
	  $q->td({-align => 'right'},
		 $q->font({-size => '-1'},
			  $q->em("Mail last checked at:".$q->br.
				 $q->u($last_time)))),
	  $q->td({-align => 'right'},
		 $q->hr({-width => '50%', -align => 'right', -size => 1})),
	  $q->td({-align => 'right'},
		 $q->font({-size => '-1'},
			  $q->submit('compose', ($msg_in_progress
						 ? "Return to msg compose"
						 : "Compose new message")))),
	  $q->td({-align => 'right'},
		 $q->hr({-width => '50%', -align => 'right', -size => 1})),
	  ($#{$self->{$box}->{'index'}} < 0
	   ? ($q->td({-align => 'right'},
		     $q->font({-size => '-1'},
			      $q->em("There are no messages in this mailbox."))))
	   : ($box ne 'outbox'
	      ? ($q->td({-align => 'right'},
			$q->font({-size => '-1'},
				 (@transfer_boxes
				  ? ($q->submit('transfer',
						"Transfer selected messages") .
				     $q->br. "to Mailbox: ".
				     $q->popup_menu(-name => 'to_mailbox',
						    -values => \@transfer_boxes,
						    -labels => $labels))
				  : ($q->em("You can ".
					    $q->a({-href => BASE_URI.'?edit_mail_prefs=1'},
						  "create custom mailboxes")."."))))),
		 $q->td({-align => 'right'},
			$q->hr({-width => '50%',-align =>'right',-size => 1})))
	      : () )),
	  $q->td({-align => 'right'},
		 $q->font({-size => '-1'},
			  $q->submit('delete',"Delete selected messages")))
	 ])
       )
      );
}

sub display_msglist {
    my ($self) = @_;
    my $q = $self->{q};

    my $box = $self->{'current_box'};
    my $msglist = $self->{$box}->{'index'};
    my $msgs = $self->{$box}->{'msgs'};

    my $sortby = $self->{$box}->{'sortby'};
    my $sortdir = $self->{$box}->{'sortdir'};
    my $arrow = $sortdir eq 'up' ? ' /\\' : ' \/';

    my $color = '#ffffff';

    return ($q->div({-align => 'center'}, $q->p . $q->p .
		    $q->em("There are no messages in this mailbox.")))
	if $#$msglist < 0;

    return
      ($q->table
       ({-width => '96%', -align => 'center'},
	$q->Tr
	([$q->th({-align => 'left', -bgcolor => '#8080ff'},
		 ['&nbsp;',
		  $q->a({-href => BASE_URI."?".$box."_sortby=subject__".
			 ($sortby eq 'subject' && $sortdir eq 'up' ?'down':'up'),
			 -class => 'msgsort'}, 'Subject') .
		  $q->font({-size => '-1'},
			   $q->span({-class => 'msgsort'}, " (click to view)")).
		  ($sortby eq 'subject' ? $arrow : ''),
		  ($box ne 'outbox'
		   ? ($q->a({-href => BASE_URI."?".$box."_sortby=sender__".
			     ($sortby eq 'sender' && $sortdir eq 'up'
			      ? 'down' : 'up'),
			     -class => 'msgsort'}, 'Sender') .
		      ($sortby eq 'sender' ? $arrow :''))
		   : ($q->a({-href => BASE_URI."?".$box."_sortby=recipient__".
			     ($sortby eq 'recipient' && $sortdir eq 'up'
			      ? 'down' : 'up'),
			     -class => 'msgsort'}, 'Recipient') .
		      ($sortby eq 'recipient' ? $arrow : ''))),
		  $q->a({-href => BASE_URI."?".$box."_sortby=time__".
			 ($sortby eq 'time' && $sortdir eq 'up' ? 'down':'up'),
			 -class => 'msgsort'}, 'Date') .
		  ($sortby eq 'time' ? $arrow : '') ]),
	  (map {
	      my $id = $msglist->[$_];
	      my $bgcol = $color;
	      $color = ($color eq '#ffffff' ? '#c8e0ff' : '#ffffff');
	      ($q->td
	       ({-align => 'left', -bgcolor => $bgcol},
		[ $q->font
		  ({-size => '-1'},
		   $q->checkbox(-name =>'select_msgs',
				-value => $id,
				-label => '')),
		  ($msgs->{$id}->{'sent_to'} ne $msgs->{$id}->{'sender'}
		   ?
		   ($box ne 'outbox' && $msgs->{$id}->{'status'} eq 'unread'
		    ?($q->font
		      ({-size => '-1'},
		       $q->strong
		       ($q->span({-class => 'msgunread'},
				 $q->a({-href => BASE_URI.'?read='.$_},
				       $msgs->{$id}->{'subject'})) )),
		      $q->font({-size => '-1'},
			       $q->strong($q->span({-class => 'msgunread'},
						   $msgs->{$id}->{'sender'}))),
		      $q->font({-size => '-1'},
			       $q->strong( $q->span({-class => 'msgunread'},
						    $msgs->{$id}->{'time_formatted'}))))
		     : ($q->font({-size => '-1'},
				 $q->a({-href => BASE_URI.'?read='.$_},
				       $msgs->{$id}->{'subject'})),
			$q->font({-size=>'-1'},
				 ($box ne 'outbox'
				  ? $msgs->{$id}->{'sender'}
				  : ($msgs->{$id}->{'recipient'} eq
				     $msgs->{$id}->{'sent_to'}
				     ? $msgs->{$id}->{'recipient'}
				     : $msgs->{$id}->{'recipient'}."..."))),
			$q->font({-size=>'-1'}, $msgs->{$id}->{'time_formatted'})) )
		   : ($q->em
		      ($q->font({-size => '-1', -color => '#666633'}, 
				$q->a({-href => BASE_URI.'?read='.$_},
				      $msgs->{$id}->{'subject'})) ),
		      $q->em( $q->font({-size => '-1', -color => '#666633'}, 
				       "Memo") ),
		      $q->em( $q->font({-size => '-1', -color => '#666633'}, 
				       $msgs->{$id}->{'time_formatted'}))))
		]));
	  } 0..$#$msglist)
	 ])
       )
      );
}

sub display_message_with_header {
    my ($self, $msg, $box) = @_;
    my $q = $self->{q};

    $box = $self->{'current_box'} if !$box;
    $msg = $self->{$box}->{'msgs'}->{$self->{$box}->{'index'}->[$self->{'cur_index'}]} if !$msg;

    return
      ($q->h2("Message".
	      ($box ne 'outbox' && $msg->{'sent_to'} ne $msg->{'sender'}
	       && $msg->{'status'} eq 'unread' ? " - New": '')) .
       $q->table({-width => '90%',-cellspacing => 0,
		  -cellpadding => 2, -border => 3},
		 $q->Tr($q->td({-width => '88%', -valign => 'top'},
			       $self->display_message).
			$q->td({-width => 2, -bgcolor => '#999999'}, '&nbsp;').
			$q->td({-valign => 'top', -align => 'right',
				-bgcolor => '#cccccc'},
			       $self->display_message_menu))));
}

sub display_message {
    my ($self, $msg, $box) = @_;

    unless (ref $msg eq "Apache::App::Mercury::Message") {
	$box = $self->{'current_box'} unless $box;
	$msg = $self->{$box}->{'msgs'}->{$self->{$box}->{'index'}->[$self->{'cur_index'}]};
    }

    # tell the message to display itself
    return $msg->display;
}

sub display_message_menu {
    my ($self, $msg, $box, $labels) = @_;
    my $q = $self->{q};

    $box = $self->{'current_box'} unless $box;
    $msg = $self->{$box}->{'msgs'}->{$self->{$box}->{'index'}->[$self->{'cur_index'}]} unless $msg;

    # only allow message transfering if more than just in and out boxes
    # never allow transfering to or from outbox
    my (@transfer_boxes, $lbls);
    if (($#{$self->{'mailboxes'}} >= 2) and ($box ne 'outbox')) {
	foreach (@{$self->{'mailboxes'}}) {
	    if (($_ ne 'outbox') and ($_ ne $box)) {
		push(@transfer_boxes, $_);
		$lbls->{$_} = ucfirst($_);
	    }
	}
	$labels = $lbls if !$labels or ref $labels ne 'HASH';
    }

    my $is_memo = ($msg->{'sender'} eq $msg->{'sent_to'});
    my $msg_in_progress =
      ref $self->{compose_msg} eq "Apache::App::Mercury::Message";

    return
      ($q->startform(-action => BASE_URI) .
       $q->hidden(-name => 'msg_id', -default => $msg->{'id'}, -override=>1) .
       $q->table
       ({-bgcolor => '#cccccc', -cellspacing => 0},
	$q->Tr
	([$q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  $q->submit('message_center',
				     "Return to '".ucfirst($box)."'") .
			  $q->hr({-size => 1}))),
	  $q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  ($self->{'cur_index'} > 0
			   ? $q->submit('read_prev', "Previous Msg")
			   : $q->em('at first message in box')) .
			  ($self->{'cur_index'} <= 0 ||
			   $self->{'cur_index'} >= $#{$self->{$box}->{'index'}}
			   ? $q->br : " ") .
			  ($self->{'cur_index'} < $#{$self->{$box}->{'index'}}
			   ? $q->submit('read_next', "Next Msg")
			   : $q->em('at last message in box')) .
			  $q->hr({-size => 1}))),
	  $q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  $q->submit('print', "Format for Printing") .
			  $q->hr({-size => 1}))),
	  $q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  $q->submit('compose', ($msg_in_progress
						 ? "Return to msg compose"
						 : "Compose new message")))),
	  $q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  ($box ne 'outbox'
			   ? ((!$is_memo ? $q->submit('reply', "Reply") : '') .
			      $q->submit('forward', "Forward"))
			   : $q->submit('re-send', "Re-send")) .
			  $q->hr({-size => 1}))),
	  (@transfer_boxes
	   ? ($q->td({-align => 'center'},
		     $q->font({-size => '-1'},
			      $q->submit('transfer',
					 "Transfer Msg to: ") . $q->br .
			      $q->popup_menu(-name => 'to_mailbox',
					     -values => \@transfer_boxes,
					     -labels => $labels) .
			      $q->hr({-size => 1}))))
	   : () ),
	  $q->td({-align => 'center'},
		 $q->font({-size => '-1'},
			  $q->submit('delete',
				     $is_memo ? "Delete Memo" : "Delete Msg")))
	 ])
       )
      );
}

sub display_compose_with_header {
    my ($self) = @_;
    my $q = $self->{q};

    return
      ($q->h2("Message Composition") .
       $q->startform(-name => 'comp_form', -action => BASE_URI) .
       $q->table
       ({-width => '96%', -cellspacing => 0, -cellpadding => 2,
	 -border => 3, -bgcolor => '#cccccc'},
	$q->Tr
	([$q->td({-valign => 'top'},
		 $q->table({-width => '100%', -cellpadding => 2,
			    -cellspacing => 0, -border => 0},
			   $q->Tr([$q->td({-bgcolor => '#ffffff'},
					  $self->{compose_msg}->display_compose),
				   $q->td({-bgcolor => '#cccccc'},
					  $self->display_compose_menu)
				  ]) ) ) .
	  ($self->can("display_compose_help")
	   ? ($q->td({-width => 2, -bgcolor => '#999999'}, '&nbsp;') .
	      $q->td({-valign => 'top', -bgcolor => '#cccccc'},
		     $self->display_compose_help))
	   : '')
	 ])) .
       $q->endform
      );
}

# this must be within a form
sub display_compose_menu {
    my ($self) = @_;
    my $q = $self->{q};

    return
      ($q->table({-width => '100%'},
		 $q->Tr($q->td($q->submit('preview', "Preview") .
			       $q->submit('return', "Store and return to '" .
					  ucfirst($self->{'current_box'})."'")
			      ) .
			$q->td({-align => 'right'},
			       $q->submit('reset', "Reset Message") .
			       $q->submit('cancel', "Cancel")
			      ))));
}

sub display_preview_with_header {
    my ($self) = @_;
    my $q = $self->{q};

    return
      ($q->h2("Message Preview") . $q->br .
       $self->display_preview_message .
       $self->{compose_msg}->display_preview
      );
}

sub display_preview_message {
    my ($self) = @_;
    my $q = $self->{q};

    my $message;

    if (ref $self->{compose_msg} eq "Apache::App::Mercury::Message" and
	$self->{compose_msg}->{'transcode'}) {
	my $is_memo = ($self->{compose_msg}->{'sender'} eq
		       $self->{compose_msg}->{'sent_to'});
	$message = ($q->p . $q->em("You are about to ".(!$is_memo ? "send a message in response to" : "commit a memo regarding")." a transaction (Reference number: ".$self->{compose_msg}->{'transcode'}.").  Anyone with permission to view this transaction will be able to read ".(!$is_memo ? "your message.  If you do not want this message to be connected to transaction ".$self->{compose_msg}->{'transcode'}.", return to the ".$q->a({-href => BASE_URI.'?cancel=1'}, "Message Center")." and compose a new message from there." : "this memo.")));
    } else {
	$message = ($q->p . "Please review your message before sending.");
    }

    $message .= ($q->p . "Be sure to select the files you wish to attach.")
      if $self->{compose_msg}->{'num_to_attach'};

    $message .= ($q->p . "Your message is marked as <B>low</B>-security.  This means it may be forwarded over the internet via insecure e-mail.  If this message contains <B>any</B> patient-identifiable information, it is your responsibility to raise the security level to <B>medium</B> or higher.")
      if $self->{compose_msg}->{'security'} eq 'low';

    return $message;
}

sub display_mail_settings {
    my ($self) = @_;
    my $q = $self->{q};

    my @custom_mboxes = $self->{user_manager}->mailboxes;
    my $labels = { map { $_ => ucfirst($_) } @custom_mboxes };
    $labels->{'inbox'} = "Inbox";

    my $trans_filter = $self->{user_manager}->mail_trans_filter;

    return
      ($q->div
       ({-align => 'center'},
	$q->h2("Messaging Settings for " . $self->{user_manager}->userprofile('user')) .
	$q->startform(-action => BASE_URI) .
	$q->table
	({-width => '80%'},
	 $q->Tr
	 ([$q->th({-colspan => 2, -align => 'left', -bgcolor => '#cccccc'},
		  "Add and remove customized mailboxes"),
	   $q->td({-align => 'right', -width => '50%'}, "Custom mailboxes: ") .
	   $q->td({-width => '50%'},
		  ($#custom_mboxes >= 0
		   ? $q->popup_menu(-name => 'custom_box',
				    -values => \@custom_mboxes,
				    -labels => $labels)
		   : $q->em('None'))),
	   $q->td({-valign => 'top', -width => '50%'},
		  ($#custom_mboxes < 14
		   ? ($q->submit('add_box', "Add box: ") .
		      $q->textfield(-name => 'new_box',
				    -size => 16, -maxlength => 16))
		   : $q->em("You have 15 custom mailboxes, which is the maximum currently allowed."))) .
	   $q->td({-align => 'right', -valign => 'top', -width => '50%'},
		  ($#custom_mboxes >= 0
		   ? ($q->submit('delete_box', "Delete selected box").$q->br .
		      $q->font({-size => '-1'}, " (" .
			       $q->checkbox(-name => 'delete_mail_in_box',
					    -value => 1,
					    -label => '') .
			       " Check to delete all mail in that box, otherwise mail will be transfered to your Inbox.)"))
		   : '&nbsp;')),

	   $q->th({-colspan => 2, -align => 'left', -bgcolor => '#cccccc'},
		  "Edit filters"),
	   $q->td({-width => '50%', -align => 'right'},
		  "Send transaction related messages to: ") .
	   $q->td({-width => '50%'},
		  $q->popup_menu(-name => 'trans_filter',
				 -values => [ 'inbox', @custom_mboxes ],
				 -override => 1,
				 -default => ($trans_filter
					      ? $trans_filter : 'inbox'),
				 -labels => $labels)),
	   $q->td({-colspan => 2, -align => 'right'},
		  $q->submit('commit_filter', "Commit Filter")),

	   ($self->{user_manager}->userprofile('e_mail')
	    ? ($q->th({-colspan => 2, -align => 'left', -bgcolor => '#cccccc'},
		      "E-mail auto-forwarding"),
	       $q->td({-width => '50%', -align => 'right'},
		      "Registered e-mail address:") .
	       $q->td({-width => '50%'},
		      $q->i("&lt;".$self->{user_manager}->userprofile('e_mail')."&gt;")),
	       $q->td({-width => '50%', -align => 'right'},
		      "When I receive a message tagged <B>low</B>-security:") .
	       $q->td({-width => '50%', -align => 'left'},
		      $q->popup_menu
		      (-name => 'forward_low',
		       -values => [qw(message notify none)],
		       -override => 1,
		       -default => $self->{user_manager}->auto_forward('low'),
		       -labels => {'message' => "send the entire message",
				   'notify' => "send a notification",
				   'none' => "do not send anything"}) .
		      " to me via e-mail"),

	       $q->td({-width => '50%', -align => 'right'},
		      "When I receive a message tagged <B>medium</B>-security:") .
	       $q->td({-width => '50%', -align => 'left'},
		      $q->popup_menu(-name => 'forward_medium',
				     -values => [qw(notify none)],
				     -override => 1,
				     -default => $self->{user_manager}->auto_forward('medium'),
				     -labels => { 'notify' => "send",
						  'none' => "do not send" }) .
		      " e-mail notification"),

	       $q->td({-width => '50%', -align => 'right'},
		      "When I receive a message tagged <B>high</B>-security:") .
	       $q->td({-width => '50%', -align => 'left'},
		      $q->popup_menu(-name => 'forward_high',
				     -values => [qw(notify none)],
				     -override => 1,
				     -default => $self->{user_manager}->auto_forward('high'),
				     -labels => { 'notify' => "send",
						  'none' => "do not send" }) .
		      " e-mail notification"),

	       $q->td({-colspan => 2, -align => 'right'},
		      $q->submit('update_auto_forward',
				 "Update auto-forward settings")),
	      )
	    : ()),

	   $q->td({-colspan => 2, -bgcolor => '#cccccc'}, '&nbsp;'),
	   $q->td({-align => 'left', -colspan => 2},
		  $q->submit('message_center', "Return to '" .
			     ucfirst($self->{'current_box'}."'")))
	  ])))
      );
}


1;
