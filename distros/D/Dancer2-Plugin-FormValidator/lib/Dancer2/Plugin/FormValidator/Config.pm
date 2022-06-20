package Dancer2::Plugin::FormValidator::Config;

use strict;
use warnings;

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
    builder  => sub {
        return $_[0]->config->{session} // {};
    }
);

has session_namespace => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
    builder  => sub {
        return $_[0]->session->{namespace} //  '_form_validator';
    }
);

has messages => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    builder  => sub {
        return $_[0]->config->{messages} // {};
    }
);

has messages_validators => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
    builder  => sub {
        return $_[0]->messages->{validators} // {};
    }
);

has ucfirst => (
    is       => 'ro',
    isa      => Bool,
    lazy     => 1,
    builder  => sub {
        return $_[0]->messages->{ucfirst} // 1;
    }
);

has language => (
    is       => 'rw',
    isa      => NonEmptyStr,
    lazy     => 1,
    builder  => sub {
        return $_[0]->messages->{language} // 'en';
    }
);

1;
