package Audio::TagLib::ID3v1;

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

Audio::TagLib::ID3v1 - Functions in this namespace

=head1 SYNOPSIS

  use Audio::TagLib::ID3v1;
  
  my $list     = Audio::TagLib::ID3v1->genreList();
  my $genremap = Audio::TagLib::ID3v1->genreMap();

=head1 DESCRIPTION

=over

=item I<L<StringList|Audio::TagLib::StringList> genreList()> [static]

Returns the list of canonical ID3v1 genre names in the order that they
are listed in the standard.

=item I<L<Genremap|Audio::TagLib::ID3v1::GenreMap> genreMap()> [static]

A "reverse mapping" that goes from the canonical ID3v1 genre name to
the respective genre number.

=item I<L<String|Audio::TagLib::String> genre(IV $index)> [static]

Returns the name of the genre at $index in the ID3v1 genre list. If
  $index is out of range -- less than zero or greater than 146 -- a
  null string will be returned.

=item I<IV genreIndex(L<String|Audio::TagLib::String> $name)> [static]

Returns the genre index for the (case sensitive) genre $name. If the
genre is not in the list 255 (which signifies an unknown genre in
ID3v1) will be returned.

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
