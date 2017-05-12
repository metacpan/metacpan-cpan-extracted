# $Id: Telephone.pm,v 1.1 2004/09/19 19:05:44 simonflack Exp $

package Telephone;
use strict;
use base 'Class::Publisher';
use vars '$DEBUG';

sub new {
    my $class = shift;
    TRACE('Adding new Telphone: ' . $_[0]);
    my $self = bless { number => shift }, $class;
    $self->switch_on();
    return $self;
}

sub switch_on {
    my $self = shift;
    TRACE('Switching on: ' . $self->{number});
    $self->notify_subscribers('connect');
}

sub switch_off {
    my $self = shift;
    TRACE('Switching off: ' . $self->{number});
    $self->hangup if $self->busy;
    $self->online(0);
    $self->notify_subscribers('disconnect');
}

sub busy {
    my $self = shift;
    return defined $_[0] ? $self->{busy} = shift : $self->{busy}
}

sub online {
    my $self = shift;
    return defined $_[0] ? $self->{online} = shift : $self->{online}
}

sub call {
    my $self = shift;
    my $number = shift;
    return unless $self->online();
    if ($self->busy()) {
        TRACE('Cannot make a call. Call already in progress');
    }

    $self->busy(1);
    delete $self->{hangup};
    $self->{calls_made}++;
    TRACE($self->{number} . "calling $number");
    $self->notify_subscribers('call', number => $number);
    return 1;
}

sub connect {
    my $self = shift;
    my ($other_phone) = @_;

    TRACE($self->{number} . ' connected to ' . $other_phone->{number});
    $self->{connections}++;
    $self->{other_party} = $other_phone;

    # Ordinarily the exchange would route communications
    $other_phone->add_subscriber('communicate', $self);

    $self->busy(1);
}

sub hangup {
    my $self = shift;
    my ($reason) = @_;

    TRACE($self->{number} . " hanging up [$reason]") if $reason;
    if ($self->{other_party}) {
        $self->delete_subscriber('communicate', $self->{other_party});
        $self->notify_subscribers('end_call');
        delete $self->{other_party};
    }
    $self->busy(0);
    $self->{listened_to} = undef;
    $self->{hangup} = $reason;
}

sub speak {
    my $self = shift;
    my ($words) = @_;
    TRACE($self->{number} . " saying '$words'");
    $self->notify_subscribers('communicate', words => $words);
}

sub update {
    my $self = shift;
    my ($other_party, $action, %params) = @_;

    if ($action eq 'communicate') {
        TRACE($self->{number} . " heard '$params{words}'");
        push @{$self->{listened_to}}, $params{words};
    }
}

sub TRACE {$DEBUG && print STDERR @_, $/ }
sub DUMP  {$DEBUG && require Data::Dumper && TRACE(Data::Dumper::Dumper(@_))}

package Telephone::Exchange;

*TRACE = \&Telephone::TRACE;
*DUMP  = \&Telephone::DUMP;

sub new {
    bless {}, shift;
}

sub valid_phone {
    my $self = shift;
    return 1 if $self->{shift->{number}};
}

sub connect_phones {
    my $self = shift;
    my ($caller, $action, %params) = @_;

    my $recipient = $self->{$params{number}};
    if ($recipient) {
        if ($recipient->busy()) {
            $caller->hangup('BUSY');
        } else {
            $caller->connect($recipient);
            $recipient->connect($caller);
        }
    } else {
        $caller->hangup('WRONG NUMBER');
    }
}

sub disconnect_phones {
    my $self = shift;
    my ($phone, $action, %params) = @_;
    my $other_phone = delete $phone->{other_party};
    if ($other_phone) {
        $other_phone->hangup('CALL ENDED');
    }
}

sub register_phone {
    my $self = shift;
    my ($phone) = @_;
    TRACE('Exchange: registering phone ' . $phone->{number});
    $self->{$phone->{number}} = $phone;
    $phone->online(1);
}

sub unregister_phone {
    my $self = shift;
    my ($phone) = @_;
    TRACE('Exchange: unregistering phone ' . $phone->{number});
    delete $self->{$phone->{number}};
    $phone->online(1);
}

1;
