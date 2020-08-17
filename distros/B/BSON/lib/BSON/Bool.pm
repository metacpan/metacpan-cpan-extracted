use 5.010001;
use strict;
use warnings;

package BSON::Bool;
# ABSTRACT: Legacy BSON type wrapper for Booleans (DEPRECATED)

use version;
our $VERSION = 'v1.12.2';

use boolean 0.45 ();
our @ISA = qw/boolean/;

sub new {
    my ( $class, $bool ) = @_;
    return bless \(my $dummy = $bool ? 1 : 0), $class;
}

sub value {
    ${$_[0]} ? 1 : 0;
}

sub true {
    return $_[0]->new(1);
}

sub false {
    return $_[0]->new(0);
}

sub op_eq {
    return !! $_[0] == !! $_[1];
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Bool - Legacy BSON type wrapper for Booleans (DEPRECATED)

=head1 VERSION

version v1.12.2

=head1 DESCRIPTION

This module has been deprecated as it was not compatible with
other common boolean implementations on CPAN.

You are strongly encouraged to use L<boolean> directly instead.

=for Pod::Coverage new value true false op_eq

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
