package Ambrosia::Addons::Session;
use strict;
use warnings;

use Ambrosia::core::Nil;
use Ambrosia::Meta;

class sealed {
    extends => [qw/Exporter/],
    public => [qw/storage/],
};

our @EXPORT = qw/session/;

our $VERSION = 0.010;

{
    our $__SESSION__;

    sub new : Private
    {
        return shift->SUPER::new(@_);
    }

    sub instance
    {
        return $__SESSION__ ||= @_ ? shift()->new(@_) : new Ambrosia::core::Nil;
    }

    sub destroy
    {
        undef $__SESSION__;
    }

    sub session
    {
        return instance __PACKAGE__;
    }
}

sub getSessionName
{
    return $_[0]->storage->getSessionName();
}

sub getSessionValue
{
    return $_[0]->storage->getSessionValue();
}

sub addItem
{
    return shift()->storage->addItem(@_);
}

sub getItem
{
    return $_[0]->storage->getItem($_[1]);
}

sub deleteItem
{
    return $_[0]->storage->deleteItem($_[1]);
}

sub hasSessionData
{
    return $_[0]->storage->hasData();
}

1;

__END__

=head1 NAME

Ambrosia::Addons::Session - 

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use Ambrosia::Addons::Session;

=head1 DESCRIPTION

C<Ambrosia::Addons::Session> .

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
