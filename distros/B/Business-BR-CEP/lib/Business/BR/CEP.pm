package Business::BR::CEP;
use warnings;
use strict;
use parent 'Exporter';

our $VERSION = 0.01;
our @EXPORT_OK =
  qw( test_cep testa_cep cep_type tipo_cep cep_region regiao_cep );

sub test_cep { return $_[0] =~ m/^\d{5}-\d{3}$/ }
*testa_cep = \&test_cep;

sub tipo_cep {
  return '' unless test_cep( $_[0] );

  my $suffix = substr $_[0], 6, 3;
  return 'logradouro'   if $suffix < 900;
  return 'especial'     if $suffix < 960;
  return 'promocionais' if $suffix < 970;
  return 'correios'     if $suffix < 990 || $suffix == 999;
  return 'caixapostal';
}
*cep_type = \&tipo_cep;

sub regiao_cep {
  return () unless test_cep( $_[0] );

    my %regioes = (
        0 => ['sp'],
        1 => ['sp'],
        2 => [qw( rj es)],
        3 => ['mg'],
        4 => [qw( ba se )],
        5 => [qw( pe al pb rn )],
        6 => [qw( ce pi ma pa am ac ap rr )],
        7 => [qw( df go to mt mg ro )],
        8 => [qw( pr sc )],
        9 => ['rs'],
    );

  return @{ $regioes{ substr( $_[0], 0, 1 ) } };
}
*cep_region = \&regiao_cep;

42;
__END__
=encoding utf8

=head1 NAME

Business::BR::CEP - Test for correct CEP numbers (Brazilian ZIP Code)


=head1 SYNOPSIS

    use Business::BR::CEP qw( test_cep cep_type cep_region );
    
    print 'ok!' if test_cep( '13165-000' );

    print 'invalid cep' unless cep_type( $cep ) eq 'logradouro';

    use List::MoreUtils qw( any );
    print 'address mismatch!'
      unless any { $_ eq $given_state } cep_region( $cep );


=head1 DESCRIPTION

The CEP number is the Brasilian postal (ZIP) code, used by the national
post office to locate addresses in Brasil. CEP stands for "Código de
Endereçamento Postal" (literally, Postal Addressing Code).

This module exports by default the C<test_cep()> function, meant for
checking that a CEP number is I<correct>. According to the
L<http://www.correios.com.br/servicos/cep/cep_estrutura.cfm|Correios website>,
this is what means to be correct:

=over 4

=item * 'NNNNN-NNN', where N is a digit [0-9]

=back

That's pretty much it. Contrary to popular belief, there is no validation digit.
This module just validate CEP syntax, it does not test whether the actual CEP exists
- you would have to query the actual full database from Correios for that (refer to
the L</"SEE ALSO"> section of this document for extra modules that help with that).

However, there are times when all you need is check whether it's a valid number from
a particular region, or from an actual address (rather than an internal code for the
post office or something). In case you need such extra validation, there are other
exportable functions that help figuring out just that.

=head1 BASIC INTERFACE 

=head2 test_cep( $cep )

=head2 testa_cep( $cep )

Receives the CEP code as a string, returns true if it's a valid CEP string.

=head1 EXTRA FUNCTIONS

There's some extra benefit to using this module, as it is also able to check
the type and region of the CEP, making it ideal for extra validation.

These functions are B<not> exported by default.

=head2 cep_type( $cep )

=head2 tipo_cep( $cep )

Returns a string containing the type of the CEP, or an empty string if it's not a valid CEP.

Possible return values, depending on the given suffix:

=over 4

=item * C<'logradouro'> - regular addresses (usually that's all you care about):  000-899

=item * C<'especial'> - special codes from the post office: 900-959

=item * C<'promocionais'> - promotional CEP numbers: 960-969

=item * C<'correios'> - Correios facilities: 970-989, 999

=item * C<'caixapostal'> - Community PO Boxes: 990-998

=back

=head2 cep_region( $cep )

=head2 regiao_cep( $cep )

CEP numbers follow this numbering scheme:

   NNNNN-NNN
   ||||| |||
   ||||| || \__
   ||||| | \___\ distribution identifiers (suffix)
   |||||  \____/
   |||||
   |||| \__ subsector division
   ||| \___ subsector
   || \____ sector
   | \_____ subregion
    \______ region

While returning every possible address would require the full Correios database,
the basic regions (first digit) are well known and simple enough to be used, if
only to identify whether the CEP is from the same region as an address.

This function returns an array where each element is the short version of
a Brasilian State covered by the region from the provided CEP, or an empty list
if it's not a valid CEP.


=head1 CONFIGURATION AND ENVIRONMENT

Business::BR::CEP requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-business-br-cep@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Estante Virtual. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as the Perl 5 programming language itself.
See L<perlartistic>.


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
