package Acme::CPAN::Testers::FAIL;
BEGIN {
  $Acme::CPAN::Testers::FAIL::VERSION = '0.02';
}

#ABSTRACT: generate a FAILing test report

use strict;
use warnings;

q[defectus semper];


__END__
=pod

=head1 NAME

Acme::CPAN::Testers::FAIL - generate a FAILing test report

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Acme::CPAN::Testers::FAIL generates a C<FAIL> test report when run by a CPAN Tester.

That's pretty much it, really.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

