package Ambrosia::BaseManager;
use strict;
use warnings;
use Carp;

use Ambrosia::error::Exceptions;
use Ambrosia::core::ClassFactory;
use Ambrosia::core::Nil;
use Ambrosia::Context;
use Ambrosia::Meta;

class
{
    extends => [qw/Exporter/],
    private => [qw/__managers __last_manager/],
};

our $VERSION = 0.010;

sub RELEGATE() { 0 }
sub INTERNALREDIRECT() { 1 }
sub FORWARD() { 2 }

our @EXPORT = qw/controller/;

{
    my $__CONTROLLER__;

    sub instance
    {
        $__CONTROLLER__ = shift->SUPER::new(@_) unless $__CONTROLLER__;
        return $__CONTROLLER__;
    }

    sub controller
    {
        no warnings;
        return __PACKAGE__->instance(@_);
    }
}

sub managers
{
    controller->__managers;
}

sub last_manager
{
    controller->__last_manager;
}

sub current_manager
{
    if ( my $f = Context->mqueue->first() )
    {
        return $f->[0];
    }
    return new Ambrosia::core::Nil;
}

sub prepare : Protected
{
    return $_[0];
}

sub process
{
    $_[0]->prepare();
    return $_[0];
}

sub next_manager
{
    my ($manager_params, $state) = @{Context->mqueue->first() || []};
    if ( $manager_params )
    {
        if ( $state == &RELEGATE )
        {
            Context->mqueue->next();
            return create_object($manager_params);
        }
    }
    return new Ambrosia::core::Nil;
}

#
# relegate the handling to other manager
#
sub __relegate #(anotherManager)
{
    my $self = shift;

    if ( my $mng = shift )
    {
        my $strategi = shift || &RELEGATE;
        my $manager_params;

        if ( ref $mng )
        {
            $manager_params = $mng
        }
        elsif(! ($manager_params = $self->managers()->{$mng}) )
        {
            return $self;
        }

        if ( $strategi == &FORWARD )
        {
            Context->mqueue->inhead([$manager_params, &RELEGATE]);
        }
        else
        {
            Context->mqueue->add([$manager_params, $strategi]);
        }
    }
    return $self;
}

sub relegate
{
    controller->__relegate($_[1]);
}

sub reset
{
    if ( $_[1])
    {
        Context->mqueue->clear();
        controller->__relegate($_[1]);
    }
}

sub forward
{
    controller->__relegate($_[1], &FORWARD);
}

sub internal_redirect
{
    if ( $_[1] )
    {
        controller->__relegate($_[1], &INTERNALREDIRECT);
    }
    else
    {
        my ($manager_params, $state) = @{Context->mqueue->first() || []};
        if ( $manager_params )
        {
            if ( $state == &INTERNALREDIRECT )
            {
                Context->mqueue->first()->[1] = &RELEGATE;
                return 1;
            }
        }
        return 0;
    }
}

sub immediate
{#may need to add one more queue in the Context of a higher priority
    my $self = shift;
    return create_object($self->managers->{+shift})->prepare();
}

sub create_object
{
    my $manager_info = controller->__last_manager = shift;

    if ( my $m = $manager_info->{manager} )
    {
        return Ambrosia::core::ClassFactory::create_object($m);
    }
    else
    {
        throw Ambrosia::error::Exception "Manager not defined.";
    }
}

sub _addEWM
{
    my $self  = shift;
    my $level = shift;
    my $msg   = shift;

    return undef unless $msg;

    my $refMsg = ref $msg;

    my $error_h = Context->repository->get('mng_EWM') || {};
    my $log = '';

    if ( $refMsg eq 'Ambrosia::Validator::Violation' )
    {
        push @{$error_h->{$level}}, $msg->errorSummary;
        $log = "ERROR bad request(VALIDATOR): $msg";
    }
    elsif ( $refMsg eq 'Ambrosia::core::Exception::BadParams' )
    {
        push @{$error_h->{$level}}, $msg->message;
        $log = "ERROR bad request(VALIDATOR): " . $msg->message;
    }
    elsif ( $refMsg eq 'ARRAY' )
    {
        foreach my $m ( @$msg )
        {
            $self->_addEWM($level, $m);
        }
        return $msg;
    }
    elsif ( $refMsg eq 'HASH' )
    {
        foreach my $m ( values %$msg )
        {
            $self->_addEWM($level, $m);
        }
        return $msg;
    }
    elsif ( $refMsg )
    {
        $error_h->{error} = ['Internal Error'];
        $log = "ERROR bad request(OTHER): '$refMsg' ==>> '$msg'";
    }
    elsif ( $msg )
    {
        $log = $msg;
        $msg =~ s/ at.*//;
        push @{$error_h->{$level}}, $msg;
    }

    Context->repository->set('mng_EWM' => $error_h);
    carp ('BaseManager::_addEWM: ' . $log) if $log && $level ne 'message';

    return $msg;
}

sub add_error
{
    my $self = shift;
    my $msg = shift || $@;
    my $fName = shift;

    return $self->_addEWM('error', $msg);
}

sub add_warning
{
    return shift->_addEWM('warning', @_);
}

sub add_message
{
    return shift->_addEWM('message', @_);
}

sub get_info
{
    return Context->repository->get('mng_EWM');
}

sub set_info
{
    my $self = shift;
    my $info = shift;
    return Context->repository->set( mng_EWM => $info );
}

sub error
{
    my $self = shift;
    return $self->get_info && defined $self->get_info->{error};
}

1;

__END__

=head1 NAME

Ambrosia::BaseManager - a base class of Managers in your application.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    package Employee::Managers::BaseManager;
    use strict;

    use Ambrosia::Meta;
    class
    {
        extends => [qw/Ambrosia::BaseManager/]
    };

    sub prepare
    {
        my $self = shift;
        ...........
    }

    1;

=head1 DESCRIPTION

C<Ambrosia::BaseManager> is base class of Managers in your application.
You must override method C<prepare> in your module.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 SEE ALSO

L<Ambrosia::Dispatcher>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
