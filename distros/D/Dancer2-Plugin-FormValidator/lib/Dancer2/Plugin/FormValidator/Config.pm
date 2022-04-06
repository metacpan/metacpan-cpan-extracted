package Dancer2::Plugin::FormValidator::Config;

use Moo;
use Carp;
use Types::Standard qw(HashRef Bool);
use Types::Common::String qw(NonEmptyStr);
use namespace::clean;

has config => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has session => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

has session_namespace => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has messages => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    builder  => sub {
        return shift->config->{messages} // {};
    }
);

has messages_validators => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    builder  => sub {
        return shift->messages->{validators} // {};
    }
);

has ucfirst => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    builder  => sub {
        return shift->messages->{ucfirst} // 1;
    }
);

has language => (
    is       => 'rw',
    isa      => NonEmptyStr,
    lazy     => 1,
    builder  => sub {
        return shift->messages->{language} // 'en';
    }
);

has forms => (
    is       => 'ro',
    isa      => HashRef,
    lazy     => 1,
    builder  => sub {
        return shift->config->{forms} // {};
    }
);

sub BUILDARGS {
    my ($self, %args) = @_;

    if (my $config = $args{config}) {
        if (my $session = $config->{session}) {
            $args{session}           = $session;
            $args{session_namespace} = $session->{namespace};
        }
    }

    return \%args;
}

sub form {
    my ($self, $form) = @_;

    return $self->forms->{$form};
}

1;
