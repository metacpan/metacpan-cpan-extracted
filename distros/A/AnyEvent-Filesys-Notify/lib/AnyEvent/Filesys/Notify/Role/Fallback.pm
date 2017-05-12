package AnyEvent::Filesys::Notify::Role::Fallback;

# ABSTRACT: Fallback method of file watching (check in regular intervals)

use Moo::Role;
use MooX::late;
use namespace::autoclean;
use AnyEvent;
use Carp;

our $VERSION = '1.21';

sub _init {
    my $self = shift;

    $self->_watcher(
        AnyEvent->timer(
            after    => $self->interval,
            interval => $self->interval,
            cb       => sub {
                $self->_process_events();
            } ) ) or croak "Error creating timer: $@";

    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::Fallback - Fallback method of file watching (check in regular intervals)

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
