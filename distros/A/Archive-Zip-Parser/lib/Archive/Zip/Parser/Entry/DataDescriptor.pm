package Archive::Zip::Parser::Entry::DataDescriptor;

use warnings;
use strict;

use base qw( Archive::Zip::Parser::Entry::Header );

1;
__END__

=head1 NAME

Archive::Zip::Parser::Entry::DataDescriptor - Provides methods to access
data descriptor fields.

=head1 VERSION

This document describes Archive::Zip::Parser::Entry::DataDescriptor version 0.0.3


=head1 SYNOPSIS

    use Archive::Zip::Parser;

    my $parser
      = Archive::Zip::Parser->new( { file_name => 'secret_files.zip' } );
    $parser->parse();
    my $entry = $parser->get_entry(3);
    my $data_descriptor = $entry->get_data_descriptor();
    my $crc_32 = $data_descriptor->get_crc_32();


=head1 DESCRIPTION

Provides methods to access data descriptor fields.

=head1 INTERFACE

=over 4

=item C<< get_crc_32() >>

Returns CRC-32 in hexadecimal.

=item C<< get_compressed_size() >>

Returns compressed size in bytes.

=item C<< get_uncompressed_size() >>

Returns uncompressed size in bytes.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Archive::Zip::Parser::Entry::DataDescriptor requires no configuration files or
environment variables.


=head1 DEPENDENCIES

=over 4

=item L<autodie>

First released with perl 5.010001

=item L<Carp>

First released with perl 5

=item L<Data::ParseBinary>

Not in CORE

=item L<version>

First released with perl 5.009

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-archive-zip-parser@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alan Haggai Alavi  C<< <haggai@cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Thanks to Shain Padmajan (L<http://shain.co.in/>) for helping me shorten method
names.


=head1 SEE ALSO

=over 4

=item * L<Archive::Zip::Parser>

=item * L<Archive::Zip::Parser::CentralDirectoryEnd>

=item * L<Archive::Zip::Parser::Entry>

=item * L<Archive::Zip::Parser::Entry::CentralDirectory>

=item * L<Archive::Zip::Parser::Entry::LocalFileHeader>

=back


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Alan Haggai Alavi C<< <haggai@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
