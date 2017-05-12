package AnyEvent::Inotify::EventReceiver::Null;
$AnyEvent::Inotify::EventReceiver::Null::VERSION = '0.03';
use Moose;
use namespace::autoclean;

with 'AnyEvent::Inotify::EventReceiver';

sub handle_access {}
sub handle_modify {}
sub handle_attribute_change {}
sub handle_close {}
sub handle_open {}
sub handle_move {}
sub handle_delete {}
sub handle_create {}

1;

__END__

=head1 NAME

AnyEvent::Inotify::EventReceiver::Null - does nothing

=head1 VERSION

version 0.03

=head1 ABSTRACT
