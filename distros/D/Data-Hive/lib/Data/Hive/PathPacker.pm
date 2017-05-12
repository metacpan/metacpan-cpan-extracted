use strict;
use warnings;
package Data::Hive::PathPacker;
# ABSTRACT: a thing that converts paths to strings and then back
$Data::Hive::PathPacker::VERSION = '1.013';
#pod =head1 DESCRIPTION
#pod
#pod Data::Hive::PathPacker classes are used by some L<Data::Hive::Store> classes to convert hive paths to strings so that deep hives can be stored in flat storage.
#pod
#pod Path packers must implement two methods:
#pod
#pod =method pack_path
#pod
#pod   my $str = $packer->pack_path( \@path );
#pod
#pod This method is passed an arrayref of path parts and returns a string to be used
#pod as a key in flat storage for the path.
#pod
#pod =method unpack_path
#pod
#pod   my $path_arrayref = $packer->unpack_path( $str );
#pod
#pod This method is passed a string and returns an arrayref of path parts
#pod represented by the string.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive::PathPacker - a thing that converts paths to strings and then back

=head1 VERSION

version 1.013

=head1 DESCRIPTION

Data::Hive::PathPacker classes are used by some L<Data::Hive::Store> classes to convert hive paths to strings so that deep hives can be stored in flat storage.

Path packers must implement two methods:

=head1 METHODS

=head2 pack_path

  my $str = $packer->pack_path( \@path );

This method is passed an arrayref of path parts and returns a string to be used
as a key in flat storage for the path.

=head2 unpack_path

  my $path_arrayref = $packer->unpack_path( $str );

This method is passed a string and returns an arrayref of path parts
represented by the string.

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
