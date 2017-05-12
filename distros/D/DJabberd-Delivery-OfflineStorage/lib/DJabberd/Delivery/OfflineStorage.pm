package DJabberd::Delivery::OfflineStorage;
use strict;
use warnings;
use base 'DJabberd::Delivery';

use DJabberd::Queue::ServerOut;
use DJabberd::Log;
our $logger = DJabberd::Log->get_logger;
use Storable qw(nfreeze thaw);

use vars qw($VERSION);
$VERSION = '0.04';

=head1 NAME

DJabberd::Delivery::OfflineStorage - Basic OfflineStorage (old style) for DJabberd

=head1 DESCRIPTION

So you want offline storage - well add this to djabberd.conf:

    <VHost mydomain.com>

        [...]
        <Plugin DJabberd::Delivery::OfflineStorage::InMemoryOnly>
             Types Message
         </Plugin>
    </VHost>

 For InMemoryOnly based storage, and:

    <VHost mydomain.com>

        [...]
        <Plugin DJabberd::Delivery::OfflineStorage::SQLite>
           Database offline.sqlite
           Types Message
        </Plugin>
    </VHost>
 For SQLite based storage.

Parameter Database specifies the sqlite database file to use, and Types is a list of Stanza
types that will be collected.  This should really only be Message - think really hard before
you ad IQ to the list.

Also - it is extremely IMPORTANT as Edward Rudd pointed out - this Plugin MUST be the last
in the delivery chain, as it assumes that if S2S and Local haven't dealt with it, then the
JID in question is offline.


=head1 AUTHOR

Piers Harding, piers@cpan.org.


=cut



sub run_after { ("DJabberd::Delivery::Local") }


sub set_config_types {
    my ($self, $types) = @_;
    $self->{types} = { map { lc($_) => 1 }  grep(/^(IQ|Message)$/i, split(/\s+/, $types)) };
}


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}


sub register {
  my ($self, $vhost) = @_;
  $self->set_vhost($vhost);
  $vhost->register_hook("OnInitialPresence", sub { $self->on_initial_presence(@_) });
  $self->SUPER::register($vhost);
}


# OIntialPresence is used to determine that a user is now available
# and can receive stored offline messages
sub on_initial_presence {
    my ($self, $vhost, $cb, $conn) = @_;
    my $from = $conn->bound_jid
        or return;
    my $messages = $self->load_offline_messages($from->as_bare_string);
    # deliver messages
    foreach my $message (@$messages) {
      my $packet = Storable::thaw($message->{packet});
      my $class = $packet->{type};
      my $xml = DJabberd::XMLElement->new($packet->{ns}, $packet->{element}, $packet->{attrs}, []);
      my $stanza = $class->downbless($xml, $conn);
      $stanza->set_raw($packet->{stanza});
      $stanza->deliver($vhost);
      $self->delete_offline_message($message->{id});
    }
}


# hit the end of the delivery chain and we know that the user
# cannot accept the message -> store it offline for later
sub deliver {
    my ($self, $vhost, $cb, $stanza) = @_;
    die unless $vhost == $self->{vhost}; # sanity check

    my $to = $stanza->to_jid
        or return $cb->declined;

   # only configured packet types
    return $cb->declined
      unless exists $self->{types}->{$stanza->element_name};

    my $packet = { 'type'    => ref($stanza),
                   'element' => $stanza->element_name,
                   'stanza'  => $stanza->innards_as_xml,
                   'ns'      => $stanza->namespace,
                   'attrs'   => {}                      };
    map { $packet->{attrs}->{$_} = $stanza->attrs->{$_} } keys %{$stanza->{attrs}};

    $self->store_offline_message($to->as_bare_string, Storable::nfreeze($packet));

    $DJabberd::Stats::counter{deliver_to_offline_storage}++;

    $cb->delivered;
}

=head1 COPYRIGHT & LICENSE

Original work Copyright 2006 Alexander Karelas, Martin Atkins, Brad Fitzpatrick and Aleksandar Milanov. All rights reserved.
Copyright 2007 Piers Harding.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
