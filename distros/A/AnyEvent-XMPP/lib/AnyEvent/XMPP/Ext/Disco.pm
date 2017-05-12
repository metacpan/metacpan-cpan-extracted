package AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/simxml/;
use AnyEvent::XMPP::Ext::Disco::Items;
use AnyEvent::XMPP::Ext::Disco::Info;
use AnyEvent::XMPP::Ext;
use strict;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 NAME

AnyEvent::XMPP::Ext::Disco - Service discovery manager class for XEP-0030

=head1 SYNOPSIS

   use AnyEvent::XMPP::Ext::Disco;

   my $con = AnyEvent::XMPP::IM::Connection->new (...);
   $con->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
   $disco->request_items ($con, 'romeo@montague.net', undef,
      sub {
         my ($disco, $items, $error) = @_;
         if ($error) { print "ERROR:" . $error->string . "\n" }
         else {
            ... do something with the $items ...
         }
      }
   );

=head1 DESCRIPTION

This module represents a service discovery manager class.
You make instances of this class and get a handle to send
discovery requests like described in XEP-0030.

It also allows you to setup a disco-info/items tree
that others can walk and also lets you publish disco information.

This class is derived from L<AnyEvent::XMPP::Ext> and can be added as extension to
objects that implement the L<AnyEvent::XMPP::Extendable> interface or derive from
it.

=head1 METHODS

=over 4

=item B<new (%args)>

Creates a new disco handle.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { @_ }, $class;
   $self->init;
   $self
}

sub init {
   my ($self) = @_;

   $self->set_identity (client => console => 'AnyEvent::XMPP');
   $self->enable_feature (xmpp_ns ('disco_info'));
   $self->enable_feature (xmpp_ns ('disco_items'));

   # and features supported by AnyEvent::XMPP in general:
   $self->enable_feature (AnyEvent::XMPP::Ext::disco_feature_standard ());

   $self->{cb_id} = $self->reg_cb (
      iq_get_request_xml => sub {
         my ($self, $con, $node, $handled) = @_;

         if ($self->handle_disco_query ($con, $node)) {
            $$handled = 1;
         }
      }
   );
}

=item B<set_identity ($category, $type, $name)>

This sets the identity of the top info node.

C<$name> is optional and can be undef.  Please note that C<$name> will
overwrite all previous set names! If C<$name> is undefined then
no previous set name is overwritten.

For a list of valid identites look at:

   http://www.xmpp.org/registrar/disco-categories.html

Valid identity C<$type>s for C<$category = "client"> may be:

   bot
   console
   handheld
   pc
   phone
   web

=cut

sub set_identity {
   my ($self, $category, $type, $name) = @_;
   $self->{iden_name} = $name;
   $self->{iden}->{$category}->{$type} = 1;
}

=item B<unset_identity ($category, $type)>

This function removes the identity C<$category> and C<$type>.

=cut

sub unset_identity {
   my ($self, $category, $type) = @_;
   delete $self->{iden}->{$category}->{$type};
}

=item B<enable_feature ($uri)>

This method enables the feature C<$uri>, where C<$uri>
should be one of the values from the B<Name> column on:

   http://www.xmpp.org/registrar/disco-features.html

These features are enabled by default:

   http://jabber.org/protocol/disco#info
   http://jabber.org/protocol/disco#items

You can pass also a list of features you want to enable to C<enable_feature>!

=cut

sub enable_feature {
   my ($self, @feature) = @_;
   $self->{feat}->{$_} = 1 for @feature;
}

=item B<disable_feature ($uri)>

This method enables the feature C<$uri>, where C<$uri>
should be one of the values from the B<Name> column on:

   http://www.xmpp.org/registrar/disco-features.html

You can pass also a list of features you want to disable to C<disable_feature>!

=cut

sub disable_feature {
   my ($self, @feature) = @_;
   delete $self->{feat}->{$_} for @feature;
}

sub write_feature {
   my ($self, $w, $var) = @_;

   $w->emptyTag ([xmpp_ns ('disco_info'), 'feature'], var => $var);
}

sub write_identity {
   my ($self, $w, $cat, $type, $name) = @_;

   $w->emptyTag ([xmpp_ns ('disco_info'), 'identity'],
      category => $cat,
      type     => $type,
      (defined $name ? (name => $name) : ())
   );
}

sub handle_disco_query {
   my ($self, $con, $node) = @_;

   my $q;
   if (($q) = $node->find_all ([qw/disco_info query/])) {
      $con->reply_iq_result (
         $node, sub {
            my ($w) = @_;

            if ($q->attr ('node')) {
               simxml ($w, defns => 'disco_info', node => {
                 ns => 'disco_info', name => 'query',
                 attrs => [ node => $q->attr ('node') ] 
               });

            } else {
               $w->addPrefix (xmpp_ns ('disco_info'), '');
               $w->startTag ([xmpp_ns ('disco_info'), 'query']);
                  for my $cat (keys %{$self->{iden}}) {
                     for my $type (keys %{$self->{iden}->{$cat}}) {
                        $self->write_identity ($w,
                           $cat, $type, $self->{iden_name}
                        );
                     }
                  }
                  for (sort grep { $self->{feat}->{$_} } keys %{$self->{feat}}) {
                     $self->write_feature ($w, $_);
                  }
               $w->endTag;
            }
         }
      );

      return 1

   } elsif (($q) = $node->find_all ([qw/disco_items query/])) {
      $con->reply_iq_result (
         $node, sub {
            my ($w) = @_;

            if ($q->attr ('node')) {
               simxml ($w, defns => 'disco_items', node => {
                  ns    => 'disco_items',
                  name  => 'query',
                  attrs => [ node => $q->attr ('node') ]
               });

            } else {
               simxml ($w, defns => 'disco_items', node => {
                  ns   => 'disco_items',
                  name => 'query'
               });
            }
         }
      );

      return 1
   }

   0
}

sub DESTROY {
   my ($self) = @_;
   $self->unreg_cb ($self->{cb_id})
}


=item B<request_items ($con, $dest, $node, $cb)>

This method does send a items request to the JID entity C<$from>.
C<$node> is the optional node to send the request to, which can be
undef.

C<$con> must be an instance of L<AnyEvent::XMPP::Connection> or a subclass of it.
The callback C<$cb> will be called when the request returns with 3 arguments:
the disco handle, an L<AnyEvent::XMPP::Ext::Disco::Items> object (or undef)
and an L<AnyEvent::XMPP::Error::IQ> object when an error occured and no items
were received.

The timeout of the request is the IQ timeout of the connection C<$con>.

   $disco->request_items ($con, 'a@b.com', undef, sub {
      my ($disco, $items, $error) = @_;
      die $error->string if $error;

      # do something with the items here ;_)
   });

=cut

sub request_items {
   my ($self, $con, $dest, $node, $cb) = @_;

   $con->send_iq (
      get => sub {
         my ($w) = @_;
         $w->addPrefix (xmpp_ns ('disco_items'), '');
         $w->emptyTag ([xmpp_ns ('disco_items'), 'query'],
            (defined $node ? (node => $node) : ())
         );
      },
      sub {
         my ($xmlnode, $error) = @_;
         my $items;

         if ($xmlnode) {
            my (@query) = $xmlnode->find_all ([qw/disco_items query/]);
            $items = AnyEvent::XMPP::Ext::Disco::Items->new (
               jid     => $dest,
               node    => $node,
               xmlnode => $query[0]
            )
         }

         $cb->($self, $items, $error)
      },
      to => $dest
   );
}

=item B<request_info ($con, $dest, $node, $cb)>

This method does send a info request to the JID entity C<$from>.
C<$node> is the optional node to send the request to, which can be
undef.

C<$con> must be an instance of L<AnyEvent::XMPP::Connection> or a subclass of it.
The callback C<$cb> will be called when the request returns with 3 arguments:
the disco handle, an L<AnyEvent::XMPP::Ext::Disco::Info> object (or undef)
and an L<AnyEvent::XMPP::Error::IQ> object when an error occured and no items
were received.

The timeout of the request is the IQ timeout of the connection C<$con>.

   $disco->request_info ($con, 'a@b.com', undef, sub {
      my ($disco, $info, $error) = @_;
      die $error->string if $error;

      # do something with info here ;_)
   });

=cut

sub request_info {
   my ($self, $con, $dest, $node, $cb) = @_;

   $con->send_iq (
      get => sub {
         my ($w) = @_;
         $w->addPrefix (xmpp_ns ('disco_info'), '');
         $w->emptyTag ([xmpp_ns ('disco_info'), 'query'],
            (defined $node ? (node => $node) : ())
         );
      },
      sub {
         my ($xmlnode, $error) = @_;
         my $info;

         if ($xmlnode) {
            my (@query) = $xmlnode->find_all ([qw/disco_info query/]);
            $info = AnyEvent::XMPP::Ext::Disco::Info->new (
               jid     => $dest,
               node    => $node,
               xmlnode => $query[0]
            )
         }

         $cb->($self, $info, $error)
      },
      to => $dest
   );
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
