package AudioCD;

use strict;
use vars qw($VERSION @ISA @EXPORT $IsMac);
use Exporter;

@ISA = qw(DynaLoader);
$VERSION = '0.20';

$IsMac = $^O eq 'MacOS';

if ($IsMac) {
    require AudioCD::Mac;
    AudioCD::Mac->import();
    push @EXPORT, @AudioCD::Mac::EXPORT;
    @ISA = qw(AudioCD::Mac);
}

1;
__END__

=head1 NAME

AudioCD - Module for basic Audio CD control

=head1 SYNOPSIS

    use AudioCD;
    # see below

=head1 DESCRIPTION

See C<AudioCD::Mac> for more information.  Right now, this module has 
support only for MacPerl.  Please feel free to write other modules
for Your Favorite Platform and let me know about it.


=head1 AUTHOR

Chris Nandor F<E<lt>pudge@pobox.comE<gt>>
http://pudge.net/

Copyright (c) 1998 Chris Nandor.  All rights reserved.  This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself.  Please see the Perl Artistic License.


=head1 VERSION

=over 4

=item v0.20, Wednesday, December 9, 1998

Renamed to C<AudioCD>, added controls for Audio CD.

=item v0.10, Thursday, October 8, 1998

First version, made for Mac OS to get CDDB TOC data.

=back


=head1 SEE ALSO

F<CDDB.pm>

=cut
