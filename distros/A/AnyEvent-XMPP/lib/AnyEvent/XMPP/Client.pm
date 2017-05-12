package AnyEvent::XMPP::Client;
use strict;
use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::Util qw/stringprep_jid prep_bare_jid dump_twig_xml bare_jid cmp_bare_jid/;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Extendable;
use AnyEvent::XMPP::IM::Account;
use Object::Event;
use Scalar::Util;

#use XML::Twig;
#
#sub _dumpxml {
#   my $data = shift;
#   my $t = XML::Twig->new;
#   if ($t->safe_parse ("<deb>$data</deb>")) {
#      $t->set_pretty_print ('indented');
#      $t->print;
#      print "\n";
#   } else {
#      print "[$data]\n";
#   }
#}

our @ISA = qw/Object::Event AnyEvent::XMPP::Extendable/;

=head1 NAME

AnyEvent::XMPP::Client - XMPP Client abstraction

=head1 SYNOPSIS

   use AnyEvent::XMPP::Client;
   use AnyEvent;

   my $j = AnyEvent->condvar;

   my $cl = AnyEvent::XMPP::Client->new;
   $cl->start;

   $j->wait;

=head1 DESCRIPTION

This module tries to implement a straight forward and easy to
use API to communicate with XMPP entities. L<AnyEvent::XMPP::Client>
handles connections and timeouts and all such stuff for you.

For more flexibility please have a look at L<AnyEvent::XMPP::Connection>
and L<AnyEvent::XMPP::IM::Connection>, they allow you to control what
and how something is being sent more precisely.

=head1 METHODS

=head2 new (%args)

Following arguments can be passed in C<%args>:

=over 4

=item debug => 1

This will install callbacks which produce debugging output. This will
require L<XML::Twig> to be installed (as it is used for pretty printing
the "XML" output).

=back

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = { @_ };
   bless $self, $class;

   if ($self->{debug}) {
      $self->reg_cb (
         debug_recv => sub {
            my ($self, $acc, $data) = @_;
            printf "recv>> %s\n%s", $acc->jid, dump_twig_xml ($data)
         },
         debug_send => sub {
            my ($self, $acc, $data) = @_;
            printf "send<< %s\n%s", $acc->jid, dump_twig_xml ($data)
         },
      )
   }
   return $self;
}

sub add_extension {
   my ($self, $ext) = @_;
   $self->add_forward ($ext, sub {
      my ($self, $ext, $ev, $acc, @args) = @_;
      return if $ext->{inhibit_forward}->{$ev};
      $ext->_event ($ev, $acc->connection (), @args);
   });
}

=head2 add_account ($jid, $password, $host, $port, $connection_args)

This method adds a jabber account for connection with the JID C<$jid>
and the password C<$password>.

C<$host> and C<$port> can be undef and their default will be the domain of the
C<$jid> and the default for the C<port> parameter to the constructor of
L<AnyEvent::XMPP::Connection> (look there for details about DNS-SRV lookups).

C<$connection_args> must either be undef or a hash reference to
additional arguments for the constructor of the L<AnyEvent::XMPP::IM::Connection>
that will be used to connect the account.

Returns 1 on success and undef when the account already exists.

=cut

sub add_account {
   my ($self, $jid, $password, $host, $port, $connection_args) = @_;
   my $bj = prep_bare_jid $jid;

   my $acc = $self->{accounts}->{$bj};
   if ($acc) {
      $acc->{password} = $password;
      $acc->{host}     = $host;
      $acc->{port}     = $port;
      $acc->{args}     = $connection_args;
      return;
   }

   $acc =
      $self->{accounts}->{$bj} =
         AnyEvent::XMPP::IM::Account->new (
            jid      => $jid,
            password => $password,
            host     => $host,
            port     => $port,
            args     => $connection_args,
         );

   $self->event (added_account => $acc);

   $self->update_connections
      if $self->{started};

   $acc
}

=head2 start ()

This method initiates the connections to the XMPP servers.

=cut

sub start {
   my ($self) = @_;
   $self->{started} = 1;
   $self->update_connections;
}

=head2 update_connections ()

This method tries to connect all unconnected accounts.

=cut

sub update_connections {
   my ($self) = @_;

   Scalar::Util::weaken $self;

   for (values %{$self->{accounts}}) {
      my $acc = $_;

      if (!$acc->is_connected && !$self->{prep_connections}->{$acc->bare_jid}) {
         my %args = (initial_presence => 10);

         if (defined $self->{presence}) {
            if (defined $self->{presence}->{priority}) {
               $args{initial_presence} = $self->{presence}->{priority};
            }
         }

         my $con = $acc->spawn_connection (%args);
         $self->{prep_connections}->{$acc->bare_jid} = $con;

         $con->add_forward ($self, sub {
            my ($con, $self, $ev, @arg) = @_;
            $self->_event ($ev, $acc, @arg);
         });

         $con->reg_cb (
            session_ready => sub {
               my ($con) = @_;
               delete $self->{prep_connections}->{$acc->bare_jid};
               $self->event (connected => $acc);
               if (defined $self->{presence}) {
                  $con->send_presence (undef, undef, %{$self->{presence} || {}});
               }
               $con->unreg_me
            },
            disconnect => sub {
               my ($con, $h, $p, $err) = @_;
               $self->event (connect_error => $acc, $err);
               delete $self->{prep_connections}->{$acc->bare_jid};
               $con->unreg_me;
            },
            after_disconnect => sub {
               my ($con, $h, $p, $err) = @_;
               $con->remove_forward ($self);
            }
         );

         $con->connect;
      }
   }
}

=head2 disconnect ($msg)

Disconnect all accounts.

=cut

sub disconnect {
   my ($self, $msg) = @_;
   for my $acc (values %{$self->{accounts}}) {
      if ($acc->is_connected) { $acc->connection ()->disconnect ($msg) }
   }
}

=head2 remove_accounts ($reason)

Removes all accounts and disconnects. C<$reason> should be some descriptive
reason why this account was removed (just for logging purposes).

=cut

sub remove_accounts {
   my ($self, $reason) = @_;
   for my $acc (keys %{$self->{accounts}}) {
      $self->remove_account ($acc, $reason);
   }
}

=head2 remove_account ($acc, $reason)

Removes and disconnects account C<$acc> (which is a L<AnyEvent::XMPP::IM::Account> object).
The reason for the removal can be given via C<$reason>.

=cut

sub remove_account {
   my ($self, $acc, $reason) = @_;
   my $acca = $self->{accounts}->{$acc};
   $self->event (removed_account => $acca);
   if ($acca->is_connected) { $acca->connection ()->disconnect ($reason) }
   delete $self->{accounts}->{$acc};
}

=head2 set_accounts (%$accounts)

Sets the set of (to be connected) accounts. C<$accounts> must be a hash
reference which contains the JIDs of the accounts as keys and the values for
C<$password>, C<$domain>, C<$port> and C<$connection_args> as described in
C<add_account> above.

If the account is not yet connected it will be connected on the next call to
C<update_connections> and if an account is connected that is not in
C<$accounts> it will be disconnected.

=cut

sub set_accounts {
   my ($self, $accounts) = @_;


   for my $accid (keys %{$self->{accounts}}) {
      my $acca = $self->{accounts}->{$accid};
      if (!grep { cmp_bare_jid ($acca->jid, $_) } keys %$accounts) {
         $self->remove_account ($accid, "removed from set");
      }
   }

   for my $acc_jid (keys %$accounts) {
      $self->add_account ($acc_jid, @{$accounts->{$acc_jid}});
   }
}

=head2 send_message ($msg, $dest_jid, $src, $type)

Sends a message to the destination C<$dest_jid>.
C<$msg> can either be a string or a L<AnyEvent::XMPP::IM::Message> object.
If C<$msg> is such an object C<$dest_jid> is optional, but will, when
passed, override the destination of the message.

NOTE: C<$dest_jid> is transformed into a bare JID and the routing
is done by the conversation tracking mechanism which keeps track of
which resource should get the message.

C<$src> is optional. It specifies which account to use
to send the message. If it is not passed L<AnyEvent::XMPP::Client> will try
to find an account itself. First it will look through all rosters
to find C<$dest_jid> and if none found it will pick any of the accounts that
are connected.

C<$src> can either be a JID or a L<AnyEvent::XMPP::IM::Account> object as returned
by C<add_account> and C<get_account>.

C<$type> is optional but overrides the type of the message object in C<$msg>
if C<$msg> is such an object.

C<$type> should be 'chat' for normal chatter. If no C<$type> is specified
the type of the message defaults to the value documented in L<AnyEvent::XMPP::IM::Message>
(should be 'normal').

=cut

sub send_message {
   my ($self, $msg, $dest_jid, $src, $type) = @_;

   unless (ref $msg) {
      $msg = AnyEvent::XMPP::IM::Message->new (body => $msg);
   }

   if (defined $dest_jid) {
      my $jid = stringprep_jid $dest_jid
         or die "send_message: \$dest_jid is not a proper JID";
      $msg->to ($jid);
   }

   $msg->type ($type) if defined $type;

   my $srcacc;
   if (ref $src) {
      $srcacc = $src;
   } elsif (defined $src) {
      $srcacc = $self->get_account ($src)
   } else {
      $srcacc = $self->find_account_for_dest_jid ($dest_jid);
   }

   unless ($srcacc && $srcacc->is_connected) {
      die "send_message: Couldn't get connected account for sending"
   }

   $srcacc->send_tracked_message ($msg);
}

=head2 get_account ($jid)

Returns the L<AnyEvent::XMPP::IM::Account> account object for the JID C<$jid>
if there is any such account added. (returns undef otherwise).

=cut

sub get_account {
   my ($self, $jid) = @_;
   $self->{accounts}->{prep_bare_jid $jid}
}

=head2 get_accounts ()

Returns a list of L<AnyEvent::XMPP::IM::Account>s.

=cut

sub get_accounts {
   my ($self) = @_;
   values %{$self->{accounts}}
}

=head2 get_connected_accounts ()

Returns a list of connected L<AnyEvent::XMPP::IM::Account>s.

Same as:

  grep { $_->is_connected } $client->get_accounts ();

=cut

sub get_connected_accounts {
   my ($self, $jid) = @_;
   my (@a) = grep $_->is_connected, values %{$self->{accounts}};
   @a
}

=head2 find_account_for_dest_jid ($jid)

This method tries to find any account that has the contact C<$jid>
on his roster. If no account with C<$jid> on his roster was found
it takes the first one that is connected. (Return value is a L<AnyEvent::XMPP::IM::Account>
object).

If no account is connected it returns undef.

=cut

sub find_account_for_dest_jid {
   my ($self, $jid) = @_;

   my $any_acc;
   for my $acc (values %{$self->{accounts}}) {
      next unless $acc->is_connected;

      # take "first" active account
      $any_acc = $acc unless defined $any_acc;

      my $roster = $acc->connection ()->get_roster;
      if (my $c = $roster->get_contact ($jid)) {
         return $acc;
      }
   }

   $any_acc
}

=head2 get_contacts_for_jid ($jid)

This method returns all contacts that we are connected to.
That means: It joins the contact lists of all account's rosters
that we are connected to.

=cut

sub get_contacts_for_jid {
   my ($self, $jid) = @_;
   my @cons;
   for ($self->get_connected_accounts) {
      my $roster = $_->connection ()->get_roster ();
      my $con = $roster->get_contact ($jid);
      push @cons, $con if $con;
   }
   return @cons;
}

=head2 get_priority_presence_for_jid ($jid)

This method returns the presence for the contact C<$jid> with the highest
priority.

If the contact C<$jid> is on multiple account's rosters it's undefined which
roster the presence belongs to.

=cut

sub get_priority_presence_for_jid {
   my ($self, $jid) = @_;

   my $lpres;
   for ($self->get_connected_accounts) {
      my $roster = $_->connection ()->get_roster ();
      my $con = $roster->get_contact ($jid);
      next unless defined $con;
      my $pres = $con->get_priority_presence ($jid);
      next unless defined $pres;
      if ((not defined $lpres) || $lpres->priority < $pres->priority) {
         $lpres = $pres;
      }
   }

   $lpres
}

=head2 set_presence ($show, $status, $priority)

This sets the presence of all accounts.  For a meaning of C<$show>, C<$status>
and C<$priority> see the description of the C<%attrs> hash in
C<send_presence> method of L<AnyEvent::XMPP::Writer>.

=cut

sub set_presence {
   my ($self, $show, $status, $priority) = @_;

   $self->{presence} = {
      show     => $show,
      status   => $status,
      priority => $priority
   };

   for my $ac ($self->get_connected_accounts) {
      my $con = $ac->connection ();
      $con->send_presence (undef, undef, %{$self->{presence}});
   }
}

=head1 EVENTS

In the following event descriptions the argument C<$account>
is always a L<AnyEvent::XMPP::IM::Account> object.

All events from L<AnyEvent::XMPP::IM::Connection> are forwarded to the client,
only that the first argument for every event is a C<$account> object.

Aside fom those, these events can be registered on with C<reg_cb>:

=over 4

=item connected => $account

This event is sent when the C<$account> was successfully connected.

=item connect_error => $account, $reason

This event is emitted when an error occured in the connection process for the
account C<$account>.

=item error => $account, $error

This event is emitted when any error occured while communicating
over the connection to the C<$account> - after a connection was established.

C<$error> is an error object which is derived from L<AnyEvent::XMPP::Error>.
It will reveal human readable information about the error by calling the C<string ()>
method (which returns a descriptive error string about the nature of the error).

=item added_account => $account

Called whenever an account is added.

=item removed_account => $account

Called whenever an account is removed.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::Client
