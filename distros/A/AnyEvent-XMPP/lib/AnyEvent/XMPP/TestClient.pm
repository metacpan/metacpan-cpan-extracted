package AnyEvent::XMPP::TestClient;
use strict;
no warnings;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Util qw/stringprep_jid prep_bare_jid dump_twig_xml/;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use Test::More;

=head1 NAME

AnyEvent::XMPP::TestClient - XMPP Test Client for tests

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is a helper module to ease the task of testing.
If you want to run the developer test suite you have to set the environment
variable C<NET_XMPP2_TEST> to something like this:

   NET_XMPP2_TEST="test_me@your_xmpp_server.tld:secret_password"

Most tests will try to connect two accounts, so please take a server
that allows two connections from the same IP.

If you also want to run the MUC tests (see L<AnyEvent::XMPP::Ext::MUC>)
you also need to setup the environment variable C<NET_XMPP2_TEST_MUC>
to contain the domain of a MUC service:

   NET_XMPP2_TEST_MUC="conference.your_xmpp_server.tld"

If you see some tests fail and want to know more about the protocol flow
you can enable the protocol debugging output by setting C<NET_XMPP2_TEST_DEBUG>
to '1':

   NET_XMPP2_TEST_DEBUG=1

(NOTE: You will only see the output of this by running a single test)

If one of the tests takes longer than the preconfigured 20 seconds default
timeout in your setup you can set C<NET_XMPP2_TEST_TIMEOUT>:

   NET_XMPP2_TEST_TIMEOUT=60  # for a 1 minute timeout

=head1 CLEANING UP

If the tests went wrong somewhere or you interrupted the tests you might
want to delete the accounts from the server manually, then run:

   perl t/z_*_unregister.t

=head1 MANUAL TESTING

If you just want to run a single test yourself, just execute the register
test before doing so:

   perl t/z_00_register.t

And then you could eg. run:

   perl t/z_03_iq_auth.t

=head1 METHODS

=head2 new (%args)

Following arguments can be passed in C<%args>:

=over 4

=back

=cut

sub new_or_exit {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = {
      timeout      => 20,
      finish_count =>  1,
      @_
   };

   if ($ENV{NET_XMPP2_TEST_DEBUG}) {
      $self->{debug} = 1;
   }

   if ($ENV{NET_XMPP2_TEST_TIMEOUT}) {
      $self->{timeout} = $ENV{NET_XMPP2_TEST_TIMEOUT};
   }

   $self->{tests};

   if ($self->{muc_test} && not $ENV{NET_XMPP2_TEST_MUC}) {
      plan skip_all => "environment var NET_XMPP2_TEST_MUC not set! Set it to a conference!";
      exit;
   }

   if ($ENV{NET_XMPP2_TEST}) {
      plan tests => $self->{tests} + 1
   } else {
      plan skip_all => "environment var NET_XMPP2_TEST not set! (see also AnyEvent::XMPP::TestClient)!";
      exit;
   }

   bless $self, $class;
   $self->init;
   $self
}

sub init {
   my ($self) = @_;
   $self->{condvar} = AnyEvent->condvar;
   $self->{timeout} =
      AnyEvent->timer (
         after => $self->{timeout}, cb => sub {
            $self->{error} .= "Error: Test Timeout\n";
            $self->{condvar}->broadcast;
         }
      );

   my $cl = $self->{client} = AnyEvent::XMPP::Client->new (debug => $self->{debug} || 0);
   my ($jid, $password) = split /:/, $ENV{NET_XMPP2_TEST}, 2;

   $self->{jid}      = $jid;
   $self->{jid2}     = "2nd_" . $jid;
   $self->{password} = $password;
   $cl->add_account ($jid, $password, undef, undef, $self->{connection_args});

   if ($self->{two_accounts}) {
      my $cnt = 0;
      $cl->reg_cb (session_ready => sub {
         my ($cl, $acc) = @_;

         if (++$cnt > 1) {
            $self->{acc}  = $cl->get_account ($self->{jid});
            $self->{acc2} = $cl->get_account ($self->{jid2});
            $cl->event ('two_accounts_ready', $acc);
            $self->state_done ('two_accounts_ready');
         }
      });

      $cl->add_account ("2nd_".$jid, $password, undef, undef, $self->{connection_args});

   } else {
      $cl->reg_cb (before_session_ready => sub {
         my ($cl, $acc) = @_;
         $self->{acc} = $acc;
         $self->state_done ('one_account_ready');
      });
   }

   if ($self->{muc_test} && $ENV{NET_XMPP2_TEST_MUC}) {
      $self->{muc_room} = "test_nxmpp2@" . $ENV{NET_XMPP2_TEST_MUC};

      my $disco = $self->{disco} = $self->instance_ext ('AnyEvent::XMPP::Ext::Disco');
      my $muc   = $self->{muc}   = $self->instance_ext ('AnyEvent::XMPP::Ext::MUC', disco => $disco);

      $cl->reg_cb (
         two_accounts_ready => sub {
            my ($cl, $acc) = @_;
            my $cnt = 0;
            my ($room1, $room2);

            $muc->join_room ($self->{acc}->connection, $self->{muc_room}, "test1");
            my $rid;
            $rid = $muc->reg_cb (
               join_error => sub {
                  my ($muc, $room, $error) = @_;
                  $self->{error} .= "Error: Couldn't join $self->{muc_room}: ".$error->string."\n";
                  $self->{condvar}->broadcast;
               },
               enter => sub {
                  my ($muc, $room, $user) = @_;

                  if ($room->get_me->nick eq 'test1') {
                     $self->{user} = $user;
                     $self->{room} = $room;

                     $muc->join_room ($self->{acc2}->connection, $self->{muc_room}, "test2");
                  } else {
                     $self->{user2} = $user;
                     $self->{room2} = $room;

                     $muc->unreg_cb ($rid);
                     $cl->event ('two_rooms_joined', $acc);
                     $self->state_done ('two_rooms_joined');
                  }
               }
            );
         }
      );
   }

   $cl->reg_cb (error => sub {
      my ($cl, $acc, $error) = @_;

      $self->{error} .= "Error: " . $error->string . "\n";
      $self->finish unless $self->{continue_on_error};
   });

   $cl->start;
}

sub checkpoint {
   my ($self, $name, $cnt, $cb) = @_;
   $self->{checkpoints}->{$name} = [$cnt, $cb];
}

sub reached_checkpoint {
   my ($self, $name) = @_;
   my $chp = $self->{checkpoints}->{$name}
      or die "no such checkpoint defined: $name";

   $chp->[0]--;
   if ($chp->[0] <= 0) {
      $chp->[1]->();
      delete $self->{checkpoints}->{$name};
   }
}

sub main_account { ($_[0]->{jid}, $_[0]->{password}) }

sub client { $_[0]->{client} }

sub tests { $_[0]->{tests} }

sub instance_ext {
   my ($self, $ext, @args) = @_;

   eval "require $ext; 1";
   if ($@) { die "Couldn't load '$ext': $@" }
   my $eo = $ext->new (@args);
   $self->{client}->add_extension ($eo);
   $eo
}

sub finish {
   my ($self) = @_;

   $self->{_cur_finish_cnt}++;
   if ($self->{finish_count} <= $self->{_cur_finish_cnt}) {
      $self->{condvar}->broadcast;
   }
}

sub wait {
   my ($self) = @_;
   $self->{condvar}->wait;

   if ($self->error) {
      fail ("error free");
      diag ($self->error);
   } else {
      pass ("error free");
   }
}

sub error { $_[0]->{error} }

my %STATE;

sub state {
   my $self = shift;
   my $prec = [];
   if (ref $_[0] eq 'ARRAY') {
      $prec = shift;
   }
   my ($state, $args, $cond, $cb) = @_;
   $STATE{$state} = { name => $state, args => $args, cond => $cond, cb => $cb, done => 0, prec => $prec };

   $self->state_check ();
}

sub state_done {
   my ($self, $state) = @_;
   $STATE{$state} ||= {
      name => $state, args => undef, cond => undef, cb => undef, done => 0
   };
   $STATE{$state}->{done} = 1;
   if ($ENV{ANYEVENT_XMPP_MAINTAINER_TEST_DEBUG}) {
      warn "STATE '$state' DONE\n";
   }

   $self->state_check ();
}

sub state_check {
   my ($self, $state, $cb) = @_;
   if (defined $state && $STATE{$state} && !$STATE{$state}->{done}) {
      $cb->($STATE{$state}->{args});
   }

   RESTART: {
      for my $s (grep { !$_->{done} } values %STATE) {
         if (@{$s->{prec} || []}
             && grep { !$STATE{$_} || !$STATE{$_}->{done} } @{$s->{prec} || []}) {
            next;
         }

         if (!defined ($s->{cond}) || $s->{cond}->($s->{args})) {
            if ($ENV{ANYEVENT_XMPP_MAINTAINER_TEST_DEBUG}) {
               print "STATE '$s->{name}' OK (".join (',', @{$s->{prec} || []}).")\n";
            }
            $s->{cb}->($s->{args}) if defined $s->{cb};
            $s->{done} = 1;
            goto RESTART;
         }
      }
   }

   if ($ENV{ANYEVENT_XMPP_MAINTAINER_TEST_DEBUG}) {
      warn "STATE STATUS:\n";
      for my $s (keys %STATE) {
         warn "\t$s => $STATE{$s}->{done}\t"
            . join (',', map {
                  "$_:$STATE{$s}->{args}->{$_}" } keys %{$STATE{$s}->{args}}
            )."\n";
      }
   }
}

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::TestClient
