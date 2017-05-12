package Bot::Backbone::Meta::Class::Service;
$Bot::Backbone::Meta::Class::Service::VERSION = '0.161950';
use Moose;

extends 'Moose::Meta::Class';
with 'Bot::Backbone::Meta::Class::DispatchBuilder';

# ABSTRACT: Metaclass attached to backbone bot services


has bot_roles => (
    is          => 'rw',
    isa         => 'ArrayRef[ClassName]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        'add_bot_roles' => 'push',
        'all_bot_roles' => 'elements',
        'has_bot_roles' => 'count',
    },
);

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Meta::Class::Service - Metaclass attached to backbone bot services

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

This provides some tools necessary for building a dispatcher. It also lists all the additional roles that should be applied to a bot using this service.

=head1 ATTRIBUTES

=head2 bot_roles

This is a list of packages that will be applied as roles to the bot when this service is configured.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
