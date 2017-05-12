package DBIx::NoSQL::Store::Manager::StoreKey;
BEGIN {
  $DBIx::NoSQL::Store::Manager::StoreKey::AUTHORITY = 'cpan:YANICK';
}
{
  $DBIx::NoSQL::Store::Manager::StoreKey::VERSION = '0.2.2';
}
# ABSTRACT: Marks attributes defining the object's key in the store


use Moose::Role;
Moose::Util::meta_attribute_alias('StoreKey');

1;

__END__

=pod

=head1 NAME

DBIx::NoSQL::Store::Manager::StoreKey - Marks attributes defining the object's key in the store

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

    # in a class consuming the DBIx::NoSQL::Store::Manager::Model role

    has my_id => (
        traits => [ 'StoreKey' ],
        is => 'ro',
    );

=head1 DESCRIPTION

I<DBIx::NoSQL::Store::Manager::StoreKey> (also aliased to I<StoreKey>)
is used to mark attributes that will be used as the object id in the 
L<DBIx::NoSQL::Store::Manager> store.

If more than one attribute has the
trait, the id will be the concatenated values of those attributes.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
