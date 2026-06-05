# ABSTRACT: Push guard with automatic retry on scope exit

package App::karr::SyncGuard;
our $VERSION = '0.301';
use Moo;
use strict;
use warnings;


has git => (
    is       => 'ro',
    required => 1,
);

has _done => (
    is       => 'rw',
    default  => 0,
);

has _errors => (
    is       => 'ro',
    default  => sub { [] },
);


sub done {
    my ($self) = @_;
    $self->{_done} = 1;
}


sub errs {
    my ($self) = @_;
    return @{$self->{_errors}};
}

sub DESTROY {
    my ($self) = @_;
    return if $self->{_done};

    my $git  = $self->git;
    my $ok   = 0;
    my $err  = '';

    for my $attempt ( 1 .. 3 ) {
        print STDERR "Push attempt $attempt of 3...\n";
        $ok = $git->push;
        if ($ok) {
            $self->{_done} = 1;
            return;
        }
        $err = "git push failed (exit code $?)";
        push @{$self->{_errors}}, $err;
        print STDERR "  $err\n";
        sleep 1 if $attempt < 3;
    }

    die "Push failed after 3 attempts. Local refs are intact.\n"
      . "Run 'karr sync' to retry.\n"
      . "Errors: " . join( ', ', $self->errs ) . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::SyncGuard - Push guard with automatic retry on scope exit

=head1 VERSION

version 0.301

=head1 SYNOPSIS

    my $guard = $self->sync_before;  # git pull + return guard
    # ... command logic ...
    $self->sync_after;               # explicit push
    $guard->done;                    # mark guard as done (DESTROY no-ops)
    undef $guard;

    # If die/croak happens before sync_after:
    # Guard DESTROY runs sync_after with 3 retries, then dies with clear error

=head1 DESCRIPTION

L<App::karr::SyncGuard> is created by L<App::karr::Role::SyncLifecycle/sync_before>.
It acts as an insurance policy: if the command body dies or croaks before
L<App::karr::Role::SyncLifecycle/sync_after> is called explicitly, the guard's
DESTROY runs sync_after with retry logic, ensuring refs are pushed even on failure.

=head1 METHODS

=head2 done

    $guard->done;

Marks the guard as successfully completed. After this is called, the guard's
DESTROY is a no-op. Call this after L</sync_after> succeeds.

=head2 errs

    my @errors = $guard->errs;

Returns the list of error messages from retry attempts.

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
