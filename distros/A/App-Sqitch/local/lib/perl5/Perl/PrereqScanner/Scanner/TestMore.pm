use strict;
use warnings;

package Perl::PrereqScanner::Scanner::TestMore 1.024;
# ABSTRACT: scanner to find recent Test::More usage

use Moose;
use List::Util 1.33 'none';
with 'Perl::PrereqScanner::Scanner';

sub scan_for_prereqs {
  my ($self, $ppi_doc, $req) = @_;

  return if none { $_ eq 'Test::More' } $req->required_modules;

  $req->add_minimum('Test::More' => '0.88') if grep {
      $_->isa('PPI::Token::Word') && $_->content eq 'done_testing';
  } map {
      my @c = $_->children;
      @c == 1 ? @c : ()
  } @{ $ppi_doc->find('Statement') || [] }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Perl::PrereqScanner::Scanner::TestMore - scanner to find recent Test::More usage

=head1 VERSION

version 1.024

=head1 DESCRIPTION

This scanner will check if a given test is using recent functions from
L<Test::More>, and increase the minimum version for this module
accordingly.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHORS

=over 4

=item *

Jerome Quelin

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 DESCRIPTION
#pod
#pod This scanner will check if a given test is using recent functions from
#pod L<Test::More>, and increase the minimum version for this module
#pod accordingly.
#pod
