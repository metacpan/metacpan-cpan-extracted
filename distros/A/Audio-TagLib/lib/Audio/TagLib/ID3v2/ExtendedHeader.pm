package Audio::TagLib::ID3v2::ExtendedHeader;

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

Audio::TagLib::ID3v2::ExtendedHeader - ID3v2 extended header implementation

=head1 SYNOPSIS

  use Audio::TagLib::ID3v2::ExtendedHeader;
  
  my $i = Audio::TagLib::ID3v2::ExtendedHeader->new();
  $i->setData($data);

=head1 DESCRIPTION

This class implements ID3v2 extended headers. It attempts to follow,
both semantically and programatically, the structure specified in the
ID3v2 standard. The API is based on the properties of ID3v2 extended
headers specified there. If any of the terms used in this
documentation are unclear please check the specification in the linked
section. 

=over

=item I<new()>

Constructs an empty ID3v2 extended header.

=item I<DESTROY()>

Destroys the extended header.

=item I<UV size()>

Returns the size of the extended header. This is variable for the
extended header.

=item I<void setData(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Sets the data that will be used as the extended header. Since the
  length is not known before the extended header has been parsed, this
  should just be a pointer to the first byte of the extended
  header. It will determine the length internally and make that
  available through size().

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
