package AnyEvent::Filesys::Notify::Role::FSEvents;

# ABSTRACT: Use Mac::FSEvents to watch for changed files

use Moo::Role;
use MooX::late;
use namespace::autoclean;
use AnyEvent;
use Mac::FSEvents;
use Carp;

our $VERSION = '1.21';

sub _init {
    my $self = shift;

    # Created a new Mac::FSEvents fs_monitor for each dir to watch
    # TODO: don't add sub-dirs of a watched dir
    my @fs_monitors =
      map { Mac::FSEvents->new( { path => $_, latency => $self->interval, } ) }
      @{ $self->dirs };

    # Create an AnyEvent->io watcher for each fs_monitor
    my @watchers;
    for my $fs_monitor (@fs_monitors) {

        my $w = AE::io $fs_monitor->watch, 0, sub {
            if ( my @events = $fs_monitor->read_events ) {
                $self->_process_events(@events);
            }
        };
        push @watchers, $w;

    }

    $self->_fs_monitor( \@fs_monitors );
    $self->_watcher( \@watchers );
    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::FSEvents - Use Mac::FSEvents to watch for changed files

=head1 VERSION

version 1.21

=head1 CONTRIBUTORS

=for stopwords Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the BSD support for IO::KQueue Dave Hayes E<lt>dave@jetcafe.orgE<gt> Carsten Wolff E<lt>carsten@wolffcarsten.deE<gt>

=over 4

=item *

Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the BSD support for IO::KQueue

=item *

Dave Hayes E<lt>dave@jetcafe.orgE<gt>

=item *

Carsten Wolff E<lt>carsten@wolffcarsten.deE<gt>

=back

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/AnyEvent-Filesys-Notify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
