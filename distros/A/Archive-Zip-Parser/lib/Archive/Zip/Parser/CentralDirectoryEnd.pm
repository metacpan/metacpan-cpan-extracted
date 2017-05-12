package Archive::Zip::Parser::CentralDirectoryEnd;

use warnings;
use strict;

sub get_signature {
    my $self = shift;
    return unpack( 'H*', pack( 'N', $self->{'_signature'} ) );
}

sub get_disk_number {
    my $self = shift;
    return $self->{'_disk_number'};
}

sub get_start_disk_number {
    my $self = shift;
    return $self->{'_start_disk_number'};
}

sub get_total_disk_entries {
    my $self = shift;
    return $self->{'_total_disk_entries'};
}

sub get_total_entries {
    my $self = shift;
    return $self->{'_total_entries'};
}

sub get_size {
    my $self = shift;
    return $self->{'_size'};
}

sub get_start_offset {
    my $self = shift;
    return $self->{'_start_offset'};
}

sub get_zip_comment_length {
    my $self = shift;
    return $self->{'_zip_comment_length'};
}

sub get_zip_comment {
    my $self = shift;
    return $self->{'_zip_comment'};
}

1;
__END__

=head1 NAME

Archive::Zip::Parser::CentralDirectoryEnd - Provides methods to access end of
central directory fields.

=head1 VERSION

This document describes Archive::Zip::Parser::CentralDirectoryEnd version 0.0.3


=head1 SYNOPSIS

    use Archive::Zip::Parser;

    my $parser
      = Archive::Zip::Parser->new( { file_name => 'secret_files.zip' } );
    $parser->parse();
    my $central_directory_end = $parser->get_central_directory_end();
    my $total_entries = $central_directory_end->get_total_entries();


=head1 DESCRIPTION

Provides methods to access end of central directory fields.

=head1 INTERFACE

=over 4

=item C<< get_signature() >>

Returns central directory end signature in hexadecimal (06054b50).

=item C<< get_disk_number() >>

Returns number of the disk.

=item C<< get_start_disk_number() >>

Returns number of the disk with the start of the central directory.

=item C<< get_total_disk_entries() >>

Returns total number of entries in the central directory on the disk.

=item C<< get_total_entries() >>

Returns total number of entries in the central directory.

=item C<< get_size() >>

Returns size of the central directory.

=item C<< get_start_offset() >>

Returns offset of start of central directory with respect to the starting disk
number.

=item C<< get_zip_comment_length() >>

Returns .ZIP file comment length.

=item C<< get_zip_comment() >>

Returns .ZIP file comment.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Archive::Zip::Parser::CentralDirectoryEnd requires no configuration files or
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

=item * L<Archive::Zip::Parser::Entry>

=item * L<Archive::Zip::Parser::Entry::CentralDirectory>

=item * L<Archive::Zip::Parser::Entry::DataDescriptor>

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
