package AnyEvent::Semaphore;

our $VERSION = '0.01';

use strict;
use warnings;

use AE;
use Scalar::Util ();
use Method::WeakCallback qw(weak_method_callback);

# internal representation of watcher is an array [$semaphore, $cb]

sub new {
    my ($class, $size) = @_;
    my $sem = { size => $size || 1,
                holes => 0,
                running => 0,
                watchers => [] };
    $sem->{schedule_cb} = weak_method_callback($sem, '_schedule'),
    bless $sem, $class;
}

sub size {
    my $sem = shift;
    if (@_) {
        $sem->{size} = shift;
        &AE::postpone($sem->{schedule_cb});
    }
    $sem->{size};
}

sub running { shift->{running} }

sub down {
    return unless defined $_[1];
    my ($sem) = @_;
    my $watchers = $sem->{watchers};
    my $w = [@_];
    bless $w, 'AnyEvent::Semaphore::Watcher';
    push @{$watchers}, $w;
    Scalar::Util::weaken($watchers->[-1]);
    &AE::postpone($sem->{schedule_cb});
    $w;
}

sub _schedule {
    my $sem = shift;
    my $watchers = $sem->{watchers};
    while ($sem->{size} > $sem->{running}) {
        if (defined (my $w = shift @$watchers)) {
            $sem->{running}++;
            my ($cb, @args) = splice @$w, 1;
            bless $w, 'AnyEvent::Semaphore::Down';
            $cb->(@args);
        }
        else {
            @$watchers or return;
        }
    }
}

sub AnyEvent::Semaphore::Watcher::DESTROY {
    local ($!, $@, $SIG{__DIE__});
    eval {
        my $watcher = shift;
        my $sem = $watcher->[0];
        my $holes = ++$sem->{holes};
        my $watchers = $sem->{watchers};
        if ($holes > 100 and $holes * 2 > @$watchers) {
            @{$sem->{watchers}} = grep defined, @$watchers;
            Scalar::Util::weaken $_ for @$watchers;
            $sem->{holes} = 0;
        }
    }
}

sub AnyEvent::Semaphore::Down::DESTROY {
    local ($!, $@, $SIG{__DIE__});
    eval {
        my $sem = shift->[0];
        $sem->{running}--;
        &AE::postpone($sem->{schedule_cb})
    }
}

1;

__END__


=head1 NAME

AnyEvent::Semaphore - Semaphore implementation for AnyEvent

=head1 SYNOPSIS

  use AnyEvent::Semaphore;

  my $sem = AnyEvent::Semaphore->new(5);
  ...

  my $watcher = $sem->down( sub { ... } );
  ...

  undef $watcher; # semaphore up



=head1 DESCRIPTION

This module provides a semaphore implementation intended to be used
with the L<AnyEvent> framework.

It tries to be as simple as possible and to follow AnyEvent style.

=head2 API

The module provides the following methods:

=over 4

=item $sem = AnyEvent::Semaphore->new($size);

Creates a new semaphore object of the given size.

=item $watcher = $sem->down($callback)

Queues a down (or wait) operation on the semaphore. The given callback
will be eventually invoked when the resouce guarded by the semaphore
becomes free.

The call returns a watcher object.

After the resource is assigned and the callback invoked, destroying
the watcher frees the resource (it is the equivalent of the up or
signal operation).

Destroying the watcher before the resource is asigned just cancels the
down operation.

=item $new_size = $sem->size($size)

=item $new_size = $sem->size

Gets or sets the semaphore size.

When the size is increased, queued operations will be processed.

=item $n = $sem->running

Returns the number of slots currently used.

=back

=head1 SEE ALSO

The Wikipedia page on L<semaphores|http://en.wikipedia.org/wiki/Semaphore_%28programming%29>.

L<AnyEvent>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
