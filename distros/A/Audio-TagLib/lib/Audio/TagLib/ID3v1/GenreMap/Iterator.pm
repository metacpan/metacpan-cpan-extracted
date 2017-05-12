package Audio::TagLib::ID3v1::GenreMap::Iterator;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

use overload
    q(${}) => sub { my $data = shift->data(); \$data; },
    q(=)   => sub { __PACKAGE__->new( $_[0] ); },
    q(++)  => sub { shift->next(); },
    q(--)  => sub { shift->last(); };

#  q(+=)  => sub { shift->forward($_[0]);},
#  q(-=)  => sub { shift->backward($_[0]);};

1;

__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::ID3v1::GenreMap::Iterator - Perl-only class

=head1 SYNOPSIS

  use Audio::TagLib::ID3v1::GenreMap::Iterator;
  
  my $map = Audio::TagLib::ID3v1->genreMap();
  my $i   = $map->begin();
  print $$i, "\n"; # got 123

=head1 DESCRIPTION

Implements C++ std::map::iterator to be corporately used with
L<GenreMap|Audio::TagLib::ID3v1::GenreMap>.

=over

=item I<new()>

Generates an iterator attached with no map.

=item I<new(L<Iterator|Audio::TagLib::ID3v1::GenreMap::Iterator> $it)>

Copy constructor.

=item I<DESTROY()>

Deletes the instance.

=item I<IV data()>

Returns the IV pointed by current iterator.

overloaded by operator q(${})

=item I<L<Iterator|Audio::TagLib::ID3v1::GenreMap::Iterator> next()>

Moves to next item.

overloaded by operator q(++)

=item I<L<Iterator|Audio::TagLib::ID3v1::GenreMap::Iterator> last()>

Moves to last item.

overloaded by operator q(--)

=item I<void copy(L<Iterator|Audio::TagLib::ID3v1::GenreMap::Iterator> $it)>

Makes a copy of $it.


=back


=head2 OVERLOADED OPERATORS

B<${} = ++ -->

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
