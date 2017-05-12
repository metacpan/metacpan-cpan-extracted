package AnyMerchant::Gateway;
use Moo::Role;

requires qw(debit authorize capture credit void);


1;

__END__

=pod

=head1 NAME

AnyMerchant::Gateway

=head1 VERSION

version 0.0002

=head1 DESCRIPTION

This role defines the interface for all C<AnyMerchant::Gateway::* classes>.

=head1 METHODS

The param C<$amount> is an integer representing cents.
An amount of 1000 corresponds to $10.00.

The param C<$source> refers to either a credit card or a bank account.
It may be a proper object or a hashref.

=head2 debit

    debit($amount, $source, %params)

Charge a credit card or debit a bank account.

=head2 authorize

    authorize($amount, $source, %params)

Authorize a transaction.

=head2 capture

    capture($amount, $id, %params)

Capture an authorized transaction.

=head2 credit

    credit($amount, $target, %params)

Credit account.

=head2 void

    void($id, %params)

Void a transaction.

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
