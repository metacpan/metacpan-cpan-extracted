package GnuCash::Schema::ResultSet::Customer;
use strict;
use warnings;
use base qw( DBIx::Class::ResultSet );

=head1 NAME

GnuCash::Schema::ResultSet::Customer - Contains helper methods.

=head1 DESCRIPTION

GnuCash::Schema::ResultSet::Customer is based on L<DBIx::Class::ResultSet> and
contains helper methods for accessing GnuCash customer rows.

=head1 SYNOPSIS

  use GnuCash::Schema::ResultSet::Customer;

=head1 METHODS

=cut

=head2 active_customers($attrs)

    my $rs = $schema->resultset('Customer')->active_customers($attrs);

Returns a L<DBIx::Class::ResultSet> for selecting only the customer accounts
whose C<active> column is 1.

=cut

sub active_customers {
    my $self  = shift;
    my $attrs = shift // {};

    return $self->search(
      {
        'me.active' => 1,
      }, 
      {
        order_by => { -asc => "name", },
        %$attrs,
      }
    );
}

=head2 all_customers($attrs)

    my $rs = $schema->resultset('Customer')->all_customers($attrs);

Returns a L<DBIx::Class::ResultSet> for selecting all customer accounts.

=cut

sub all_customers {
    my $self  = shift;
    my $attrs = shift // {};

    return $self->search(
      undef,
      {
        order_by => { -asc => "name", },
        %$attrs,
      }
    );
}

=head1 COPYRIGHT AND LICENSE

Copyright 2024, Paul Durden.

=cut

1;

