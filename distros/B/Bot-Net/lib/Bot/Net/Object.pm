use strict;
use warnings;

package Bot::Net::Object;

=head1 NAME

Bot::Net::Object - facilties common to many Bot::Net objects

=head1 SYNOPSIS

  my $log = $self->log;

=head1 DESCRIPTION

This provides a set of common facilities to all L<Bot::Net> components.

=head1 METHODS

=head2 log

Returns a logger appropriate for the current component. This is the preferred way to retrieve a logger for logging.

=cut

sub log {
    my $self = shift;
    my $proto = ref $self || $self;

    return Bot::Net->log($proto);
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
