package Audio::TagLib::ID3v1::StringHandler;

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

Audio::TagLib::ID3v1::StringHandler - A abstraction for the string to data
encoding in ID3v1 tags. 

=head1 DESCRIPTION

ID3v1 should in theory always contain ISO-8859-1 (Latin1) data. In
practise it does not. Audio::TagLib by default only supports ISO-8859-1 data
in ID3v1 tags.

However by subclassing this class and reimplementing parse() and
render() and setting your reimplementation as the default with
ID3v1::Tag::setStringHandler() you can define how you would like these
transformations to be done. 

B<WARNING> It is advisable B<NOT> to write non-ISO-8859-1 data to
ID3v1 tags. Please consider disabling the writing of ID3v1 tags in the
case that the data is ISO-8859-1.

see I<L<ID3v1::Tag::setStringHandler()|Audio::TagLib::ID3v1::Tag>>

=over

=item I<L<String|Audio::TagLib::String>
parse(L<ByteVector|Audio::TagLib::ByteVector> $data)> 

Decode a string from $data. The default implementation assumes that
$data is an ISO-8859-1 (Latin1) character array.

=item I<ByteVector|Audio::TagLib::ByteVector> render(L<String|Audio::TagLib::String>
$s)> 

Encode a ByteVector with the data from $s. The default implementation
assumes that $s is an ISO-8859-1 (Latin1) string.

B<WARNING> It is recommended that you B<NOT> override this method, but
instead do not write an ID3v1 tag in the case that the data is not
ISO-8859-1. 

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
