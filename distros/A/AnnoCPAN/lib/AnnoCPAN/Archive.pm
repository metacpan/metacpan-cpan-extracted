package AnnoCPAN::Archive;

$VERSION = '0.22';

use strict;
use warnings;

use Archive::Zip;
use Archive::Tar;

=head1 NAME

AnnoCPAN::Archive - Simple archive abstraction layer

=head1 SYNOPSIS

=head1 DESCRIPTION

AnnoCPAN is expected to handle both tar.gz and zip archives. L<Archive::Tar>
and L<Archive::Zip> take care of accessing those types of files, but they 
have different interfaces. AnnoCPAN::Archive provides a common interface to 
the very few methods that are actually needed.

=head1 METHODS

=over

=item $class->new($fname)

Create a new AnnoCPAN::Archive object. It uses the filename extension, which
must be .zip or .tar.gz, to determine the type of archive. Returns undefined
if there is any problem.

=cut

sub new {
    my ($class, $fname) = @_;
    return AnnoCPAN::Archive::Zip->new($fname) 
        if $fname =~ /\.zip$/;
    return AnnoCPAN::Archive::Tar->new($fname) 
        if $fname =~ /(\.tar\.gz|\.tgz)$/;
    return;
}

=item $obj->files

Returns a list of the filenames contained in the archive.

=item $obj->read_file($fname)

Returns as a string the contents of file $fname in the archive.

=cut

package AnnoCPAN::Archive::Zip;
our @ISA = qw(AnnoCPAN::Archive Archive::Zip::Archive);
sub new { shift->Archive::Zip::Archive::new(@_) }
sub files { shift->memberNames }
sub read_file { shift->contents(@_) }

package AnnoCPAN::Archive::Tar;
our @ISA = qw(AnnoCPAN::Archive Archive::Tar);
sub new { shift->Archive::Tar::new(@_) }
sub files { shift->list_files }
sub read_file { shift->get_content(@_) }

=back

=head1 SEE ALSO

L<Archive::Tar>, L<Archive::Zip>

There are other modules on CPAN, such as L<Archive::Any>, L<Archive::Extract>,
and L<File::Archive>, that seem to do similar things, but they didn't appear to
do exactly what I wanted or seemed too complicated, so I resorted to rolling my
own. It was just a dozen lines of code (heck, this documentation is way longer
than the code itself!)

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;

