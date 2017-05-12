package Bubblegum::Object::Role::Item;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'requires';
use Bubblegum::Namespace;

our $VERSION = '0.45'; # VERSION

requires 'defined';

sub class {
    my $self  = CORE::shift;
    my $types = $Bubblegum::Namespace::DefaultTypes;
    return $types->{type($self)};
}

sub of {
    my $self  = CORE::shift;
    my $type  = CORE::shift;
    my $types = $Bubblegum::Namespace::DefaultTypes;

    my $alias = {
        aref  => 'array',
        cref  => 'code',
        href  => 'hash',
        int   => 'integer',
        nil   => 'undef',
        null  => 'undef',
        num   => 'number',
        str   => 'string',
        undef => 'undef',
    };

    $type = $alias->{lc $type} if $alias->{lc $type};

    my $kind  = $types->{uc $type};
    my $class = $self->autobox_class;

    return $kind && $class->isa($kind) ? 1 : 0;
}

sub type {
    my $self = CORE::shift;
    return autobox::universal::type $self;
}

sub typeof {
    goto &of;
}

1;
