package Array::RefElem;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(av_store av_push hv_store);

$VERSION = '1.00';

Array::RefElem->bootstrap($VERSION);

1;

__END__

=head1 NAME

Array::RefElem - Set up array elements as aliases

=head1 SYNOPSIS

 use Array::RefElem qw(av_store av_push hv_store);

 av_store(@a, 1, $a);
 av_push(@a, $a);
 hv_store(%h, $key, $a);

=head1 DESCRIPTION

This module gives direct access to some of the internal Perl routines
that let you store things in arrays and hashes.  The following
functions are available:

=over

=item av_store(@array, $index, $value)

Stores $value in @array at the specified $index.  After executing this call,
$array[$index] and $value denote the same thing.

=item av_push(@array, $value)

Pushes $value onto the @array.  After executing this call, $array[-1] and $value
denote the same thing.

=item hv_store(%hash, $key, $value);

Stores $value in the %hash with the given $key. After executing this call,
$hash{$key} and $value denote the same thing.

=back

=head1 SEE ALSO

L<perlguts>

=head1 COPYRIGHT

Copyright 2000 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
