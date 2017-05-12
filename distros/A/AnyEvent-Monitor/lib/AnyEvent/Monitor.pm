package AnyEvent::Monitor;
use 5.10.1;
use AnyEvent;
use Method::Signatures::Simple;
use Any::Moose;

our $VERSION = '0.32';

has on_softfail => ( is => "ro", isa => "CodeRef" );
has on_hardfail => ( is => "ro", isa => "CodeRef" );
has on_resume   => ( is => "ro", isa => "CodeRef" );
has on_fatal    => ( is => "ro", isa => "CodeRef" );
has status      => ( is => "rw", isa => "Str", default => sub {''} );
has timer       => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has soft_timeout => ( is => 'rw', isa => 'Num', default => sub { 10 } );
has hard_timeout => ( is => 'rw', isa => 'Num', default => sub { 45 } );

has fail_detected => ( is => 'rw', isa => 'Num' );

method BUILD {
    $self->install_timers(0);
};

method install_timers($delay) {
    $self->install_timer( soft => $delay + $self->soft_timeout );
    $self->install_timer( hard => $delay + $self->hard_timeout );
}

method install_timer($which, $after) {
    my $method = "${which}fail";
    $self->timer->{$which} = AnyEvent->timer(after => $after,
                                             cb => sub {
                                                 $self->fail_detected(AnyEvent->now) unless $self->fail_detected;
                                                 $self->$method();
                                             },
                                         );
}

method heartbeat($timestamp, $status) {
    if ($status eq 'normal') {
        $self->install_timers($timestamp - AnyEvent->now);
        if ($self->status ne 'normal') { 
            my $outage = $self->fail_detected ? AnyEvent->now - $self->fail_detected : 0;
            $self->fail_detected(0);

            $self->on_resume->($self->status, $outage);
        }
    }
    $self->status($status);
}

method softfail {
    $self->status('soft timeout')
        if $self->status eq 'normal';
    $self->on_softfail->();
}

method hardfail {
    $self->status('hard timeout')
        if $self->status eq 'normal';
    $self->on_hardfail->(sub {
                             $self->install_timers(shift || 60)
                                 unless $self->status eq 'normal'
                             });
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::Monitor - Service Monitoring using AnyEvent

=head1 SYNOPSIS

  use AnyEvent::Monitor;

  my $foo = AnyEvent::Monitor->new(
      name => 'foo',
      on_softfail => sub {
          warn "==> service fail: $_[1]";
      },
      on_hardfail => sub {
          my ($resume_check);
          warn "==> service fail, should attempt to do something to fix it: $_[1]";
          $resume_check->(60); # resume checking after 60 secs
      },
      on_resume => sub {
          my ($prev, $outage) = @_;
          if ($prev) {
              warn "service resumed from: $prev, total outage: $outage secs";
          }
      });

  $foo->install_timers( 300 ); # delay checking for 300 secs

  sub my_polling_check {
      my ($timestamp, $status) = @_;
      # $foo->heartbeat($timestamp, $status);
  }

  $foo->status; # expecting "normal"

=head1 DESCRIPTION

AnyEvent::Monitor provides a simple way to do periodical checks on
given services, and provides callback when the service fails that you
can attempt to fix it programmatically.

=head1 ATTRIBUTES

=over

=item softfail_timeout

=item hardfail_timeout

=item on_softfail

The callback to be called after service remains failed for C<$soft_timeout>.

=item on_hardfail($resume)

The callback to be called after service remains failed for
C<$hard_timeout>.  You should attempt to fix the service and call
C<$resume->($delay)> after the attempt has been made.  This will make
the monitoring resume after C<$delay> seconds.

=item on_resume($previous_status, $outage)

The callback to be called after service monitoring resumes.  If it had
failed, C<$previous_status> and C<$outage> seconds will be given.

=back

=head1 METHODS

=over

=item install_timers($delay)

Set the next checking timer according to C<soft_timeout> and
C<hard_timeout>, with additional C<$delay> from now.  You don't
normally need to call this method manually, unless you want to delay
the start of the monitoring.

=item heartbeat($timestamp, $status)

This is used to update the status of the service.  only C<normal> is
meaningful to L<AnyEvent::Monitor>.  Other values are considered as
the service failed.

=back

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
