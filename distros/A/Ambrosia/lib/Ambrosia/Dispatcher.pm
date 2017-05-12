package Ambrosia::Dispatcher;
use strict;

use Ambrosia::error::Exceptions;
use Ambrosia::Context;
use Ambrosia::BaseManager;
use Ambrosia::Event qw/on_run on_complete on_error on_success/;

use Ambrosia::Meta;
class sealed {
    private => [qw/__check_access/],
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->__check_access = sub {1};
    $self->on_error(sub {warn "Error: @_\n";1;});
}

sub on_check_access
{
    my $self = shift;
    my $proc = shift;
    if ( $proc && ref $proc eq 'CODE' )
    {
        my $old_f = $self->__check_access;
        $self->__check_access = sub { $old_f->(@_); $proc->(@_) };
    }
    return $self;
}

sub run
{
    my $self = shift;
    my $manager = shift;
    my $success;
    my $access = 0;

    eval
    {
        controller->relegate($manager);
        do
        {
            $self->publicEvent( 'on_run' );
            $success = 0;
            if ( $access = $self->__check_access->(controller->current_manager) )
            {
                for(; controller->next_manager->process; ){};
                $self->publicEvent( on_success => controller->last_manager );
                $success = 1;
            }
        } until ( !controller->internal_redirect );
    };

    if ( $@ )
    {
        $self->publicEvent( on_error => "$@" );
    }
    elsif($access)
    {
        $self->publicEvent( on_complete => $success ? controller->last_manager : undef );
    }
    return $self;
}

1;

__END__

=head1 NAME

Ambrosia::Dispatcher - a dispatcher that execute the specified managers.

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::Dispatcher> transfers control to the next manager in the pool.

=head1 CONSTRUCTOR

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
