package Audio::TagLib::APE::ItemListMap::Iterator;

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

Audio::TagLib::APE::ItemListMap::Iterator - Perl-only class

=head1 SYNOPSIS

  use Audio::TagLib::APE::ItemListMap;
  
  my $key1   = Audio::TagLib::String->new("key1");
  my $key2   = Audio::TagLib::String->new("key2");
  my $value1 = Audio::TagLib::String->new("value1");
  my $value2 = Audio::TagLib::String->new("value2");
  my $item1  = Audio::TagLib::APE::Item->new($key1, $value1);
  my $item2  = Audio::TagLib::APE::Item->new($key2, $value2);
  my $map   = Audio::TagLib::APE::ItemListMap->new();
  $map->insert($key1, $item1);
  $map->insert($key2, $item2);
  my $i     = $map->begin();
  
  print $$i->toString()->toCString(), "\n"; # got "value1"
  $i++;
  print $i->data()->toString()->toCString(), "\n"; # got "value2"
  print ${--$i}->toString()->toCString(), "\n"; # got "value1"

=head1 DESCRIPTION

Implements C++ std::map::iterator to be corporately used with
L<ItemListMap|Audio::TagLib::APE::ItemListMap>.

=over

=item I<new()>

Generates an iterator attached with no map.

=item I<new(L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> $it)>

Copy constructor.

=item I<DESTROY()>

Deletes the instance.

=item I<L<Item|Audio::TagLib::APE::Item> data()>

Returns the L<Item|Audio::TagLib::APE::Item> pointed by current iterator.

overloaded by operator q(${})

=item I<L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> next()>

Moves to next item.

overloaded by operator q(++)

=item I<L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> last()>

Moves to last item.

Overloaded by operator q(--)

=item I<void copy(L<Iterator|Audio::TagLib::APE::ItemListMap::Iterator> $it)>

Makes a copy of $it.


=back

=head2 OVERLOADED OPERATORS

B<${} = ++ -->


=head2 EXPORT

None by default.



=head1 SEE ALSO

L<ItemListMap|Audio::TagLib::APE::ItemListMap> L<Audio::TagLib|Audio::TagLib>

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
