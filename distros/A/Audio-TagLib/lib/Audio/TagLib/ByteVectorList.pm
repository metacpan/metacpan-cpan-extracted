package Audio::TagLib::ByteVectorList;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ByteVectorList - A list of ByteVectors

=head1 SYNOPSIS

  use Audio::TagLib::ByteVectorList;
  
  my $i = Audio::TagLib::ByteVctorList->split(
    Audio::TagLib::ByteVector->new("Here I am"), 
    Audio::TagLib::ByteVector->new(" "));
  print $i->toByteVector()->data(), "\n"; # got "here I am"

=head1 DESCRIPTION

A List specialization with some handy features useful for ByteVectors.

=over

=item I<new()>

Construct an empty ByteVectorList.

=item I<new(L<ByteVectorList|Audio::TagLib::ByteVectorList> $l)>

Make a shallow, implicitly shared, copy of $l. Because this is
 implicitly shared, this method is lightweight and suitable for
 pass-by-value usage. 

=item I<DESTROY()>

Destroys this ByteVectorList instance.

=item I<L<ByteVector|Audio::TagLib::ByteVector>
toByteVector(L<ByteVector|Audio::TagLib::ByteVector> $separator = " ")>

Convert the ByteVectorList to a ByteVector separated by $separator. By
  default a space is used.

=item I<L<ByteVectorList|Audio::TagLib::ByteVectorList>
split(L<ByteVector|Audio::TagLib::ByteVector> $v,
L<ByteVector|Audio::TagLib::ByteVector> $pattern, IV $byteAlign = 1)>
[static] 

Splits the ByteVector $v into several strings at $pattern. This will
not include the pattern in the returned ByteVectors.

=item I<L<ByteVectorList|Audio::TagLib::ByteVectorList>
split(L<ByteVector|Audio::TagLib::ByteVector> $v,
L<ByteVector|Audio::TagLib::ByteVector> $pattern, IV byteAlign, IV max)>
[static] 

Splits the ByteVector $v into several strings at $pattern. This will
not include the pattern in the returned ByteVectors. $max is the
maximum number of entries that will be separated.  If $max for
instance is 2 then a maximum of 1 match will be found and the vector
will be split on that match.


=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib>

=head1 AUTHOR

Dongxu Ma, E<lt>dongxu@cpan.orgE<gt>

=head1 MAINTAINER

Geoffrey Leach GLEACH@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Dongxu Ma

Copyright (C) 2011 - 2013 Geoffrey Leach


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
