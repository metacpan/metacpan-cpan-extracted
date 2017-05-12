package DJabberd::Delivery::OfflineStorage::InMemoryOnly;
use strict;
use base 'DJabberd::Delivery::OfflineStorage';
use warnings;
use Data::Dumper;

use vars qw($VERSION);
$VERSION = '0.04';


our $logger = DJabberd::Log->get_logger();


sub load_offline_messages {
    my ($self, $user) = @_;
    $logger->info("InMemoryOnly OfflineStorage load for: $user");
    $self->{'offline'} ||= {};
    if (exists $self->{'offline'}{$user}) {
        my @messages = ();
        foreach my $message (sort keys %{$self->{'offline'}{$user}}) {
          push(@messages, $self->{'offline'}{$message});
        }
        return \@messages;
    } else {
        return [];
    }
}


sub delete_offline_message {
    my ($self, $id) = @_;
    $self->{'offline'} ||= {};
    $logger->info("InMemoryOnly OfflineStorage delete for: $id");
    # must remove it from $user too
    if (exists $self->{'offline'}->{$id}){
      my $user = $self->{'offline'}->{$id}->{'jid'};
      if (exists $self->{'offline'}->{$user}) {
        delete $self->{'offline'}->{$user}->{$id};
        delete $self->{'offline'}->{$user}
          unless keys %{$self->{'offline'}->{$user}};
      }
      delete $self->{'offline'}->{$id} 
    }
}


sub store_offline_message {
    my ($self, $user, $packet) = @_;
    $self->{offline} ||= {};
    $self->{offline_id} ||= 1;

    my $id = $self->{'offline_id'}++;
    $logger->info("InMemoryOnly OfflineStorage store for: $user/$id");
    $self->{'offline'}->{$user} ||= {};
    $self->{'offline'}->{$id} = {'id' => $id, 'packet' => $packet, 'jid' => $user};
    $self->{'offline'}->{$user}->{$id} = 1;
}

1;
