package Catalyst::Plugin::MobileUserID;

use strict;
use warnings;
use Catalyst::Request;
use HTTP::MobileUserID;

our $VERSION = '0.01';

{
    package Catalyst::Request;
    sub mobile_userid {
        my $req = shift;
        $req->{mobile_userid} ||= HTTP::MobileUserID->new($req->mobile_agent);
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::MobileUserID - mobile user id returned plugin for Catalyst

=head1 SYNOPSIS

  package MyApp;
  
  use Catalystqw/MobileAgent MobileUserID/;
  
  package MyApp::Controller::Root;
  
  sub index : Private {
     my ($self,$c) = @_;
     print $c->req->mobile_userid->id;
  }

=head1 DESCRIPTION

This Plugin is mobile user id returned for Catalyst

=head1 METHODS

=head2 mobile_userid

Returns an instance of HTTP::MobileUserID

=head1 AUTHOR

Ittetsu Miyazaki E<lt>ittetsu.miyazaki@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::MobileAgent>,L<HTTP::MobileUserID>,L<Catalyst::Request>

=cut
