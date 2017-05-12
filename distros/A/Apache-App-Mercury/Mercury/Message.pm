package Apache::App::Mercury::Message;

require 5.004;
use strict;

use Apache::App::Mercury::Base;
use Apache::App::Mercury::Message::DBI;
use base qw(Apache::App::Mercury::Base  Apache::App::Mercury::Message::DBI);
use Apache::App::Mercury::Message::Attachment;
use Apache::App::Mercury::Config;

use Text::Wrap qw(wrap);


sub initialize {
    my ($self, $messaging) = @_;
    $self->{messaging} = $messaging;
}


# CGI display methods and helpers

sub read_attachments_from_cgi {
    my ($self) = @_;
    my $q = $self->{messaging}->{q};

    $self->{'Attachments'} = [] if ref $self->{'Attachments'} ne "ARRAY";
    foreach (0..$self->{'num_to_attach'}-1) {
	my $fh = $q->param('attachment'.$_);
	next if !$fh;

	my $new_attach = Apache::App::Mercury::Message::Attachment->new;
	( $new_attach->{'Name'} ) = ( $fh =~ m/([^\\]+)$/ );
	$new_attach->{'Name'} = $fh unless $new_attach->{'Name'};
	my $buffer;
	while (read($fh, $buffer, 10240)) {
	    $new_attach->{'Data'} .= $buffer;
	}
	push(@{$self->{'Attachments'}}, $new_attach);
    }
}

sub pretty_print {
    my ($self, $body) = @_;

    # split long lines (60 char max)
    $Text::Wrap::columns = 60;
    $body = wrap('', '', $body);

    # make URLs in body into hyper references
    $body =~
      s!(\s+)(https?|telnet|news):(/{0,2}[^\s]+)!$1<A HREF="$2:$3">$2:$3</A>!g;

    # make e-mail addresses into mailto tags
    $body =~
      s!(\s+)(\w+)\@([-a-zA-Z]+\.)+([-a-zA-Z]{2,3})(\s+)!$1<A HREF="mailto:$2\@$3$4">$2\@$3$4</A>$5!g;

    return $body;
}

sub display {
    my ($self) = @_;
    my $messaging = $self->{messaging};
    my $q = $messaging->{q};
    my $user = $messaging->{user_manager}->userprofile('user');

    # get custom-defined display class, if there is one
    my $dispclass = Apache::App::Mercury::Config::DISPLAY_CLASS();

    my $is_recip = ($user eq $self->{'sent_to'});
    my $is_sender = ($user eq $self->{'sender'});
    my $is_memo = ($self->{'sent_to'} eq $self->{'sender'});

    # save database hits by caching results in message object
    unless (ref $self->{'sender_info'} eq "HASH") {
	my %sender_info =
	  ($is_sender
	   ? ( 'fname' => $messaging->{user_manager}->userprofile('fname'),
	       'lname' => $messaging->{user_manager}->userprofile('lname') )
	   : %{($messaging->{user_manager}->get_userinfo($self->{'sender'}))[0]});
	$self->{'sender_info'} = { 'fname' => $sender_info{'fname'},
				   'lname' => $sender_info{'lname'} };
    }

    my $recip_desc;
    if ($self->{'recipient_desc'}) {
	$recip_desc = $self->{'recipient_desc'};
    } elsif ($is_recip) {
	$recip_desc =
	  ($user." (".$messaging->{user_manager}->userprofile('fname').
	   " ".$messaging->{user_manager}->userprofile('lname').")");
    } else {
	# save database hits by caching results in message object
	unless (ref $self->{'recip_info'} eq "ARRAY") {
	    my @recip_info = $messaging->{user_manager}->get_userinfo
	      (split(';', $self->{'sent_to'}));
	    $self->{'recip_info'} =
	      [ map { { 'user' => $_->{'user'},
			'fname' => $_->{'fname'},
			'lname' => $_->{'lname'} }; } @recip_info ];
	}

	foreach (@{$self->{'recip_info'}}) {
	    $recip_desc .=
	      (($recip_desc ? "; " : "") .
	       ($dispclass->can("USER_INFO_HREF")
		? $dispclass->USER_INFO_HREF($_->{'user'}, $q)
		: '') .
	       " (" . $_->{'fname'}." ".$_->{'lname'} . ")");
	}
    }

    # generate attachment HTML
    my @attach_html;
    if (ref $self->{'Attachments'} eq "ARRAY") {
	foreach (0..$#{$self->{'Attachments'}}) {
	    my $a = $self->{'Attachments'}->[$_];
	    next unless
	      $a->{'Filename'} and $a->{'Name'} and $a->{'AttachmentID'};
	    push(@attach_html,
		 ($q->td({-align => 'right', -nowrap},
			 $q->b("Attachment ".($_+1).":")) .
		  $q->td({-nowrap},
			 $q->a({-href => $self->uri_escape_noamp
				(Apache::App::Mercury::Config::ATTACHMENT_BASE_URI() .
				 $a->{'Filename'}),
				-class => 'attach',
				-target => 'theAttachmentWindow'},
			       $a->{'Name'}))));
	}
    }

    my $markedup_body = $self->pretty_print($self->{'body'});

    return
      ($q->table
       ($q->Tr
	([$q->td({-align => 'right', -nowrap}, $q->b("Subject:")) .
	  $q->td({-nowrap}, $q->b($self->{'subject'})),

	  # add possible additional message headers according to customization
	  ($dispclass->can("AUX_HEADERS")
	   ? $dispclass->AUX_HEADERS($self)
	   : ''),

	  ($self->{'time_formatted'}
	   ? ($q->td({-align => 'right', -nowrap}, $q->b("Date:")) .
	      $q->td({-nowrap}, $self->{'time_formatted'}))
	   : ()),
	  $q->td({-align => 'right', -nowrap},
		 $q->b(!$is_memo ? "From:" : "Memo by:")) .
	  $q->td({-nowrap},
		 ($is_sender
		  ? $user
		  : ($dispclass->can("USER_INFO_HREF")
		     ? $dispclass->USER_INFO_HREF($self->{'sender'}, $q)
		     : '')) .
		 " (".$self->{'sender_info'}->{'fname'}." ".
		 $self->{'sender_info'}->{'lname'}.")"),
	  (!$is_memo
	   ? ($q->td({-align => 'right', -valign => 'top', -nowrap},
		     $q->b("To:")) . $q->td($recip_desc))
	   : ()),
	  @attach_html,
	  ($self->{'action'}
	   ? ()
	   : ($q->td({-align => 'right', -nowrap}, $q->b("Security level:")) .
	      $q->td({-nowrap}, $q->font({-face => 'fixed'},
					 uc $self->{'security'}))))
	 ])
       ) .
       $q->hr({-width => '200', -align => 'left', -size => '1'}) .
       $q->pre($markedup_body)
      );
}

sub display_compose {
    my ($self) = @_;
    my $messaging = $self->{messaging};
    my $q = $messaging->{q};

    my $sender = $messaging->{user_manager}->userprofile('user');

    # see if there are defaults (a msg in composition, or a reply/forward...)
    my $recipient = $self->{'sent_to'};

    my $is_memo = ($sender eq $recipient);

    # generate attachment HTML
    my @attach_html;
    if (ref $self->{'Attachments'} eq "ARRAY") {
	foreach (0..$#{$self->{'Attachments'}}) {
	    my $a = $self->{'Attachments'}->[$_];
	    next unless
	      $a->{'Filename'} and $a->{'Name'} and $a->{'AttachmentID'};
	    push(@attach_html,
		 ($q->b("Attachment ".($_+1).": ") .
		  $q->a({-href => $self->uri_escape_noamp
			 (Apache::App::Mercury::Config::ATTACHMENT_BASE_URI() .
			  $a->{'Filename'}),
			 -class => 'attach',
			 -target => 'theAttachmentWindow'},
			$a->{'Name'}) .
		  " (".$q->a({-href => Apache::App::Mercury::Config::BASE_URI()."?remove_attach=".$_},
			     "remove").")"
		 ));
	}
    }

    return
      ((!$is_memo
	? ($q->b("From: ") . $sender." (".
	   $messaging->{user_manager}->userprofile('fname')." ".
	   $messaging->{user_manager}->userprofile('lname').")".$q->br.$q->br.
	   $q->b("To: ") .
	   ($recipient &&
	    ($self->{'action'} eq 'reply' || $self->{'action'} eq 'mailto')
	    ? ($self->{'recipient_desc'} . $q->br)
	    : $q->textfield(-name => 'recipient', -override => 1,
			    -default => $recipient,
			    -size => 34, -maxlength => 255)))
	: ($q->b("Memo by: ").$sender.
	   ($messaging->{user_manager}->userprofile('user_desc')
	    ? " (".$messaging->{user_manager}->userprofile('user_desc').")" : "") .
	   $q->br)) .
       $q->br .
       $q->b("Subject: ") .
       $q->textfield(-name => 'subject', -override => 1,
		     -default => $self->{'subject'},
		     -size => 40, -maxlength => 100) . $q->br .
       ($self->{'transcode'}
	? $q->br.$q->b("Trans: ").$self->{'transcode'}.$q->br.$q->br : '') .
       $q->b("Body: ") . $q->br .
       $q->textarea(-name => 'body', -override => 1,
		    -default => $self->{'body'},
		    -rows => 13, -columns => 60, -wrap => 'soft') .
       $q->br .
       join($q->br, @attach_html) .
       $q->br .
       $q->b("Attach ") .
       $q->textfield(-name => 'num_files_to_attach', -override => 1,
		     -default => ($self->{'num_to_attach'}
				  ? $self->{'num_to_attach'} : 0),
		     -size => 2, -maxlength => 2) .
       $q->b(" file(s)") . $q->br .
       $q->b("Security level of this message: ") .
       ($self->{'security_fixed'} && $self->{'security'}
	? $q->font({-face => 'fixed'}, uc($self->{'security'}))
	: $q->popup_menu(-name => 'security', -override => 1,
			 -values => ['low', 'medium', 'high'],
			 -default => ($self->{'security'}
				      ? $self->{'security'} : 'medium'),
			 -labels => { 'low' => "Low", 'medium' => "Medium",
				      'high' => "High" },
			)) .
       $q->br
      );
}

sub display_preview {
    my ($self) = @_;
    my $messaging = $self->{messaging};
    my $q = $messaging->{q};

    my $is_memo = ($self->{'sender'} eq $self->{'sent_to'});

    return
      ($q->start_multipart_form(-action => Apache::App::Mercury::Config::BASE_URI()) .
       $q->table
       ({-width => '96%', -cellspacing => 0, -cellpadding => 2,
	 -border => 3, -bgcolor => '#cccccc'},
	$q->Tr
	($q->td
	 ({-width => '70%', -valign => 'top', -align => 'left'},
	  $q->table({-width => '100%', -height => '100%', -cellpadding => 2,
		     -cellspacing => 0, -border => 0, -bgcolor => '#ffffff'},
		    $q->Tr([$q->td({-valign => 'top', -height => '100%',
				    -bgcolor => '#ffffff'}, $self->display),
			    ($self->{'num_to_attach'}
			     ? $q->td({-valign=>'bottom', -bgcolor=>'#cccccc'},
				      $q->b("Select new attachments:") .$q->p.
				      join('', map {
					  ("$_: " . $q->filefield(-name => 'attachment'.($_-1)) . $q->br)
				      } 1..$self->{'num_to_attach'}))
			     : $q->td({-bgcolor=>'#ffffff', -valign=>'bottom'},
				      '&nbsp;')),
			    $q->td({-bgcolor => '#cccccc'},
				   $q->b("Security level: ") .
				   ($self->{'security_fixed'} &&
				    $self->{'security'}
				    ? $q->font({-face => 'fixed'},
					       uc($self->{'security'}))
				    : $q->popup_menu
				    (-name => 'security', -override => 1,
				     -values => ['low', 'medium', 'high'],
				     -default => ($self->{'security'}
						  ? $self->{'security'}
						  : 'medium'),
				     -labels => { 'low' => "Low",
						  'medium' => "Medium",
						  'high' => "High" }))),
			   ]))) .
	 $q->td({-width => 2, -bgcolor => '#999999'}, '&nbsp;') .
	 $q->td({-bgcolor => '#cccccc', -valign => 'top', -align => 'right'},
		$q->table
		($q->Tr
		 ([$q->td({-align => 'right'},
			  $q->submit('send', (!$is_memo ? "Send message"
					      : "Commit memo"))),
		   $q->td({-align => 'right'},
			  $q->submit('make_changes', "Make changes")),
		   $q->td({-align => 'right'}, $q->submit('cancel', "Cancel")),
		   $q->td('&nbsp;' . $q->br . '&nbsp;'),
		   $q->td({-align => 'right', -valign => 'bottom'},
			  $q->submit('return', "Store and return to '".
				     ucfirst($messaging->{'current_box'})."'").
			  ($self->{'num_to_attach'}
			   ? ($q->br .
			      $q->font({-size => '-2'},
				       $q->em("Selected attached files will " .
					      $q->b('NOT') .
					      " be remembered when stored")))
			   : ''))
		  ]))))) .
       $q->endform
      );
}


1;
