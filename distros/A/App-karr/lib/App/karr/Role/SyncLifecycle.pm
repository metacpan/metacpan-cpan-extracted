# ABSTRACT: Role providing sync lifecycle with retry and guard insurance

package App::karr::Role::SyncLifecycle;
our $VERSION = '0.205';
use Moo::Role;
use Carp qw( croak );



sub sync_before {
    my ($self) = @_;
    my $git = $self->can('git') ? $self->git : $self->store->git;

    my $ok   = 0;
    my $err  = '';
    for my $attempt ( 1 .. 3 ) {
        print STDERR "Pull attempt $attempt of 3...\n";
        $ok = $git->pull;
        if ($ok) {
            print STDERR "Pull successful.\n" if $attempt > 1;
            last;
        }
        $err = "git pull failed (exit code $?)";
        print STDERR "  $err\n";
        sleep 1 if $attempt < 3;
    }
    croak "Pull failed after 3 attempts: $err\n" unless $ok;

    require App::karr::SyncGuard;
    return App::karr::SyncGuard->new( git => $git );
}


sub sync_after {
    my ($self) = @_;
    my $git = $self->can('git') ? $self->git : $self->store->git;

    my $ok   = 0;
    my $err  = '';
    for my $attempt ( 1 .. 3 ) {
        print STDERR "Push attempt $attempt of 3...\n";
        $ok = $git->push;
        if ($ok) {
            print STDERR "Push successful.\n" if $attempt > 1;
            last;
        }
        $err = "git push failed (exit code $?)";
        print STDERR "  $err\n";
        sleep 1 if $attempt < 3;
    }
    croak "Push failed after 3 attempts. Local refs are intact.\n"
      . "Run 'karr sync' to retry.\n" unless $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::SyncLifecycle - Role providing sync lifecycle with retry and guard insurance

=head1 VERSION

version 0.205

=head1 DESCRIPTION

This role provides C<sync_before> and C<sync_after> methods that wrap Git pull
and push operations with retry logic. C<sync_before> returns a L<App::karr::SyncGuard>
object that acts as insurance: if the command body dies or croaks before
C<sync_after> is called, the guard's DESTROY runs C<sync_after> with 3 retries.

Commands that compose this role must also have a C<store> attribute (provided
by L<App::karr::Role::BoardDiscovery>) with a C<git> accessor.

=head1 METHODS

=head2 sync_before

    my $guard = $self->sync_before;

Pulls refs from remote with 3 retries and clear error messages on failure.
Returns a L<App::karr::SyncGuard> object. The guard must be marked done after
successful C<sync_after>, or it will attempt push on scope exit.

=head2 sync_after

    $self->sync_after;  # push with 3 retries
    $guard->done;       # mark guard as handled

Pushes refs to remote with 3 retries and clear error messages. After
successful push, mark the guard done so its DESTROY is a no-op.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
