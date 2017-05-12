use 5.010000;
use strict;
use warnings;

package Acme::Futuristic::Perl;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

require version;

&Internals::SvREADONLY($_, 0) for \($^V, $]);
$] = ($^V = 'version'->declare('v7.0.0'))->numify;
&Internals::SvREADONLY($_, 1) for \($^V, $]);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Acme::Futuristic::Perl - because Modern::Perl is too old

=head1 SYNOPSIS

	use Acme::Futuristic::Perl;

=head1 DESCRIPTION

Sets the C<< $] >> and C<< $^V >> variables to 7.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Futuristic-Perl>.

=head1 SEE ALSO

L<perlvar>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

