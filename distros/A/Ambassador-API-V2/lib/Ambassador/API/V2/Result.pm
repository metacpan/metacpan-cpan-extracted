package Ambassador::API::V2::Result;

use Moo;
use Types::Standard ":types";
with 'Ambassador::API::V2::Role::Response';

our $VERSION = '0.001';

has data => (
    is       => 'lazy',
    isa      => HashRef,
    required => 1
);

sub _build_data {
    my $self = shift;

    return $self->response->{data};
}

1;

__END__

=head1 NAME

Ambassador::API::V2::Result - A successful API response.

=head1 DESCRIPTION

L<Ambassador::API::V2::Role::Response> plus...

=head1 ATTRIBUTES

=over 4

=item data

The "data" portion of an Ambassador response as a hash ref.

=back

=head1 SOURCE

The source code repository for Ambassador-API-V2 can be found at
F<https://github.com/dreamhost/Ambassador-API-V2>.

=head1 COPYRIGHT

Copyright 2016 Dreamhost E<lt>dev-notify@hq.newdream.netE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
