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
# ABSTRACT: XS implementation of MongoDB's BSON serialization

use version;
our $VERSION = 'v0.8.0';

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

BSON::XS - XS implementation of MongoDB's BSON serialization

=head1 VERSION

version v0.8.0

=head1 DESCRIPTION

This module contains an XS implementation for BSON encoding and
decoding.  There is no public API.  Use the L<BSON> module and it will
choose the best implementation for you.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://jira.mongodb.org/browse/PERL>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mongodb/mongo-perl-bson-xs>

  git clone https://github.com/mongodb/mongo-perl-bson-xs.git

=head1 AUTHOR

David Golden <david@mongodb.com>

=head1 CONTRIBUTOR

=for stopwords Paul "LeoNerd" Evans

Paul "LeoNerd" Evans <leonerd@leonerd.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: ts=4 sts=4 sw=4 et tw=75:
