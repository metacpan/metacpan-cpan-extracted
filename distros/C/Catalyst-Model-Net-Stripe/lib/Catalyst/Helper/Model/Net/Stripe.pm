package Catalyst::Helper::Model::Net::Stripe;
use strict;
 
=head1 NAME
 
Catalyst::Helper::Model::Net::Stripe - Helper for Net::Stripe Model
 
=head1 SYNOPSIS
 
  script/myapp_create.pl model Stripe Net::Stripe
 
=head1 DESCRIPTION
 
Helper for Net::Stripe model
 
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
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::Net::Stripe>
 
=head1 AUTHOR
 
Adam Hopkins, C<srchulo at cpan.org>
 
=head1 LICENSE
 
This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.
 
=cut
 
1;
 
__DATA__
=begin pod_to_ignore
 
__compclass__
package [% class %];
 
use strict;
use warnings;
 
use base qw/Catalyst::Model::Net::Stripe/;
 
# 3-token (Signature) authentication
__PACKAGE__->config(
	api_key => 'API_KEY_HERE',
);
 
=head1 NAME
 
[% class %] - Catalyst Net::Stripe Model for [% app %]
 
=head1 SYNOPSIS
 
See L<[% app %]>
 
=head1 DESCRIPTION
 
Catalyst Net::Stripe Model for [% app %]
 
=head1 AUTHOR
 
[% author %]
 
=head1 LICENSE
 
This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
 
1;
