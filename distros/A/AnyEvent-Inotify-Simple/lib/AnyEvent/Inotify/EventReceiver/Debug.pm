package AnyEvent::Inotify::EventReceiver::Debug;
$AnyEvent::Inotify::EventReceiver::Debug::VERSION = '0.03';
use Moose;
use namespace::autoclean;

with 'AnyEvent::Inotify::EventReceiver';
use Carp qw(carp);

sub handle_access {
    my ($self,$file) = @_;
    carp "Access $file";
}

sub handle_modify {
    my ($self, $file) = @_;
    carp "Modify $file";
}

sub handle_attribute_change {
    my ($self, $file) = @_;
    carp "Attribute change $file";
}

sub handle_close {
    my ($self, $file) = @_;
    carp "Close $file";
}

sub handle_open {
    my ($self, $file) = @_;
    carp "Open $file";
}

sub handle_move {
    my ($self, $from, $to) = @_;
    carp "Move $from to $to";
}

sub handle_delete {
    my ($self, $file) = @_;
    carp "Delete $file";
}

sub handle_create {
    my ($self, $file) = @_;
    carp "Create $file";
}

1;

__END__

=head1 NAME

AnyEvent::Inotify::EventReceiver::Debug - carps with an infomative message whenever an event is called

=head1 VERSION

version 0.03

=head1 ABSTRACT
