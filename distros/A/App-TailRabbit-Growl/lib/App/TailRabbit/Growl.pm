package App::TailRabbit::Growl;
use Moose;
use Mac::Growl;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

our $VERSION = '0.001';

extends 'App::TailRabbit';

has sticky => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

my @names = ("App::TailRabbit::Growl");
my $as_app = 'GrowlHelperApp.app';

before run => sub {
    Mac::Growl::RegisterNotifications($as_app, \@names, [$names[0]], $as_app);
};

sub notify {
    my ($self, $payload, $routing_key, $message) = @_;
    Mac::Growl::PostNotification($as_app, $names[0], '', $payload, $self->sticky, 1);
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

App::TailRabbit::Growl - Listen to a RabbitMQ exchange and emit the messages to Growl.

=head1 SYNOPSIS

    tail_reabbit_growl --sticky --exchange_name firehose --routing_key # --rabbitmq_user guest --rabbitmq_user guest --rabbitmq_host localhost

=head1 DESCRIPTION

Simple module to consume messages from a RabitMQ message queue.

=head1 BUGS

=over

=item Virtually no docs

=item All the same bugs as L<App::TailRabbit>

=item Probably several more

=back

=head1 SEE ALSO

L<Net::RabbitFoot>, L<Mac::Growl>.

=head1 AUTHOR

Tomas (t0m) Doran C<< <bobtfish@bobtfish.net> >>.

=head1 COPYRIGHT & LICENSE

Copyright the above author(s).

Licensed under the same terms as perl itself.

=cut
