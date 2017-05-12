package Bot::Backbone::Meta::Class::DispatchBuilder;
$Bot::Backbone::Meta::Class::DispatchBuilder::VERSION = '0.161950';
use Moose::Role;

# ABSTRACT: Metaclass role providing dispatcher setup helps


has dispatch_builder => (
    is          => 'rw',
    isa         => 'CodeRef',
    predicate   => 'has_dispatch_builder',
    traits      => [ 'Code' ],
    handles     => {
        run_dispatch_builder => 'execute',
    },
);

has building_dispatcher => (
    is          => 'rw',
    isa         => 'Bot::Backbone::Dispatcher',
    clearer     => 'no_longer_building_dispatcher',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Meta::Class::DispatchBuilder - Metaclass role providing dispatcher setup helps

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

This metaclass role is used to help the sugar subroutines setup a dispatcher. That is all. There are no additional services provided here that should be used directly.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
