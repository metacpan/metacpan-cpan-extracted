use 5.010001;
use strict;
use warnings;

package BSON::Array;
# ABSTRACT: BSON type wrapper for a list of elements

use version;
our $VERSION = 'v1.12.2';

sub new {
    my ( $class, @args ) = @_;
    return bless [@args], $class;
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Array - BSON type wrapper for a list of elements

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    my $array = bson_array(...);

=head1 DESCRIPTION

This module provides a BSON type wrapper representing a list of elements.
It is currently read-only.

Wrapping is usually not necessary as an ordinary array reference is usually
sufficient.  This class is helpful for cases where an array reference could
be ambiguously interpreted as a top-level document container.

=for Pod::Coverage new

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
