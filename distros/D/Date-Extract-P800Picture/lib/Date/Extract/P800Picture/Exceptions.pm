# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2008-2019, Roland van Ipenburg
package Date::Extract::P800Picture::Exceptions v1.1.2;
use strict;
use warnings;

use utf8;
use 5.014000;

use Exception::Class qw(
  DateExtractP800PictureException
);

1;

__END__

=encoding utf8

=for stopwords Ericsson Filename MERCHANTABILITY POSIX filename timestamp
Ipenburg

=head1 NAME

Date::Extract::P800Picture::Exceptions - exceptions.

=head1 VERSION

This document describes Date::Extract::P800Picture::Exceptions version v1.1.2.

=head1 SYNOPSIS

    use Date::Extract::P800Picture::Exceptions;
    DateExtractP800PictureException->throw( error => $ERR );

=head1 DESCRIPTION

Provides C<DateExtractP800PictureException> exception classes based on
L<Exception::Class::Base|Exception::Class::Base>.

=head1 SUBROUTINES/METHODS

All inherited from L<Exception::Class::Base|Exception::Class::Base/METHODS>.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

L<Exception::Class|Exception::Class>

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<RT for rt.cpan.org|
https://rt.cpan.org/Dist/Display.html?Queue=Date-Extract-P800Picture>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008-2019, Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
