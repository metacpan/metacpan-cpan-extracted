########################################################################

package __Aut__YesNo;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);

use Locale::Framework;

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__YesNo::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{yn_label} = Wx::StaticText->new($self, -1, _T("label_11"), wxDefaultPosition, wxDefaultSize, );
	$self->{static_line_4} = Wx::StaticLine->new($self, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{yn_no} = Wx::Button->new($self, wxNO, _T("&No"));
	$self->{yn_yes} = Wx::Button->new($self, wxYES, _T("&Yes"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__YesNo::__set_properties

	$self->SetTitle(_T("Yes No"));
	$self->{yn_yes}->SetDefault();

# end wxGlade
	$self->{yn_no}->SetDefault();

	EVT_BUTTON($self,$self->{yn_no},\&No);
	EVT_BUTTON($self,$self->{yn_yes},\&Yes);
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__YesNo::__do_layout

	$self->{grid_sizer_9} = Wx::FlexGridSizer->new(3, 1, 5, 5);
	$self->{grid_sizer_10} = Wx::GridSizer->new(1, 2, 5, 5);
	$self->{grid_sizer_9}->Add($self->{yn_label}, 0, wxALL|wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 5);
	$self->{grid_sizer_9}->Add($self->{static_line_4}, 0, wxEXPAND, 0);
	$self->{grid_sizer_10}->Add($self->{yn_no}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_10}->Add($self->{yn_yes}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_9}->Add($self->{grid_sizer_10}, 1, wxEXPAND, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{grid_sizer_9});
	$self->{grid_sizer_9}->Fit($self);
	$self->{grid_sizer_9}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__YesNo

sub max {
  my ($x,$y)=@_;
  return ($x > $y) ? $x : $y;
}

sub set_label {
  my $self=shift;
  my $text=shift;

  my $borderwidth=5;

  my $size=$self->{'yn_label'}->GetSize();
  $self->{'yn_label'}->SetLabel($text);
  my $nsize=$self->{'yn_label'}->GetBestSize();
  my $x=max($size->x,$nsize->x);
  my $y=max($size->y,$nsize->y);
  my $minsize=new Wx::Size($x+2*$borderwidth,$y+2*$borderwidth);
  $self->{'grid_sizer_10'}->SetMinSize($minsize);

  $self->SetAutoLayout(1);
  $self->SetSizerAndFit($self->{grid_sizer_9},0);
  $self->{grid_sizer_9}->Fit($self);
  $self->{grid_sizer_9}->SetSizeHints($self);
  $self->Layout();
  $self->Centre();
  $self->{'yn_yes'}->SetDefault();
}

sub Yes {
  my $self=shift;
  $self->EndModal(wxYES);
}

sub No {
  my $self=shift;
  $self->EndModal(wxNO);
}

1;

package __Aut__Msg;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

use Locale::Framework;

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__Msg::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{msgLabel} = Wx::StaticText->new($self, -1, _T("label_11"), wxDefaultPosition, wxDefaultSize, );
	$self->{static_line_3} = Wx::StaticLine->new($self, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{autmsg_ok} = Wx::Button->new($self, wxID_OK, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__Msg::__set_properties

	$self->SetTitle(_T("Message"));
	$self->{autmsg_ok}->SetDefault();

# end wxGlade

	
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__Msg::__do_layout

	$self->{grid_sizer_8} = Wx::GridSizer->new(3, 1, 5, 5);
	$self->{grid_sizer_8}->Add($self->{msgLabel}, 0, wxALL|wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 5);
	$self->{grid_sizer_8}->Add($self->{static_line_3}, 0, wxEXPAND, 0);
	$self->{grid_sizer_8}->Add($self->{autmsg_ok}, 0, wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{grid_sizer_8});
	$self->{grid_sizer_8}->Fit($self);
	$self->{grid_sizer_8}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__Msg

sub max {
  my ($x,$y)=@_;
  return ($x > $y) ? $x : $y;
}

sub set_label {
  my $self=shift;
  my $text=shift;

  my $borderwidth=5;

  my $size=$self->{'msgLabel'}->GetSize();
  $self->{'msgLabel'}->SetLabel($text);
  my $nsize=$self->{'msgLabel'}->GetBestSize();
  my $x=max($size->x,$nsize->x);
  my $y=max($size->y,$nsize->y);
  my $minsize=new Wx::Size($x+2*$borderwidth,$y+2*$borderwidth);

  $self->{'grid_sizer_8'}->SetMinSize($minsize);

  $self->SetAutoLayout(1);
  $self->SetSizerAndFit($self->{grid_sizer_8},0);
  $self->{grid_sizer_8}->Fit($self);
  $self->{grid_sizer_8}->SetSizeHints($self);
  $self->Layout();
  $self->Centre();
}

1;

package __Aut__Entry;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

use Locale::Framework;

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__Entry::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{txtLabel} = Wx::StaticText->new($self, -1, _T(".sdfsdfsfa"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtEntry} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{static_line_2} = Wx::StaticLine->new($self, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{qCancel} = Wx::Button->new($self, wxID_CANCEL, _T("&Cancel"));
	$self->{qOK} = Wx::Button->new($self, wxID_OK, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__Entry::__set_properties

	$self->SetTitle(_T("Question"));
	$self->{txtEntry}->SetFocus();
	$self->{qOK}->SetDefault();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__Entry::__do_layout

	$self->{sizer_4} = Wx::FlexGridSizer->new(3, 1, 0, 0);
	$self->{grid_sizer_6} = Wx::GridSizer->new(1, 2, 5, 5);
	$self->{grid_sizer_5} = Wx::FlexGridSizer->new(2, 1, 5, 5);
	$self->{grid_sizer_5}->Add($self->{txtLabel}, 0, wxALL|wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 5);
	$self->{grid_sizer_5}->Add($self->{txtEntry}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{sizer_4}->Add($self->{grid_sizer_5}, 1, wxEXPAND, 0);
	$self->{sizer_4}->Add($self->{static_line_2}, 0, wxEXPAND, 0);
	$self->{grid_sizer_6}->Add($self->{qCancel}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_6}->Add($self->{qOK}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{sizer_4}->Add($self->{grid_sizer_6}, 1, wxEXPAND, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{sizer_4});
	$self->{sizer_4}->Fit($self);
	$self->{sizer_4}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__Entry

sub max {
  my ($x,$y)=@_;
  return ($x > $y) ? $x : $y;
}

sub set_label {
  my $self=shift;
  my $text=shift;

  my $borderwidth=5;

  my $size=$self->{'txtLabel'}->GetSize();
  $self->{'txtLabel'}->SetLabel($text);
  my $nsize=$self->{'txtLabel'}->GetBestSize();
  my $x=max($size->x,$nsize->x);
  my $y=max($size->y,$nsize->y);
  my $minsize=new Wx::Size($x+2*$borderwidth,$y+2*$borderwidth);

  $self->{'grid_sizer_5'}->SetMinSize($minsize);
  $self->{'grid_sizer_5'}->SetItemMinSize($self->{'txtLabel'},$x,$y);

  $self->SetAutoLayout(1);
  $self->SetSizerAndFit($self->{sizer_4},0);
  $self->{sizer_4}->Fit($self);
  $self->{sizer_4}->SetSizeHints($self);
  $self->Layout();
  $self->Centre();
}

sub get_value {
  my $self=shift;
return $self->{'txtEntry'}->GetValue();
}

1;

package __Aut__ChangePass;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);

use strict;

use Locale::Framework;


sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__ChangePass::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{label_7} = Wx::StaticText->new($self, -1, _T("Account:"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtchgpass_account} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_10} = Wx::StaticText->new($self, -1, _T("Current password:"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtchgpass_old} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{label_8} = Wx::StaticText->new($self, -1, _T("Password:"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtchgpass_pass} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{label_9} = Wx::StaticText->new($self, -1, _T("Password (again):"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtchgpass_again} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{static_line_1} = Wx::StaticLine->new($self, -1, wxDefaultPosition, wxDefaultSize, );
	$self->{chgpassCancel} = Wx::Button->new($self, wxID_CANCEL, _T("&Cancel"));
	$self->{chgpassOK} = Wx::Button->new($self, wxID_OK, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__ChangePass::__set_properties

	$self->SetTitle(_T("Change Password"));
	$self->{txtchgpass_account}->Enable(0);
	$self->{txtchgpass_old}->SetFocus();
	$self->{chgpassOK}->SetDefault();

# end wxGlade

	EVT_BUTTON($self,$self->{chgpassOK},\&Ok);
	EVT_BUTTON($self,$self->{chgpassCancel},\&Cancel);
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__ChangePass::__do_layout

	$self->{sizer_3} = Wx::FlexGridSizer->new(3, 1, 0, 0);
	$self->{grid_sizer_3} = Wx::GridSizer->new(1, 2, 5, 5);
	$self->{grid_sizer_4} = Wx::GridSizer->new(3, 2, 5, 5);
	$self->{grid_sizer_4}->Add($self->{label_7}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{txtchgpass_account}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{label_10}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{txtchgpass_old}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{label_8}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{txtchgpass_pass}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{label_9}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_4}->Add($self->{txtchgpass_again}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{sizer_3}->Add($self->{grid_sizer_4}, 1, wxEXPAND, 0);
	$self->{sizer_3}->Add($self->{static_line_1}, 0, wxEXPAND, 0);
	$self->{grid_sizer_3}->Add($self->{chgpassCancel}, 0, wxEXPAND, 0);
	$self->{grid_sizer_3}->Add($self->{chgpassOK}, 0, wxEXPAND, 0);
	$self->{sizer_3}->Add($self->{grid_sizer_3}, 1, wxEXPAND, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{sizer_3});
	$self->{sizer_3}->Fit($self);
	$self->{sizer_3}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__ChangePass

sub set_aut {
  my ($self,$aut)=@_;
  $self->{"aut"}=$aut;
}

sub set_ui {
  my ($self,$ui)=@_;
  $self->{"ui"}=$ui;
}

sub set_account {
  my ($self,$account)=@_;
  $self->{"txtchgpass_account"}->SetValue($account);
}

sub set_ticket {
  my ($self,$ticket)=@_;
  $self->{"ticket"}=$ticket;
}

sub Ok {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ticket=$self->{"ticket"};
  my $ui=$self->{"ui"};

  my $old=$self->{"txtchgpass_old"}->GetValue();
  my $pass=$self->{"txtchgpass_pass"}->GetValue();
  my $again=$self->{"txtchgpass_again"}->GetValue();

  my $thepass=$ticket->pass();

  my $ok=0;

  if ($thepass ne $old) {
    $ui->message_ok(_T("You didn't give a valid current password"),
		    _T("Change Password"),
		    $self
		   );
  }
  elsif ($pass ne $again) {
    $ui->message_ok(_T("New passwords don't match"),
		    _T("Change Password"),
		    $self
		   );
  }
  else {
    my $msg=$aut->check_pass($pass);
    if ($msg ne "") {
      $ui->message_ok($msg,
		      _T("Change Password"),
		       $self
		      );
    }
    else {
      # Update account via Aut

      $ticket->set_pass($pass);
      $aut->ticket_update($ticket);

      # End dialog

      $self->EndModal(wxID_OK);
      $ok=1;
    }
  }

  if (not $ok) {
    $self->{"txtchgpass_again"}->SetValue("");
    $self->{"txtchgpass_pass"}->SetValue("");
    $self->{"txtchgpass_old"}->SetValue("");
    $self->{"txtchgpass_old"}->SetFocus();
  }
}

sub Cancel {
    my $self=shift;
    $self->EndModal(wxID_CANCEL);
}

1;

########################################################################

package __Aut__dlgLogin;

use strict;

use Wx qw[:everything];
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);
use Locale::Framework;

use base qw(Wx::Dialog);

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__dlgLogin::new

	$style = wxDIALOG_MODAL|wxCAPTION 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{label_1} = Wx::StaticText->new($self, -1, _T("Account:"), wxDefaultPosition, wxDefaultSize, wxALIGN_RIGHT);
	$self->{authAccount} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_2} = Wx::StaticText->new($self, -1, _T("Password:"), wxDefaultPosition, wxDefaultSize, wxALIGN_RIGHT);
	$self->{authPass} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{authCancel} = Wx::Button->new($self, -1, _T("&Cancel"));
	$self->{authOK} = Wx::Button->new($self, -1, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__dlgLogin::__set_properties

	$self->SetTitle(_T("Login"));
	$self->{authOK}->SetDefault();

# end wxGlade

	EVT_BUTTON($self,$self->{authOK},\&Ok);
	EVT_BUTTON($self,$self->{authCancel},\&Cancel);
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__dlgLogin::__do_layout

	$self->{grid_sizer_1} = Wx::GridSizer->new(3, 2, 5, 5);
	$self->{grid_sizer_1}->Add($self->{label_1}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{authAccount}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{label_2}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{authPass}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{authCancel}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{grid_sizer_1}->Add($self->{authOK}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{grid_sizer_1});
	$self->{grid_sizer_1}->Fit($self);
	$self->{grid_sizer_1}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

#### User functions

sub set_aut {
  my ($self,$aut)=@_;
  $self->{"aut"}=$aut;
}

sub set_ui {
  my ($self,$ui)=@_;
  $self->{"ui"}=$ui;
}

sub account {
  my $self=shift;
return $self->{'authAccount'}->GetValue();
}

sub pass {
  my $self=shift;
  my $pass=shift;
  if (defined $pass) { 
    $self->{'authPass'}->SetValue($pass);
    $self->{'authPass'}->SetFocus();
  }
return $self->{'authPass'}->GetValue();
}

sub ticket {
  my $self=shift;
return $self->{"ticket"};
}

sub Ok {
    my $self=shift;
    my $aut=$self->{'aut'};
    my $ui=$self->{'ui'};

    $self->{"ok"}=0;

    my $account=$self->account();
    my $pass=$self->pass();
    my $ticket=$aut->ticket_get($account,$pass);

    if ($ticket->valid()) {
	$self->{"ok"}=1;
    }
    else {
	$ui->message_ok(_T("Not a valid account/user combination"),_T("Login"),$self);
	$self->pass("");
    }

    $self->{"ticket"}=$ticket;

    if ($self->{"ok"}) {
      $self->EndModal(wxID_OK);
    }
}

sub Cancel {
    my $self=shift;
    $self->{"ticket"}=new Aut::Ticket($self->account(),$self->pass());
    $self->{"ticket"}->invalidate();
    $self->EndModal(wxID_CANCEL);
}

# end of class __Aut__dlgLogin

1;

########################################################################

package __Aut__InputAccount;

use strict;

use Wx qw[:everything];
use Locale::Framework;
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);

use base qw(Wx::Dialog);

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__InputAccount::new

	$style = wxDEFAULT_DIALOG_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{label_3} = Wx::StaticText->new($self, -1, _T("Account:"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtAccount} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{label_4} = Wx::StaticText->new($self, -1, _T("Password:"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtPass} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{label_6} = Wx::StaticText->new($self, -1, _T("Password (Again):"), wxDefaultPosition, wxDefaultSize, );
	$self->{txtPassAgain} = Wx::TextCtrl->new($self, -1, "", wxDefaultPosition, wxDefaultSize, wxTE_PASSWORD);
	$self->{label_5} = Wx::StaticText->new($self, -1, _T("Authorization Level:"), wxDefaultPosition, wxDefaultSize, );
	$self->{chTicket} = Wx::Choice->new($self, -1, wxDefaultPosition, wxDefaultSize, [_T("choice 1")], );
	$self->{iaCancel} = Wx::Button->new($self, wxID_CANCEL, _T("&Cancel"));
	$self->{iaOK} = Wx::Button->new($self, wxID_OK, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__InputAccount::__set_properties

	$self->SetTitle(_T("Account Input"));
	$self->{chTicket}->SetSelection(0);
	$self->{iaOK}->SetDefault();

# end wxGlade

	EVT_BUTTON($self,$self->{iaOK},\&Ok);
	EVT_BUTTON($self,$self->{iaCancel},\&Cancel);
	
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__InputAccount::__do_layout

	$self->{ias} = Wx::GridSizer->new(4, 2, 5, 5);
	$self->{ias}->Add($self->{label_3}, 0, wxRIGHT|wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{txtAccount}, 0, wxEXPAND|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{label_4}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{txtPass}, 0, wxEXPAND|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{label_6}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{txtPassAgain}, 0, wxEXPAND|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{label_5}, 0, wxALIGN_RIGHT|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{chTicket}, 0, wxEXPAND|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{iaCancel}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->{ias}->Add($self->{iaOK}, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{ias});
	$self->{ias}->Fit($self);
	$self->{ias}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__InputAccount

sub set_aut {
  my ($self,$aut)=@_;
  $self->{"aut"}=$aut;
}

sub set_ui {
  my ($self,$ui)=@_;
  $self->{"ui"}=$ui;
}

sub account {
  my $self=shift;
return $self->{"txtAccount"}->GetValue();
}

sub  pass {
  my $self=shift;
return $self->{"txtPass"}->GetValue();
}

sub passagain {
  my $self=shift;
return $self->{"txtPassAgain"}->GetValue();
}

sub rights {
  my $self=shift;
  my $rights=$self->{"chTicket"}->GetStringSelection();
return $self->{"rights_untrans"}->{$rights};
}

sub set {
  my $self=shift;
  my $ticket=shift;
  $self->{'txtPass'}->SetValue($ticket->pass());
  $self->{'txtPassAgain'}->SetValue($ticket->pass());
  $self->{'txtAccount'}->SetValue($ticket->account());
  $self->{'chTicket'}->SetStringSelection($ticket->rights());
}

sub get {
  my $self=shift;
  my $ticket=shift;
  $ticket->set_pass($self->pass());
  $ticket->set_rights($self->rights());
}

sub set_mode {
  my $self=shift;
  $self->{'mode'}=shift;

  if ($self->{'mode'} eq "edit") {
    $self->{'txtAccount'}->Enable(0);
  }
}

sub initialize {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ui=$self->{"ui"};
  my @rights=$ui->levels();

  my %rights_untrans;
  
  $self->{"chTicket"}->Clear();
  for my $right (@rights) {
    $rights_untrans{_T($right)}=$right;
    $self->{"chTicket"}->Append(_T($right));
  }
  $self->{"rights_untrans"}=\%rights_untrans;
  $self->{"chTicket"}->SetSelection(0);
}

###

sub Ok {
  my $self=shift;
  my $ui=$self->{"ui"};
  my $aut=$self->{"aut"};

  ### Check validity of account and password

  my $account=$self->account();
  
  if ($account eq "") {
    $ui->message_ok(_T("You cannot use an empty account"));
  }
  elsif ($aut->exists($account) and ($self->{"mode"} eq "add")) {
    $ui->message_ok(_T("Please use a non existing account"));
  }
  elsif ($self->pass() ne $self->passagain()) {
    $ui->message_ok(_T("The given passwords don't match"));
  }
  else {
    my $msg=$aut->check_pass($self->pass());
    if ($msg ne "") {
      $ui->message_ok($msg);
    }
    else {
      $self->EndModal(wxID_OK);
    }
  }
}

sub Cancel {
  my $self=shift;
  $self->EndModal(wxID_CANCEL);
}


1;

########################################################################

package __Aut__AdminAccounts;

use strict;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use Wx::Event qw(EVT_CLOSE EVT_BUTTON);
use Locale::Framework;

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: __Aut__AdminAccounts::new

	$style = wxDIALOG_MODAL|wxCAPTION 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{lstAccounts} = Wx::ListCtrl->new($self, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxSUNKEN_BORDER);
	$self->{glAddAccount} = Wx::Button->new($self, -1, _T("&Add"));
	$self->{glRemoveAccount} = Wx::Button->new($self, -1, _T("&Remove"));
	$self->{glEditAccount} = Wx::Button->new($self, -1, _T("&Edit"));
	$self->{glOK} = Wx::Button->new($self, -1, _T("&OK"));

	$self->__set_properties();
	$self->__do_layout();

	return $self;

# end wxGlade
}


sub __set_properties {
	my $self = shift;

# begin wxGlade: __Aut__AdminAccounts::__set_properties

	$self->SetTitle(_T("Administer Accounts"));
	$self->{lstAccounts}->SetSize($self->{lstAccounts}->ConvertDialogSizeToPixels(Wx::Size->new(137, 168)));

# end wxGlade

	$self->{glOK}->SetDefault();

	EVT_BUTTON($self,$self->{glOK},\&Ok);
	EVT_BUTTON($self,$self->{glAddAccount},\&AddAccount);
	EVT_BUTTON($self,$self->{glRemoveAccount},\&RemoveAccount);
	EVT_BUTTON($self,$self->{glEditAccount},\&EditAccount);
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: __Aut__AdminAccounts::__do_layout

	$self->{grid_sizer_2} = Wx::FlexGridSizer->new(1, 2, 5, 5);
	$self->{sizer_1} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_2} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{grid_sizer_2}->Add($self->{lstAccounts}, 1, wxEXPAND, 0);
	$self->{sizer_1}->Add($self->{glAddAccount}, 0, 0, 0);
	$self->{sizer_1}->Add($self->{glRemoveAccount}, 0, 0, 0);
	$self->{sizer_1}->Add($self->{glEditAccount}, 0, 0, 0);
	$self->{sizer_2}->Add($self->{glOK}, 0, wxALIGN_BOTTOM, 0);
	$self->{sizer_1}->Add($self->{sizer_2}, 1, wxEXPAND, 0);
	$self->{grid_sizer_2}->Add($self->{sizer_1}, 1, wxEXPAND, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{grid_sizer_2});
	$self->{grid_sizer_2}->Fit($self);
	$self->{grid_sizer_2}->SetSizeHints($self);
	$self->{grid_sizer_2}->AddGrowableRow(0);
	$self->{grid_sizer_2}->AddGrowableCol(0);
	$self->Layout();
	$self->Centre();

# end wxGlade
}

# end of class __Aut__AdminAccounts

sub set_aut {
  my ($self,$aut)=@_;
  $self->{"aut"}=$aut;
}

sub set_ui {
  my ($self,$ui)=@_;
  $self->{"ui"}=$ui;
}

sub set_ticket {
  my ($self,$ticket)=@_;
  $self->{"ticket"}=$ticket;
}

sub initialize {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $idx=0;

  my $lst=$self->{"lstAccounts"};

  $lst->InsertColumn(1,_T("Account"));
  $lst->InsertColumn(2,_T("Rights"));

  my $count=0;
  my @tickets=undef;
  while ($count lt 3) {
    $count+=1;
    @tickets=$aut->ticket_all_admin_get();
    if (defined $tickets[0]) {
      last;
    }
  }

  if (not defined $tickets[0]) {
    return 0;
  }

  $self->{"tickets"}=\@tickets;

  for my $entry (@tickets) {
    $lst->InsertStringItem($idx,$entry->account());
    $lst->SetItem($idx,1,_T($entry->rights()));
    $idx+=1;
  }

  $self->retreive_config();

return 1;
}

sub commit_config {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ticket=$self->{"ticket"};
  my $width1=$self->{"lstAccounts"}->GetColumnWidth(0);
  my $width2=$self->{"lstAccounts"}->GetColumnWidth(1);

  $aut->set($ticket,"admin_col1",$width1);
  $aut->set($ticket,"admin_col2",$width2);
}

sub retreive_config {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ticket=$self->{"ticket"};

  my $width1=$aut->get($ticket,"admin_col1");
  my $width2=$aut->get($ticket,"admin_col2");

  if (defined $width1) { 
    $self->{"lstAccounts"}->SetColumnWidth(0,$width1);
  }
  if (defined $width2) { 
    $self->{"lstAccounts"}->SetColumnWidth(1,$width2);
  }

}

sub Ok {
  my $self=shift;
  $self->commit_config();
  $self->EndModal(wxID_OK);
}

sub AddAccount {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ui=$self->{"ui"};

  my $dlg=new __Aut__InputAccount($self,-1,_T("Add Account"));
  $dlg->set_mode("add");
  $dlg->set_aut($self->{"aut"});
  $dlg->set_ui($self->{"ui"});
  $dlg->initialize();

  if ($dlg->ShowModal()==wxID_OK) {
    my $account=$dlg->account();
    my $pass=$dlg->pass();
    my $rights=$dlg->rights();

    my $ticket=new Aut::Ticket($account,$pass);
    $ticket->set_rights($rights);

    $aut->ticket_create($ticket);

    # Adding the entry

    my $idx=$self->{"lstAccounts"}->GetItemCount();
    $self->{"lstAccounts"}->InsertStringItem($idx,$account);
    $self->{"lstAccounts"}->SetItem($idx,1,_T($rights));
    push @{$self->{"tickets"}},$ticket;
  }

  $dlg->Destroy();
  
}

sub findSelected {
  my $self=shift;
  my $item=$self->{"lstAccounts"}->GetNextItem(-1,wxLIST_NEXT_ALL,wxLIST_STATE_SELECTED);
return $item;
}

sub yesno {
  my $self=shift;
  my $text=shift;
  my $title=$self->GetTitle();

  my $dlg=new __Aut__YesNo($self,-1,$title);
  $dlg->set_label($text);
  $dlg->SetTitle($title);

  my $answer=$dlg->ShowModal();
#  my $answer=Wx::MessageBox($text,$title,wxYES_NO(),$self);

  $dlg->Destroy();

  if ($answer==wxYES) {
    return "yes";
  }
  else {
    return "no";
  }
}

sub RemoveAccount {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ui=$self->{"ui"};
  my $ticket=$self->{"ticket"};

  my $item=$self->findSelected();
  if ($item ge 0) {

    my $account=$self->{"lstAccounts"}->GetItemText($item);
    my $text=_T("Are you sure you want to remove this account")." ($account)";
    my $title=$self->GetTitle();

    if ($account eq $ticket->account()) {
      $ui->message_ok(_T("You cannot remove yourself")." ($account)",$title);
    }
     elsif ($self->yesno($text) eq "yes") {
       $self->{"lstAccounts"}->DeleteItem($item);
       my @tickets=@{$self->{"tickets"}};
       for my $t (@tickets) {
 	if ($account eq $t->account()) {
 	  $aut->ticket_remove($t);
 	  $t->invalidate();
 	}
       }
     }
  }
}

sub EditAccount {
  my $self=shift;
  my $aut=$self->{"aut"};
  my $ui=$self->{"ui"};
  my $ticket=$self->{"ticket"};

  my $item=$self->findSelected();
  if ($item ge 0) {

    my $account=$self->{"lstAccounts"}->GetItemText($item);
    my $title=$self->GetTitle();
    
    if ($account eq $ticket->account()) {
      $ui->message_ok(_T("You cannot edit yourself,\n".
			 "try just changing you password.")." ($account)",
		      $title);
    }
    else {
      my @tickets=@{$self->{"tickets"}};
      for my $t (@tickets) {
	if ($account eq $t->account()) {
	  my $dlg=new __Aut__InputAccount($self,-1,$title);
	  $dlg->set_mode("edit");
	  $dlg->set_aut($aut);
	  $dlg->set_ui($ui);
	  $dlg->initialize();
	  $dlg->set($t);
	  if ($dlg->ShowModal()==wxID_OK) {
	    $dlg->get($t);
	    $aut->ticket_update($t);
	    $self->{'lstAccounts'}->SetItem($item,1,_T($t->rights()))
	  }
	  last;
	}
      }
    }
  }
}

1;

