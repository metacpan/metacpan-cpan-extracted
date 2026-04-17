package Apertur::SDK::Resource::Polling;

use strict;
use warnings;

use Time::HiRes qw(sleep time);

sub new {
    my ($class, %args) = @_;
    return bless { http => $args{http} }, $class;
}

sub list {
    my ($self, $uuid) = @_;
    return $self->{http}->request('GET', "/api/v1/upload-sessions/$uuid/poll");
}

sub download {
    my ($self, $uuid, $image_id) = @_;
    return $self->{http}->request_raw(
        'GET', "/api/v1/upload-sessions/$uuid/images/$image_id",
    );
}

sub ack {
    my ($self, $uuid, $image_id) = @_;
    return $self->{http}->request(
        'POST', "/api/v1/upload-sessions/$uuid/images/$image_id/ack",
    );
}

sub poll_and_process {
    my ($self, $uuid, $handler, %options) = @_;

    my $interval = $options{interval} || 3;
    my $timeout  = $options{timeout}  || 0;
    my $start    = time();

    while (1) {
        if ($timeout > 0 && (time() - $start) >= $timeout) {
            last;
        }

        my $result = $self->list($uuid);
        my $images = $result->{images} || [];

        for my $image (@$images) {
            if ($timeout > 0 && (time() - $start) >= $timeout) {
                return;
            }
            my $data = $self->download($uuid, $image->{id});
            $handler->($image, $data);
            $self->ack($uuid, $image->{id});
        }

        if ($timeout > 0 && (time() - $start) >= $timeout) {
            last;
        }

        sleep($interval);
    }

    return;
}

1;

__END__

=head1 NAME

Apertur::SDK::Resource::Polling - Long polling for new images

=head1 DESCRIPTION

Polls an upload session for new images, downloads them, and
acknowledges receipt to advance the queue.

=head1 METHODS

=over 4

=item B<list($uuid)>

Returns the current poll result for a session (hashref with C<images>).

=item B<download($uuid, $image_id)>

Downloads an image as raw bytes.

=item B<ack($uuid, $image_id)>

Acknowledges receipt of an image, removing it from the poll queue.

=item B<poll_and_process($uuid, $handler, %options)>

Blocking polling loop. Calls C<$handler-E<gt>($image, $data)> for
each new image. Options:

=over 8

=item C<interval> - seconds between polls (default 3)

=item C<timeout> - total seconds before stopping (default 0 = no timeout)

=back

=back

=cut
