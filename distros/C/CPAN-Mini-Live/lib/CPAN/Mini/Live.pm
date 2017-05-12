package CPAN::Mini::Live;
use strict;
use warnings;
use AnyEvent::FriendFeed::Realtime;
use base qw( CPAN::Mini );
our $VERSION = '0.33';

sub update_mirror {
    my $self = shift;
    $self = $self->new(@_) unless ref $self;

    # first we have to catch up if we've missed anything
    $self->trace("updating mirror...\n");
    $self->SUPER::update_mirror();

    # and now we try being live
    $self->trace("and live...\n");
    my $done   = AnyEvent->condvar;
    my $client = AnyEvent::FriendFeed::Realtime->new(
        request  => '/feed/minicpan',
        on_entry => sub {
            my $entry = shift;
            my $body  = $entry->{body};
            my ($action) = $body =~ /^(.+?) /;
            my ($uri)    = $body =~ /href="(.+?)"/;
            my $path     = $uri;
            my $remote   = $self->{remote};
            $path =~ s/^$remote//;
            my $local_file
                = File::Spec->catfile( $self->{local}, split m{/}, $path );
            $self->trace("live [$action] [$path]\n");

            if ( $action eq 'mirror_file' ) {
                $self->mirror_file($path);
            } elsif ( $action eq 'clean_file' ) {
                $self->clean_file($local_file);
            } else {
                warn "ERROR: unknown action $action";
                $done->send;
            }
        },
        on_error => sub {
            warn "ERROR: $_[0]";
            $done->send;
        },
    );
    $done->recv;
}

1;

__END__

=head1 NAME

CPAN::Mini::Live - Keep CPAN Mini up to date

=head1 SYNOPSIS

  # have a ~/.minicpanrc:
  # (change local to where you want the mirror)
  remote: http://cpan.cpantesters.org/
  exact_mirror: 1
  force: 0
  trace: 0
  class: CPAN::Mini::Live
  local: /home/acme/Public/minicpanlive/

  # then run the minicpan command:
  % minicpan
  updating mirror...
  and live...

=head1 DESCRIPTION

L<CPAN::Mini> creates a minimal mirror of CPAN and is very useful
indeed. However, to keep the mirror up to date, you must continually
run minicpan. This module makes minicpan block and listen for live
updates, thus keeping your minicpan live.

This is an experimental module. Let's see how it works out.

It works by having a backend running L<CPAN::Mini::Live::Publish>
which publishes file updates and deletions to FriendFeed.

L<CPAN::Mini::Live> first make sures it is up to date and then
listens to these updates using the FriendFeed real-time API so
your minicpan will be kept up to date in real time.

You have to use the same mirror as the backend code,
L<http://cpan.cpantesters.org/>.

=head1 SEE ALSO

L<CPAN::Mini>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
