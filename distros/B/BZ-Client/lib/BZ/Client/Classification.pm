#!/bin/false
# PODNAME: BZ::Client::Classification
# ABSTRACT: Client side representation of Classifications in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Classification;
$BZ::Client::Classification::VERSION = '4.4003';

use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Classificaton.html
# These are in order as per the above

## functions

sub get {
    my($class, $client, $params) = @_;
    return $class->_returns_array($client, 'Classification.get', $params, 'classifications');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Classification - Client side representation of Classifications in Bugzilla

=head1 VERSION

version 4.4003

=head1 SYNOPSIS

This class provides methods for accessing Classification information in the
Bugzilla server.

  my $client = BZ::Client->new( url      => $url,
                                user     => $user,
                                password => $password );

  my $classifications = BZ::Client::Classification->get( $client, \%params );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get

 $classifications = BZ::Client::Classification->get( $client, \%params );

Returns a hash containing information about a set of classifications.

=head3 History

Added in Bugzilla 4.4.

Marked experiemental as of Bugzilla 5.0.

=head3 Parameters

In addition to the parameters below, this method also accepts the standard
L<BZ::Client::Bug/include_fields> and L<BZ::Client::Bug/exclude_fields> arguments.

You could get classifications info by supplying their names and/or ids. So,
this method accepts the following parameters:

=over 4

=item ids

An array of classification ids.

=item names

An array of classification names.

=back

=head3 Returns

An array of hashes as the corresponding value. Each element of the array represents
a classification that the user is authorized to see and has the following keys:

=over 4

=item id

I<id> (int) The id of the classification.

=item name

I<name> (string) The name of the classification.

=item description

I<description> (string) The description of the classificaion.

=item sort_key

I<sort_key> (int) The value which determines the order the classification is sorted.

=item products

An array of hashes. The array contains the products the user is authorized to
access within the classification. Each hash has the following keys:

=over 4

=item name

I<name> (string) The name of the product.

=item id

I<id> (int) The id of the product.

=item description

I<description> (string) The description of the product.

=back

=back

=head3 Errors

=over

=item 900 - Classification not enabled

Classification is not enabled on this installation.

=back

=head1 EXCEPTION HANDLING

See L<BZ::Client::Exception>

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Classification.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
