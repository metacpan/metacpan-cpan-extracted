package BPM::Engine::Role::RunnerAPI;
BEGIN {
    $BPM::Engine::Role::RunnerAPI::VERSION   = '0.01';
    $BPM::Engine::Role::RunnerAPI::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose::Role;

requires qw(
    log
    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency

    cb_start_process
    cb_start_activity
    cb_start_transition
    cb_start_task
    cb_continue_process
    cb_continue_activity
    cb_continue_transition
    cb_continue_task
    cb_complete_process
    cb_complete_activity
    cb_complete_transition
    cb_complete_task
    cb_execute_process
    cb_execute_activity
    cb_execute_transition
    cb_execute_task

    process
    process_instance
    callback

    start_process
    complete_process

    start_activity
    continue_activity
    complete_activity
    );

no Moose::Role;

1;
__END__


=pod

=head1 NAME

BPM::Engine::Role::RunnerAPI - ProcessRunner API inventory

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This Moose role requires all documented API methods for L<BPM::Engine::ProcessRunner>.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut