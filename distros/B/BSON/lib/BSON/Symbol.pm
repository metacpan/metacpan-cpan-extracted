use 5.010001;
use strict;
use warnings;

package BSON::Symbol;

# ABSTRACT: BSON type wrapper for symbol data (DEPRECATED)

our $VERSION = 'v1.12.2';

use Moo 2.002004;
use namespace::clean -except => 'meta';

extends 'BSON::String';

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Symbol - BSON type wrapper for symbol data (DEPRECATED)

=head1 VERSION

version v1.12.2

=head1 DESCRIPTION

This module wraps the deprecated BSON "symbol" type.

You are strongly encouraged to use ordinary string data instead.

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
