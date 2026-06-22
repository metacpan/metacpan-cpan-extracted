# ABSTRACT: Role providing board discovery, sync lifecycle, and task access

package App::karr::Role::BoardAccess;
our $VERSION = '0.302';
use Moo::Role;

with 'App::karr::Role::BoardDiscovery';
with 'App::karr::Role::SyncLifecycle';


sub load_tasks {
    my ($self) = @_;
    return $self->store->load_tasks;
}

sub find_task {
    my ($self, $id) = @_;
    return $self->store->find_task($id);
}

sub save_task {
    my ($self, $task) = @_;
    return $self->store->save_task($task);
}

sub delete_task {
    my ($self, $id) = @_;
    return $self->store->delete_task($id);
}

sub allocate_next_id {
    my ($self) = @_;
    return $self->store->allocate_next_id;
}

sub parse_ids {
    my ($self, $id_str) = @_;
    return split /,/, $id_str;
}

sub activity_log {
    my ($self, $git) = @_;
    $git //= $self->git;
    require App::karr::ActivityLog;
    return App::karr::ActivityLog->new(git => $git, role => $self->role);
}

sub append_log {
    my ($self, $git, %entry) = @_;
    return $self->activity_log($git)->log_entry(%entry);
}

sub save_config {
    my ($self, $effective) = @_;
    $effective //= $self->config;
    return $self->store->save_config($effective);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::BoardAccess - Role providing board discovery, sync lifecycle, and task access

=head1 VERSION

version 0.302

=head1 DESCRIPTION

This role composes L<Role::BoardDiscovery> and L<Role::SyncLifecycle> and
adds task-access methods that delegate to the store. Commands compose this role
for full board functionality.

All task operations work directly against refs via C<< $self->store->load_tasks() >>
and similar. No temporary directory is created.

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
