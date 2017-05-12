package AnyEvent::Inotify::EventReceiver::Callback;
$AnyEvent::Inotify::EventReceiver::Callback::VERSION = '0.03';
use Moose;
#use namespace::autoclean;

use MooseX::Types::Moose qw(CodeRef);

has 'callback' => (
    traits   => ['Code'],
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
    handles  => {
        call_callback => 'execute',
    },
);

for my $event (qw/access modify attribute_change close open move delete create/){
    __PACKAGE__->meta->add_method( "handle_$event" => sub {
        my $self = shift;
        $self->call_callback($event, @_);
    });
}

with 'AnyEvent::Inotify::EventReceiver';

1;

__END__

=head1 NAME

AnyEvent::Inotify::EventReceiver::Callback - delegates everything to a coderef

=head1 VERSION

version 0.03

=head1 ABSTRACT

=head1 INITARGS

=head2 callback

Coderef to be called when an event is received.

=head1 DESCRIPTION

This EventReceiver delegates every event to the C<callback> coderef.
The coderef gets the name of the event being delegated (access,
modify, attribute_change, ...) and the args that that event handler
would normally get.
