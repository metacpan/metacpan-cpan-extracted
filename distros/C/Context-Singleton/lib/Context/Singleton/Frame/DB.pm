
use strict;
use warnings;
use feature 'state';

package Context::Singleton::Frame::DB;

our $VERSION = v1.0.2;

use Class::Load;
use Module::Pluggable::Object;
use Ref::Util;

use Context::Singleton::Frame::Builder::Value;
use Context::Singleton::Frame::Builder::Hash;
use Context::Singleton::Frame::Builder::Array;

sub new {
    my ($class) = @_;

    my $self = bless {
        cache => {},
        plugin => {},
    }, $class;

    $self->contrive ('Class::Load', (
        value => 'Class::Load',
    ));

    $self->contrive ('class_loader', (
        dep => [ 'Class::Load' ],
        as  => sub { $_[0]->can ('load_class') },
    ));

    return $self;
}

sub instance {
    state $instance = __PACKAGE__->new;
    return $instance;
}

sub _contrive_class_loader {
    my ($self, $name) = @_;

    return if exists $self->{cache}{$name};

    $self->contrive ($name, (
        dep => [ 'class_loader' ],
        as => eval "sub { \$_[0]->(q[$name]) && q[$name] }",
    ));

    return;
}

sub _guess_builder_class {
    my ($self, $def) = @_;

    return 'Context::Singleton::Frame::Builder::Value' if exists $def->{value};
    return 'Context::Singleton::Frame::Builder::Hash'  if Ref::Util::is_hashref ($def->{dep});
    return 'Context::Singleton::Frame::Builder::Array'
}

sub contrive {
    my ($self, $name, %def) = @_;

    if ($def{class}) {
        $self->_contrive_class_loader ($def{class});
        $def{builder} //= 'new';
    }

    my $builder_class = $self->_guess_builder_class (\%def);
    my $builder = $builder_class->new (%def);

    push @{ $self->{cache}{ $name } }, $builder;

    return;
}

sub trigger {
    my ($self, $name, $code) = @_;

    push @{ $self->{trigger}{ $name } }, $code;

    return;
}

sub find_builder_for {
    my ($self, $name) = @_;

    return @{ $self->{cache}{ $name } // [] };
}

sub find_trigger_for {
    my ($self, $name) = @_;

    return @{ $self->{trigger}{ $name } // [] };
}

sub load_rules {
    my ($self, @packages) = @_;

    for my $package (@packages) {
        $self->{plugins}{ $package } //= do {
            Module::Pluggable::Object->new (
                require => 1,
                search_path => [ $package ],
            )->plugins;
            1;
        };
    }

    return;
}

1;
