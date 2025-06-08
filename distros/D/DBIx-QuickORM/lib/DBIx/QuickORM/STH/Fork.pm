package DBIx::QuickORM::STH::Fork;
use strict;
use warnings;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use Carp qw/croak/;
use Time::HiRes qw/sleep/;
use Cpanel::JSON::XS qw/decode_json/;

use IO::Select;

use DBIx::QuickORM::Util::HashBase qw{
    <connection
    <source

    only_one

    +dialect
    +ready
    <got_result
    <done
    <pid
    <pipe
    <ios
};

sub cancel_supported { 1 }

sub dialect { $_[0]->{+DIALECT} //= $_[0]->{+CONNECTION}->dialect }
sub clear   { $_[0]->{+CONNECTION}->clear_fork($_[0]) }

sub init {
    my $self = shift;

    croak "'pid' is a required attribute"         unless $self->{+PID};
    croak "'pipe' is a required attribute"        unless $self->{+PIPE};
    croak "'connection' is a required attribute"  unless $self->{+CONNECTION};
    croak "'source' is a required attribute" unless $self->{+SOURCE};
}

sub ready {
    my $self = shift;
    return 1 if $self->{+READY};

    my $ios = $self->{+IOS} //= IO::Select->new($self->{+PIPE});
    return unless $ios->can_read(0);

    return $self->{+READY} = 1;
}

sub result {
    my $self = shift;
    return $self->{+GOT_RESULT} if $self->{+GOT_RESULT};

    $self->wait unless $self->{+READY};

    my $pipe = $self->{+PIPE};
    my $line = <$pipe>;
    my $data = decode_json($line);

    unless ($data && exists $data->{result}) {
        chomp($line);
        croak "Got invalid data from pipe: $line";
    }

    return $self->{+GOT_RESULT} = $data->{result};
}

sub cancel {
    my $self = shift;

    return if $self->{+DONE};

    close(delete $self->{+PIPE}) if $self->{+PIPE};

    kill('TERM', $self->{+PID}) or die "Could not kill pid $self->{+PID}: $!\n";

    $self->clear;
    $self->{+DONE} = 1;
}

sub next {
    my $self = shift;
    my $row = $self->_next;

    if ($self->{+ONLY_ONE}) {
        croak "Expected only 1 row, but got more than one" if $self->_next;
        $self->set_done;
    }

    return $row;
}

sub _next {
    my $self = shift;

    return if $self->{+DONE};

    $self->result unless $self->{+GOT_RESULT};

    my $pipe = $self->{+PIPE};
    my $line = <$pipe>;
    if (defined $line) {
        my $row = decode_json($line);
        return $row if $row;
    }

    $self->set_done;

    return;
}

sub set_done {
    my $self = shift;

    return if $self->{+DONE};

    close(delete $self->{+PIPE}) if $self->{+PIPE};
    $self->clear;
    $self->{+DONE} = 1;
}

1;
