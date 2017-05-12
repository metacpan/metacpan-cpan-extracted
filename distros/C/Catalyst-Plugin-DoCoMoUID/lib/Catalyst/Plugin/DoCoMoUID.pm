package Catalyst::Plugin::DoCoMoUID;

use strict;
use warnings;

our $VERSION = '0.01';

sub prepare_headers {
    my $c = shift;
    $c->NEXT::prepare_headers(@_);
    if ($c->req->user_agent =~ /^DoCoMo/) {
        $c->req->header('X-DoCoMo-UID' => $c->req->query_parameters->{uid});
    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::DoCoMoUID - Add i-mode terminal's uid to HTTP Request Header

=head1 SYNOPSIS

 sub default : Private {
     my ( $self, $c ) = @_;
     my $uid = $c->req->header('X-DoCoMo-UID');
 }

=head1 DESCRIPTION

The Plugin is Add i-mode terminal's uid to HTTP Request Header

=head1 AUTHOR

Ittetsu Miyazaki E<lt>ittetsu.miyazaki@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::DoCoMoUID>

Nihongo Document is Catalyst/Plugin/DoCoMoUID/Nihongo.pod

=cut
