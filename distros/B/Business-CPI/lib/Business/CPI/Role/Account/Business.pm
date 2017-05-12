package Business::CPI::Role::Account::Business;
# ABSTRACT: Business::CPI representation of corporations
use Moo::Role;
use utf8;

our $VERSION = '0.924'; # VERSION

has _gateway => ( is => 'ro', required => 1 );

has corporate_name => ( is => 'rw' );
has trading_name   => ( is => 'rw' );
has phone          => ( is => 'rw' );

has address => ( is => 'rw' );

around address => sub {
    my $orig = shift;
    my $self = shift;

    if (my $new_address = shift) {
        return $self->$orig( $self->_inflate_address($new_address) );
    }

    return $self->$orig();
};

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $args  = $class->$orig(@_);

    return $args if !$args->{_gateway};

    if (exists $args->{address}) {
        $args->{address} = $class->_inflate_address($args->{address}, $args->{_gateway});
    }

    return $args;
};

sub _inflate_address {
    my ($self, $addr, $gateway) = @_;

    $gateway ||= $self->_gateway;

    return $gateway->account_address_class->new($addr);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Account::Business - Business::CPI representation of corporations

=head1 VERSION

version 0.924

=head1 SYNOPSIS

    $cpi->create_account({
        # ...
        business => {
            corporate_name => 'MyCompany Ltd.',
            trading_name   => 'MyCompany',
            phone          => '11 11110000',
            address        => {
                street     => 'Alameda Santos',
                number     => '321',
                complement => '3º andar',
                district   => 'Bairro Y',
                city       => 'São Paulo',
                state      => 'SP',
                country    => 'br',
            },
        },
        # ...
    });

=head1 DESCRIPTION

This role represents information about businesses in the context of accounts in
gateways. You shouldn't have to instantiate this yourself, but use the helpers
provided by the gateway driver.

=head1 ATTRIBUTES

=head2 corporate_name

The complete corporate name of the company.

=head2 trading_name

The common trading name as the company is known.

=head2 phone

A phone number of the company.

=head2 address

See L<Business::CPI::Role::Account::Address>. You should provide a
HashRef with the attributes, according to the
L<< Address | Business::CPI::Role::Account::Address >>
role, and it will be inflated for you.

=head1 SPONSORED BY

Estante Virtual - L<http://www.estantevirtual.com.br>

=head1 SEE ALSO

L<Business::CPI>, L<Business::CPI::Role::Account>,
L<Business::CPI::Role::Account::Address>

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
