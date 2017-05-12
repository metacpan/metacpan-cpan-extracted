package Archive::StringToZip;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);

use Carp qw(croak);
use IO::String ();
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use base qw(Archive::Zip);

require Exporter;
@ISA = qw(Exporter Archive::Zip::Archive Archive::Zip);
@EXPORT_OK = qw(zipString);


$VERSION = '1.03';

sub zipString {
    my $self = ref($_[0]) ? shift : __PACKAGE__->new();
    my ($string, $filename) = @_;

    croak 'Cannot archive an undefined string' unless defined $string;
    $filename = 'file.txt' unless $filename;

    my $SH = IO::String->new();
    
    my $member = $self->addString($string, $filename);
    $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
    $member->desiredCompressionLevel( 9 );

    my $status = $self->writeToFileHandle($SH);
    die $! if $status != AZ_OK;

    binmode STDOUT;     # necessary for Win32 and does no harm on *nix
    $SH->setpos(0);
    return do { local $/ = undef; $SH->getline };
}

1;

__END__

=head1 NAME

Archive::StringToZip - Transforms a string to a zip

=head1 SYNOPSIS

A simple wrapper around L<Archive::Zip> for transforming a string
to a compressed zip returned as a filehandle. Inherits all of
Archive::Zip's methods.

This module operates in memory and avoids the use of temporary files.
If you want to send the contents of a zip to standard output, for
example, you might find this module useful.

=head1 USAGE

=over

=item OO-style:

 use Archive::StringToZip;

 my $stz = Archive::StringToZip->new();
 my $zip = $stz->zipString($string,$filename) 
            or die "Zipping string failed";

or 

=item Procedural-style

 use Archive::StringToZip qw(zipString);

 my $zip = zipString($string,$filename) 
            or die "Zipping string failed";

or even

=item Classy-style

 use Archive::StringToZip;

 my $zip = Archive::StringToZip::zipString($string,$filename) 
            or die "Zipping string failed";

=item Then return a zip file to a browser download

 print qq~Content-Type: application/x-zip\nContent-Disposition: attachment; Encoding: base64; filename="${filename}.zip"\n\n~;
 print $zip;

=back

=head1 METHODS

=over

=item new

 my $stz = Archive::StringToZip->new();

Constructs a new string zipping object

=item zipString

 my $zip_content = $stz->zipString($string, $filename);

or

 my $zip_content = zipString($string, $filename);

First argument is compulsory; second is optional. The default filename
is F<file.txt> if the second argument is undefined.

Converts a string (C<$string>) into a file (C<$filename>) in a compressed
zip file format which is returned as a string. 

Returns a false value on failure.

Sets C<binmode STDOUT> by default to help prevent Win32 systems being
confused about your output.

=back

=head1 DEPENDENCIES

L<Archive::Zip> and L<IO::String>.

=head1 MOTIVATION

We had users wanting to carry bulk exports of data from a database 
representing their online store's order history. After slurping the 
data out and converting it, the resulting CSV was pretty big, so 
compression was the way forward, et voila! Archive::StringToZip was
born.

=head1 AUTHORS

Robbie Bow and Tom Hukins sometime in spring 2006.

=head1 BUGS

Please report any bugs or feature requests to

C<bug-archive-stringtozip at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-StringToZip>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 ALTERNATIVES

L<IO::Compress::Zip>, unstable at the time of writing.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
