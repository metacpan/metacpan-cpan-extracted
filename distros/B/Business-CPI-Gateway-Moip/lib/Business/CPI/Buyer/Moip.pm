package Business::CPI::Buyer::Moip;
use Moo;

extends qw/Business::CPI::Buyer/;

=pod

=encoding utf-8

=head1 NAME

Business::CPI::Buyer::Moip

=head1 DESCRIPTION

extends Business::CPI::Buyer

=head1 ATTRIBUTES

=head2 phone

buyer phone number

=cut

has phone => (
    is => 'rw',
);

=head2 id_pagador

de acordo com os docs: http://labs.moip.com.br/referencia/integracao_xml_identificacao/

=cut

has id_pagador => (
    is => 'rw',
);

1;
