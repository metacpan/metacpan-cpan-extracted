
package Business::BR::Ids;

use 5;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( canon_id parse_id format_id random_id );
our @EXPORT = qw( test_id );

our $VERSION = '0.0022';
$VERSION = eval $VERSION;

use Carp;

# a hash from entity types to packages
my %types = (
  cpf => 'Business::BR::CPF',
  cnpj => 'Business::BR::CNPJ',
  ie => 'Business::BR::IE',
  pis => 'Business::BR::PIS',
);


# invoke($type, $subroot, @args)
sub _invoke {
  my $type = lc shift;
  my $subroot = shift;
  my $package = $types{$type}
    or croak "unknown '$type'\n";
  eval "require $package";
  croak $@ if $@;
  no strict 'refs';
  return &{"${package}::${subroot}${type}"}(@_);
}

sub test_id {
  return _invoke(shift, 'test_', @_);
}

sub canon_id {
  return _invoke(shift, 'canon_', @_);
}

sub format_id {
  return _invoke(shift, 'format_', @_);
}

sub parse_id {
  return _invoke(shift, 'parse_', @_);
}

sub random_id {
  return _invoke(shift, 'random_', @_);
}

1;

__END__

=head1 NAME

Business::BR::Ids - Modules for dealing with Brazilian identification codes (CPF, CNPJ, ...)

=head1 SYNOPSIS

  use Business::BR::Ids;
  my $cpf = '390.533.447-05';
  print "ok as CPF" if test_id('cpf', $cpf);
  my $cnpj = '90.117.749/7654-80';
  print "ok as CNPJ" if test_id('cnpj', $cnpj);

=head1 DESCRIPTION

This is a generic module for handling the various supported
operations on Brazilian identification numbers and codes.
For example, it is capable to test the correctness of CPF,
CNPJ and IE numbers without the need for explicitly 'requiring' or
'using' this modules (doing it automatically on demand).

=over 4

=item B<test_id>

  test_id($entity_type, @args); 
  test_id('cpf', $cpf); # the same as "require Business::BR::CPF; Business::BR::CPF::test_cpf($cpf)"

Tests for correct inputs of ids which have a corresponding Business::BR module.
For now, the supported id types are 'cpf', 'cnpj', 'ie', and 'pis'.

=item B<canon_id>

  canon_id($entity_type, @args)

Transform the input to a canonical form. The canonical
form is well-defined and as short as possible.
For instance, C<canon_id('cpf', '29.128.129-11')>
returns C<'02912812911'> which has exactly 11 digits
and no extra character.

=back

=head2 EXPORT

C<test_id> is exported by default. C<canon_id>, C<format_id>,
C<parse_id> and C<random_id> are exported on demand.

=begin comment

 =head1 OVERVIEW

 test_*
 canon_*
 format_*
 parse_*
 random_*
 
 =head1 ETHICS

 The facilities provided here can be used for bad purposes,
 like generating correct codes for trying frauds.
 This is specially true of the C<random_*()> functions.
 But anyway with only C<test_*()> functions, it is also very
 easy to try typically 100 choices and find a correct
 code as well. 

 Unethical programmers (as any unethical people) should not be 
 a reason to conceal things (like code) that can benefit
 a community. And I felt that this kind of code sometimes
 is hidden by other wrong reasons: to keep such a knowledge
 restricted to a group of people wanting to make money of it.
 But this is (or should be) public information.

 If institutions were really worried about this, they
 should publish validation equations like the ones
 listed in the documentation here instead of computation
 algorithms for check digits. If one does not know enough
 math to solve the equations, probably
 they don't need the solutions anyway. 

 For modules on this distribution, only correctness is tested.
 For doing business, usually codes must be verified 
 against the databases of the information owners, usually
 government bodies. 


=end comment

=head1 SEE ALSO

Details on handling CPF, CNPJ, IE and PIS can be found in
the specific modules:

=over 4

=item *

Business::BR::CPF

=item *

Business::BR::CNPJ

=item *

Business::BR::IE

=item *

Business::BR::PIS

=back

Please reports bugs via CPAN RT, 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-BR-Ids

=head1 AUTHOR

A. R. Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by A. R. Ferreira

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
