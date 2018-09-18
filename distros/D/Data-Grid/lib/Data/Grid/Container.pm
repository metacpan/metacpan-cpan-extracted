package Data::Grid::Container;

use 5.014;
use strict;
use warnings FATAL => 'all';

use Moo;

use Scalar::Util ();
use Carp         ();

use overload '""' => 'as_string';

use Type::Params qw(multisig Invocant);
use Types::Standard qw(slurpy Maybe Optional Any Int HashRef CodeRef Object);

=head1 NAME

Data::Grid::Container - Generic superclass for Data::Grid containers

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

    package Data::Grid::Foo;

    use Moo;
    extends 'Data::Grid::Container';

    # Now code some specific stuff...

=head1 DESCRIPTION

The data grid in L<Data::Grid> is modeled as an ordered tree of
tables, rows and cells, all contained inside a bundle. This module
encapsulates the common behaviour of these components.

=head1 METHODS

=head2 new $parent, $position [, $proxy ] | %params

This basic constructor takes three arguments: the parent object, a
numeric position amongst its siblings, beginning with 0, and an
optional proxy object to manipulate directly, if it is necessary or
advantageous to do so.

=cut

around BUILDARGS => sub {
    state $check = Type::Params::multisig(
        [CodeRef, Invocant, Object, Int, Optional[Any]],
        [CodeRef, Invocant, slurpy HashRef],

        # this doesn't need to get checked twice
        # [CodeRef, Invocant, slurpy Dict[parent => Object, position => Int,
        #                                 proxy => Optional[Maybe[Object]],
        #                                 slurpy Any]]
    );
    my ($orig, $class, @rest) = $check->(@_);

    # normalize parameters
    my $p;
    if (ref $rest[0] eq 'HASH') {
        $p = $rest[0];
    }
    else {
        my @k = qw(parent position proxy);
        $p = { map +($k[$_] => $rest[$_]), (0..$#k) };
    }

    #warn Data::Dumper::Dumper($p);

    $class->$orig($p);
};

=head2 parent

Retrieve the parent object.

=cut

has parent => (
    is        => 'ro',
    weak_ref => 1,
    required => 1,
);

=head2 position

The position of the object in a list of its siblings, starting with 0.

=cut

has position => (
    is       => 'rwp',
    isa      => sub { Scalar::Util::looks_like_number($_) },
    required => 1,
);

=head2 proxy

Whatever object or value the container is proxying.

=cut

has proxy => (
    is       => 'rwp',
    required => 0,
);

=head2 as_string

This is a I<stub> to hook up a serialization method to the string
overload. Fill it in at your leisure, otherwise it is a no-op.

=cut

sub as_string {
    $_[0];
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 SEE ALSO

=over 4

=item

L<Data::Grid>

=item

L<Data::Grid::Table>

=item

L<Data::Grid::Row>

=item

L<Data::Grid::Cell>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010-2018 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::Grid::Row
