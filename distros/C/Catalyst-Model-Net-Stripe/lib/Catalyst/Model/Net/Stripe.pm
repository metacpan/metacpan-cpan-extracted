package Catalyst::Model::Net::Stripe;
use strict;

use Carp qw( croak );
use Net::Stripe;
use Moose;
extends 'Catalyst::Model';
no Moose;

=head1 NAME

Catalyst::Model::Net::Stripe - Stripe Model for Catalyst

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    # Use the helper to add a Stripe model to your application
    script/myapp_create.pl model Stripe Net::Stripe

    package YourApp::Model::Stripe;
    use parent 'Catalyst::Model::Net::Stripe';
        __PACKAGE->config(
            api_key => 'API_KEY_HERE',
        );
    1;
    
    package YourApp::Controller::Foo;

    sub index : Path('/') {
        my ($self, $c) = @_;
    
        my $card = Net::Stripe::Card->new(
            number => '4242424242424242',
            cvc => '499',
            name => 'Bob Jones',
            address_line1 => '2222 Palm Street',
            address_line2 => 'Apt. 603',
            address_zip => '78705',
            address_state => 'TX',
            exp_month => '02',
            exp_year=> '15',
        );

        my $customer = $c->model('Net::Stripe')->post_customer(
          card => $card,
          email => 'stripe@example.com',
          description => 'Test for Net::Stripe',
        );

        $c->res->body($customer->id);
    }
 
    1;

=head1 SUBROUTINES/METHODS

=cut

=head2 new

L<Catalyst> calls this method.

=cut

sub new {
	my $self  = shift->next::method(@_);
	my $class = ref($self);

    # Ensure that the required configuration is available...
    croak "->config->{api_key} must be set for $class\n" unless $self->{api_key};
     
    # Instantiate a new Net::Stripe object...
    $self->{stripe} = Net::Stripe->new(
		api_key => $self->{api_key},
    );
     
    return $self;
}

sub stripe { shift->{stripe} }

sub AUTOLOAD {
    my $self = shift;
    my %args = @_;
 
    our $AUTOLOAD;
 
    my $program = $AUTOLOAD;
    $program =~ s/.*:://;
 
    # pass straight through to our paypal object
    return $self->{stripe}->$program(%args);
}

=head1 AUTHOR

Adam Hopkins, C<< <srchulo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-model-net-stripe at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-Net-Stripe>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Model::Net::Stripe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Model-Net-Stripe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Model-Net-Stripe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Model-Net-Stripe>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Model-Net-Stripe/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Adam Hopkins.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Catalyst::Model::Net::Stripe
