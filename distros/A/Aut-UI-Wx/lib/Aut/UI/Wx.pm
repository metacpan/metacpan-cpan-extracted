package Aut::UI::Wx;

use strict;
use Locale::Framework;
use Aut::UI::wxGUI;
use Aut;
use Aut::Ticket;
use Wx qw(:everything);

our $VERSION='0.02';

#####################################################
# Instantiation/Initialization
#####################################################

sub new {
  my $class=shift;
  my $parent=shift;
  my $self;

  if (defined $parent) {
    $self->{"parent"}=$parent;
  }
  else {
    $self->{"parent"}=undef;
  }

  $self->{"levels"}=undef;
  $self->{"admin"}=undef;

  bless $self,$class;
return $self;
}

sub initialize {
  my $self=shift;
  my $levels=shift;
  my $adminlevel=shift;

  $self->{"levels"}=$levels;
  $self->{"admin"}=$adminlevel;
}

sub levels {
  my $self=shift;
return @{$self->{"levels"}};
}

#####################################################
# Messages
#####################################################

sub message_ok {
  my $self=shift;
  my $text=shift;
  my $title=shift;
  my $parent=shift;

  if (not defined $title) { $title=_T("Alert"); }
  if (not defined $parent) { $parent=$self->{"parent"}; }
  
  #my $dlg=new __Aut__Msg($parent,-1,$title);
  #$dlg->set_label($text);
  #$dlg->ShowModal();
  #$dlg->Destroy();
  Wx::MessageBox( $text, $title, wxOK|wxCENTRE, $parent );
}

sub message {
  
}

#####################################################
# Password/account related
#####################################################

sub ask_pass {
  my $self=shift;
  my $aut=shift;
  my $text=shift;
  my $title=shift;
  my $parent=shift;
  my $pass;

  if (not defined $title) { $title=_T("Give password"); }
  if (not defined $parent) { $parent=$self->{"parent"}; }

  my $dlg=new __Aut__Entry($parent,-1,$title);

  $dlg->set_label($text);
  $dlg->SetTitle($title);
  if ($dlg->ShowModal()==wxID_OK) {
    $pass=$dlg->get_value();
    if ($pass eq "") {
      $pass=undef;
    }
  }
  else {
    $pass=undef;
  }

  $dlg->Destroy();

return $pass;
}

sub login {
  my $self=shift;
  my $aut=shift;
  my $title=shift;
  my $parent=shift;

  if (not defined $title) { $title=_T("Login"); }
  if (not defined $parent) { $parent=$self->{"parent"}; }

  my $dlg=new __Aut__dlgLogin($parent,-1,$title);
  $dlg->set_aut($aut);
  $dlg->set_ui($self);


  $dlg->ShowModal();

  my $ticket=$dlg->ticket();

  $dlg->Destroy();

return $ticket;
}

sub logout {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;
  $ticket->invalidate();
return 1;
}

sub change_pass {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;
  my $title=shift;
  my $parent=shift;

  if (not defined $title) { $title=_T("Change Password"); }
  if (not defined $parent) { $parent=$self->{"parent"}; }

  my $dlg=new __Aut__ChangePass($parent,-1,$title);
  $dlg->set_aut($aut);
  $dlg->set_ui($self);
  $dlg->set_account($ticket->account());
  $dlg->set_ticket($ticket);

  $dlg->ShowModal();

  $dlg->Destroy();
}

#####################################################
# Administration
#####################################################

sub admin {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;
  my $title=shift;
  my $parent=shift;

  if (not defined $title) { $title=_T("Account Administration"); }
  if (not defined $parent) { $parent=$self->{"parent"}; }

  my $dlg=new __Aut__AdminAccounts($parent,-1,$title);
  $dlg->set_aut($aut);
  $dlg->set_ui($self);
  $dlg->set_ticket($ticket);

  if ($dlg->initialize()) {
    $dlg->ShowModal();
  }

  $dlg->Destroy();
}

1;
__END__

=head1 NAME

Aut::UI::Wx - A wxPerl User Interface for the Aut framework.

=head1 ABSTRACT

This module provides a wxPerl User Interface for the authorization
framework (see L<Aut::UI::Console|Aut::UI::Console> for an interface
description).

=head1 DESCRIPTION

This User Interface has the same interface as C<Aut::UI::Console>.
Please refere to this interface for more information.

=head2 Interface

The interface extends the minimal C<Aut::UI::Console> interface.

=head2 Functions

=head3 C<new([parent]) --E<gt> Aut::UI::Wx>

The C<new> function of this interface accepts a 'parent' window id.
Which is normal for wxWidgets.

=head3 C<message_ok(text, [title], [parent]) --E<gt> void>

This function accepts beneath the standard C<text> also a C<title> and
a C<parent>. It will display a messagebox with an OK buttonthat is centered
on the parent.

=head3 C<ask_pass(text,[title],[parent]) --E<gt> string>

This function accepts beneath the standard C<text> also a C<title> and
a C<parent>. It will display a dialog asking for a password with a
C<Cancel> and an C<OK> button.

Returns 'undef' in case of a C<Cancel>, or if an empty password
has been given.

=head3 C<login(aut:Aut, [title], [parent]) --E<gt> Aut::Ticket>

See L<Aut::UI::Console|Aut::UI::Console>. This function displays
a dialog with a C<Cancel> and a C<OK> button. C<Cancel> will
yield an invalid ticket.

=head3 C<logout(aut:Aut, ticket:Aut::Ticket) --E<gt> void>

Currently only invalidates the ticket.

=head3 C<change_pass(aut:Aut, ticket:Aut::Ticket, [title], [parent]) --E<gt> void>

Changes the password, see L<Aut::UI::Console|Aut::UI::Console>.

=head3 C<admin(aut::Aut, ticket:Aut::Ticket, [title], [parent]) --E<gt> void>

Administers the accounts, see L<Aut::UI::Console|Aut::UI::Console>.


=head1 SEE ALSO

L<Aut|Aut>, L<Aut::Ticket|Aut::Ticket>, L<Aut::Backend::Conf|Aut::Backend::Conf>,
L<Aut::UI::Console|Aut::UI::Console>.

=head1 AUTHOR

Hans Oesterholt-Dijkema E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

(c)2004 Hans Oesterholt-Dijkema, This module is distributed
under Artistic license.


=cut
