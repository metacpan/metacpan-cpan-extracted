#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use warnings;
use strict;

package Audio::MPD::Types;
# ABSTRACT: types used in the distribution
$Audio::MPD::Types::VERSION = '2.004';
use Moose::Util::TypeConstraints;

enum CONNTYPE => [ qw{ reuse once } ];

1;

__END__

=pod

=head1 NAME

Audio::MPD::Types - types used in the distribution

=head1 VERSION

version 2.004

=head1 DESCRIPTION

This module implements the specific types used by the distribution, and
exports them (exporting is done directly by
L<Moose::Util::TypeConstraints>.

Current types defined:

=over 4

=item * CONNTYPE - a simple enumeration, allowing only C<reuse>
or C<once>.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
