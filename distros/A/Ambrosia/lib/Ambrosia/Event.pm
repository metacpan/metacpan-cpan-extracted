package Ambrosia::Event;
use strict;
use warnings;

use Ambrosia::Meta;
class sealed
{
    private => [qw/_handlers/],
};

our $VERSION = 0.010;

sub import
{
    no strict 'refs';
    no warnings 'redefine';

    my $proto = shift;
    throw Ambrosia::error::Exception("'$proto' cannot inherit from sealed class '" . __PACKAGE__ . '\'.') if $proto ne __PACKAGE__;

    my $INSTANCE_CLASS = caller(0);

    foreach my $e ( @_ ) #@events )
    {
        *{"${INSTANCE_CLASS}::$e"} = sub()
        {
            #my $pack = ref $_[0];
            #$pack =~ s/::/_/sg;
            #attachHandler($pack . '_' . $e, $_[1]);
            attachHandler($_[0], $e, $_[1]);
            $_[0];
        };
    }
    *{"${INSTANCE_CLASS}::publicEvent"} = sub()
    {
        my $self = shift;
        fireEvent($self, @_);
    };
}

{
    my %__EVENT_HANDLER__ = ();

    sub new : Private {};

    sub instance
    {
        return $__EVENT_HANDLER__{$$} ||= __PACKAGE__->SUPER::new();
    }
}

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_handlers = {};
}

sub attachHandler
{
    my $class = shift;
    my $type = ref $class || $class || '';
    my $name = shift;
    my $handler = shift;

    my $h = instance();

    if ( my $prev = $h->_handlers->{$type}->{$name} )
    {
        $h->_handlers->{$type}->{$name} = sub { $handler->(@_) || $prev->(@_) };
    }
    elsif (ref $handler eq 'CODE')
    {
        $h->_handlers->{$type}->{$name} = $handler;
    }
    else
    {
        die 'error';
    }
}

sub fireEvent
{
    my $class = shift;
    my $type = ref $class || $class || '';
    my $name = shift;
    if ( my $h = instance()->_handlers->{$type}->{$name} )
    {
        $h->(@_);
    }
}

1;

__END__

=head1 NAME

Ambrosia::Event - lets you publish and subscribe to events.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    package Foo;
    use Ambrosia::Event qw/on_start on_complete/;

    use Ambrosia::Meta;
    class sealed {
    };

    sub run
    {
        my $self = shift;
        $self->publicEvent( 'on_start' );
        .........
        $self->publicEvent( on_complete => $eny_params );
    }
    1;

and other module.

    $foo = Foo
    ->new()
    ->on_start(sub { print "Foo start\n" } )
    ->on_complete(sub { print "Foo complete: @_\n" } );

    $foo->run();


=head1 DESCRIPTION

C<Ambrosia::Event> lets you publish and subscribe to events.

=head1 METHODS

=head2 publicEvent $name, $params

Fire named ($name) event and passes a $params ($params is optional).

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
