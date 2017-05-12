package Aut::UI::Console;

# $Id: Console.pm,v 1.4 2004/04/10 09:33:58 cvs Exp $ 

use strict;
use Term::ReadKey;
use Locale::Framework;
use Aut;
use Aut::Ticket;

#####################################################
# Instantiation/Initialization
#####################################################

sub new {
  my $class=shift;
  my $self;

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

#####################################################
# Messages
#####################################################

sub message_ok {
  my $self=shift;
  my $text=shift;
  print "$text\n\n"._T("Press enter to continue").">>";
  ReadMode(2);
  ReadLine(0);
  ReadMode(0);
  print "\n";
}

sub message {
  my $self=shift;
  my $text=shift;
  print "$text\n";
}

#####################################################
# Password/Account related
#####################################################

sub ask_pass {
  my $self=shift;
  my $aut=shift;
  my $text=shift;

  print "$text >>";

  ReadMode(2);
  my $pass=ReadLine(0);
  chomp $pass;
  ReadMode(0);
  print "\n";

  if ($pass eq "") { $pass=undef; }

return $pass;
}

sub login {
  my $self=shift;
  my $aut=shift;

  if ($aut->has_accounts()) {
    my $ticket;

    print _T("login")."\n\n";

    for (1..3) {

      print _T("account")."  >>";
      ReadMode(1);
      my $account=ReadLine(0);
      ReadMode(0);
      chomp $account;

      my $pass=$self->ask_pass($aut,_T("password"));
      $ticket=$aut->ticket_get($account,$pass);

      if ($ticket->valid()) {
	last;
      }
      else {
	print _T("Invalid account/password combination")."\n";
	print _T("Reported error: "),$aut->last_error(),"\n\n";
      }
    }

    return $ticket;
  }
  else {
    return undef;
  }
}

sub logout {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;
return 1;
}

sub change_pass {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;

  my $account=$ticket->account();

  print "\n";
  print _T("Change password for $account")."\n";
  print "\n";

  my $oldpass=$self->ask_pass($aut,_T("Old password "));
  my $newpass=$self->ask_pass($aut,_T("New password "));
  my $again  =$self->ask_pass($aut,_T("Again        "));

  my $pass=$ticket->pass();
  if ($pass ne $oldpass) {
    $self->message_ok(_T("You didn't give a valid (old) password"));
    return 0;
  }
  else {
    if ($newpass ne $again) {
      $self->message_ok(_T("New passswords don't match"));
      return 0;
    }
    else {
      my $msg=$aut->check_pass($newpass);
      if ($msg ne "") {
	$self->message_ok($msg);
	return 0;
      }
      else {
	$ticket->set_pass($newpass);
	$aut->ticket_update($ticket);
	return 1;
      }
    }
  }
}


#####################################################
# Administration
#####################################################

sub admin {
  my $self=shift;
  my $aut=shift;
  my $ticket=shift;

  my $choice="";
  while ($choice ne "0") {
    print "\n";
    print _T("Account Administration")."\n";
    print "\n";
    print "1. "._T("Add an account")."\n";
    print "2. "._T("Change password for an account")."\n";
    print "3. "._T("Change rights for an account")."\n";
    print "4. "._T("Delete an account")."\n";
    print "\n";
    print "0. "._T("End")."\n\n";

    ReadMode(1);
    print ">>";$choice=ReadLine(0);
    chomp $choice;

    if ($choice eq "1") {
      print "\n";
      print _T("account  ").">>";my $account=ReadLine(0);chomp $account;
      if ($account eq "") {
	print _T("  Empty account, aborting")."\n";
      }
      else {
	print _T("  Checking existence of ").$account,"\n";
	if ($aut->exists($account)) {
	  $self->message_ok( _T("  Account already exists, aborting"));
	}
	else {
	  my $pass=$self->ask_pass($aut,_T("password        "));
	  my $passagain=$self->ask_pass($aut,_T("password (again)"));

	  my $msg=$aut->check_pass($pass);

	  if ($pass eq "") {
	    $self->message_ok(_T("  Empty password, aborting"));
	  }
	  elsif ($pass ne $passagain) {
	    $self->message_ok(_T("  Given passwords are not equal, aborting"));
	  }
	  elsif ($msg ne "") {
	    $self->message_ok("  $msg");
	  }
	  else {
	    my $rights=$self->choose_rights();
	    if (not defined $rights) {
	      $self->message_ok(_T("  No rights given, aborting"));
	    }
	    else {
	      my $ticket=new Aut::Ticket($account,$pass);
	      $ticket->set_rights($rights);
	      print _T("  Creating account: "),$account,_T(", rights: "),$rights;
	      $aut->ticket_create($ticket);
	    }
	  }
	}
      }
    }
    elsif ($choice eq "2") {
      print "\n";
      print _T("Change password for an account\n");
      print "\n";
      $self->list_accounts($aut);
      print _T("account  ").">>";my $account=ReadLine(0);chomp $account;
      if ($aut->exists($account)) {
	  my $pass=$self->ask_pass($aut,_T("password        "));
	  my $passagain=$self->ask_pass($aut,_T("password (again)"));

	  my $msg=$aut->check_pass($pass);

	  if ($pass eq "") {
	    $self->message_ok(_T("  Empty password, aborting"));
	  }
	  elsif ($pass ne $passagain) {
	    $self->message_ok(_T("  Given passwords are not equal, aborting"));
	  }
	  elsif ($msg ne "") {
	    $self->message_ok("  $msg");
	  }
	  else { # Try to change the password
	    my $ticket=$aut->ticket_admin_get($account);
	    if ($ticket->valid()) {
	      print _T("  Changing password to new one")."\n";
	      $ticket->set_pass($pass);
	      print _T("  Updating ticket")."\n";
	      $aut->ticket_update($ticket);
	      print _T("  Done\n");
	    }
	  }
      }
    }
    elsif ($choice eq "3") {
      print "\n";
      print _T("Change rights for an account")."\n";
      print "\n";
      $self->list_accounts($aut);
      print _T("account  ").">>";my $account=ReadLine(0);chomp $account;
      if ($aut->exists($account)) {
	my $rights=$self->choose_rights();
	if (defined $rights) {
	  my $ticket=$aut->ticket_admin_get($account);
	  if ($ticket->valid()) {
	    print _T("  Changing rights to $rights\n");
	    $ticket->set_rights($rights);
	    print _T("  Updating ticket\n");
	    $aut->ticket_update($ticket);
	    print _T("  Done\n");
	  }
	}
      }
    }
    elsif ($choice eq "4") {
      print "\n";
      print _T("Remove an account")."\n";
      print "\n";
      $self->list_accounts($aut);
      print _T("account  ").">>";my $account=ReadLine(0);chomp $account;

      if ($account eq $ticket->account()) {
	$self->message_ok(_T("You cannot delete yourself"));
      }
      elsif ($aut->exists($account)) {
	print _T("Remove account yes/no? ").">>";my $yesno=ReadLine(0);chomp $yesno;
	if (lc($yesno) eq "yes") {
	  print _T("  Removing account: ").$account."\n";
	  my $ticket=new Aut::Ticket($account,"");
	  $aut->ticket_remove($ticket);
	}
	else {
	  $self->message_ok(_T("You need to answer a full 'yes' to get accounts removed"));
        }
      }
    }
  }
}

sub list_accounts {
  my $self=shift;
  my $aut=shift;
  my @accounts=$aut->list_accounts();
  my $perline=3;
  my $cnt=0;

  for my $a (@accounts) {
    printf("%-20s",$a);
    $cnt+=1;
    if ($cnt%$perline==0) {
      print "\n";
    }
  }
  print "\n";
}

sub choose_rights {
  my $self=shift;
  my @rights=@{$self->{"levels"}};

  my $nrights=@rights;

  print "\n";
  print _T("Choose rights from menu")."\n";
  print "\n";

  for (1..$nrights) {
    print "$_. $rights[$_-1]\n";
  }

  print ">>";
  my $choice=ReadLine(0);chomp $choice;

  if (($choice gt 0) and ($choice le $nrights)) {
    return $rights[$choice-1];
  }
  else {
    return undef;
  }
}


1;
__END__

=head1 NAME

Aut::UI::Console - Reference implementation for a User Interface to L<Aut>

=head1 ABSTRACT

This is a very simple Console based reference implementation for a User Interface
to the L<Aut Framework|Aut>.

=head1 DESCRIPTION

C<Aut::UI:...> classes are user interface classes to Aut. They are called through
the Aut module. Most methods that have to be implemented, when called through
an Aut object are given this same object as an argument, to make it possible 
to call back into the Aut object. 

=head2 Note!

=over 1

=item *

The user interface must take care that the last admin account is not deleted.
This user interface does this by not removing the account currently in use.

=item *

The admin() function can always be called. The calling program must take care
that the function is not allowed for non adminlevel accounts.

=back

=head2 Instantiating and initializing

=head3 C<new() --E<gt> Aut::UI::Console>

=over 1

This method instantiates a new Aut::UI::Console object.

=back

=head3 C<initialize(level::\(list authorization_level:string, admin_level:string) --E<gt> void>

=over 1

This method is called from an Aut object to initialize the user
interface with a list of possible authorization levels and the
level that has administrator rights.

=back

=head2 Message related functions

=head3 C<message_ok(msg:string) --E<gt> void>

=over 1

This function displays message 'msg' and waits for input (OK button, Enter,
whatever is standard for the given UI environment).

=back

=head2 Password related

=head3 C<ask_pass(aut:Aut, msg:string [,any]) --E<gt> string>

=over 1

This function displays message 'msg', displays a appropriate prompt and
asks the user to input his/hers password.

Returns the password that has been entered, or C<undef>, if an empty
password has been given.

=back

=head3 C<login(aut:Aut [,any]) --E<gt> Aut::Ticket>

=over 1

This function askes account and password and returns a ticket for
the given account. The ticket can be retreived from the Aut object,
using the C<aut-E<gt>ticket_get> function.

=back

=head3 C<logout(aut:Aut, ticket:Aut::Ticket,  [,any]) --E<gt> boolean>

=over 1

This function can be used to inform the user about logging out and
check certain properties before logging out (e.g. if the user
confirms logging out). It returns true, if the user can logout,
false otherwise.

=back


=head3 C<change_pass(aut:Aut, ticket:Aut::Ticket, [,any] --E<gt> void>

=over 1

This function is used to enable changing a password for a given ticket.
The function must ask the password two times, validate their equalness,
validate the password through C<aut-E<gt>check_pass()> and if valid,
store the new password in the ticket using C<ticket-E<gt>set_pass(pass)> and update
the ticket in the backend using C<aut-E<gt>ticket_update(ticket)>.

=back

=head2 Administration 

=head3 C<admin(aut:Aut, ticket, [,any]) --E<gt> void>

=over 1

This function is used to do account administration. It takes the aut system as
argument and the ticket of the administrator that is going to do administration.
It must provide following functionality:

=over 1

=item 1

Adding new accounts.

=item 2

Changing the password for an account.

=item 3

Changing the rights for an account.

=item 4

Delete an account.

=back

See the implementation of Aut::UI::Console for a reference on how this is
done using the given C<aut> object. 

=back

=head1 SEE ALSO

<Aut Framework|Aut>.

=head1 AUTHOR

Hans Oesterholt-Dijkema E<lt>oesterhol@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under Artistic license

=cut
