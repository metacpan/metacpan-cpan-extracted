package Acme::ExceptionEater;

use strict;
use warnings;

use vars qw( $VERSION );
use version; $VERSION = qv('0.0.1');

# Module implementation here

sub new { bless {}, shift }
sub DESTROY { eval {} }

1; # Magic true value required at end of module
__END__

=head1 NAME

Acme::ExceptionEater - Prevents eval from returning an exception.

=head1 VERSION

This document describes Acme::ExceptionEater version 0.0.1

=head1 SYNOPSIS

    use Acme::ExceptionEater;
    eval {
	my $ee = Acme::ExceptionEater->new();
	die 'My final wish is for you to know this...';
    };
    # $@ is still ''

=head1 DESCRIPTION

Placing an Acme::ExceptionEater object in a lexical in the
outer-most scope of an C<eval> will prevent exceptions from
escaping the C<eval> where they may confuse, annoy, frighten,
or inform others.

Simply instanciate an Acme::ExceptionEater object at the
start of the C<eval>.  When the eater goes out of scope and
Perl does garbage collection, it will eat any exceptions
that might be waiting to pass on their final words to
the code after the C<eval>.

=head1 METHODS

=over 4

=item new

Creates a new Acme::ExceptionEater object.  For Acme::ExceptionEater
to work, this object must not be prematurely destroyed.

=back

=head1 DIAGNOSTICS

None.  Acme::ExceptionEater produces fewer than zero error messages.

=head1 CONFIGURATION AND ENVIRONMENT
  
Acme::ExceptionEater requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-exceptioneater@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 CONTRIBUTORS

Author: Kyle Hasselbacher  C<< <kyleha@gmail.com> >>
http://perlmonks.org/?node=kyle

The idea for Acme::ExceptionEater came from an interaction with
Tye McQueen, http://perlmonks.org/?node=tye at
http://perlmonks.org/?node_id=637425

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kyle Hasselbacher C<< <kyleha@gmail.com> >>.
All rights reserved.

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
