package Audio::TagLib::APE::Item;

use 5.008003;
use strict;
use warnings;

our $VERSION = '1.1';

use Audio::TagLib;

## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)
our %_ItemTypes = (
    "Text"    => 0,
    "Binary"  => 1,
    "Locator" => 2,
);

sub item_types { return \%_ItemTypes; }

1;
__END__

=pod

=begin stopwords

Dongxu

=end stopwords

=head1 NAME

Audio::TagLib::APE::Item - An implementation of APE-items

=head1 SYNOPSIS

  use Audio::TagLib::APE::Item;
  
  my $key   = Audio::TagLib::String->new("key");
  my $value = Audio::TagLib::String->new("value");
  my $i     = Audio::TagLib::APE::Item->new($key, $value);
  $i->setType("Text");
  $i->setReadOnly(1) unless $i->isReadOnly();
  my $data  = $i->render();

=head1 DESCRIPTION

This class provides the features of items in the APEv2 standard.

=over

=item I<new()>

Constructs an empty item.

=item I<new(L<String|Audio::TagLib::String> $key, L<String|Audio::TagLib::String>
$value)> 

Constructs an item with $key and $value. 

=item I<new(L<String|Audio::TagLib::String> $key,
L<StringList|Audio::TagLib::StringList> $values)>

Constructs an item with $key and $values.

=item I<new(L<Item|Audio::TagLib::APE::Item> $item)>

Construct an item as a copy of $item.

=item I<DESTROY()>## no critic (ProhibitPackageVars)
## no critic (ProhibitMixedCaseVars)


Destroys the item.

=item I<copy(L<Item|Audio::TagLib::APE::Item> $item)>

Copies the contents of $item into this item.

=item I<L<String|Audio::TagLib::String> key()>

Returns the key.

=item I<L<ByteVector|Audio::TagLib::ByteVector> value()>

Returns the binary value.

=item I<IV size()>

Returns the size of the full item.

=item I<L<String|Audio::TagLib::String> toString()>

Returns the value as a single string. In case of multiple strings, the
first is returned.

=item I<L<StringList|Audio::TagLib::StringList> toStringList()>

Returns the value as a string list.

=item I<L<ByteVector|Audio::TagLib::ByteVector> render()>

Render the item to a ByteVector.

=item I<void parse(L<ByteVector|Audio::TagLib::ByteVector> $data)>

Parse the item from the ByteVector $data.

=item I<void setReadOnly(BOOL $b)>

Set the item to read-only.

=item I<BOOL isReadOnly()>

 Return true if the item is read-only.

=item I<void setType(PV $type)>

Sets the type of the item to $type.

see I<item_types>

=item I<PV type()>

Returns the type of the item.

see I<item_types>

=item I<BOOL isEmpty()>

Returns if the item has any real content.

=item %_ItemTypes

Deprecated. See I<item_types>

=item item_types

Returns a reference to  %_ItemTypes, which  lists all available itemtypes.
C<keys $%Audio::TagLib::APE::Item::item_types()> lists all available itemtypes.

see I<L<setType>>

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

L<Audio::TagLib|Audio::TagLib>

=head1 AUTHOR

Dongxu Ma, E<lt>dongxu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Dongxu Ma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
