package Bot::Backbone::Types;
$Bot::Backbone::Types::VERSION = '0.161950';
use v5.10;
use Moose;

use List::MoreUtils qw( all );
use MooseX::Types::Moose qw( ArrayRef ClassName CodeRef HashRef Object );
use MooseX::Types -declare => [ qw(
    DispatcherType
    EventLoop
    PredicateList
    ServiceList
    VolumeLevel
) ];
use Scalar::Util qw( blessed );

use namespace::autoclean;

# ABSTRACT: The type library for Bot::Backbone


class_type 'Moose::Meta::Class';
enum DispatcherType, [qw( bot service )];
coerce DispatcherType,
    from 'Moose::Meta::Class',
    via { 
        if    ($_->name->isa('Bot::Backbone::Bot'))                     { 'bot' }
        elsif ($_->name->does('Bot::Backbone::Service::Role::Service')) { 'service' }
        else  { die "unknown meta object $_ in DispatherType coercion" }
    };


subtype EventLoop,
    as ClassName|Object,
    where { $_->can('run') };


role_type 'Bot::Backbone::Dispatcher::Predicate';
subtype PredicateList,
    as ArrayRef,
    where { all { $_->does('Bot::Backbone::Dispatcher::Predicate') } @$_ };


class_type 'Bot::Backbone::Service::Role::Service';
subtype ServiceList,
    as HashRef[Object],
    where { all { blessed $_ and $_->does('Bot::Backbone::Service::Role::Service') } values %$_ };


enum VolumeLevel, [ qw( shout spoken whisper ) ];

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Types - The type library for Bot::Backbone

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

This is a container for the various types used by L<Bot::Backbone>. It is built
using L<MooseX::Types>.

=head1 TYPES

=head2 DispatcherType

This is an enum with the following values:

    bot
    service

=head2 EventLoop

This is just an object with a C<run> method.

=head2 PredicateList

This is an array of code references.

=head2 ServiceList

This is a hash of objects that implement L<Bot::Backbone::Service::Role::Service>.

=head2 VolumeLevel

This is an enumeration of possible volume levels for chats. It must be one of the following:

    shout
    spoken
    whisper

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
