use 5.010001;
use strict;
use warnings;

package BSON::MaxKey;
# ABSTRACT: BSON type wrapper for MaxKey

use version;
our $VERSION = 'v1.12.2';

use Carp;

my $singleton = bless \(my $x), __PACKAGE__;

sub new {
    return $singleton;
}

#pod =method TO_JSON
#pod
#pod If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$maxKey" : 1}
#pod
#pod If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
#pod can't otherwise be represented in JSON.
#pod
#pod =cut

sub TO_JSON {
    if ( $ENV{BSON_EXTJSON} ) {
        return { '$maxKey' => 1 };
    }

    croak( "The value '$_[0]' is illegal in JSON" );
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::MaxKey - BSON type wrapper for MaxKey

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_maxkey();

=head1 DESCRIPTION

This module provides a BSON type wrapper for the special BSON "MaxKey" type.
The object returned is a singleton.

=head1 METHODS

=head2 TO_JSON

If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$maxKey" : 1}

If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
can't otherwise be represented in JSON.

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
