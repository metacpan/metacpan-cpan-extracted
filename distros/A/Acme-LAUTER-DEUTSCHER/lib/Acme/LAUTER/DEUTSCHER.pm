package Acme::LAUTER::DEUTSCHER;
use strict;
use warnings;

our $VERSION = '1.02';

use Carp;

use PerlIO::via::LAUTER_DEUTSCHER;

binmode STDOUT, ':via(LAUTER_DEUTSCHER)'
    or croak 'KONNTE NICHT BINMODE VON STDOUT EINSTELLEN!';

1;

__END__

=head1 NAME

Acme::LAUTER::DEUTSCHER - make your program's output indistinguishable from someone yelling German

=head1 SYNOPSIS

    use Acme::LAUTER::DEUTSCHER;
    
    print "Timmy pet the cute puppy.\n";

Running the above produces the following output:

    DIETER HAUSTIER DER NETTE WELPE!

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-lauter-deutscher@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ian Langworth, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

