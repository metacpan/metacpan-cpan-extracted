#
#  Copyright 2016 MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use 5.010001;
use strict;
use warnings;

package BSON::XS;
# ABSTRACT: XS implementation of MongoDB's BSON serialization (EOL)

use version;
our $VERSION = 'v0.8.4';

# cached for efficiency during decoding
# XXX eventually move this into XS
use boolean;
our $_boolean_true  = true;
our $_boolean_false = false;

use XSLoader;
XSLoader::load( "BSON::XS", $VERSION );

# For errors
sub _printable {
    my $value = shift;
    $value =~ s/([^[:print:]])/sprintf("\\x%02x",ord($1))/ge;
    return $value;
}

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::XS - XS implementation of MongoDB's BSON serialization (EOL)

=head1 VERSION

version v0.8.4

=head1 END OF LIFE NOTICE

Version v0.8.0 was the final feature release of the MongoDB BSON::XS
library and v0.8.4 is the final patch release.

B<As of August 13, 2020, the MongoDB Perl driver and related libraries have
reached end of life and are no longer supported by MongoDB.> See the
L<August 2019 deprecation
notice|https://www.mongodb.com/blog/post/the-mongodb-perl-driver-is-being-deprecated>
for rationale.

If members of the community wish to continue development, they are welcome
to fork the code under the terms of the Apache 2 license and release it
under a new namespace.  Specifications and test files for MongoDB drivers
and libraries are published in an open repository:
L<mongodb/specifications|https://github.com/mongodb/specifications/tree/master/source>.

=head1 DESCRIPTION

This module contains an XS implementation for BSON encoding and
decoding.  There is no public API.  Use the L<BSON> module and it will
choose the best implementation for you.

=head1 AUTHOR

David Golden <david@mongodb.com>

=head1 CONTRIBUTOR

=for stopwords Paul "LeoNerd" Evans

Paul "LeoNerd" Evans <leonerd@leonerd.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: ts=4 sts=4 sw=4 et tw=75:
