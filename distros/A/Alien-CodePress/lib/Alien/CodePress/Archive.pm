# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package Alien::CodePress::Archive;

use strict;
use warnings;
use 5.00600;

use Carp;
use vars qw($VERSION);

$VERSION            = 1.03;

my $CODEPRESS_VERSION  = '0.9.6';

my $CODEPRESS_URL      = 'http://codepress.org/download/';

my $CODEPRESS_FILE_FMT = 'codepress-v.%s.zip';

sub version {
    return $CODEPRESS_VERSION;
}


sub filename {
   my ($class) = @_;

   my $filename = sprintf $CODEPRESS_FILE_FMT, $CODEPRESS_VERSION;

   return $filename;
}

sub url {
   my ($class) = @_;

   my $url = $CODEPRESS_URL . $class->filename();

   return $url;
}

1;

__END__


=pod

=for stopwords CodePress namespace Solem

=head1 NAME

Alien::CodePress::Archive - CodePress archive utilities.

=head1 VERSION

This document describes Alien::CodePress version v1.0

=head1 SYNOPSIS

    use Alien::CodePress::Archive;

    my $codepress_version = Alien::CodePress::Archive->version;

    # ... 

    my $this_version_download = Alien::CodePress::Archive->url();

    my $this_version_filename = Alien::CodePress::Archive->filename();


=head1 DESCRIPTION

Utility for finding the URL and archive filename for the current CodePress version.

=head1 SUBROUTINES/METHODS


=head2 CLASS METHODS

=head3 C<version()>

Get the CodePress version string.

=head3 C<filename()>

Get the archive filename for this CodePress version.

=head3 C<url>

Get the download URL for this CodePress version.

=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

=head1 DEPENDENCIES


=over 4

=item * perl 5.6.1

=back



=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-alien-codepress@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<http://codepress.org/>

The official CodePress home page.

=item * L<Alien>

The manifesto of the Alien namespace.

=back

=head1 AUTHOR

Ask Solem, C<< ask@0x61736b.net >>.


=head1 LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem C<< ask@0x61736b.net >>.

All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
