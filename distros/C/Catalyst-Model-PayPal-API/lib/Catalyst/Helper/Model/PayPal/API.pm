use strict;
package Catalyst::Helper::Model::PayPal::API;

=head1 NAME

Catalyst::Helper::Model::PayPal::API - Helper for Business::PayPal::API Models

=head1 SYNOPSIS

  script/create.pl model NameOfMyView PayPal::API

=head1 DESCRIPTION

Helper for Business::PayPal::API Models

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
  my ($self, $helper) = @_;
  my $file = $helper->{file};
  $helper->render_file('compclass', $file);
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::PayPal::API>

=head1 AUTHOR

Dean Hamstead, C<dean@fragfest.com.au>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::Model::PayPal::API';

# 3-token (Signature) authentication
__PACKAGE__->config(
	Username   => 'your paypal username',
	Password   => 'ABCDEF',  ## supplied by PayPal
	Signature  => 'xyz',     ## ditto
	sandbox    => 1 || 0,    ## Use sandbox or production API
	subclasses => [qw( ExpressCheckout GetTransactionDetails )],
		       ## Which functions to use
);


=head1 NAME

[% class %] - Catalyst Business::PayPal::API Model for [% app %]

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst Business::PayPal::API Model for [% app %]

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
