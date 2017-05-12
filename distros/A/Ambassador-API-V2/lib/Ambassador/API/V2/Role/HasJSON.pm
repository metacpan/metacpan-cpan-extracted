package Ambassador::API::V2::Role::HasJSON;

use Moo::Role;
use JSON::MaybeXS;

our $VERSION = '0.001';

# Configure and cache the JSON object
has json => (
    is      => 'ro',
    default => sub {
        return JSON->new->utf8(1);
    }
);

1;

__END__

=head1 NAME

Ambassador::API::V2::Role::HasJSON - Adds a json attribute with a JSON::MaybeXS
object

=head1 DESCRIPTION

Role for objects with JSON.

=head1 ATTRIBUTES

=over 4

=item json

Returns a JSON::MaybeXS object.

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
