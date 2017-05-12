package Config::LDAPClient::Search;

use Moose;
use overload '""' => 'as_string';
use warnings;
use strict;

has 'base'      =>  ( is => 'rw', isa => 'Any' );
has 'scope'     =>  ( is => 'rw', isa => 'Any' );
has 'filter'    =>  ( is => 'rw', isa => 'Any' );

around BUILDARGS => sub {
    my($orig, $class, $base, $scope, $filter) = @_;
    return $class->$orig( base => $base, scope => $scope, filter => $filter);
};




sub as_string {
    my($self) = @_;
    return join(
        '?',
        map { defined() ? $_ : "" } $self->base, $self->scope, $self->filter
    );
}




1;

__END__

=head1 NAME

Config::LDAPClient::Search - simple encapsulation for search criteria.


=head1 SYNOPSIS

    use Config::LDAPClient::Search;

    $s = Config::LDAPClient::Search->new('dc=foo', 'one', '(uid=*)');
    $ldap->search( base => $s->base, scope => $s->scope, filter => $s->filter );


=head1 DESCRIPTION

This is a very simple class designed to wrap simple search criteria.
Specifically, libnss-ldap.conf lets you specify search critieria for specific
maps in the form 'base?scope?filter'; this encapsulates that data and
provides convenient access to it.


=head2 Methods

=over 4

=item $class->new($base, $scope, $filter)

Constructs and returns a new object with the accessors defaulted to the
specified values.  Any of them can be specified as undef.


=item $object->base

=item $object->base($base)

Accessor for the search base.


=item $object->scope

=item $object->scope($scope)

Accessor for the search scope.


=item $object->filter

=item $object->filter($scope)

Accessor for the search filter.


=item $object->as_string

Called when the object is stringified.  Returns the base, scope, and filter
(in that order) joined by '?'.

=back


=head1 AUTHOR

Michael Fowler <mfowler@cpan.org>


=head1 COPYRIGHT & LICENSE

Copyright 2009  Michael Fowler

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
