package Audio::TagLib::StringList;

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

Audio::TagLib::StringList - A list of strings

=head1 SYNOPSIS

  use Audio::TagLib::StringList;
  my $i = Audio::TagLib::StringList->new();
  $i->append(Audio::TagLib::String->new("catch"));
  $i->append(Audio::TagLib::String->new("me!"));
  print $i->toString()->toCString(), "\n"; # got "catch me!"

=head1 DESCRIPTION

This is a spcialization of the List class with some members convention
for string operations.

=over

=item I<new()>

Constructs an empty StringList.

=item I<new(StringList $l)>

Make a shallow, implicitly shared, copy of $l. Because this is
 implicitly shared, this method is lightweight and suitable for
 pass-by-value usage.

=item I<new(L<String|Audio::TagLib::String> $s)>

Constructs a StringList with $s as a member.

=item I<new(L<ByteVectorList|Audio::TagLib::ByteVectorList> $vl, PV $t =
"Latin1")> 

Makes a deep copy of the data in $vl.

B<NOTE> This should only be used with the 8-bit codecs Latin1 and
 UTF8, when used with other codecs it will simply print a warning and
 exit. 

=item I<DESTROY()>

Destroys this StringList instance.

=item I<L<String|Audio::TagLib::String> toString(L<String|Audio::TagLib::String>
$separator = " ")>

Concatenate the list of strings into one string separated by
$separator.

=item I<StringList append(L<String|Audio::TagLib::String> $s)>

Appends $s to to the end of the list and returns a reference to the
list. 

=item I<StringList append(StringList $l)>

Appends all of the values in $l to the end of the list and returns a
reference to the list.

=item I<StringList split(L<String|Audio::TagLib::String> $s,
L<String|Audio::TagLib::String> $pattern)> [static]

Splits the String $s into several strings at $pattern. This will not
include the pattern in the returned strings.

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
