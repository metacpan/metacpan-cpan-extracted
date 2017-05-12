package Acme::Base64;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.2');

use MIME::Base64;
use Filter::Simple;

FILTER {
    $_ = decode_base64($_);
};

1;
__END__

=head1 NAME

Acme::Base64 - Write Perl in Base64 encoding

=head1 VERSION

This document describes Acme::Base64 version 0.0.2


=head1 SYNOPSIS

    use Acme::Base64;

    cHJpbnQgIkhlbGxvIHdvcmxkIVxuIjsK


=head1 DESCRIPTION

B<Bored writing normal Perl code?>

Write Perl in Base64 encoding. :-)


=head1 INTERFACE 

Every line of code after C<use Acme::Base64> should be encoded in Base64
encoding.


=head1 CONFIGURATION AND ENVIRONMENT

Acme::Base64 requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over 4

=item L<MIME::Base64>

First released with perl 5.007003

=item L<Filter::Simple>

First released with perl 5.007003

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-base64@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Alan Haggai Alavi  C<< <haggai@cpan.org> >>


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
