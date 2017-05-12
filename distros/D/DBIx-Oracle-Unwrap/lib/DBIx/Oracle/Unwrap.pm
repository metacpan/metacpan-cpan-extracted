package DBIx::Oracle::Unwrap;
use strict;
use MIME::Base64;
use IO::Uncompress::Inflate qw(inflate $InflateError);
use Readonly;
use File::Slurp;

=head1 NAME

DBIx::Oracle::Unwrap - Unwrap code obfuscated with the Oracle wrap command

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

This class unwraps text that has been obfuscated using the wrap utiltity
supplied with version 10 of Oracle and above. Note that it does not unwrap
text from earlier versions, as the method of obfuscation is different

How to unwrap code in a file

    use DBIx::Oracle::Unwrap;
    my $filename       = "$HOME/plsql/mypackage.plb";
    my $unwrapper      = DBIx::Oracle::Unwrap->new();
    my $unwrapped_text = $unwrapper->unwrap_file($filename);

How to unwrap code in the database.

    use DBIx::Oracle::Unwrap;
    use DBI;
    
    my $dbh = DBI->connect('DBI:Oracle:orcl', 'scott', 'tiger');
    
    my $source_sql = q/
        SELECT text
        FROM   user_source
        WHERE  name = 'MYPACKAGE'
        AND    type = 'PACKAGE BODY'
        ORDER  BY line
    /;
    
    my $source         = join("",@{$dbh->selectcol_arrayref($source_sql)});
    my $unwrapper      = DBIx::Oracle::Unwrap->new();
    my $unwrapped_text = $unwrapper->unwrap($source);

=head1 METHODS

=cut

# this is the substituion table. All the characters in the base64 decoded text
# must be replaced with its lookup

Readonly::Array my @sub_table => (
    0x3d, 0x65, 0x85, 0xb3, 0x18, 0xdb, 0xe2, 0x87, 0xf1, 0x52, 0xab, 0x63,
    0x4b, 0xb5, 0xa0, 0x5f, 0x7d, 0x68, 0x7b, 0x9b, 0x24, 0xc2, 0x28, 0x67,
    0x8a, 0xde, 0xa4, 0x26, 0x1e, 0x03, 0xeb, 0x17, 0x6f, 0x34, 0x3e, 0x7a,
    0x3f, 0xd2, 0xa9, 0x6a, 0x0f, 0xe9, 0x35, 0x56, 0x1f, 0xb1, 0x4d, 0x10,
    0x78, 0xd9, 0x75, 0xf6, 0xbc, 0x41, 0x04, 0x81, 0x61, 0x06, 0xf9, 0xad,
    0xd6, 0xd5, 0x29, 0x7e, 0x86, 0x9e, 0x79, 0xe5, 0x05, 0xba, 0x84, 0xcc,
    0x6e, 0x27, 0x8e, 0xb0, 0x5d, 0xa8, 0xf3, 0x9f, 0xd0, 0xa2, 0x71, 0xb8,
    0x58, 0xdd, 0x2c, 0x38, 0x99, 0x4c, 0x48, 0x07, 0x55, 0xe4, 0x53, 0x8c,
    0x46, 0xb6, 0x2d, 0xa5, 0xaf, 0x32, 0x22, 0x40, 0xdc, 0x50, 0xc3, 0xa1,
    0x25, 0x8b, 0x9c, 0x16, 0x60, 0x5c, 0xcf, 0xfd, 0x0c, 0x98, 0x1c, 0xd4,
    0x37, 0x6d, 0x3c, 0x3a, 0x30, 0xe8, 0x6c, 0x31, 0x47, 0xf5, 0x33, 0xda,
    0x43, 0xc8, 0xe3, 0x5e, 0x19, 0x94, 0xec, 0xe6, 0xa3, 0x95, 0x14, 0xe0,
    0x9d, 0x64, 0xfa, 0x59, 0x15, 0xc5, 0x2f, 0xca, 0xbb, 0x0b, 0xdf, 0xf2,
    0x97, 0xbf, 0x0a, 0x76, 0xb4, 0x49, 0x44, 0x5a, 0x1d, 0xf0, 0x00, 0x96,
    0x21, 0x80, 0x7f, 0x1a, 0x82, 0x39, 0x4f, 0xc1, 0xa7, 0xd7, 0x0d, 0xd1,
    0xd8, 0xff, 0x13, 0x93, 0x70, 0xee, 0x5b, 0xef, 0xbe, 0x09, 0xb9, 0x77,
    0x72, 0xe7, 0xb2, 0x54, 0xb7, 0x2a, 0xc7, 0x73, 0x90, 0x66, 0x20, 0x0e,
    0x51, 0xed, 0xf8, 0x7c, 0x8f, 0x2e, 0xf4, 0x12, 0xc6, 0x2b, 0x83, 0xcd,
    0xac, 0xcb, 0x3b, 0xc4, 0x4e, 0xc0, 0x69, 0x36, 0x62, 0x02, 0xae, 0x88,
    0xfc, 0xaa, 0x42, 0x08, 0xa6, 0x45, 0x57, 0xd3, 0x9a, 0xbd, 0xe1, 0x23,
    0x8d, 0x92, 0x4a, 0x11, 0x89, 0x74, 0x6b, 0x91, 0xfb, 0xfe, 0xc9, 0x01,
    0xea, 0x1b, 0xf7, 0xce
);

sub _decode {
    my $self = shift;
    my $text = shift;
    
    return unless $text;

    # Decode text and ignore the SHA1 hash (first 20 characters)
    my $decoded = substr(decode_base64($text), 20, length($text) - 1);
    return unless $decoded;

    my ($zipped, $source);

    #Translate each character
    foreach my $byte (split //, $decoded) {
        $zipped .= chr($sub_table[ord($byte)]);
    }

    # Uncompress (inflate) the data
    my $status = inflate \$zipped => \$source
        or die "Can't decompress requested data: $InflateError\n";
    return $source;
}

=head2 new

Create an instance of DBIx::Oracle::Unwrap:

    my $unwrapper = DBIx::Oracle::Unwrap->new;

=cut

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

=head2 unwrap

Unwrap the provided text:

    my $unwrapped_text = $unwrapper->unwrap($mytext);

=cut

sub unwrap {
    my $self  = shift;
    my $text  = shift;
    my @line  = split("\n", $text);

    #    Line 20 marks the beginning the last line of the header. Everything
    # beyond is the wrapped code. The second number on line 20 is the length of
    # the base 64 encoded text. If the 20th line doesn't meet the pattern below
    # then chances are the code is either not wrapped, or it uses the wrapper
    # from Oracle 9

    #    The second line appears to be '0' in the older wrapper, so don't even
    # try unwrapping if that's the case with the supplied text

    return
      unless (($line[19] =~ /^[0-9a-f]+ [0-9a-f]+$/)
        && ($line[1] ne '0')
        && ($line[0] =~ /\bwrapped\b/));
    my $enc_source = join("", @line[20 .. scalar(@line) - 1]);
    return $self->_decode($enc_source);
}

=head2 unwrap_file

Unwrap the text in the file provided:

    $my $unwrapped_text = $unwrapper->unwrap_file($file_name);

=cut

sub unwrap_file {
    my $self      = shift;
    my $file_name = shift;
    my $file_text = read_file($file_name);
    return $self->unwrap($file_text);
}

=head1 SEE ALSO

L<unwrap> is a script supplied with this distribution that will
unwrap obfuscated files. It writes to STDOUT, so redirect to
a file if you want to keep the output

    unwrap mysource.plb > unwrapped.plb
    
=head1 ACKNOWLEDGEMENTS

This code is largely based on uwrap.py, by Niels Teusink. See
L<Unwrapping Oracle PL/SQL with unwrap.py|http://blog.teusink.net/2010/04/unwrapping-oracle-plsql-with-unwrappy.html>

Thanks to Niels for supporting this port of his code.

=head1 AUTHOR

Dan Horne, C<< <dhorne at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-oracle-unwrap at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Oracle-Unwrap>. I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Oracle::Unwrap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Oracle-Unwrap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Oracle-Unwrap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Oracle-Unwrap>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Oracle-Unwrap/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Dan Horne

This Perl implementation is based on Python code by Niels Teusink, 2010
L<Unwrapping Oracle PL/SQL with unwrap.py|http://blog.teusink.net/2010/04/unwrapping-oracle-plsql-with-unwrappy.html>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of DBIx::Oracle::Unwrap
