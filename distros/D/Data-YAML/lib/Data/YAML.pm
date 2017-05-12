package Data::YAML;

use strict;
use warnings;

use vars qw{$VERSION};

$VERSION = '0.0.7';

1;

__END__

=head1 NAME

Data::YAML - Easy YAML serialisation of Perl data structures

=head1 VERSION

This document describes Data::YAML version 0.0.7

=head1 DESCRIPTION

In the spirit of L<YAML::Tiny>, L<Data::YAML::Reader> and
L<Data::YAML::Writer> provide lightweight, dependency-free YAML
handling. While C<YAML::Tiny> is designed principally for working with
configuration files C<Data::YAML> concentrates on the transparent round-
tripping of YAML serialized Perl data structures.

As an example of why this distinction matters consider that
C<YAML::Tiny> doesn't handle hashes with keys containing non-printable
characters. This is fine for configuration files but likely to cause
problems when handling arbitrary Perl data structures. C<Data::YAML>
handles exotic hash keys correctly.

The syntax accepted by C<Data::YAML> is a subset of YAML. Specifically
it is the same subset of YAML that L<Data::YAML::Writer> produces. See
L<Data::YAML> for more information.

=head2 YAML syntax

Although YAML appears to be a simple language the entire YAML
specification is huge. C<Data::YAML> implements a small subset of the
complete syntax trading completeness for compactness and simplicity.
This restricted syntax is known (to me at least) as 'YAMLish'.

These examples demonstrates the full range of supported syntax. 

All YAML documents must begin with '---' and end with a line
containing '...'.

    --- Simple scalar
    ...

Unprintable characters are represented using standard escapes in double
quoted strings.

    --- "\t\x01\x02\n"
    ...

Array and hashes are represented thusly

    ---
      - "This"
      - "is"
      - "an"
      - "array"
    ...

    ---
      This: is
      a: hash
    ...

Structures may nest arbitrarily

    ---
      -
        name: 'Hash one'
        value: 1
      -
        name: 'Hash two'
        value: 2
    ...

Undef is a tilde

    --- ~
    ...

=head2 Uses

Use C<Data::YAML> may be used any time you need to freeze and thaw Perl
data structures into a human readable format. The output from
C<Data::YAML::Writer> should be readable by any YAML parser.

C<Data::YAML> was originally written to allow machine-readable
diagnostic information to be passed from test scripts to
L<TAP::Harness>. That means that if you're writing a testing system that
needs to output TAP version 13 or later syntax you might find
C<Data::YAML> useful.

Read more about TAP and YAMLish here: L<http://testanything.org/wiki>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<data-yaml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

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
