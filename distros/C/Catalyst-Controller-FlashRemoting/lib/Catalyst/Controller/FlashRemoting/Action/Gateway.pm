package Catalyst::Controller::FlashRemoting::Action::Gateway;
use strict;
use warnings;
use base qw/Catalyst::Action/;

use Data::AMF::Packet;

sub execute {
    my $self = shift;
    my ($controller, $c, @args) = @_;

    if ($c->req->content_type eq 'application/x-amf' and my $body = $c->req->body) {
        my $data = do { local $/; <$body> };

        my $request = Data::AMF::Packet->deserialize($data);

        my @results;
        for my $message (@{ $request->messages }) {
            my $method = $controller->_amf_method->{ $message->target_uri };

            if ($method) {
                my $res;
                eval {
                    $res = $method->($controller, $c, $message->value);
                };
                if ($@) {
                    (my $res = $@) =~ s/ at.*?$//;
                    push @results, $message->error($res);
                }
                else {
                    push @results, $message->result($res);
                }
            }
            else {
                $c->log->error(qq{method for "@{[ $message->target_uri ]}" does not exist});
            }
        }

        my $response = Data::AMF::Packet->new(
            version  => $request->version,
            headers  => [],
            messages => \@results,
        );

        $c->res->content_type('application/x-amf');
        $c->res->body( $response->serialize );
    }
    else {
        $c->res->status(500);
        $c->res->body('');
    }

    $self->NEXT::execute(@_);
}

=head1 NAME

Catalyst::Controller::FlashRemoting::Action::Gateway - Action class for AMF Method

=head1 DESCRIPTION

See L<Catalyst::Controller::FlashRemoting>.

=head1 METHOD

=head2 execute

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

