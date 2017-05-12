package Acme::CPAN::Testers::PASS;
BEGIN {
  $Acme::CPAN::Testers::PASS::VERSION = '0.02';
}

#ABSTRACT: generate a PASSing test report

use strict;
use warnings;

q[Integer semper];


__END__
=pod

=head1 NAME

Acme::CPAN::Testers::PASS - generate a PASSing test report

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Acme::CPAN::Testers::PASS generates a C<PASS> test report when run by a CPAN Tester.

That's pretty much it, really.

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

