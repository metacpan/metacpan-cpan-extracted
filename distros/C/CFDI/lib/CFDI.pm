package CFDI;
use strict;
use CFDI::Macros::Excel;
require Exporter;
our @EXPORT = qw(xcel xcel2 xcel3 xcel4 xcel5 excel excel2 excel3 excel4 excel5);
our @ISA = qw(Exporter);
our $VERSION = 0.2;
1;

__END__


=head1 NAME

CFDI - Comprobante Fiscal Digital por Internet

=head1 SYNOPSIS

  use CFDI;
  xcel;

  #or one liner
  perl -MCFDI -excel

=head1 DESCRIPTION

  Advise for non-mexican users: This module is meant to be used to parse very specific XML Mexican government defined invoices.

  Lee todos los CFDI en XML dentro del directorio actual y despliega en hoja de calculo.

=head1 LICENSE

  This is released under the Artistic License 2.

=head1 AUTHOR

  Aldo Montes Zapata - amontes@cpan.org

=cut

