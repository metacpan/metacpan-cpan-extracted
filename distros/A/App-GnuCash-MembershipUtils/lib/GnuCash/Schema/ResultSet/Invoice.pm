package GnuCash::Schema::ResultSet::Invoice;
use strict;
use warnings;
use base qw( DBIx::Class::ResultSet );

=head1 NAME

GnuCash::Schema::ResultSet::Invoice - Contains helper methods.

=head1 DESCRIPTION

GnuCash::Schema::ResultSet::Invoice is based on L<DBIx::Class::ResultSet> and
contains helper methods for accessing GnuCash invoice rows.

=head1 SYNOPSIS

  use GnuCash::Schema::ResultSet::Invoice;

=head1 METHODS

=cut

=head2 last_invoice_id

    my $last_invoice_id = $schema->resultset('Invoice')->last_invoice_id;

Returns the last invoice id.

=cut

sub last_invoice_id {
    my $self  = shift;
    
    my $invoice = $self->search(
        undef,
        {
            order_by => { -desc => "id", },
            columns  => [ qw( id ) ],
            rows     => 1,
        }
    )->first;

    return $invoice->id if ($invoice);
    return;

}

=head1 COPYRIGHT AND LICENSE

Copyright 2024, Paul Durden.

=cut

1;

